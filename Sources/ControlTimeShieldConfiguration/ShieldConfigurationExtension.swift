import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: ApplicationToken) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding application: ApplicationToken, in category: ActivityCategoryToken) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomainToken) -> ShieldConfiguration {
        makeConfiguration()
    }

    override func configuration(shielding webDomain: WebDomainToken, in category: ActivityCategoryToken) -> ShieldConfiguration {
        makeConfiguration()
    }

    private func makeConfiguration() -> ShieldConfiguration {
        let reps = AppGroup.defaults.object(forKey: StorageKey.repsPerInterval) as? Int ?? 15
        let exercise = ExerciseType(rawValue: AppGroup.defaults.string(forKey: StorageKey.exerciseType) ?? "") ?? .squats

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.85),
            icon: UIImage(systemName: "figure.strengthtraining.functional"),
            title: ShieldConfiguration.Label(text: "Время вышло", color: .white),
            subtitle: ShieldConfiguration.Label(
                text: "Сделай \(reps) \(exercise.displayName.lowercased()), чтобы продолжить",
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Начать упражнение", color: .white),
            primaryButtonBackgroundColor: .systemGreen,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Закрыть", color: .white)
        )
    }
}
