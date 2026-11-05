import SwiftUI

struct AdditionalTaskSlot: View {
    @Environment(TaskStore.self) private var store
    let slot: Int       // 0 = left, 1 = right

    var body: some View {
        if let task = store.nextTask(at: slot) {
            filledCard(task)
        } else {
            emptyCard
        }
    }


    private var emptyTint: [Color] {
        if slot == 0 {
            return [Color(red: 0.92, green: 0.89, blue: 0.99),
                    Color(red: 0.99, green: 0.93, blue: 0.90)]
        } else {
            return [Color(red: 0.86, green: 0.95, blue: 0.91),
                    Color(red: 0.99, green: 0.96, blue: 0.88)]
        }
    }

    private var emptySymbol: String {
        slot == 0 ? "film" : "book.closed"
    }

    private var emptyCard: some View {
        Button {
            store.openCountries(forNextSlot: slot)
        } label: {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: emptyTint,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: emptySymbol)
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.07))
                    .rotationEffect(.degrees(-12))
                    .padding(14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(slot == 0 ? "UP NEXT" : "AFTER THAT")
                        .font(.caption2.weight(.heavy))
                        .tracking(1)
                        .foregroundStyle(.black)

                    Text("Add a task")
                        .font(.headline.weight(.heavy))


                    Spacer(minLength: 0)

                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.black, in: Circle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(16)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .shadow(color: .black.opacity(0.10), radius: 10, y: 6)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Add next task")
    }


    private func filledCard(_ task: Item) -> some View {
        ZStack {
            PhotoView(name: task.photo, url: task.imageURL)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .clipped()

            EdgeShade() //selfexplanatory

            VStack {
                HStack {
                    Spacer()
                    Text(task.name)
                        .font(.subheadline.weight(.heavy))
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .photoBubble(in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer(minLength: 4)

                HStack {
                    Spacer()

                    Button("Change Task") {
                        store.openCountries(forNextSlot: slot)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .photoBubble(in: Capsule())
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

#Preview {
    HStack(spacing: 12) {
        AdditionalTaskSlot(slot: 0)
        AdditionalTaskSlot(slot: 1)
    }
    .padding(20)
    .background(Color.appBackground)
    .environment(TaskStore())
}
