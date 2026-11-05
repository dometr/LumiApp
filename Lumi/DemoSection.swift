// xcode: set sdk=iOS

import SwiftUI
import AVFoundation
import SafariServices

// Plays a short audio clip and reports how far it is (0...1)
@MainActor @Observable
final class ClipPlayer {
    var isPlaying = false
    var progress: Double = 0

    private var player: AVPlayer?
    private var endObserver: Any?
    private var timeObserver: Any?

    func toggle(url: URL) {
        if isPlaying { stop(); return }
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)

        let p = AVPlayer(url: url)
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: p.currentItem, queue: .main
        ) { [weak self] _ in
            guard let self = self else { return } // Converts weak var to a strong let
            Task { @MainActor in self.stop() }
        }

        timeObserver = p.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            Task { @MainActor in self.progress = min(max(time.seconds / 30, 0), 1) }
        }
        player = p
        progress = 0
        p.play()
        isPlaying = true
    }

    func stop() {
        if let t = timeObserver { player?.removeTimeObserver(t) }
        timeObserver = nil
        if let e = endObserver { NotificationCenter.default.removeObserver(e) }
        endObserver = nil
        player?.pause()
        player = nil
        isPlaying = false
        progress = 0
    }
}

struct WebLink: Identifiable {
    let id = UUID()
    let url: URL
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

// "Demo" of a work: 30 s of the song, the film trailer, the first lines of the book
struct DemoSection: View {
    let item: Item

    @State private var player = ClipPlayer()
    @State private var loading = true
    @State private var audioURL: URL?
    @State private var trailerURL: URL?
    @State private var firstLine = ""
    @State private var about = ""
    @State private var bookURL: URL?
    @State private var web: WebLink?

    private var hasBookText: Bool { !firstLine.isEmpty || !about.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if loading {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Loading demo…")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.vertical, 6)
            }

            if let audioURL {
                Button { player.toggle(url: audioURL) } label: {
                    Label(player.isPlaying ? "Stop" : "Listen to a 30-second clip",
                          systemImage: player.isPlaying ? "stop.fill" : "play.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appTan.opacity(0.5), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            if let trailerURL { movieCard(trailerURL) }
            if hasBookText || bookURL != nil { bookCard }
        }
        .task { await load() }
        .onDisappear { player.stop() }
        .sheet(item: $web) { link in
            SafariView(url: link.url).ignoresSafeArea()
        }
    }

    

    // MARK: - Movie: poster with a play button, like a video cover

    private func movieCard(_ url: URL) -> some View {
        Button { web = WebLink(url: url) } label: {
            ZStack(alignment: .bottomLeading) {
                PhotoView(name: "", url: item.imageURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()

                LinearGradient(colors: [.clear, .black.opacity(0.65)],
                               startPoint: .center, endPoint: .bottom)

                Image(systemName: "play.fill")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.appGreen)
                    .frame(width: 68, height: 68)
                    .background(Circle().fill(.white.opacity(0.92)))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 2) {
                    Text("OFFICIAL TRAILER")
                        .font(.caption2.weight(.heavy))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(item.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(16)
            }
            .frame(height: 200)
            .background(Color.appGreen)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Book: a page with the first line

    private var bookCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("A TASTE OF THE BOOK")
                .font(.caption2.weight(.heavy))
                .tracking(1)
                .foregroundStyle(Color.appGreen)

            if !firstLine.isEmpty {
                Text(verbatim: "“")
                    .font(.system(size: 54, weight: .bold, design: .serif))
                    .foregroundStyle(Color.appGreen.opacity(0.35))
                    .frame(height: 30, alignment: .top)
                Text(firstLine)
                    .font(.system(.title3, design: .serif).italic())
                    .foregroundStyle(.black)
            }

            if !about.isEmpty {
                if !firstLine.isEmpty { Divider().padding(.vertical, 4) }
                Text(about)
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.8))
            }

            if let bookURL {
                Button { web = WebLink(url: bookURL) } label: {
                    HStack(spacing: 6) {
                        Text("Open the book page")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.appGreen))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appTan.opacity(0.3), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Data

    private func load() async {
        switch item.kind {
        case ItemKind.music.rawValue:
            audioURL = await APIService.musicPreview(for: item).flatMap { URL(string: $0) }
        case ItemKind.movies.rawValue:
            trailerURL = await APIService.trailer(for: item).flatMap { URL(string: $0) }
        case ItemKind.books.rawValue:
            let b = await APIService.bookPreview(for: item)
            firstLine = b.first
            about = b.about
            bookURL = URL(string: b.link)
        default:
            break
        }
        loading = false
    }
}
