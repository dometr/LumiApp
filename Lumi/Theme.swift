import SwiftUI

struct RowCard<Content: View>: View {
    let showsChevron: Bool
    let content: Content

    init(showsChevron: Bool = true, @ViewBuilder content: () -> Content) {
        self.showsChevron = showsChevron
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 14) {
            content

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}

extension View {
    func photoBubble<S: Shape>(in shape: S) -> some View {
        self
            .foregroundStyle(.black)
            .background {
                shape
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2) // shadows to make text more readable
            }
    }
}

struct EdgeShade: View {
    var cornerRadius: CGFloat = 32

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.55), location: 0.0),
                    .init(color: .black.opacity(0.0), location: 0.40),
                    .init(color: .black.opacity(0.0), location: 0.55),
                    .init(color: .black.opacity(0.60), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.35), lineWidth: 12)
                .blur(radius: 10)
        }
        .allowsHitTesting(false)
    }
}

extension Color {
    static let plusGray = Color(red: 0.29, green: 0.31, blue: 0.28)
}

// "pressure" effect : when pressed the bubble becomes smaller
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}
