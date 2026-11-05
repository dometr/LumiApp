import SwiftUI

struct CategoriesView: View {
    let country: Country

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("\(country.flag) \(country.name.uppercased())")
                    .font(.title.weight(.heavy))

                ForEach(country.categories) { category in
                    NavigationLink(destination: ItemsView(category: category)) {
                        RowCard {
                            Image(systemName: category.icon)
                                .font(.title3.weight(.bold))
                                .frame(width: 48, height: 48)
                                .overlay(Circle().stroke(.black, lineWidth: 2))

                            Text(category.name)
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
        CategoriesView(country: infoData.countries[0])
    }
}
