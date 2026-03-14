import SwiftUI

struct StatsView: View {
    @State private var words: [WordItem] = []
    @State private var notice = ""
    @State private var loading = false

    private let context: AppContext
    private let calculator = StatsCalculator()
    private let isActive: Bool

    init(context: AppContext, isActive: Bool) {
        self.context = context
        self.isActive = isActive
    }

    var body: some View {
        let result = calculator.calculate(words: words)

        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    summarySection(result.summary)
                    distributionSection(result.distribution)
                    timelineSection(result.timeline)
                    rulesSection

                    if !notice.isEmpty {
                        noticeSection(notice)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .blur(radius: loading ? 1.5 : 0)

            if loading {
                syncOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .navigationTitle("统计")
        .task(id: isActive) {
            guard isActive else { return }
            await loadWords()
        }
        .refreshable { await loadWords() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("刷新") { Task { await loadWords() } }
            }
        }
    }

    private func summarySection(_ summary: StatsSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("学习总览")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                statCard("总单词量", "\(summary.total)", color: .blue)
                statCard("进行中", "\(summary.inProgress)", color: .orange)
                statCard("逾期", "\(summary.overdue)", color: .red)
                statCard("已掌握", "\(summary.mastered)", color: .green)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statCard(_ title: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func distributionSection(_ distribution: [StageDistributionItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("阶段分布")
                .font(.headline)

            ForEach(distribution) { item in
                HStack {
                    Label("阶段 \(item.stage)", systemImage: "circle.fill")
                        .foregroundStyle(stageColor(item.stage))
                    Spacer()
                    Text("\(item.count)")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func timelineSection(_ timeline: [TimelineItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("艾宾浩斯复习时间轴")
                .font(.headline)

            ForEach(timeline) { item in
                HStack {
                    Text("阶段 \(item.stage)")
                    Spacer()
                    Text("+\(item.daysAfterReview) 天")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("复习规则说明")
                .font(.headline)
            Text("1. 当天队列包含所有 next_review_date <= 今天 的单词（含逾期）。")
            Text("2. 直接点卡片表示“会”，进入下一阶段。")
            Text("3. 点击“英文翻译”后再点卡片表示“不会”，回退到阶段 1，下一次复习为第二天。")
            Text("4. 新增单词首次复习日期为第二天。")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
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

    private func stageColor(_ stage: Int) -> Color {
        switch stage {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .mint
        case 5: return .blue
        default: return .purple
        }
    }

    private func loadWords() async {
        guard let userId = context.currentUserId else {
            notice = "请先登录"
            words = []
            return
        }

        loading = true
        defer { loading = false }

        do {
            words = try await context.wordRepository.fetchAllWords(userId: userId)
            notice = words.isEmpty ? "暂无统计数据" : ""
        } catch {
            notice = "统计加载失败：\(error.localizedDescription)"
        }
    }
}
