//
//  Settings.swift
//  LifeSim
//
//  Created by iDeveloper on 2/8/19.
//  Copyright © 2019 iDeveloper. All rights reserved.
//

import Foundation

let STEPS_IN_TICK = 5000

//MARK: - BOT

let GENETIC_CODE_SIZE = 64

let MAX_ENERGY = 1000
let MAX_BODY = 1000

let ENERGY_STEP = 10

//MARK: - WORLD

let MAX_LIGHT_VALUE = 30

let WORLD_ROWS =
//108
144
var WORLD_COLUMNS: Int {
  return Int(Double(WORLD_ROWS) * 1.6)
}
