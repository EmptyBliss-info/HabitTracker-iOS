//
//  LocalNotificationManager.swift
//  Habit Tracker
//
//  Created by Jordan Christensen on 11/20/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UserNotifications

class LocalNotificationManager {
    public static let shared = LocalNotificationManager()
    
    var notifications = [Notification]()
    let reuseId = "habitNotification"

    func listScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { notifications in
            for notification in notifications {
                print(notification)
            }
        }
    }
    
    func schedule() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization()
            case .authorized, .provisional:
                self.scheduleNotifications()
            default:
                break
            }
        }
    }
    
    func scheduleNotification(for habit: Habit) {
        guard let id = habit.id, let title = habit.title else { return }
        var datetime = DateComponents()
        datetime.hour = 20
        notifications.append(Notification(id: id.uuidString, title: "Habit Reminder", body: "Have you completed your \(title) habit today?", subtitle: nil, datetime: datetime))
        schedule()
    }
    
    func deleteNotificiation(with id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    private func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { didAllow, error in
            if let error = error {
                NSLog("Error: \(error)")
            } else if !didAllow {
                NSLog("User notifications are not enabled. Please enable in settings")
            } else {
                self.scheduleNotifications()
            }
        }
    }
    
    private func scheduleNotifications() {
        for notification in notifications {
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.subtitle = notification.subtitle ?? ""
            content.body = notification.body
            content.sound = .defaultCritical
            content.categoryIdentifier = reuseId
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
//            let trigger = UNCalendarNotificationTrigger(dateMatching: notification.datetime, repeats: true)
            let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    NSLog("Error adding notification: \(error)")
                    return
                } else {
                    print("Notification scheduled. ID: \(notification.id)")
                }
            }
        }
    }

    private init() {
        let habitNotificationCategory = UNNotificationCategory(identifier: reuseId, actions: [], intentIdentifiers: [], options: [])
        UNUserNotificationCenter.current().setNotificationCategories([habitNotificationCategory])
    }
}

struct Notification {
    var id: String
    var title: String
    var body: String
    var subtitle: String?
    var datetime: DateComponents
}
