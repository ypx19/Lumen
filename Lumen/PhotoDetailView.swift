import SwiftUI

struct PhotoDetailView: View {
    let photoData: PhotoData
    @Environment(\.dismiss) private var dismiss
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var showingFullImage = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 图片区域
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                        
                        AsyncImage(url: URL(string: photoData.url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(imageScale)
                                .offset(imageOffset)
                                .onTapGesture(count: 2) {
                                    withAnimation(.spring()) {
                                        if imageScale > 1 {
                                            imageScale = 1
                                            imageOffset = .zero
                                        } else {
                                            imageScale = 2
                                        }
                                    }
                                }
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            imageScale = max(1, min(value, 4))
                                        }
                                        .onEnded { _ in
                                            if imageScale < 1.2 {
                                                withAnimation(.spring()) {
                                                    imageScale = 1
                                                    imageOffset = .zero
                                                }
                                            }
                                        }
                                )
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if imageScale > 1 {
                                                imageOffset = value.translation
                                            }
                                        }
                                        .onEnded { _ in
                                            if imageScale <= 1 {
                                                withAnimation(.spring()) {
                                                    imageOffset = .zero
                                                }
                                            }
                                        }
                                )
                        } placeholder: {
                            ZStack {
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.3),
                                        Color.purple.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        }
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .onTapGesture {
                        showingFullImage = true
                    }
                    
                    // 信息区域
                    VStack(alignment: .leading, spacing: 20) {
                        // 日期信息
                        InfoCard(
                            icon: "calendar",
                            title: "日期",
                            content: photoData.date,
                            color: .blue
                        )
                        
                        // 标签信息
                        if !photoData.tag.isEmpty {
                            InfoCard(
                                icon: "tag.fill",
                                title: "标签",
                                content: photoData.tag,
                                color: .purple
                            )
                        }
                        
                        // 文本描述
                        if !photoData.text.isEmpty {
                            InfoCard(
                                icon: "text.alignleft",
                                title: "描述",
                                content: photoData.text,
                                color: .green
                            )
                        }
                        
                        // URL信息
                        InfoCard(
                            icon: "link",
                            title: "图片链接",
                            content: photoData.url,
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("图片详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            FullScreenImageView(imageUrl: photoData.url)
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text(content)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FullScreenImageView: View {
    let imageUrl: String
    @Environment(\.dismiss) private var dismiss
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                imageScale = max(0.5, min(value, 4))
                            }
                            .onEnded { _ in
                                if imageScale < 1 {
                                    withAnimation(.spring()) {
                                        imageScale = 1
                                        imageOffset = .zero
                                    }
                                }
                            }
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                imageOffset = value.translation
                            }
                            .onEnded { _ in
                                if imageScale <= 1 {
                                    withAnimation(.spring()) {
                                        imageOffset = .zero
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if imageScale > 1 {
                                imageScale = 1
                                imageOffset = .zero
                            } else {
                                imageScale = 2
                            }
                        }
                    }
            } placeholder: {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                Spacer()
            }
        }
        .onTapGesture {
            dismiss()
        }
    }
}

#Preview {
    PhotoDetailView(photoData: PhotoData(
        url: "https://example.com/image.jpg",
        date: "2024-01-15",
        tag: "风景",
        text: "这是一张美丽的风景照片"
    ))
}