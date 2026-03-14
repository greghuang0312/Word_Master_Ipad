import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(context: AppContext) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(context: context))
    }

    var body: some View {
        ZStack {
            Form {
                Section("当前账号") {
                    Label(viewModel.currentEmail, systemImage: "person.crop.circle")
                        .font(.subheadline)
                }

                Section("DeepSeek API Key") {
                    TextField("请输入 API Key", text: $viewModel.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack(spacing: 8) {
                        Image(systemName: viewModel.hasSavedApiKey ? "checkmark.seal.fill" : "exclamationmark.triangle")
                            .foregroundStyle(viewModel.hasSavedApiKey ? .green : .orange)
                        Text(ProfileApiKeyGuidance.statusText(hasSavedApiKey: viewModel.hasSavedApiKey))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button {
                            Task { await viewModel.testAndSaveApiKey() }
                        } label: {
                            if viewModel.testing {
                                ProgressView()
                            } else {
                                Text("测试并保存")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(viewModel.testing || trimmedApiKey.isEmpty)

                        Button("清除", role: .destructive) {
                            viewModel.clearApiKey()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .disabled(viewModel.testing || (!viewModel.hasSavedApiKey && trimmedApiKey.isEmpty))
                    }

                    Text(ProfileApiKeyGuidance.helperText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("账号") {
                    Button("退出当前账号", role: .destructive) {
                        Task { await viewModel.logout() }
                    }
                }

                if !viewModel.notice.isEmpty {
                    Section("提示") {
                        Text(viewModel.notice)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("我的")

            if let banner = viewModel.resultBanner {
                resultBanner(banner)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1)
            }
        }
        .animation(
            reduceMotion ? .none : .spring(response: 0.32, dampingFraction: 0.88),
            value: viewModel.resultBanner != nil
        )
    }

    private var trimmedApiKey: String {
        viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resultBanner(_ banner: ProfileResultBanner) -> some View {
        HStack(spacing: 8) {
            Image(systemName: banner.tone.iconSystemName)
                .foregroundStyle(banner.tone == .error ? .red : .green)
            Text(banner.message)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
    }
}
