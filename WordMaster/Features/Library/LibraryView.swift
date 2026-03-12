import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @State private var pendingDeletion: WordItem?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    init(context: AppContext) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(context: context))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if viewModel.loading {
                        ProgressView("正在加载词库...")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !viewModel.notice.isEmpty {
                        noticeView(viewModel.notice)
                    }

                    if viewModel.words.isEmpty, !viewModel.loading {
                        ContentUnavailableView(
                            "暂无词条",
                            systemImage: "books.vertical",
                            description: Text("请先到“添加”页录入单词")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.words) { word in
                                wordCard(word)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())

            if let message = viewModel.feedbackMessage {
                feedbackBanner(message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1)
            }
        }
        .animation(
            reduceMotion ? .none : .spring(response: 0.32, dampingFraction: 0.88),
            value: viewModel.feedbackMessage != nil
        )
        .navigationTitle("库")
        .task { await viewModel.loadWords() }
        .refreshable { await viewModel.loadWords() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("刷新") { Task { await viewModel.loadWords() } }
            }
        }
        .confirmationDialog(
            "删除词条",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let word = pendingDeletion {
                Button("删除“\(word.enWord)”", role: .destructive) {
                    let wordId = word.id
                    pendingDeletion = nil
                    Task { await viewModel.deleteWord(id: wordId) }
                }
            }
            Button("取消", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            if let word = pendingDeletion {
                Text("删除后不可恢复，确认删除“\(word.zhText) / \(word.enWord)”吗？")
            }
        }
    }

    private func wordCard(_ word: WordItem) -> some View {
        let deleting = viewModel.deletingWordIds.contains(word.id)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(word.zhText)
                        .font(.headline)
                        .lineLimit(2)

                    Text(word.enWord)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button(role: .destructive) {
                    pendingDeletion = word
                } label: {
                    HStack(spacing: 6) {
                        if deleting {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "trash")
                        }
                        Text(deleting ? "删除中" : "删除")
                    }
                    .frame(minWidth: 88, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(deleting)
                .accessibilityLabel("删除 \(word.enWord)")
            }

            HStack(spacing: 12) {
                Label("阶段 \(word.stage)", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.blue.opacity(0.12), in: Capsule())

                Label(word.isMastered ? "已掌握" : "进行中", systemImage: word.isMastered ? "checkmark.seal.fill" : "circle.dotted")
                    .font(.caption)
                    .foregroundStyle(word.isMastered ? .green : .orange)

                Spacer()

                Text("下次复习 \(dateFormatter.string(from: word.nextReviewDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func noticeView(_ text: String) -> some View {
        Label(text, systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func feedbackBanner(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}
