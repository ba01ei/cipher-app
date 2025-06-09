//
//  TimeHelper.swift
//  cipher
//
//  Created by Bao Lei on 6/8/25.
//

import Foundation

func formatTime(from timestamp: TimeInterval) -> String {
  let date = Date(timeIntervalSince1970: timestamp)
  let formatter = DateFormatter()
  
  let now = Date()
  let calendar = Calendar.current
  
  // Check if it's today
  if calendar.isDate(date, inSameDayAs: now) {
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }
  
  // Check if it's this week
  if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
     date > weekAgo {
    formatter.dateFormat = "E h:mm a" // "Mon 2:30 PM"
    return formatter.string(from: date)
  }
  
  // Check if it's this year
  if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
    formatter.dateFormat = "MMM d, h:mm a" // "Jan 15, 2:30 PM"
    return formatter.string(from: date)
  }
  
  // Different year
  formatter.dateFormat = "MMM d, yyyy" // "Jan 15, 2024"
  return formatter.string(from: date)
}

// Extension for even more concise usage
extension TimeInterval {
  var formatted: String {
    formatTime(from: self)
  }
}
