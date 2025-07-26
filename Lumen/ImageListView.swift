import SwiftUI

struct ImageListView: View {
    @StateObject private var cozeAPI = CozeAPIService.shared
    @State private var photoData: [PhotoData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedYear = "2024"
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.pink.opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 标题和控制区域
                    VStack(spacing: 16) {
                        // 主标题
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("数字孪生")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Digital Twin")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // 年份选择器
                            Picker("年份", selection: $selectedYear) {
                                ForEach(2020...2024, id: \.self) { year in
                                    Text("\(year)年").tag("\(year)")
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
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
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // 内容区域
                    if isLoading {
                        Spacer()
                        VStack(spacing: 16) {
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
                            
                            Text("该年份暂无数字孪生记录")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        // 瀑布流布局
                        GeometryReader { geometry in
                            ScrollView {
                                WaterfallLayout(photoData: photoData, screenWidth: geometry.size.width)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 100)
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadPhotos()
        }
        .onChange(of: selectedYear) { _ in
            loadPhotos()
        }
    }
    
    private func loadPhotos() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let photos = try await cozeAPI.getDigitalTwinPhotosByYear(selectedYear)
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

// 瀑布流布局视图
struct WaterfallLayout: View {
    let photoData: [PhotoData]
    let screenWidth: CGFloat
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(photoData.enumerated()), id: \.element.id) { index, photo in
                        GeometryReader { itemGeometry in
                            let globalFrame = itemGeometry.frame(in: .global)
                            let screenHeight = UIScreen.main.bounds.height
                            let screenCenter = screenHeight / 2
                            let itemCenter = globalFrame.midY
                            let distance = abs(itemCenter - screenCenter)
                            let maxDistance = screenHeight * 0.6 // 调整影响范围
                            let normalizedDistance = min(distance / maxDistance, 1.0)
                            
                            // 使用更平滑的缩放曲线
                            let smoothDistance = 1.0 - pow(normalizedDistance, 0.8)
                            let scale = 0.7 + (smoothDistance * 0.3) // 范围从0.7到1.0
                            let opacity = 0.5 + (smoothDistance * 0.5) // 范围从0.5到1.0
                            
                            // 计算旋转角度，增加3D效果
                            let rotationAngle = (normalizedDistance * 8) * (index % 2 == 0 ? 1 : -1)
                            
                            NavigationLink(destination: PhotoDetailView(photoData: photo)) {
                                OptimizedWaterfallCard(
                                    photoData: photo,
                                    index: index,
                                    scale: scale,
                                    opacity: opacity,
                                    rotationAngle: rotationAngle
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .scaleEffect(scale)
                            .opacity(opacity)
                            .rotation3DEffect(
                                .degrees(rotationAngle),
                                axis: (x: 1, y: 0, z: 0)
                            )
                            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: scale)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: opacity)
                            .animation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0), value: rotationAngle)
                        }
                        .frame(height: getOptimizedCardHeight(for: index))
                        .id(index)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .coordinateSpace(name: "scroll")
        }
    }
    
    // 优化的卡片高度算法，更自然的瀑布流效果
    private func getOptimizedCardHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 350 // 增加基础高度以容纳更多信息
        let variations: [CGFloat] = [80, -40, 60, -20, 40, -60, 100, -30]
        let variationIndex = index % variations.count
        let height = baseHeight + variations[variationIndex]
        
        // 添加一些随机性，但保持一致性
        let seed = Double(index * 37) // 使用固定种子确保一致性
        let randomFactor = sin(seed) * 20
        
        return max(height + randomFactor, 250) // 确保最小高度
    }
}

// 优化的瀑布流卡片
struct OptimizedWaterfallCard: View {
    let photoData: PhotoData
    let index: Int
    let scale: Double
    let opacity: Double
    let rotationAngle: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 图片上方的信息区域
            VStack(alignment: .leading, spacing: 12) {
                // 日期信息
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text(photoData.date)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // 标签信息
                if !photoData.tag.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple.opacity(0.8))
                        
                        Text(photoData.tag)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.purple.opacity(0.15),
                                                Color.blue.opacity(0.1)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .foregroundColor(.purple.opacity(0.9))
                        
                        Spacer()
                    }
                }
                
                // 文本描述
                if !photoData.text.isEmpty {
                    Text(photoData.text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.blue.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            
            // 图片区域
            ZStack {
                // 主图像容器
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.1 * opacity),
                                Color.purple.opacity(0.05 * opacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // 主图像
                        AsyncImage(url: URL(string: photoData.url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .clipped()
                        } placeholder: {
                            ZStack {
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.3 * opacity),
                                        Color.purple.opacity(0.2 * opacity),
                                        Color.pink.opacity(0.1 * opacity)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(opacity)))
                                    .scaleEffect(scale * 0.8)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                
                // 增强的光效层
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.15 * opacity * scale),
                                Color.blue.opacity(0.08 * opacity * scale),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .blendMode(.overlay)
                
                // 动态边框效果
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3 * opacity),
                                Color.blue.opacity(0.2 * opacity),
                                Color.purple.opacity(0.1 * opacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2 * scale
                    )
            }
            .frame(height: 200) // 固定图片区域高度
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: .black.opacity(0.1 * opacity),
                    radius: 15 * scale,
                    x: 0,
                    y: 8 * scale
                )
        )
        // 增强的3D效果
        .rotation3DEffect(
            .degrees(rotationAngle * 0.5),
            axis: (x: 0, y: 1, z: 0)
        )
    }
}

#Preview {
    ImageListView()
}