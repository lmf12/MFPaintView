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

protocol MFPaintViewDelegate {
    
    func paintViewDidFinishDrawLine(_ paintView: MFPaintView);
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
    public var delegate: MFPaintViewDelegate?
    private var paintLineWidth: CGFloat = 1.0
    private var paintStrokeColor: UIColor = UIColor.black
    private var isEraserMode: Bool = false
    
    // MARK: - private property
    private var paths = [MFBezierPath]()
    private var undoPaths = [MFBezierPath]() //被撤销的路径
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
        self.undoPaths.removeAll()
        
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
        
        if (self.needsCorrectCurve(currentPoint: (self.currentPath?.currentPoint)!, endPoint: midPoint, controlPoint: prePoint, lineWidth: (self.currentPath?.lineWidth)!)) {
                        
            self.currentPath?.addLine(to: prePoint)
            self.currentPath?.addLine(to: midPoint)
        }
        else {
            self.currentPath?.addQuadCurve(to: midPoint, controlPoint: prePoint)
        }
 
        self.setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesCancelled(touches, with: event)
        
        let currentTouch = event?.allTouches?.first;
        
        let currentPoint = (currentTouch?.location(in: self))!
        let prePoint = (currentTouch?.previousLocation(in: self))!
        
        self.currentPath?.addQuadCurve(to: currentPoint, controlPoint: prePoint)
        
        self.setNeedsDisplay()
        
        self.delegate?.paintViewDidFinishDrawLine(self)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesEnded(touches, with: event)
        
        let currentTouch = event?.allTouches?.first;
        
        let currentPoint = (currentTouch?.location(in: self))!
        let prePoint = (currentTouch?.previousLocation(in: self))!
        
        self.currentPath?.addQuadCurve(to: currentPoint, controlPoint: prePoint)
        
        self.setNeedsDisplay()
        
        self.delegate?.paintViewDidFinishDrawLine(self)
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
        self.undoPaths.removeAll()
        self.setNeedsDisplay()
    }
    
    /// 撤销上一步操作
    public func undo() {
    
        if (!self.canUndo()) {
            return
        }
        
        let path = self.paths.removeLast()
        self.undoPaths.append(path)
        self.setNeedsDisplay()
    }
    
    /// 重做撤销的操作
    public func redo() {
        
        if (!self.canRedo()) {
            return
        }
        
        let path = self.undoPaths.removeLast()
        self.paths.append(path)
        self.setNeedsDisplay()
    }
    
    /// 是否可以进行撤销
    ///
    /// - Returns: 是或否
    public func canUndo() -> Bool {
    
        return self.paths.count > 0;
    }
    
    /// 是否可以进行重做
    ///
    /// - Returns: 是或否
    public func canRedo() -> Bool {
    
        return self.undoPaths.count > 0;
    }
    
    // MARK: - private methods
    private func commonInit() {
        
        self.backgroundColor = UIColor.clear
    }
    
    /// 检查贝塞尔曲线角度是否过小，过小则需要修正
    ///
    /// - Parameters:
    ///   - currentPoint: 曲线出发点
    ///   - endPoint: 曲线结束点
    ///   - controlPoint: 曲线控制点
    ///   - lineWidth: 线宽
    /// - Returns: 是或否
    private func needsCorrectCurve(currentPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint, lineWidth: CGFloat) -> Bool {

        let angle = self.getAnglesWithThreePoint(startPoint: currentPoint, centerPoint: controlPoint, endPoint: endPoint)
        
        return (angle < CGFloat.pi / 20)
    }
    
    /// 获取三个点的角度
    ///
    /// - Parameters:
    ///   - startPoint: 角度起始点
    ///   - centerPoint: 角度中间点
    ///   - endPoint: 角度终点
    /// - Returns: 角的弧度0～π
    private func getAnglesWithThreePoint(startPoint: CGPoint, centerPoint: CGPoint, endPoint: CGPoint) -> CGFloat {
    
        let x1 = startPoint.x - centerPoint.x
        let y1 = startPoint.y - centerPoint.y;
        let x2 = endPoint.x - centerPoint.x;
        let y2 = endPoint.y - centerPoint.y;
        
        let x = x1 * x2 + y1 * y2;
        let y = x1 * y2 - x2 * y1;
        
        let angle = acos(x/sqrt(x*x+y*y));
        
        return angle;
    }
}












