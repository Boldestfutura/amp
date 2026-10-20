import Foundation
import Observation
import Security

@MainActor
@Observable
final class SessionStore {
    private(set) var server: PlexServer?
    private(set) var isAuthenticated = false

    private let serverKey = "plexglass.server"
    private let tokenKey = "plexglass.token"

    init() {
        restore()
    }

    func authenticate(token: String, server: PlexServer) {
        self.server = server
        self.isAuthenticated = true
        persist(token: token, server: server)
    }

    func enableDemo() {
        server = DemoData.server
        isAuthenticated = true
    }

    func signOut() {        server = nil
        isAuthenticated = false
        Keychain.delete(tokenKey)
        UserDefaults.standard.removeObject(forKey: serverKey)
    }

    private func persist(token: String, server: PlexServer) {
        Keychain.save(token, for: tokenKey)
        if let data = try? JSONEncoder().encode(server) {
            UserDefaults.standard.set(data, forKey: serverKey)
        }
    }

    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: serverKey),
              var server = try? JSONDecoder().decode(PlexServer.self, from: data),
              let token = Keychain.read(tokenKey) else { return }
        server = PlexServer(
            name: server.name, host: server.host, port: server.port,
            scheme: server.scheme, token: token
        )
        self.server = server
        self.isAuthenticated = true
    }
}

enum Keychain {
    static func save(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func read(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
