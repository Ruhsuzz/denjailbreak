import SwiftUI
import UIKit
import CryptoKit
import AVFoundation

// MARK: - Liste

struct ToolsView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: DeviceInfoView()) { Label("Cihaz Bilgisi", systemImage: "cpu") }
                NavigationLink(destination: BatteryView()) { Label("Pil Durumu", systemImage: "battery.100") }
                NavigationLink(destination: StorageView()) { Label("Depolama", systemImage: "internaldrive") }
                NavigationLink(destination: NetworkView()) { Label("Ag / IP / Ping", systemImage: "network") }
                NavigationLink(destination: ClipboardView()) { Label("Pano", systemImage: "doc.on.clipboard") }
                NavigationLink(destination: HashView()) { Label("Hash / Base64", systemImage: "number") }
                NavigationLink(destination: PasswordView()) { Label("Sifre Uretici", systemImage: "key.fill") }
                NavigationLink(destination: FlashlightView()) { Label("Fener", systemImage: "flashlight.on.fill") }
            }
            .navigationTitle("Tools")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Yardimcilar

struct TermText: View {
    let text: String
    var body: some View {
        ScrollView {
            Text(text)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

func machineID() -> String {
    var info = utsname()
    uname(&info)
    return withUnsafePointer(to: &info.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
    }
}

func bytes(_ n: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: n, countStyle: .file)
}

// MARK: - Cihaz bilgisi

struct DeviceInfoView: View {
    @State private var text = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        TermText(text: text)
            .navigationTitle("Cihaz Bilgisi")
            .onAppear { text = build() }
            .onReceive(timer) { _ in text = build() }
    }

    private func build() -> String {
        let d = UIDevice.current
        let p = ProcessInfo.processInfo
        let s = UIScreen.main
        let ram = Double(p.physicalMemory) / 1_073_741_824
        var thermal = "bilinmiyor"
        switch p.thermalState {
        case .nominal: thermal = "normal"
        case .fair: thermal = "hafif sicak"
        case .serious: thermal = "sicak"
        case .critical: thermal = "kritik"
        @unknown default: break
        }
        let up = Int(p.systemUptime)
        return """
        $ uname -a
        model        : \(machineID())
        cihaz adi    : \(d.name)
        sistem       : \(d.systemName) \(d.systemVersion)
        islemci      : \(p.processorCount) cekirdek (\(p.activeProcessorCount) aktif)
        ram          : \(String(format: "%.1f", ram)) GB
        ekran        : \(Int(s.bounds.width * s.scale))x\(Int(s.bounds.height * s.scale)) @\(Int(s.scale))x
        parlaklik    : %\(Int(s.brightness * 100))
        termal       : \(thermal)
        dusuk guc    : \(p.isLowPowerModeEnabled ? "acik" : "kapali")
        uptime       : \(up / 3600)s \((up % 3600) / 60)dk \(up % 60)sn
        """
    }
}

// MARK: - Pil

struct BatteryView: View {
    @State private var text = ""
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        TermText(text: text)
            .navigationTitle("Pil Durumu")
            .onAppear {
                UIDevice.current.isBatteryMonitoringEnabled = true
                text = build()
            }
            .onReceive(timer) { _ in text = build() }
    }

    private func build() -> String {
        let d = UIDevice.current
        let level = d.batteryLevel < 0 ? "bilinmiyor" : "%\(Int(d.batteryLevel * 100))"
        var state = "bilinmiyor"
        switch d.batteryState {
        case .charging: state = "sarj oluyor"
        case .full: state = "dolu"
        case .unplugged: state = "sarjda degil"
        default: break
        }
        return """
        $ battery --status
        seviye : \(level)
        durum  : \(state)
        dusuk guc modu : \(ProcessInfo.processInfo.isLowPowerModeEnabled ? "acik" : "kapali")
        """
    }
}

// MARK: - Depolama

struct StorageView: View {
    @State private var text = ""
    var body: some View {
        TermText(text: text)
            .navigationTitle("Depolama")
            .onAppear {
                let url = URL(fileURLWithPath: NSHomeDirectory())
                let v = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
                let total = Int64(v?.volumeTotalCapacity ?? 0)
                let free = v?.volumeAvailableCapacityForImportantUsage ?? 0
                let used = total - free
                let pct = total > 0 ? Int(Double(used) / Double(total) * 100) : 0
                text = """
                $ df -h /
                toplam : \(bytes(total))
                kullanilan : \(bytes(used)) (%\(pct))
                bos : \(bytes(free))
                """
            }
    }
}

// MARK: - Ag

struct NetworkView: View {
    @State private var text = "Baslat'a bas."
    @State private var running = false

    var body: some View {
        VStack(spacing: 0) {
            TermText(text: text)
            Button(action: { Task { await run() } }) {
                Text(running ? "Calisiyor..." : "Baslat")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundColor(.white).cornerRadius(12)
            }
            .disabled(running)
            .padding()
        }
        .navigationTitle("Ag / IP / Ping")
    }

