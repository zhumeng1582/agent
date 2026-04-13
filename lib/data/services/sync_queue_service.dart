import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

enum SyncOperationType { create, update, delete }

class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String entity; // 'chat' or 'message'
  final String entityId;
  final String? conversationId; // for messages
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  int retryCount;

  SyncOperation({
    required this.id,
    required this.type,
    required this.entity,
    required this.entityId,
    this.conversationId,
    this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'entity': entity,
    'entityId': entityId,
    'conversationId': conversationId,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) => SyncOperation(
    id: json['id'] as String,
    type: SyncOperationType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => SyncOperationType.create,
    ),
    entity: json['entity'] as String,
    entityId: json['entityId'] as String,
    conversationId: json['conversationId'] as String?,
    data: json['data'] as Map<String, dynamic>?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
  );
}

class SyncQueueService {
  static const String _queueKey = 'sync_queue';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const int _maxRetries = 3;

  static final SyncQueueService _instance = SyncQueueService._internal();
  factory SyncQueueService() => _instance;
  SyncQueueService._internal();

  final List<SyncOperation> _queue = [];
  bool _isSyncing = false;
  bool _isOnline = true;
  Timer? _syncTimer;
  StreamController<List<SyncOperation>>? _queueController;

  bool get isOnline => _isOnline;
  bool get hasPendingOperations => _queue.isNotEmpty;

  Stream<List<SyncOperation>> get queueStream {
    _queueController ??= StreamController<List<SyncOperation>>.broadcast();
    return _queueController!.stream;
  }

  List<SyncOperation> get pendingOperations => List.unmodifiable(_queue);

  Future<void> init() async {
    await _loadQueue();
    _startPeriodicSync();
  }

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson != null && queueJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(queueJson);
        _queue.clear();
        for (final item in decoded) {
          try {
            _queue.add(SyncOperation.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('Failed to parse sync operation: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load sync queue: $e');
    }
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = jsonEncode(_queue.map((op) => op.toJson()).toList());
      await prefs.setString(_queueKey, queueJson);
      _queueController?.add(_queue);
    } catch (e) {
      debugPrint('Failed to save sync queue: $e');
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!ApiService.isAuthenticated) return;
      syncPendingOperations();
    });
  }

  Future<void> addOperation(SyncOperation operation) async {
    _queue.add(operation);
    await _saveQueue();
    _queueController?.add(_queue);

    // Try to sync immediately if online
    if (ApiService.isAuthenticated) {
      syncPendingOperations();
    }
  }

  Future<void> removeOperation(String operationId) async {
    _queue.removeWhere((op) => op.id == operationId);
    await _saveQueue();
    _queueController?.add(_queue);
  }

  Future<bool> syncPendingOperations() async {
    if (_isSyncing || !ApiService.isAuthenticated || _queue.isEmpty) {
      return true;
    }

    _isSyncing = true;
    _isOnline = true;
    final failedOps = <SyncOperation>[];

    try {
      for (final operation in List.from(_queue)) {
        try {
          bool success = await _executeOperation(operation);
          if (success) {
            await removeOperation(operation.id);
          } else {
            operation.retryCount++;
            if (operation.retryCount >= _maxRetries) {
              debugPrint('Operation ${operation.id} failed after $_maxRetries retries, removing');
              await removeOperation(operation.id);
            } else {
              failedOps.add(operation);
            }
          }
        } catch (e) {
          debugPrint('Sync operation error: $e');
          _isOnline = false;
          operation.retryCount++;
          if (operation.retryCount < _maxRetries) {
            failedOps.add(operation);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }

    // Update queue with failed operations
    _queue.clear();
    _queue.addAll(failedOps);
    await _saveQueue();
    _queueController?.add(_queue);

    return _queue.isEmpty;
  }

  Future<bool> _executeOperation(SyncOperation operation) async {
    switch (operation.entity) {
      case 'chat':
        return await _executeChatOperation(operation);
      case 'message':
        return await _executeMessageOperation(operation);
      default:
        return false;
    }
  }

  Future<bool> _executeChatOperation(SyncOperation operation) async {
    switch (operation.type) {
      case SyncOperationType.create:
        final response = await ApiService.createConversation(
          title: operation.data?['title'] as String? ?? '新聊天',
        );
        return response.success;

      case SyncOperationType.update:
        if (operation.data == null) return false;
        final response = await ApiService.updateConversation(
          operation.entityId,
          title: operation.data!['title'] as String?,
          isPinned: operation.data!['isPinned'] as bool?,
        );
        return response.success;

      case SyncOperationType.delete:
        final response = await ApiService.deleteConversation(operation.entityId);
        return response.success;
    }
  }

  Future<bool> _executeMessageOperation(SyncOperation operation) async {
    if (operation.conversationId == null) return false;

    switch (operation.type) {
      case SyncOperationType.create:
        if (operation.data == null) return false;
        final response = await ApiService.sendMessage(
          operation.conversationId!,
          operation.data!,
        );
        return response.success;

      case SyncOperationType.delete:
        final response = await ApiService.deleteMessage(
          operation.conversationId!,
          operation.entityId,
        );
        return response.success;

      case SyncOperationType.update:
        // Messages don't support update operations, treat as success
        return true;
    }
  }

  Future<void> saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncTimeKey, time.toIso8601String());
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastSyncTimeKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  void dispose() {
    _syncTimer?.cancel();
    _queueController?.close();
  }
}
