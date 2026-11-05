import SwiftUI

struct CountriesView: View {
    var myData = infoData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("COUNTRIES")
                    .font(.title.weight(.heavy))

                ForEach(myData.countries) { country in
                    NavigationLink(destination: CategoriesView(country: country)) {
                        RowCard {
                            Text(country.flag)
                                .font(.title)
                            Text(country.name)
                                .font(.title3.weight(.bold))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CountriesView()
    }
}
