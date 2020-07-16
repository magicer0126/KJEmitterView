//
//  KJSuspendedView.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/13.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "KJSuspendedView.h"
@interface KJSuspendedModel : NSObject
@property(nonatomic,assign) NSInteger sixMark;/// 对应的六个面  上：0 下：1 左：2 右：3 前：4 后：5
@property(nonatomic,assign) KJKnownPoints points;
@property(nonatomic,strong) UIBezierPath *path;/// 路径
@property(nonatomic,assign) CGRect imageRect;
@property(nonatomic,strong) UIImage *materialImage;/// 素材图
@property(nonatomic,strong) UIImage *perspectiveImage;/// 透视好的素材图
@property(nonatomic,assign) bool chartletComplete;/// 是否贴图
@property(nonatomic,strong) UIColor *coverColor;/// 未贴图时候选区颜色
@end

@interface KJSuspendedView ()
@property(nonatomic,assign) KJKnownPoints topPoints,botPoints;
@property(nonatomic,assign) CGFloat lineLenght; /// 线条长度
@property(nonatomic,assign) CGFloat ovalLen; /// 椭圆上下方向处理
@property(nonatomic,strong) CAShapeLayer *topLayer; /// 虚线选区
@property(nonatomic,assign) CGPoint touchBeginPoint; /// 记录touch开始的点
@property(nonatomic,assign) BOOL drawTop; /// 是否绘制顶部选区
@property(nonatomic,assign) BOOL drawLine; /// 是否拖拽形成凹凸部分
@property(nonatomic,assign) BOOL clearDarw;/// 清除画布内容开关
@property(nonatomic,assign) BOOL fmdbDatas;/// 是否为数据库获取的数据
@property(nonatomic,assign) KJSlideDirectionType directionType; /// 选区滑动方向
@property(nonatomic,assign) KJConcaveConvexType concaveType; /// 凹凸方向
@property(nonatomic,strong) KJSuspendedModel *topModel;
@property(nonatomic,strong) KJSuspendedModel *botModel;
@property(nonatomic,strong) KJSuspendedModel *leftModel;
@property(nonatomic,strong) KJSuspendedModel *rightModel;
@property(nonatomic,strong) KJSuspendedModel *frontModel;
@property(nonatomic,strong) KJSuspendedModel *backModel;
@property(nonatomic,strong) NSMutableArray<KJSuspendedModel*>*temps; /// 存储装饰容器
@end

