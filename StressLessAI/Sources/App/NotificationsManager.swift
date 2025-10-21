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

    func notifyRisingStress() {
        let c = UNMutableNotificationContent()
        c.title = "Rising Stress Detected"
        c.body = "Your stress levels are rising. Take a moment to refocus and breathe."
        let r = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "StressLessAI.rising", content: c, trigger: r)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    func notifySessionRecommendation(recommendation: String) {
        let c = UNMutableNotificationContent()
        c.title = "Session Report"
        c.body = recommendation
        let r = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: "StressLessAI.recommendation", content: c, trigger: r)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}
