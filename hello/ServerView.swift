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
    @State private var sunrise: Date?
    @State private var sunset: Date?

    private static let sunTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.timeZone = .current
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

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
                                Divider()
                                HStack {
                                    Text("Sunrise")
                                    Spacer()
                                    Text(formatSunTime(sunrise))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Text("Sunset")
                                    Spacer()
                                    Text(formatSunTime(sunset))
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
        .onReceive(loc.$coordinate) { newValue in
            guard let c = newValue else { return }
            let (sr, ss) = computeSunriseSunset(for: Date(), latitude: c.latitude, longitude: c.longitude)
            sunrise = sr
            sunset = ss
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

    private func formatSunTime(_ date: Date?) -> String {
        guard let d = date else { return "—" }
        return Self.sunTimeFormatter.string(from: d)
    }

    // MARK: - Sunrise/Sunset Calculation (NOAA algorithm)
    private func computeSunriseSunset(for date: Date, latitude: Double, longitude: Double) -> (Date?, Date?) {
        func degrees(_ rad: Double) -> Double { rad * 180.0 / .pi }
        func radians(_ deg: Double) -> Double { deg * .pi / 180.0 }

        // Use the user's local calendar for the target day (N = day-of-year for local date)
        let localCal = Calendar(identifier: .gregorian)
        let N = Double(localCal.ordinality(of: .day, in: .year, for: date) ?? 1)

    // NOAA algorithm expects longitude in degrees WEST (positive west, negative east).
    // CoreLocation uses positive EAST longitudes, so invert the sign here.
    let lngHour = -longitude / 15.0
        let zenith = 90.833 // official sunrise/sunset

        func calculate(isSunrise: Bool) -> Date? {
            // 1) Approximate time
            let t = N + ((isSunrise ? (6.0 - lngHour) : (18.0 - lngHour)) / 24.0)

            // 2) Sun's mean anomaly
            let M = (0.9856 * t) - 3.289

            // 3) Sun's true longitude
            var L = M + (1.916 * sin(radians(M))) + (0.020 * sin(radians(2 * M))) + 282.634
            L = fmod(L, 360.0)
            if L < 0 { L += 360.0 }

            // 4) Sun's right ascension
            var RA = degrees(atan(0.91764 * tan(radians(L))))
            RA = fmod(RA, 360.0)
            if RA < 0 { RA += 360.0 }
            // Put RA in the same quadrant as L
            let Lquadrant = floor(L / 90.0) * 90.0
            let RAquadrant = floor(RA / 90.0) * 90.0
            RA = RA + (Lquadrant - RAquadrant)
            RA /= 15.0

            // 5) Sun's declination
            let sinDec = 0.39782 * sin(radians(L))
            let cosDec = cos(asin(sinDec))

            // 6) Sun's local hour angle
            let cosH = (cos(radians(zenith)) - (sinDec * sin(radians(latitude)))) / (cosDec * cos(radians(latitude)))
            if isSunrise && cosH > 1 { return nil }      // sun never rises on this location (on the specified date)
            if !isSunrise && cosH < -1 { return nil }    // sun never sets on this location (on the specified date)

            var H = isSunrise ? (360.0 - degrees(acos(cosH))) : degrees(acos(cosH))
            H /= 15.0

            // 7) Local mean time and UT
            let T = H + RA - (0.06571 * t) - 6.622
            var UT = T - lngHour
            UT = fmod(UT, 24.0)
            if UT < 0 { UT += 24.0 }

            // 8) Build a Date at UT for the LOCAL calendar day
            var ymd = localCal.dateComponents([.year, .month, .day], from: date)
            ymd.timeZone = TimeZone(secondsFromGMT: 0)
            ymd.hour = Int(UT)
            ymd.minute = Int((UT - floor(UT)) * 60.0)
            let secondsFrac = (((UT - floor(UT)) * 60.0) - Double(ymd.minute ?? 0)) * 60.0
            ymd.second = Int(secondsFrac.rounded())

            var utcCal = Calendar(identifier: .gregorian)
            utcCal.timeZone = TimeZone(secondsFromGMT: 0)!
            return utcCal.date(from: ymd)
        }

        // Return UTC instants; formatting to local time is handled by DateFormatter
        let srUTC = calculate(isSunrise: true)
        let ssUTC = calculate(isSunrise: false)
        return (srUTC, ssUTC)
    }
}

#Preview {
    ServerView()
}
