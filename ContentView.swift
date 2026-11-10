import SwiftUI
import UIKit

struct LogLine: Identifiable {
    let id = UUID()
    let text: String
    let kind: Kind
    enum Kind { case info, ok, warn }
}

struct ContentView: View {
    enum Phase { case idle, running, done }

    @State private var phase: Phase = .idle
    @State private var progress: Int = 0
    @State private var lines: [LogLine] = []
    @State private var fadeToBlack = false
    @State private var pulse = false

    private let appName = "den"
    private let appVersion = "v2.4.1"

    // Cihaz bilgisi
    private var machine: String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }
    private var iosVersion: String { UIDevice.current.systemVersion }

    private func hex() -> String {
        String(format: "0x%016llx", UInt64.random(in: 0xfffffff007000000...0xfffffff00fffffff))
    }
    private func hex32() -> String {
        String(format: "0x%08x", UInt32.random(in: 0x10000000...0xffffffff))
    }

    // (yüzde, satır, tür) — yüzde gelince satır basılır
    private func script() -> [(Int, String, LogLine.Kind)] {
        let dev = machine
        return [
            (1,  "[*] \(appName) \(appVersion) baslatildi", .info),
            (1,  "[*] cihaz: \(dev) / iOS \(iosVersion)", .info),
            (3,  "[*] kernel surumu kontrol ediliyor...", .info),
            (5,  "[+] desteklenen surum bulundu", .ok),
            (7,  "[*] exploit zinciri hazirlaniyor", .info),
            (10, "[*] IOSurface heap spray basliyor", .info),
            (13, "[*] mach_port_t spray: \(hex32())", .info),
            (16, "[+] heap grooming tamamlandi", .ok),
            (19, "[*] zone_map taraniyor...", .info),
            (23, "[!] race condition tetikleniyor (deneme 1/3)", .warn),
            (26, "[!] race condition tetikleniyor (deneme 2/3)", .warn),
            (29, "[+] race kazanildi, UAF elde edildi", .ok),
            (32, "[*] kernel_base araniyor...", .info),
            (35, "[+] kernel_base = \(hex())", .ok),
            (38, "[+] kernel_slide = \(hex32())", .ok),
            (41, "[*] allproc offset cozuluyor", .info),
            (44, "[+] allproc = \(hex())", .ok),
            (47, "[*] kernel task port aliniyor", .info),
            (50, "[+] tfp0 elde edildi", .ok),
            (53, "[*] ucred patchleniyor: uid=0 gid=0", .info),
            (56, "[+] root yetkisi alindi", .ok),
            (59, "[*] sandbox kisitlari kaldiriliyor", .info),
            (62, "[+] sandbox patch: \(hex())", .ok),
            (65, "[*] AMFI devre disi birakiliyor", .info),
            (68, "[+] amfid patch tamamlandi", .ok),
            (71, "[*] trustcache enjekte ediliyor", .info),
            (74, "[*] rootfs remount ediliyor (rw)", .info),
            (77, "[+] / yazilabilir yapildi", .ok),
            (80, "[*] bootstrap cikariliyor...", .info),
            (83, "[+] /var/jb olusturuldu", .ok),
            (86, "[*] Sileo kuruluyor", .info),
            (89, "[*] libhooker ve substitute yukleniyor", .info),
            (92, "[+] tweak injection hazir", .ok),
            (95, "[*] launchd daemonlari kaydediliyor", .info),
            (97, "[*] kernel bellek temizleniyor", .info),
            (99, "[+] tum islemler tamamlandi", .ok),
            (100, "[+] JAILBREAK BASARILI", .ok),
        ]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.05, green: 0.02, blue: 0.14), .black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header
                if phase == .idle { idleBody } else { runBody }
            }
            .padding(.top, 30)

            Color.black.ignoresSafeArea().opacity(fadeToBlack ? 1 : 0)
                .allowsHitTesting(fadeToBlack)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    // MARK: Parcalar

    private var header: some View {
        VStack(spacing: 10) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: phase == .idle ? 120 : 70, height: phase == .idle ? 120 : 70)
                .clipShape(RoundedRectangle(cornerRadius: phase == .idle ? 27 : 16, style: .continuous))
                .shadow(color: Color.blue.opacity(pulse ? 0.7 : 0.25), radius: pulse ? 24 : 10)
            Text(appName)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("iOS Jailbreak  \(appVersion)")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.gray)
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
    }

    private var idleBody: some View {
        VStack(spacing: 14) {
            Spacer()
            VStack(spacing: 6) {
                infoRow("Cihaz", machine)
                infoRow("iOS", iosVersion)
                infoRow("Durum", "Destekleniyor ✓")
                infoRow("Jailbreak", "Yapilmamis")
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)
            .padding(.horizontal, 30)

            Spacer()

            Button(action: start) {
                Text("Jailbreak")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color(red: 0.45, green: 0.2, blue: 0.95),
                                                Color(red: 0.1, green: 0.5, blue: 1)],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }

    private var runBody: some View {
        VStack(spacing: 14) {
            Text("%\(progress)")
                .font(.system(size: 52, weight: .bold, design: .monospaced))
                .foregroundColor(phase == .done ? .green : .white)

            ProgressView(value: Double(progress), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: phase == .done ? .green : .blue))
                .padding(.horizontal, 30)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(lines) { l in
                            Text(l.text)
                                .font(.system(size: 11.5, design: .monospaced))
                                .foregroundColor(color(l.kind))
                                .id(l.id)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                }
                .background(Color(white: 0.05))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .onChange(of: lines.count) { _ in
                    if let last = lines.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            if phase == .done {
                VStack(spacing: 10) {
                    Text("iPhone jailbreaklandi! 🎉")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.green)
                    Button(action: respring) {
                        Text("Respring")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green.opacity(0.85))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 30)
            } else {
                Text("Cihazi kapatmayin, uygulamadan cikmayin")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
                    .padding(.bottom, 30)
            }
        }
    }

    private func infoRow(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundColor(.gray)
            Spacer()
            Text(v).foregroundColor(.white)
        }
        .font(.system(size: 15, design: .monospaced))
    }

    private func color(_ k: LogLine.Kind) -> Color {
        switch k {
        case .info: return Color(white: 0.75)
        case .ok:   return .green
        case .warn: return .orange
        }
    }

    // MARK: Aksiyonlar

    private func start() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        lines = []
        progress = 0
        phase = .running
        let steps = script()

        Task { @MainActor in
            var idx = 0
            for p in 1...100 {
                progress = p
                while idx < steps.count && steps[idx].0 <= p {
                    lines.append(LogLine(text: steps[idx].1, kind: steps[idx].2))
                    idx += 1
                }
                // Gercekci duraklamalar: bazi yuzdelerde takilir
                var delay = Double.random(in: 0.04...0.16)
                if [23, 26, 35, 50, 74, 83].contains(p) { delay = Double.random(in: 0.8...1.5) }
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            phase = .done
        }
    }

    private func respring() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        withAnimation(.easeIn(duration: 0.5)) { fadeToBlack = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            phase = .idle
            progress = 0
            lines = []
            withAnimation(.easeOut(duration: 0.8)) { fadeToBlack = false }
        }
    }
}
