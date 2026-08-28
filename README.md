<div align="center">
  <h1>📝 极简任务清单 (Minimalist Todo)</h1>
  <p>一款基于 Flutter 的跨平台极简任务清单应用，支持 Markdown 纯文本存储与全平台云盘同步。</p>

  <!-- Badges -->
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter Version" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20iOS%20%7C%20Android-4CAF50" alt="Platforms" />
  <img src="https://img.shields.io/badge/Storage-Markdown-black?logo=markdown" alt="Markdown Storage" />
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License" />
</div>

<br/>

## ✨ 核心特性 (Features)

- **🌱 极简主义设计**：界面干净无广告，超低内存占用，系统托盘常驻，随时呼出。
- **☁️ 数据完全掌控**：数据以标准 Markdown `.md` 文件格式保存在您指定的本地/云盘文件夹中（兼容 iCloud / OneDrive / Dropbox 等），可直接用 Obsidian 或 Typora 关联打开！
- **📅 自动任务流转**：拥有独立的日期系统，前一天未完成的今日任务会自动滚动累积到新的一天。
- **🎯 目标分解管理**：
  - **年度 / 月度目标**：独立的侧边栏全局展示，时刻保持大局观。
  - **日目标 (Focus)**：顶部高亮独立显示，每天专注最核心的一件事。
- **✅ 细节满满的反馈**：勾选任务后自动触发删除线动效，任务移至列表底部并自动记录**完成精确时间**。
- **⏰ 智能提醒系统**：
  - **截止提醒**：可为任务设定精确截止时间，并在该时间触发系统级本地通知。
  - **复盘提醒**：支持自定义每晚定时推送（如 21:00）提醒总结今天，规划明天。

---

## 🛠️ 技术栈 (Tech Stack)

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Desktop Support**: `window_manager`, `tray_manager` (跨平台系统托盘与窗口控制)
- **Notification**: `flutter_local_notifications` (多端本地通知)
- **Storage**: 本地文件系统 (无后端数据库依赖，纯 I/O 操作)

---

## 📂 数据结构 (Data Structure)

指向您的同步目录后，应用会自动构建如下的纯文本知识库：

```text
📁 <您的云盘同步目录>/
 ├── 📂 daily/
 │   ├── 📄 2026-08-27.md     # 每日任务记录
 │   └── 📄 2026-08-26.md
 └── 📂 goals/
     ├── 📄 year_2026.md      # 年度大目标
     └── 📄 month_2026_08.md  # 月度小目标
```

_示例 `daily/2026-08-27.md` 内容：_
```markdown
# 📅 2026-08-27

## 🎯 日目标
- [ ] 完成项目核心模块代码开发

## 📋 今日任务
- [ ] 参加团队周会 ⏰10:30
- [x] ~~查阅竞品分析报告~~ — 完成于 09:15
```

---

## 🚀 快速启动 (Getting Started)

### 1. 环境准备
确保您的设备已安装 [Flutter SDK](https://flutter.dev/docs/get-started/install)。
*对于 Windows 桌面端编译，您需要安装 Visual Studio 2022 Build Tools (含 C++ 桌面开发组件)。*

### 2. 获取代码
```bash
git clone https://github.com/jiawanh/TODOLIST.git
cd TODOLIST
flutter pub get
```

### 3. 运行与编译
```bash
# 调试运行 (Windows)
flutter run -d windows

# 打包发布版 (Windows)
flutter build windows --release
```
*(打包后的免安装执行文件位于 `build\windows\x64\runner\Release\todo_list.exe`)*

---

## ⚙️ 首次使用指南

1. 启动应用后，点击首页中心的 **「选择同步目录」**。
2. 在弹出的系统文件管理器中，选择一个安全且支持云同步的文件夹（例如 `D:\OneDrive\TodoList`）。
3. 选择完成后，应用会自动接管该文件夹，并为您创建今天的 Markdown 任务清单。
4. 点击右上角 ⚙️ 进入设置，可随时调整您的主题外观与通知推送规则。

---

## 📜 许可证 (License)

本项目采用 [MIT License](LICENSE) 开源，您可以自由地使用、修改和分发。
