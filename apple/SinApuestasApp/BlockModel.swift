import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

/// Gestiona el bloqueo con Screen Time (Family Controls + ManagedSettings).
///
/// Dos capas de bloqueo:
///  1. AUTOMÁTICA: bloquea en Safari toda la lista de BettingDomains (cientos
///     de casas de apuestas) sin que el usuario elija nada, usando el filtro
///     de contenido web (`webContent.blockedByFilter = .auto`).
///  2. MANUAL: además escuda las apps de apuestas que el usuario elija con el
///     selector de Apple (las apps instaladas no se pueden bloquear por lista,
///     Apple obliga a elegirlas con el picker por privacidad).
///
/// Un DeviceActivityMonitor reaplica el bloqueo para que persista, y un candado
/// de compromiso impide desactivarlo antes de tiempo.
@MainActor
final class BlockModel: ObservableObject {

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()
    private let activity = DeviceActivityName("sinapuestas.always")
    private let defaults = UserDefaults.standard
    private let lockKey = "lock_until"
    private let onKey = "protection_on"

    @Published var selection = FamilyActivitySelection()
    @Published var isAuthorized = false
    @Published var protectionOn = false

    init() {
        protectionOn = defaults.bool(forKey: onKey)
        if let saved = SelectionStore.load() { selection = saved }
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    var remainingDays: Int {
        let rem = defaults.double(forKey: lockKey) - Date().timeIntervalSince1970
        return max(0, Int((rem + 86_399) / 86_400))
    }

    var commitmentActive: Bool {
        protectionOn && Date().timeIntervalSince1970 < defaults.double(forKey: lockKey)
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    /// Activa el bloqueo con compromiso en días.
    func activate(days: Int) {
        SelectionStore.save(selection)
        applyAllBlocks()
        startMonitoring()
        defaults.set(true, forKey: onKey)
        defaults.set(Date().timeIntervalSince1970 + Double(days) * 86_400, forKey: lockKey)
        protectionOn = true
    }

    /// Aplica las dos capas: filtro web automático + escudo de apps elegidas.
    private func applyAllBlocks() {
        // Capa 1 — filtro web automático con toda la lista de apuestas.
        let domains = Set(BettingDomains.all.map { WebDomain(domain: $0) })
        store.webContent.blockedByFilter = .auto(domains)

        // Capa 2 — escudo de apps/categorías/sitios que el usuario eligió.
        store.shield.applications =
            selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories =
            selection.categoryTokens.isEmpty ? ShieldSettings.ActivityCategoryPolicy.none
                                             : .specific(selection.categoryTokens)
        store.shield.webDomains =
            selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }

    private func startMonitoring() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        try? center.startMonitoring(activity, during: schedule)
    }

    /// Desactiva el bloqueo. Solo si el compromiso ya terminó.
    func deactivate() -> Bool {
        if commitmentActive { return false }
        store.webContent.blockedByFilter = .none
        store.shield.applications = nil
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.none
        store.shield.webDomains = nil
        center.stopMonitoring([activity])
        defaults.set(false, forKey: onKey)
        protectionOn = false
        return true
    }
}
