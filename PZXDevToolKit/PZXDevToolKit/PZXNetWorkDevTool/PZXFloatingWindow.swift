//
//  PZXFloatingWindow.swift
//  PZXDevToolKit
//
//  Created by 彭祖鑫 on 2025/2/5.
//

import Foundation
import UIKit

class PZXFloatingWindow: UIWindow {

    private var panGesture: UIPanGestureRecognizer!
    private let size: CGFloat = 58
    private let margin: CGFloat = 10
    private var floatingButton: UIButton!

    init() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            super.init(windowScene: scene)
        } else {
            super.init(frame: UIScreen.main.bounds)
        }
        
        self.backgroundColor = .clear
        self.windowLevel = UIWindow.Level.statusBar + 100
        self.frame = CGRect(x: UIScreen.main.bounds.width - size - margin,
                            y: UIScreen.main.bounds.height / 3,
                            width: size,
                            height: size)
        self.layer.cornerRadius = size / 2
        self.layer.masksToBounds = true
        
        setupFloatingView()
        addGesture()
        
        // 监听键盘通知
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillShow),
                                             name: UIResponder.keyboardWillShowNotification,
                                             object: nil)
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(keyboardWillHide),
                                             name: UIResponder.keyboardWillHideNotification,
                                             object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(notification: Notification) {
        self.windowLevel = UIWindow.Level.statusBar + 100
    }
    
    @objc private func keyboardWillHide(notification: Notification) {
        self.windowLevel = UIWindow.Level.statusBar + 100
    }
    
    private func setupFloatingView() {
        floatingButton = UIButton(frame: bounds)
        floatingButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        floatingButton.layer.cornerRadius = size / 2
        floatingButton.layer.masksToBounds = true
        
        // 添加网络图标
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "network", withConfiguration: config)
        floatingButton.setImage(image, for: .normal)
        floatingButton.tintColor = .white
        
        // 添加点击事件
        floatingButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        self.addSubview(floatingButton)
    }
    
    @objc private func buttonTapped() {
        // 点击效果
        UIView.animate(withDuration: 0.1, animations: {
            self.floatingButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.floatingButton.transform = .identity
            }
        }
        
        // 如果未显示，则显示网络请求列表
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyWindow = windowScene.windows.first {
            let listVC = NetworkRequestListViewController()
            let nav = UINavigationController(rootViewController: listVC)
            nav.modalPresentationStyle = .fullScreen
            keyWindow.rootViewController?.present(nav, animated: true)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // 扩大点击区域
        let enlargedBounds = bounds.insetBy(dx: -10, dy: -10)
        return enlargedBounds.contains(point)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let button = super.hitTest(point, with: event) {
            return button
        }
        if bounds.insetBy(dx: -10, dy: -10).contains(point) {
            return floatingButton
        }
        return nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGesture)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let screen = self.screen
        let superview = screen.bounds
        let safeAreaInsets = self.safeAreaInsets

        let translation = gesture.translation(in: self)
        self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
        gesture.setTranslation(.zero, in: self)

        if gesture.state == .ended {
            var finalX: CGFloat
            let screenWidth = superview.width

            // 计算吸附位置
            if self.center.x < screenWidth / 2 {
                finalX = margin + size / 2  // 吸附左边
            } else {
                finalX = screenWidth - margin - size / 2 // 吸附右边
            }

            // 计算 Y 轴边界，预留安全区域
            let topLimit = safeAreaInsets.top + margin + size / 2  // 预留安全区
            let bottomLimit = superview.height - margin - size / 2
            var finalY = self.center.y

            if finalY < topLimit { finalY = topLimit }
            if finalY > bottomLimit { finalY = bottomLimit }

            UIView.animate(withDuration: 0.3) {
                self.center = CGPoint(x: finalX, y: finalY)
            }
        }
    }
}
