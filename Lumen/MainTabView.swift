//
//  MainTabView.swift
//  AdvxProject1
//
//  Created by AI Assistant on 2025/7/25.
//

import SwiftUI

// MARK: - Commented out duplicate declarations to avoid conflicts with ContentView.swift
// The main interface is now handled by ContentView.swift

/*
enum AppTab: String, CaseIterable {
    case digitalTwin = "数字孪生"
    case aiAssistant = "AI助手"
    
    var icon: String {
        switch self {
        case .digitalTwin:
            return "cube.transparent"
        case .aiAssistant:
            return "brain.head.profile"
        }
    }
}
*/

struct MainTabView: View {
    @State private var selectedTab: AppTab = .aiAssistant
    @StateObject private var bluetoothManager = BluetoothManager.shared
    @State private var showBluetoothAnimation = false
    @State private var showBluetoothView = false
    
    var body: some View {
        ZStack {
            // Enhanced Liquid glass background
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.15),
                        Color.purple.opacity(0.12),
                        Color.pink.opacity(0.14),
                        Color.cyan.opacity(0.11),
                        Color.indigo.opacity(0.09)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated radial gradients
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.08),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 400
                )
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.06),
                        Color.clear
                    ]),
                    center: .bottomLeading,
                    startRadius: 150,
                    endRadius: 500
                )
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area
                ZStack {
                    switch selectedTab {
                    case .digitalTwin:
                        ImageListView()
                            .transition(.opacity)
                    case .aiAssistant:
                        AIChatHistoryView(selectedTab: selectedTab)
                            .transition(.opacity)
                    case .settings:
                        SettingsView()
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)
                
                Spacer()
                
                // Bottom navigation with Liquid Glass effect
                VStack(spacing: 8) { // 减少间距从12到8
                    // Bluetooth connection button (smaller size)
                    BluetoothConnectionButton(
                        isConnected: bluetoothManager.isConnected,
                        showAnimation: $showBluetoothAnimation
                    )
                    .scaleEffect(0.7) // 进一步缩小蓝牙按钮从0.8到0.7
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showBluetoothAnimation.toggle()
                            showBluetoothView = true
                            
                            // 如果蓝牙未连接，自动开始扫描
                            if !bluetoothManager.isConnected {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    bluetoothManager.startScanning()
                                }
                            }
                        }
                    }
                    
                    // Tab switching bar (smaller size)
                    LiquidGlassTabBar(selectedTab: $selectedTab)
                        .scaleEffect(0.75) // 进一步缩小切换栏从0.85到0.75
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 25) // 减少底部边距从30到25
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showBluetoothView) {
            BluetoothConnectionView()
        }
        .withLumenProgress() // 添加进度显示
    }
}

// MARK: - Commented out duplicate structures to avoid conflicts with ContentView.swift

/*
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabAnimation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(
                                selectedTab == tab ?
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .cyan, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    gradient: Gradient(colors: [.primary.opacity(0.6), .secondary]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(
                                selectedTab == tab ?
                                LinearGradient(
                                    gradient: Gradient(colors: [.white, .cyan]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    gradient: Gradient(colors: [.primary.opacity(0.6), .secondary]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        .white.opacity(0.25),
                                                        .clear,
                                                        .blue.opacity(0.15),
                                                        .cyan.opacity(0.1)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        .white.opacity(0.6),
                                                        .white.opacity(0.2),
                                                        .clear,
                                                        .blue.opacity(0.3)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                                    .shadow(color: .blue.opacity(0.2), radius: 15, x: 0, y: 8)
                                    .shadow(color: .cyan.opacity(0.15), radius: 25, x: 0, y: 0)
                                    .matchedGeometryEffect(id: "selectedTab", in: tabAnimation)
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.15),
                                    .clear,
                                    .blue.opacity(0.08)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white.opacity(0.4),
                                    .white.opacity(0.1),
                                    .clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
        .shadow(color: .blue.opacity(0.1), radius: 30, x: 0, y: 0)
    }
}

struct BluetoothConnectionButton: View {
    let isConnected: Bool
    @Binding var showAnimation: Bool
    
    var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    // Connection status indicator
                    Circle()
                        .fill(
                            isConnected ?
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .mint, .cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                gradient: Gradient(colors: [.gray.opacity(0.6), .secondary]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 12, height: 12)
                        .scaleEffect(showAnimation ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showAnimation)
                    
                    if isConnected {
                        Circle()
                            .fill(.white.opacity(0.8))
                            .frame(width: 6, height: 6)
                    }
                }
                
                Image(systemName: isConnected ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        isConnected ?
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .mint, .cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [.primary.opacity(0.7), .secondary]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(isConnected ? "已连接" : "未连接")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        isConnected ?
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .mint]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [.primary.opacity(0.7), .secondary]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isConnected ? .green.opacity(0.15) : .white.opacity(0.12),
                                        .clear,
                                        isConnected ? .mint.opacity(0.08) : .blue.opacity(0.06)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        isConnected ? .green.opacity(0.4) : .white.opacity(0.3),
                                        isConnected ? .mint.opacity(0.2) : .white.opacity(0.1),
                                        .clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(
                color: isConnected ? .green.opacity(0.2) : .black.opacity(0.08),
                radius: isConnected ? 20 : 15,
                x: 0,
                y: isConnected ? 10 : 8
            )
            .shadow(
                color: isConnected ? .mint.opacity(0.15) : .blue.opacity(0.1),
                radius: isConnected ? 30 : 25,
                x: 0,
                y: 0
            )
        .onAppear {
            if isConnected {
                showAnimation = true
            }
        }
        .onChange(of: isConnected) { connected in
            showAnimation = connected
        }
    }
}
*/

#Preview {
    MainTabView()
}