import SwiftUI

struct AddWordView: View {
    @StateObject private var viewModel: AddWordViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(context: AppContext) {
        _viewModel = StateObject(wrappedValue: AddWordViewModel(context: context))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    inputSection

                    if !viewModel.candidates.isEmpty {
                        candidateSection
                    }

                    manualSection
                    actionSection

                    if !viewModel.notice.isEmpty {
                        noticeSection(viewModel.notice)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())

            if let message = viewModel.completionMessage {
                completionBanner(message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1)
            }
        }
        .animation(
            reduceMotion ? .none : .spring(response: 0.32, dampingFraction: 0.88),
            value: viewModel.completionMessage != nil
        )
        .navigationTitle("添加")
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("输入中文词义（自动查询英文候选）")
                .font(.headline)

            TextField("例如：苹果", text: $viewModel.zhText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: viewModel.zhText) { _, _ in
                    viewModel.scheduleAutoQuery()
                }

            Button {
                Task { await viewModel.queryCandidates() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.loading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(viewModel.loading ? "查询中..." : "手动重查（可选）")
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.loading)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var candidateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("候选英文（单选）")
                .font(.headline)

            ForEach(viewModel.candidates, id: \.self) { candidate in
                candidateRow(candidate)
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var manualSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("手写英文（可选，优先于候选）")
                .font(.headline)

            TextField("例如：apple", text: $viewModel.manualEnglish)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionSection: some View {
        HStack(spacing: 10) {
            Button("保存词条") {
                Task { await viewModel.save() }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.borderedProminent)

            Button("清空") {
                viewModel.resetInput()
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .buttonStyle(.bordered)
        }
    }

    private func candidateRow(_ candidate: String) -> some View {
        let isSelected = viewModel.selectedCandidate == candidate

        return Button {
            viewModel.selectedCandidate = candidate
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)

                Text(candidate)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? .blue.opacity(0.12) : .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func noticeSection(_ text: String) -> some View {
        Label(text, systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func completionBanner(_ text: String) -> some View {
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
