//
//  NotificationService.swift
//  Token Timer Prime
//
//  Created by Jack Personal on 7/22/25.
//

import Foundation
import UserNotifications

@MainActor
class NotificationService: ObservableObject {
    
    // MARK: - Public Methods
    
    func scheduleNotifications(for session: TimerSession) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        // Schedule notification for timer completion
        let content = UNMutableNotificationContent()
        content.title = "Leisure Time Complete"
        content.body = "Your \(session.originalTokens) token timer has finished!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(session.remainingMinutes * 60),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "timer_complete",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
        
        // Schedule periodic updates
        schedulePeriodicNotifications(for: session)
    }
    
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Private Methods
    
    private func schedulePeriodicNotifications(for session: TimerSession) {
        let center = UNUserNotificationCenter.current()
        let updateIntervals = [5, 10, 15, 30] // minutes
        
        for interval in updateIntervals {
            if session.remainingMinutes > interval {
                let content = UNMutableNotificationContent()
                content.title = "Leisure Time Remaining"
                let remaining = session.remainingMinutes - interval
                content.body = formatTimeRemaining(minutes: remaining)
                content.sound = nil // Silent update
                
                let trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: TimeInterval(interval * 60),
                    repeats: false
                )
                
                let request = UNNotificationRequest(
                    identifier: "timer_update_\(interval)",
                    content: content,
                    trigger: trigger
                )
                
                center.add(request)
            }
        }
    }
    
    private func formatTimeRemaining(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(mins)m remaining"
        } else {
            return "\(mins)m remaining"
        }
    }
}
