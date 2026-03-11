import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var notice = ""

    let onLogin: (String, String) async -> Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Word Master")
                .font(.title2)
                .bold()

            TextField("账号", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            SecureField("密码", text: $password)
                .textFieldStyle(.roundedBorder)

            Button("登录") {
                Task {
                    let success = await onLogin(email, password)
                    if !success {
                        notice = "登录失败，请检查账号或密码"
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            if !notice.isEmpty {
                Text(notice)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(24)
    }
}
