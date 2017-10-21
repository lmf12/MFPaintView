//
//  ViewController.swift
//  MFPaintViewDemo
//
//  Created by Lyman Li on 2017/10/16.
//  Copyright © 2017年 Lyman Li. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var paintView: MFPaintView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.paintView.setPaintLineColor(lineColor: UIColor.red)
        self.paintView.setPaintLineWidth(lineWidth: 10.0)
    }
    
    // MARK: - action
    @IBAction func onEraserClick(_ sender: UIButton) {
        
        self.paintView.setBrushMode(brushMode: MFPaintViewBrushMode.eraser)
    }
    
    @IBAction func onRedClick(_ sender: UIButton) {
        
        self.paintView.setBrushMode(brushMode: MFPaintViewBrushMode.paint)
        self.paintView.setPaintLineColor(lineColor: UIColor.red)
    }
    
    @IBAction func onGreenClick(_ sender: UIButton) {
        
        self.paintView.setBrushMode(brushMode: MFPaintViewBrushMode.paint)
        self.paintView.setPaintLineColor(lineColor: UIColor.green)
    }
    
    @IBAction func onBigBrushClick(_ sender: UIButton) {
        
        self.paintView.setPaintLineWidth(lineWidth: 20.0)
    }
    
    @IBAction func onSmallBrushClick(_ sender: UIButton) {
        
        self.paintView.setPaintLineWidth(lineWidth: 10.0)
    }
    
    @IBAction func onCleanupClick(_ sender: UIButton) {
        
        self.paintView.cleanup()
    }
    
}

