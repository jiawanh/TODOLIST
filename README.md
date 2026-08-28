# 极简任务清单 (Todo List)

一款跨平台、极低内存占用的任务清单，以 **Markdown** 格式存储数据，支持通过云盘文件夹在多设备间同步。

## 功能

- 📅 **日期系统**：随时查看历史任务
- 🎯 **日目标**：置顶独立卡片，重点突出
- 📋 **今日任务**：未完成任务自动从昨日累积
- 🏆 **年/月目标**：侧边栏独立展示
- ✅ **完成动效**：点击圆圈 → 删除线 → 移至底部 + 记录时间
- ⏰ **截止提醒**：为每个任务设置截止时间，到时推送通知
- 🔔 **晚间提醒**：每晚自定义时间提醒制定明日计划
- 🌙 **深色/浅色主题**：跟随系统
- 🗂️ **系统托盘常驻**：桌面端最小化后超低内存后台运行
- ☁️ **云盘互通**：指向 OneDrive/iCloud Drive/Dropbox 本地文件夹即可跨设备同步

## 数据格式

任务以标准 Markdown 保存，可用 Obsidian / Typora / VS Code 直接打开：

```markdown
# 📅 2026-08-27

## 🎯 日目标
- [ ] 完成项目提案

## 📋 今日任务
- [ ] 回复邮件 ⏰18:00
- [x] ~~晨跑 30 分钟~~ — 完成于07:32
```

## 文件结构

```
<同步目录>/
├── daily/
│   ├── 2026-08-27.md
│   └── 2026-08-26.md
└── goals/
    ├── year_2026.md
    └── month_2026_08.md
```

## 构建与运行

### 前置要求

- Flutter SDK 3.x（已解压至 `C:\flutter_sdk\flutter`）
- Windows：Visual Studio 2022 Build Tools（含 C++ 桌面开发）
- Android：Android Studio（可选）

### 运行

```powershell
# Windows
$env:PATH = "C:\flutter_sdk\flutter\bin;$env:PATH"
flutter run -d windows

# 构建 release 版本
flutter build windows --release
```

### 首次启动

1. 点击「选择同步目录」，选择云盘的本地同步文件夹（如 OneDrive 中的一个文件夹）
2. 任务数据将自动保存为 `.md` 文件
3. 在设置中配置通知时间和提醒选项
