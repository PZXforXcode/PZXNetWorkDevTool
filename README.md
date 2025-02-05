
# PZXNetWorkDevTool

## 介绍
`PZXNetWorkDevTool` 是一个轻量级 iOS 调试工具，用于实时监控网络请求。它提供了一个悬浮窗口，方便查看网络日志。

## 特性
- 实时监控网络请求
- 悬浮窗口，便捷访问
- 显示请求方法、URL、状态码和响应时间

## 安装
目前，你可以通过手动克隆仓库并将文件添加到你的项目中来使用 `PZXNetWorkDevTool`。

## 使用方法

### 1. 在 `AppDelegate` 中初始化
要启用网络监控，请在 `AppDelegate` 中初始化 `PZXNetWorkDevTool`：

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 启动网络监控工具
    PZXNetWorkDevTool.shared.setup()
    return true
}
```

### 2. 在 `SceneDelegate` 中显示悬浮窗口
如果你的应用支持多场景（iOS 13+），你还需要在 `SceneDelegate` 中初始化悬浮窗口：

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let _ = (scene as? UIWindowScene) else { return }
    
    // 初始化悬浮调试按钮
    PZXNetWorkDevTool.shared.showFloatingWindow()
}
```

## 许可证
本项目遵循 MIT 许可证。详情请查看 LICENSE 文件。

## 联系方式
如果你有任何问题或建议，欢迎提交 issue 或参与项目贡献！

