import ManagedSettings
import Foundation

/// Открывает основное приложение по deep link, когда пользователь нажимает
/// "Начать упражнение" на экране блокировки. Это неофициальный, но широко
/// используемый приём (extensionContext?.open) — на случай, если система его
/// заблокирует, приложение дополнительно само проверяет флаг блокировки при
/// каждом переходе в активное состояние (см. ControlTimeApp.swift).
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        respond(to: action, completionHandler: completionHandler)
    }

    private func respond(to action: ShieldAction, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            if let url = URL(string: "\(StorageKey.unlockDeepLinkScheme)://unlock") {
                extensionContext?.open(url, completionHandler: nil)
            }
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }
}
