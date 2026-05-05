# KeyLaunch

KeyLaunch 是一个 macOS 菜单栏应用，可以为已安装的 App 配置全局快捷键。按下配置好的快捷键后，KeyLaunch 会直接打开对应的 App。

## 功能

- 菜单栏常驻，无 Dock 图标
- 支持开机启动
- 支持添加、删除快捷键启动配置
- 支持录制快捷键
- 自动扫描 `/Applications` 和 `~/Applications` 中的 App
- 配置失效时会提示刷新 App 列表
- 配置数据本地保存

## 系统要求

- macOS 14 或更高版本
- Xcode 16 或更高版本

## 项目结构

```text
TinyLaunch
├── KeyLaunch
│   ├── App
│   │   └── KeyLaunchApp.swift
│   ├── Core
│   │   ├── AppDiscovery.swift
│   │   ├── ConfigStore.swift
│   │   ├── LaunchConfig.swift
│   │   └── LaunchConfigSanitizer.swift
│   └── Assets.xcassets
├── KeyLaunch.xcodeproj
├── Makefile
├── Package.resolved
└── README.md
```

## 打开项目

使用 Xcode 打开：

```bash
open KeyLaunch.xcodeproj
```

项目中只有一个 App target：`KeyLaunch`。

## 构建

本项目以 Xcode 工程为准进行构建。

```bash
make build-app
```

如果本机没有配置代码签名，可以使用：

```bash
make build-app CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO
```

构建产物位置：

```text
.build/DerivedData/Build/Products/Debug/KeyLaunch.app
```

## 运行

```bash
make run
```

## Archive

```bash
make archive
```

Archive 产物位置：

```text
dist/KeyLaunch.xcarchive
```

## 清理构建产物

```bash
make clean
```

## 使用方式

1. 启动 KeyLaunch 后，点击菜单栏图标。
2. 点击「配置」打开配置窗口。
3. 点击右上角加号新增一行配置。
4. 在快捷键区域录制快捷键。
5. 在 App 下拉列表中选择要打开的 App。
6. 之后按下该快捷键即可打开对应 App。

菜单栏菜单包含：

- `开机启动`
- `配置`
- `退出`

## 配置存储

配置文件保存在用户目录下的 Application Support：

```text
~/Library/Application Support/KeyLaunch/config.json
```

配置内容包含快捷键名称、App bundle id、App 显示名称和 App 路径。

## 依赖

项目使用 Swift Package Manager 解析 Xcode 依赖：

- KeyboardShortcuts
