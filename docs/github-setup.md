# GitHub 设置指南

本项目建议使用 GitHub private repository 进行备份和版本管理。项目会涉及 AI API 配置、个人录音、学习记录等敏感内容，不建议公开仓库。

## 当前状态

- 本地 Git 仓库已初始化。
- 默认分支为 `main`。
- 首次提交已完成。
- 尚未设置远程 GitHub 仓库。
- 当前环境未检测到 GitHub CLI (`gh`)。

## 推荐仓库设置

在 GitHub 新建仓库时：

- Repository name: `english-learning-app`
- Visibility: `Private`
- 不要勾选初始化 README、`.gitignore` 或 license，因为本地项目已经有这些文件。

## 配置 Git 身份

先为这个项目设置本地 Git 用户身份，避免影响电脑上的其他项目：

```bash
git config user.name "你的 GitHub 用户名"
git config user.email "你的 GitHub 邮箱"
```

如果使用 GitHub 隐私邮箱，可以在 GitHub 的 Email settings 中找到形如：

```text
12345678+username@users.noreply.github.com
```

## 连接远程仓库

在 GitHub 创建 private repo 后，复制仓库 SSH 或 HTTPS 地址。

推荐使用 SSH：

```bash
git remote add origin git@github.com:你的用户名/english-learning-app.git
git push -u origin main
```

如果使用 HTTPS：

```bash
git remote add origin https://github.com/你的用户名/english-learning-app.git
git push -u origin main
```

## 后续版本标签

每完成一个稳定阶段后打 tag：

```bash
git tag v0.1.0
git push origin v0.1.0
```

推荐版本节奏：

- `v0.1.0`: 项目定义与文档。
- `v0.2.0`: iOS 静态原型。
- `v0.3.0`: AI 听说闭环。
- `v0.4.0`: 兴趣内容系统。
- `v0.5.0`: 个人 Beta。
- `v1.0.0`: 稳定自用版。

## 不要提交的内容

以下内容必须保持在 Git 外：

- OpenAI API key。
- `.env` 和本地配置。
- 个人录音。
- 完整歌词、完整剧本、盗版字幕。
- 真实学习记录导出文件。
- Xcode 构建产物。

`.gitignore` 已包含这些常见规则。新增敏感文件类型时，应先更新 `.gitignore`，再创建文件。