    private func localIPs() -> [String] {
        var res = [String]()
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return res }
        defer { freeifaddrs(ifaddr) }
        for ptr in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let i = ptr.pointee
            guard let sa = i.ifa_addr, sa.pointee.sa_family == UInt8(AF_INET) else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(sa, socklen_t(sa.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
            res.append("\(String(cString: i.ifa_name)) : \(String(cString: host))")
        }
        return res
    }

    @MainActor
    private func run() async {
        running = true
        text = "$ ifconfig\n" + localIPs().joined(separator: "\n") + "\n"
        text += "\n$ curl ifconfig\n"
        if let url = URL(string: "https://api.ipify.org"),
           let (data, _) = try? await URLSession.shared.data(from: url),
           let ip = String(data: data, encoding: .utf8) {
            text += "dis IP : \(ip)\n"
        } else {
            text += "dis IP alinamadi (internet yok?)\n"
        }
        text += "\n$ ping apple.com\n"
        if let url = URL(string: "https://www.apple.com/library/test/success.html") {
            for n in 1...4 {
                var req = URLRequest(url: url)
                req.cachePolicy = .reloadIgnoringLocalCacheData
                let t0 = Date()
                if (try? await URLSession.shared.data(for: req)) != nil {
                    let ms = Int(Date().timeIntervalSince(t0) * 1000)
                    text += "cevap \(n): \(ms) ms\n"
                } else {
                    text += "cevap \(n): zaman asimi\n"
                }
            }
        }
        running = false
    }
}

// MARK: - Pano

struct ClipboardView: View {
    @State private var text = ""
    var body: some View {
        VStack(spacing: 0) {
            TermText(text: text.isEmpty ? "(pano bos)" : text)
            HStack {
                Button("Yenile") { text = UIPasteboard.general.string ?? "" }
                    .frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(12)
                Button("Temizle") { UIPasteboard.general.string = ""; text = "" }
                    .frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Pano")
        .onAppear { text = UIPasteboard.general.string ?? "" }
    }
}

// MARK: - Hash / Base64

struct HashView: View {
    @State private var input = ""

    private func hex<D: Sequence>(_ d: D) -> String where D.Element == UInt8 {
        d.map { String(format: "%02x", $0) }.joined()
    }
    private var data: Data { Data(input.utf8) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                TextField("Metin yaz", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                out("MD5", hex(Insecure.MD5.hash(data: data)))
                out("SHA1", hex(Insecure.SHA1.hash(data: data)))
                out("SHA256", hex(SHA256.hash(data: data)))
                out("Base64 (kodla)", data.base64EncodedString())
                out("Base64 (coz)", Data(base64Encoded: input).flatMap { String(data: $0, encoding: .utf8) } ?? "-")
            }
            .padding()
        }
        .navigationTitle("Hash / Base64")
    }

    private func out(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundColor(.gray)
            Text(value.isEmpty ? "-" : value)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.green)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Sifre uretici

struct PasswordView: View {
    @State private var length: Double = 16
    @State private var symbols = true
    @State private var password = ""

    var body: some View {
        VStack(spacing: 18) {
            Text(password)
                .font(.system(size: 17, design: .monospaced))
                .foregroundColor(.green)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.08))
                .cornerRadius(10)
            Text("Uzunluk: \(Int(length))")
            Slider(value: $length, in: 8...64, step: 1)
            Toggle("Ozel karakterler", isOn: $symbols)
            Button("Uret") { generate() }
                .frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(12)
            Button("Kopyala") { UIPasteboard.general.string = password }
                .frame(maxWidth: .infinity).padding().background(Color(white: 0.2)).foregroundColor(.white).cornerRadius(12)
            Spacer()
        }
        .padding()
        .navigationTitle("Sifre Uretici")
        .onAppear { generate() }
    }

    private func generate() {
        var chars = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        if symbols { chars += Array("!@#$%^&*()-_=+[]{}?") }
        password = String((0..<Int(length)).compactMap { _ in chars.randomElement() })
    }
}

// MARK: - Fener

struct FlashlightView: View {
    @State private var on = false
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: on ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.system(size: 90))
                .foregroundColor(on ? .yellow : .gray)
            Button(on ? "Kapat" : "Ac") { toggle() }
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(12)
                .padding(.horizontal, 30)
            Spacer()
        }
        .navigationTitle("Fener")
        .onDisappear { set(false) }
    }

    private func toggle() { set(!on) }

    private func set(_ value: Bool) {
        guard let d = AVCaptureDevice.default(for: .video), d.hasTorch else { return }
        do {
            try d.lockForConfiguration()
            d.torchMode = value ? .on : .off
            d.unlockForConfiguration()
            on = value
        } catch {}
    }
}
