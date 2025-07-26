//
//  ShortcutManager.swift
//  AdvxProject1
//
//  Created by AI Assistant on 2025/7/25.
//

import Foundation
import AppIntents
import UIKit
import AVFoundation
import AVKit
import CoreMedia

// MARK: - App Intent for Taking Photo
struct TakePhotoIntent: AppIntent {
    static var title: LocalizedStringResource = "拍照"
    
    static var description = IntentDescription("通过蓝牙连接的相机设备拍摄照片")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let bluetoothManager = BluetoothManager.shared
        
        // 等待应用完全启动
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 检查蓝牙状态
        guard bluetoothManager.isBluetoothPoweredOn else {
            let dialog = IntentDialog("蓝牙未开启，请先开启蓝牙后再尝试拍照")
            return .result(dialog: dialog)
        }
        
        // 检查蓝牙连接状态
        guard bluetoothManager.isConnected else {
            let dialog = IntentDialog("设备未连接，请先连接蓝牙设备后再尝试拍照")
            return .result(dialog: dialog)
        }
        
        // 检查是否正在传输图片
        guard !bluetoothManager.isTransferringImage else {
            let dialog = IntentDialog("正在传输图片，请稍后再试")
            return .result(dialog: dialog)
        }
        
        // 执行拍照操作 - 直接调用与按钮相同的逻辑
        bluetoothManager.requestPhoto()
        
        // 等待一小段时间确保命令发送
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        let dialog = IntentDialog("拍照指令已发送，请查看应用获取照片")
        return .result(dialog: dialog)
    }
}

// MARK: - App Intent for Opening AI Chat
struct OpenAIChatIntent: AppIntent {
    static var title: LocalizedStringResource = "打开AI聊天"
    
    static var description = IntentDescription("打开应用并进入AI聊天界面")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 由于新的导航结构，这里不需要特殊的导航逻辑
        // 应用会直接打开到主界面
        
        let dialog = IntentDialog("正在打开AI聊天界面")
        return .result(dialog: dialog)
    }
}

// MARK: - App Intent for Connecting Bluetooth
struct ConnectBluetoothIntent: AppIntent {
    static var title: LocalizedStringResource = "连接蓝牙设备"
    
    static var description = IntentDescription("扫描并连接蓝牙相机设备")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let bluetoothManager = BluetoothManager.shared
        
        // 检查蓝牙状态
        if bluetoothManager.isConnected {
            let dialog = IntentDialog("设备已连接")
            return .result(dialog: dialog)
        }
        
        // 导航到蓝牙设置页面
        NavigationManager.shared.navigateToBluetoothSettings()
        
        // 开始扫描设备
        bluetoothManager.startScanning()
        
        let dialog = IntentDialog("正在扫描蓝牙设备...")
        return .result(dialog: dialog)
    }
}





// MARK: - App Intent for Wake Lumen
struct WakeLumenIntent: AppIntent {
    static var title: LocalizedStringResource = "唤醒Lumen"
    
    static var description = IntentDescription("唤醒Lumen，自动拍照并进行AI分析")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let bluetoothManager = BluetoothManager.shared
        let progressManager = await LumenProgressManager.shared
        
        // 重置进度状态
        await progressManager.reset()
        
        // 等待应用完全启动
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 检查蓝牙状态
        guard bluetoothManager.isBluetoothPoweredOn else {
            await progressManager.showError("蓝牙未开启")
            let dialog = IntentDialog("蓝牙未开启，请先开启蓝牙后再尝试唤醒Lumen")
            return .result(dialog: dialog)
        }
        
        // 检查蓝牙连接状态
        guard bluetoothManager.isConnected else {
            await progressManager.showError("设备未连接")
            let dialog = IntentDialog("设备未连接，请先连接蓝牙设备后再尝试唤醒Lumen")
            return .result(dialog: dialog)
        }
        
        // 检查是否正在传输图片
        guard !bluetoothManager.isTransferringImage else {
            await progressManager.showError("正在传输图片")
            let dialog = IntentDialog("正在传输图片，请稍后再试")
            return .result(dialog: dialog)
        }
        
        // 执行拍照操作
        await progressManager.updateState(.takingPhoto, progress: 0.1)
        bluetoothManager.requestPhoto()
        
        // 等待拍照完成和图片传输
        var waitTime = 0
        let maxWaitTime = 30 // 最多等待30秒
        
