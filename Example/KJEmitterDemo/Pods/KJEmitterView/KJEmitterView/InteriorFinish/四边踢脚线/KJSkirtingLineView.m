//
//  KJSkirtingLineView.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/27.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "KJSkirtingLineView.h"
@interface KJSkirtingLineModel : NSObject
@property(nonatomic,assign) KJSkirtingLineType type;
@property(nonatomic,assign) bool opencv;
@property(nonatomic,assign) KJKnownPoints knownPoints; /// 已知选区ABCD四点
@property(nonatomic,strong) UIImage *materialImage; /// 素材图
@property(nonatomic,strong) UIImage *jointImage; /// 拼接好的素材图
@property(nonatomic,strong) UIImage *perspectiveImage; /// 透视好的素材图
@property(nonatomic,strong) CAShapeLayer *dashPatternLayer; /// 虚线选区
@property(nonatomic,assign) CGFloat width; /// 边线宽度
@property(nonatomic,assign) CGFloat height;/// 边线高度
@property(nonatomic,assign) CGRect imageRect;
@property(nonatomic,assign) KJKnownPoints points; /// 虚线框四点
@property(nonatomic,strong) UIBezierPath *bezierPath;/// 虚线路径
@property(nonatomic,assign) bool chartletComplete; /// 是否贴图
@property(nonatomic,assign) bool displayDashPattern; /// 是否显示虚线框
@property(nonatomic,readwrite,copy) void (^kChartletMoveBlcok)(KJSkirtingLineModel *model); /// 贴图之后移动回调处理
@end
@interface KJSkirtingLineView ()
@property(nonatomic,strong) KJSkirtingLineModel *topModel;
@property(nonatomic,strong) KJSkirtingLineModel *bottomModel;
@property(nonatomic,strong) KJSkirtingLineModel *leftModel;
@property(nonatomic,strong) KJSkirtingLineModel *rightModel;
@property(nonatomic,assign) CGPoint lastMovePoint; /// 记录上一次移动的点，用于确定上拉还是下拉
@property(nonatomic,assign) CGPoint touchBeginPoint;/// 记录开始移动触摸的点
@property(nonatomic,assign) bool canMove;/// 是否关闭当前滑动处理
@property(nonatomic,assign) KJSkirtingLineType currentType;/// 当前拖动的边线
@property(nonatomic,strong) UIBezierPath *fourBezierPath;/// 四条边形成的路径
@property(nonatomic,strong) NSMutableArray<KJSkirtingLineModel*>*temps;
@end

