import SwiftUI
 
@main
struct LumiApp: App {
    @State private var store = TaskStore()
 
    var body: some Scene {
        WindowGroup {
            User()
                .environment(store)
                .preferredColorScheme(.light)
                .tint(.black)
                .task { await APIService.prefetch() }   // warm up music covers and books
        }
    }
}
