class ChatResponse {
  final String content;
  final String? reasoning;

  ChatResponse({required this.content, this.reasoning});
}

abstract class AIService {
  Future<ChatResponse> chat(List<Map<String, String>> messages);
  Future<String> chatImage(String message, String imagePath);
  Future<String> chatVoice(String message, String audioPath);
  Future<String> summarizeForTitle(String message);
  Future<String> summarizeImageForTitle(String imagePath);
  Future<String> textToSpeech(String text);
  Future<String> generateImage(String prompt);
  Future<List<String>> generateFollowUpTopics(String userMessage, String conversationContext);
}
