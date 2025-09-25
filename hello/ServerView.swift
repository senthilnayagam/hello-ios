//
//  ServerView.swift
//  hello
//
//  Created by Senthil Nayagam on 25/09/25.
//

import SwiftUI
import Combine
import CoreLocation
import WebKit

// Location manager wrapper
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    let objectWillChange = PassthroughSubject<Void, Never>()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var speed: CLLocationSpeed? // m/s
    @Published var course: CLLocationDirection? // degrees

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingHeading()
    }

    func request() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            self.manager.startUpdatingLocation()
            self.manager.startUpdatingHeading()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        coordinate = last.coordinate
        speed = last.speed >= 0 ? last.speed : nil
        course = last.course >= 0 ? last.course : nil
        objectWillChange.send()
    }
}

// Simple WebView wrapper
struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Only load if different
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

struct ServerView: View {
    @StateObject private var loc = LocationProvider()
    @State private var publicIP: String = "—"
    @State private var showBrowser: Bool = false

    private var ipInfoURL: URL? {
        guard publicIP != "—", let url = URL(string: "https://whatismyipaddress.com/ip/\(publicIP)") else { return nil }
        return url
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GroupBox("Network") {
                        HStack {
                            Text("Public IP")
                            Spacer()
                            Text(publicIP)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        .task { await fetchPublicIP() }

                        if let url = ipInfoURL {
                            Button {
                                showBrowser = true
                            } label: {
                                Label("Open IP details", systemImage: "safari")
                            }
                            .padding(.top, 6)
                        }
                    }

                    GroupBox("Location") {
                        VStack(alignment: .leading, spacing: 8) {
                            switch loc.authorizationStatus {
                            case .authorizedWhenInUse, .authorizedAlways:
                                HStack {
                                    Text("Coordinates")
                                    Spacer()
                                    Text(formatCoords(loc.coordinate))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Speed")
                                    Spacer()
                                    Text(formatSpeed(loc.speed))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Direction")
                                    Spacer()
                                    Text(formatCourse(loc.course))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                            case .denied, .restricted:
                                Text("Location access denied. Enable it in Settings to see coordinates and motion.")
                                    .foregroundStyle(.secondary)
                            case .notDetermined:
                                Button("Allow Location Access") {
                                    loc.request()
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Server")
        }
        .sheet(isPresented: $showBrowser) {
            if let url = ipInfoURL {
                NavigationStack {
                    WebView(url: url)
                        .navigationTitle("IP Details")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Close") { showBrowser = false }
                            }
                        }
                }
            }
        }
        .onAppear {
            loc.request()
        }
    }

    // Helpers
    private func fetchPublicIP() async {
        // Simple service to get IP, no API key needed.
        let endpoints = ["https://api.ipify.org", "https://ifconfig.me/ip"]
        for e in endpoints {
            if let url = URL(string: e) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                        await MainActor.run { publicIP = text }
                        return
                    }
                } catch {
                    continue
                }
            }
        }
    }

    private func formatCoords(_ coord: CLLocationCoordinate2D?) -> String {
        guard let c = coord else { return "—" }
        return String(format: "%.5f, %.5f", c.latitude, c.longitude)
    }

    private func formatSpeed(_ speed: CLLocationSpeed?) -> String {
        guard let s = speed else { return "—" }
        // Convert m/s to km/h
        let kmh = s * 3.6
        return String(format: "%.1f km/h", kmh)
    }

    private func formatCourse(_ course: CLLocationDirection?) -> String {
        guard let d = course else { return "—" }
        return String(format: "%.0f°", d)
    }
}

#Preview {
    ServerView()
}
