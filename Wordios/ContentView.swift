//
//  ContentView.swift
//  Wordios
//
//  Created by Костенко Крістіна on 20.11.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionViewModel: FlashcardSessionViewModel

    init() {
        let repository = MockDictionaryRepository()
        let firstModuleId = repository.fetchModules().first?.id ?? UUID()
        _sessionViewModel = StateObject(
            wrappedValue: FlashcardSessionViewModel(
                moduleId: firstModuleId,
                repository: repository,
                strategy: SequentialStrategy()
            )
        )
    }

    var body: some View {
        NavigationView {
            FlashcardSessionView(viewModel: sessionViewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
