# RctTool

![Static Badge](https://img.shields.io/badge/flutter-3.24.1-blue)
![GitHub commit activity](https://img.shields.io/github/commit-activity/w/richuff/RcTool)
[![XERJ Corpus Hub contributor](https://hub.xerj.org/contributors/richuff/badge.svg)](https://hub.xerj.org/contributors/richuff)

## Getting Started

### 安装 Flutter

1. 访问 [Flutter 官方网站](https://docs.flutter.dev/) 下载并安装 Flutter SDK。
2. 配置环境变量，确保 `flutter` 命令可以在终端中使用。
3. 运行 `flutter doctor` 检查安装状态并解决可能的依赖问题。

### 克隆项目

```bash
git clone https://github.com/richuff/RcTool.git
cd rctool
```

### 运行项目

1. 确保已连接设备或启动模拟器。
2. 运行以下命令启动应用：

```bash
flutter run
```

### 依赖管理

项目使用 `pubspec.yaml` 文件管理依赖项。添加或更新依赖后，运行以下命令：

```bash
flutter pub get
```

## 文档

更详细的开发、架构、数据库与 Live2D 设计文档请查看 [`docs/`](docs/README.md) 目录：

- [开发入门](docs/01-getting-started.md)
- [整体架构](docs/02-architecture.md)
- [功能模块](docs/03-features.md)
- [数据库设计](docs/04-database.md)
- [Live2D 集成](docs/05-live2d.md)

## 资源链接

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Get 官方文档](https://pub.dev/packages/get)

## 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 项目到你的仓库。
2. 创建一个新的分支：`git checkout -b feature/your-feature`
3. 提交你的更改：`git commit -m "Add some feature"`
4. 推送分支到远程仓库：`git push origin feature/your-feature`
5. 提交 Pull Request

## 许可证

本项目采用 MIT 许可证，详情请参阅 [LICENSE](LICENSE) 文件。