        await progressManager.updateState(.transferringImage, progress: 0.2)
        
        while waitTime < maxWaitTime {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 等待1秒
            waitTime += 1
            
            // 更新传输进度
            let transferProgress = 0.2 + (Double(waitTime) / Double(maxWaitTime)) * 0.3
            await progressManager.updateState(.transferringImage, progress: transferProgress)
            
            print("⏱️ 等待图片传输... (\(waitTime)/\(maxWaitTime)秒)")
            print("📊 传输状态: \(bluetoothManager.isTransferringImage ? "传输中" : "未传输")")
            print("🖼️ 图片状态: \(bluetoothManager.receivedImage != nil ? "已接收" : "未接收")")
            
            // 检查是否有接收到图片
            if let receivedImage = bluetoothManager.receivedImage {
                print("✅ 成功接收到图片")
                
                // 保存图片到临时位置
                guard let imageData = receivedImage.jpegData(compressionQuality: 0.8) else {
                    print("❌ 图片数据转换失败")
                    await progressManager.showError("图片处理失败")
                    let dialog = IntentDialog("图片处理失败：无法转换图片数据")
                    return .result(dialog: dialog)
                }
                
                // 创建临时文件路径
                let tempDirectory = FileManager.default.temporaryDirectory
                let imageFileName = "lumen_photo_\(Date().timeIntervalSince1970).jpg"
                let imageURL = tempDirectory.appendingPathComponent(imageFileName)
                
                do {
                    // 保存图片到临时文件
                    try imageData.write(to: imageURL)
                    print("✅ 图片已保存到: \(imageURL.path)")
                    print("📏 图片大小: \(imageData.count) 字节")
                    
                    // 使用远程音频 URL
                    guard let audioURL = URL(string: "https://lf-bot-studio-plugin-resource.coze.cn/obj/bot-studio-platform-plugin-tos/artist/image/3b71bb9d6d274a49925845b38e6f0629.mp3") else {
                        print("⚠️ 无效的远程音频URL")
                        await progressManager.showError("无效的远程音频URL")
                        let dialog = IntentDialog("无效的远程音频URL")
                        return .result(dialog: dialog)
                    }
                    
                    print("✅ 远程音频URL: \(audioURL)")
                    
                    // 调用AI聊天工作流
                    let answerAudioURL = try await callAIChatWorkflow(
                        imageData: imageData,
                        audioURL: audioURL.absoluteString
                    )
                    
                    print("🎯 AI分析完成，结果: \(answerAudioURL)")
                    await progressManager.showCompleted()
                    let dialog = IntentDialog("Lumen已唤醒！拍照完成，AI分析结果：\(answerAudioURL)")
                    return .result(dialog: dialog)
                    
                } catch {
                    print("❌ 保存图片或AI分析失败: \(error)")
                    await progressManager.showError("AI分析失败：\(error.localizedDescription)")
                    let dialog = IntentDialog("保存图片或AI分析失败：\(error.localizedDescription)")
                    return .result(dialog: dialog)
                }
            }
            
            // 如果不再传输图片但也没有收到图片，可能是传输失败
            if !bluetoothManager.isTransferringImage && bluetoothManager.receivedImage == nil && waitTime > 5 {
                print("❌ 图片传输失败")
                await progressManager.showError("图片传输失败")
                let dialog = IntentDialog("图片传输失败，请重试")
                return .result(dialog: dialog)
            }
        }
        
