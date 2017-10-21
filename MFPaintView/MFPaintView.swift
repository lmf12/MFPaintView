//
//  MFPaintView.swift
//  MFPaintViewDemo
//
//  Created by Lyman Li on 2017/10/16.
//  Copyright © 2017年 Lyman Li. All rights reserved.
//

import UIKit

enum MFPaintViewBrushMode {
    case paint
    case eraser
}

class MFPaintView: UIView {
    
    // MARK: - super property
    override var backgroundColor: UIColor? {
        didSet {
            //如果背景色非透明，橡皮擦功能会有问题
            super.backgroundColor = UIColor.clear
        }
    }
    
    // MARK: - public property
    private var paintLineWidth: CGFloat = 1.0
    private var paintStrokeColor: UIColor = UIColor.black
    private var isEraserMode: Bool = false
    
    // MARK: - private property
    private var paths = [MFBezierPath]()
    private var currentPath: MFBezierPath?

    // MARK: - super methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override func draw(_ rect: CGRect) {
        
        for path in paths {
            
            if (path.isEraser) {
                UIColor.clear.set()
                path.stroke(with: CGBlendMode.clear, alpha: 1.0)
            }
            else {
                path.lineColor.set()
                path.stroke()
            }
        }
        
        super.draw(rect)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        super.touchesBegan(touches, with: event)
        
        self.currentPath = MFBezierPath()
        self.currentPath?.lineColor = self.paintStrokeColor
        self.currentPath?.lineWidth = self.paintLineWidth
        self.currentPath?.isEraser = self.isEraserMode
        self.currentPath?.lineCapStyle = CGLineCap.round
        self.currentPath?.lineJoinStyle = CGLineJoin.round
        
        self.paths.append(self.currentPath!)
        
        let point:CGPoint = (event?.allTouches?.first?.location(in: self))!
        self.currentPath?.move(to: point)
        
        self.setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesMoved(touches, with: event)
        
        let currentTouch = event?.allTouches?.first;
        
        let currentPoint = (currentTouch?.location(in: self))!
        let prePoint = (currentTouch?.previousLocation(in: self))!
        
        let midPoint = CGPoint(x:(prePoint.x + currentPoint.x) * 0.5,
                               y: (prePoint.y + currentPoint.y) * 0.5)
        
        
        self.currentPath?.addQuadCurve(to: midPoint, controlPoint: prePoint)
        
        self.setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesCancelled(touches, with: event)
        
        let currentTouch = event?.allTouches?.first;
        
        let currentPoint = (currentTouch?.location(in: self))!
        let prePoint = (currentTouch?.previousLocation(in: self))!
        
        self.currentPath?.addQuadCurve(to: currentPoint, controlPoint: prePoint)
        
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesEnded(touches, with: event)
        
        let currentTouch = event?.allTouches?.first;
        
        let currentPoint = (currentTouch?.location(in: self))!
        let prePoint = (currentTouch?.previousLocation(in: self))!
        
        self.currentPath?.addQuadCurve(to: currentPoint, controlPoint: prePoint)
        
        self.setNeedsDisplay()
    }
    
    // MARK: - public methods
    
    /// 设置画笔或橡皮擦粗细
    ///
    /// - Parameter width: 画笔或橡皮擦粗细
    public func setPaintLineWidth(lineWidth width: CGFloat) {
        
        self.paintLineWidth = width;
    }

    /// 设置画笔颜色
    ///
    /// - Parameter color: 画笔颜色
    public func setPaintLineColor(lineColor color: UIColor) {
        
        self.paintStrokeColor = color;
    }
    
    
    /// 设置笔刷模式
    ///
    /// - Parameter mode: 画笔或橡皮擦
    public func setBrushMode(brushMode mode: MFPaintViewBrushMode) {
        
        self.isEraserMode = mode == .eraser;
    }
    
    /// 清除画板
    public func cleanup() {
        
        self.paths.removeAll()
        self.setNeedsDisplay()
    }
    
    // MARK: - private methods
    private func commonInit() {
        
        self.backgroundColor = UIColor.clear
    }
}


















