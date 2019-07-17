//
//  ViewController.swift
//  LifeSim
//
//  Created by iDeveloper on 2/5/19.
//  Copyright © 2019 iDeveloper. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
  
  //MARK: - IBOutlets
  
  @IBOutlet private weak var lifeField: LifeFieldView!
  
  //MARK: -
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }
  
  //MARK: -
}

