# MFPaintView
一个基于Quartz2D实现的画板，适用于Swift3.0以上版本。
![](https://raw.githubusercontent.com/lmf12/MFPaintView/master/exhibition.gif)

## 如何导入
#### 手动导入
将MFPaintView文件夹拖入工程中。
## 如何使用
#### 1. 引入与布局
支持通过**纯代码的方式**和**xib的方式**引入，支持**AutoLayout布局方式**和**Frame布局方式**。
#### 2. 实现代理（可选）
实现代理**MFPaintViewDelegate**，可在单次绘画开始和结束时做对应的操作。  
绘画即将开始时会调用：

```Swift
func paintViewWillBeginDrawLine(_ paintView: MFPaintView)
```
绘画已经结束时会调用：

```Swift
func paintViewDidFinishDrawLine(_ paintView: MFPaintView)
```
## 功能介绍
#### 1. 调整笔触大小
##### 实现方式：
通过设置Path的lineWidth来实现。
##### 接口方法：

```Swift
public func setPaintLineWidth(lineWidth width: CGFloat)
```
#### 2. 调整笔触颜色
##### 实现方式：
在func draw(_ rect: CGRect)中，调用path.stroke()之前，先调用color.set()，可进行笔触颜色设置。
##### 接口方法：

```Swift
public func setPaintLineColor(lineColor color: UIColor)
```
#### 3. 橡皮擦功能
##### 实现方式：
将当前颜色设置为**UIColor.clear**，并将BlendMode设置为CGBlendMode.clear来实现。关键代码如下：  

```Swift
UIColor.clear.set()
path.stroke(with: CGBlendMode.clear, alpha: 1.0)
```
##### 接口方法：

```Swift
public func setBrushMode(brushMode mode: MFPaintViewBrushMode)
```
#### 4. 撤销和重做
##### 实现方式：
将每一次绘画保存为一个路径，并将所有路径用栈来保存，撤销和重做只是一个出栈和入栈的过程。
##### 接口方法：

```Swift
public func undo()
public func redo()
```
#### 5. 结果保存
##### 实现方式：
对UIGraphicsGetCurrentContext()做一个render，并通过UIGraphicsGetImageFromCurrentImageContext()来获取一个UIImage对象。
##### 接口方法：

```Swift
public func snapshot() -> UIImage?
```
#### 6. 清除画板
##### 实现方式：
将保存在栈中的所有路径清空，此操作不可恢复。
##### 接口方法：

```Swift
public func cleanup()
```

## 性能优化
#### 1. 使用贝塞尔曲线解决连接点不平滑问题
一般画线功能的实现，是通过将上次触摸点坐标与当前触摸点坐标相连。但如果在性能较差的机器上，当手指的移动速度过快时，触摸点之间的距离较大时，线条会出现明显的转折点，如下图所示。这里采用了贝塞尔曲线进行优化，以曲线的上个结束点作为起点，上次的触摸点作为控制点，上次触摸点与本次触摸点的中点作为结束点，来绘制贝塞尔曲线，从而使线条更加平滑。
![](https://raw.githubusercontent.com/lmf12/MFPaintView/master/image1.jpg)

#### 2. 当夹角过小时，贝塞尔曲线转角不平滑
使用贝塞尔曲线来绘制线条会带来额外的问题，即当起始点、控制点、结束点三点构成的角度过小时，在曲线的转角处会出现平角，如下图所示。此时path的JoinStyle并不起作用，因此在连线时进行角度判定，若角度过小，则直接采取线段连接的方式，这样能保证拐角的平滑。
![](https://raw.githubusercontent.com/lmf12/MFPaintView/master/image2.jpg)

#### 3. 有效减少CPU和内存的占用
###### 1. 将全局刷新改为局部刷新
每当手指移动，产生新的触摸点时，画布需要进行重绘。若此时画布很大，而需要刷新的区域很小，则会造成不必要的浪费。因此在刷新前先计算出需要刷新的区域，然后只刷新对应区域。
###### 2. 每次绘画避免重新绘制所有路径
为了实现撤销和重做功能，必须将每一条路径的信息都记录下来。随着绘画的进行，路径的数目会越来越多。若每次重绘，都将路径一条条重新绘制，则到最后，CPU的占用率肯定会到达100%，绘画肯定会产生卡顿。这里的做法是每次画完一条路径，都生成当前结果的image，下次重绘时，则先绘制image，再绘画路径。则保证在绘画时，最多只会重新绘制一个image和一条路径，这样能大大减少CPU的消耗。
