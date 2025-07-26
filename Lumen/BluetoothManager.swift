//
//  BluetoothManager.swift
//  AdvxProject1
//
//  Created by AI Assistant on 2025/7/25.
//

import Foundation
import CoreBluetooth
import Combine
import UIKit

class BluetoothManager: NSObject, ObservableObject {
    // 单例实例
    static let shared = BluetoothManager()
    
    // ESP32控制板的服务和特征UUID
    private let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    private let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    
    // 蓝牙相关属性
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var characteristic: CBCharacteristic?
    
    // 图片传输相关属性
    @Published var isReceivingImage = false
    private var imageData = Data()
    private var expectedImageSize: Int = 0
    private var imageWidth: Int = 0
    private var imageHeight: Int = 0
    
    // 发布的状态属性
    @Published var isConnected = false
    @Published var isScanning = false
    @Published var receivedData = ""
    @Published var connectionStatus = "未连接"
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var receivedImage: UIImage?
    @Published var imageTransferProgress: Float = 0.0
    @Published var isTransferringImage = false
    
    // 蓝牙状态检查
    var isBluetoothPoweredOn: Bool {
        return centralManager.state == .poweredOn
    }
    
    // 检查蓝牙权限状态
    var bluetoothAuthorizationStatus: String {
        switch centralManager.state {
        case .unauthorized:
            return "未授权"
        case .poweredOff:
            return "已关闭"
        case .poweredOn:
            return "已开启"
        case .resetting:
            return "重置中"
        case .unsupported:
            return "不支持"
        case .unknown:
            return "未知"
        @unknown default:
            return "未知状态"
        }
    }
    
    // 是否需要用户手动设置权限
    var needsManualPermission: Bool {
        return centralManager.state == .unauthorized
    }
    