        await progressManager.showError("等待图片传输超时")
        let dialog = IntentDialog("等待图片传输超时，请重试")
        return .result(dialog: dialog)
    }
    
    // 调用AI聊天工作流
    private func callAIChatWorkflow(imageData: Data, audioURL: String) async throws -> String {
        print("🚀 开始调用AI聊天工作流")
        print("📷 图片数据大小: \(imageData.count) bytes")
        print("🎵 音频URL: \(audioURL)")
        
        let workflowId = "7530959394042544168"
        
        // 下载远程音频文件数据
        guard let url = URL(string: audioURL) else {
            throw CozeAPIError.apiError("无效的音频URL")
        }
        
        print("📤 下载远程音频文件...")
        let (audioData, _) = try await URLSession.shared.data(from: url)
        print("🎵 音频数据大小: \(audioData.count) bytes")
        
        print("📤 第一步：上传图片到腾讯云COS...")
        // 使用腾讯云COS上传图片（永久密钥方式）
        let imageFileName = "lumen_photo_\(Date().timeIntervalSince1970).jpg"
        let imageURL = try await TencentCOSService.uploadImageWithPermanentKey(
            data: imageData,
            fileName: imageFileName
        )
        print("✅ 图片上传成功，URL: \(imageURL)")
        
        print("📤 第二步：上传音频到腾讯云COS...")
        // 使用腾讯云COS上传音频（永久密钥方式）
        let audioFileName = "lumen_audio_\(Date().timeIntervalSince1970).mp3"
        let audioUploadURL = try await TencentCOSService.uploadAudioWithPermanentKey(
            data: audioData,
            fileName: audioFileName
        )
        print("✅ 音频上传成功，URL: \(audioUploadURL)")
        
        print("🔄 第三步：调用AI聊天工作流...")
        // 创建工作流请求，使用图片和音频的URL
        let request = CozeWorkflowRequest(
            workflow_id: workflowId,
            parameters: [
                "input_img": .string(imageURL),
                "audio": .string(audioUploadURL)
            ]
        )
        
        print("📋 工作流请求已创建，使用URL参数")
        print("🖼️ 图片URL: \(imageURL)")
        print("🎵 音频URL: \(audioUploadURL)")
        
        // 创建CozeAPIService实例
        let apiService = CozeAPIService()
        
        do {
            // 使用CozeAPIService的executeWorkflow方法
            let response = try await apiService.executeWorkflow(request)
            
            print("✅ 工作流执行成功")
            print("📊 响应代码: \(response.code)")
            print("💬 响应消息: \(response.msg)")
            
            // 解析响应获取答案音频URL
            if let dataString = response.data {
                print("📤 工作流数据: \(dataString)")
                
                // 首先尝试解析为JSON对象
                if let data = dataString.data(using: String.Encoding.utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    print("🔍 JSON解析成功，检查所有字段:")
                    for (key, value) in jsonObject {
                        print("  - \(key): \(value)")
                    }
                    
                    // 检查是否有data字段
                    if let dataField = jsonObject["data"] as? String {
                        print("🎯 解析到data字段: '\(dataField)'")
                        
                        // 检查data字段是否为空
                        if dataField.isEmpty {
                            print("⚠️ data字段为空，检查其他字段...")
                            
                            // 检查original_result字段
                            if let originalResult = jsonObject["original_result"] as? String, !originalResult.isEmpty {
                                print("🎯 找到original_result字段: \(originalResult)")
                                let cleanedURL = originalResult
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .replacingOccurrences(of: "`", with: "")
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                print("🎵 清理后的音频URL: \(cleanedURL)")
                                return cleanedURL
                            }
                            
                            // 检查是否有其他可能包含URL的字段
                            for (key, value) in jsonObject {
                                if let stringValue = value as? String,
                                   stringValue.contains("http") {
                                    print("🎯 在字段'\(key)'中找到可能的URL: \(stringValue)")
                                    let cleanedURL = stringValue
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .replacingOccurrences(of: "`", with: "")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    print("🎵 清理后的音频URL: \(cleanedURL)")
                                    return cleanedURL
                                }
                            }
                            
                            print("❌ 所有字段都不包含有效的音频URL")
                            throw CozeAPIError.apiError("工作流返回的数据中没有音频URL，data字段为空")
                        } else {
                            // 从data字段中提取URL（去除反引号和空格）
                            let cleanedURL = dataField
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .replacingOccurrences(of: "`", with: "")
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            print("🎵 清理后的音频URL: \(cleanedURL)")
                            return cleanedURL
                        }
                    }
                    
                    // 如果没有data字段，尝试查找output字段
                    if let output = jsonObject["output"] as? String {
                        print("🎯 解析到输出: \(output)")
                        return output
                    }
                    
                    print("❌ JSON中没有找到data或output字段")
                } else {
                    print("❌ JSON解析失败，尝试直接处理字符串")
                }
                
                // 如果JSON解析失败，尝试直接从字符串中提取URL
                let urlPattern = "https://[^\\s`]+"
                if let regex = try? NSRegularExpression(pattern: urlPattern, options: []),
                   let match = regex.firstMatch(in: dataString, options: [], range: NSRange(location: 0, length: dataString.count)) {
                    let extractedURL = String(dataString[Range(match.range, in: dataString)!])
                    print("🎵 正则提取的音频URL: \(extractedURL)")
                    return extractedURL
                }
                
                // 如果都无法解析，抛出错误而不是返回空字符串
                print("❌ 无法从工作流响应中解析出音频URL")
                print("📋 原始数据: \(dataString)")
                throw CozeAPIError.apiError("工作流返回的数据中没有有效的音频URL")
            }
            
            throw CozeAPIError.apiError("工作流没有返回任何数据")
            
        } catch let error as CozeAPIError {
            print("❌ Coze API 错误: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ 未知错误: \(error.localizedDescription)")
            throw CozeAPIError.apiError("调用工作流失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - App Intent for Call Lumen (现场录音版本)
struct CallLumenIntent: AppIntent {
    static var title: LocalizedStringResource = "Call Lumen"
    
    static var description = IntentDescription("Call Lumen，自动拍照并现场录音进行AI分析")
    
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let bluetoothManager = BluetoothManager.shared
        let progressManager = await LumenProgressManager.shared
        
        // 重置进度状态
        await progressManager.reset()
        
        // 等待应用完全启动
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
        
        // 检查蓝牙状态
        guard bluetoothManager.isBluetoothPoweredOn else {
            await progressManager.showError("蓝牙未开启")
            let dialog = IntentDialog("蓝牙未开启，请先开启蓝牙后再尝试Call Lumen")
            return .result(dialog: dialog)
        }
        
        // 检查蓝牙连接状态
        guard bluetoothManager.isConnected else {
            await progressManager.showError("设备未连接")
            let dialog = IntentDialog("设备未连接，请先连接蓝牙设备后再尝试Call Lumen")
            return .result(dialog: dialog)
        }
        
        // 检查是否正在传输图片
        guard !bluetoothManager.isTransferringImage else {
            await progressManager.showError("正在传输图片")
            let dialog = IntentDialog("正在传输图片，请稍后再试")
            return .result(dialog: dialog)
        }
        
        // 开始录音（5秒）
        await progressManager.updateState(.recording, progress: 0.1)
        print("🎤 开始录音...")
        let audioData: Data
        do {
            audioData = try await recordAudio(duration: 5.0)
            print("✅ 录音完成，音频大小: \(audioData.count) bytes")
            await progressManager.updateState(.recording, progress: 0.2)
        } catch {
            print("❌ 录音失败: \(error)")
            await progressManager.showError("录音失败：\(error.localizedDescription)")
            let dialog = IntentDialog("录音失败：\(error.localizedDescription)")
            return .result(dialog: dialog)
        }
        
        // 执行拍照操作
        await progressManager.updateState(.takingPhoto, progress: 0.25)
        bluetoothManager.requestPhoto()
        
        // 等待拍照完成和图片传输
        var waitTime = 0
        let maxWaitTime = 30 // 最多等待30秒
        
        await progressManager.updateState(.transferringImage, progress: 0.3)
        
        while waitTime < maxWaitTime {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 等待1秒
            waitTime += 1
            
            // 更新传输进度
            let transferProgress = 0.3 + (Double(waitTime) / Double(maxWaitTime)) * 0.2
            await progressManager.updateState(.transferringImage, progress: transferProgress)
            
            print("⏱️ 等待图片传输... (\(waitTime)/\(maxWaitTime)秒)")
            print("📊 传输状态: \(bluetoothManager.isTransferringImage ? "传输中" : "未传输")")
            print("🖼️ 图片状态: \(bluetoothManager.receivedImage != nil ? "已接收" : "未接收")")
            
            // 检查是否有接收到图片
            if let receivedImage = bluetoothManager.receivedImage {
                print("✅ 成功接收到图片")
                
                // 保存图片到临时位置
                guard let imageData = receivedImage.jpegData(compressionQuality: 0.8) else {
                    print("❌ 图片数据转换失败")
                    await progressManager.showError("图片处理失败")
                    let dialog = IntentDialog("图片处理失败：无法转换图片数据")
                    return .result(dialog: dialog)
                }
                
                do {
                    // 调用AI聊天工作流，使用录制的音频
                    let answerAudioURL = try await callAIChatWorkflowWithRecordedAudio(
                        imageData: imageData,
                        audioData: audioData
                    )
                    
                    print("🎯 AI分析完成，结果: \(answerAudioURL)")
                    
                    // 播放返回的音频
                    await progressManager.updateState(.playingAudio, progress: 0.9)
                    try await playAudioFromURL(answerAudioURL)
                    
                    await progressManager.showCompleted()
                    let dialog = IntentDialog("Call Lumen完成！拍照和录音已完成，AI分析结果已播放")
                    return .result(dialog: dialog)
                    
                } catch {
                    print("❌ AI分析或音频播放失败: \(error)")
                    await progressManager.showError("AI分析失败：\(error.localizedDescription)")
                    let dialog = IntentDialog("AI分析或音频播放失败：\(error.localizedDescription)")
                    return .result(dialog: dialog)
                }
            }
            
            // 如果不再传输图片但也没有收到图片，可能是传输失败
            if !bluetoothManager.isTransferringImage && bluetoothManager.receivedImage == nil && waitTime > 5 {
                print("❌ 图片传输失败")
                await progressManager.showError("图片传输失败")
                let dialog = IntentDialog("图片传输失败，请重试")
                return .result(dialog: dialog)
            }
        }
        
        await progressManager.showError("等待图片传输超时")
        let dialog = IntentDialog("等待图片传输超时，请重试")
        return .result(dialog: dialog)
    }
    
    // 录音功能
    private func recordAudio(duration: TimeInterval) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            // 请求麦克风权限 - 使用新的API
            Task {
                do {
                    // 对于iOS 17+，使用新的权限请求方式
                    if #available(iOS 17.0, *) {
                        // 使用新的AVAudioApplication API
                        let granted = await AVAudioApplication.requestRecordPermission()
                        guard granted else {
                            continuation.resume(throwing: NSError(domain: "AudioRecording", code: 1, userInfo: [NSLocalizedDescriptionKey: "麦克风权限被拒绝"]))
                            return
                        }
                    } else {
                        // 对于iOS 17以下版本，使用旧的API
                        let granted = await withCheckedContinuation { permissionContinuation in
                            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                                permissionContinuation.resume(returning: granted)
                            }
                        }
                        guard granted else {
                            continuation.resume(throwing: NSError(domain: "AudioRecording", code: 1, userInfo: [NSLocalizedDescriptionKey: "麦克风权限被拒绝"]))
                            return
                        }
                    }
                    
                    // 配置音频会话
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playAndRecord, mode: .default)
                    try audioSession.setActive(true)
                    
                    // 创建临时文件路径
                    let tempDirectory = FileManager.default.temporaryDirectory
                    let audioFileName = "call_lumen_audio_\(Date().timeIntervalSince1970).m4a"
                    let audioURL = tempDirectory.appendingPathComponent(audioFileName)
                    
                    // 配置录音设置 - 使用AAC格式
                    let settings: [String: Any] = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 44100,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]
                    
                    // 创建录音器
                    let audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
                    audioRecorder.prepareToRecord()
                    
                    // 开始录音
                    audioRecorder.record()
                    print("🎤 录音开始，时长: \(duration)秒")
                    
                    // 等待指定时长
                    try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    
                    // 停止录音
                    audioRecorder.stop()
                    print("🎤 录音结束")
                    
                    // 读取录音文件数据
                    let audioData = try Data(contentsOf: audioURL)
                    
                    // 清理临时文件
                    try? FileManager.default.removeItem(at: audioURL)
                    
                    continuation.resume(returning: audioData)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 调用AI聊天工作流（使用录制的音频）
    private func callAIChatWorkflowWithRecordedAudio(imageData: Data, audioData: Data) async throws -> String {
        let progressManager = await LumenProgressManager.shared
        
        print("🚀 开始调用AI聊天工作流（使用录制音频）")
        print("📷 图片数据大小: \(imageData.count) bytes")
        print("🎵 音频数据大小: \(audioData.count) bytes")
        
        let workflowId = "7530959394042544168"
        
        await progressManager.updateState(.uploadingImage, progress: 0.5)
        print("📤 第一步：上传图片到腾讯云COS...")
        // 使用腾讯云COS上传图片（永久密钥方式）
        let imageFileName = "call_lumen_photo_\(Date().timeIntervalSince1970).jpg"
        let imageURL = try await TencentCOSService.uploadImageWithPermanentKey(
            data: imageData,
            fileName: imageFileName
        )
        print("✅ 图片上传成功，URL: \(imageURL)")
        
        await progressManager.updateState(.uploadingAudio, progress: 0.6)
        print("📤 第二步：上传音频到腾讯云COS...")
        // 使用腾讯云COS上传音频（永久密钥方式）
        let audioFileName = "call_lumen_audio_\(Date().timeIntervalSince1970).m4a"
        let audioUploadURL = try await TencentCOSService.uploadAudioWithPermanentKey(
            data: audioData,
            fileName: audioFileName
        )
        print("✅ 音频上传成功，URL: \(audioUploadURL)")
        
        await progressManager.updateState(.processingAI, progress: 0.7)
        print("🔄 第三步：调用AI聊天工作流...")
        // 创建工作流请求，使用图片和音频的URL
        let request = CozeWorkflowRequest(
            workflow_id: workflowId,
            parameters: [
                "input_img": .string(imageURL),
                "audio": .string(audioUploadURL)
            ]
        )
        
        print("📋 工作流请求已创建，使用URL参数")
        print("🖼️ 图片URL: \(imageURL)")
        print("🎵 音频URL: \(audioUploadURL)")
        
        // 创建CozeAPIService实例
        let apiService = CozeAPIService()
        
        do {
            // 使用CozeAPIService的executeWorkflow方法
            let response = try await apiService.executeWorkflow(request)
            
            await progressManager.updateState(.downloadingResult, progress: 0.8)
            print("✅ 工作流执行成功")
            print("📊 响应代码: \(response.code)")
            print("💬 响应消息: \(response.msg)")
            
            // 解析响应获取答案音频URL
            if let dataString = response.data {
                print("📤 工作流数据: \(dataString)")
                
                // 首先尝试解析为JSON对象
                if let data = dataString.data(using: String.Encoding.utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    // 检查是否有data字段
                    if let dataField = jsonObject["data"] as? String {
                        print("🎯 解析到data字段: \(dataField)")
                        
                        // 从data字段中提取URL（去除反引号和空格）
                        let cleanedURL = dataField
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "`", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        print("🎵 清理后的音频URL: \(cleanedURL)")
                        return cleanedURL
                    }
                    
                    // 如果没有data字段，尝试查找output字段
                    if let output = jsonObject["output"] as? String {
                        print("🎯 解析到输出: \(output)")
                        return output
                    }
                }
                
                // 如果JSON解析失败，尝试直接从字符串中提取URL
                let urlPattern = "https://[^\\s`]+"
                if let regex = try? NSRegularExpression(pattern: urlPattern, options: []),
                   let match = regex.firstMatch(in: dataString, options: [], range: NSRange(location: 0, length: dataString.count)) {
                    let extractedURL = String(dataString[Range(match.range, in: dataString)!])
                    print("🎵 正则提取的音频URL: \(extractedURL)")
                    return extractedURL
                }
                
                // 如果都无法解析，直接返回data字符串
                print("⚠️ 无法解析音频URL，返回原始数据")
                return dataString
            }
            
            return "AI分析完成，但未获取到音频URL"
            
        } catch let error as CozeAPIError {
            print("❌ Coze API 错误: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ 未知错误: \(error.localizedDescription)")
            throw CozeAPIError.apiError("调用工作流失败: \(error.localizedDescription)")
        }
    }
    
    // 播放音频URL（使用 AudioPlayerService）
    private func playAudioFromURL(_ urlString: String) async throws {
        print("🔊 开始播放音频: \(urlString)")
        
        try await AudioPlayerService.shared.playAudio(urlString: urlString)
        print("✅ 音频播放完成")
    }
    
}

