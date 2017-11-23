//
//  ViewController.swift
//  MFPaintViewDemo
//
//  Created by Lyman Li on 2017/10/16.
//  Copyright © 2017年 Lyman Li. All rights reserved.
//

import UIKit

class ViewController: UIViewController, MFPaintViewDelegate {

    @IBOutlet weak var paintView: MFPaintView!
    @IBOutlet weak var btnUndo: UIButton!
    @IBOutlet weak var btnRedo: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.paintView.setPaintLineColor(lineColor: UIColor.red)
        self.paintView.setPaintLineWidth(lineWidth: 10.0)
        self.paintView.delegate = self;
        
        self.refreshUndoAndRedoState()
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
        self.refreshUndoAndRedoState()
    }
    
    @IBAction func onUndoClick(_ sender: UIButton) {
        
        self.paintView.undo()
        self.refreshUndoAndRedoState()
    }
    
    @IBAction func onRedoClick(_ sender: UIButton) {
        
        self.paintView.redo()
        self.refreshUndoAndRedoState()
    }
    
    // MARK: - MFPaintViewDelegate
    func paintViewDidFinishDrawLine(_ paintView: MFPaintView) {
        
        self.refreshUndoAndRedoState()
    }
    
    func paintViewWillBeginDrawLine(_ paintView: MFPaintView) {
        
    }
    
    // MARK: - private methods
    private func refreshUndoAndRedoState() {
    
        self.btnUndo.setTitleColor(paintView.canUndo() ? UIColor.blue : UIColor.gray,
                                   for: UIControlState.normal)
        self.btnRedo.setTitleColor(paintView.canRedo() ? UIColor.blue : UIColor.gray,
                                   for: UIControlState.normal)
    }
    
}

