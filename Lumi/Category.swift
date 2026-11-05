import Foundation

struct Category: Identifiable {
    let id = UUID()
    var name: String
    var icon: String    
    var items: [Item]
}
