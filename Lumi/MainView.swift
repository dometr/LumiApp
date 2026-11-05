import SwiftUI

struct MainView: View {
    @Environment(TaskStore.self) private var store
    @State private var selectedTab: TabType = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground.ignoresSafeArea()
            
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .globe:
                    GlobeView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Hidden while the task search screen is open, so it never covers the list
            if !store.showCountries {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.showCountries)
    }
}

#Preview {
    MainView()
        .environment(TaskStore())
}
