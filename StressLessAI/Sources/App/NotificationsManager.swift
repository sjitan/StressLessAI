import UserNotifications

final class NotificationsManager {
    static let shared = NotificationsManager()
    func requestAuth() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound]) { _,_ in }
    }
    func notifyTakeABreak() {
        let c = UNMutableNotificationContent()
        c.title = "Take a Break"
        c.body = "Stress stayed high. Breathe and step away."
        let r = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "StressLessAI.break", content: c, trigger: r)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}
