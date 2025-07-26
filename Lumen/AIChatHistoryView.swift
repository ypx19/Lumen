//
//  AIChatHistoryView.swift
//  AdvxProject1
//
//  Created by 尤沛兴 on 2025/7/25.
//

import SwiftUI

struct AIChatHistoryView: View {
    let selectedTab: AppTab
    @StateObject private var cozeAPI = CozeAPIService.shared
    @State private var photoData: [PhotoData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedYear = "2025"
    @State private var selectedPhoto: PhotoData?
    
    let years = ["2023", "2024", "2025"]
    
    var body: some View {
        ZStack {
            // Liquid glass background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05),
                    Color.pink.opacity(0.08),
                    Color.cyan.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                    // Header with year picker
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI 助手")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.primary, .blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .white.opacity(0.8), radius: 2, x: 0, y: 1)
                            
                            Text("AI Assistant")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.secondary, .blue.opacity(0.7)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(0.8)
                        }
                        
                        Spacer()
                        
                        // Year Picker
                        Picker("年份", selection: $selectedYear) {
                            ForEach(years, id: \.self) { year in
                                Text(year).tag(year)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.2)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    if isLoading {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("加载中...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else if let error = errorMessage {
                        Spacer()
                        VStack(spacing: 16) {
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
                                loadPhotos()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.blue, .purple]),
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                        Spacer()
                    } else if photoData.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("暂无照片")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("该年份暂无 AI 助手记录")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        // Photo Grid
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(photoData) { photo in
                                    Button(action: {
                                        selectedPhoto = photo
                                    }) {
                                        PhotoCardView(photo: photo)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        .onAppear {
            loadPhotos()
        }
        .onChange(of: selectedYear) {
            loadPhotos()
        }
        .onChange(of: selectedTab) {
            // 每次切换到AI助手页面时重新加载数据
            if selectedTab == .aiAssistant {
                loadPhotos()
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            AIChatDetailView(photoData: photo)
        }
    }
    
    private func loadPhotos() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let photos = try await cozeAPI.getAIAssistantPhotosByYear(selectedYear)
                await MainActor.run {
                    photoData = photos
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct PhotoCardView: View {
    let photo: PhotoData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo
            AsyncImage(url: URL(string: photo.url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.2),
                                Color.purple.opacity(0.15),
                                Color.cyan.opacity(0.18)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    )
            }
            .frame(height: 140)
            .clipped()
            .cornerRadius(16)
            
            // Date with glass effect
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue.opacity(0.7))
                
                Text(photo.date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.secondary, .blue.opacity(0.6)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
                .shadow(color: .white.opacity(0.8), radius: 1, x: 0, y: 1)
        )
        .padding(4)
    }
}

#Preview {
    AIChatHistoryView(selectedTab: .aiAssistant)
}