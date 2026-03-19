import SwiftUI

struct ReviewView: View {
    @StateObject private var viewModel: ReviewViewModel
    @State private var cardRotation: Double = 0
    @State private var cardScale: CGFloat = 1
    @State private var cardOpacity: Double = 1

    private let isActive: Bool

    init(context: AppContext, isActive: Bool) {
        _viewModel = StateObject(wrappedValue: ReviewViewModel(context: context))
        self.isActive = isActive
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
        .onChangeCompat(of: viewModel.isTransitioningToNextCard) { isTransitioningToNextCard in
            guard isTransitioningToNextCard else { return }
            Task { await playNextCardTransition() }
        }
        .onChangeCompat(of: viewModel.currentWord?.id) { _ in
            guard !viewModel.isTransitioningToNextCard else { return }
            resetCardPresentation()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("今日队列")
                        .font(.headline)
                    Text("点中文卡片表示会，点“英文翻译”后再点卡片表示不会。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(viewModel.progressText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                phaseHint(text: "点卡片 = 会", systemImage: "hand.tap")
                phaseHint(text: "看英文后点卡片 = 不会", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func phaseHint(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.45), in: Capsule())
    }

    private func card(for word: WordItem) -> some View {
        Button {
            Task { await viewModel.tapCard() }
        } label: {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    Label("阶段 \(word.stage)", systemImage: "clock.arrow.circlepath")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.12), in: Capsule())

                    Spacer()

                    Label(cardStatusText, systemImage: viewModel.showEnglish ? "arrowshape.turn.up.left.fill" : "hand.tap.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(viewModel.showEnglish ? .orange : .secondary)
                }

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    Text(word.zhText)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)

                    Text(viewModel.showEnglish ? "再点卡片，标记这次不会并从阶段 1 重新开始。" : "先看中文回忆，直接点卡片表示你会。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 0)

                if viewModel.showEnglish {
                    VStack(spacing: 14) {
                        Divider()
                            .overlay(.white.opacity(0.35))

                        Text(word.enWord)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity)
                } else {
                    Label("需要提示时先点下方“英文翻译”", systemImage: "lightbulb")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 320)
            .padding(22)
            .background(cardBackground)
            .overlay(cardOutline)
            .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .disabled(cardInteractionsDisabled)
        .rotation3DEffect(.degrees(cardRotation), axis: (x: 0, y: 1, z: 0), perspective: 0.72)
        .scaleEffect(cardScale)
        .opacity(cardOpacity)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.94),
                        Color(uiColor: .secondarySystemGroupedBackground).opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var cardOutline: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        Color.blue.opacity(0.14),
                        Color.black.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.2
            )
    }

    private var actionBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(viewModel.showEnglish ? "已显示英文" : "英文翻译") {
                viewModel.revealEnglish()
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .buttonStyle(.borderedProminent)
            .tint(viewModel.showEnglish ? .gray : .blue)
            .disabled(cardInteractionsDisabled || viewModel.showEnglish)

            Text(viewModel.showEnglish ? "现在再点卡片，表示这次不会。" : "如果想确认答案，再点一次这个按钮显示英文。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("当前没有待复习单词")
                .font(.headline)
            Text("去“添加”页录入新单词后，次日会自动进入队列。")
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

    private var cardInteractionsDisabled: Bool {
        viewModel.loading || viewModel.submittingReview || viewModel.isTransitioningToNextCard
    }

    private var cardStatusText: String {
        viewModel.showEnglish ? "再点卡片表示不会" : "点卡片表示会"
    }

    private func resetCardPresentation() {
        cardRotation = 0
        cardScale = 1
        cardOpacity = 1
    }

    private func playNextCardTransition() async {
        withAnimation(.easeIn(duration: 0.18)) {
            cardRotation = 90
            cardScale = 0.96
            cardOpacity = 0.84
        }

        try? await Task.sleep(nanoseconds: 180_000_000)

        guard viewModel.isTransitioningToNextCard else {
            resetCardPresentation()
            return
        }

        var jumpTransaction = Transaction()
        jumpTransaction.disablesAnimations = true
        withTransaction(jumpTransaction) {
            cardRotation = -90
            cardOpacity = 0.84
            viewModel.completeCardTransition()
        }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            cardRotation = 0
            cardScale = 1
            cardOpacity = 1
        }
    }
}
