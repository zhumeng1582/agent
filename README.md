# 多模态聊天应用 (Multi-modal Chat)

一款支持文本、语音、图片、视频的本地 AI 聊天应用，基于 Flutter 开发，支持 iOS、Android 和 macOS。

## 功能特性

### 聊天功能
- **多会话支持** - 创建和管理多个聊天会话
- **AI 智能回复** - 基于 MiniMax API 的 AI 对话能力
- **打字机效果** - AI 回复逐字显示动画
- **聊天置顶** - 滑动左滑菜单快速置顶/取消置顶
- **引用回复** - 长按消息进行引用回复
- **拖动排序** - 自由调整聊天顺序
- **会话搜索** - 搜索聊天内容和会话名称

### 消息类型
- **文本消息** - 支持 Markdown 渲染（代码高亮、粗体、斜体等）
- **图片消息** - 支持从相册选择或拍照发送，支持 AI 图片生成
- **语音消息** - 支持录制和播放语音
- **视频消息** - 支持发送视频
- **收藏功能** - 收藏重要消息，支持跳转定位

### AI 增强功能
- **翻译** - 实时翻译消息内容
- **TTS 朗读** - 文字转语音朗读 AI 回复
- **AI 图片生成** - 根据描述生成图片
- **AI 视频生成** - 根据描述生成视频

### 界面与体验
- **豆包风格 UI** - 现代化设计，圆角卡片布局，渐变色彩
- **深色模式** - 支持浅色/深色主题切换，跟随系统选项
- **多语言** - 支持简体中文、繁体中文、English
- **字体大小调节** - 小/中/大三档可调
- **会话列表加载指示** - 显示 AI 正在思考的会话

### 数据管理
- **本地存储** - 使用 SQLite 本地保存聊天记录
- **消息操作** - 复制、删除、收藏、翻译
- **每日额度限制** - 免费用户每日 100 次 AI 对话

## 技术栈

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **Database**: SQLite (sqflite)
- **AI Service**: MiniMax API
- **Audio**: audioplayers, record
- **Image**: image_picker
- **Markdown**: flutter_markdown
- **Animation**: animated_text_kit

## 项目结构

```
lib/
├── main.dart                     # 应用入口
├── app.dart                     # 应用配置
├── core/
│   └── constants/              # 常量配置
│       ├── app_colors.dart     # 豆包风格配色
│       ├── font_size_provider.dart
│       ├── locale_provider.dart
│       ├── theme_provider.dart
│       ├── translation_provider.dart
│       └── tts_provider.dart
├── data/
│   ├── models/                # 数据模型
│   │   ├── chat.dart
│   │   └── message.dart
│   ├── repositories/          # 数据仓库
│   │   └── message_repository.dart
│   └── services/              # 服务
│       ├── audio_service.dart
│       ├── database_service.dart
│       ├── image_service.dart
│       ├── minimax_service.dart
│       └── ai_service.dart
└── presentation/
    ├── providers/            # 状态管理
    │   └── chat_provider.dart
    ├── screens/              # 页面
    │   ├── chat_list_screen.dart
    │   ├── chat_room_screen.dart
    │   ├── chat_settings_screen.dart
    │   ├── favorites_screen.dart
    │   ├── home_screen.dart
    │   ├── profile_screen.dart
    │   ├── search_screen.dart
    │   └── settings_screen.dart
    └── widgets/              # 组件
        ├── input_bar.dart
        ├── message_bubble.dart
        ├── text_message.dart
        ├── voice_message.dart
        ├── image_message.dart
        └── video_message.dart
```

## 安装与运行

### 前置要求
- Flutter SDK 3.10+
- iOS Simulator / Android Emulator / macOS 设备

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

# Android 模拟器
flutter run -d <android-device-id>
```

## 配置说明

### MiniMax API

应用使用 MiniMax API 进行 AI 对话。在 `lib/data/services/minimax_service.dart` 中配置 API Key：

```dart
class MiniMaxConfig {
  static const String apiKey = 'your-api-key-here';
  static const String baseUrl = 'https://api.minimax.chat/v1';
}
```

### Android 权限配置

在 `android/app/src/main/AndroidManifest.xml` 中已配置以下权限：
- INTERNET
- RECORD_AUDIO
- READ_EXTERNAL_STORAGE / READ_MEDIA_IMAGES

### iOS 权限配置

在 `ios/Runner/Info.plist` 中配置以下权限：

```xml
<key>NSCameraUsageDescription</key>
<string>需要相机权限来拍照发送</string>
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限来录制语音</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>需要相册权限来选择图片</string>
```

## 开发

```bash
# 代码分析
flutter analyze

# 构建 iOS
flutter build ios

# 构建 macOS
flutter build macos

# 构建 Android APK
flutter build apk
```

## 更新日志

### v2.0
- 新增豆包风格 UI 设计
- 新增打字机效果动画
- 新增视频消息支持
- 新增消息收藏和跳转定位
- 新增翻译功能
- 新增 TTS 朗读功能
- 优化深色模式体验
- 消息气泡宽度优化

### v1.0
- 基础聊天功能
- 文本、语音、图片消息
- AI 对话能力
- 多会话管理
- 搜索功能
- 深色模式
- 多语言支持

## License

MIT License
