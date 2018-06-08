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
	/// Returns readable date with time.
	func humanizedDateTime() -> String {
		if daysAgo < 7 {
			let dayString: String
			if isToday {
				dayString = NSLocalizedString("Today", tableName: "DateTools", bundle: Bundle.dateToolsBundle(), value: "", comment: "")
			} else if daysAgo < 2 {
				/*
					We can't use 'self.timeAgoSinceNow' here, because after midnight, when it is already not 'isToday',
					but less than 24 hours has passed, so it is technically not 'Yesterday' yet,
					it will display something like '6 hours ago'
				*/
				dayString = NSLocalizedString("Yesterday", tableName: "DateTools", bundle: Bundle.dateToolsBundle(), value: "", comment: "")
			} else {
				dayString = format(with: "EEEE") // weekday
			}
			
			return "\(dayString), \(DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: .short))"
		} else {
			return DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .short)
		}
	}
	
	
	/// Returns readable day string. "Today, Yesterday, etc"
	func humanizedDay() -> String {
		let dateString: String
		
		if daysAgo < 7 {
			if isToday {
				dateString = NSLocalizedString("Today", tableName: "DateTools", bundle: Bundle.dateToolsBundle(), value: "", comment: "")
			} else if daysAgo < 2 {
				dateString = self.timeAgoSinceNow
			} else {
				dateString = self.format(with: "EEEE")
			}
		} else {
			dateString = DateFormatter.localizedString(from: self, dateStyle: .medium, timeStyle: .none)
		}
		
		return dateString
	}
	
	
	/// Returns readable time string. "Just now, minutes ago, 11:30, etc"
	func humanizedTime() -> String {
		let dateString: String
		
		if minutesAgo < 2 {
			dateString = timeAgoSinceNow
		} else {
			let localizedDateString = DateFormatter.localizedString(from: self, dateStyle: .none, timeStyle: .short)
			dateString = localizedDateString
		}
		
		return dateString
	}
}
