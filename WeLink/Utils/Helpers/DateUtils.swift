//
//  DateUtils.swift
//  WeLink
//
//  Created by Assistant on 10/1/25.
//

import Foundation

enum DateUtils {
    static let monthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter
    }()
    
    // Common ISO-like date format used in previews: "yyyy-MM-dd"
    static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

/// Formats a Date to "MM.dd" (e.g., 04.24)
func formatMonthDay(from date: Date) -> String {
    DateUtils.monthDayFormatter.string(from: date)
}

/// Parses a string date (expected format: "yyyy-MM-dd") and formats to "MM.dd". If parsing fails, returns the original string.
func formatMonthDay(from dateString: String) -> String {
    if let date = DateUtils.isoDateFormatter.date(from: dateString) {
        return DateUtils.monthDayFormatter.string(from: date)
    }
    return dateString
}
