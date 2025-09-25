//
//  helloApp.swift
//  hello
//
//  Created by Senthil Nayagam on 24/09/25.
//

import SwiftUI

@main
struct helloApp: App {
    @State private var isDarkMode: Bool = false
    @State private var showSplash: Bool = true
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView()
                } else {
                    ContentView(isDarkMode: $isDarkMode)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .onAppear {
                // Hold the splash for 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeInOut) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
