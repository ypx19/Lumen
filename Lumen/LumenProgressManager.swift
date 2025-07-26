//
//  LumenProgressManager.swift
//  AdvxProject1
//
//  Created by AI Assistant on 2025/1/27.
//

import Foundation
import SwiftUI

// MARK: - 进度状态枚举
enum LumenProgressState: String, CaseIterable {
    case idle = "待机"
    case recording = "正在录音..."
    case takingPhoto = "正在拍照..."
    case transferringImage = "正在传输图片..."
    case uploadingImage = "正在上传图片..."
    case uploadingAudio = "正在上传音频..."
    case processingAI = "正在请求AI分析..."
    case downloadingResult = "正在获取分析结果..."
    case playingAudio = "正在播放音频..."
    case completed = "完成"
    case error = "错误"
    
    var icon: String {
        switch self {
        case .idle:
            return "moon.zzz"
        case .recording:
            return "mic.fill"
        case .takingPhoto:
            return "camera.fill"
        case .transferringImage:
            return "arrow.down.circle.fill"
        case .uploadingImage:
            return "icloud.and.arrow.up.fill"
        case .uploadingAudio:
            return "waveform.and.mic"
        case .processingAI:
            return "brain.head.profile.fill"
        case .downloadingResult:
            return "arrow.down.to.line.circle.fill"
        case .playingAudio:
            return "speaker.wave.3.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .idle:
            return .gray
        case .recording, .takingPhoto, .transferringImage, .uploadingImage, .uploadingAudio, .processingAI, .downloadingResult, .playingAudio:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}

// MARK: - 进度管理器
@MainActor
class LumenProgressManager: ObservableObject {
    static let shared = LumenProgressManager()
    
    @Published var currentState: LumenProgressState = .idle
    @Published var isVisible: Bool = false
    @Published var errorMessage: String = ""
    @Published var progress: Double = 0.0 // 0.0 到 1.0
    
    private init() {}
    
    // 更新进度状态
    func updateState(_ state: LumenProgressState, progress: Double = 0.0) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentState = state
            self.progress = progress
            
            if state != .idle && state != .completed && state != .error {
                self.isVisible = true
            }
        }
    }
    
    // 显示错误
    func showError(_ message: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentState = .error
            self.errorMessage = message
            self.isVisible = true
        }
        
        // 3秒后自动隐藏错误
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.hide()
        }
    }
    
    // 显示完成状态
    func showCompleted() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.currentState = .completed
            self.progress = 1.0
            self.isVisible = true
        }
        
        // 2秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hide()
        }
    }
    
    // 隐藏进度显示
    func hide() {
        withAnimation(.easeInOut(duration: 0.3)) {
            self.isVisible = false
            self.currentState = .idle
            self.errorMessage = ""
            self.progress = 0.0
        }
    }
    
    // 重置状态
    func reset() {
        currentState = .idle
        isVisible = false
        errorMessage = ""
        progress = 0.0
    }
}

// MARK: - 进度显示视图
struct LumenProgressView: View {
    @StateObject private var progressManager = LumenProgressManager.shared
    
    var body: some View {
        if progressManager.isVisible {
            VStack(spacing: 16) {
                // 图标和状态文本
                HStack(spacing: 12) {
                    Image(systemName: progressManager.currentState.icon)
                        .font(.title2)
                        .foregroundColor(progressManager.currentState.color)
                        .scaleEffect(progressManager.currentState == .error ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: progressManager.currentState)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(progressManager.currentState.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if !progressManager.errorMessage.isEmpty {
                            Text(progressManager.errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                }
                
                // 进度条（仅在非错误和非完成状态时显示）
                if progressManager.currentState != .error && 
                   progressManager.currentState != .completed && 
                   progressManager.currentState != .idle {
                    ProgressView(value: progressManager.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: progressManager.currentState.color))
                        .scaleEffect(y: 2.0)
                }
                
                // 关闭按钮
                HStack {
                    Spacer()
                    Button("关闭") {
                        progressManager.hide()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 20)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - 进度显示修饰符
struct LumenProgressModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                LumenProgressView()
                Spacer()
            }
            .zIndex(1000)
        }
    }
}

extension View {
    func withLumenProgress() -> some View {
        modifier(LumenProgressModifier())
    }
}