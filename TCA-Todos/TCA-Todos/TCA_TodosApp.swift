import SwiftUI
import ComposableArchitecture

@main
struct TCA_TodosApp: App {
    var body: some Scene {
        WindowGroup {
            FeatureView(store: Store(
                initialState: Feature.State(),
                reducer: Feature()
                )
            )
        }
    }
}
