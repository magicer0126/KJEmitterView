//
//  KJDecorateBoxView.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/28.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "KJDecorateBoxView.h"
/// 装饰类
@interface KJDecorateView : UIImageView
@property(nonatomic,strong) UIBezierPath *outsidePath;/// 外界选区的路径
@property(nonatomic,assign) KJKnownPoints childPoints;
@property(nonatomic,strong) CAShapeLayer *dashPatternLayer; /// 虚线选区
@property(nonatomic,strong) UIImage *materialImage; /// 原始素材图
@property(nonatomic,readwrite,copy) void (^kBlockageMoveBlcok)(CGPoint translation,KJDecorateView *decorateView,UIView *blockageView); /// 小方块移动处理
@property(nonatomic,readwrite,copy) void (^kDecorateMoveBlcok)(CGPoint translation,KJDecorateView *decorateView); /// KJDecorateView移动处理
@property(nonatomic,readwrite,copy) void (^kMoveEndBlcok)(KJDecorateView *decorateView); /// 移动结束
- (instancetype)initWithKnownPoints:(KJKnownPoints)points SuperView:(UIView*)superView;
@end
@interface KJDecorateBoxView ()
@property(nonatomic,assign) KJSlideDirectionType directionType; /// 选区滑动方向
@property(nonatomic,strong) CAShapeLayer *topLayer; /// 虚线选区
@property(nonatomic,assign) KJKnownPoints drawPoints;/// 拖动形成的四点区域
@property(nonatomic,assign) CGPoint touchBeginPoint;/// 记录开始移动触摸的点
@property(nonatomic,strong) NSMutableArray<KJDecorateView*>*temps; /// 存储装饰容器
@end

