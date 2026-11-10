import SwiftUI
import UIKit
import UniformTypeIdentifiers

// MARK: - Tema

enum DenTheme {
    static let blue = Color(red: 0.11, green: 0.40, blue: 0.96)
    static let sky  = Color(red: 0.36, green: 0.64, blue: 1.0)
    static let bg   = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let ink  = Color(red: 0.08, green: 0.14, blue: 0.30)
    static let soft = Color(red: 0.88, green: 0.93, blue: 1.0)
    static let gradient = LinearGradient(colors: [blue, sky], startPoint: .topLeading, endPoint: .bottomTrailing)
}

final class FMState: ObservableObject {
    @Published var roots: [URL] = []
    @Published var clip: URL? = nil
    @Published var isMove = false
}

struct FileEntry: Identifiable {
    let url: URL
    let isDir: Bool
    let size: Int64
    let date: Date?
    var id: URL { url }
}

struct ShareItem: Identifiable { let id = UUID(); let url: URL }

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ c: UIActivityViewController, context: Context) {}
}

let textExts = ["txt", "json", "plist", "md", "swift", "xml", "html", "css", "js", "log", "yml", "yaml", "csv", "strings", "ini", "conf", "sh", "py", "c", "h", "m"]
let imageExts = ["png", "jpg", "jpeg", "gif", "heic", "webp", "bmp"]

func sizeText(_ n: Int64) -> String { ByteCountFormatter.string(fromByteCount: n, countStyle: .file) }

func hexDump(_ d: Data) -> String {
    var out = ""
    let b = [UInt8](d)
    for off in stride(from: 0, to: b.count, by: 16) {
        let chunk = b[off..<min(off + 16, b.count)]
        let h = chunk.map { String(format: "%02x", $0) }.joined(separator: " ")
        let a = String(chunk.map { ($0 >= 32 && $0 < 127) ? Character(UnicodeScalar($0)) : "." })
        out += String(format: "%08x  ", off) + h.padding(toLength: 47, withPad: " ", startingAt: 0) + "  " + a + "\n"
    }
    return out
}

// MARK: - Ortak parcalar

struct DenHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    let onBack: (() -> Void)?
    let trailing: () -> Trailing

    init(title: String, subtitle: String, onBack: (() -> Void)? = nil,
         @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title; self.subtitle = subtitle; self.onBack = onBack; self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let onBack = onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .padding(9)
                            .background(Color.white.opacity(0.22))
                            .clipShape(Circle())
                    }
                }
                Spacer()
                trailing()
            }
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.head)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            DenTheme.gradient
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.top, -80)
                .ignoresSafeArea(edges: .top)
        )
    }
}

struct RowCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var showChevron = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(DenTheme.blue)
                .frame(width: 42, height: 42)
                .background(DenTheme.soft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundColor(DenTheme.ink).lineLimit(1)
                Text(subtitle).font(.system(size: 12)).foregroundColor(DenTheme.ink.opacity(0.5)).lineLimit(1)
            }
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DenTheme.blue.opacity(0.6))
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: DenTheme.blue.opacity(0.08), radius: 8, x: 0, y: 3)
    }
}

struct NameSheet: View {
    let title: String
    let confirm: String
    let onDone: (String) -> Void
    @State private var text: String
    @Environment(\.presentationMode) private var pm

    init(title: String, initial: String, confirm: String, onDone: @escaping (String) -> Void) {
        self.title = title; self.confirm = confirm; self.onDone = onDone
        _text = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 18) {
            Text(title).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(DenTheme.ink)
            TextField("Isim", text: $text)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(DenTheme.ink)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            HStack(spacing: 12) {
                Button("Vazgec") { pm.wrappedValue.dismiss() }
                    .frame(maxWidth: .infinity).padding(13)
                    .background(DenTheme.soft).foregroundColor(DenTheme.blue).cornerRadius(12)
                Button(confirm) {
                    let t = text.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty { onDone(t) }
                    pm.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity).padding(13)
                .background(DenTheme.gradient).foregroundColor(.white).cornerRadius(12)
            }
            Spacer()
        }
        .padding(24)
        .background(DenTheme.bg.ignoresSafeArea())
    }
}

// MARK: - Ana ekran

