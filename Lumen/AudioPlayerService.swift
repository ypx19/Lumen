//
//  AudioPlayerService.swift
//  AdvxProject1
//
//  Created by AI Assistant on 2025/7/26.
//

import Foundation
import AVFoundation
import AVKit

class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()
    
    @Published var player: AVPlayer?
    @Published var isPlaying = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // 播放本地音频
    func playLocalAudio() async throws {
        // 清除之前的错误信息
        await MainActor.run {
            errorMessage = nil
        }
        
        // 从Bundle中获取音频文件
        guard let audioPath = Bundle.main.path(forResource: "test1", ofType: "mp3") else {
            await MainActor.run {
                errorMessage = "找不到音频文件 test1.mp3"
            }
            print("找不到音频文件")
            throw AudioPlayerError.fileNotFound("找不到音频文件 test1.mp3")
        }
        
        let url = URL(fileURLWithPath: audioPath)
        try await playAudio(audioURL: url)
    }
    
    // 播放远程音频
    func playRemoteAudio() async throws {
        // 使用示例远程音频URL
        guard let url = URL(string: "https://lf-bot-studio-plugin-resource.coze.cn/obj/bot-studio-platform-plugin-tos/artist/image/3b71bb9d6d274a49925845b38e6f0629.mp3") else {
            await MainActor.run {
                errorMessage = "无效的远程音频URL"
            }
            throw AudioPlayerError.invalidURL("无效的远程音频URL")
        }
        
        try await playAudio(audioURL: url)
    }
    
    // 播放指定URL的音频
    func playAudio(audioURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                do {
                    // 配置音频会话
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    self.player = AVPlayer(url: audioURL)
                    
                    // 添加播放结束监听
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: self.player?.currentItem,
                        queue: .main
                    ) { _ in
                        self.isPlaying = false
                        print("🔊 音频播放完成")
                        continuation.resume()
                    }
                    
                    // 开始播放
                    self.player?.play()
                    self.isPlaying = true
                    print("开始播放音频: \(audioURL)")
                    
                } catch {
                    self.errorMessage = "播放音频时出错: \(error.localizedDescription)"
                    print("播放音频时出错: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 播放指定URL字符串的音频
    func playAudio(urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            await MainActor.run {
                errorMessage = "无效的音频URL: \(urlString)"
            }
            throw AudioPlayerError.invalidURL("无效的音频URL: \(urlString)")
        }
        
        try await playAudio(audioURL: url)
    }
    
    // 停止播放
    func stopAudio() {
        player?.pause()
        player = nil
        isPlaying = false
        errorMessage = nil
    }
}

// 音频播放错误类型
enum AudioPlayerError: LocalizedError {
    case fileNotFound(String)
    case invalidURL(String)
    case playbackError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let message):
            return message
        case .invalidURL(let message):
            return message
        case .playbackError(let message):
            return message
        }
    }
}