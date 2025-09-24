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
    var body: some View {
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
