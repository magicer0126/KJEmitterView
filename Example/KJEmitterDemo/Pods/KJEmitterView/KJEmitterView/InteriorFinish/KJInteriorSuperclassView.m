//
//  KJInteriorSuperclassView.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/28.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "KJInteriorSuperclassView.h"

@interface KJInteriorSuperclassView ()
@property(nonatomic,assign) NSInteger limitTwice;/// 限制点击调用两次处理
@property(nonatomic,assign) CGPoint startPoint;
@property(nonatomic,assign) CGFloat minLen;
@property(nonatomic,assign) BOOL openMaxRegion;
@property(nonatomic,readwrite,copy) kInteriorPerspectiveBlock xxblock;
@property(nonatomic,readwrite,copy) kInteriorDatasInfoBlock chartblock;
@property(nonatomic,readwrite,copy) kLongPressResponseBlock responseblock;
@end
@implementation KJInteriorSuperclassView
#pragma mark - 手势响应区域处理
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event{
//    /// 解决调用两次处理
//    if (++self.limitTwice % 2 == 0) {}
    /// 判断能不能接收触摸事件
    if (self.userInteractionEnabled == NO || self.hidden == YES || self.alpha < 0.01) return nil;
    /// 判断是否触发的是自己内部的view
    NSInteger count = self.subviews.count;
    for (int i = 0; i < count; i++){
        UIView *childView = self.subviews[count - 1 - i];
        CGPoint childPoint = [self convertPoint:point toView:childView];
        UIView *view = [childView hitTest:childPoint withEvent:event];
        if (view) return view;
    }
    /// 判断触摸点手势是否需要被使用
    bool boo = [self kj_gestureIsUsedWithPoint:point];
    if (boo == false) return nil;
    return self;
}
/// 判断触摸点手势是否需要被使用
- (bool)kj_gestureIsUsedWithPoint:(CGPoint)point{
    if (self.vesselSuperview) {
        point = [self convertPoint:point toView:self.vesselSuperview];
    }else{
        /// 将屏幕上的点转换到视图上对应的点
        UIWindow *window = [UIApplication sharedApplication].delegate.window;
        point = [self convertPoint:point toView:window];
    }
    /// 处理是否在可见选区区域
    return [_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.outsidePath];
}
#pragma mark - 初始化方法
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points ExtendParameterBlock:(void(^)(KJInteriorSuperclassView *obj))block{
    if (self == [super init]) {
        self.backgroundColor = UIColor.clearColor;
        self.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        static CGFloat scale;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            scale = [UIScreen mainScreen].scale;
        });
        self.layer.contentsScale = scale;
        self.testPattern = false;
        self.minLen = 1.0;
        self.dashPatternColor = UIColor.blackColor;
        self.dashPatternWidth = 1.;
        self.openMaxRegion = YES;
        /// 过滤水平线和竖直线
        KJKnownPoints tempPoints = points;
        if (points.PointA.x == points.PointB.x) tempPoints.PointA.x += 0.01;
        if (points.PointC.x == points.PointD.x) tempPoints.PointD.x += 0.02;
        if (points.PointA.y == points.PointD.y) tempPoints.PointA.y += 0.01;
        if (points.PointB.y == points.PointC.y) tempPoints.PointC.y -= 0.01;
        self.knownPoints = tempPoints;
        self.maxKnownRect = [_KJIFinishTools kj_rectWithPoints:points];
        self.userInteractionEnabled = YES;
        /// 添加移动手势
        [self addGestureRecognizer:({
            UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(kInteriorSuperclassViewMove:)];
            gesture;
        })];
        /// 添加长按删除手势
        [self addGestureRecognizer:({
            UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(kInteriorSuperclassViewLongPress:)];
            longPress.minimumPressDuration = 1.;
            longPress;
        })];
        /// 脚线添加点击手势
        if ([NSStringFromClass([self class]) isEqualToString:@"KJSkirtingLineView"]) {
            [self addGestureRecognizer:({
                UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(kInteriorSuperclassViewTap:)];
                gesture.numberOfTapsRequired = 1;
                gesture;
            })];
        }
        /// 扩展参数回调处理
        if (block) block(self);
    }
    return self;
}
/// 改变KnownPoints的已知四点的相关操作
- (void)kj_changeKnownPoints:(KJKnownPoints)points{
    self.knownPoints = points;
    self.maxKnownRect = [_KJIFinishTools kj_rectWithPoints:points];
    
}
/// 贴图并且固定图片到相应区域 -- 回调透视图片处理
- (bool)kj_chartletAndFixationWithMaterialImage:(UIImage*)materialImage Point:(CGPoint)point PerspectiveBlock:(UIImage *(^)(KJKnownPoints points,UIImage *image))block{
    return false;
}
/// 调用存储处理的回调
- (void)kj_saveToFmdbBlock{
    if (self.chartblock) {
        KJInteriorSaveDatasInfo *info = [self kj_getSaveDatasInfo];
        self.chartblock(info);
    }
}
/// 重置
- (void)kj_clearLayers{
    /// 子类实现处理
}
#pragma mark - 手势处理
- (void)kInteriorSuperclassViewTap:(UITapGestureRecognizer*)gesture{
    CGPoint tempPoint = [gesture locationInView:gesture.view];
    [self kj_tapWithPoint:tempPoint];
}
/// 移动处理
- (void)kInteriorSuperclassViewMove:(UIPanGestureRecognizer*)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.startPoint = [gesture locationInView:gesture.view];
        [self kj_moveWithStartPoint:_startPoint];
    }else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint movePoint = [gesture locationInView:gesture.view];
        if (self.openMaxRegion) {
            /// 判断是否超出区域
            if (![_KJIFinishTools kj_confirmCurrentPointWithPoint:movePoint KnownPoints:self.knownPoints]) return;
        }
        if (fabs(movePoint.x) >= self.minLen || fabs(movePoint.y) >= self.minLen) {
            CGPoint tempPoint = [gesture locationInView:gesture.view];
            [self kj_moveWithChangePoint:tempPoint];
        }
    }else if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateFailed) {
        [self kj_moveWithEndPoint:[gesture locationInView:gesture.view]];
    }
}
/// 长按处理
- (void)kInteriorSuperclassViewLongPress:(UILongPressGestureRecognizer*)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (self.responseblock && self.responseblock([gesture locationInView:gesture.view])) {
            KJInteriorSaveDatasInfo *info = [self kj_getSaveDatasInfo];
            [self kj_longPressDelPoint:[gesture locationInView:gesture.view] SaveDatasInfo:info];
        }
    }
}
#pragma mark - 子类处理
/// 点击处理
- (void)kj_tapWithPoint:(CGPoint)tempPoint{ }
/// 开始触摸的点
- (void)kj_moveWithStartPoint:(CGPoint)tempPoint{ }
/// 移动处理
- (void)kj_moveWithChangePoint:(CGPoint)tempPoint{ }
/// 移动结束
- (void)kj_moveWithEndPoint:(CGPoint)tempPoint{ }
/// 长按删除处理
- (void)kj_longPressDelPoint:(CGPoint)tempPoint SaveDatasInfo:(KJInteriorSaveDatasInfo*)info{ }
#pragma mark - 数据存储处理
/// 加载数据库数据
- (void)kj_loadFmdbDatasInfoWithSaveDatasInfo:(KJInteriorSaveDatasInfo*)info{
    [self kj_setSaveDatasInfos:info PerspectiveBlock:self.xxblock];
}
/// 获取到存储数据
- (void)kj_setSaveDatasInfos:(KJInteriorSaveDatasInfo*)info PerspectiveBlock:(kInteriorPerspectiveBlock)block{
    /// 子类实现具体操作流程
}
/// 子类传递数据至父类
- (KJInteriorSaveDatasInfo*)kj_getSaveDatasInfo{
    /// 子类实现数据传输
    return nil;
}
#pragma mark - geter/seter
/// 调试模式
@synthesize testPattern = _testPattern;
- (void)setTestPattern:(bool)testPattern{
    _testPattern = testPattern;
    if (testPattern) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.fillColor = [UIColor.redColor colorWithAlphaComponent:0.5].CGColor;
        shapeLayer.strokeColor = UIColor.blueColor.CGColor;
        shapeLayer.lineWidth = 2;
        shapeLayer.lineJoin = kCALineJoinRound;// 连接节点样式
        shapeLayer.lineCap = kCALineCapRound;// 线头样式
        [self.layer addSublayer:shapeLayer];
        shapeLayer.path = ({
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:self.knownPoints.PointA];
            [path addLineToPoint:self.knownPoints.PointB];
            [path addLineToPoint:self.knownPoints.PointC];
            [path addLineToPoint:self.knownPoints.PointD];
            [path closePath]; /// 闭合路径
            path.CGPath;
        });
    }
}
#pragma mark - ExtendParameterBlock 扩展参数
- (KJInteriorSuperclassView *(^)(NSInteger))kViewTag {
    return ^(NSInteger tag){
        self.tag = tag;
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(UIView*))kAddView {
    return ^(UIView *superView){
        [superView addSubview:self];
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(UIBezierPath*))kOutsidePath {
    return ^(UIBezierPath *path) {
        self.outsidePath = path;
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(UIColor *))kBackgroundColor {
    return ^(UIColor *color) {
        self.backgroundColor = color;
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(CGFloat))kMinLenght {
    return ^(CGFloat a){
        self.minLen = a;
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(BOOL))kUseOpenCV {
    return ^(BOOL a){
        self.opencv = a;
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(BOOL))kOpenMaxRegion {
    return ^(BOOL a){
        self.openMaxRegion = a;
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(kInteriorPerspectiveBlock))kGetInfosPerspectiveBlock {
    return ^(kInteriorPerspectiveBlock block){
        self.xxblock = block;
        return self;
    };
}
/// 长按删除响应回调处理
- (KJInteriorSuperclassView *(^)(kInteriorDatasInfoBlock))kLongPressDelBlock {
    return ^(kInteriorDatasInfoBlock block){
        self.longblock = block;
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(kInteriorDatasInfoBlock))kChartletImageBlock {
    return ^(kInteriorDatasInfoBlock block){
        self.chartblock = block;
        return self;
    };
}
- (KJInteriorSuperclassView *(^)(kLongPressResponseBlock))kLongPressResponseBlock {
    return ^(kLongPressResponseBlock block){
        self.responseblock = block;
        return self;
    };
}

@end
