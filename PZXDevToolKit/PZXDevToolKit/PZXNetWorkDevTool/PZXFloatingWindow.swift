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

    init() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            super.init(windowScene: scene)
        } else {
            super.init(frame: UIScreen.main.bounds)
        }
        
        self.backgroundColor = .clear
        self.windowLevel = .alert // 确保在最顶层
        self.frame = CGRect(x: UIScreen.main.bounds.width - size - margin,
                            y: UIScreen.main.bounds.height / 3,
                            width: size,
                            height: size)
        self.layer.cornerRadius = size / 2
        self.layer.masksToBounds = true

        setupFloatingView()
        addGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupFloatingView() {
        let floatingView = UIView(frame: self.bounds)
        floatingView.backgroundColor = .clear
        floatingView.layer.cornerRadius = size / 2
        floatingView.layer.masksToBounds = true
        self.addSubview(floatingView)
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