@implementation KJSuspendedView
#pragma mark - super method
/// 判断触摸点手势是否需要被使用
- (bool)kj_gestureIsUsedWithPoint:(CGPoint)point{
    if (![super kj_gestureIsUsedWithPoint:point]) {
        return false;
    }
    if (self.openDrawSuspended) {
        return true;
    }
    /// 已经绘制凹凸部分
    if (self.drawLine) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path appendPath:self.topModel.path];
        [path appendPath:self.botModel.path];
        [path appendPath:self.leftModel.path];
        [path appendPath:self.rightModel.path];
        [path appendPath:self.frontModel.path];
        [path appendPath:self.backModel.path];
        bool boo = [_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:path];/// 判断当前是否在可见区域之内
        return boo;
    }
    return false;
}
/// 重置
- (void)kj_clearLayers{
    [self kj_setNull];
    self.clearDarw = YES;
    [self setNeedsDisplay];
}
/// 初始化
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points ExtendParameterBlock:(void (^)(KJInteriorSuperclassView * _Nonnull))block{
    if (self == [super kj_initWithKnownPoints:points ExtendParameterBlock:block]) {
        self.maxLen = 100.;
        self.shapeType = KJDarwShapeTypeOval;
        [self kj_setNull];
    }
    return self;
}
/// 置空处理
- (void)kj_setNull{
    if (_topLayer) [_topLayer removeFromSuperlayer];
    self.clearDarw = NO;
    self.fmdbDatas = NO;
    self.drawTop = self.drawLine = NO;
    self.topPoints = (KJKnownPoints){CGPointZero,CGPointZero,CGPointZero,CGPointZero};
    self.botPoints = (KJKnownPoints){CGPointZero,CGPointZero,CGPointZero,CGPointZero};
    [self.temps removeAllObjects];
    self.topModel   = [self kj_initSuspendedModelWithSixMark:0];
    self.botModel   = [self kj_initSuspendedModelWithSixMark:1];
    self.leftModel  = [self kj_initSuspendedModelWithSixMark:2];
    self.rightModel = [self kj_initSuspendedModelWithSixMark:3];
    self.frontModel = [self kj_initSuspendedModelWithSixMark:4];
    self.backModel  = [self kj_initSuspendedModelWithSixMark:5];
}
/// 初始化模型
- (KJSuspendedModel*)kj_initSuspendedModelWithSixMark:(NSInteger)sixMark{
    NSArray<UIColor*>*colorTemps = @[UIColor.orangeColor,UIColor.redColor,UIColor.blueColor,
                                     UIColor.blueColor,UIColor.orangeColor,UIColor.orangeColor];
    KJSuspendedModel *model = [KJSuspendedModel new];
    model.sixMark = sixMark;
    model.coverColor = colorTemps[sixMark];
    [self.temps addObject:model];
    colorTemps = nil;
    return model;
}
/// 改变KnownPoints的已知四点的相关操作
- (void)kj_changeKnownPoints:(KJKnownPoints)points{
    [super kj_changeKnownPoints:points];
    
}
/// 获取到存储数据
- (void)kj_setSaveDatasInfos:(KJInteriorSaveDatasInfo*)info PerspectiveBlock:(kInteriorPerspectiveBlock)block{
    [self kj_setNull];
    self.fmdbDatas = YES;
    self.openDrawSuspended = NO;
    /// 1、绘制顶部区域
    self.drawTop = YES;
    self.topPoints = (KJKnownPoints){CGPointFromString(info.suspendedInfo.topA),CGPointFromString(info.suspendedInfo.topB),CGPointFromString(info.suspendedInfo.topC),CGPointFromString(info.suspendedInfo.topD)};
    self.botPoints = (KJKnownPoints){CGPointFromString(info.suspendedInfo.botA),CGPointFromString(info.suspendedInfo.botB),CGPointFromString(info.suspendedInfo.botC),CGPointFromString(info.suspendedInfo.botD)};
    self.touchBeginPoint = self.topPoints.PointA;
    [self kj_darwTopWithPoint:self.topPoints.PointC];
    self.shapeType = info.suspendedInfo.shapeType;
    self.lineLenght = info.suspendedInfo.lineLenght;
    self.ovalLen = info.suspendedInfo.ovalLen;
    self.touchBeginPoint = self.botPoints.PointA;
    if (info.suspendedInfo.shapeType == KJDarwShapeTypeOval) {
        if (_drawTop == YES) [self kj_drawOvalConcaveAndConvexWithPoint:self.botPoints.PointC];
    }else{
        if (_drawTop == YES) [self kj_drawQuadrangleConcaveAndConvexWithPoint:self.botPoints.PointC];
    }
    /// 2、绘制凹凸区域
    self.drawLine = YES;
    for (KJSuspendedFaceInfo *obj in info.suspendedInfo.suspendedFaceInfoTemps) {
        UIImage *materialImage = [_KJIFinishTools kj_getImageWithType:obj.imageGetModeType ImageName:obj.imageName];
        materialImage.kj_imageName = obj.imageName;
        materialImage.kj_imageGetModeType = obj.imageGetModeType;
        if (materialImage == nil) continue;
        if (info.suspendedInfo.shapeType == KJDarwShapeTypeOval) {
            if (obj.sixMark == 1) {
                self.botModel.materialImage = materialImage;
                self.botModel.perspectiveImage = [self kj_getBottomOvalImage];
                self.botModel.chartletComplete = true;
            }else if (obj.sixMark == 0) {
                self.topModel.materialImage = materialImage;
                self.topModel.perspectiveImage = [self kj_getTopCylinderImage];
                self.topModel.chartletComplete = true;
            }
        }else if (info.suspendedInfo.shapeType == KJDarwShapeTypeQuadrangle) {
            if (obj.sixMark == 0) {
                self.topModel.materialImage = materialImage;
                if (block) {
                    self.topModel.perspectiveImage = block(self.topModel.points,self.topModel.materialImage);
                    self.topModel.chartletComplete = true;
                }
            }else if (obj.sixMark == 1) {
                self.botModel.materialImage = materialImage;
                if (block) {
                    self.botModel.perspectiveImage = block(self.botModel.points,self.botModel.materialImage);
                    self.botModel.chartletComplete = true;
                }
            }else if (obj.sixMark == 2) {
                self.leftModel.materialImage = materialImage;
                if (block) {
                    self.leftModel.perspectiveImage = block(self.leftModel.points,self.leftModel.materialImage);
                    self.leftModel.chartletComplete = true;
                }
            }else if (obj.sixMark == 3) {
                self.rightModel.materialImage = materialImage;
                if (block) {
                    self.rightModel.perspectiveImage = block(self.rightModel.points,self.rightModel.materialImage);
                    self.rightModel.chartletComplete = true;
                }
            }else if (obj.sixMark == 4) {
                self.frontModel.materialImage = materialImage;
                if (block) {
                    self.frontModel.perspectiveImage = block(self.frontModel.points,self.frontModel.materialImage);
                    self.frontModel.chartletComplete = true;
                }
            }else if (obj.sixMark == 5) {
                self.backModel.materialImage = materialImage;
                if (block) {
                    self.backModel.perspectiveImage = block(self.backModel.points,self.backModel.materialImage);
                    self.backModel.chartletComplete = true;
                }
            }
        }
    };
    if (info.suspendedInfo.shapeType == KJDarwShapeTypeOval) {
        [self kj_drawOvalConcaveAndConvexWithPoint:self.botPoints.PointC];
    }else{
        [self kj_drawQuadrangleConcaveAndConvexWithPoint:self.botPoints.PointC];
    }
    self.fmdbDatas = NO;
}
/// 子类传递数据至父类
- (KJInteriorSaveDatasInfo*)kj_getSaveDatasInfo{
    KJSuspendedInfo *spInfo = [KJSuspendedInfo new];
    spInfo.shapeType = self.shapeType;
    spInfo.lineLenght = self.lineLenght;
    spInfo.ovalLen = self.ovalLen;
    spInfo.topA = NSStringFromCGPoint(self.topPoints.PointA);
    spInfo.topB = NSStringFromCGPoint(self.topPoints.PointB);
    spInfo.topC = NSStringFromCGPoint(self.topPoints.PointC);
    spInfo.topD = NSStringFromCGPoint(self.topPoints.PointD);
    spInfo.botA = NSStringFromCGPoint(self.botPoints.PointA);
    spInfo.botB = NSStringFromCGPoint(self.botPoints.PointB);
    spInfo.botC = NSStringFromCGPoint(self.botPoints.PointC);
    spInfo.botD = NSStringFromCGPoint(self.botPoints.PointD);
    NSMutableArray *temp = [NSMutableArray array];
    for (KJSuspendedModel *model in self.temps) {
        KJSuspendedFaceInfo *info = [KJSuspendedFaceInfo new];
        if (model.materialImage.kj_imageName) {
            info.imageName = model.materialImage.kj_imageName;
            info.imageGetModeType = model.materialImage.kj_imageGetModeType;
        }else{
            continue;
        }
        info.sixMark = model.sixMark;
        [temp addObject:info];
    }
    spInfo.suspendedFaceInfoTemps = temp.mutableCopy;
    temp = nil;
    KJInteriorSaveDatasInfo *info = [KJInteriorSaveDatasInfo new];
    info.suspendedInfo = spInfo;
    return info;
}
#pragma mark - geter/seter
- (NSMutableArray<KJSuspendedModel*>*)temps{
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
#pragma mark - publick method
/// 贴图并且固定
- (bool)kj_chartletAndFixationWithMaterialImage:(UIImage*)materialImage Point:(CGPoint)point PerspectiveBlock:(UIImage *(^)(KJKnownPoints points,UIImage *materialImage))block{
    point = [self.superview convertPoint:point toView:self];
    if (self.shapeType == KJDarwShapeTypeOval) {
        if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.botModel.path]) {
            self.botModel.materialImage = materialImage;
            self.botModel.perspectiveImage = [self kj_getBottomOvalImage];
            self.botModel.chartletComplete = true;
            [self setNeedsDisplay];
            /// 调用父类的数据存储处理
            [super kj_saveToFmdbBlock];
            return true;
        }
        if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.topModel.path]) {
            self.topModel.materialImage = materialImage;
            self.topModel.perspectiveImage = [self kj_getTopCylinderImage];
            self.topModel.chartletComplete = true;
            [self setNeedsDisplay];
            /// 调用父类的数据存储处理
            [super kj_saveToFmdbBlock];
            return true;
        }
    }else{
        NSInteger i = [self kj_Point:point];
        if (i==-1) {
            return false;
        }else if (i==0) {
            self.topModel.materialImage = materialImage;
            if (block) {
                self.topModel.perspectiveImage = block(self.topModel.points,self.topModel.materialImage);
                self.topModel.chartletComplete = true;
                [self setNeedsDisplay];
            }
        }else if (i==1) {
            self.botModel.materialImage = materialImage;
            if (block) {
                self.botModel.perspectiveImage = block(self.botModel.points,self.botModel.materialImage);
                self.botModel.chartletComplete = true;
                [self setNeedsDisplay];
            }
        }else if (i==2) {
            self.leftModel.materialImage = materialImage;
            if (block) {
                self.leftModel.perspectiveImage = block(self.leftModel.points,self.leftModel.materialImage);
                self.leftModel.chartletComplete = true;
                [self setNeedsDisplay];
            }
        }else if (i==3) {
            self.rightModel.materialImage = materialImage;
            if (block) {
                self.rightModel.perspectiveImage = block(self.rightModel.points,self.rightModel.materialImage);
                self.rightModel.chartletComplete = true;
                [self setNeedsDisplay];
            }
        }else if (i==4) {
            self.frontModel.materialImage = materialImage;
            if (block) {
                self.frontModel.perspectiveImage = block(self.frontModel.points,self.frontModel.materialImage);
                self.frontModel.chartletComplete = true;
                [self setNeedsDisplay];
            }
        }else if (i==5) {
            self.backModel.materialImage = materialImage;
            if (block) {
                self.backModel.perspectiveImage = block(self.backModel.points,self.backModel.materialImage);
                self.backModel.chartletComplete = true;
                [self setNeedsDisplay];
            }
        }
        /// 调用父类的数据存储处理
        [super kj_saveToFmdbBlock];
        return true;
    }
    return false;
}
/// 判断当前固定到哪一个面
- (NSInteger)kj_Point:(CGPoint)point{
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.frontModel.path]) {
        return 4;
    }
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.botModel.path]) {
        return 1;
    }
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.rightModel.path]) {
        return 3;
    }
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.leftModel.path]) {
        return 2;
    }
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.backModel.path]) {
        return 5;
    }
    return -1;
}
/// 获取顶部圆柱图像
- (UIImage*)kj_getTopCylinderImage{
    CGFloat w = self.topPoints.PointC.x - self.topPoints.PointA.x;
    CGFloat h = self.topPoints.PointC.y - self.topPoints.PointA.y;
    UIImage *smaleImage = [_KJIFinishTools kj_changeImageSizeWithImage:self.topModel.materialImage SimpleImageSize:CGSizeMake(w*3, self.lineLenght)];
    if (self.ovalLen<0) {
        return [_KJIFinishTools kj_orthogonImageBecomeCylinderImage:smaleImage Rect:CGRectMake(0, 0, w, h) Up:self.ovalLen<0];
    }else{
        return smaleImage;
    }
}
/// 获取底部椭圆图
- (UIImage*)kj_getBottomOvalImage{
    CGFloat w = fabs(self.botPoints.PointC.x - self.botPoints.PointA.x);
    CGFloat h = fabs(self.botPoints.PointC.y - self.botPoints.PointA.y);
    UIImage *smaleImage = [_KJIFinishTools kj_changeImageSizeWithImage:self.botModel.materialImage SimpleImageWidth:w*2];
    return [_KJIFinishTools kj_orthogonImageBecomeOvalImage:smaleImage Rect:CGRectMake(0, 0, w, h)];
}
#pragma mark - 绘图
- (void)drawRect:(CGRect)rect{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIRectFrame(self.bounds);
    CGContextSaveGState(ctx);
    if (self.clearDarw) {
        CGContextClearRect(ctx, self.bounds);//清除指定矩形区域上绘制的图形
        self.clearDarw = NO;
        return;
    }
    if (self.shapeType == KJDarwShapeTypeOval) {
        if (self.concaveType == KJConcaveConvexTypeConcave) {
            [[self kj_topPath] addClip];
        }else{
            [self kj_drawWithCtx:ctx SuspendedModel:self.topModel];
        }
        [self kj_drawWithCtx:ctx SuspendedModel:self.botModel];
    }else if (self.shapeType == KJDarwShapeTypeQuadrangle) {
        if (self.concaveType == KJConcaveConvexTypeConcave) {
            CGContextAddPath(ctx, [self kj_topPath].CGPath);
            CGContextClip(ctx);
        }
        /// 绘制顺序不可乱改
        [self kj_drawWithCtx:ctx SuspendedModel:self.backModel];
        [self kj_drawWithCtx:ctx SuspendedModel:self.leftModel];
        [self kj_drawWithCtx:ctx SuspendedModel:self.rightModel];
        [self kj_drawWithCtx:ctx SuspendedModel:self.botModel];
        [self kj_drawWithCtx:ctx SuspendedModel:self.frontModel];
    }
    CGContextRestoreGState(ctx);
}
/// 绘制相关
- (void)kj_drawWithCtx:(CGContextRef)ctx SuspendedModel:(KJSuspendedModel*)model{
    if (model.chartletComplete) {
        UIGraphicsPushContext(ctx);
        [model.perspectiveImage drawInRect:model.imageRect];
        UIGraphicsPopContext();
    }else{
        CGContextSetStrokeColorWithColor(ctx, UIColor.clearColor.CGColor);
        CGContextSetFillColorWithColor(ctx, model.coverColor.CGColor);
        CGContextAddPath(ctx, model.path.CGPath);
        CGContextDrawPath(ctx, kCGPathFillStroke);
    }
}
#pragma mark - touches
/// 开始触摸的点
- (void)kj_moveWithStartPoint:(CGPoint)tempPoint{
    self.touchBeginPoint = tempPoint;
//    if (!_drawTop) self.touchBeginPoint = tempPoint;
//    if (_drawTop == YES && _drawLine == NO) self.touchBeginPoint = tempPoint;
}
/// 移动处理
- (void)kj_moveWithChangePoint:(CGPoint)tempPoint{
    if (!_drawTop) [self kj_darwTopWithPoint:tempPoint];
    if (self.shapeType == KJDarwShapeTypeOval) {
        if (_drawTop == YES) [self kj_drawOvalConcaveAndConvexWithPoint:tempPoint];
//        if (_drawTop == YES && _drawLine == NO) [self kj_drawOvalConcaveAndConvexWithPoint:tempPoint];
    }else {
        if (_drawTop == YES) [self kj_drawQuadrangleConcaveAndConvexWithPoint:tempPoint];
//        if (_drawTop == YES && _drawLine == NO) [self kj_drawQuadrangleConcaveAndConvexWithPoint:tempPoint];
    }
}
/// 移动结束
- (void)kj_moveWithEndPoint:(CGPoint)tempPoint{
    if (_drawTop == YES && _drawLine == NO) {
        self.openDrawSuspended = NO;
        self.drawLine = YES;
    }
    self.drawTop = YES;
}
/// 长按删除处理
- (void)kj_longPressDelPoint:(CGPoint)tempPoint SaveDatasInfo:(KJInteriorSaveDatasInfo*)info{
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (KJSuspendedFaceInfo *sfInfo in info.suspendedInfo.suspendedFaceInfoTemps) {
        [path appendPath:[self kj_appendPathWithSix:sfInfo.sixMark]];
    }
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint BezierPath:path]) {
        info.suspendedInfo = nil;
        [self kj_clearLayers];
    }
    if (self.longblock) self.longblock(info);
}
- (UIBezierPath*)kj_appendPathWithSix:(NSInteger)six{
    /// 上：0 下：1 左：2 右：3 前：4 后：5
    UIBezierPath *path = nil;
    switch (six) {
        case 0:
            path = self.topModel.path;
            break;
        case 1:
            path = self.botModel.path;
            break;
        case 2:
            path = self.leftModel.path;
            break;
        case 3:
            path = self.rightModel.path;
            break;
        case 4:
            path = self.frontModel.path;
            break;
        case 5:
            path = self.backModel.path;
            break;
        default:
            break;
    }
    return path;
}
#pragma mark - 内部处理方法
/// 操作画顶部选区
- (void)kj_darwTopWithPoint:(CGPoint)tempPoint {
    /// 滑动方向
    self.directionType = [_KJIFinishTools kj_slideDirectionWithPoint:self.touchBeginPoint Point2:tempPoint];
    self.topPoints = [_KJIFinishTools kj_pointsWithKnownPoints:self.knownPoints BeginPoint:self.touchBeginPoint EndPoint:tempPoint DirectionType:self.directionType];
    self.topLayer.path = [self kj_topPath].CGPath;
}
/// 操作四边形凹凸选区
- (void)kj_drawQuadrangleConcaveAndConvexWithPoint:(CGPoint)tempPoint{
    if (self.fmdbDatas == NO) {
        CGFloat len = fabs(self.touchBeginPoint.y - tempPoint.y);/// 取绝对值
        self.lineLenght = len<self.maxLen?len:self.maxLen; /// 限制下拉距离
    }
    /// 凹凸方向
    self.concaveType = [self kj_concaveConvesTypeWithPoint:tempPoint];
    /// 获取点坐标
    self.botPoints = [self kj_bottomPoints];
    [_topLayer removeFromSuperlayer];
    _topLayer = nil;
    self.botModel.points   = (KJKnownPoints){self.botPoints.PointA,self.botPoints.PointB,self.botPoints.PointC,self.botPoints.PointD};
    self.frontModel.points = (KJKnownPoints){self.topPoints.PointA,self.botPoints.PointA,self.botPoints.PointD,self.topPoints.PointD};
    self.backModel.points  = (KJKnownPoints){self.topPoints.PointB,self.botPoints.PointB,self.botPoints.PointC,self.topPoints.PointC};
    self.leftModel.points  = (KJKnownPoints){self.topPoints.PointA,self.botPoints.PointA,self.botPoints.PointB,self.topPoints.PointB};
    self.rightModel.points = (KJKnownPoints){self.topPoints.PointD,self.botPoints.PointD,self.botPoints.PointC,self.topPoints.PointC};
    self.backModel.path  = [self kj_backPath];
    self.leftModel.path  = [self kj_leftPath];
    self.rightModel.path = [self kj_rightPath];
    self.botModel.path   = [self kj_botomPath];
    self.frontModel.path = [self kj_frontPath];
    [self setNeedsDisplay];
}
/// 操作椭圆凹凸选区
- (void)kj_drawOvalConcaveAndConvexWithPoint:(CGPoint)tempPoint{
    if (self.fmdbDatas == NO) {
        self.ovalLen = self.touchBeginPoint.y - tempPoint.y;
        CGFloat len = fabs(self.touchBeginPoint.y - tempPoint.y);/// 取绝对值
        self.lineLenght = len<self.maxLen?len:self.maxLen; /// 限制下拉距离
    }
    /// 凹凸方向
    self.concaveType = [self kj_concaveConvesTypeWithPoint:tempPoint];
    /// 获取点坐标
    CGFloat y = 0.;
    if (self.concaveType == KJConcaveConvexTypeConcave) { /// 内凹
        y = -self.lineLenght;
    }else { /// 外凸
        y = self.lineLenght;
    }
    KJKnownPoints newPoints = self.botPoints;
    newPoints.PointA = CGPointMake(self.topPoints.PointA.x, self.topPoints.PointA.y+y);
    newPoints.PointB = CGPointMake(self.topPoints.PointB.x, self.topPoints.PointB.y+y);
    newPoints.PointC = CGPointMake(self.topPoints.PointC.x, self.topPoints.PointC.y+y);
    newPoints.PointD = CGPointMake(self.topPoints.PointD.x, self.topPoints.PointD.y+y);
    self.botPoints = newPoints;
    [_topLayer removeFromSuperlayer];
    _topLayer = nil;
    if (self.concaveType == KJConcaveConvexTypeConcave) {
        self.topModel.path = [self kj_topPath];
    }else{
        CGFloat x = self.topPoints.PointA.x;
        CGFloat y = self.topPoints.PointA.y + (self.topPoints.PointC.y - self.topPoints.PointA.y)*.5;
        CGFloat w = fabs(self.topPoints.PointC.x - self.topPoints.PointA.x); /// 取绝对值
        if (self.directionType == KJSlideDirectionTypeRightBottom || self.directionType == KJSlideDirectionTypeRightTop) {
            x += self.topPoints.PointC.x - self.topPoints.PointA.x;
        }
        UIBezierPath *topPath = [self kj_topPath];
        /// 追加矩形路径
        [topPath appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(x,y,w,self.lineLenght) cornerRadius:0.0]];
        self.topModel.path = topPath;
    }
    self.topModel.imageRect = ({
        CGFloat w = self.topPoints.PointC.x - self.topPoints.PointA.x;
        CGFloat h = self.topPoints.PointC.y - self.topPoints.PointA.y;
        CGRectMake(self.topPoints.PointA.x, self.topPoints.PointA.y, w, h+self.lineLenght);
    });
    if (self.topModel.chartletComplete) self.topModel.perspectiveImage = [self kj_getTopCylinderImage];
    /// 底部椭圆
    self.botModel.path = [self kj_botomPath];
    self.botModel.imageRect = ({
        CGFloat x = self.botPoints.PointA.x;
        CGFloat y = self.botPoints.PointA.y;
        CGFloat w = self.topPoints.PointC.x - self.topPoints.PointA.x;
        CGFloat h = self.topPoints.PointC.y - self.topPoints.PointA.y;
        CGRectMake(x,y,w,h);
    });
