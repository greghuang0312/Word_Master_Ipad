import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var notice = ""
    @State private var submitting = false

    let onLogin: (String, String) async -> Bool

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack {
                Spacer(minLength: 40)

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Word Master")
                            .font(.largeTitle.weight(.bold))
                        Text("登录后开始你的每日单词复习")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    TextField("账号", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("密码", text: $password)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await performLogin() }
                    } label: {
                        HStack(spacing: 8) {
                            if submitting {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(submitting ? "登录中..." : "登录")
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(submitting || trimmedEmail.isEmpty || password.isEmpty)

                    if !notice.isEmpty {
                        Label(notice, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(20)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .frame(maxWidth: 540)
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func performLogin() async {
        guard !submitting else { return }
        submitting = true
        defer { submitting = false }

        let success = await onLogin(trimmedEmail, password)
        if success {
            notice = ""
        } else {
            notice = "登录失败，请检查账号或密码"
        }
    }
}
