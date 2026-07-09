import DeviceActivity
import ManagedSettings
import FamilyControls

/// Extensión que reaplica el bloqueo periódicamente para que persista (aunque
/// el sistema descargue la app de memoria o pase el tiempo). Lee la selección
/// guardada en el App Group compartido.
///
/// En Xcode: File → New → Target → "Device Activity Monitor Extension".
/// Agrega a este target la capacidad Family Controls y el mismo App Group.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        applyBlocks()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        applyBlocks() // seguir bloqueando en el siguiente ciclo
    }

    private func applyBlocks() {
        // Capa web automática (siempre, con toda la lista).
        let domains = Set(BettingDomains.all.map { WebDomain(domain: $0) })
        store.webContent.blockedByFilter = .auto(domains)

        // Capa de apps elegidas por el usuario (si hay selección guardada).
        guard let selection = SelectionStore.load() else { return }
        store.shield.applications =
            selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories =
            selection.categoryTokens.isEmpty ? ShieldSettings.ActivityCategoryPolicy.none
                                             : .specific(selection.categoryTokens)
        store.shield.webDomains =
            selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
    }
}
