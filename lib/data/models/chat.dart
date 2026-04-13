class Chat {
  final String id;
  final String name;
  final DateTime lastMessageTime;
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isPinned;

  Chat({
    required this.id,
    required this.name,
    required this.lastMessageTime,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'lastMessagePreview': lastMessagePreview,
      'unreadCount': unreadCount,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      name: map['name'],
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(map['lastMessageTime']),
      lastMessagePreview: map['lastMessagePreview'],
      unreadCount: map['unreadCount'] ?? 0,
      isPinned: map['isPinned'] == 1,
    );
  }

  // Parse from server response
  factory Chat.fromServerMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'],
      name: map['title'] ?? map['name'] ?? '新聊天',
      lastMessageTime: map['last_message_time'] != null
          ? DateTime.parse(map['last_message_time'])
          : DateTime.now(),
      lastMessagePreview: map['last_message_preview'],
      unreadCount: 0,
      isPinned: map['is_pinned'] ?? false,
    );
  }

  Chat copyWith({
    String? id,
    String? name,
    DateTime? lastMessageTime,
    String? lastMessagePreview,
    int? unreadCount,
    bool? isPinned,
  }) {
    return Chat(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
