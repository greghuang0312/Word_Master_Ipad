import Foundation

enum ProfileApiKeyGuidance {
    static let helperText = "请输入 DeepSeek 平台生成的完整 API Key；如果以 sk- 开头，请连同 sk- 一起输入，不要输入 Bearer。"

    static func statusText(hasSavedApiKey: Bool) -> String {
        hasSavedApiKey ? "当前已保存可用 API Key" : "当前尚未保存 API Key"
    }
}
