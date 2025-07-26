//
//  SettingsView.swift
//  Lumen
//
//  Created by Assistant on 2025/1/27.
//

import SwiftUI
import CoreBluetooth

struct SettingsView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @State private var showBluetoothPermissionAlert = false
    @State private var showSystemSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced Liquid glass background
                ZStack {
                    // Base gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.15),
                            Color.purple.opacity(0.12),
                            Color.pink.opacity(0.14),
                            Color.cyan.opacity(0.11),
                            Color.indigo.opacity(0.09)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Animated radial gradients
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.08),
                            Color.clear
                        ]),
                        center: .topTrailing,
                        startRadius: 100,
                        endRadius: 400
                    )
                    
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.06),
                            Color.clear
                        ]),
                        center: .bottomLeading,
                        startRadius: 150,
                        endRadius: 500
                    )
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple, .cyan]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("设置")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.primary, .blue]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.top, 20)
                        
                        // Bluetooth Settings Section
                        SettingsSection(title: "蓝牙设置", icon: "antenna.radiowaves.left.and.right") {
                            VStack(spacing: 16) {
                                // Bluetooth Permission Status
                                BluetoothPermissionRow()
                                
                                Divider()
                                    .background(.white.opacity(0.3))
                                
                                // Bluetooth Connection Status
                                BluetoothConnectionRow()
                                
                                Divider()
                                    .background(.white.opacity(0.3))
                                
                                // Manual Permission Button
                                BluetoothManualPermissionRow()
                            }
                        }
                        
                        // App Information Section
                        SettingsSection(title: "应用信息", icon: "info.circle") {
                            VStack(spacing: 16) {
                                SettingsRow(
                                    title: "版本",
                                    value: "1.0.0",
                                    icon: "app.badge"
                                )
                                
                                Divider()
                                    .background(.white.opacity(0.3))
                                
                                SettingsRow(
                                    title: "构建版本",
                                    value: "1",
                                    icon: "hammer"
                                )
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            
            // Section Content
            VStack(spacing: 0) {
                content
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .white.opacity(0.15),
                                        .clear,
                                        .blue.opacity(0.08)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        .white.opacity(0.4),
                                        .white.opacity(0.1),
                                        .clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
            .shadow(color: .blue.opacity(0.1), radius: 25, x: 0, y: 0)
        }
    }
}

struct BluetoothPermissionRow: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(
                        bluetoothManager.bluetoothAuthorizationStatus == "已授权" ?
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .mint]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [.orange, .red]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: bluetoothManager.bluetoothAuthorizationStatus == "已授权" ? "checkmark" : "exclamationmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("蓝牙权限状态")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(bluetoothManager.bluetoothAuthorizationStatus)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if bluetoothManager.bluetoothAuthorizationStatus != "已授权" {
                Button(action: {
                    openSystemSettings()
                }) {
                    Text("设置")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.blue.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.blue.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
        }
    }
    
    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct BluetoothConnectionRow: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Connection Icon
            ZStack {
                Circle()
                    .fill(
                        bluetoothManager.isConnected ?
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .mint]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [.gray, .secondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: bluetoothManager.isConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("连接状态")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(bluetoothManager.isConnected ? "已连接" : "未连接")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if bluetoothManager.isConnected {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("设备名称")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(bluetoothManager.connectedDeviceName ?? "未知设备")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}

struct BluetoothManualPermissionRow: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @State private var showAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Manual Permission Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "hand.raised")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("手动权限请求")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(bluetoothManager.needsManualPermission ? "需要手动授权" : "自动权限管理")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                if bluetoothManager.needsManualPermission {
                    showAlert = true
                } else {
                    bluetoothManager.requestBluetoothPermission()
                }
            }) {
                Text(bluetoothManager.needsManualPermission ? "授权" : "请求权限")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
        }
        .alert("蓝牙权限", isPresented: $showAlert) {
            Button("取消", role: .cancel) { }
            Button("前往设置") {
                openSystemSettings()
            }
        } message: {
            Text("请前往：设置 > 隐私与安全 > 蓝牙，找到Lumen应用并开启蓝牙权限。")
        }
    }
    
    private func openSystemSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.gray.opacity(0.3), .secondary.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}