@implementation KJDecorateBoxView
#pragma mark - super method
/// 判断触摸点手势是否需要被使用
- (bool)kj_gestureIsUsedWithPoint:(CGPoint)point{
    if (_openDrawDecorateBox) {
        return [super kj_gestureIsUsedWithPoint:point];
    }
    return false;
}
/// 初始化
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points ExtendParameterBlock:(void (^ _Nullable)(KJInteriorSuperclassView * _Nonnull))block{
    if (self==[super kj_initWithKnownPoints:points ExtendParameterBlock:block]) {
        
    }
    return self;
}
/// 改变KnownPoints的已知四点的相关操作
- (void)kj_changeKnownPoints:(KJKnownPoints)points{
    [super kj_changeKnownPoints:points];
    
}
/// 获取到存储数据
- (void)kj_setSaveDatasInfos:(KJInteriorSaveDatasInfo*)info PerspectiveBlock:(kInteriorPerspectiveBlock)block{
    [self.temps removeAllObjects];
    for (KJDecorateBoxInfo *dbInfo in info.decorateBoxInfoTemps) {
        UIImage *materialImage = [_KJIFinishTools kj_getImageWithType:dbInfo.imageGetModeType ImageName:dbInfo.imageName];
        materialImage.kj_imageName = dbInfo.imageName;
        materialImage.kj_imageGetModeType = dbInfo.imageGetModeType;
        self.drawPoints = (KJKnownPoints){CGPointFromString(dbInfo.pointA),CGPointFromString(dbInfo.pointB),CGPointFromString(dbInfo.pointC),CGPointFromString(dbInfo.pointD)};
        KJDecorateView *decorateView = [self kj_createDecorateViewWithMaterialImage:materialImage PerspectiveImage:block(self.drawPoints,materialImage)];
        [self.temps addObject:decorateView];
    }
}
/// 子类传递数据至父类
- (KJInteriorSaveDatasInfo*)kj_getSaveDatasInfo{
    NSMutableArray<KJDecorateBoxInfo*>*temp = [NSMutableArray array];
    for (KJDecorateView *view in self.temps) {
        if (view.materialImage) {
            KJDecorateBoxInfo *info = [KJDecorateBoxInfo new];
            info.pointA = NSStringFromCGPoint(view.childPoints.PointA);
            info.pointB = NSStringFromCGPoint(view.childPoints.PointB);
            info.pointC = NSStringFromCGPoint(view.childPoints.PointC);
            info.pointD = NSStringFromCGPoint(view.childPoints.PointD);
            info.imageName = view.materialImage.kj_imageName;
            info.imageGetModeType = view.materialImage.kj_imageGetModeType;
            [temp addObject:info];
        }
    }
    KJInteriorSaveDatasInfo *info = [KJInteriorSaveDatasInfo new];
    info.decorateBoxInfoTemps = temp.mutableCopy;
    temp = nil;
    return info;
}
#pragma mark - publick method
/// 贴图并且固定装饰品
- (bool)kj_chartletAndFixationWithMaterialImage:(UIImage*)materialImage Point:(CGPoint)point PerspectiveBlock:(UIImage *(^)(KJKnownPoints points,UIImage *materialImage))block{
    __weak typeof(self) weakself = self;
    /// 判断当前是否有虚线区域，优先满足是否拖动到正确虚线区域
    if (_topLayer) {
        if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.drawPoints]) {
            if (block) {
                KJDecorateView *decorateView = [self kj_createDecorateViewWithMaterialImage:materialImage PerspectiveImage:block(self.drawPoints,materialImage)];
                [self.temps addObject:decorateView]; /// 存入容器
                [self kj_setNull]; /// 置空处理
                /// 调用父类的数据存储处理
                [super kj_saveToFmdbBlock];
            }
            return true;
        }else{
            return false;
        }
    }
    /// 判断是否在已存在的装饰区域
    __block bool boo = false;
    [self.subviews enumerateObjectsUsingBlock:^(KJDecorateView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGPoint childPoint = [weakself convertPoint:point toView:obj];
        BOOL result = [obj.layer containsPoint:childPoint];
        if (result) {
            obj.materialImage = materialImage;
            obj.image = block(obj.childPoints,materialImage);/// 获取到透视好的素材图
            boo = true;
            *stop = YES;
            /// 调用父类的数据存储处理
            [super kj_saveToFmdbBlock];
        }
    }];
    return boo;
}
#pragma mark - private method
/// 创建壁画view
- (KJDecorateView*)kj_createDecorateViewWithMaterialImage:(UIImage*)materialImage PerspectiveImage:(UIImage*)perspectiveImage{
    __weak typeof(self) weakself = self;
    KJDecorateView *view = [[KJDecorateView alloc]initWithKnownPoints:self.drawPoints SuperView:self];
    view.outsidePath = self.outsidePath;
    view.materialImage = materialImage;
    view.image = perspectiveImage;/// 获取到透视好的素材图
//    /// 平移处理
//    view.kDecorateMoveBlcok = ^(CGPoint translation,KJDecorateView *decorateView) {
//        weakself.drawPoints = [weakself kj_changePointsWithKnownPoints:decorateView.points Translation:translation];
//        SEL selector = NSSelectorFromString(@"kj_changeBlockagePoints:");
//        IMP imp = [decorateView methodForSelector:selector];
//        void (*func)(id, SEL, KJKnownPoints) = (void *)imp;
//        func(decorateView, selector, weakself.drawPoints);
//        if (weakself.kPerspectiveBlock) {
//            decorateView.image = weakself.kPerspectiveBlock(weakself.drawPoints,decorateView.materialImage);
//        }
//    };
    /// 小方块改变大小处理
    __block KJKnownPoints tempPoints = weakself.drawPoints;
    view.kBlockageMoveBlcok = ^(CGPoint translation,KJDecorateView *decorateView,UIView *blockageView) {
        CGPoint pt = CGPointZero;
        KJSlideDirectionType directionType = KJSlideDirectionTypeLeftBottom;
        if (blockageView.tag == 100) {/// 左上角
            weakself.touchBeginPoint = decorateView.childPoints.PointC;
            pt = decorateView.childPoints.PointA;
            directionType = KJSlideDirectionTypeRightTop;
        }else if (blockageView.tag == 101) {/// 左下角
            weakself.touchBeginPoint = decorateView.childPoints.PointD;
            pt = decorateView.childPoints.PointB;
            directionType = KJSlideDirectionTypeRightBottom;
        }else if (blockageView.tag == 102) {/// 右下角
            weakself.touchBeginPoint = decorateView.childPoints.PointA;
            pt = decorateView.childPoints.PointC;
            directionType = KJSlideDirectionTypeLeftBottom;
        }else if (blockageView.tag == 103) {/// 右上角
            weakself.touchBeginPoint = decorateView.childPoints.PointB;
            pt = decorateView.childPoints.PointD;
            directionType = KJSlideDirectionTypeLeftTop;
        }
        pt.x += translation.x;pt.y += translation.y;
        tempPoints = [weakself kj_pointsWithTempPoint:pt DirectionType:directionType];
        SEL selector = NSSelectorFromString(@"kj_changeBlockagePoints:");
        IMP imp = [decorateView methodForSelector:selector];
        void (*func)(id, SEL, KJKnownPoints) = (void*)imp;
        func(decorateView, selector, tempPoints);
        if (weakself.kPerspectiveBlock) {
            decorateView.image = weakself.kPerspectiveBlock(tempPoints,decorateView.materialImage);
        }
    };
    view.kMoveEndBlcok = ^(KJDecorateView *decorateView){
        decorateView.childPoints = tempPoints;
        /// 调用父类的数据存储处理
        [super kj_saveToFmdbBlock];
    };
    return view;
}
/// 置空处理
- (void)kj_setNull{
    self.drawPoints = (KJKnownPoints){CGPointZero,CGPointZero,CGPointZero,CGPointZero};
    [self.topLayer removeFromSuperlayer];
    _topLayer = nil;
}
/// 平移之后透视点相对处理
- (KJKnownPoints)kj_changePointsWithKnownPoints:(KJKnownPoints)points Translation:(CGPoint)translation{
    CGPoint A = points.PointA;
    CGPoint B = points.PointB;
    CGPoint C = points.PointC;
    CGPoint D = points.PointD;
    A.x += translation.x;
    A.y += translation.y;
    B.x += translation.x;
    B.y += translation.y;
    C.x += translation.x;
    C.y += translation.y;
    D.x += translation.x;
    D.y += translation.y;
    return (KJKnownPoints){A,B,C,D};
}
#pragma mark - geter/seter
- (NSMutableArray<KJDecorateView*>*)temps{
    if (!_temps) {
        _temps = [NSMutableArray array];
    }
    return _temps;
}
- (CAShapeLayer*)topLayer{
    if (!_topLayer) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.fillColor = [UIColor.redColor colorWithAlphaComponent:0.0].CGColor;
        shapeLayer.strokeColor = self.dashPatternColor.CGColor;
        shapeLayer.lineWidth = self.dashPatternWidth;
        shapeLayer.lineCap = kCALineCapButt;
        shapeLayer.lineDashPattern = @[@(5),@(5)];
        shapeLayer.fillRule = kCAFillRuleEvenOdd;
        shapeLayer.lineJoin = kCALineJoinRound;
        shapeLayer.lineCap = kCALineCapRound;
        _topLayer = shapeLayer;
        [self.layer addSublayer:_topLayer];
    }
    return _topLayer;
}
@synthesize dashPatternColor = _dashPatternColor;
@synthesize dashPatternWidth = _dashPatternWidth;
- (void)setDashPatternColor:(UIColor*)dashPatternColor{
    _dashPatternColor = dashPatternColor;
    if (_topLayer) _topLayer.strokeColor = dashPatternColor.CGColor;
}
- (void)setDashPatternWidth:(CGFloat)dashPatternWidth{
    _dashPatternWidth = dashPatternWidth;
    if (_topLayer) _topLayer.lineWidth = dashPatternWidth;
}
- (void)setOpenDrawDecorateBox:(bool)openDrawDecorateBox{
    _openDrawDecorateBox = openDrawDecorateBox;
    if (openDrawDecorateBox == false) {
        [self kj_setNull];
        /// 打开容器子类里面的手势操作
        [self.subviews enumerateObjectsUsingBlock:^(KJDecorateView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.userInteractionEnabled = YES;
        }];
    }else{
        [self.subviews enumerateObjectsUsingBlock:^(KJDecorateView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.userInteractionEnabled = NO;
        }];
    }
}
#pragma mark - touches
/// 开始触摸的点
- (void)kj_moveWithStartPoint:(CGPoint)tempPoint{
    self.touchBeginPoint = tempPoint;
}
/// 移动处理
- (void)kj_moveWithChangePoint:(CGPoint)tempPoint{
    if (_openDrawDecorateBox == false) return;
    [self kj_delSlideAreaWithTempPoint:tempPoint];
}
/// 移动结束
- (void)kj_moveWithEndPoint:(CGPoint)tempPoint{
    
}
/// 处理滑动形成的四边形区域
- (void)kj_delSlideAreaWithTempPoint:(CGPoint)tempPoint{
    /// 确定滑动方向
    KJSlideDirectionType directionType = [_KJIFinishTools kj_slideDirectionWithPoint:self.touchBeginPoint Point2:tempPoint];
    self.drawPoints = [self kj_pointsWithTempPoint:tempPoint DirectionType:directionType];
    self.topLayer.path = ({
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:self.drawPoints.PointA];
        [path addLineToPoint:self.drawPoints.PointB];
        [path addLineToPoint:self.drawPoints.PointC];
        [path addLineToPoint:self.drawPoints.PointD];
        [path closePath];
        path.CGPath;
    });
}
- (KJKnownPoints)kj_pointsWithTempPoint:(CGPoint)tempPoint DirectionType:(KJSlideDirectionType)directionType{
    CGPoint A = self.knownPoints.PointA;
    CGPoint B = self.knownPoints.PointB;
    CGPoint C = self.knownPoints.PointC;
    CGPoint D = self.knownPoints.PointD;
    CGPoint E = self.touchBeginPoint;
    CGPoint F = CGPointZero;
    CGPoint G = tempPoint;
    CGPoint H = CGPointZero;
    CGPoint O1 = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:A Point2:B Point3:C Point4:D];/// AB和CD交点
    CGPoint O2 = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:A Point2:D Point3:C Point4:B];/// AD和CB交点
    /// 重合或者平行
    if (CGPointEqualToPoint(CGPointZero,O1) && CGPointEqualToPoint(CGPointZero,O2)) {
        CGPoint M = [_KJIFinishTools kj_parallelLineDotsWithPoint1:A Point2:B Point3:E];
        CGPoint N = [_KJIFinishTools kj_parallelLineDotsWithPoint1:C Point2:D Point3:G];
        CGPoint J = [_KJIFinishTools kj_parallelLineDotsWithPoint1:B Point2:C Point3:G];
        CGPoint K = [_KJIFinishTools kj_parallelLineDotsWithPoint1:A Point2:D Point3:E];
        F = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:E Point2:M Point3:J Point4:G];
        H = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:G Point2:N Point3:K Point4:E];
    }else if (CGPointEqualToPoint(CGPointZero,O1)) {
        CGPoint M = [_KJIFinishTools kj_parallelLineDotsWithPoint1:A Point2:B Point3:E];
        CGPoint N = [_KJIFinishTools kj_parallelLineDotsWithPoint1:C Point2:D Point3:G];
        F = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:E Point2:M Point3:O2 Point4:G];
        H = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:G Point2:N Point3:O2 Point4:E];
    }else if (CGPointEqualToPoint(CGPointZero,O2)) {
        CGPoint M = [_KJIFinishTools kj_parallelLineDotsWithPoint1:B Point2:C Point3:G];
        CGPoint N = [_KJIFinishTools kj_parallelLineDotsWithPoint1:A Point2:D Point3:E];
        F = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:E Point2:O1 Point3:M Point4:G];
        H = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:G Point2:O1 Point3:N Point4:E];
    }else{
        F = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:E Point2:O1 Point3:O2 Point4:G];
        H = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:G Point2:O1 Point3:O2 Point4:E];
    }
    KJKnownPoints points = (KJKnownPoints){E,F,G,H}; /// 左下滑动
    if (directionType == KJSlideDirectionTypeRightBottom) { /// 右下滑动
        points = (KJKnownPoints){H,G,F,E};
    }else if (directionType == KJSlideDirectionTypeLeftTop) { /// 左上滑动
        points = (KJKnownPoints){F,E,H,G};
    }else if (directionType == KJSlideDirectionTypeRightTop) { /// 右上滑动
        points = (KJKnownPoints){G,H,E,F};
    }
    return points;
}
/// 长按删除处理
- (void)kj_longPressDelPoint:(CGPoint)tempPoint SaveDatasInfo:(KJInteriorSaveDatasInfo*)info{
    NSMutableArray *temp = [NSMutableArray arrayWithArray:info.decorateBoxInfoTemps];
    __weak typeof(self) weakself = self;
    [self.temps enumerateObjectsUsingBlock:^(KJDecorateView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:obj.childPoints]) {
            [temp removeObjectAtIndex:idx];
            [weakself.temps removeObjectAtIndex:idx];
            [obj removeFromSuperview];
            *stop = YES;
        }
    }];
    info.decorateBoxInfoTemps = temp.mutableCopy;
    temp = nil;
    if (self.longblock) self.longblock(info);
}
@end