@implementation KJSkirtingLineView
#pragma mark - super method
/// 判断触摸点手势是否需要被使用
- (bool)kj_gestureIsUsedWithPoint:(CGPoint)point{
    if (![super kj_gestureIsUsedWithPoint:point]) return false;
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.topModel.points]) {
        return true;
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.bottomModel.points]) {
        return true;
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.leftModel.points]) {
        return true;
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.rightModel.points]) {
        return true;
    }
    return false;
}
/// 初始化
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points ExtendParameterBlock:(void (^ _Nullable)(KJInteriorSuperclassView * _Nonnull))block{
    if (self==[super kj_initWithKnownPoints:points ExtendParameterBlock:block]) {
        [self kj_addModelToTemps];
    }
    return self;
}
/// 改变KnownPoints的已知四点的相关操作
- (void)kj_changeKnownPoints:(KJKnownPoints)points{
    [super kj_changeKnownPoints:points];
    
}
/// 获取到存储数据
- (void)kj_setSaveDatasInfos:(KJInteriorSaveDatasInfo*)info PerspectiveBlock:(kInteriorPerspectiveBlock)block{
    for (KJSkirtingLineInfo *obj in info.skirtingLineInfoTemps) {
        obj.image = [_KJIFinishTools kj_getImageWithType:obj.imageGetModeType ImageName:obj.imageName];
        switch (obj.skirtingLineType) {
            case KJSkirtingLineTypeTop:
                [self kj_replaceSkirtingLineModel:self.topModel SkirtingLineInfo:obj PerspectiveBlock:block];
                break;
            case KJSkirtingLineTypeBottom:
                [self kj_replaceSkirtingLineModel:self.bottomModel SkirtingLineInfo:obj PerspectiveBlock:block];
                break;
            case KJSkirtingLineTypeLeft:
                [self kj_replaceSkirtingLineModel:self.leftModel SkirtingLineInfo:obj PerspectiveBlock:block];
                break;
            case KJSkirtingLineTypeRight:
                [self kj_replaceSkirtingLineModel:self.rightModel SkirtingLineInfo:obj PerspectiveBlock:block];
                break;
            default:
                break;
        }
    }
}
/// 子类传递数据至父类
- (KJInteriorSaveDatasInfo*)kj_getSaveDatasInfo{
    NSMutableArray<KJSkirtingLineInfo*>*temp = [NSMutableArray array];
    for (KJSkirtingLineModel *model in self.temps) {
        if (model.chartletComplete) {
            KJSkirtingLineInfo *info = [[KJSkirtingLineInfo alloc]init];
            info.imageName = model.materialImage.kj_imageName;
            info.imageGetModeType = model.materialImage.kj_imageGetModeType;
            info.skirtingLineType = model.type;
            if (model.type == KJSkirtingLineTypeLeft || model.type == KJSkirtingLineTypeRight) {
                info.lenght = model.width;
            }else if (model.type == KJSkirtingLineTypeTop || model.type == KJSkirtingLineTypeBottom) {
                info.lenght = model.height;
            }
            [temp addObject:info];
        }
    }
    KJInteriorSaveDatasInfo *info = [KJInteriorSaveDatasInfo new];
    info.skirtingLineInfoTemps = temp.mutableCopy;
    temp = nil;
    return info;
}
#pragma mark - private method
/// 创建对应的模型
- (KJSkirtingLineModel*)kj_skirtingLineModelWithType:(KJSkirtingLineType)type{
    KJKnownPoints points = self.knownPoints;
    KJSkirtingLineModel *model = [[KJSkirtingLineModel alloc]init];
    model.opencv = self.opencv;
    model.type = type;
    model.displayDashPattern = false;
    model.chartletComplete = false;
    model.knownPoints = points;
    CGFloat w = self.maxKnownRect.size.width;
    CGFloat h = self.maxKnownRect.size.height;
    CGFloat _len;
    CGFloat max = 30;
    CGFloat min = 20;
    if (type == KJSkirtingLineTypeLeft || type == KJSkirtingLineTypeRight) {
        CGFloat AB = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:points.PointA Point2:points.PointB];
        CGFloat CD = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:points.PointC Point2:points.PointD];
        if (AB>CD) {
            _len = type == KJSkirtingLineTypeLeft ? w/10. : (w/10. * CD/AB);
            model.width = MIN(MAX(max,_len),min);
        }else{
            _len = type == KJSkirtingLineTypeRight ? w/10. : (w/10. * CD/AB);
            model.width = MIN(MAX(max,_len),min);
        }
        model.height = h;
    }else if (type == KJSkirtingLineTypeTop || type == KJSkirtingLineTypeBottom) {
        CGFloat AD = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:points.PointA Point2:points.PointD];
        CGFloat CB = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:points.PointC Point2:points.PointB];
        if (AD>CB) {
            _len = type == KJSkirtingLineTypeTop ? h/10. : (h/10. * CB/AD);
            model.height = MIN(MAX(max,_len),min);
        }else{
            _len = type == KJSkirtingLineTypeBottom ? h/10. : (h/10. * AD/CB);
            model.height = MIN(MAX(max,_len),min);
        }
        model.width = w;
    }
    __weak typeof(self) weakself = self;
    model.kChartletMoveBlcok = ^(KJSkirtingLineModel *model) {
        model.dashPatternLayer.strokeColor = weakself.dashPatternColor.CGColor;
        if (weakself.kPerspectiveBlock) {
            /// 重新拼接素材
            SEL selector = NSSelectorFromString(@"kj_jointImage");
            IMP imp = [model methodForSelector:selector];
            void (*func)(id, SEL) = (void *)imp;
            func(model, selector);
            /// 回调贴图
            model.perspectiveImage = weakself.kPerspectiveBlock(model.points, model.jointImage);
            [weakself setNeedsDisplay];
        }
    };
    [self.layer addSublayer:model.dashPatternLayer];
    return model;
}
/// 替换模型当中的参数
- (void)kj_replaceSkirtingLineModel:(KJSkirtingLineModel*)model SkirtingLineInfo:(KJSkirtingLineInfo*)info PerspectiveBlock:(kInteriorPerspectiveBlock)block{
    model.height = info.lenght;
    if (info.image == nil) return;
    model.materialImage = info.image;
    if (block) {
        model.perspectiveImage = block(model.points, model.jointImage);
        model.chartletComplete = true;
        model.displayDashPattern = false;
    }
}
/// 创建数据模型并且存储在数组
- (void)kj_addModelToTemps{
    if (self.temps.count == 0) {
        self.topModel = [self kj_skirtingLineModelWithType:KJSkirtingLineTypeTop];
        self.bottomModel = [self kj_skirtingLineModelWithType:KJSkirtingLineTypeBottom];
        self.leftModel = [self kj_skirtingLineModelWithType:KJSkirtingLineTypeLeft];
        self.rightModel = [self kj_skirtingLineModelWithType:KJSkirtingLineTypeRight];
        [self.temps addObject:self.topModel];
        [self.temps addObject:self.bottomModel];
        [self.temps addObject:self.leftModel];
        [self.temps addObject:self.rightModel];
    }
}
#pragma mark - lazy
- (NSMutableArray<KJSkirtingLineModel*>*)temps{
    if (!_temps) {
        _temps = [NSMutableArray array];
    }
    return _temps;
}
#pragma mark - geter/seter
@synthesize dashPatternColor = _dashPatternColor;
@synthesize dashPatternWidth = _dashPatternWidth;
- (void)setDashPatternColor:(UIColor*)dashPatternColor{
    _dashPatternColor = dashPatternColor;
    [self kj_setLayerSkirtingLineModel:self.topModel];
    [self kj_setLayerSkirtingLineModel:self.bottomModel];
    [self kj_setLayerSkirtingLineModel:self.leftModel];
    [self kj_setLayerSkirtingLineModel:self.rightModel];
}
- (void)kj_setLayerSkirtingLineModel:(KJSkirtingLineModel*)model{
    if (model.displayDashPattern && model.chartletComplete == false) {
        model.dashPatternLayer.strokeColor = _dashPatternColor.CGColor;
    }
}
- (void)setDashPatternWidth:(CGFloat)dashPatternWidth{
    _dashPatternWidth = dashPatternWidth;
    self.topModel.dashPatternLayer.lineWidth = dashPatternWidth;
    self.bottomModel.dashPatternLayer.lineWidth = dashPatternWidth;
    self.leftModel.dashPatternLayer.lineWidth = dashPatternWidth;
    self.rightModel.dashPatternLayer.lineWidth = dashPatternWidth;
}
#pragma mark - publick method
/// 初始化
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points SkirtingLineType:(KJSkirtingLineType)type ExtendParameterBlock:(void(^_Nullable)(KJInteriorSuperclassView *obj))block{
    if (self == [super kj_initWithKnownPoints:points ExtendParameterBlock:block]) {
        [self kj_addModelToTemps];
        if (type == 1 || (type & KJSkirtingLineTypeTop)) {
            self.topModel.displayDashPattern = true;
        }
        if (type == 2 || (type & KJSkirtingLineTypeBottom)) {
            self.bottomModel.displayDashPattern = true;
        }
        if (type == 3 || (type & KJSkirtingLineTypeLeft)) {
            self.leftModel.displayDashPattern = true;
        }
        if (type == 4 || (type & KJSkirtingLineTypeRight)) {
            self.rightModel.displayDashPattern = true;
        }
    }
    return self;
}
/// 根据当前坐标修改指定区域素材图 - 透视图片
- (bool)kj_chartletAndFixationWithMaterialImage:(UIImage*)materialImage Point:(CGPoint)point PerspectiveBlock:(UIImage *(^)(KJKnownPoints points,UIImage *jointImage))block{
    bool boo;
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.topModel.points]) {
        boo = [self kj_setImage:materialImage SkirtingLineModel:self.topModel PerspectiveBlock:block];
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.bottomModel.points]) {
        boo = [self kj_setImage:materialImage SkirtingLineModel:self.bottomModel PerspectiveBlock:block];
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.leftModel.points]) {
        boo = [self kj_setImage:materialImage SkirtingLineModel:self.leftModel PerspectiveBlock:block];
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.rightModel.points]) {
        boo = [self kj_setImage:materialImage SkirtingLineModel:self.rightModel PerspectiveBlock:block];
    }else {
        return false;
    }
    if (boo == false) return false;
    /// 调用父类的数据存储处理
    [super kj_saveToFmdbBlock];
    return true;
}
- (bool)kj_setImage:(UIImage*)materialImage SkirtingLineModel:(KJSkirtingLineModel*)model PerspectiveBlock:(UIImage *(^)(KJKnownPoints points,UIImage *jointImage))block{
    if (model.displayDashPattern == false && model.chartletComplete == false) return false;
    model.materialImage = materialImage;
    if (block) {
        model.perspectiveImage = block(model.points,model.jointImage);
        model.chartletComplete = true;
        model.displayDashPattern = false;
        model.dashPatternLayer.strokeColor = UIColor.clearColor.CGColor;
        [self setNeedsDisplay];
    }
    return true;
}
#pragma mark - 绘制
- (void)drawRect:(CGRect)rect{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetShouldAntialias(ctx,YES);
    /// 四条边形成的路径区域
    UIBezierPath *path = [UIBezierPath new];
    [path appendPath:[self kj_getPathWithSkirtingLineModel:self.topModel]];
    [path appendPath:[self kj_getPathWithSkirtingLineModel:self.bottomModel]];
    [path appendPath:[self kj_getPathWithSkirtingLineModel:self.leftModel]];
    [path appendPath:[self kj_getPathWithSkirtingLineModel:self.rightModel]];
    [path addClip]; /// 路径裁剪
    if (self.rightModel.chartletComplete) [self kj_chartletWithCtx:ctx SkirtingLineModel:self.rightModel];
    if (self.leftModel.chartletComplete)  [self kj_chartletWithCtx:ctx SkirtingLineModel:self.leftModel];
    if (self.topModel.chartletComplete)   [self kj_chartletWithCtx:ctx SkirtingLineModel:self.topModel];
    if (self.bottomModel.chartletComplete)[self kj_chartletWithCtx:ctx SkirtingLineModel:self.bottomModel];
}
- (UIBezierPath*)kj_getPathWithSkirtingLineModel:(KJSkirtingLineModel*)model{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:model.points.PointA];
    [path addLineToPoint:model.points.PointB];
    [path addLineToPoint:model.points.PointC];
    [path addLineToPoint:model.points.PointD];
    [path closePath]; /// 闭合路径
    return path;
}
- (void)kj_chartletWithCtx:(CGContextRef)ctx SkirtingLineModel:(KJSkirtingLineModel*)model{
    UIGraphicsPushContext(ctx);// 解决绘制图片上下颠倒
//    if (self.opencv) {
//        [model.perspectiveImage drawInRect:self.bounds];
//    }else{
        CGRect tempRect = model.imageRect;
        tempRect.size.width -= 1.;
        tempRect.size.height -= 1;
        [model.perspectiveImage drawInRect:tempRect];
//    }
    UIGraphicsPopContext();
}
#pragma mark - touches
/// 点击处理
- (void)kj_tapWithPoint:(CGPoint)tempPoint{
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.topModel.points]) {
        [self kj_setTapSelectWithSkirtingLineModel:self.topModel];
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.bottomModel.points]) {
        [self kj_setTapSelectWithSkirtingLineModel:self.bottomModel];
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.rightModel.points]) {
        [self kj_setTapSelectWithSkirtingLineModel:self.rightModel];
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.leftModel.points]) {
        [self kj_setTapSelectWithSkirtingLineModel:self.leftModel];
    }
}
- (void)kj_setTapSelectWithSkirtingLineModel:(KJSkirtingLineModel*)model{
    if (model.chartletComplete) {
//        model.chartletComplete = false;
//        model.displayDashPattern = true;
//        model.dashPatternLayer.strokeColor = self.dashPatternColor.CGColor;
    }else if (model.displayDashPattern) {
        model.displayDashPattern = false;
        model.dashPatternLayer.strokeColor = UIColor.clearColor.CGColor;
    }else {
        model.displayDashPattern = true;
        model.dashPatternLayer.strokeColor = self.dashPatternColor.CGColor;
    }
}
/// 开始触摸的点
- (void)kj_moveWithStartPoint:(CGPoint)tempPoint{
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.topModel.points]) {
        self.currentType = KJSkirtingLineTypeTop;
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.bottomModel.points]) {
        self.currentType = KJSkirtingLineTypeBottom;
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.leftModel.points]) {
        self.currentType = KJSkirtingLineTypeLeft;
    }else if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.rightModel.points]) {
        self.currentType = KJSkirtingLineTypeRight;
    }else{
        self.currentType = KJSkirtingLineTypeUnknown;
        return;
    }
    self.touchBeginPoint = tempPoint;
    self.lastMovePoint = self.touchBeginPoint;
    self.canMove = true;
}
/// 移动处理
- (void)kj_moveWithChangePoint:(CGPoint)tempPoint{
    if (self.currentType == KJSkirtingLineTypeTop) {
        if (self.topModel.height>0) {
            CGFloat x = tempPoint.y - self.lastMovePoint.y;
            self.topModel.height += x;
            if (self.topModel.height<=0) self.topModel.height = 0;
            self.lastMovePoint = tempPoint;
        }
    }else if (self.currentType == KJSkirtingLineTypeBottom) {
        if (self.bottomModel.height>0) {
            CGFloat x = tempPoint.y - self.lastMovePoint.y;
            self.bottomModel.height -= x;
            if (self.bottomModel.height<=0) self.bottomModel.height = 0;
            self.lastMovePoint = tempPoint;
        }
    }else if (self.currentType == KJSkirtingLineTypeLeft) {
        if (self.leftModel.width>0) {
            CGFloat x = tempPoint.x - self.lastMovePoint.x;
            self.leftModel.width += x;
            if (self.leftModel.width<=0) self.leftModel.width = 0;
            self.lastMovePoint = tempPoint;
        }
    }else if (self.currentType == KJSkirtingLineTypeRight) {
        if (self.rightModel.width>0) {
            CGFloat x = tempPoint.x - self.lastMovePoint.x;
            self.rightModel.width -= x;
            if (self.rightModel.width<=0) self.rightModel.width = 0;
            self.lastMovePoint = tempPoint;
        }
    }
}
/// 移动结束
- (void)kj_moveWithEndPoint:(CGPoint)tempPoint{
    self.canMove = false;
    if (self.topModel.chartletComplete) self.topModel.dashPatternLayer.strokeColor = UIColor.clearColor.CGColor;
    if (self.bottomModel.chartletComplete) self.bottomModel.dashPatternLayer.strokeColor = UIColor.clearColor.CGColor;
    if (self.leftModel.chartletComplete) self.leftModel.dashPatternLayer.strokeColor = UIColor.clearColor.CGColor;
    if (self.rightModel.chartletComplete) self.rightModel.dashPatternLayer.strokeColor = UIColor.clearColor.CGColor;
}
/// 长按删除处理
- (void)kj_longPressDelPoint:(CGPoint)tempPoint SaveDatasInfo:(KJInteriorSaveDatasInfo*)info{
    bool top = [_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.topModel.points];
    bool bottom = [_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.bottomModel.points];
    bool left = [_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.leftModel.points];
    bool right = [_KJIFinishTools kj_confirmCurrentPointWithPoint:tempPoint KnownPoints:self.rightModel.points];
    if (bottom && self.bottomModel.chartletComplete) {
        [self kj_delInfoWithSkirtingLineModel:self.bottomModel SaveDatasInfo:info];
    }else if (top && self.topModel.chartletComplete) {
        [self kj_delInfoWithSkirtingLineModel:self.topModel SaveDatasInfo:info];
    }else if (left && self.leftModel.chartletComplete) {
        [self kj_delInfoWithSkirtingLineModel:self.leftModel SaveDatasInfo:info];
    }else if (right && self.rightModel.chartletComplete) {
        [self kj_delInfoWithSkirtingLineModel:self.rightModel SaveDatasInfo:info];
    }else{
        return;
    }
    if (self.longblock) self.longblock(info);
    [self setNeedsDisplay];
}
- (void)kj_delInfoWithSkirtingLineModel:(KJSkirtingLineModel*)model SaveDatasInfo:(KJInteriorSaveDatasInfo*)info{
    NSMutableArray<KJSkirtingLineInfo*>*temp = [NSMutableArray array];
    for (KJSkirtingLineInfo *skInfo in info.skirtingLineInfoTemps) {
        if (skInfo.skirtingLineType == model.type) continue;
        [temp addObject:skInfo];
    }
    info.skirtingLineInfoTemps = temp.mutableCopy;
    model.displayDashPattern = true;
    model.chartletComplete = false;
    model.dashPatternLayer.strokeColor = self.dashPatternColor.CGColor;
    temp = nil;
}
@end




