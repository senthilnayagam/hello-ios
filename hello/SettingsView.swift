//
//  SettingsView.swift
//  hello
//
//  Created by Senthil Nayagam on 25/09/25.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isDarkMode: Bool

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle(isOn: $isDarkMode) {
                        Text("Dark Mode")
                    }
                }

                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView(isDarkMode: .constant(false))
}
