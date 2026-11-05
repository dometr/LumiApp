import SwiftUI

struct ItemsView: View {
    let category: Category

    @Environment(TaskStore.self) private var store
    @State private var selectedItem: Item?

    // Not completed works
    private var availableItems: [Item] {
        category.items.filter { !$0.watched }
    }

    private func isBeingReplaced(_ item: Item) -> Bool {
        store.targetTask?.id == item.id
    }

    private var highlightLabel: String {
        switch store.chooseTarget {
        case .current:
            return "CURRENT TASK"
        case .next(let slot):
            return slot == 0 ? "UP NEXT" : "AFTER THAT"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(category.name.uppercased())
                    .font(.title.weight(.heavy))

                ForEach(availableItems) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        RowCard(showsChevron: false) {
                            PhotoView(name: item.photo)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            VStack(alignment: .leading, spacing: 4) {
                                if isBeingReplaced(item) {
                                    Text(highlightLabel)
                                        .font(.caption2.weight(.heavy))
                                        .tracking(1)
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.appGreen, in: Capsule())
                                }

                                Text(item.name)
                                    .font(.title3.weight(.bold))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        // Green border on task being replaced
                        .overlay {
                            if isBeingReplaced(item) {
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.appGreen, lineWidth: 3)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                if availableItems.isEmpty {
                    Text("You've completed everything in this category!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(Color.appBackground)
        }
    }
}

#Preview {
    NavigationStack {
        ItemsView(category: infoData.countries[0].categories[0])
    }
    .environment(TaskStore())
}
