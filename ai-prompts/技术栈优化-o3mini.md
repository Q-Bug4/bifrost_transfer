# 虹桥 (Bifrost) 局域网文件传输助手 - 精简技术栈文档

## 核心功能模块依赖库清单

### 1. 用户界面层 (UI Layer)
- **UI 框架**: [Flutter](https://flutter.dev) (内置框架，无需额外库)
- **图标库** (可选):
  - `flutter_vector_icons`: 提供多种图标集（Font Awesome, Material Icons, Ionicons 等）
  - 或使用 Flutter 内置的 `Icons` 类（基本图标）
- **UI 动画** (可选): 
  - Flutter 内置动画框架（`AnimatedBuilder`, `TweenAnimationBuilder` 等）
- **提示与反馈**:
  - 内置组件：`SnackBar`, `AlertDialog`
  - 可选：`fluttertoast`（轻量级 Toast 提示）

### 2. 应用逻辑层 (Application Logic Layer)
- **状态管理** (选择其一):
  - `provider`: 官方推荐，易用
  - `riverpod`: 更强大，适合复杂状态
  - `flutter_bloc`: 适合复杂状态管理
- **文件选择**: `file_picker`
- **数据持久化**: 
  - `shared_preferences`: 简单的键值存储
- **数据库** (可选):
  - `sqflite`: SQLite 数据库（关系型）
  - `hive`: NoSQL 数据库（轻量级）
- **JSON 序列化/反序列化**:
  - `dart:convert`: 内置库，基础 JSON 处理
  - `json_serializable` 和 `build_runner`（可选，复杂结构生成代码）
- **日志** (可选): `logger` 或 `logging`

### 3. 网络通信层 (Network Communication Layer)
- **网络库**: `dart:io`（内置库，支持 Socket, HttpServer, HttpClient 等）
- **网络状态监听** (可选): `connectivity_plus`

### 4. 底层平台适配层 (Platform Adaptation Layer)
- **平台通道**: `flutter/services`（内置框架）
- **外部函数接口**: `dart:ffi`（内置库）
- **文件路径获取**: `path_provider`
- **权限处理**: `permission_handler`（或 `app_settings` 处理细粒度权限）

### 5. 其他常用库 (可选)
- **路由管理** (可选): 
  - `go_router`: 声明式路由，官方推荐
  - `auto_route`: 代码生成式路由
- **依赖注入** (可选):
  - `get_it`: 简单依赖注入
  - `injectable`: 依赖注入和代码生成
- **国际化** (可选):
  - `flutter_localizations`: Flutter 官方国际化框架
  - `intl`: 本地化库
- **测试**: `flutter_test`（Flutter 内置测试框架）

## 依赖管理工具
- **`pubspec.yaml` 和 `flutter pub get`**: Flutter 内置依赖管理，无需额外工具

## 总结
本技术栈文档列出了 "虹桥"（Bifrost）局域网文件传输助手项目的核心功能模块所推荐的 Dart/Flutter 库。您可以根据项目需求选择适合的库进行开发。大部分功能可以使用 Flutter 内置框架和 `dart:io` 库来实现，第三方库主要用于增强特定功能或提高开发效率。

**可选库说明**: 例如状态管理、数据库、路由管理等库，在小型项目中可选，不必强制使用；在中大型项目中，则有助于提升可维护性和可扩展性。