    override private init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // 开始扫描设备
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            switch centralManager.state {
            case .poweredOff:
                connectionStatus = "系统蓝牙已关闭 - 请在设置 > 蓝牙中开启"
            case .unauthorized:
                connectionStatus = "蓝牙权限未授权 - 请在设置 > 隐私与安全 > 蓝牙中开启Lumen的蓝牙权限"
            default:
                connectionStatus = "蓝牙不可用"
            }
            return
        }
        
        isScanning = true
        connectionStatus = "正在扫描设备..."
        discoveredDevices.removeAll()
        
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        // 10秒后停止扫描
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.stopScanning()
        }
    }
    
    // 停止扫描
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
        if !isConnected {
            connectionStatus = discoveredDevices.isEmpty ? "未发现设备" : "扫描完成"
        }
    }
    
    // 连接到指定设备
    func connect(to peripheral: CBPeripheral) {
        self.peripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        connectionStatus = "正在连接..."
    }
    
    // 断开连接
    func disconnect() {
        guard let peripheral = peripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // 发送数据到ESP32
    func sendData(_ data: String) {
        guard let characteristic = characteristic,
              let peripheral = peripheral,
              peripheral.state == .connected else {
            print("设备未连接或特征不可用")
            return
        }
        
        let dataToSend = Data(data.utf8)
        peripheral.writeValue(dataToSend, for: characteristic, type: .withResponse)
    }
    
    // 请求拍照
    func requestPhoto() {
        guard isConnected else {
            print("设备未连接，无法拍照")
            return
        }
        
        // 重置图片传输状态
        resetImageTransfer()
        
        // 发送拍照指令
        sendData("SNAP")
        print("已发送拍照请求")
        
        // 捐赠拍照 Intent 到系统
        ShortcutManager.shared.donateTakePhotoIntent()
    }
    
    // 请求蓝牙权限
    func requestBluetoothPermission() {
        // 重新初始化CBCentralManager来触发权限请求
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // 如果蓝牙已经开启，尝试开始扫描来触发权限检查
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.centralManager.state == .poweredOn {
                self.startScanning()
            }
        }
    }
    
    // 获取连接设备名称
    var connectedDeviceName: String? {
        return peripheral?.name
    }
    
    // 重置图片传输状态
    private func resetImageTransfer() {
        isReceivingImage = false
        imageData.removeAll()
        expectedImageSize = 0
        imageWidth = 0
        imageHeight = 0
        imageTransferProgress = 0.0
        isTransferringImage = false
        receivedImage = nil
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "蓝牙已开启，可以开始扫描"
        case .poweredOff:
            connectionStatus = "系统蓝牙已关闭 - 请在设置 > 蓝牙中开启"
        case .resetting:
            connectionStatus = "蓝牙重置中"
        case .unauthorized:
            connectionStatus = "蓝牙权限未授权 - 请在设置 > 隐私与安全 > 蓝牙中开启Lumen的蓝牙权限"
        case .unsupported:
            connectionStatus = "设备不支持蓝牙"
        case .unknown:
            connectionStatus = "蓝牙状态未知"
        @unknown default:
            connectionStatus = "未知状态"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // 检查是否是ESP32设备
        if let name = peripheral.name, name.contains("ESP32") {
            if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                discoveredDevices.append(peripheral)
                print("发现设备: \(name)")
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        connectionStatus = "已连接到 \(peripheral.name ?? "未知设备")"
        peripheral.discoverServices([serviceUUID])
        stopScanning()
        
        // 捐赠连接蓝牙 Intent 到系统
        ShortcutManager.shared.donateConnectBluetoothIntent()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectionStatus = "连接失败: \(error?.localizedDescription ?? "未知错误")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectionStatus = "连接已断开"
        self.peripheral = nil
        self.characteristic = nil
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else {
            print("发现服务失败: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("发现特征失败: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                self.characteristic = characteristic
                // 订阅通知
                peripheral.setNotifyValue(true, for: characteristic)
                print("已订阅特征通知")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("读取数据失败: \(error!.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else { return }
        
        // 尝试解析为字符串
        if let receivedString = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedData = receivedString
                print("收到数据: \(receivedString)")
            }
            
            // 处理图片传输协议
            handleImageTransferData(receivedString, rawData: data)
        } else {
            // 如果不是字符串，可能是图片数据
            handleImageData(data)
        }
    }
    
    // 处理图片传输数据
    private func handleImageTransferData(_ dataString: String, rawData: Data) {
        if dataString.hasPrefix("IMG:") {
            // 解析图片头信息: IMG:SIZE:WIDTH:HEIGHT
            let components = dataString.components(separatedBy: ":")
            if components.count >= 4 {
                expectedImageSize = Int(components[1]) ?? 0
                imageWidth = Int(components[2]) ?? 0
                imageHeight = Int(components[3]) ?? 0
                
                print("开始接收图片: 大小=\(expectedImageSize) bytes, 尺寸=\(imageWidth)x\(imageHeight)")
                
                DispatchQueue.main.async {
                    self.isReceivingImage = true
                    self.isTransferringImage = true
                    self.imageTransferProgress = 0.0
                }
            }
        } else if dataString == "END" {
            // 图片传输结束
            print("图片传输完成，总共接收 \(imageData.count) bytes")
            processReceivedImage()
        } else if !isReceivingImage {
            // 普通文本数据
            print("收到普通数据: \(dataString)")
        }
    }
    
    // 处理图片数据块
    private func handleImageData(_ data: Data) {
        if isReceivingImage {
            imageData.append(data)
            
            // 更新进度
            let progress = expectedImageSize > 0 ? Float(imageData.count) / Float(expectedImageSize) : 0.0
            DispatchQueue.main.async {
                self.imageTransferProgress = min(progress, 1.0)
            }
            
            print("接收图片数据: \(imageData.count)/\(expectedImageSize) bytes (进度: \(Int(progress * 100))%)")
            
            // 检查是否已接收完所有数据（备用完成判断）
            if expectedImageSize > 0 && imageData.count >= expectedImageSize {
                print("⚠️ 基于数据大小判断图片传输完成（可能缺少END信号）")
                processReceivedImage()
            }
            // 如果进度达到97%以上，启动超时检查
            else if progress >= 0.97 {
                print("📊 传输进度达到97%，启动完成检查...")
                // 延迟2秒后检查是否需要强制完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.isReceivingImage && self.imageData.count > 0 {
                        let currentProgress = self.expectedImageSize > 0 ? Float(self.imageData.count) / Float(self.expectedImageSize) : 0.0
                        if currentProgress >= 0.95 {
                            print("⚠️ 传输可能卡住，强制完成图片处理")
                            self.processReceivedImage()
                        }
                    }
                }
            }
        }
    }
    
    // 处理接收到的完整图片
    private func processReceivedImage() {
        guard imageData.count > 0 else {
            print("没有接收到图片数据")
            return
        }
        
        print("🔄 开始处理接收到的图片数据...")
        print("📊 实际接收: \(imageData.count) bytes")
        print("📊 预期大小: \(expectedImageSize) bytes")
        print("📊 完成度: \(expectedImageSize > 0 ? String(format: "%.1f", Float(imageData.count) / Float(expectedImageSize) * 100) : "未知")%")
        
        // 尝试创建UIImage
        if let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.receivedImage = image
                self.isReceivingImage = false
                self.isTransferringImage = false
                self.imageTransferProgress = 1.0
                print("✅ 图片解析成功！尺寸: \(image.size)")
            }
        } else {
            print("❌ 图片数据解析失败，尝试修复...")
            
            // 尝试修复JPEG数据
            let repairedData = repairJPEGData(imageData)
            if let image = UIImage(data: repairedData) {
                DispatchQueue.main.async {
                    self.receivedImage = image
                    self.isReceivingImage = false
                    self.isTransferringImage = false
                    self.imageTransferProgress = 1.0
                    print("✅ 修复后图片解析成功！尺寸: \(image.size)")
                }
            } else {
                print("❌ 图片数据修复失败")
                DispatchQueue.main.async {
                    self.isReceivingImage = false
                    self.isTransferringImage = false
                }
            }
        }
    }
    
    // 尝试修复不完整的JPEG数据
    private func repairJPEGData(_ data: Data) -> Data {
        var repairedData = data
        
        // JPEG文件应该以0xFFD8开始，以0xFFD9结束
        let jpegStart: [UInt8] = [0xFF, 0xD8]
        let jpegEnd: [UInt8] = [0xFF, 0xD9]
        
        // 检查是否有正确的开始标记
        if data.count >= 2 {
            let startBytes = Array(data.prefix(2))
            if startBytes != jpegStart {
                print("⚠️ JPEG开始标记不正确，尝试修复...")
                repairedData = Data(jpegStart) + data
            }
        }
        
        // 检查是否有正确的结束标记
        if repairedData.count >= 2 {
            let endBytes = Array(repairedData.suffix(2))
            if endBytes != jpegEnd {
                print("⚠️ JPEG结束标记缺失，添加结束标记...")
                repairedData.append(contentsOf: jpegEnd)
            }
        }
        
        return repairedData
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("写入数据失败: \(error.localizedDescription)")
        } else {
            print("数据写入成功")
        }
    }
}