//
//  AudioPlayerView.swift
//  AdvxProject1
//
//  Created by AI Assistant on 2025/7/26.
//

import SwiftUI
import AVFoundation
import AVKit

struct AudioPlayerView: View {
    @StateObject private var audioService = AudioPlayerService.shared
    @State private var showingPlayer = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "music.note")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 60))
            
            Text("音频播放器")
                .font(.title)
                .fontWeight(.bold)
            
            if let errorMessage = audioService.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 15) {
                // 播放本地音频按钮
                Button(action: {
                    Task {
                        do {
                            try await audioService.playLocalAudio()
                        } catch {
                            print("播放本地音频失败: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("播放本地音频")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                
                // 播放远程音频按钮
                Button(action: {
                    Task {
                        do {
                            try await audioService.playRemoteAudio()
                        } catch {
                            print("播放远程音频失败: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "globe")
                        Text("播放远程音频")
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.green)
                    .cornerRadius(25)
                }
                
                // 停止播放按钮
                if audioService.isPlaying {
                    Button(action: {
                        audioService.stopAudio()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("停止播放")
                        }
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.red)
                        .cornerRadius(25)
                    }
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingPlayer) {
            if let player = audioService.player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            }
        }
    }
}

#Preview {
    AudioPlayerView()
}