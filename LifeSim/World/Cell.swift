//
//  Cell.swift
//  LifeSim
//
//  Created by iDeveloper on 10.07.2019.
//  Copyright © 2019 iDeveloper. All rights reserved.
//

import Foundation

enum Direction: Int, CaseIterable {
  case up_left
  case up
  case up_right
  case right
  case down_right
  case down
  case down_left
  case left
  
  static var random: Direction {
    return Direction(rawValue: Int.random(in: 0...3)) ?? .up
  }
}

struct Coord {
  let x: Int
  let y: Int
  
  static var zero: Coord {
    return Coord(x: 0, y: 0)
  }
  
  static var center: Coord {
    return Coord(x: WORLD_COLUMNS / 2, y: WORLD_ROWS / 2)
  }
  
  static var max: Coord {
    return Coord(x: WORLD_COLUMNS - 1, y: WORLD_ROWS - 1)
  }
  
  static var random: Coord {
    return Coord(x: Int.random(in: 0...WORLD_COLUMNS - 1),
                 y: Int.random(in: 0...WORLD_ROWS - 1))
  }
  
  func moved(to direction: Direction) -> Coord {
    var x = self.x
    var y = self.y
    
    switch direction {
    case .up_left:
      x -= 1
      y += 1
    case .up: y += 1
    case .up_right:
      x += 1
      y += 1
    case .right: x += 1
    case .down_right:
      x += 1
      y -= 1
    case .down: y -= 1
    case .down_left:
      x -= 1
      y -= 1
    case .left: x -= 1
    }
    
    if x < 0 {
      x = WORLD_COLUMNS - 1
    } else if x >= WORLD_COLUMNS {
      x = 0
    }
    
    return Coord(x: x, y: y)
  }
  
  var isValid: Bool {
    return (0...(WORLD_COLUMNS - 1)).contains(x) && (0...(WORLD_ROWS - 1)).contains(y)
  }
  
  static func ==(left: Coord, right: Coord) -> Bool {
    return left.x == right.x && left.y == right.y
  }
}

enum CellState {
  case empty
  case fill(Bot)
}

class Cell {
  var state: CellState = .empty {
    didSet {
      switch state {
      case .fill(let bot): self.bot = bot
      case .empty: bot = nil
      }
    }
  }
  
  private(set) var bot: Bot?
}
