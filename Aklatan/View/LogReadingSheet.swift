import SwiftUI

struct LogReadingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accentTheme) private var theme
    @EnvironmentObject private var activity: ReadingActivityStore
    @EnvironmentObject private var library: LibraryStore

    let book: Book
    @State private var minutes = 20
    @State private var progress: Double
    @State private var finished = false

    init(book: Book) {
        self.book = book
        _progress = State(initialValue: book.progress)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading time") {
                    Stepper("\(minutes) minutes", value: $minutes, in: 5...240, step: 5)
                }

                Section("Progress") {
                    Slider(value: $progress, in: 0...1, step: 0.01)
                        .tint(theme.color)
                    Text("\(Int(progress * 100))% complete")
                        .foregroundStyle(Palette.muted)
                    Toggle("Mark as finished", isOn: $finished)
                }
            }
            .navigationTitle("Log Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            let storedBook = library.resolvedBook(book)
            progress = storedBook.progress
            finished = library.status(of: storedBook) == .finished
        }
    }

    private func save() {
        let finalProgress = finished ? 1 : progress
        let storedBook = library.resolvedBook(book)
        activity.logSession(for: storedBook, minutes: minutes, progressAfter: finalProgress)
        library.updateProgress(for: storedBook, progress: finalProgress)

        if finished {
            activity.markFinished(storedBook)
            library.markFinished(storedBook)
        }
        dismiss()
    }
}
