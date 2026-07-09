import Foundation
import FamilyControls

/// Guarda la selección del usuario en un App Group compartido, para que la app
/// y las extensiones (monitor y escudo) lean lo mismo. FamilyActivitySelection
/// es Codable, así que se serializa a JSON.
enum SelectionStore {
    /// Debe coincidir con el App Group configurado en la app y las extensiones.
    static let appGroup = "group.com.sinapuestas.shared"
    private static let key = "family_selection"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func save(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: key)
        }
    }

    static func load() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}
