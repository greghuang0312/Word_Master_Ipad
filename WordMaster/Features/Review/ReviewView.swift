import SwiftUI

struct ReviewView: View {
    @StateObject private var viewModel: ReviewViewModel
    private let isActive: Bool

    init(context: AppContext, isActive: Bool) {
        _viewModel = StateObject(wrappedValue: ReviewViewModel(context: context))
        self.isActive = isActive
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerCard

                    if let word = viewModel.currentWord {
                        card(for: word)
                        actionBar
                    } else {
                        emptyState
                    }

                    if !viewModel.notice.isEmpty {
                        noticeSection(viewModel.notice)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .blur(radius: viewModel.loading ? 1.5 : 0)

            if viewModel.loading {
                syncOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .navigationTitle("复习")
        .task(id: isActive) {
            guard isActive else { return }
            await viewModel.loadQueue()
        }
    }

    private var headerCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日队列")
                    .font(.headline)
                Text("按卡片完成“会/不会”判断")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(viewModel.progressText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func card(for word: WordItem) -> some View {
        Button {
            Task { await viewModel.tapCard() }
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("阶段 \(word.stage)", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.blue.opacity(0.12), in: Capsule())

                    Spacer()

                    Text("点击卡片提交")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(word.zhText)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)

                if viewModel.showEnglish {
                    Divider()
                    Text(word.enWord)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                } else {
                    Text("点击“英文翻译”后再点卡片，记为“不会”")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var actionBar: some View {
        Button("英文翻译") {
            viewModel.revealEnglish()
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .buttonStyle(.bordered)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("当前没有待复习单词")
                .font(.headline)
            Text("去“添加”页录入新单词后，次日会自动进入队列")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("重新加载") {
                Task { await viewModel.loadQueue() }
            }
            .frame(minHeight: 44)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var syncOverlay: some View {
        ZStack {
            Color.black.opacity(0.14)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.regular)
                Text("正在同步数据")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
        }
    }

    private func noticeSection(_ text: String) -> some View {
        Label(text, systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
