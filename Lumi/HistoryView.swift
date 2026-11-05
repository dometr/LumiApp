import SwiftUI

//Detailed history view containing various details about each task
struct HistoryView: View {
    @Environment(TaskStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if store.completedTasks.isEmpty {
                    Text("Your completed tasks will appear here.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                }

                ForEach(store.completedTasks) { completed in
                    HistoryRow(completed: completed)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 120)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HistoryRow: View {
    let completed: CompletedTask

    private var item: Item { completed.item }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {

            // poster
            PhotoView(name: item.photo, url: item.imageURL)
                .frame(width: 85, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {

                // Points
                HStack(alignment: .center, spacing: 6) {
                    Image(systemName: "medal.fill")
                        .font(.title3)
                        .foregroundColor(.appTan)

                    Text("\(completed.points) pts")
                        .font(.title.weight(.heavy))
                        .foregroundColor(.black)
                }

                // Title
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(2)

                // Author and year
                if !item.author.isEmpty || !item.year.isEmpty {
                    HStack(spacing: 4) {
                        Text(item.author)
                        if !item.author.isEmpty && !item.year.isEmpty {
                            Text("·")
                        }
                        Text(item.year)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
                }

                // Country of origin
                if !item.countryCode.isEmpty {
                    CountryLine(code: item.countryCode)
                }

                // Rating
                if !item.rating.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(item.rating)
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
                }

                // description
                if !item.details.isEmpty {
                    Text(item.details)
                        .font(.callout)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }

                // date of completion
                Text(completed.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.black)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    NavigationStack { HistoryView() }
        .environment(historyPreviewStore)
}

private let historyPreviewStore: TaskStore = {
    let store = TaskStore()
    store.completedTasks = [
        CompletedTask(
            item: Item(photo: "esempio", name: "Titolo", author: "Autore", year: "2000",
                       details: "Qui va la descrizione dell'opera.", rating: "8.5/10 (IMDb)"),
            points: 850,
            date: .now
        )
    ]
    return store
}()
