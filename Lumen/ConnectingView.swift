//
//  ConnectingView.swift
//  AdvxProject1
//
//  Created by 尤沛兴 on 2025/7/25.
//

import SwiftUI

struct ConnectingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Liquid glass background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.08),
                    Color.pink.opacity(0.12),
                    Color.cyan.opacity(0.10),
                    Color.indigo.opacity(0.06)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated background particles
            ForEach(0..<20, id: \.self) { _ in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.white.opacity(0.1), .clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: CGFloat.random(in: 20...80))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .blur(radius: CGFloat.random(in: 2...8))
            }
            
            VStack(spacing: 50) {
                Spacer()
                
                // Lumen title with liquid glass effect
                Text("Lumen")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [.white, .cyan.opacity(0.8), .blue.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .tracking(12)
                    .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
                    .shadow(color: .cyan.opacity(0.3), radius: 20, x: 0, y: 0)
                
                Spacer()
                
                // Earbuds and charging case with glass container
                VStack(spacing: 40) {
                    // Left and right earbuds
                    HStack(spacing: 80) {
                        EarbudView(isLeft: true)
                        EarbudView(isLeft: false)
                    }
                    
                    // Charging case
                    ChargingCaseView()
                }
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.6), .white.opacity(0.1)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                .shadow(color: .white.opacity(0.2), radius: 5, x: 0, y: 2)
                
                Spacer()
                
                // Connection status with glass effect
                VStack(spacing: 25) {
                    HStack(spacing: 12) {
                        // Rotating loading indicator with glass effect
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white.opacity(0.3), .cyan.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .trim(from: 0, to: 0.3)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.white, .cyan]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                            )
                            .shadow(color: .white.opacity(0.5), radius: 8, x: 0, y: 0)
                        
                        Text("配对中...")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .cyan.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .white.opacity(0.5), radius: 5, x: 0, y: 2)
                    }
                    
                    Button(action: {
                        // 取消配对操作
                        print("取消配对按钮被点击")
                        // 这里可以添加具体的取消配对逻辑
                    }) {
                        Text("取消配对")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.2)]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                            )
                            .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                            .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
    }
}

struct EarbudView: View {
    let isLeft: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Earbud body with liquid glass effect
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.cyan.opacity(0.2),
                            Color.blue.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .overlay(
                    // Lumen text on earbud with glass effect
                    Text("Lumen")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .cyan.opacity(0.8)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(isLeft ? -90 : 90))
                        .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 1)
                )
                .frame(width: 50, height: 80)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                .shadow(color: .white.opacity(0.5), radius: 3, x: 0, y: 1)
            
            // Earbud tip with glass effect
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.cyan.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .overlay(
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [.black, .black.opacity(0.8)]),
                                center: .center,
                                startRadius: 2,
                                endRadius: 6
                            )
                        )
                        .frame(width: 8, height: 8)
                )
                .frame(width: 30, height: 30)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .shadow(color: .white.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .scaleEffect(x: isLeft ? -1 : 1, y: 1)
    }
}

struct ChargingCaseView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Charging case shape with liquid glass effect
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.4),
                            Color.cyan.opacity(0.25),
                            Color.blue.opacity(0.15)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.8), .white.opacity(0.2)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .frame(width: 120, height: 40)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                .shadow(color: .white.opacity(0.5), radius: 3, x: 0, y: 1)
            
            // LED indicators with glow effect
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    index == 1 ? .orange : .gray.opacity(0.4),
                                    index == 1 ? .orange.opacity(0.6) : .gray.opacity(0.2)
                                ]),
                                center: .center,
                                startRadius: 1,
                                endRadius: 4
                            )
                        )
                        .frame(width: 6, height: 6)
                        .shadow(
                            color: index == 1 ? .orange.opacity(0.8) : .clear,
                            radius: index == 1 ? 6 : 0,
                            x: 0,
                            y: 0
                        )
                }
            }
        }
    }
}

#Preview {
    ConnectingView()
}