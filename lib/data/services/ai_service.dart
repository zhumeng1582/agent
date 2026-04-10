abstract class AIService {
  Future<String> chat(String message);
  Future<String> chatImage(String message, String imagePath);
  Future<String> chatVoice(String message, String audioPath);
  Future<String> summarizeForTitle(String message);
  Future<String> summarizeImageForTitle(String imagePath);
}
