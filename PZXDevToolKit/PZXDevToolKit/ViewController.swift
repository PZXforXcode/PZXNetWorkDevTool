import UIKit
import Alamofire

class ViewController: UIViewController {
    
    /// **持有 Session，避免被提前释放**
      private let session: Session = {
          let configuration = URLSessionConfiguration.default
          configuration.protocolClasses = [NetworkInterceptor.self] + (configuration.protocolClasses ?? [])
          return Session(configuration: configuration)
      }()
    
    private let testButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发起测试请求", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        setupTestButton()
    }
    
    private func setupTestButton() {
        view.addSubview(testButton)
        testButton.frame = CGRect(x: 50, y: 200, width: view.bounds.width - 100, height: 50)
        testButton.addTarget(self, action: #selector(testButtonTapped), for: .touchUpInside)
    }
    
    @objc private func testButtonTapped() {
//        // GET请求测试
//        makeGetRequest()
//        
//        // POST请求测试
//        makePostRequest()
        
        // Alamofire GET请求测试
        makeAFGetRequest()
        
        // Alamofire POST请求测试
        makeAFPostRequest()
    }
    
    private func makeGetRequest() {
        let urlString = "https://jsonplaceholder.typicode.com/posts/1"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data {
                print("GET Response: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }
        task.resume()
    }
    
    private func makePostRequest() {
        let urlString = "https://jsonplaceholder.typicode.com/posts"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "title": "测试标题",
            "body": "测试内容",
            "userId": 1
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            print("Error: \(error)")
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data {
                print("POST Response: \(String(data: data, encoding: .utf8) ?? "")")
            }
        }
        task.resume()
    }
    
    private func makeAFGetRequest() {
        
        let urlString = "https://jsonplaceholder.typicode.com/posts/1"
        AF.request(urlString).response { response in
            switch response.result {
            case .success(let value):
                print("AF GET Response: \(value)")
            case .failure(let error):
                print("AF GET Error: \(error)")
            }
        }
    }
    
    private func makeAFPostRequest() {
    
        
        let urlString = "https://jsonplaceholder.typicode.com/posts"
        let parameters: [String: Any] = [
            "title": "测试标题",
            "body": "测试内容",
            "userId": 1
        ]
        
        session.request(urlString, method: .post, parameters: parameters, encoding: JSONEncoding.default).response { response in
            switch response.result {
            case .success(let value):
                print("AF POST Response: \(value)")
            case .failure(let error):
                print("AF POST Error: \(error)")
            }
        }
    }
}
