import SwiftUI
import ComposableArchitecture


struct Feature: ReducerProtocol {
    struct State: Equatable {
        /// 현재 값
        var count = 0
        /// 화면에 표시할 alert 의 title
        var numberFactAlert: String?
    }
    
    /// 사용자 action 에 대한 타입
    enum Action: Equatable {
        case factAlertDismissed
        case decrementButtonTapped
        case incrementButtonTapped
        case numberFactButtonTapped
        case numberFactResponse(TaskResult<String>)
    }
    
    // State 를 inout 으로 받음
    // 클로저에서는 mutate 할 수 없다
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .factAlertDismissed:
            state.numberFactAlert = nil
            return .none
        case .decrementButtonTapped:
            state.count -= 1
            return .none
        case .incrementButtonTapped:
            state.count += 1
            return .none
        case .numberFactButtonTapped:
            // inout 으로 받아온 State 를 변경하는 방식
            return .task { [count = state.count] in
                await .numberFactResponse(
                    TaskResult {
                        String(
                            decoding: try await URLSession.shared
                                .data(from: URL(string: "http://numbersapi.com/\(count)/trivia")!).0,
                            as: UTF8.self
                        )
                    }
                )
            }
        case let .numberFactResponse(.success(fact)):
            state.numberFactAlert = fact
            return .none
        case .numberFactResponse(.failure):
            state.numberFactAlert = "Could not load a number fact"
            return .none
        }
    }
}

struct FeatureView: View {
    // state에 대한 모든 변경을 관찰(observe) 하고 다시 렌더링할 수 있도록 StoreOf<Feature> 을 유지
    // 모든 사용자 action 을 store 로 보내서 state 를 변경할 수 있다
  let store: StoreOf<Feature>

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        HStack {
          Button("−") { viewStore.send(.decrementButtonTapped) }
          Text("\(viewStore.count)")
          Button("+") { viewStore.send(.incrementButtonTapped) }
        }

        Button("Number fact") { viewStore.send(.numberFactButtonTapped) }
      }
      .alert(
        item: viewStore.binding(
          get: { $0.numberFactAlert.map(FactAlert.init(title:)) },
          send: .factAlertDismissed
        ),
        content: { Alert(title: Text($0.title)) }
      )
    }
  }
}

struct FactAlert: Identifiable {
    var title: String
    var id: String { self.title }
}

// MARK: - ContentView
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
