# PZXNetWorkDevTool

## 简介

PZXNetWorkDevTool 是一款轻量级的 iOS 调试工具，用于实时监控网络请求。它提供了一个浮动窗口，便于快速访问网络日志。

## 特性

- **实时网络请求监控**：捕获并展示应用中的每个网络请求。
- **浮动窗口**：提供便捷的浮动窗口，实时查看网络请求的详细信息。
- **详细日志信息**：显示请求方法、URL、状态码和响应时间，帮助快速定位问题。

## 安装

目前，您可以通过手动克隆该项目的代码库，并将文件添加到您的 iOS 项目中来使用 PZXNetWorkDevTool。

## 使用方法

### 在 `AppDelegate` 中初始化

为了启用网络监控，您需要在 `AppDelegate` 中初始化 PZXNetWorkDevTool。**请确保在应用发起第一次网络请求前调用 `setup()` 方法。**

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 启动网络监控工具
    PZXNetWorkDevTool.shared.setup()
    return true
}
```
## 许可证

本项目使用 [MIT 许可证](https://opensource.org/licenses/MIT)。具体内容请参阅项目中的 `LICENSE` 文件。

## 联系方式

如果您有任何问题或建议，欢迎提交 issue 或为项目贡献代码！
