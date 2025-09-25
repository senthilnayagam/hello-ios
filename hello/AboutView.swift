//
//  AboutView.swift
//  hello
//
//  Created by Senthil Nayagam on 25/09/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Hello App"
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .padding(.top, 8)

                    Text(appName)
                        .font(.title).bold()

                    Text("Version \(version) (\(build))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("A simple SwiftUI demo app made by Senthil in partnership with GPT5. This app shows a greeting, a clock, theme toggling, and a splash screen.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .padding(.top, 4)

                    Spacer(minLength: 8)

                    GroupBox("Credits") {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Design & Development: Senthil")
                            Text("Assistant: GPT5")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AboutView()
}
