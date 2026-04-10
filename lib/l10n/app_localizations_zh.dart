// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '多模态聊天';

  @override
  String get settings => '设置';

  @override
  String get appearance => '外观';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeSubtitle => '开启后应用将使用深色主题';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get developer => '开发者';

  @override
  String get newChat => '新聊天';

  @override
  String get noChats => '暂无聊天\n点击右上角 + 创建新聊天';

  @override
  String get deleteChat => '删除聊天';

  @override
  String get deleteChatConfirm => '确定要删除这个聊天吗？';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get clearChat => '清空聊天';

  @override
  String get clearChatConfirm => '确定要清空所有消息吗？';

  @override
  String get confirm => '确定';

  @override
  String get startChatting => '开始聊天吧\n发送文本、图片或语音消息';

  @override
  String get aiThinking => 'AI思考中...';

  @override
  String get inputPlaceholder => '输入消息...';

  @override
  String get recording => '正在录音...';

  @override
  String get needPhotoPermission => '需要相册权限来选择图片';

  @override
  String get needCameraPermission => '需要相机权限来拍照';

  @override
  String get needMicrophonePermission => '需要麦克风权限来录制语音';

  @override
  String get macOSNotSupported => 'macOS 暂不支持此功能';

  @override
  String get voiceMessage => '语音消息';

  @override
  String get image => '图片';

  @override
  String get me => '我';

  @override
  String get aiAssistant => 'AI助手';

  @override
  String get noMessages => '暂无消息';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get chinese => '中文';

  @override
  String get english => '英文';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '多模態聊天';

  @override
  String get settings => '設定';

  @override
  String get appearance => '外觀';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeSubtitle => '開啟後應用將使用深色主題';

  @override
  String get about => '關於';

  @override
  String get version => '版本';

  @override
  String get developer => '開發者';

  @override
  String get newChat => '新聊天';

  @override
  String get noChats => '暫無聊天\n點擊右上角 + 創建新聊天';

  @override
  String get deleteChat => '刪除聊天';

  @override
  String get deleteChatConfirm => '確定要刪除這個聊天嗎？';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get clearChat => '清空聊天';

  @override
  String get clearChatConfirm => '確定要清空所有訊息嗎？';

  @override
  String get confirm => '確定';

  @override
  String get startChatting => '開始聊天吧\n發送文本、圖片或語音訊息';

  @override
  String get aiThinking => 'AI思考中...';

  @override
  String get inputPlaceholder => '輸入訊息...';

  @override
  String get recording => '正在錄音...';

  @override
  String get needPhotoPermission => '需要相冊權限來選擇圖片';

  @override
  String get needCameraPermission => '需要相機權限來拍照';

  @override
  String get needMicrophonePermission => '需要麥克風權限來錄製語音';

  @override
  String get macOSNotSupported => 'macOS 暫不支援此功能';

  @override
  String get voiceMessage => '語音訊息';

  @override
  String get image => '圖片';

  @override
  String get me => '我';

  @override
  String get aiAssistant => 'AI助手';

  @override
  String get noMessages => '暫無訊息';

  @override
  String get language => '語言';

  @override
  String get selectLanguage => '選擇語言';

  @override
  String get chinese => '中文';

  @override
  String get english => '英文';
}
