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
                    SecureField("请输入 API Key", text: $viewModel.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack(spacing: 8) {
                        Image(systemName: viewModel.hasSavedApiKey ? "checkmark.seal.fill" : "exclamationmark.triangle")
                            .foregroundStyle(viewModel.hasSavedApiKey ? .green : .orange)
                        Text(viewModel.hasSavedApiKey ? "当前已保存可用 API Key" : "当前尚未保存 API Key")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Button("保存") {
                                viewModel.saveApiKey()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .disabled(trimmedApiKey.isEmpty)

                            Button {
                                Task { await viewModel.testApiKey() }
                            } label: {
                                if viewModel.testing {
                                    ProgressView()
                                } else {
                                    Text("测试连接")
                                }
                            }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .disabled(viewModel.testing)
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
                        }
                    }

                    Text("点击“测试连接”或“测试并保存”成功后，都会自动保存 API。")
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

            if let message = viewModel.resultBannerMessage {
                resultBanner(message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: -120)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(1)
            }
        }
        .animation(
            reduceMotion ? .none : .spring(response: 0.32, dampingFraction: 0.88),
            value: viewModel.resultBannerMessage != nil
        )
    }

    private var trimmedApiKey: String {
        viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resultBanner(_ text: String) -> some View {
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
