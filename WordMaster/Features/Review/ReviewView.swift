import SwiftUI

struct ReviewView: View {
    @StateObject private var viewModel: ReviewViewModel

    init(context: AppContext) {
        _viewModel = StateObject(wrappedValue: ReviewViewModel(context: context))
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            if let word = viewModel.currentWord {
                card(for: word)
                actionBar
            } else {
                emptyState
            }

            if !viewModel.notice.isEmpty {
                Text(viewModel.notice)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .navigationTitle("复习")
        .task { await viewModel.loadQueue() }
    }

    private var header: some View {
        HStack {
            Text("今日队列")
                .font(.headline)
            Spacer()
            Text(viewModel.progressText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func card(for word: WordItem) -> some View {
        Button {
            Task { await viewModel.tapCard() }
        } label: {
            VStack(spacing: 10) {
                Text(word.zhText)
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)
                if viewModel.showEnglish {
                    Text(word.enWord)
                        .font(.title3)
                        .foregroundStyle(.blue)
                } else {
                    Text("点击卡片表示“会”")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var actionBar: some View {
        HStack {
            Button("英文翻译") { viewModel.revealEnglish() }
                .buttonStyle(.bordered)

            Spacer()
            Button("刷新队列") { Task { await viewModel.loadQueue() } }
                .buttonStyle(.bordered)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("当前没有待复习单词")
                .font(.headline)
            Button("重新加载") {
                Task { await viewModel.loadQueue() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
    }
}

