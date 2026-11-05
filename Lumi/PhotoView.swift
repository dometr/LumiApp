import SwiftUI
import UIKit
import CryptoKit

// Downloads each picture once and keeps it on the phone (memory + disk), so it shows instantly
// next time, even without internet.
actor ImageStore {
    static let shared = ImageStore()

    private let memory = NSCache<NSString, NSData>()
    private let folder: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("LumiImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private func file(_ url: String) -> URL {
        let name = SHA256.hash(data: Data(url.utf8)).map { String(format: "%02x", $0) }.joined()
        return folder.appendingPathComponent(name)
    }

    func data(for url: String) async -> Data? {
        if let m = memory.object(forKey: url as NSString) { return m as Data }

        let f = file(url)
        if let d = try? Data(contentsOf: f) {
            memory.setObject(d as NSData, forKey: url as NSString)
            return d
        }

        guard let u = URL(string: url) else { return nil }
        var r = URLRequest(url: u)
        r.timeoutInterval = 20
        r.setValue("LumiApp (student project)", forHTTPHeaderField: "User-Agent")
        guard let (d, resp) = try? await URLSession.shared.data(for: r),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              UIImage(data: d) != nil else { return nil }

        try? d.write(to: f)
        memory.setObject(d as NSData, forKey: url as NSString)
        return d
    }

    // Downloads many pictures in the background, 6 at a time
    func prefetch(_ urls: [String]) async {
        var seen = Set<String>()
        let list = urls.filter { !$0.isEmpty && seen.insert($0).inserted }
        var start = 0
        while start < list.count {
            let chunk = Array(list[start..<min(start + 6, list.count)])
            await withTaskGroup(of: Void.self) { group in
                for u in chunk { group.addTask { _ = await ImageStore.shared.data(for: u) } }
            }
            start += 6
        }
    }
}

// Shows an image from a URL (API) or from Assets (legacy)
struct PhotoView: View {
    let name: String
    var url: String = ""
    @State private var loaded: UIImage?

    var body: some View {
        if !url.isEmpty {
            Group {
                if let loaded {
                    Image(uiImage: loaded)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            }
            .task(id: url) {
                if let d = await ImageStore.shared.data(for: url) {
                    loaded = UIImage(data: d)
                }
            }
        } else if UIImage(named: name) != nil {
            Image(name)
                .resizable()
                .scaledToFill()
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.15)
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
        }
    }
}

// Profile photo during onboarding otherwise grey avatar
struct AvatarView: View {
    @AppStorage("savedProfileImageData") private var savedProfileImageData: Data?

    var body: some View {
        if let savedProfileImageData, let uiImage = UIImage(data: savedProfileImageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.appLightGray)
        }
    }
}

#Preview {
    PhotoView(name: "esempio")
        .frame(width: 50, height: 50)
}
