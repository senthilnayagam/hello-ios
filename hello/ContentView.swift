//
//  ContentView.swift
//  hello
//
//  Created by Senthil Nayagam on 24/09/25.
//

import SwiftUI
import Combine
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @Binding var isDarkMode: Bool
    var body: some View {
        TabView {
            HomeView(isDarkMode: $isDarkMode)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            SettingsView(isDarkMode: $isDarkMode)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            ServerView()
                .tabItem {
                    Label("Server", systemImage: "server.rack")
                }
            AboutView(showsCloseButton: false)
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

#Preview {
    ContentView(isDarkMode: .constant(false))
}
