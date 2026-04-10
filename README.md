# 多模态聊天应用 (Multi-modal Chat)

一款支持文本、语音、图片的本地 AI 聊天应用，基于 Flutter 开发，支持 iOS 和 macOS。

## 功能特性

### 聊天功能
- **多会话支持** - 创建和管理多个聊天会话
- **AI 智能回复** - 基于 MiniMax API 的 AI 对话能力
- **聊天置顶** - 滑动左滑菜单快速置顶/取消置顶
- **引用回复** - 长按消息进行引用回复
- **拖动排序** - 自由调整聊天顺序

### 消息类型
- **文本消息** - 支持富文本聊天
- **图片消息** - 支持从相册选择或拍照发送
- **语音消息** - 支持录制和播放语音
- **语音转文字** - 长按语音消息进行语音识别转文字

### 界面与体验
- **深色模式** - 支持浅色/深色主题切换
- **多语言** - 支持简体中文、繁体中文、English
- **字体大小调节** - 可根据需求调整字体大小
- ** Typing Indicator** - AI 输入时显示动画提示

### 数据管理
- **本地存储** - 使用 SQLite 本地保存聊天记录
- **消息操作** - 复制、删除、引用回复

## 截图预览

(请在此处添加应用截图)

## 技术栈

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **Database**: SQLite (sqflite)
- **AI Service**: MiniMax API
- **Audio**: audioplayers, record
- **Image**: image_picker
- **Speech**: speech_to_text

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── app.dart                  # 应用配置
├── core/
│   └── constants/           # 常量配置
│       ├── app_colors.dart
│       ├── font_size_provider.dart
│       ├── locale_provider.dart
│       └── theme_provider.dart
├── data/
│   ├── models/              # 数据模型
│   │   ├── chat.dart
│   │   └── message.dart
│   ├── repositories/        # 数据仓库
│   └── services/            # 服务
│       ├── audio_service.dart
│       ├── database_service.dart
│       ├── image_service.dart
│       ├── minimax_service.dart
│       └── speech_service.dart
└── presentation/
    ├── providers/          # 状态管理
    │   └── chat_provider.dart
    ├── screens/            # 页面
    │   ├── chat_list_screen.dart
    │   ├── chat_room_screen.dart
    │   ├── home_screen.dart
    │   └── settings_screen.dart
    └── widgets/            # 组件
        ├── input_bar.dart
        ├── message_bubble.dart
        ├── text_message.dart
        ├── voice_message.dart
        └── image_message.dart
```

## 安装与运行

### 前置要求
- Flutter SDK 3.10+
- iOS Simulator 或 macOS 设备

### 运行步骤

```bash
# 克隆项目
git clone <repository-url>
cd agent

# 安装依赖
flutter pub get

# 运行应用
flutter run -d <device-id>

# iOS 模拟器
flutter run -d "iPhone 16"
```

## 配置说明

### MiniMax API

应用使用 MiniMax API 进行 AI 对话。在 `lib/core/constants/app_config.dart` 中配置 API Key：

```dart
class AppConfig {
  static const String minimimaxApiKey = 'your-api-key-here';
}
```

### iOS 权限配置

在 `ios/Runner/Info.plist` 中配置以下权限：

```xml
<key>NSCameraUsageDescription</key>
<string>需要相机权限来拍照发送</string>
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限来录制语音</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要相册权限来选择图片</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>需要语音识别权限来转文字</string>
```

## 开发

```bash
# 代码分析
flutter analyze

# 构建 iOS
flutter build ios

# 构建 macOS
flutter build macos
```

## License

MIT License
