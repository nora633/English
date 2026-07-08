# 外语岛 AI 接入方案

## 原则

- OpenAI API Key 只放在后端，不放进 Flutter App。
- Flutter App 只调用自己的后端接口。
- 后端负责调用 OpenAI，并把结果整理成 App 能直接展示的 JSON。
- 没有配置后端时，App 继续使用本地词库，不影响离线自用。

## 当前已接入的第一步

当前版本先接“翻译”：

```text
Flutter App -> /api/translate -> OpenAI Responses API -> Flutter App
```

后端目录：

```text
server/
```

接口：

```text
POST /api/translate
```

请求：

```json
{
  "text": "我想要一杯咖啡"
}
```

返回：

```json
{
  "source": "我想要一杯咖啡",
  "english": "I'd like a cup of coffee.",
  "koreanHonorific": "커피 한 잔 주세요.",
  "koreanCasual": "커피 한 잔 줘.",
  "koreanPronunciation": "keo-pi han jan ju-se-yo / keo-pi han jan jwo",
  "usageNote": "点单时这样说更自然。"
}
```

## 本地运行后端

```bash
cd server
cp .env.example .env
```

编辑 `.env`：

```text
OPENAI_API_KEY=你的 OpenAI API Key
OPENAI_MODEL=gpt-4.1-mini
PORT=8787
```

启动：

```bash
set -a
source .env
set +a
npm run dev
```

检查：

```bash
curl http://localhost:8787/health
```

## Flutter 连接后端

电脑浏览器或模拟器调试：

```bash
cd mobile
flutter run --dart-define=AI_TRANSLATION_API_BASE=http://localhost:8787
```

安卓真机不能用电脑的 `localhost`。如果手机和电脑在同一 Wi-Fi 下，把地址换成电脑局域网 IP：

```bash
flutter run --dart-define=AI_TRANSLATION_API_BASE=http://192.168.1.10:8787
```

如果没有传 `AI_TRANSLATION_API_BASE`，App 会自动使用本地词库。

## 打 APK 时接入 AI

```bash
cd mobile
flutter build apk --debug --no-pub \
  --dart-define=AI_TRANSLATION_API_BASE=https://你的后端域名
```

前期自用建议：

- 本地词库版：不传 `AI_TRANSLATION_API_BASE`，完全不花 AI 钱。
- AI 翻译版：部署一个后端地址，只在点“生成翻译”时调用 AI。

## 下一步 AI 功能

1. 翻译：已经具备接口骨架。
2. 听写检查：把目标句和用户输入发给 AI，返回漏词、错词和建议。
3. 默写检查：判断意思是否接近，返回自然表达建议。
4. 口语评分：上传录音，后端先转写，再评分。
5. 每日练习生成：根据本地复盘记录生成下一天 15 分钟练习。
