//
//  DateHelper.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import Foundation

func hasNDayStreak(dates: [Date], streakLength: Int) -> Bool {
  guard streakLength > 0 else { return true }
  guard dates.count >= streakLength else { return false }
  
  let calendar = Calendar.current
  
  // Convert dates to local date components (ignoring time)
  let uniqueDates = Set(dates.map { date in
    calendar.startOfDay(for: date)
  })
  
  // Convert to sorted array
  let sortedDates = uniqueDates.sorted()
  
  guard sortedDates.count >= streakLength else { return false }
  
  var currentStreakLength = 1
  
  for i in 1..<sortedDates.count {
    let previousDate = sortedDates[i - 1]
    let currentDate = sortedDates[i]
    
    // Check if current date is exactly one day after previous date
    if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
       calendar.isDate(nextDay, inSameDayAs: currentDate) {
      currentStreakLength += 1
      
      // Check if we've found the required streak length
      if currentStreakLength >= streakLength {
        return true
      }
    } else {
      // Reset streak counter
      currentStreakLength = 1
    }
  }
  
  return false
}
