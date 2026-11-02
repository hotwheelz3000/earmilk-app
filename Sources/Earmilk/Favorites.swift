import Foundation
import Observation

/// Songs the user starred, kept on the phone in UserDefaults by post id.
@MainActor
@Observable
final class Favorites {
    private static let key = "favorites"

    private(set) var ids: Set<String>

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: Self.key) ?? [])
    }

    func contains(_ post: Post) -> Bool {
        ids.contains(post.id)
    }

    func toggle(_ post: Post) {
        if ids.contains(post.id) {
            ids.remove(post.id)
        } else {
            ids.insert(post.id)
        }
        UserDefaults.standard.set(Array(ids), forKey: Self.key)
    }
}
