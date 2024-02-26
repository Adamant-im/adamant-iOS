//
//  Date+humanizedString.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import DateToolsSwift

public extension Date {
    // MARK: - Constants
    static let adamantNullDate = Date(timeIntervalSince1970: .zero)
    
    // MARK: - Humanized dates
    
    /// Returns readable date with time.
    func humanizedDateTime(withWeekday: Bool = true) -> String {
        let formatter = defaultFormatter
        
        if year == Date().year {
            let dateString: String
            if isToday {
                dateString = String.localized("Chats.Date.Today")
            } else if daysAgo < 2 {
                /*
                    We can't use 'self.timeAgoSinceNow' here, because after midnight, when it is already not 'isToday',
                    but less than 24 hours has passed, so it is technically not 'Yesterday' yet,
                    it will display something like '6 hours ago'
                */
                dateString = String.localized("Chats.Date.Yesterday")
            } else if withWeekday && weeksAgo < 1 { // This week, show weekday, month and date
                dateString = Date.formatterWeekDayMonth.string(from: self)
            } else { // This year, long ago: show month and date
                dateString = Date.formatterDayMonth.string(from: self)
            }
            
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            
            return "\(dateString), \(formatter.string(from: self))"
        }
        
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func humanizedDateTimeFull() -> String {
        let formatter = defaultFormatter
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Returns readable day string. "Today, Yesterday, etc"
    func humanizedDay() -> String {
        let dateString: String
        
        if isToday { // Today
            dateString = String.localized("Chats.Date.Today")
        } else if daysAgo < 2 { // Yesterday
            dateString = elapsedTime(from: self)
        } else if weeksAgo < 1 { // This week, show weekday, month and date
            dateString = Date.formatterWeekDayMonth.string(from: self)
        } else if yearsAgo < 1 { // This year, long ago: show month and date
            dateString = Date.formatterDayMonth.string(from: self)
        } else { // Show full date
            dateString = DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .none)
        }
        
        return dateString
    }
    
    /// Returns readable time string. "Just now, minutes ago, 11:30, etc"
    /// - Returns: Readable string, and time when string will be expired and needs an update
    func humanizedTime() -> (string: String, expireIn: TimeInterval?) {
        let timeString: String
        let expire: TimeInterval?
        
        let seconds = secondsAgo
        if seconds < 30 {
            timeString = String.localized("Chats.Date.JustNow")
            expire = TimeInterval(30 - seconds)
        } else if seconds < 90 {
            timeString = String.localized("Chats.Date.MinAgo")
            expire = TimeInterval(60 - (seconds % 60))
        } else if minutesAgo < 5 {
            timeString = elapsedTime(from: self)
            expire = TimeInterval(60 - (seconds % 60))
        } else {
            let formatter = defaultFormatter
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            timeString = formatter.string(from: self)
            
            expire = nil
        }
        
        return (timeString, expire)
    }
}

private extension Date {
    // MARK: Formatters
    
     static var formatterWeekDayMonth: DateFormatter {
        let formatter = DateFormatter()
        if let localeRaw = UserDefaults.standard.string(forKey: StoreKey.language.languageLocale) {
            formatter.locale = Locale(identifier: localeRaw)
        }
        formatter.setLocalizedDateFormatFromTemplate("MMMMEEEEd")
        return formatter
    }
    
     static var formatterDayMonth: DateFormatter {
        let formatter = DateFormatter()
        if let localeRaw = UserDefaults.standard.string(forKey: StoreKey.language.languageLocale) {
            formatter.locale = Locale(identifier: localeRaw)
        }
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        return formatter
    }
    
     var defaultFormatter: DateFormatter {
        let formatter = DateFormatter()
        if let localeRaw = UserDefaults.standard.string(forKey: StoreKey.language.languageLocale) {
            formatter.locale = Locale(identifier: localeRaw)
        }
        return formatter
    }
    
    // MARK: Helpers

    func elapsedTime(from date: Date) -> String {
        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince(date)
        
        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        
        if days > 0 {
            return String.adamant.dateChatList.days(days)
        } else if hours > 0 {
            return String.adamant.dateChatList.hours(hours)
        } else if minutes > 0 {
            return String.adamant.dateChatList.minutes(minutes)
        } else {
            return String.adamant.dateChatList.seconds(seconds)
        }
    }
}

extension String.adamant {
    enum dateChatList {
        static func days(_ days: Int) -> String {
            return String.localizedStringWithFormat(.localized("Chats.Date.For.Days", comment: "Date chats: Duration in days if longer than one."), days)
        }
        
        static func hours(_ hours: Int) -> String {
            return String.localizedStringWithFormat(.localized("Chats.Date.For.Hours", comment: "Date chats: Duration in hours if longer than one."), hours)
        }
        
        static func minutes(_ minutes: Int) -> String {
            return String.localizedStringWithFormat(.localized("Chats.Date.For.Minutes", comment: "Date chats: Duration in minutes if longer than one."), minutes)
        }
        
        static func seconds(_ seconds: Int) -> String {
            return String.localizedStringWithFormat(.localized("Chats.Date.For.Seconds", comment: "Date chats: Duration in seconds if longer than one."), seconds)
        }
    }
}
