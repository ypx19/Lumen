//
//  BluetoothConnectionView.swift
//  AdvxProject1
//
//  Created by AI Assistant on 2025/7/25.
//

import SwiftUI
import CoreBluetooth

struct BluetoothConnectionView: View {
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @State private var commandText = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid glass background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.08),
                        Color.purple.opacity(0.04),
                        Color.pink.opacity(0.06),
                        Color.cyan.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Connection Status Card
                        connectionStatusCard
                        
                        // Bluetooth Settings Guide (show when bluetooth is off)
                        if bluetoothManager.connectionStatus.contains("已关闭") || bluetoothManager.connectionStatus.contains("未开启") {
                            bluetoothSettingsGuideCard
                        }
                        
                        // Device List
                        if !bluetoothManager.discoveredDevices.isEmpty {
                            deviceListCard
                        }
                        
                        // Control Panel (only show when connected)
                        if bluetoothManager.isConnected {
                            controlPanelCard
                        }
                        
                        // Data Display (only show when connected)
                        if bluetoothManager.isConnected {
                            dataDisplayCard
                        }
                        
                        // 图片显示卡片
                        if bluetoothManager.isTransferringImage || bluetoothManager.receivedImage != nil {
                            imageDisplayCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // 当界面出现时，如果蓝牙可用且未连接，自动开始扫描
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !bluetoothManager.isConnected && !bluetoothManager.isScanning {
                    bluetoothManager.startScanning()
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("蓝牙连接")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.primary, .blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            Button(action: {
                if bluetoothManager.isConnected {
                    bluetoothManager.disconnect()
                } else {
                    bluetoothManager.startScanning()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: bluetoothManager.isConnected ? "wifi.slash" : "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(bluetoothManager.isConnected ? "断开连接" : (bluetoothManager.isScanning ? "扫描中..." : "开始扫描"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.3), .clear]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
            .disabled(bluetoothManager.isScanning)
        }
    }
    
    // MARK: - Connection Status Card
    private var connectionStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: bluetoothManager.isConnected ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(bluetoothManager.isConnected ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("连接状态")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(bluetoothManager.connectionStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if bluetoothManager.isScanning {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Shortcut Setup
    private func setupShortcut() {
        ShortcutManager.shared.donateTakePhotoActivity()
        showingAlert = true
        alertMessage = "快捷指令已设置！您可以在快捷指令应用中找到'拍照'功能。"
    }
    
    // MARK: - Bluetooth Settings Guide Card
    private var bluetoothSettingsGuideCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: bluetoothManager.connectionStatus.contains("权限") ? "lock.fill" : "wifi.slash")
                    .font(.system(size: 32))
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bluetoothManager.connectionStatus.contains("权限") ? "蓝牙权限未授权" : "蓝牙未开启")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(bluetoothManager.connectionStatus.contains("权限") ? "需要在设置中开启Lumen的蓝牙权限" : "需要开启蓝牙才能连接设备")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(bluetoothManager.connectionStatus.contains("权限") ? "开启权限步骤：" : "开启步骤：")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if bluetoothManager.connectionStatus.contains("权限") {
                    // 权限相关步骤
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("1.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("打开 iPhone 的\"设置\"应用")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("2.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("点击\"隐私与安全\"")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("3.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("点击\"蓝牙\"选项")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("4.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("找到\"Lumen\"应用并开启蓝牙权限")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("5.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("返回此应用重新扫描")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 12) {
                            Text("1.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("打开 iPhone 的\"设置\"应用")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("2.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("点击\"蓝牙\"选项")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("3.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("开启蓝牙开关")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("4.")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                            
                            Text("返回此应用重新扫描")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            Button(action: {
                // 尝试打开系统设置
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("打开设置")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.red, .orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.3), .clear]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.red.opacity(0.3), .orange.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .red.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Device List Card
    private var deviceListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("发现的设备")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                Button(action: {
                    bluetoothManager.connect(to: device)
                }) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.name ?? "未知设备")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text(device.identifier.uuidString)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Control Panel Card
    private var controlPanelCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("控制面板")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Command input
            VStack(alignment: .leading, spacing: 8) {
                Text("发送指令")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("输入指令...", text: $commandText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        if !commandText.isEmpty {
                            bluetoothManager.sendData(commandText)
                            commandText = ""
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                    .disabled(commandText.isEmpty)
                }
            }
            
            // Quick action buttons
            VStack(alignment: .leading, spacing: 8) {
                Text("快捷操作")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    // ESP32相机拍照按钮
                    Button(action: {
                        bluetoothManager.requestPhoto()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Text("拍照")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
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
                    .disabled(!bluetoothManager.isConnected || bluetoothManager.isTransferringImage)
                    
                    // 快捷指令设置按钮
                    Button(action: {
                        setupShortcut()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Text("快捷指令")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.orange, .red]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                    }
                    
                    quickActionButton(title: "录像", icon: "video", command: "RECORD")
                    quickActionButton(title: "停止", icon: "stop", command: "STOP")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Data Display Card
    private var dataDisplayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("接收数据")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView {
                Text(bluetoothManager.receivedData.isEmpty ? "暂无数据" : bluetoothManager.receivedData)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.05))
                    )
            }
            .frame(height: 120)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Quick Action Button
    private func quickActionButton(title: String, icon: String, command: String) -> some View {
        Button(action: {
            bluetoothManager.sendData(command)
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Image Display Card
    private var imageDisplayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("相机图片")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if bluetoothManager.isTransferringImage {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        
                        Text("\(Int(bluetoothManager.imageTransferProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let image = bluetoothManager.receivedImage {
                // 显示接收到的图片
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                
                // 图片信息
                VStack(alignment: .leading, spacing: 4) {
                    Text("图片信息")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("尺寸: \(Int(image.size.width)) × \(Int(image.size.height))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            // 保存图片到相册
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.caption)
                                Text("保存")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.05))
                )
            } else if bluetoothManager.isTransferringImage {
                // 传输进度显示
                VStack(spacing: 12) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("正在接收图片...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: bluetoothManager.imageTransferProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.05))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    BluetoothConnectionView()
}