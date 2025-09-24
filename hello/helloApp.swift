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
    var body: some Scene {
        WindowGroup {
            ContentView(isDarkMode: $isDarkMode)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
