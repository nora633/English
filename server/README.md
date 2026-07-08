# 外语岛 AI 后端

这是外语岛自用版的轻量 AI 后端。手机 App 不保存 OpenAI API Key，只调用这个后端。

## 本地启动

```bash
cd server
cp .env.example .env
```

把 `.env` 里的 `OPENAI_API_KEY` 改成自己的 Key，然后启动：

```bash
set -a
source .env
set +a
npm run dev
```

健康检查：

```bash
curl http://localhost:8787/health
```

翻译接口：

```bash
curl -X POST http://localhost:8787/api/translate \
  -H "Content-Type: application/json" \
  -d '{"text":"我想要一杯咖啡"}'
```

## App 连接方式

打包或运行 Flutter 时传入后端地址：

```bash
flutter run --dart-define=AI_TRANSLATION_API_BASE=http://localhost:8787
```

安卓真机不能直接访问电脑的 `localhost`。如果在同一 Wi-Fi 下测试，需要把地址换成电脑局域网 IP，例如：

```bash
flutter run --dart-define=AI_TRANSLATION_API_BASE=http://192.168.1.10:8787
```

正式给手机长期使用时，建议部署到支持 HTTPS 的云函数或轻量服务上。
