//
//  LifeFieldView.swift
//  LifeSim
//
//  Created by iDeveloper on 2/5/19.
//  Copyright © 2019 iDeveloper. All rights reserved.
//

import Cocoa

enum WorldSituation {
  case lifeCreated(Coord)
  
  case botWasBorn(Bot)
  
  case botPhotosynthesised(Bot)
  case botWantMove(Bot)
  case botWantEat(Bot)
  
  case botDied(Bot)
  case botFalling(Bot)
//  case botDecomposed(Bot)
  case botWasGone(Bot)
}

// MARK: -

// ================================================================================

class LifeFieldView: NSView {
  var displayLink: CVDisplayLink?
  var currentTick: Int = 0
  var numberOfBots: Int = 0
  
  var tileHeight: CGFloat = 0
  var tileWidth: CGFloat = 0
  
  var cells = [[Cell]]()
  
  var currentBot: Bot?
  
  var context: CGContext? {
    return NSGraphicsContext.current?.cgContext
  }
  
  // MARK: -
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    
    for _ in 0...WORLD_ROWS - 1 {
      var row = [Cell]()
      for _ in 0...WORLD_COLUMNS - 1 {
        row.append(Cell())
      }
      cells.append(row)
    }
    
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
    CVDisplayLinkSetOutputCallback(displayLink!,
                                   
                                   { (_: CVDisplayLink,
                                      _: UnsafePointer<CVTimeStamp>,
                                      _: UnsafePointer<CVTimeStamp>,
                                      _: CVOptionFlags,
                                      _: UnsafeMutablePointer<CVOptionFlags>,
                                      sourceUnsafeRaw: UnsafeMutableRawPointer?) -> CVReturn in
                                     
                                     if let sourceUnsafeRaw = sourceUnsafeRaw {
                                       let mySelf = Unmanaged<LifeFieldView>.fromOpaque(sourceUnsafeRaw).takeUnretainedValue()
                                       DispatchQueue.main.sync {
                                         mySelf.worldTick()
                                         _ = Unmanaged<LifeFieldView>.fromOpaque(sourceUnsafeRaw).retain()
                                       }
                                     }
                                     
                                     return kCVReturnSuccess
                                     
    }, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
    CVDisplayLinkStart(displayLink!)
  }
  
  deinit {
    if let timer = displayLink {
      CVDisplayLinkStop(timer)
    }
  }
  
  override func layout() {
    super.layout()
    tileHeight = bounds.height / CGFloat(WORLD_ROWS)
    tileWidth = bounds.width / CGFloat(WORLD_COLUMNS)
  }
  
  // MARK: - Ticks
  
  func worldTick() {
    currentTick += 1
    
    var stepsInTick = min(STEPS_IN_TICK, numberOfBots)
    print("Tick:", currentTick, " BOTS:", numberOfBots)
    
    if numberOfBots <= 0 {
      createLife()
    } else {
      while stepsInTick > 0 {
        if let currBot = currentBot {
          currBot.step { [weak self] situation in
            self?.handleSituation(situation)
            
            var next = currBot.nextBot
            if next!.isAdam {
              next = next!.nextBot
            }
            self?.currentBot = next
          }
          stepsInTick -= 1
        }
      }
    }
    
    layer?.sublayers?.removeAll()
    drawBots()
  }
  
  // MARK: - Draw
  
  private func drawBots() {
    guard let startDrawingBot = currentBot else { return }
    
    func drawBot(_ bot: Bot) -> Bot? {
      let coord = bot.coord
      let color = bot.color
      
      let botLayer = CALayer()
      botLayer.frame = CGRect(x: tileWidth * CGFloat(coord.x) + 0.5,
                              y: tileHeight * CGFloat(coord.y) + 0.5,
                              width: tileWidth - 1,
                              height: tileHeight - 1)
      botLayer.backgroundColor = color.cgColor
      
      layer?.addSublayer(botLayer)
      
      return bot.nextBot
    }
    
    var nextBot = drawBot(startDrawingBot)
    while nextBot != nil {
      guard let bot = nextBot else { break }
      guard nextBot != startDrawingBot else { break }
      nextBot = drawBot(bot)
    }
  }
  
