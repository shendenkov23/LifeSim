//
//  Bot.swift
//  LifeSim
//
//  Created by iDeveloper on 2/5/19.
//  Copyright © 2019 iDeveloper. All rights reserved.
//

import Cocoa

struct BotColor {
  let red: CGFloat
  let green: CGFloat
  let blue: CGFloat
  
  static var white: BotColor {
    return .init(red: 1.0, green: 1.0, blue: 1.0)
  }
  
  static var orange: BotColor {
    return .init(red: 1.0, green: 0.5, blue: 0)
  }
}

class Bot {
  var isGone = false
  
  private let ID: String
  
  let world: LifeFieldView
  
  var color: NSColor {
    let ageCoef = CGFloat(age) / CGFloat(maxAge)
    let offset: CGFloat = 0.7
    let alpha = ageCoef * (1 - offset) + offset
    return NSColor(calibratedRed: botColor.red, green: botColor.green, blue: botColor.blue, alpha: alpha)
  }
  
  // MARK: -
  
  var isAdam: Bool = false
  
  private(set) var isDead = false
  
  private(set) var coord: Coord
  private(set) var botColor: BotColor
  
  private(set) var maxAge: Int
  private(set) var age: Int = 0
  
  private(set) var body: Int = MAX_BODY
  private(set) var energy: Int = MAX_ENERGY
  
  private var genIndex = 0
  private(set) var geneticCode: [Command]
  
  var nextBot: Bot?
  var prevBot: Bot?
  
  var possibleCommands: [Command] {
    return Command.allCases
  }
  
  // MARK: -
  
  init(world: LifeFieldView, coord: Coord, color: BotColor, geneticCode: [Command]) {
    ID = UUID().uuidString
    
    self.world = world
    
    self.coord = coord
    self.botColor = color
    
    maxAge = Bot.maxAge(for: geneticCode)
    self.geneticCode = geneticCode
  }
  
  // MARK: -
  
  func addEnergy(_ value: Int) {
    energy += value
    if energy > MAX_ENERGY {
      energy = MAX_ENERGY
    }
  }
  
  func addBody(_ value: Int) {
    body += value
    if body > MAX_BODY {
      body = MAX_BODY
    }
  }
  
  func move(to newCoord: Coord) {
    coord = newCoord
  }
  
  func step(resultHandler: (WorldSituation) -> ()) {
    isDead ?
      handleDeadStep(resultHandler: resultHandler) :
      handleLiveStep(resultHandler: resultHandler)
  }
  
  // MARK: -
  
  private func handleLiveStep(resultHandler: (WorldSituation) -> ()) {
    age += 1
    energy -= ENERGY_STEP
    
    //    print("BOT \(ID) AGE: \(age) ENERGY: \(energy)")
    
    guard age < maxAge, energy > 0 else {
      dead()
      resultHandler(.botDied(self))
      return
    }
        
    let command = geneticCode[genIndex]
    
//    print("COMMAND \(genIndex):", command)
    switch command {
    case .empty: break
    case .move: resultHandler(.botWantMove(self))
    case .reproduction:
      if let newBot = reproduction(with: 1) {
        newBot.prevBot = prevBot
        prevBot?.nextBot = newBot
        
        prevBot = newBot
        newBot.nextBot = self
        
        resultHandler(.botWasBorn(newBot))
      }
    case .photosynthesis:
      resultHandler(.botPhotosynthesised(self))
    case .eat:
      resultHandler(.botWantEat(self))
    }
    
    genIndex(add: command == .empty ? genIndex : 1)
  }
  
  private func handleDeadStep(resultHandler: (WorldSituation) -> ()) {
    resultHandler(.botWasGone(self))
  }
  
  private func mutate(with index: Int) {
    for _ in 1...index {
      let newCommand = possibleCommands.randomElement() ?? .empty
      // Command(rawValue: Int.random(in: 0...(Command.allCases.count - 1))) ?? .empty
      geneticCode[Int.random(in: 0...(GENETIC_CODE_SIZE - 1))] = newCommand
      
      botColor = color(for: geneticCode)
    }
  }
  
  private func genIndex(add steps: Int) {
    genIndex += steps
    if genIndex >= geneticCode.count {
      genIndex -= GENETIC_CODE_SIZE
    }
  }
  
  private func dead() {
    isDead = true
//    color = .black
  }
}

// MARK: - Genom Utils

extension Bot {
  private func color(for genom: [Command]) -> BotColor {
    let numOfPhotosynthesis = genom.histogram[.photosynthesis] ?? 0
    let numOfEat = genom.histogram[.eat] ?? 0
    let numOfReproductivity = genom.histogram[.reproduction] ?? 0
    
    let red = numOfEat
    let green = numOfPhotosynthesis
    let blue = numOfReproductivity
    
    let summ = red + green + blue
    
    return BotColor(red: CGFloat(red) / CGFloat(summ),
                    green: CGFloat(green) / CGFloat(summ),
                    blue: CGFloat(blue) / CGFloat(summ))
  }
  
  private static func maxAge(for geneticCode: [Command]) -> Int {
    return 100
  }
}

// MARK: - Commands

extension Bot {
  func reproduction(with mutateIndex: Int) -> Bot? {
    guard Double(energy) > Double(MAX_ENERGY) * 0.75 else { return nil }
    
    var directions = Direction.allCases
    
    while true {
      guard let direction = directions.randomElement() else { return nil }
      let newCoord = coord.moved(to: direction)
      
      if world.canReproduce(coord: newCoord) {
        energy /= 2
        
        let bot = Bot(world: world, coord: newCoord, color: botColor, geneticCode: geneticCode)
        bot.energy = energy
        bot.mutate(with: mutateIndex)
        
        return bot
      } else {
        directions.removeAll(where: { $0 == direction })
      }
    }
  }
}

// MARK: - Hashable

extension Bot: Hashable {
  func hash(into hasher: inout Hasher) {
    ID.hash(into: &hasher)
  }
  
  static func == (lhs: Bot, rhs: Bot) -> Bool {
    return lhs.ID == rhs.ID
  }
}
