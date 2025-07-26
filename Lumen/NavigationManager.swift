//
//  NavigationManager.swift
//  AdvxProject1
//
//  Created by AI Assistant on 2025/7/25.
//

import Foundation
import SwiftUI

// MARK: - Navigation Manager
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    
    @Published var shouldNavigateToCamera = false
    @Published var shouldNavigateToBluetoothSettings = false
    
    private init() {}
    
    // 导航到相机功能
    func navigateToCamera() {
        shouldNavigateToCamera = true
    }
    
    // 导航到蓝牙设置
    func navigateToBluetoothSettings() {
        shouldNavigateToBluetoothSettings = true
    }
    
    // 重置导航状态
    func resetNavigation() {
        shouldNavigateToCamera = false
        shouldNavigateToBluetoothSettings = false
    }
}