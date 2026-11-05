import SwiftUI

struct CountryLine: View {
    let code: String

    var body: some View {
        let country = WorldCountry(code: code)
        Text(verbatim: "\(country.flag)  \(country.name)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.black)
    }
}

struct ItemDetailSheet: View {
    let item: Item

    @Environment(\.dismiss) private var dismiss
    @Environment(TaskStore.self) private var store
    @State private var working = false
    @State private var showPicker = false
    @State private var country = ""         // ISO alpha-2 of the work, found when the details open
    @State private var searching = false    // true while the country is being looked up

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PhotoView(name: item.photo, url: item.imageURL)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 32))

                Text(item.name)
                    .font(.title.weight(.heavy))

                VStack(alignment: .leading, spacing: 6) {
                    // Author and year
                    if !item.author.isEmpty || !item.year.isEmpty {
                        HStack {
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
                    countryRow
                }

                // Rating
                if !item.rating.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(item.rating)
                            .font(.subheadline.weight(.bold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.2), in: Capsule())
                }

                // Description
                if !item.details.isEmpty {
                    Text(item.details)
                        .font(.body)
                }
                
                DemoSection(item: item)

                Button {
                    Task { await choose() }
                } label: {
                    Group {
                        if working || searching {
                            ProgressView().tint(.white)
                        } else {
                            Text(store.targetHasTask ? "Change Task" : "Choose Task")
                        }
                    }
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.black, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(working || searching)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .task { await findCountry() }
        .sheet(isPresented: $showPicker) {
            CountryPickerSheet { code in
                var picked = item
                picked.countryCode = code
                finish(picked)
            }
        }
    }

    @ViewBuilder
    private var countryRow: some View {
        if !country.isEmpty {
            CountryLine(code: country)
        } else if searching {
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Finding country…")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.black)
            }
        } else {
            Text("Country unknown")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.black)
        }
    }

    // The globe needs a country: found automatically for movies, books and music
    private func lookupCountry(for work: Item) async -> String {
        if work.kind == ItemKind.movies.rawValue {
            return await APIService.movieCountry(externalID: work.externalID) ?? ""
        }
        return await CountryLookup.country(for: work) ?? ""
    }

    // Runs when the details open, so the country can be shown right away
    private func findCountry() async {
        if !item.countryCode.isEmpty {
            country = item.countryCode
            return
        }
        searching = true
        country = await lookupCountry(for: item)
        searching = false
    }

    private func choose() async {
        var picked = item
        picked.countryCode = item.countryCode.isEmpty ? country : item.countryCode   // already found above
        if picked.countryCode.isEmpty {
            // the lookup found nothing (e.g. no connection): try once more
            working = true
            picked.countryCode = await lookupCountry(for: picked)
            working = false
        }
        finish(picked)
    }

    private func finish(_ picked: Item) {
        store.choose(picked)
        dismiss()
    }
}

#Preview {
    ItemDetailSheet(
        item: Item(
            photo: "esempio",
            name: "Title",
            author: "Author",
            year: "2000",
            details: "description",
            rating: "8.5/10 (TMDB)"
        )
    )
    .environment(TaskStore())
}
