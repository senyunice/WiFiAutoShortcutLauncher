# WiFi自动快捷指令启动器

一个iOS 15.0越狱插件，当iPhone连接到指定WiFi时自动运行快捷指令。

## 功能特性

- **WiFi自动检测** - 连接指定WiFi时自动触发快捷指令
- **多个规则** - 支持配置多个WiFi+快捷指令规则
- **时段控制** - 支持工作日/周末不同的时间规则
- **不生效时段** - 可设置禁止执行的时间段（如深夜）
- **失败通知** - 快捷指令运行失败时发送通知
- **中文界面** - 流畅的iOS原生风格设置界面

## 系统要求

- iOS 15.0 (支持多巴胺越狱)
- iPhone 13 Pro Max (兼容其他设备)
- 已安装Sileo

## 安装方法

### 方法一：直接安装deb（推荐）

1. 从GitHub Actions下载编译好的deb文件
2. 通过Sileo安装

### 方法二：自行编译

1. Fork此仓库
2. 触发GitHub Actions构建
3. 下载生成的deb文件
4. 通过Sileo安装

## 使用说明

1. 打开「设置」>「WiFi自动快捷指令启动器」
2. 开启插件总开关
3. 点击「添加规则」配置：
   - 选择WiFi网络（从历史记录或手动输入）
   - 选择要运行的快捷指令
   - 设置生效时段（始终/工作日/周末）
4. 设置工作日和周末的生效时间
5. 可选设置不生效时段

## 编译说明

### 使用GitHub Actions（免Mac）

1. Fork此仓库
2. 前往 Actions 页面
3. 点击 "Build Deb" 工作流
4. 点击 "Run workflow"
5. 等待构建完成后下载 deb 文件

### 本地编译（需要Mac + Theos）

```bash
# 安装Theos
brew install theos

# 克隆项目
git clone https://github.com/YOUR_USERNAME/WiFiAutoShortcutLauncher.git
cd WiFiAutoShortcutLauncher

# 编译
make
make package
```

## 项目结构

```
WiFiAutoShortcutLauncher/
├── Tweak.x                 # 主入口文件
├── Makefile               # Theos编译配置
├── control                # deb包信息
├── WiFiAutoShortcutLauncher.entitlements
├── WiFiWatcher.*          # WiFi检测模块
├── ShortcutsRunner.*      # 快捷指令执行模块
├── ConfigManager.*        # 配置管理模块
├── ScheduleManager.*      # 时段管理模块
├── WIFIRule.*             # 规则数据模型
├── RootViewController.*   # 主设置界面
├── WiFiRuleCell.*         # 规则单元格
├── SchedulePickerViewController.*  # 时段选择器
└── layout/                # deb安装布局
    ├── DEBIAN/
    └── Library/PreferenceLoader/Preferences/
```

## 权限说明

插件需要以下权限：
- `com.apple.developer.networking.HotspotHelper` - WiFi检测
- `com.apple.developer.networking.networkextension` - 网络扩展
- 后台运行模式

## 注意事项

- WiFi检测间隔为5秒
- 同一个WiFi触发后60秒内不会重复触发
- 快捷指令运行失败会发送通知，成功不通知
- 工作日=周一到周五，周末=周六周日

## 更新日志

### v1.0.0
- 初始版本
- 支持多WiFi规则
- 支持工作日/周末时段
- 支持不生效时段设置
