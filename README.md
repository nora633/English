# 英语学习 App

一款面向个人自用的英语学习 App，目标是把兴趣内容变成每天 15 分钟能坚持完成的听说训练闭环，并用一套 Flutter 代码同时支持 iPhone 和 Android。

## Product Goal

- 唤醒毕业后遗忘的词汇和表达。
- 围绕生活情景剧、热门英文歌等兴趣内容学习。
- 重点提升听力理解、口语流利度和日常表达反应速度。
- 通过可量化反馈帮助长期坚持，而不是只做打卡。

## MVP Direction

当前方向采用 Flutter 跨端 App + 轻后端：

- 移动端使用 Flutter，统一维护 iOS 和 Android 前端代码。
- 后端负责保护 AI API key、生成学习任务、处理语音转写与口语反馈。
- 每日学习任务控制在 15 分钟。
- 内容使用合法短片段、官方预览、公开视频链接或用户手动提供内容。

## Core Loop

1. 选择一个剧集、歌曲或生活主题。
2. 精听 2-4 句短内容。
3. 标记听不懂的词块。
4. 影子跟读并录音。
5. 获取 AI 反馈。
6. 用当天表达完成一个短情景对话。
7. 复盘 3 个词块和 1 句可迁移表达。

## Project Docs

- [产品规格](docs/product-spec.md)
- [版本路线图](docs/roadmap.md)
- [GitHub 设置指南](docs/github-setup.md)
- [iOS 静态原型](docs/ios-static-prototype.md)
- [Flutter 跨端迁移](docs/flutter-cross-platform.md)

## Run Flutter Prototype

```bash
cd mobile
flutter run
```

如需先做编译验证：

```bash
cd mobile
flutter test
flutter build web
```

## Run Legacy iOS Prototype

需要安装完整 Xcode。打开 `EnglishLearningApp.xcodeproj`，选择 iPhone 模拟器运行 `EnglishLearningApp` scheme。

## Run Backend Prototype

```bash
cd backend
cp .env.example .env
python3 server.py
```

默认没有 `OPENAI_API_KEY` 时会使用 mock 响应，方便先打通 iOS 调用链。
