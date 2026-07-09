import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Personaliza la pantalla que ve el usuario cuando abre una app o sitio de
/// apuestas bloqueado: colores de SinApuestas y un mensaje de apoyo.
///
/// En Xcode: File → New → Target → "Shield Configuration Extension".
/// Agrega a este target la capacidad Family Controls.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func shield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.055, green: 0.322, blue: 0.282, alpha: 1), // teal
            icon: UIImage(systemName: "shield.fill"),
            title: ShieldConfiguration.Label(
                text: "Bloqueado por SinApuestas",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Tú decidiste protegerte. Respira: el impulso pasa en unos minutos. 💪",
                color: UIColor(white: 1, alpha: 0.85)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Volver",
                color: UIColor(red: 0.055, green: 0.322, blue: 0.282, alpha: 1)
            ),
            primaryButtonBackgroundColor: .white
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        shield()
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        shield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        shield()
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        shield()
    }
}
