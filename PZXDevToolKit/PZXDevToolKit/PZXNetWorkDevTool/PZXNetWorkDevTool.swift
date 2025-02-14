import UIKit
import Alamofire

// MARK: - NetworkRequest Model
public struct NetworkRequestModel {
    let identifier: String
    let url: String
    let method: String
    let requestHeaders: [String: String]
    let requestBody: String?
    let responseHeaders: [String: String]
    let responseBody: String?
    let statusCode: Int
    let timestamp: Date
    let duration: TimeInterval
    
    var isSuccess: Bool {
        return (200...299).contains(statusCode)
    }
}

// MARK: - NetworkMonitor
private class NetworkMonitor {
    static let shared = NetworkMonitor()
    private init() {}
    
    private var requests: [NetworkRequestModel] = []
    private var startTimes: [String: Date] = [:]
    
    func startRequest(identifier: String) {
        startTimes[identifier] = Date()
    }
    
    func addRequest(_ request: NetworkRequestModel) {
        requests.append(request)
        NotificationCenter.default.post(name: .newNetworkRequest, object: request)
    }
    
    func getAllRequests() -> [NetworkRequestModel] {
        return requests
    }
    
    func clearRequests() {
        requests.removeAll()
        startTimes.removeAll()
    }
}

// MARK: - NetworkInterceptor
 class NetworkInterceptor: URLProtocol {
    private static let requestIdKey = "NetworkInterceptorRequestIDKey"
    private var dataTask: URLSessionDataTask?
    private var receivedData: NSMutableData?
    private var startTime: Date?
    private var responseData: (response: URLResponse?, data: Data?)?
    
    override class func canInit(with request: URLRequest) -> Bool {
        // 避免重复拦截
        if URLProtocol.property(forKey: requestIdKey, in: request) != nil {
            return false
        }
        
        // 确保拦截所有HTTP/HTTPS请求
        guard let url = request.url,
              
              let scheme = url.scheme?.lowercased() else { return false }
        return ["http", "https"].contains(scheme)
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let identifier = UUID().uuidString
        let mutableRequest = (request as NSURLRequest).mutableCopy() as! NSMutableURLRequest
        URLProtocol.setProperty(true, forKey: NetworkInterceptor.requestIdKey, in: mutableRequest)
        
        startTime = Date()
        receivedData = NSMutableData()
        NetworkMonitor.shared.startRequest(identifier: identifier)
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session.dataTask(with: mutableRequest as URLRequest)
        dataTask?.resume()
    }
    
    override func stopLoading() {
        dataTask?.cancel()
    }
    
    private func processResponse() {
        guard let startTime = startTime,
              let response = responseData?.response as? HTTPURLResponse,
              let url = request.url?.absoluteString,
              let method = request.httpMethod else {
            return
        }
        
        // 获取请求头
        let requestHeaders = request.allHTTPHeaderFields ?? [:]
        
        // 获取请求体
        var requestBody: String?
        if let httpBody = request.httpBody {
            requestBody = formatData(httpBody)
        }
        
        // 获取响应头
        let responseHeaders = response.allHeaderFields as? [String: String] ?? [:]
        
        // 获取响应体
        var responseBody: String?
        if let data = responseData?.data {
            responseBody = formatData(data)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        let requestModel = NetworkRequestModel(
            identifier: UUID().uuidString,
            url: url,
            method: method,
            requestHeaders: requestHeaders,
            requestBody: requestBody,
            responseHeaders: responseHeaders,
            responseBody: responseBody,
            statusCode: response.statusCode,
            timestamp: startTime,
            duration: duration
        )
        
        NetworkMonitor.shared.addRequest(requestModel)
    }
    
    private func formatData(_ data: Data) -> String? {
        // 尝试解析为JSON
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        
        // 如果不是JSON，尝试解析为字符串
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - NetworkInterceptor URLSession Delegate
extension NetworkInterceptor: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
        receivedData?.append(data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        responseData = (response: response, data: nil)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            responseData?.data = receivedData as Data?
            processResponse()
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let newNetworkRequest = Notification.Name("newNetworkRequest")
}

public class PZXNetWorkDevTool {
    
    // MARK: - Singleton
    public static let shared = PZXNetWorkDevTool()
    var floatingWindow: PZXFloatingWindow?
    
    private init() {
        NotificationCenter.default.addObserver(
            forName: UIWindowScene.willConnectNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                if notification.object is UIWindowScene {
                    self?.showFloatingWindow()
                }
            }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func showFloatingWindow() {
    #if DEBUG
        // 如果floatingWindow已经存在且不为nil，就不再创建新的
        if floatingWindow == nil {
            floatingWindow = PZXFloatingWindow()
            floatingWindow?.isHidden = false
        }
    #endif
    }
    
    // MARK: - Public Methods
    public func setup() {
    #if DEBUG
        setupNetworkInterceptor()
    #endif
    }
    
    // MARK: - Private Methods
    private func setupNetworkInterceptor() {
        URLProtocol.registerClass(NetworkInterceptor.self)
        
        let config = URLSessionConfiguration.default
        config.protocolClasses = [NetworkInterceptor.self] + (config.protocolClasses ?? [])
        
        URLSession.shared.configuration.protocolClasses = [NetworkInterceptor.self] + (URLSession.shared.configuration.protocolClasses ?? [])
        URLSessionConfiguration.default.protocolClasses = [NetworkInterceptor.self] + (URLSessionConfiguration.default.protocolClasses ?? [])
        URLSessionConfiguration.ephemeral.protocolClasses = [NetworkInterceptor.self] + (URLSessionConfiguration.ephemeral.protocolClasses ?? [])
        
        swizzleProtocolSetterMethod()
    }
    
    private func swizzleProtocolSetterMethod() {
        guard let originalMethod = class_getInstanceMethod(URLSessionConfiguration.self, #selector(setter: URLSessionConfiguration.protocolClasses)),
              let swizzledMethod = class_getInstanceMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.swizzled_setProtocolClasses(_:))) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    // MARK: - Public Methods
    public func getAllRequests() -> [NetworkRequestModel] {
        return NetworkMonitor.shared.getAllRequests()
    }
    
    public func clearRequests() {
        NetworkMonitor.shared.clearRequests()
    }
}


// MARK: - NetworkRequestListViewController
class NetworkRequestListViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private var requests: [NetworkRequestModel] = []
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    private lazy var emptyView: UIView = {
        let view = UIView()
        view.isHidden = true
        
        let imageView = UIImageView(image: UIImage(systemName: "network.slash"))
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = "暂无网络请求"
        label.textColor = .systemGray2
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        // 设置约束
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 50),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "网络请求列表"
        view.backgroundColor = .white
        
        // 设置导航栏
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "清除",
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(clearRequests))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "关闭",
                                                         style: .plain,
                                                         target: self,
                                                         action: #selector(dismissSelf))
        
        // 设置tableView
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NetworkRequestCell.self, forCellReuseIdentifier: "RequestCell")
        view.addSubview(tableView)
        
        // 添加空数据视图
        emptyView.frame = view.bounds
        emptyView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(emptyView)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleNewRequest),
                                             name: .newNetworkRequest,
                                             object: nil)
    }
    
    // MARK: - Data
    private func loadData() {
        let newRequests = Array(NetworkMonitor.shared.getAllRequests().reversed())
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.requests = newRequests
            self.updateEmptyViewVisibility()
            self.tableView.reloadData()
        }
    }
    
    private func updateEmptyViewVisibility() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.emptyView.isHidden = !self.requests.isEmpty
            self.tableView.isHidden = self.requests.isEmpty
        }
    }
    
    @objc private func handleNewRequest() {
        loadData()
    }
    
    @objc private func clearRequests() {
        let alertController = UIAlertController(
            title: "确认清除",
            message: "是否清除所有网络请求记录？",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        let confirmAction = UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            NetworkMonitor.shared.clearRequests()
            self?.loadData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        
        present(alertController, animated: true)
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

// MARK: - NetworkRequestListViewController TableView
extension NetworkRequestListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return requests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! NetworkRequestCell
        let request = requests[indexPath.row]
        cell.configure(with: request, dateFormatter: dateFormatter)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let request = requests[indexPath.row]
        let detailVC = NetworkRequestDetailViewController(request: request)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: - NetworkRequestCell

private class NetworkRequestCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let methodLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.textColor = .white
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()
    
    private let urlLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(methodLabel)
        contentView.addSubview(urlLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(timeLabel)
        
        methodLabel.translatesAutoresizingMaskIntoConstraints = false
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // methodLabel (左上角)
            methodLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            methodLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            methodLabel.widthAnchor.constraint(equalToConstant: 60),
            methodLabel.heightAnchor.constraint(equalToConstant: 25),
            
            // urlLabel (methodLabel 右侧)
            urlLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            urlLabel.leadingAnchor.constraint(equalTo: methodLabel.trailingAnchor, constant: 10),
            urlLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            
            // statusLabel (methodLabel 下方)
            statusLabel.topAnchor.constraint(equalTo: methodLabel.bottomAnchor, constant: 5),
            statusLabel.leadingAnchor.constraint(equalTo: methodLabel.leadingAnchor),
            statusLabel.widthAnchor.constraint(equalToConstant: 60),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            
            // timeLabel (statusLabel 右侧)
            timeLabel.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 5),
            timeLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 10),
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -15),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

        ])
    }
    
    // MARK: - Configuration
    func configure(with request: NetworkRequestModel, dateFormatter: DateFormatter) {
        methodLabel.text = request.method
        urlLabel.text = request.url
        
        // 设置状态码颜色
        statusLabel.text = "\(request.statusCode)"
        statusLabel.textColor = request.isSuccess ? .systemGreen : .systemRed
        
        timeLabel.text = dateFormatter.string(from: request.timestamp)
        
        // 设置方法标签样式
        methodLabel.backgroundColor = methodColor(for: request.method)
    }
    
    private func methodColor(for method: String) -> UIColor {
        switch method.uppercased() {
        case "GET": return .systemBlue
        case "POST": return .systemGreen
        case "PUT": return .systemOrange
        case "DELETE": return .systemRed
        default: return .systemGray
        }
    }
}


