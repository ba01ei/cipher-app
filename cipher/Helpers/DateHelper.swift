//
//  DateHelper.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import Foundation

struct DateHelper {
  static func longestDayStreak(from dates: [Date]) -> Int {
    // 1. Normalize Dates to the start of the day and get unique dates.
    // This removes the time component, ensuring only the day matters for comparison.
    let calendar = Calendar.current
    let uniqueNormalizedDates = Set(dates.compactMap { date in
      calendar.startOfDay(for: date)
    })
    
    // If there are no unique dates, the streak is 0.
    guard !uniqueNormalizedDates.isEmpty else {
      return 0
    }
    
    // 2. Sort the unique normalized dates in ascending order.
    let sortedDates = uniqueNormalizedDates.sorted()
    
    var maxStreak = 0
    var currentStreak = 0
    
    // 3. Iterate through the sorted dates to find the longest streak.
    for i in 0..<sortedDates.count {
      // If it's the first date, start a new streak.
      if i == 0 {
        currentStreak = 1
      } else {
        let previousDate = sortedDates[i - 1]
        let currentDate = sortedDates[i]
        
        // Calculate the difference in days between the current date and the previous date.
        // We use `dateComponents` with `.day` to correctly account for day boundaries.
        let components = calendar.dateComponents([.day], from: previousDate, to: currentDate)
        
        // If the difference is exactly 1 day, it's a consecutive day.
        if components.day == 1 {
          currentStreak += 1
        } else {
          // If not consecutive, the streak is broken, start a new one.
          currentStreak = 1
        }
      }
      // Update the maximum streak found so far.
      maxStreak = max(maxStreak, currentStreak)
    }
    
    return maxStreak
  }
}
