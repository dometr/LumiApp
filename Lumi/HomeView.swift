import SwiftUI

struct HomeView: View {
    @Environment(TaskStore.self) private var store
    @AppStorage("savedUsername") private var savedUsername: String = ""

    var body: some View {
        @Bindable var store = store

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    Text("CURRENT TASK")
                        .font(.headline.weight(.heavy))

                    if let task = store.currentTask {
                        currentTaskCard(task)
                    } else {
                        currentTaskPlaceholder
                    }

                    nextTaskSection
                }
                .padding(20)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .background(Color.appBackground.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $store.showCountries) {
                SearchView()
            }
            .fullScreenCover(isPresented: $store.showCongrats) {
                CongratulationsView()
            }
        }
    }


    private var header: some View {
        HStack(spacing: 14) {
            AvatarView()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .overlay(Circle().stroke(.black, lineWidth: 2))

            Text("Hi, \(savedUsername)!")
                .font(.title2.weight(.heavy))

            Spacer()

            Image(systemName: "medal.fill")
            Text("\(store.points)")
                .font(.title3.weight(.heavy))
        }
    }

    // MARK: - Current task

    private func currentTaskCard(_ task: Item) -> some View {
        ZStack {
            PhotoView(name: task.photo, url: task.imageURL)
                .frame(maxWidth: .infinity)
                .frame(height: 290)
                .clipped()

            EdgeShade()

            VStack {
                HStack {
                    Spacer()
                    Text(task.name)
                        .font(.title.weight(.heavy))
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .photoBubble(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                Spacer()

                HStack {
                    Button("Update Progress") {
                        store.finishCurrentTask()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .photoBubble(in: Capsule())

                    Spacer()

                    Button("Change Task") {
                        store.openCountries()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .photoBubble(in: Capsule())
                }
            }
            .padding(16)
        }
        .frame(height: 290)
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }

    private var currentTaskPlaceholder: some View {
        Button {
            store.openCountries()
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    decoTile("book.closed", angle: -10, x: -66, y: 8)
                    decoTile("music.note", angle: 10, x: 66, y: 8)
                    decoTile("film", angle: 0, x: 0, y: -4)
                }
                .frame(height: 96)

                Text("Start your next task")
                    .font(.title2.weight(.heavy))
                    .padding(.top, 10)

                Text("Search any movie, song or book and earn points.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 6)

                Text("Choose a task")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.black, in: Capsule())
                    .padding(.top, 14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 290)
            .background(
                LinearGradient(
                    colors: [Color(red: 1.00, green: 0.91, blue: 0.83),
                             Color(red: 0.99, green: 0.82, blue: 0.84)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 32)
            )
            .shadow(color: .black.opacity(0.10), radius: 14, y: 8)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Choose a task")
    }

    private func decoTile(_ icon: String, angle: Double, x: CGFloat, y: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.white.opacity(0.7))
            .frame(width: 62, height: 80)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.75))
            )
            .shadow(color: .black.opacity(0.12), radius: 6, y: 4)
            .rotationEffect(.degrees(angle))
            .offset(x: x, y: y)
    }

    // MARK: - Next task

    private var nextTaskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEXT TASK")
                .font(.headline.weight(.heavy))

            HStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { slot in
                    if slot < store.visibleNextSlots {
                        AdditionalTaskSlot(slot: slot)
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity)
                            .frame(height: 150)
                    }
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.85), value: store.nextTasks.count)
        }
    }
}

#Preview {
    HomeView()
        .environment(TaskStore())
}
