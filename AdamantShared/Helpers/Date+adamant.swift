//
//  Date+humanizedString.swift
//  Adamant
//
//  Created by Anokhov Pavel on 07.06.2018.
//  Copyright © 2018 Adamant. All rights reserved.
//

import Foundation
import DateToolsSwift

extension Date {
    // MARK: - Constants
    static let adamantNullDate = Date(timeIntervalSince1970: 0)
    
    // MARK: - Humanized dates
    
	/// Returns readable date with time.
    func humanizedDateTime(withWeekday: Bool = true) -> String {
		if yearsAgo < 1 {
			let dateString: String
			if isToday {
				dateString = NSLocalizedString("Today", tableName: "DateTools", bundle: Bundle.dateToolsBundle(), comment: "")
			} else if daysAgo < 2 {
				/*
					We can't use 'self.timeAgoSinceNow' here, because after midnight, when it is already not 'isToday',
					but less than 24 hours has passed, so it is technically not 'Yesterday' yet,
					it will display something like '6 hours ago'
				*/
				dateString = NSLocalizedString("Yesterday", tableName: "DateTools", bundle: Bundle.dateToolsBundle(), comment: "")
			} else if withWeekday && weeksAgo < 1 { // This week, show weekday, month and date
				dateString = Date.formatterWeekDayMonth.string(from: self)
			} else { // This year, long ago: show month and date
				dateString = Date.formatterDayMonth.string(from: self)
			}
			
			return "\(dateString), \(DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: .short))"
		} else {
			return DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .short)
		}
	}
	
	func humanizedDateTimeFull() -> String {
		return DateFormatter.localizedString(from: self, dateStyle: .long, timeStyle: .short)
	}
	
	
	/// Returns readable day string. "Today, Yesterday, etc"
	func humanizedDay() -> String {
		let dateString: String
		
		if isToday { // Today
			dateString = NSLocalizedString("Today", tableName: "DateTools", bundle: Bundle.dateToolsBundle(), comment: "")
		} else if daysAgo < 2 { // Yesterday
			dateString = self.timeAgoSinceNow
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
			timeString = NSLocalizedString("Just now", tableName: "DateTools", bundle: Bundle.dateToolsBundle(), comment: "")
			expire = TimeInterval(30 - seconds)
		} else if seconds < 90 {
			timeString = NSLocalizedString("A minute ago", tableName: "DateTools", bundle: Bundle.dateToolsBundle(), comment: "")
			expire = TimeInterval(60 - (seconds % 60))
		} else if minutesAgo < 5 {
			timeString = timeAgoSinceNow
			expire = TimeInterval(60 - (seconds % 60))
		} else {
			let localizedDateString = DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: .short)
			timeString = localizedDateString
			expire = nil
		}
		
		return (timeString, expire)
	}
	
	
	// MARK: Formatters
	
	private static let formatterWeekDayMonth: DateFormatter = {
		let formatter = DateFormatter()
		formatter.setLocalizedDateFormatFromTemplate("MMMMEEEEd")
		return formatter
	}()
	
	private static let formatterDayMonth: DateFormatter = {
		let formatter = DateFormatter()
		formatter.setLocalizedDateFormatFromTemplate("MMMMd")
		return formatter
	}()
}
