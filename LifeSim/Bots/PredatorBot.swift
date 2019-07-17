//
//  PredatorBot.swift
//  LifeSim
//
//  Created by iDeveloper on 2/8/19.
//  Copyright © 2019 iDeveloper. All rights reserved.
//

import Foundation

class PredatorBot: Bot {
  
  override var maxAge: Int { return PREDATOR_MAX_AGE }
  
  override var possibleCommands: [Command] {
    return [.empty, .move, .reproduction, .eat]
  }
}
