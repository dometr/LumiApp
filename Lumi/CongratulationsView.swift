import SwiftUI

struct CongratulationsView: View {
    @Environment(TaskStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var appeared = false
    @State private var shownPoints = 0
    @State private var shownTotal = 0

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ConfettiView()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Medal
                    ZStack {
                        Circle()
                            .fill(Color.yellow.opacity(0.25))
                        Circle()
                            .stroke(.black, lineWidth: 3)
                        Image(systemName: "medal.fill")
                            .font(.system(size: 54))
                            .foregroundStyle(.yellow)
                            .shadow(color: .black.opacity(0.25), radius: 2, y: 2)
                            .symbolEffect(.bounce, value: appeared)
                    }
                    .frame(width: 124, height: 124)
                    .scaleEffect(appeared ? 1 : 0.2)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 20) {
                        Text("CONGRATULATIONS!")
                            .font(.system(size: 34, weight: .heavy))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)

                        if let task = store.finishedTask {
                            Text("You completed this task")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.black)

                            // Poster
                            PhotoView(name: task.photo, url: task.imageURL)
                                .frame(width: 150, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(.white, lineWidth: 4)
                                )
                                .rotationEffect(.degrees(-3))
                                .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                                .padding(.vertical, 6)

                            Text(task.name)
                                .font(.title2.weight(.heavy))
                                .multilineTextAlignment(.center)

                            pointsCard(for: task)
                        }

                        totalRow
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
                }
                .padding(24)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        // Button
        .safeAreaInset(edge: .bottom) {
            Button {
                store.promoteNextTask()
                dismiss()
            } label: {
                Text("Back to Home")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Color.black, in: Capsule())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            shownTotal = store.points - store.earnedPoints

            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                appeared = true
            }
            // points increasing animation
            withAnimation(.easeOut(duration: 1.6).delay(0.5)) {
                shownPoints = store.earnedPoints
                shownTotal = store.points
            }
        }
    }

    // Bubble with points
    private func pointsCard(for task: Item) -> some View {
        VStack(spacing: 6) {
            Text("POINTS EARNED")
                .font(.footnote.weight(.heavy))
                .tracking(1)
                .foregroundStyle(.black)

            Text("+\(shownPoints)")
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(shownPoints)))

            if store.earnedPoints > 0, let rating = store.ratingNumber(of: task) {
                Text("Rating \(String(format: "%g", rating)) × 100")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
            } else {
                Text("Standard points for this work.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 32))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }

    private var totalRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "medal.fill")
                .font(.title3)

            Text("TOTAL SCORE")
                .font(.headline.weight(.heavy))

            Spacer()

            Text("\(shownTotal)")
                .font(.title2.weight(.heavy))
                .monospacedDigit()
                .contentTransition(.numericText(value: Double(shownTotal)))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
    }
}


struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x = CGFloat.random(in: 0...1)
    let drift = CGFloat.random(in: -60...60)
    let width = CGFloat.random(in: 6...11)
    let delay = Double.random(in: 0...1.2)
    let duration = Double.random(in: 2.4...4.2)
    let spin = Double.random(in: 180...720)
    let color: Color

    init() {
        let colors: [Color] = [.yellow, .orange, .pink, .red, .blue, .green, .purple]
        color = colors.randomElement() ?? .yellow
    }
}

struct ConfettiView: View {
    @State private var pieces = (0..<60).map { _ in ConfettiPiece() }
    @State private var fall = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.width, height: piece.width * 1.8)
                    .rotationEffect(.degrees(fall ? piece.spin : 0))
                    .position(x: piece.x * geo.size.width + (fall ? piece.drift : 0),
                              y: fall ? geo.size.height + 40 : -40)
                    .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: fall)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            fall = true
        }
    }
}

#Preview {
    let store = TaskStore()
    store.finishedTask = Item(photo: "esempio",
                              name: "La Dolce Vita",
                              author: "Federico Fellini",
                              year: "1960",
                              details: "",
                              rating: "8.0/10 (IMDb)")
    store.earnedPoints = 800
    store.completedTasks = [
        CompletedTask(item: store.finishedTask!, points: 800, date: .now)
    ]
    return CongratulationsView()
        .environment(store)
}
