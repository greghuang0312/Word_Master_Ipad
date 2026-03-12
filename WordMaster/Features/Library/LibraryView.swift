import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel

    init(context: AppContext) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(context: context))
    }

    var body: some View {
        List {
            ForEach(viewModel.words) { word in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(word.zhText)
                            .font(.headline)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        Text(word.enWord)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }

                    HStack {
                        Label("阶段 \(word.stage)", systemImage: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Spacer()
                        Text(word.isMastered ? "已掌握" : "进行中")
                            .font(.caption)
                            .foregroundStyle(word.isMastered ? .green : .orange)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete { offsets in
                Task { await viewModel.deleteWord(at: offsets) }
            }
        }
        .overlay {
            if viewModel.words.isEmpty {
                ContentUnavailableView("暂无词条", systemImage: "books.vertical", description: Text("请先到“添加”页录入单词"))
            }
        }
        .navigationTitle("库")
        .task { await viewModel.loadWords() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("刷新") { Task { await viewModel.loadWords() } }
            }
        }
    }
}

