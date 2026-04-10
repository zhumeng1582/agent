// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Multi-modal Chat';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeSubtitle => 'Enable dark theme';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  @override
  String get newChat => 'New Chat';

  @override
  String get noChats => 'No chats yet\nTap + to create a new chat';

  @override
  String get deleteChat => 'Delete Chat';

  @override
  String get deleteChatConfirm => 'Are you sure you want to delete this chat?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get clearChat => 'Clear Chat';

  @override
  String get clearChatConfirm => 'Are you sure you want to clear all messages?';

  @override
  String get confirm => 'Confirm';

  @override
  String get startChatting =>
      'Start chatting\nSend text, image or voice messages';

  @override
  String get aiThinking => 'AI is thinking...';

  @override
  String get inputPlaceholder => 'Type a message...';

  @override
  String get recording => 'Recording...';

  @override
  String get needPhotoPermission =>
      'Photo library permission is required to select images';

  @override
  String get needCameraPermission =>
      'Camera permission is required to take photos';

  @override
  String get needMicrophonePermission =>
      'Microphone permission is required to record voice';

  @override
  String get macOSNotSupported => 'macOS does not support this feature';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get image => 'Image';

  @override
  String get me => 'Me';

  @override
  String get aiAssistant => 'AI Assistant';

  @override
  String get noMessages => 'No messages yet';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get chinese => 'Chinese';

  @override
  String get english => 'English';
}
