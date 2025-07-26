//
//  AIChatDetailView.swift
//  AdvxProject1
//
//  Created by 尤沛兴 on 2025/7/25.
//

import SwiftUI

struct AIChatDetailView: View {
    let photoData: PhotoData
    @StateObject private var cozeAPI = CozeAPIService.shared
    @State private var chatDetail: ChatDetailData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text("AI 助手详情")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 24, height: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 16)
                
                if isLoading {
                    Spacer()
                    ProgressView("加载聊天详情...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("加载失败")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("重试") {
                            loadChatDetail()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Photo Display
                            AsyncImage(url: URL(string: photoData.url)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .overlay(
                                        ProgressView()
                                            .scaleEffect(1.2)
                                    )
                            }
                            .frame(maxHeight: 300)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 20)
                            
                            // Date
                            Text(photoData.date)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                            
                            if let detail = chatDetail {
                                // Question Section
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                        
                                        Text("问题")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if !detail.questionUrl.isEmpty {
                                            Button(action: {
                                                playAudio(url: detail.questionUrl)
                                            }) {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    
                                    Text(detail.question)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                        .padding(.leading, 32)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                                .padding(.horizontal, 20)
                                
                                // Answer Section
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "brain.head.profile")
                                            .font(.system(size: 20))
                                            .foregroundColor(.green)
                                        
                                        Text("AI 回答")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if !detail.answerUrl.isEmpty {
                                            Button(action: {
                                                playAudio(url: detail.answerUrl)
                                            }) {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.green)
                                            }
                                        }
                                    }
                                    
                                    Text(detail.answer)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                        .padding(.leading, 32)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadChatDetail()
        }
    }
    
    private func loadChatDetail() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let detail = try await cozeAPI.getChatDetail(imageUrl: photoData.url)
                await MainActor.run {
                    self.chatDetail = detail
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func playAudio(url: String) {
        // TODO: 实现音频播放功能
        print("播放音频: \(url)")
    }
}

#Preview {
    AIChatDetailView(photoData: PhotoData(
        url: "https://example.com/photo.jpg",
        date: "7月24日 10:34",
        tag: "示例",
        text: "这是一张示例图片"
    ))
}