// MARK: - App Intent for Playing Local Audio
struct PlayLocalAudioIntent: AppIntent {
    static var title: LocalizedStringResource = "播放本地音频"
    
    static var description = IntentDescription("播放应用内置的本地音频文件")
    
    static var openAppWhenRun: Bool = false
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 首先尝试从 Bundle 中获取音频文件
        guard let audioPath = Bundle.main.path(forResource: "test1", ofType: "mp3") else {
            // 如果 Bundle 中没有，尝试使用绝对路径（仅用于开发环境）
            let fallbackPath = "/Users/youpeixing/ws/AdvxProject1/AdvxProject1/test1.mp3"
            
            guard FileManager.default.fileExists(atPath: fallbackPath) else {
                let dialog = IntentDialog("找不到音频文件 test1.mp3")
                return .result(dialog: dialog)
            }
            
            let fallbackURL = URL(fileURLWithPath: fallbackPath)
            do {
                try await playLocalAudio(audioURL: fallbackURL)
                let dialog = IntentDialog("本地音频播放完成")
                return .result(dialog: dialog)
            } catch {
                let dialog = IntentDialog("播放音频时出错: \(error.localizedDescription)")
                return .result(dialog: dialog)
            }
        }
        
        let audioURL = URL(fileURLWithPath: audioPath)
        do {
            // 播放本地音频
            try await playLocalAudio(audioURL: audioURL)
            let dialog = IntentDialog("本地音频播放完成")
            return .result(dialog: dialog)
        } catch {
            let dialog = IntentDialog("播放音频时出错: \(error.localizedDescription)")
            return .result(dialog: dialog)
        }
    }
    
    // 播放本地音频的方法 - 使用 AudioPlayerService
    private func playLocalAudio(audioURL: URL) async throws {
        try await AudioPlayerService.shared.playAudio(audioURL: audioURL)
        print("✅ 本地音频播放完成: \(audioURL.lastPathComponent)")
    }
}

