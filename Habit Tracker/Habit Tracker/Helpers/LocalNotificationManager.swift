//
//  LocalNotificationManager.swift
//  Habit Tracker
//
//  Created by Jordan Christensen on 11/20/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UserNotifications
import CoreData

class LocalNotificationManager {
    public static let shared = LocalNotificationManager()
    
    var notifications = [Notification]()
    let reuseId = "HABIT_ACTION"
    
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
        guard let id = habit.id, let title = habit.title, let notifyTime = habit.notifyTime else { return }
        let datetime = Calendar.current.dateComponents([.hour, .minute, .second], from: notifyTime)
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
            let notificationCenter = UNUserNotificationCenter.current()
            let completeAction = UNNotificationAction(identifier: "COMPLETE_ACTION",
                                                      title: "Mark as completed",
                                                      options: UNNotificationActionOptions(rawValue: 0))
            let failAction = UNNotificationAction(identifier: "FAIL_ACTION",
                                                  title: "Mark as failed",
                                                  options: UNNotificationActionOptions(rawValue: 0))
            let meetingInviteCategory =
                UNNotificationCategory(identifier: reuseId,
                                       actions: [completeAction, failAction],
                                       intentIdentifiers: [],
                                       hiddenPreviewsBodyPlaceholder: "",
                                       options: .customDismissAction)
            
            notificationCenter.setNotificationCategories([meetingInviteCategory])
            
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.subtitle = notification.subtitle ?? ""
            content.body = notification.body
            content.sound = .defaultCritical
            content.categoryIdentifier = reuseId
            content.userInfo = ["HABBIT_ID": notification.id]
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false) // For presentation
//            let trigger = UNCalendarNotificationTrigger(dateMatching: notification.datetime, repeats: true)
            let request = UNNotificationRequest(identifier: notification.id, content: content, trigger: trigger)
            
            notificationCenter.add(request) { error in
                if let error = error {
                    NSLog("Error adding notification: \(error)")
                    return
                } else {
                    print("Notification scheduled. ID: \(notification.id)")
                }
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler:
        @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        let request: NSFetchRequest<Habit> = Habit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: CoreDataStack.shared.mainContext,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self as? NSFetchedResultsControllerDelegate
        do {
            try frc.performFetch()
        } catch {
            fatalError("Unable to fetch object: \(error)")
        }
        
        let habitID = userInfo["HABBIT_ID"] as? String
        let arr = frc.fetchedObjects?.filter { $0.id?.uuidString == habitID }
        
        guard let habit = arr?.first else { return }
        
        switch response.actionIdentifier {
        case "ACCEPT_ACTION":
            HabitController.shared.updateNewDayStatus(habit: habit, status: .yes)
        case "DECLINE_ACTION":
            HabitController.shared.updateNewDayStatus(habit: habit, status: .no)
        default:
            HabitController.shared.updateNewDayStatus(habit: habit, status: .unset)
        }
        
        completionHandler()
    }
    
    private init() {
        //        let habitNotificationCategory = UNNotificationCategory(identifier: reuseId, actions: [], intentIdentifiers: [], options: [])
        //        UNUserNotificationCenter.current().setNotificationCategories([habitNotificationCategory])
    }
}

struct Notification {
    var id: String
    var title: String
    var body: String
    var subtitle: String?
    var datetime: DateComponents
}