@implementation KJSkirtingLineModel
#pragma mark - geter/seter
- (CAShapeLayer*)dashPatternLayer{
    if (!_dashPatternLayer) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.fillColor = [UIColor.redColor colorWithAlphaComponent:0.0].CGColor;
        shapeLayer.strokeColor = UIColor.blackColor.CGColor;
        shapeLayer.lineWidth = 1.;
        shapeLayer.lineCap = kCALineCapButt;
        shapeLayer.lineDashPattern = @[@(5),@(5)];
        shapeLayer.fillRule = kCAFillRuleEvenOdd;
        shapeLayer.lineJoin = kCALineJoinRound;
        shapeLayer.lineCap = kCALineCapRound;
        _dashPatternLayer = shapeLayer;
    }
    return _dashPatternLayer;
}
- (void)setHeight:(CGFloat)height{
    if ((_height == height && height != 0) || height == 0) return;
    _height = height;
    [self kj_skirtingLinePointsWithKnownPoints:self.knownPoints];
}
- (void)setWidth:(CGFloat)width{
    if (width == 0) return;
    if (_width == width) return;
    _width = width;
    [self kj_skirtingLinePointsWithKnownPoints:self.knownPoints];
}
- (void)setMaterialImage:(UIImage *)materialImage{
    _materialImage = materialImage;
    [self kj_jointImage]; /// 拼接素材图
}
#pragma mark - 内部方法
/// 拼接素材图
- (void)kj_jointImage{
    /// 设置画布尺寸
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(_width, _height) ,NO, 0.0);
    UIImage *image = _materialImage;
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (self.type) {
        case KJSkirtingLineTypeTop:
            orientation = UIImageOrientationDown;
            break;
        case KJSkirtingLineTypeLeft:
            orientation = UIImageOrientationLeft;
            break;
        case KJSkirtingLineTypeRight:
            orientation = UIImageOrientationRight;
            break;
        default:
            break;
    }
    image = [_KJIFinishTools kj_rotationImageWithImage:_materialImage Orientation:orientation];
    if (self.type == KJSkirtingLineTypeTop || self.type == KJSkirtingLineTypeBottom) {
        CGFloat w  = _materialImage.size.width * _height / _materialImage.size.height;
        CGFloat xw = _width / w;
        CGFloat rw = roundf(xw);
        int row = xw<=rw ? rw : rw+1;
        CGFloat x = 0;
        for (int i=0; i<row; i++) {
            x = w * i;
            [image drawInRect:CGRectMake(x,0,w,_height)];
        }
    }else if (self.type == KJSkirtingLineTypeLeft || self.type == KJSkirtingLineTypeRight) {
        CGFloat h  = _materialImage.size.height * _width / _materialImage.size.width;
        CGFloat xh = _height / h;
        CGFloat rh = roundf(xh);
        int col = xh<=rh ? rh : rh+1;
        CGFloat y = 0;
        for (int i=0; i<col; i++) {
            y = h * i;
            [image drawInRect:CGRectMake(0,y,_width,h)];
        }
    }
    UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.jointImage = resultingImage;
}
/// 获取对应边线数据
- (void)kj_skirtingLinePointsWithKnownPoints:(KJKnownPoints)points{
    if (self.type == KJSkirtingLineTypeTop) {
        self.points = [self kj_topPointsWithKnownPoints:points];
    }else if (self.type == KJSkirtingLineTypeBottom) {
        self.points = [self kj_bottomPointsWithKnownPoints:points];
    }else if (self.type == KJSkirtingLineTypeLeft) {
        self.points = [self kj_leftPointsWithKnownPoints:points];
    }else if (self.type == KJSkirtingLineTypeRight) {
        self.points = [self kj_rightPointsWithKnownPoints:points];
    }
    self.imageRect = [_KJIFinishTools kj_rectWithPoints:self.points];
    self.bezierPath = ({
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:self.points.PointA];
        [path addLineToPoint:self.points.PointB];
        [path addLineToPoint:self.points.PointC];
        [path addLineToPoint:self.points.PointD];
        [path closePath];
        path;
    });
    /// 已经贴好图需单独处理
    if (self.chartletComplete) !self.kChartletMoveBlcok?:self.kChartletMoveBlcok(self);
    if (self.displayDashPattern == false) self.dashPatternLayer.strokeColor = UIColor.clearColor.CGColor;
    self.dashPatternLayer.path = self.bezierPath.CGPath;
}
- (KJKnownPoints)kj_topPointsWithKnownPoints:(KJKnownPoints)knownPoints{
    CGPoint A = knownPoints.PointA;
    CGPoint B = knownPoints.PointB;
    CGPoint C = knownPoints.PointC;
    CGPoint D = knownPoints.PointD;
    KJKnownPoints points;
    CGPoint O = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:A Point2:D Point3:B Point4:C];
    CGFloat AD = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:A Point2:D];
    CGFloat CB = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:C Point2:B];
    CGPoint M = CGPointZero;
    if (AD>CB) {
        M = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:D Point2:A VerticalLenght:self.height Positive:YES];
    }else{
        M = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:A Point2:D VerticalLenght:self.height Positive:YES];
    }
    if (CGPointEqualToPoint(CGPointZero, O)) { /// 重合或者平行
        O = [_KJIFinishTools kj_parallelLineDotsWithPoint1:A Point2:D Point3:M];
    }
    points.PointA = A;
    points.PointB = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:O Point2:M Point3:A Point4:B];
    points.PointC = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:O Point2:M Point3:C Point4:D];
    points.PointD = D;
    return points;
}
- (KJKnownPoints)kj_bottomPointsWithKnownPoints:(KJKnownPoints)knownPoints{
    CGPoint A = knownPoints.PointA;
    CGPoint B = knownPoints.PointB;
    CGPoint C = knownPoints.PointC;
    CGPoint D = knownPoints.PointD;
    KJKnownPoints points;
    CGPoint O = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:A Point2:D Point3:B Point4:C];
    CGFloat AD = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:A Point2:D];
    CGFloat CB = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:C Point2:B];
    CGPoint M = CGPointZero;
    if (AD>CB) {
        M = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:C Point2:B VerticalLenght:self.height Positive:NO];
    }else{
        M = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:B Point2:C VerticalLenght:self.height Positive:NO];
    }
    if (CGPointEqualToPoint(CGPointZero, O)) { /// 重合或者平行
        O = [_KJIFinishTools kj_parallelLineDotsWithPoint1:B Point2:C Point3:M];
    }
    points.PointA = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:O Point2:M Point3:A Point4:B];
    points.PointB = B;
    points.PointC = C;
    points.PointD = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:O Point2:M Point3:C Point4:D];
    return points;
}
- (KJKnownPoints)kj_leftPointsWithKnownPoints:(KJKnownPoints)knownPoints{
    CGPoint A = knownPoints.PointA;
    CGPoint B = knownPoints.PointB;
    CGPoint C = knownPoints.PointC;
    CGPoint D = knownPoints.PointD;
    KJKnownPoints points;
    CGPoint O = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:A Point2:B Point3:C Point4:D];
    CGFloat AB = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:A Point2:B];
    CGFloat CD = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:C Point2:D];
    CGPoint M = CGPointZero;
    if (AB>CD) {
        M = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:B Point2:A VerticalLenght:self.width Positive:YES];
    }else{
        M = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:A Point2:B VerticalLenght:self.width Positive:YES];
    }

    if (CGPointEqualToPoint(CGPointZero, O)) { /// 重合或者平行
        O = [_KJIFinishTools kj_parallelLineDotsWithPoint1:A Point2:B Point3:M];
    }
    points.PointA = A;
    points.PointB = B;
    points.PointC = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:O Point2:M Point3:B Point4:C];
    points.PointD = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:O Point2:M Point3:A Point4:D];
    return points;
}
- (KJKnownPoints)kj_rightPointsWithKnownPoints:(KJKnownPoints)knownPoints{
    CGPoint A = knownPoints.PointA;
    CGPoint B = knownPoints.PointB;
    CGPoint C = knownPoints.PointC;
    CGPoint D = knownPoints.PointD;
    KJKnownPoints points;
    CGPoint O = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:A Point2:B Point3:C Point4:D];
    CGFloat AB = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:A Point2:B];
    CGFloat CD = [_KJIFinishTools kj_distanceBetweenPointsWithPoint1:C Point2:D];
    CGPoint M = CGPointZero;
    if (AB>CD) {
        M = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:C Point2:D VerticalLenght:self.width Positive:NO];
    }else{
        M = [_KJIFinishTools kj_perpendicularLineDotsWithPoint1:D Point2:C VerticalLenght:self.width Positive:NO];
    }
    if (CGPointEqualToPoint(CGPointZero, O)) { /// 重合或者平行
        O = [_KJIFinishTools kj_parallelLineDotsWithPoint1:D Point2:C Point3:M];
    }
    points.PointA = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:O Point2:M Point3:A Point4:D];
    points.PointB = [_KJIFinishTools kj_linellaeCrosspointWithPoint1:O Point2:M Point3:B Point4:C];
    points.PointC = C;
    points.PointD = D;
    return points;
}
@end