@implementation KJDecorateView
- (instancetype)initWithKnownPoints:(KJKnownPoints)points SuperView:(UIView*)superView{
    if (self==[super init]) {
        self.frame = CGRectMake(0, 0, ksw, ksh);
        [superView addSubview:self];
        self.childPoints = points;
        self.backgroundColor = [UIColor.yellowColor colorWithAlphaComponent:0.];
        self.userInteractionEnabled = NO;
//        [self addGestureRecognizer:({
//            UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(kj_panMove:)];
//            gesture.delegate = self;
//            gesture;
//        })];
        [self addGestureRecognizer:({
            UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(kj_panTap:)];
            gesture.numberOfTapsRequired = 1;
            gesture;
        })];
        /// 添加4个小正方形
        for (NSInteger i=0; i<4; i++) {
            UIView *view = [UIView new];
            view.backgroundColor = UIColor.blueColor;
            view.hidden = YES;
            view.tag = 100 + i;
            [self addSubview:view];
            /// 添加移动手势
            view.userInteractionEnabled = YES;
            [view addGestureRecognizer:({
                UIPanGestureRecognizer *gesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(kj_blockageMove:)];
                gesture;
            })];
        }
        [self kj_changeBlockagePoints:points];
    }
    return self;
}
/// 改变小方块位置和KJDecorateView尺寸
- (void)kj_changeBlockagePoints:(KJKnownPoints)points{
//    self.frame = [_KJIFinishTools kj_rectWithPoints:points];
    KJKnownPoints tempPoints = points;
//    tempPoints.PointA = [self.superview convertPoint:tempPoints.PointA toView:self];
//    tempPoints.PointB = [self.superview convertPoint:tempPoints.PointB toView:self];
//    tempPoints.PointC = [self.superview convertPoint:tempPoints.PointC toView:self];
//    tempPoints.PointD = [self.superview convertPoint:tempPoints.PointD toView:self];
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.tag == 100) {/// 左上角
            obj.frame = CGRectMake(tempPoints.PointA.x - 10, tempPoints.PointA.y - 10, 20, 20);
        }else if (obj.tag == 101) {/// 左下角
            obj.frame = CGRectMake(tempPoints.PointB.x - 10, tempPoints.PointB.y - 10, 20, 20);
        }else if (obj.tag == 102) {/// 右下角
            obj.frame = CGRectMake(tempPoints.PointC.x - 10, tempPoints.PointC.y - 10, 20, 20);
        }else if (obj.tag == 103) {/// 右上角
            obj.frame = CGRectMake(tempPoints.PointD.x - 10, tempPoints.PointD.y - 10, 20, 20);
        }
    }];
    self.dashPatternLayer.path = ({
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:tempPoints.PointA];
        [path addLineToPoint:tempPoints.PointD];
        [path addLineToPoint:tempPoints.PointC];
        [path addLineToPoint:tempPoints.PointB];
        [path closePath];
        path.CGPath;
    });
}
#pragma mark - 点击域处理
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event{
    /// 如果不能接收触摸事件，直接返回nil
    if (self.userInteractionEnabled == NO || self.hidden == YES || self.alpha < 0.01) return nil;
    /// 判断是否触发的是自己内部的view
    NSInteger count = self.subviews.count;
    for (NSInteger i=count-1; i>=0; i--) {
        UIView *childView = self.subviews[i];
        CGPoint childPoint = [self convertPoint:point toView:childView];
        UIView *view = [childView hitTest:childPoint withEvent:event];
        if (view) return view;
    }
    /// 判断触摸点手势是否需要被使用
    point = [self convertPoint:point toView:self.superview];
    bool boo = [_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:({
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:_childPoints.PointA];
        [path addLineToPoint:_childPoints.PointD];
        [path addLineToPoint:_childPoints.PointC];
        [path addLineToPoint:_childPoints.PointB];
        [path closePath];
        path;
    })];
    if (boo == false) return nil;
    return self;
