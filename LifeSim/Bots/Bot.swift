//
//  Bot.swift
//  LifeSim
//
//  Created by iDeveloper on 2/5/19.
//  Copyright © 2019 iDeveloper. All rights reserved.
//

import Cocoa

class Bot {
  var isGone = false
  
  private let ID: String
  
  let world: LifeFieldView
  
  //MARK: -
  
  var isAdam: Bool = false
  
  private(set) var isDead = false
  
  private(set) var coord: Coord
  private(set) var color: NSColor
  
  private(set) var age: Int = 0
  
  private(set) var body: Int = MAX_BODY
  private(set) var energy: Int = MAX_ENERGY
  
  private var genIndex = 0
  private(set) var geneticCode: [Command]
  
  var nextBot: Bot?
  var prevBot: Bot?
  
  var maxAge: Int {
    return 0
  }
  
  var possibleCommands: [Command] {
    return Command.allCases
  }
  
  //MARK: -
  
  init(world: LifeFieldView, coord: Coord, color: NSColor, geneticCode: [Command]) {
    ID = UUID().uuidString
    
    self.world = world
    
    self.coord = coord
    self.color = color
    
    self.geneticCode = geneticCode
  }
  
  //MARK: -
  
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
  
  func isSameType(as bot: Bot) -> Bool {
    if self is HerbivorousBot {
      return bot is HerbivorousBot
    } else if self is PredatorBot {
      return bot is PredatorBot
    }
    return false
  }
  
  //MARK: -
  
  private func handleLiveStep(resultHandler: (WorldSituation) -> ()) {

    age += 1
    energy -= ENERGY_STEP
    
    //    print("BOT \(ID) AGE: \(age) ENERGY: \(energy)")
    
    guard age < maxAge, energy > 0 else {
      dead()
      resultHandler(.botDied(self))
      return
    }
    
    color = NSColor(calibratedRed: color.redComponent,
                    green: color.greenComponent,
                    blue: color.blueComponent,
                    alpha: 1.0 - (CGFloat(age) / CGFloat(maxAge)) + 0.25)
    
    let command = geneticCode[genIndex]
    
//    print("COMMAND \(genIndex):", command)
    switch command {
    case .empty: break
    case .move: resultHandler(.botWantMove(self))
    case .reproduction:
      if let newBot = reproduction(with: 1) {
        newBot.prevBot = self.prevBot
        self.prevBot?.nextBot = newBot
        
        self.prevBot = newBot
        newBot.nextBot = self
        
        resultHandler( .botWasBorn(newBot) )
      }
    case .photosynthesis:
      resultHandler(.botPhotosynthesised(self))
    case .eat:
      resultHandler(.botWantEat(self))
    }
    
    genIndex(add: command == .empty ? genIndex : 1)
  }
  
  private func handleDeadStep(resultHandler: (WorldSituation) -> ()) {
//    resultHandler(.botDecomposed(self))
    
//    guard body > 0 else {
      resultHandler(.botWasGone(self))
//      return
//    }
    
//    resultHandler(.botFalling(self))
  }
  