struct FileManagerView: View {
    @StateObject private var st = FMState()
    @State private var picking = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                DenHeader(title: "Dosyalar", subtitle: "den file manager") {
                    Button(action: { picking = true }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .padding(9)
                            .background(Color.white.opacity(0.22))
                            .clipShape(Circle())
                    }
                }
                ScrollView {
                    VStack(spacing: 10) {
                        place("Uygulama Klasoru", "iphone", URL(fileURLWithPath: NSHomeDirectory()))
                        place("Documents", "doc.fill",
                              FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0])
                        place("tmp", "clock.fill", URL(fileURLWithPath: NSTemporaryDirectory()))
                        if !st.roots.isEmpty {
                            Text("EKLENEN KLASORLER")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(DenTheme.blue)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 10)
                            ForEach(st.roots, id: \.self) { u in place(u.lastPathComponent, "folder.fill", u) }
                        }
                        Text("iOS, uygulamalarin sadece kendi klasorlerine ve sizin ekledigniz klasorlere erisimine izin verir.")
                            .font(.system(size: 11)).foregroundColor(DenTheme.ink.opacity(0.45))
                            .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .background(DenTheme.bg.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(st)
        .fileImporter(isPresented: $picking, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                if !st.roots.contains(url) { st.roots.append(url) }
            }
        }
    }

    private func place(_ name: String, _ icon: String, _ url: URL) -> some View {
        NavigationLink(destination: DirView(url: url)) {
            RowCard(icon: icon, title: name, subtitle: url.path)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Klasor

struct DirView: View {
    enum SheetKind: Identifiable {
        case folder, file, rename(URL)
        var id: String {
            switch self {
            case .folder: return "folder"
            case .file: return "file"
            case .rename(let u): return "rename" + u.path
            }
        }
    }

    let url: URL
    @EnvironmentObject private var st: FMState
    @Environment(\.presentationMode) private var pm
    @State private var items: [FileEntry] = []
    @State private var sheet: SheetKind?
    @State private var share: ShareItem?
    @State private var delTarget: URL?
    @State private var showDel = false
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            DenHeader(title: url.lastPathComponent.isEmpty ? "/" : url.lastPathComponent,
                      subtitle: url.path,
                      onBack: { pm.wrappedValue.dismiss() }) {
                Menu {
                    Button("Yeni klasor") { sheet = .folder }
                    Button("Yeni dosya") { sheet = .file }
                    if st.clip != nil { Button("Buraya yapistir") { paste() } }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .padding(9)
                        .background(Color.white.opacity(0.22))
                        .clipShape(Circle())
                }
            }

            if let e = errorText {
                Text(e).font(.system(size: 12)).foregroundColor(.red).padding(.top, 10).padding(.horizontal)
            }

            if items.isEmpty {
                Spacer()
                Text("Bu klasor bos").foregroundColor(DenTheme.ink.opacity(0.4))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(items) { e in
                            NavigationLink(destination: destination(e)) {
                                RowCard(icon: icon(e), title: e.url.lastPathComponent, subtitle: subtitle(e))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button("Yeniden adlandir") { sheet = .rename(e.url) }
                                Button("Kopyala") { st.clip = e.url; st.isMove = false }
                                Button("Tasi") { st.clip = e.url; st.isMove = true }
                                if !e.isDir { Button("Paylas") { share = ShareItem(url: e.url) } }
                                Button(role: .destructive) { delTarget = e.url; showDel = true } label: { Text("Sil") }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(DenTheme.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear(perform: load)
        .sheet(item: $sheet) { kind in
            switch kind {
            case .folder:
                NameSheet(title: "Yeni klasor", initial: "", confirm: "Olustur") { handle(kind, $0) }
            case .file:
                NameSheet(title: "Yeni dosya", initial: "not.txt", confirm: "Olustur") { handle(kind, $0) }
            case .rename(let u):
                NameSheet(title: "Yeniden adlandir", initial: u.lastPathComponent, confirm: "Kaydet") { handle(kind, $0) }
            }
        }
        .sheet(item: $share) { ShareSheet(url: $0.url) }
        .alert(isPresented: $showDel) {
            Alert(title: Text("Silinsin mi?"),
                  message: Text(delTarget?.lastPathComponent ?? ""),
                  primaryButton: .destructive(Text("Sil")) {
                      if let t = delTarget { run { try FileManager.default.removeItem(at: t) } }
                  },
                  secondaryButton: .cancel(Text("Vazgec")))
        }
    }

    // MARK: yardimcilar

    private func destination(_ e: FileEntry) -> AnyView {
        e.isDir ? AnyView(DirView(url: e.url)) : AnyView(FileView(url: e.url))
    }

    private func icon(_ e: FileEntry) -> String {
        if e.isDir { return "folder.fill" }
        let x = e.url.pathExtension.lowercased()
        if imageExts.contains(x) { return "photo.fill" }
        if textExts.contains(x) { return "doc.text.fill" }
        return "doc.fill"
    }

    private func subtitle(_ e: FileEntry) -> String {
        if e.isDir { return "Klasor" }
        var s = sizeText(e.size)
        if let d = e.date {
            let f = DateFormatter(); f.dateStyle = .short; f.timeStyle = .short
            s += "  •  " + f.string(from: d)
        }
        return s
    }

    private func load() {
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: [])
            items = urls.map { u in
                let v = try? u.resourceValues(forKeys: Set(keys))
                return FileEntry(url: u, isDir: v?.isDirectory ?? false, size: Int64(v?.fileSize ?? 0), date: v?.contentModificationDate)
            }.sorted {
                if $0.isDir != $1.isDir { return $0.isDir }
                return $0.url.lastPathComponent.lowercased() < $1.url.lastPathComponent.lowercased()
            }
            errorText = nil
        } catch {
            items = []
            errorText = "Okunamadi: \(error.localizedDescription)"
        }
    }

    private func run(_ block: () throws -> Void) {
        do { try block(); errorText = nil } catch { errorText = error.localizedDescription }
        load()
    }

    private func handle(_ kind: SheetKind, _ name: String) {
        switch kind {
        case .folder:
            run { try FileManager.default.createDirectory(at: url.appendingPathComponent(name), withIntermediateDirectories: false) }
        case .file:
            run {
                if !FileManager.default.createFile(atPath: url.appendingPathComponent(name).path, contents: Data()) {
                    throw CocoaError(.fileWriteUnknown)
                }
            }
        case .rename(let u):
            run { try FileManager.default.moveItem(at: u, to: u.deletingLastPathComponent().appendingPathComponent(name)) }
        }
    }

    private func uniqueURL(_ name: String) -> URL {
        var dest = url.appendingPathComponent(name)
        var n = 2
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        while FileManager.default.fileExists(atPath: dest.path) {
            dest = url.appendingPathComponent(ext.isEmpty ? "\(base) \(n)" : "\(base) \(n).\(ext)")
            n += 1
        }
        return dest
    }

    private func paste() {
        guard let src = st.clip else { return }
        let dest = uniqueURL(src.lastPathComponent)
        run {
            if st.isMove { try FileManager.default.moveItem(at: src, to: dest); st.clip = nil }
            else { try FileManager.default.copyItem(at: src, to: dest) }
        }
    }
}

// MARK: - Dosya goruntuleyici / duzenleyici

struct FileView: View {
    let url: URL
    @Environment(\.presentationMode) private var pm
    @State private var text = ""
    @State private var hex = ""
    @State private var image: UIImage?
    @State private var isText = false
    @State private var info = ""
    @State private var saved = false

    var body: some View {
        VStack(spacing: 0) {
            DenHeader(title: url.lastPathComponent, subtitle: info, onBack: { pm.wrappedValue.dismiss() }) {
                if isText {
                    Button(action: save) {
                        Text(saved ? "Kaydedildi ✓" : "Kaydet")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.white.opacity(0.22))
                            .clipShape(Capsule())
                    }
                }
            }
            if let img = image {
                ScrollView { Image(uiImage: img).resizable().scaledToFit().padding(16) }
            } else if isText {
                TextEditor(text: $text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(DenTheme.ink)
                    .environment(\.colorScheme, .light)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(16)
            } else {
                ScrollView {
                    Text(hex)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(DenTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
            }
        }
        .background(DenTheme.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear(perform: load)
    }

    private func load() {
        let ext = url.pathExtension.lowercased()
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        info = sizeText(Int64(size))

        if imageExts.contains(ext), let img = UIImage(contentsOfFile: url.path) {
            image = img; return
        }
        if textExts.contains(ext), let data = try? Data(contentsOf: url) {
            if ext == "plist",
               let obj = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
               let xml = try? PropertyListSerialization.data(fromPropertyList: obj, format: .xml, options: 0),
               let s = String(data: xml, encoding: .utf8) {
                text = s; isText = true; return
            }
            if let s = String(data: data, encoding: .utf8) { text = s; isText = true; return }
        }
        if let h = try? FileHandle(forReadingFrom: url) {
            hex = hexDump(h.readData(ofLength: 4096))
            if size > 4096 { hex += "\n... (ilk 4 KB gosteriliyor)" }
            try? h.close()
        } else {
            hex = "Dosya okunamadi."
        }
    }

    private func save() {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            saved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { saved = false }
        } catch {
            info = "Kaydedilemedi: \(error.localizedDescription)"
        }
    }
}