//        if (self.botModel.chartletComplete) self.botModel.perspectiveImage = [self kj_getBottomOvalImage];
    [self setNeedsDisplay];
}
/// 判断是凹进去还是凸出来
- (KJConcaveConvexType)kj_concaveConvesTypeWithPoint:(CGPoint)tempPoint{
    if (self.touchBeginPoint.y - tempPoint.y > 0) {
        return KJConcaveConvexTypeConcave;/// 向内凹
    }else{
        return KJConcaveConvexTypeConvex; /// 向外凸
    }
}
/// 获取E1，F1，G1，H1对应点坐标
- (KJKnownPoints)kj_bottomPoints{
    CGPoint E = self.topPoints.PointA;
    CGPoint F = self.topPoints.PointB;
    CGPoint G = self.topPoints.PointC;
    CGPoint H = self.topPoints.PointD;
    CGPoint E1 = CGPointZero;
    CGPoint F1 = CGPointZero;
    CGPoint G1 = CGPointZero;
    CGPoint H1 = CGPointZero;
    CGPoint O1 = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:E Point2:F Point3:G Point4:H];/// EF和GH交点
    CGPoint O2 = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:E Point2:H Point3:G Point4:F];/// EH和FG交点
    /// 重合或者平行
    if (CGPointEqualToPoint(CGPointZero,O1) && CGPointEqualToPoint(CGPointZero,O2)) {
        E1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:H Point2:E VerticalLenght:self.lineLenght Positive:self.concaveType];
        F1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:G Point2:F VerticalLenght:self.lineLenght Positive:self.concaveType];
        G1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:F Point2:G VerticalLenght:self.lineLenght Positive:self.concaveType];
        H1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:E Point2:H VerticalLenght:self.lineLenght Positive:self.concaveType];
    }else if (CGPointEqualToPoint(CGPointZero,O1)) {
        E1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:H Point2:E VerticalLenght:self.lineLenght Positive:self.concaveType];
        F1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:G Point2:F VerticalLenght:self.lineLenght Positive:self.concaveType];
        G1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:F Point2:G VerticalLenght:self.lineLenght Positive:self.concaveType];
        H1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:E Point2:H VerticalLenght:self.lineLenght Positive:self.concaveType];
    }else if (CGPointEqualToPoint(CGPointZero,O2)) {
        F1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:G Point2:F VerticalLenght:self.lineLenght Positive:self.concaveType];
        G1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:F Point2:G VerticalLenght:self.lineLenght Positive:self.concaveType];
        CGPoint E2 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:H Point2:E VerticalLenght:self.lineLenght Positive:self.concaveType];
        E1 = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:F1 Point2:O1 Point3:E Point4:E2];
        CGPoint H2 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:E Point2:H VerticalLenght:self.lineLenght Positive:self.concaveType];
        H1 = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:G1 Point2:O1 Point3:H Point4:H2];
    }else{
        E1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:H Point2:E VerticalLenght:self.lineLenght Positive:self.concaveType];
        F1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:G Point2:F VerticalLenght:self.lineLenght Positive:self.concaveType];
        G1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:F Point2:G VerticalLenght:self.lineLenght Positive:self.concaveType];
        H1 = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:E Point2:H VerticalLenght:self.lineLenght Positive:self.concaveType];
    }
    KJKnownPoints points = (KJKnownPoints){E1,F1,G1,H1};
    return points;
}
#pragma mark - 路径处理
/// 镂空路径
- (UIBezierPath*)kj_hollowOutPath{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.usesEvenOddFillRule = YES;//设置填充规则为奇偶填充
    [path moveToPoint:self.knownPoints.PointA];
    [path addLineToPoint:self.knownPoints.PointB];
    [path addLineToPoint:self.knownPoints.PointC];
    [path addLineToPoint:self.knownPoints.PointD];
    [path addLineToPoint:self.knownPoints.PointA];
    
    UIBezierPath *bPath = [UIBezierPath bezierPath];
    [bPath moveToPoint:self.topPoints.PointA];
    [bPath addLineToPoint:self.topPoints.PointD];
    [bPath addLineToPoint:self.topPoints.PointC];
    [bPath addLineToPoint:self.topPoints.PointB];
    [bPath addLineToPoint:self.topPoints.PointA];
    [path appendPath:bPath];
    return path;
}
/// 外界选区路径
- (UIBezierPath*)kj_outsidePath{
    return ({
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:self.knownPoints.PointA];
        [path addLineToPoint:self.knownPoints.PointB];
        [path addLineToPoint:self.knownPoints.PointC];
        [path addLineToPoint:self.knownPoints.PointD];
        [path closePath];
        path;
    });
}
- (UIBezierPath*)kj_topPath{
    if (self.shapeType == KJDarwShapeTypeOval) {
        CGFloat x = self.topPoints.PointA.x;
        CGFloat y = self.topPoints.PointA.y;
        CGFloat w = self.topPoints.PointC.x - self.topPoints.PointA.x;
        CGFloat h = self.topPoints.PointC.y - self.topPoints.PointA.y;
        return [UIBezierPath bezierPathWithOvalInRect:CGRectMake(x,y,w,h)];/// 椭圆路径
    }else {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:self.topPoints.PointA];
        [path addLineToPoint:self.topPoints.PointD];
        [path addLineToPoint:self.topPoints.PointC];
        [path addLineToPoint:self.topPoints.PointB];
        [path closePath];
        return path;
    }
}
- (UIBezierPath*)kj_botomPath{
    if (self.shapeType == KJDarwShapeTypeOval) {
        CGFloat x = self.botPoints.PointA.x;
        CGFloat y = self.botPoints.PointA.y;
        CGFloat w = self.topPoints.PointC.x - self.topPoints.PointA.x;
        CGFloat h = self.topPoints.PointC.y - self.topPoints.PointA.y;
        return [UIBezierPath bezierPathWithOvalInRect:CGRectMake(x,y,w,h)];/// 椭圆路径
    }else {
        UIBezierPath *path = [UIBezierPath bezierPath];
        path.usesEvenOddFillRule = YES;
        [path moveToPoint:self.botPoints.PointA];
        [path addLineToPoint:self.botPoints.PointB];
        [path addLineToPoint:self.botPoints.PointC];
        [path addLineToPoint:self.botPoints.PointD];
        [path closePath];
        return path;
    }
}
- (UIBezierPath*)kj_frontPath{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.usesEvenOddFillRule = YES;
    [path moveToPoint:self.topPoints.PointA];
    [path addLineToPoint:self.botPoints.PointA];
    [path addLineToPoint:self.botPoints.PointD];
    [path addLineToPoint:self.topPoints.PointD];
    [path closePath];
    return path;
}
- (UIBezierPath*)kj_backPath{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.usesEvenOddFillRule = YES;
    [path moveToPoint:self.topPoints.PointB];
    [path addLineToPoint:self.botPoints.PointB];
    [path addLineToPoint:self.botPoints.PointC];
    [path addLineToPoint:self.topPoints.PointC];
    [path closePath];
    return path;
}
- (UIBezierPath*)kj_leftPath{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.usesEvenOddFillRule = YES;
    [path moveToPoint:self.topPoints.PointA];
    [path addLineToPoint:self.botPoints.PointA];
    [path addLineToPoint:self.botPoints.PointB];
    [path addLineToPoint:self.topPoints.PointB];
    [path closePath];
    return path;
}
- (UIBezierPath*)kj_rightPath{
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.usesEvenOddFillRule = YES;
    [path moveToPoint:self.topPoints.PointD];
    [path addLineToPoint:self.botPoints.PointD];
    [path addLineToPoint:self.botPoints.PointC];
    [path addLineToPoint:self.topPoints.PointC];
    [path closePath];
    return path;
}

@end

@implementation KJSuspendedModel
- (void)setImageRect:(CGRect)imageRect{
    CGRect tempRect = imageRect;
    /// 对应的六个面0：上 1：下 2：左 3：右 4：前 5：后
    switch (_sixMark) {
        case 0:{
            
        }
            break;
        case 1:{
            
        }
            break;
        case 2:{
            
        }
            break;
        case 3:{
            
        }
            break;
        case 4:{
            
        }
            break;
        case 5:{
            
        }
            break;
        default:
            break;
    }
    tempRect.size.width -= 1.;
    tempRect.size.height -= 1;
    _imageRect = tempRect;
}
- (void)setPoints:(KJKnownPoints)points{
    _points = points;
    self.imageRect = [_KJIFinishTools kj_rectWithPoints:points];
}
@end