// MARK: - NetworkRequestDetailViewController
private class NetworkRequestDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let request: NetworkRequestModel
    private let textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.backgroundColor = .systemBackground
        return textView
    }()
    
    // MARK: - Initialization
    init(request: NetworkRequestModel) {
        self.request = request
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        displayRequestDetails()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "请求详情"
        view.backgroundColor = .systemBackground
        
        textView.frame = view.bounds
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(textView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(shareRequest))
    }
    
    // MARK: - Display
    private func displayRequestDetails() {
        let attributedString = NSMutableAttributedString()
        
        // 定义样式
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.systemBlue
        ]
        
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.label
        ]
        
        let separatorAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.secondaryLabel
        ]
        
        // URL
        attributedString.append(NSAttributedString(string: "URL", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(request.url)\n\n", attributes: contentAttributes))
        
        // Method
        attributedString.append(NSAttributedString(string: "请求方法", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(request.method)\n\n", attributes: contentAttributes))
        
        // Status Code
        let statusColor: UIColor = request.isSuccess ? .systemGreen : .systemRed
        let statusAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: statusColor
        ]
        attributedString.append(NSAttributedString(string: "状态码", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(request.statusCode)\n\n", attributes: statusAttributes))
        
        // Duration
        attributedString.append(NSAttributedString(string: "耗时", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(String(format: "%.2f", request.duration))秒\n\n", attributes: contentAttributes))
        
        // Time
        attributedString.append(NSAttributedString(string: "时间", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(request.timestamp)\n\n", attributes: contentAttributes))
        
        // Request Headers
        attributedString.append(NSAttributedString(string: "请求头", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(formatDictionary(request.requestHeaders))\n\n", attributes: contentAttributes))
        
        // Request Body
        attributedString.append(NSAttributedString(string: "请求体", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(request.requestBody ?? "无")\n\n", attributes: contentAttributes))
        
        // Response Headers
        attributedString.append(NSAttributedString(string: "响应头", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(formatDictionary(request.responseHeaders))\n\n", attributes: contentAttributes))
        
        // Response Body
        attributedString.append(NSAttributedString(string: "响应体", attributes: titleAttributes))
        attributedString.append(NSAttributedString(string: "\n", attributes: separatorAttributes))
        attributedString.append(NSAttributedString(string: "\(request.responseBody ?? "无")", attributes: contentAttributes))
        
        textView.attributedText = attributedString
    }
    
    private func formatDictionary(_ dict: [String: String]) -> String {
        guard !dict.isEmpty else { return "无" }
        return dict.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
    }
    
    // MARK: - Actions
    @objc private func shareRequest() {
        let text = textView.attributedText.string
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}

// MARK: - URLSessionConfiguration Extension
private extension URLSessionConfiguration {
    @objc dynamic func swizzled_setProtocolClasses(_ protocolClasses: [AnyClass]?) {
        // 确保我们的拦截器总是在列表中
        var classes = protocolClasses ?? []
        if !classes.contains(where: { $0 is NetworkInterceptor.Type }) {
            classes.insert(NetworkInterceptor.self, at: 0)
        }
        self.swizzled_setProtocolClasses(classes)
    }
}