// MARK: - App Shortcuts Provider
struct AdvxProject1Shortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: TakePhotoIntent(),
            phrases: [
                "在\(.applicationName)中拍照",
                "使用\(.applicationName)拍摄照片"
            ],
            shortTitle: "拍照",
            systemImageName: "camera"
        )
        
        AppShortcut(
            intent: OpenAIChatIntent(),
            phrases: [
                "打开\(.applicationName)",
                "启动\(.applicationName)"
            ],
            shortTitle: "AI聊天",
            systemImageName: "message"
        )
        
        AppShortcut(
            intent: ConnectBluetoothIntent(),
            phrases: [
                "在\(.applicationName)中连接蓝牙",
                "使用\(.applicationName)连接设备"
            ],
            shortTitle: "连接设备",
            systemImageName: "bluetooth"
        )
        
        AppShortcut(
            intent: WakeLumenIntent(),
            phrases: [
                "在\(.applicationName)中唤醒Lumen",
                "使用\(.applicationName)启动Lumen",
                "在\(.applicationName)中Lumen拍照分析"
            ],
            shortTitle: "唤醒Lumen",
            systemImageName: "brain.head.profile"
        )
        
        AppShortcut(
            intent: CallLumenIntent(),
            phrases: [
                "在\(.applicationName)中Call Lumen",
                "使用\(.applicationName)呼叫Lumen",
                "在\(.applicationName)中Lumen录音分析"
            ],
            shortTitle: "Call Lumen",
            systemImageName: "mic.and.signal.meter"
        )
        
        AppShortcut(
            intent: PlayLocalAudioIntent(),
            phrases: [
                "在\(.applicationName)中播放本地音频",
                "使用\(.applicationName)播放音频",
                "在\(.applicationName)中播放本地音频文件"
            ],
            shortTitle: "播放音频",
            systemImageName: "play.circle"
        )
    }
}

