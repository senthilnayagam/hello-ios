//
//  HomeView.swift
//  hello
//
//  Created by Senthil Nayagam on 25/09/25.
//

import SwiftUI
import Combine

struct HomeView: View {
    @Binding var isDarkMode: Bool
    @AppStorage("username") private var name: String = ""

    // Clock & Date
    @State private var currentDate: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var selectedDate: Date = Date()

    // Alerts
    @State private var showTimeAlert = false
    @State private var currentTimeText = ""
    @State private var showExitConfirmation = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()
    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .foregroundStyle(.tint)
                        Text("Hello App")
                            .font(.largeTitle).bold()
                        Text("Welcome!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Greeting
                    GroupBox("Personalized greeting") {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Enter your name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                            if !name.isEmpty {
                                Text("Hello, \(name)!")
                                    .font(.title3)
                            }
                        }
                    }

                    // Clock
                    GroupBox("Time") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Self.timeFormatter.string(from: currentDate))
                                .font(.title3)
                                .monospacedDigit()
                            Button("Show Time") {
                                let formatter = DateFormatter()
                                formatter.dateStyle = .none
                                formatter.timeStyle = .medium
                                currentTimeText = formatter.string(from: Date())
                                showTimeAlert = true
                            }
                        }
                    }

                    // Date picker
                    GroupBox("Select date & time") {
                        VStack(alignment: .leading, spacing: 8) {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)

                            Text(Self.dateTimeFormatter.string(from: selectedDate))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Settings quick actions
                    GroupBox("Quick actions") {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode") {
                                isDarkMode.toggle()
                            }
#if os(macOS)
                            Button("Exit") {
                                showExitConfirmation = true
                            }
                            .tint(.red)
#endif
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
        }
        .onReceive(timer) { currentDate = $0 }
        .alert("Current Time", isPresented: $showTimeAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(currentTimeText) }
        .confirmationDialog(
            "Exit App?",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Exit", role: .destructive) { handleExit() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to close the app?")
        }
    }

    private func handleExit() {
#if os(macOS)
        NSApp.terminate(nil)
#else
        exit(0)
#endif
    }
}

#Preview {
    HomeView(isDarkMode: .constant(false))
}
