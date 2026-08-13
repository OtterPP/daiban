import SwiftUI

struct SettingsView: View {
    @State private var apiKey = ""
    @State private var baseURL = PolishSettings.defaultBaseURL
    @State private var model = PolishSettings.defaultModel
    @State private var keySaved = false

    var body: some View {
        Form {
            Section {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: apiKey) { _, newValue in
                        KeychainStore.setAPIKey(newValue)
                        keySaved = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }

                TextField("接口地址", text: $baseURL)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: baseURL) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: PolishSettings.baseURLDefaultsKey)
                    }

                TextField("模型", text: $model)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: model) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: PolishSettings.modelDefaultsKey)
                    }
            } header: {
                Text("可选润色")
            } footer: {
                Text(footerText)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("设置")
        .frame(width: 460, height: 280)
        .onAppear {
            apiKey = KeychainStore.apiKey() ?? ""
            baseURL = PolishSettings.baseURL
            model = PolishSettings.model
            keySaved = !apiKey.isEmpty
        }
    }

    private var footerText: String {
        if keySaved {
            return "密钥保存在本机钥匙串，不会写入仓库。点「润色」时会调用兼容 OpenAI 的 /chat/completions。未填密钥则只用本地清理（去掉「我想 / 能不能 / 帮我」等）。"
        }
        return "不填密钥也可以用。润色会在本地去掉「我想 / 能不能 / 帮我」等填充词。默认接口为 xAI（https://api.x.ai/v1，grok-3-mini）。"
    }
}