//    /// 扩大触发范围
//    CGRect rect = self.bounds;
//    return CGRectContainsPoint(rect, point) ? self : nil;
}
#pragma mark - geter/seter
- (CAShapeLayer*)dashPatternLayer{
    if (!_dashPatternLayer) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.fillColor = [UIColor.redColor colorWithAlphaComponent:0.0].CGColor;
        shapeLayer.strokeColor = UIColor.blueColor.CGColor;
        shapeLayer.lineWidth = 1.5;
        shapeLayer.lineCap = kCALineCapButt;
        shapeLayer.lineDashPattern = @[@(5),@(5)];
        shapeLayer.fillRule = kCAFillRuleEvenOdd;
        shapeLayer.lineJoin = kCALineJoinRound;
        shapeLayer.lineCap = kCALineCapRound;
        shapeLayer.hidden = YES;
        shapeLayer.path = ({
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:_childPoints.PointA];
            [path addLineToPoint:_childPoints.PointD];
            [path addLineToPoint:_childPoints.PointC];
            [path addLineToPoint:_childPoints.PointB];
            [path closePath];
            path.CGPath;
        });
        _dashPatternLayer = shapeLayer;
        [self.layer addSublayer:_dashPatternLayer];
    }
    return _dashPatternLayer;
}
#pragma mark - 手势处理
- (void)kj_panTap:(UITapGestureRecognizer*)gesture{
    CGPoint tempPoint = [gesture locationInView:gesture.view];
    tempPoint = [self convertPoint:tempPoint toView:self.superview];
    UIBezierPath *path = ({
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:_childPoints.PointA];
        [path addLineToPoint:_childPoints.PointD];
        [path addLineToPoint:_childPoints.PointC];
        [path addLineToPoint:_childPoints.PointB];
        [path closePath];
        path;
    });
    if (![_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint BezierPath:path] ) {
        return;
    }
    __block bool state = true;
    if (self.dashPatternLayer.hidden) {
        state = false;
    }
    self.dashPatternLayer.hidden = state;
    [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.tag == 100 || obj.tag == 101 || obj.tag == 102 || obj.tag == 103) {
            obj.hidden = state;
        }
    }];
}
- (void)kj_panMove:(UIPanGestureRecognizer*)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
    }else if (gesture.state == UIGestureRecognizerStateChanged) {
        !self.kDecorateMoveBlcok?:self.kDecorateMoveBlcok([gesture translationInView:self],self);
    }else if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateFailed) {
        !self.kMoveEndBlcok?:self.kMoveEndBlcok(self);
    }
}
/// 小方块移动处理
- (void)kj_blockageMove:(UIPanGestureRecognizer*)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        
    }else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint tempPoint = [gesture locationInView:self];
        tempPoint = [self convertPoint:tempPoint toView:self.superview];
        if (![_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint BezierPath:self.outsidePath]) return;
        !self.kBlockageMoveBlcok?:self.kBlockageMoveBlcok([gesture translationInView:gesture.view],self,gesture.view);
    }else if (gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateFailed) {
        !self.kMoveEndBlcok?:self.kMoveEndBlcok(self);
    }
}
@end
