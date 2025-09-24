//
//  ContentView.swift
//  hello
//
//  Created by Senthil Nayagam on 24/09/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showTimeAlert = false
    @State private var currentTimeText = ""
    @Binding var isDarkMode: Bool
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
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
    }
}

#Preview {
    ContentView(isDarkMode: .constant(false))
}
