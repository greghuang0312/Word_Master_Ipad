import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(context: AppContext) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(context: context))
    }

    var body: some View {
        Form {
            Section("当前账号") {
                Text(viewModel.currentEmail)
                    .font(.subheadline)
            }

            Section("DeepSeek API Key") {
                SecureField("请输入 API Key", text: $viewModel.apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                HStack {
                    Button("保存") { viewModel.saveApiKey() }
                    Button("清除", role: .destructive) { viewModel.clearApiKey() }
                }
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
    }
}

