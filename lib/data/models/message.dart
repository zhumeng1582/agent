enum MessageType { text, image, voice }

class Message {
  final String id;
  final String chatId;
  final MessageType type;
  final String? content;
  final String? mediaPath;
  final DateTime timestamp;
  final bool isFromMe;
  final String? replyToId;
  final String? replyToContent;
  final bool isFavorite;
  final String? translatedContent;

  Message({
    required this.id,
    required this.chatId,
    required this.type,
    this.content,
    this.mediaPath,
    required this.timestamp,
    required this.isFromMe,
    this.replyToId,
    this.replyToContent,
    this.isFavorite = false,
    this.translatedContent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'type': type.index,
      'content': content,
      'mediaPath': mediaPath,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isFromMe': isFromMe ? 1 : 0,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'isFavorite': isFavorite ? 1 : 0,
      'translatedContent': translatedContent,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      chatId: map['chatId'],
      type: MessageType.values[map['type']],
      content: map['content'],
      mediaPath: map['mediaPath'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isFromMe: map['isFromMe'] == 1,
      replyToId: map['replyToId'],
      replyToContent: map['replyToContent'],
      isFavorite: map['isFavorite'] == 1,
      translatedContent: map['translatedContent'],
    );
  }

  Message copyWith({
    String? id,
    String? chatId,
    MessageType? type,
    String? content,
    String? mediaPath,
    DateTime? timestamp,
    bool? isFromMe,
    String? replyToId,
    String? replyToContent,
    bool? isFavorite,
    String? translatedContent,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaPath: mediaPath ?? this.mediaPath,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      isFavorite: isFavorite ?? this.isFavorite,
      translatedContent: translatedContent ?? this.translatedContent,
    );
  }

  String get replyPreview {
    if (replyToContent == null) return '';
    if (replyToContent!.length > 30) {
      return '${replyToContent!.substring(0, 30)}...';
    }
    return replyToContent!;
  }
}