  // MARK: - Bot interface
  
  func canReproduce(coord: Coord) -> Bool {
    return isEmpty(coord: coord)
  }
  
  // MARK: -
  
  func createLife() {
    let coord = Coord(x: WORLD_COLUMNS - 1, y: WORLD_ROWS - 1)
    handleSituation(.lifeCreated(coord))
  }
  
  private func setCell(_ state: CellState, with coord: Coord) {
    let cell = cells[coord.y][coord.x]
    cell.state = state
  }
  
  private func isEmpty(coord: Coord) -> Bool {
    guard coord.isValid else { return false }
    switch cells[coord.y][coord.x].state {
    case .empty: return true
    default: return false
    }
  }
  
  private func lightValue(for coord: Coord) -> Float {
    return Float(coord.y) / Float(WORLD_ROWS) * Float(MAX_LIGHT_VALUE)
  }
  
  private func handleSituation(_ situation: WorldSituation) {
    switch situation {
    case .lifeCreated(let coord):
      
      var geneticCode = [Command]()
      for i in 0...GENETIC_CODE_SIZE - 1 {
        switch i % 4 {
        case 0: geneticCode.append(.photosynthesis)
        case 1: geneticCode.append(.empty)
        case 2: geneticCode.append(.move)
        default: geneticCode.append(.reproduction)
        }
      }
      
      let adam = Bot(world: self, coord: coord, color: .white, geneticCode: geneticCode)
      adam.isAdam = true
      
      let first = Bot(world: self,
                      coord: coord,
                      color: .orange,
                      geneticCode: geneticCode)
      adam.nextBot = first
      adam.prevBot = first
      first.prevBot = adam
      first.nextBot = adam
      
      currentBot = first
      handleSituation(.botWasBorn(first))
      
    case .botWasBorn(let bot):
      cells[bot.coord.y][bot.coord.x].state = .fill(bot)
      numberOfBots += 1
    case .botPhotosynthesised(let bot):
      let energy = lightValue(for: bot.coord) * 2
      bot.addEnergy(Int(energy))
      
    case .botWantMove(let bot):
      let directions = Direction.allCases.shuffled()
      let prevCoord = bot.coord
      var newCoord: Coord?
      
      for i in 0..<directions.count {
        let direction = directions[i]
        let coord = prevCoord.moved(to: direction)
        
        if isEmpty(coord: coord) {
          newCoord = coord
          break
        }
      }
      
      if let newCoord = newCoord {
        cells[prevCoord.y][prevCoord.x].state = .empty
        bot.move(to: newCoord)
        cells[newCoord.y][newCoord.x].state = .fill(bot)
      }
      
    case .botWantEat(let bot):
      var directions = Direction.allCases
      while true {
        guard let direction = directions.randomElement() else { break }
        let coord = bot.coord.moved(to: direction)
        
        if coord.isValid,
          let victim = cells[coord.y][coord.x].bot,
          victim.isDead || bot.energy > victim.energy {
          bot.addEnergy(victim.body)
          victim.isGone = true
          break
        } else {
          directions.removeAll(where: { $0 == direction })
        }
      }
      
    case .botDied: break
    case .botFalling(let bot):
      let newCoord = bot.coord.moved(to: .down)
      
      if isEmpty(coord: newCoord) {
        cells[bot.coord.y][bot.coord.x].state = .empty
        bot.move(to: newCoord)
        cells[newCoord.y][newCoord.x].state = .fill(bot)
      }
      
    case .botWasGone(let bot):
      cells[bot.coord.y][bot.coord.x].state = .empty
      
      let pBot = bot.prevBot
      let nBot = bot.nextBot
      
      pBot?.nextBot = nBot
      nBot?.prevBot = pBot
      
      numberOfBots -= 1
    }
  }
}
