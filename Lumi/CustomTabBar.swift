import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabType
    @Namespace private var animation
    
    var body: some View {
        HStack {
            ForEach(TabType.allCases, id: \.rawValue) { tab in
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }) {
                    ZStack {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color.appTan.opacity(0.4)) // Colore della palette
                                .matchedGeometryEffect(id: "slidingBar", in: animation)
                                .frame(width: 60, height: 40)
                        }
                        
                        // Icon
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(selectedTab == tab ? .appDarkGreen : .appTabInactive)
                    }
                    .frame(width: 60, height: 50)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule())
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 30)
        .padding(.bottom, 10)
    }
}