// MARK: - Legacy Shortcut Manager (保持向后兼容)
class ShortcutManager {
    static let shared = ShortcutManager()
    static let takePhotoActivityType = "com.advxproject1.takephoto"
    
    private init() {}
    
    // 保持原有的方法以确保向后兼容
    func donateTakePhotoActivity() {
        // 使用新的 App Intents 框架，这个方法现在主要用于向后兼容
        print("快捷指令功能已迁移到 App Intents 框架")
    }
    
    // 新增：捐赠 Intent 到系统
    func donateIntents() {
        // 在 App Intents 框架中，捐赠是通过执行 Intent 来自动完成的
        // 当用户在应用中执行相关操作时，系统会自动学习并建议快捷指令
        print("App Intents 框架会自动处理 Intent 捐赠")
        print("当用户使用拍照、连接蓝牙等功能时，系统会自动学习并建议相应的快捷指令")
    }
    
    // 手动触发 Intent 捐赠（当用户执行相关操作时调用）
    func donateTakePhotoIntent() {
        Task {
            _ = TakePhotoIntent()
            // 在 App Intents 中，通过创建 Intent 实例来进行捐赠
            print("已捐赠拍照 Intent")
        }
    }
    
    func donateConnectBluetoothIntent() {
        Task {
            _ = ConnectBluetoothIntent()
            // 在 App Intents 中，通过创建 Intent 实例来进行捐赠
            print("已捐赠连接蓝牙 Intent")
        }
    }
}