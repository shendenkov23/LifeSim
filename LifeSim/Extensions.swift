//
//  Extensions.swift
//  LifeSim
//
//  Created by iDeveloper on 2/5/19.
//  Copyright © 2019 iDeveloper. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
  var histogram: [Element: Int] {
    return self.reduce(into: [:]) { counts, elem in counts[elem, default: 0] += 1 }
  }
}
