<p align="center">
  <img src="https://upload-images.jianshu.io/upload_images/19409325-519689bc90ffc96a.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/400" width="400"/>
  <img src="https://upload-images.jianshu.io/upload_images/19409325-98fcb7203098aa18.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/400" width="400"/>
  <img src="https://upload-images.jianshu.io/upload_images/19409325-b9f61f7525c69d9b.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/400" width="400"/>
</p>

[查看中文README文档](https://github.com/PZXforXcode/PZXNetWorkDevTool/blob/main/README_CN.md)

## PZXNetWorkDevTool

### Introduction

PZXNetWorkDevTool is a lightweight iOS debugging tool for real-time network request monitoring. It provides a floating window for easy access to network logs.

### Features

- Real-time network request monitoring
- Floating window for quick access
- Displays request method, URL, status code, and response time

### Installation

Currently

## PZXNetWorkDevTool

### Introduction

PZXNetWorkDevTool is a lightweight iOS debugging tool for real-time network request monitoring. It provides a floating window for easy access to network logs.

### Features

- Real-time network request monitoring
- Floating window for quick access
- Displays request method, URL, status code, and response time

### Installation

Currently, you can use PZXNetWorkDevTool by manually cloning the repository and adding the files to your project.

### Usage

#### Initialize in AppDelegate

To enable network monitoring, initialize PZXNetWorkDevTool in `AppDelegate`. **Make sure to call `setup()` before the first network request is made.**

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Start network monitoring tool
    PZXNetWorkDevTool.shared.setup()
    return true
}
```

### License

This project is licensed under the MIT License. See the LICENSE file for details.

### Contact

If you have any questions or suggestions, feel free to submit an issue or contribute to the project!

