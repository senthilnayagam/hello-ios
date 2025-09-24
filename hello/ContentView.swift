//
//  ContentView.swift
//  hello
//
//  Created by Senthil Nayagam on 24/09/25.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @State private var showTimeAlert = false
    @State private var currentTimeText = ""
    @Binding var isDarkMode: Bool
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    @State private var showExitConfirmation = false
    var body: some View {
        VStack {
            // App title at the top
            Text("Hello App")
                .font(.largeTitle).bold()

            Spacer()

            // Main content
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
                Button("Show Time") {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .none
                    formatter.timeStyle = .medium
                    currentTimeText = formatter.string(from: Date())
                    showTimeAlert = true
                }
                .padding(.top, 12)

                Button(isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode") {
                    isDarkMode.toggle()
                }
                .padding(.top, 8)

                Button("Exit") {
                    showExitConfirmation = true
                }
                .padding(.top, 8)
                .tint(.red)
            }

            Spacer()

            // Version at the bottom
            Text("v\(appVersion)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .alert("Current Time", isPresented: $showTimeAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(currentTimeText)
        }
        .confirmationDialog(
            "Exit App?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Exit", role: .destructive) {
                handleExit()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to close the app?")
        }
    }

    private func handleExit() {
#if os(macOS)
        NSApp.terminate(nil)
#else
        // Note: Programmatic exit is discouraged on iOS and may lead to App Store rejection.
        // For local/testing use only.
        exit(0)
#endif
    }
}

#Preview {
    ContentView(isDarkMode: .constant(false))
}
