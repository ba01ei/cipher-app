//
//  Achievements.swift
//  cipher
//
//  Created by Bao Lei on 6/29/25.
//

import Foundation
import GameKit

enum Achievement: String {
  case firstSolve = "fyi.lei.cipher.firstsolve"
  case independentSolve = "fyi.lei.cipher.independentsolve"
  case ten = "fyi.lei.cipher.10"
  case hundred = "fyi.lei.cipher.100"
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
      let streak = DateHelper.longestDayStreak(from: dates)
      if streak >= 7 {
        result.append(.week)
        if streak >= 30 {
          result.append(.month)
          if streak >= 365 {
            result.append(.year)
          }
        }
      }
    }
    return result
  }
  
  static func reportAchievements(from games: [FinishData]) {
    let achievements = AchievementsHelper.achievements(from: games).map {
      let achievement = GKAchievement(identifier: $0.rawValue)
      achievement.percentComplete = 100.0
      achievement.showsCompletionBanner = true
      return achievement
    }
    GKAchievement.report(achievements) { error in
      if let error {
        print("Error reporting achievement: \(error.localizedDescription)")
      }
    }
  }
}
