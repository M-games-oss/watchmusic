import SwiftUI

struct SettingsView: View {
    @AppStorage("serverURL") private var serverURL: String = ""
    @AppStorage("authUsername") private var authUsername: String = ""
    @AppStorage("authPassword") private var authPassword: String = ""

    var body: some View {
        Form {
            Section("Server") {
                TextField("https://your-tunnel.example.com", text: $serverURL)
            }
            Section("Basic Auth (optional)") {
                TextField("Username", text: $authUsername)
                SecureField("Password", text: $authPassword)
            }
        }
        .navigationTitle("Settings")
    }
}
