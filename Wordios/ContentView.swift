import SwiftUI

/// Точка входу до інтерфейсу. Навігація й залежності зібрані в AppRouter.
struct ContentView: View {
    var body: some View {
        AppRouter()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