  private func color(for genom: [Command]) -> NSColor {
    let numOfPhotosynthesis = genom.histogram[.photosynthesis] ?? 0
    let numOfEat = genom.histogram[.eat] ?? 0
//    let numOfMoved = genom.histogram[.move] ?? 0
    let numOfReproductivity = genom.histogram[.reproduction] ?? 0
//    let numOfDarkness = genom.histogram[.empty] ?? 0

    let partOfGeneticSize = GENETIC_CODE_SIZE / 4
    
    var red = numOfEat
    var green = numOfPhotosynthesis
    var blue = numOfReproductivity
    let coef = 10
    
    if numOfEat > partOfGeneticSize {
      red = partOfGeneticSize + coef * (numOfEat - partOfGeneticSize)
    }
    if numOfPhotosynthesis > partOfGeneticSize {
      green = partOfGeneticSize + coef * (numOfPhotosynthesis - partOfGeneticSize)
    }
    if numOfReproductivity > partOfGeneticSize {
      blue = partOfGeneticSize + coef * (numOfReproductivity - partOfGeneticSize)
    }
    
    return NSColor(calibratedRed: CGFloat(red) / CGFloat(GENETIC_CODE_SIZE),
                   green: CGFloat(green) / CGFloat(GENETIC_CODE_SIZE),
                   blue: CGFloat(blue) / CGFloat(GENETIC_CODE_SIZE),
                   alpha: self.color.alphaComponent)
    
//    let maximum = max(numOfPhotosynthesis, numOfMoved, numOfReproductivity, numOfDarkness)
//    if maximum == numOfPhotosynthesis {
//      //GREEN
//      return NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.0,
//                           alpha: self.color.alphaComponent)
//    } else if maximum == numOfMoved {
//      //RED
//      return NSColor(calibratedRed: 1.0, green: 0.0, blue: 0.0,
//                           alpha: self.color.alphaComponent)
//    } else if maximum == numOfReproductivity {
//      //BLUE
//      return NSColor(calibratedRed: 0.0, green: 0.0, blue: 1.0,
//                           alpha: self.color.alphaComponent)
//    } else if maximum == numOfDarkness {
//      //GRAY
//      return NSColor(calibratedRed: 0.5, green: 0.5, blue: 0.5,
//                           alpha: self.color.alphaComponent)
//    }
//
//    return NSColor.purple //TODO: remove
  }
  
  private func mutate(with index: Int) {
    for _ in 1...index {
      let newCommand = possibleCommands.randomElement() ?? .empty
        //Command(rawValue: Int.random(in: 0...(Command.allCases.count - 1))) ?? .empty
      geneticCode[Int.random(in: 0...(GENETIC_CODE_SIZE - 1))] = newCommand
      
      self.color = color(for: geneticCode)
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

//MARK: - Commands

extension Bot {
  
  func reproduction(with mutateIndex: Int) -> Bot? {
    guard Double(energy) > Double(MAX_ENERGY) * 0.75 else { return nil }
    
    var directions = Direction.allCases
    
    while true {
      guard let direction = directions.randomElement() else { return nil }
      let newCoord = coord.moved(to: direction)
      
      if world.canReproduce(coord: newCoord) {
        let newColor = NSColor(calibratedRed: color.redComponent,
                               green: color.greenComponent,
                               blue: color.blueComponent,
                               alpha: 1.0)
        energy /= 2
        
        var bot: Bot?
        if self is HerbivorousBot {
          
          if Int.random(in: 0...10) == 0, coord.y < WORLD_ROWS / 2 {
            let geneticCode = self.geneticCode.map({ return $0 == Command.photosynthesis ? Command.eat : $0 })
            
            bot = PredatorBot(world: world, coord: newCoord, color: newColor, geneticCode: geneticCode)
            bot?.energy = energy
            bot?.mutate(with: mutateIndex)
          } else {
            bot = HerbivorousBot(world: world, coord: newCoord, color: newColor, geneticCode: geneticCode)
            bot?.energy = energy
            bot?.mutate(with: mutateIndex)
          }
          
        } else if self is PredatorBot {
          bot = PredatorBot(world: world, coord: newCoord, color: newColor, geneticCode: geneticCode)
          bot?.energy = energy
          bot?.mutate(with: mutateIndex)
        } else {
          bot = Bot(world: world, coord: newCoord, color: newColor, geneticCode: geneticCode)
          bot?.energy = energy
          bot?.mutate(with: mutateIndex)
        }
        
        return bot
      } else {
        directions.removeAll(where: { $0 == direction })
      }
    }
  }
}


extension Bot: Hashable {
  
  func hash(into hasher: inout Hasher) {
    ID.hash(into: &hasher)
  }
  
  static func == (lhs: Bot, rhs: Bot) -> Bool {
    return lhs.ID == rhs.ID
  }
}
