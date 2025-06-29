//
//  Achievements.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import Foundation

enum Achievement: String {
  case firstSolve = "fyi.lei.cipher.firstsolve"
  case independentSolve = "fyi.lei.cipher.independentsolve"
  case ten = "fyi.lei.cipher.ten"
  case hundred = "fyi.lei.cipher.hundred"
  case week = "fyi.lei.cipher.week"
  case month = "fyi.lei.cipher.month"
  case year = "fyi.lei.cipher.year"
}

struct AchievementsHelper {
  static func achievements(from games: [FinishData]) -> [Achievement] {
    var result: [Achievement] = []
    let wins = games.filter(\.success)
    if !wins.isEmpty {
      result.append(.firstSolve)

      let independentCount = wins.filter({ !$0.keywordRevealed && $0.hintCount == 0 }).count
      if independentCount > 0 {
        result.append(.independentSolve)
        if independentCount >= 10 {
          result.append(.ten)
          if independentCount >= 100 {
            result.append(.hundred)
          }
        }
      }
      
      let dates = wins.compactMap(\.time).map {
        Date(timeIntervalSince1970: $0)
      }
      if hasNDayStreak(dates: dates, streakLength: 7) {
        result.append(.week)
        if hasNDayStreak(dates: dates, streakLength: 30) {
          result.append(.month)
          if hasNDayStreak(dates: dates, streakLength: 365) {
            result.append(.year)
          }
        }
      }
    }
    return result
  }
}
