import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/theme_provider.dart';
import '../../core/constants/locale_provider.dart';
import '../../core/constants/search_provider.dart';
import '../../data/models/message.dart';
import '../../data/repositories/message_repository.dart';
import '../providers/chat_provider.dart';
import 'chat_room_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? chatId;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.chatId,
  });

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<_SearchResult> _results = [];
  bool _isSearching = false;
  Timer? _debounce;
  bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _showHistory = false;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() {
      _showHistory = query.isEmpty;
    });
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isSearching = true);

    final chats = ref.read(chatsProvider);
    final results = <_SearchResult>[];
    final lowercaseQuery = query.toLowerCase();
    final repository = MessageRepository();

    for (final chat in chats) {
      if (widget.chatId != null && chat.id != widget.chatId) continue;

      final messages = await repository.getMessages(chat.id);
      for (final message in messages) {
        if (message.content?.toLowerCase().contains(lowercaseQuery) ?? false) {
          results.add(_SearchResult(
            chatId: chat.id,
            chatName: chat.name,
            message: message,
            matchedText: message.content ?? '',
          ));
        }
      }
    }

    results.sort((a, b) => b.message.timestamp.compareTo(a.message.timestamp));

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  void _onSubmit(String query) {
    _debounce?.cancel();
    if (query.trim().isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addSearch(query);
    }
    _performSearch(query);
    setState(() => _showHistory = false);
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() {
      _results = [];
      _showHistory = true;
    });
  }

  void _onHistoryItemTap(String query) {
    _searchController.text = query;
    _onSubmit(query);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: widget.chatId != null
                ? _t('searchInChat', locale)
                : _t('searchMessages', locale),
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onChanged: _onSearchChanged,
          onSubmitted: _onSubmit,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: isDarkMode ? Colors.grey[400] : Colors.grey[500]),
              onPressed: _onClearSearch,
            ),
        ],
      ),
      body: _buildBody(isDarkMode, locale),
    );
  }

  Widget _buildBody(bool isDarkMode, Locale locale) {
    if (_showHistory) {
      return _buildHistoryView(isDarkMode, locale);
    }

    if (_isSearching) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return _buildEmptyState(isDarkMode, locale);
    }

    return _buildResultsList(isDarkMode, locale);
  }

  Widget _buildHistoryView(bool isDarkMode, Locale locale) {
    final searchHistory = ref.watch(searchHistoryProvider);

    if (searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _t('searchHint', locale),
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _t('recentSearches', locale),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              GestureDetector(
                onTap: () => ref.read(searchHistoryProvider.notifier).clearAll(),
                child: Text(
                  _t('clearAll', locale),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: searchHistory.length,
            itemBuilder: (context, index) {
              final query = searchHistory[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.history,
                    size: 20,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                  title: Text(
                    query,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  trailing: Icon(
                    Icons.north_west,
                    size: 16,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                  ),
                  onTap: () => _onHistoryItemTap(query),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode, Locale locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            _t('noResults', locale),
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(bool isDarkMode, Locale locale) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
          child: Row(
            children: [
              Icon(
                Icons.find_in_page,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
              ),
              const SizedBox(width: 8),
              Text(
                '${_results.length} ${_t('resultsFound', locale)}',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final result = _results[index];
              final showChatHeader = index == 0 || _results[index - 1].chatId != result.chatId;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showChatHeader)
                    _buildChatHeader(result, isDarkMode, locale),
                  _buildResultItem(result, isDarkMode, locale),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader(_SearchResult result, bool isDarkMode, Locale locale) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatId: result.chatId,
              chatName: result.chatName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary,
              child: const Icon(
                Icons.chat_bubble,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.chatName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(_SearchResult result, bool isDarkMode, Locale locale) {
    final query = _searchController.text.toLowerCase();
    final content = result.message.content ?? '';
    final highlightedText = _highlightMatch(content, query, isDarkMode);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(
              chatId: result.chatId,
              chatName: result.chatName,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.message.isFromMe ? Icons.person : Icons.smart_toy,
                  size: 14,
                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  result.message.isFromMe ? '我' : 'AI',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(result.message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            highlightedText,
          ],
        ),
      ),
    );
  }

  Widget _highlightMatch(String text, String query, bool isDarkMode) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final lowercaseText = text.toLowerCase();
    final index = lowercaseText.indexOf(query);
    if (index == -1) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
        ),
        children: [
          if (index > 0)
            TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (index + query.length < text.length)
            TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return DateFormat('HH:mm').format(time);
    } else if (date == today.subtract(const Duration(days: 1))) {
      return '昨天 ${DateFormat('HH:mm').format(time)}';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE HH:mm', 'zh_CN').format(time);
    } else {
      return DateFormat('MM/dd HH:mm').format(time);
    }
  }

  String _t(String key, Locale locale) {
    final Map<String, Map<String, String>> translations = {
      'searchMessages': {'en': 'Search messages', 'zh': '搜索消息', 'zh_TW': '搜索消息'},
      'searchInChat': {'en': 'Search in chat', 'zh': '搜索聊天内容', 'zh_TW': '搜索聊天內容'},
      'cancel': {'en': 'Cancel', 'zh': '取消', 'zh_TW': '取消'},
      'noResults': {'en': 'No results', 'zh': '无结果', 'zh_TW': '無結果'},
      'searchHint': {'en': 'Search chat history', 'zh': '搜索聊天记录', 'zh_TW': '搜索聊天記錄'},
      'recentSearches': {'en': 'Recent Searches', 'zh': '最近搜索', 'zh_TW': '最近搜索'},
      'clearAll': {'en': 'Clear', 'zh': '清除', 'zh_TW': '清除'},
      'resultsFound': {'en': 'results', 'zh': '条结果', 'zh_TW': '條結果'},
    };

    final localeKey = locale.countryCode != null ? '${locale.languageCode}_${locale.countryCode}' : locale.languageCode;
    return translations[key]?[localeKey] ?? translations[key]?['zh'] ?? key;
  }
}

class _SearchResult {
  final String chatId;
  final String chatName;
  final Message message;
  final String matchedText;

  _SearchResult({
    required this.chatId,
    required this.chatName,
    required this.message,
    required this.matchedText,
  });
}
