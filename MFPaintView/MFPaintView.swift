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

enum MFPaintViewStatus {
    case normal
    case drawing
}

protocol MFPaintViewDelegate {
    
    func paintViewWillBeginDrawLine(_ paintView: MFPaintView)
    
    func paintViewDidFinishDrawLine(_ paintView: MFPaintView)
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
    private var status = MFPaintViewStatus.normal
    private var paths = [MFBezierPath]()
    private var undoPaths = [MFBezierPath]() //被撤销的路径
    private var currentPath: MFBezierPath?
    private var lastImage: UIImage?

    // MARK: - super methods
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    @available(iOS 10.0, *)
    override func layerWillDraw(_ layer: CALayer) {
        super.layerWillDraw(layer)

        if self.status == MFPaintViewStatus.drawing && self.lastImage == nil {
            self.refreshLastImage()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        //正在绘画则使用画Image方式，否则使用画path方式
        if self.status == MFPaintViewStatus.drawing && self.lastImage != nil {
            self.lastImage?.draw(at: CGPoint.zero, blendMode: CGBlendMode.normal, alpha: 1.0)
            if (self.currentPath?.isEraser)! {
                UIColor.clear.set()
                self.currentPath?.stroke(with: CGBlendMode.clear, alpha: 1.0)
            }
            else {
                self.currentPath?.lineColor.set()
                self.currentPath?.stroke()
            }
        }
        else {
            for path in paths {
                if path.isEraser {
                    UIColor.clear.set()
                    path.stroke(with: CGBlendMode.clear, alpha: 1.0)
                }
                else {
                    path.lineColor.set()
                    path.stroke()
                }
            }
        }
        
        super.draw(rect)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        super.touchesBegan(touches, with: event)
        
        self.status = MFPaintViewStatus.drawing
        self.delegate?.paintViewWillBeginDrawLine(self)
        
        self.currentPath = MFBezierPath()
        self.currentPath?.lineColor = self.paintStrokeColor
        self.currentPath?.lineWidth = self.paintLineWidth
        self.currentPath?.isEraser = self.isEraserMode
        self.currentPath?.lineCapStyle = CGLineCap.round
        self.currentPath?.lineJoinStyle = CGLineJoin.round
        
        self.paths.append(self.currentPath!)
        self.undoPaths.removeAll()
        
        var point = (event?.allTouches?.first?.location(in: self))!
        point = self.pointWithOffset(point: point)
        self.currentPath?.move(to: point)
        
        self.setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesMoved(touches, with: event)
        
        let currentTouch = event?.allTouches?.first
        var currentPoint = (currentTouch?.location(in: self))!
        currentPoint = self.pointWithOffset(point: currentPoint)
        var prePoint = (currentTouch?.previousLocation(in: self))!
        prePoint = self.pointWithOffset(point: prePoint)
        let midPoint = CGPoint(x:(prePoint.x + currentPoint.x) * 0.5,
                               y: (prePoint.y + currentPoint.y) * 0.5)
        
        let needRefreshArea = self.areaContainsPoints(points: (self.currentPath?.currentPoint)!, prePoint, midPoint, lineWidth: (self.currentPath?.lineWidth)!)
        
        if self.needsCorrectCurve(currentPoint: (self.currentPath?.currentPoint)!, endPoint: midPoint, controlPoint: prePoint, lineWidth: (self.currentPath?.lineWidth)!) {
                        
            self.currentPath?.addLine(to: prePoint)
            self.currentPath?.addLine(to: midPoint)
        }
        else {
            self.currentPath?.addQuadCurve(to: midPoint, controlPoint: prePoint)
        }
 
        self.setNeedsDisplay(needRefreshArea)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesCancelled(touches, with: event)
        
        self.drawEnd(with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesEnded(touches, with: event)
        
        self.drawEnd(with: event)
    }
    
    // MARK: - public methods
    
    /// 设置画笔或橡皮擦粗细
    ///
    /// - Parameter width: 画笔或橡皮擦粗细
    public func setPaintLineWidth(lineWidth width: CGFloat) {
        
        if !(self.status == MFPaintViewStatus.normal) {
            return
        }
        
        self.paintLineWidth = width
    }

    /// 设置画笔颜色
    ///
    /// - Parameter color: 画笔颜色
    public func setPaintLineColor(lineColor color: UIColor) {
        
        if !(self.status == MFPaintViewStatus.normal) {
            return
        }
        
        self.paintStrokeColor = color
    }
    
    /// 设置笔刷模式
    ///
    /// - Parameter mode: 画笔或橡皮擦
    public func setBrushMode(brushMode mode: MFPaintViewBrushMode) {
        
        if !(self.status == MFPaintViewStatus.normal) {
            return
        }
        
        self.isEraserMode = mode == .eraser
    }
    
    
    /// 获取当前的笔刷模式
    ///
    /// - Returns: 当前的笔刷模式
    public func brushMode() -> MFPaintViewBrushMode {
        
        return self.isEraserMode ? .eraser : .paint
    }
    
    /// 清除画板
    public func cleanup() {
        
        if !(self.status == MFPaintViewStatus.normal) {
            return
        }
        
        self.lastImage = nil
        self.paths.removeAll()
        self.undoPaths.removeAll()
        self.setNeedsDisplay()
    }
    
    /// 撤销上一步操作
    public func undo() {
    
        if !(self.status == MFPaintViewStatus.normal) {
            return
        }
        
        if !self.canUndo() {
            return
        }
        
        let path = self.paths.removeLast()
        self.undoPaths.append(path)
        self.lastImage = nil
        self.setNeedsDisplay()
    }
    
    /// 重做撤销的操作
    public func redo() {
        
        if !(self.status == MFPaintViewStatus.normal) {
            return
        }
        
        if !self.canRedo() {
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
    
        return self.status == MFPaintViewStatus.normal && self.paths.count > 0
    }
    
    /// 是否可以进行重做
    ///
    /// - Returns: 是或否
    public func canRedo() -> Bool {
    
        return self.status == MFPaintViewStatus.normal &&  self.undoPaths.count > 0
    }
    
    /// 获取快照
    ///
    /// - Returns: 当前绘画的快照
    public func snapshot() -> UIImage? {
        
        if self.status == MFPaintViewStatus.normal {
            self.refreshLastImage()
        }
        return self.lastImage
    }
    
    
    /// 获取偏移后的点
    ///
    /// - Parameter point: 原始点
    /// - Returns: 偏移后的点
    public func pointWithOffset(point: CGPoint) -> CGPoint {
        
        return point
    }
    
    // MARK: - private methods
    
    /// 初始化
    private func commonInit() {
        
        self.backgroundColor = UIColor.clear
    }
    
    /// 单次绘画结束处理
    ///
    /// - Parameter event: 触摸事件
    private func drawEnd(with event: UIEvent?) {
        
        let currentTouch = event?.allTouches?.first
        var currentPoint = (currentTouch?.location(in: self))!
        currentPoint = self.pointWithOffset(point: currentPoint)
        var prePoint = (currentTouch?.previousLocation(in: self))!
        prePoint = self.pointWithOffset(point: prePoint)
        
        let needRefreshArea = self.areaContainsPoints(points: (self.currentPath?.currentPoint)!, prePoint, currentPoint, lineWidth: (self.currentPath?.lineWidth)!)
        
        self.currentPath?.addQuadCurve(to: currentPoint, controlPoint: prePoint)
        
        self.setNeedsDisplay(needRefreshArea)
        
        self.refreshLastImage()
        
        self.status = MFPaintViewStatus.normal
        
        self.delegate?.paintViewDidFinishDrawLine(self)
    }
    
    /// 更新上次绘画完成的的Image
    private func refreshLastImage() {
        
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        self.lastImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
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

        let angle = self.anglesWithThreePoint(startPoint: currentPoint, centerPoint: controlPoint, endPoint: endPoint)
        
        return (angle < CGFloat.pi / 20)
    }
    
    /// 获取三个点的角度
    ///
    /// - Parameters:
    ///   - startPoint: 角度起始点
    ///   - centerPoint: 角度中间点
    ///   - endPoint: 角度终点
    /// - Returns: 角的弧度0～π
    private func anglesWithThreePoint(startPoint: CGPoint, centerPoint: CGPoint, endPoint: CGPoint) -> CGFloat {
    
        let x1 = startPoint.x - centerPoint.x
        let y1 = startPoint.y - centerPoint.y
        let x2 = endPoint.x - centerPoint.x
        let y2 = endPoint.y - centerPoint.y
        
        let x = x1 * x2 + y1 * y2
        let y = x1 * y2 - x2 * y1
        
        let angle = acos(x/sqrt(x*x+y*y))
        
        return angle
    }
    
    
    /// 获取包含所有点的区域
    ///
    /// - Parameters:
    ///   - points: 所有的点的坐标
    ///   - lineWidth: 线宽
    /// - Returns: 包含所有点的区域
    private func areaContainsPoints(points: CGPoint..., lineWidth: CGFloat) -> CGRect {
        
        if points.count == 0 {
            return CGRect.zero
        }
        
        var minX = points[0].x, minY = points[0].y, maxX = points[0].x, maxY = points[0].y

        for point in points {
            if point.x < minX {
                minX = point.x
            }
            if point.y < minY {
                minY = point.y
            }
            if point.x > maxX {
                maxX = point.x
            }
            if point.y > maxY {
                maxY = point.y
            }
        }
        
        return CGRect(x: minX - lineWidth * 0.5 - 1, y: minY - lineWidth * 0.5 - 1,
                      width: maxX - minX + lineWidth + 2, height: maxY - minY + lineWidth + 2)
    }
}












