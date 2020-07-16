//
//  KJVesselView.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/12.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "KJInteriorVesselView.h"
#import "KJPaveFloor.h"
#import "KJPaveWallpaper.h"
@interface KJInteriorVesselView ()
@property(nonatomic,strong) KJSuspendedView *suspendedView;
@property(nonatomic,strong) KJDecorateBoxView *decorateBoxView;
@property(nonatomic,strong) KJSkirtingLineView *skirtingLineView;
@property(nonatomic,strong) KJLamplightLayer *lamplightLayer;
@property(nonatomic,strong) KJPaveImageView *paveImageView;/// 墙纸和地板载体，二者互斥
@property(nonatomic,strong) CAShapeLayer *tapSelectLayer;/// 选中状态展示
@property(nonatomic,assign) KJKnownPoints knownPoints; /// 容器选区透视四点
@property(nonatomic,assign) NSUInteger saveNumber;/// 容器独有标签 - 应用于数据存储
@property(nonatomic,assign) CGSize vesselSize; /// 容器尺寸
@property(nonatomic,assign) bool selectState;/// 是否为选中状态
@property(nonatomic,assign) bool useLazy;/// 是否采用懒加载方式
@property(nonatomic,assign) bool testPattern;/// 调试模式，绘制选区，需在addSubview之后执行才有效
@property(nonatomic,assign) bool opencv;/// 是否使用OpenCV透视，需要单独处理
@property(nonatomic,assign) bool clipPave;/// 是否根据外界选区路径裁剪墙纸和地板
@property(nonatomic,strong) UIBezierPath *outsidePath;/// 外界选区路径
@property(nonatomic,readwrite,copy) bool(^selectblock)(bool state);/// 选中状态处理
@property(nonatomic,readwrite,copy) void(^paveblock)(KJVesselPavedType paveType);/// 地板铺贴之后处理
@property(nonatomic,readwrite,copy) void(^lamplightblock)(KJLamplightModel *model);/// 读取的数据赋值给外界UI，针对用于灯光处理
@property(nonatomic,readwrite,copy) kInteriorVesselPerspectiveBlock xxblock; /// 透视图回调处理
@property(nonatomic,readwrite,copy) kFmdbSqlBlock sqlblock;/// 数据存储回调 - 调用外界存储
@property(nonatomic,readwrite,copy) kGetDatasFromFmdbSqlBlock datasblock;/// 获取到存储数据回调
@property(nonatomic,readwrite,copy) kFmdbSqlBlock delblock;/// 数据长按删除回调处理
@property(nonatomic,readwrite,copy) kResponseBlock responseblock;/// 长按删除事件响应
@end

@implementation KJInteriorVesselView
NSString * const kInteriorVessel_Tableview = @"kInteriorVessel_Tableview37"; /// 容器表名
#pragma mark - 手势响应区域处理
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent*)event{
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
    point = [self convertPoint:point toView:self.superview];
    /// 处理是否在可见选区区域
    return [_KJIFinishTools kj_confirmCurrentPointWithPoint:point BezierPath:self.outsidePath];
}
#pragma mark - 手势处理
- (void)kj_tapWithPoint:(UIPanGestureRecognizer*)gesture{
    CGPoint point = [gesture locationInView:gesture.view];
    CGPoint superPoint = [self convertPoint:point toView:self.superview];
    if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:superPoint BezierPath:self.outsidePath]) {
        [self kj_tapDrawSelectRegion];
    }
}
/// 点击选中绘制选区
- (void)kj_tapDrawSelectRegion{
    self.selectState = !self.selectState;
    if (self.selectblock) {
        if (self.selectblock(self.selectState)) {
            return;
        }
    }
    [self kj_setSelectState:self.selectState];
}
/// 修改当前选中状态
- (void)kj_setSelectState:(bool)state{
    self.selectState = state;
    if (state && _tapSelectLayer == nil) {
        self.tapSelectLayer.path = self.outsidePath.CGPath;
    }else{
        [self.tapSelectLayer removeFromSuperlayer];
        self.tapSelectLayer = nil;
    }
}
#pragma mark - publick method
/// 初始化 - 推荐使用，内部做懒加载处理
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points PerspectiveBlock:(kInteriorVesselPerspectiveBlock)block ExtendParameterBlock:(void(^_Nullable)(KJInteriorVesselView *obj))paramblock{
    if (self==[super init]) {
        self.useLazy = true;
        self.xxblock = block;
        self.knownPoints = points;
        CGRect rect = [_KJIFinishTools kj_rectWithPoints:points];
        self.frame = rect;
        self.vesselSize = rect.size;
        /// 添加点击手势
        [self addGestureRecognizer:({
            self.userInteractionEnabled = YES;
            UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(kj_tapWithPoint:)];
            gesture.numberOfTapsRequired = 1;
            gesture;
        })];
        /// 扩展参数回调处理
        if (paramblock) paramblock(self);
        /// 调整容器相对位置尺寸
        self.frame = CGRectMake(rect.origin.x, rect.origin.y, self.vesselSize.width, self.vesselSize.height);
        /// 获取数据之后的相关处理操作
        if (self.datasblock) {
            KJInteriorSaveDatasInfo *info = self.datasblock(kInteriorVessel_Tableview,[NSString stringWithFormat:@"%lu",(unsigned long)self.saveNumber]);
            /// 处理墙纸和地板
            if (info.wallpaperInfo.imageName && info.wallpaperInfo.displayWallpaper) {
                UIImage *materialImage = [_KJIFinishTools kj_getImageWithType:info.wallpaperInfo.imageGetModeType ImageName:info.wallpaperInfo.imageName];
                materialImage.kj_wallpaperType = info.wallpaperInfo.wallpaperType;
                info.wallpaperInfo.image = materialImage;
                [self kj_paveWallpaperWithMaterialImage:materialImage UseSave:false];
            }else if (info.floorInfo.imageName) {
                UIImage *materialImage = [_KJIFinishTools kj_getImageWithType:info.floorInfo.imageGetModeType ImageName:info.floorInfo.imageName];
                materialImage.kj_floorType = info.floorInfo.floorType;
                materialImage.kj_floorOpenAcross = info.floorInfo.openAcross;
                materialImage.kj_floorOpenVertical = info.floorInfo.openVertical;
                info.floorInfo.image = materialImage;
                [self kj_paveFloorWithMaterialImage:materialImage UseSave:false];
            }
            /// 处理脚线
            if (info.skirtingLineInfoTemps.count>0) {
                [self.skirtingLineView kj_loadFmdbDatasInfoWithSaveDatasInfo:info];
            }else if (self.skirtingLineView) { }
            /// 处理吊顶
            if (info.suspendedInfo.suspendedFaceInfoTemps.count>0) {
                [self.suspendedView kj_loadFmdbDatasInfoWithSaveDatasInfo:info];
                self.suspendedView.openDrawSuspended = false;
            }
            /// 处理壁画
            if (info.decorateBoxInfoTemps.count>0) {
                [self.decorateBoxView kj_loadFmdbDatasInfoWithSaveDatasInfo:info];
                self.decorateBoxView.openDrawDecorateBox = false;
            }
            /// 处理灯光
            if (info.lamplightModel.imageName) {
                UIImage *materialImage = [_KJIFinishTools kj_getImageWithType:info.lamplightModel.imageGetModeType ImageName:info.lamplightModel.imageName];
                materialImage.kj_imageName = info.lamplightModel.imageName;
                materialImage.kj_imageGetModeType = info.lamplightModel.imageGetModeType;
                info.lamplightModel.image = materialImage;
                [self kj_delLamplightWithLamplightModel:info.lamplightModel UseSave:false];
                if (self.lamplightblock) {
                    self.lamplightblock(info.lamplightModel);
                }
            }
        }
    }
    return self;
}
/// 初始化
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points VesselNeedViewType:(KJVesselNeedViewType)type PerspectiveBlock:(kInteriorVesselPerspectiveBlock)block{
    if (self==[super init]) {
        self.useLazy = false;
        self.xxblock = block;
        self.knownPoints = points;
        self.frame = [_KJIFinishTools kj_rectWithPoints:points];
        self.vesselSize = self.frame.size;
        /// 添加点击手势
        [self addGestureRecognizer:({
            UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(kj_tapWithPoint:)];
            gesture.numberOfTapsRequired = 1;
            gesture;
        })];
        if ((type == 4 || (type & KJVesselNeedViewTypeWallpaper)) || (type == 5 || (type & KJVesselNeedViewTypeFloor))) {
            [self addSubview:self.paveImageView];
        }
        if (type == 1 || (type & KJVesselNeedViewTypeSuspended)) {
            [self addSubview:self.suspendedView];
        }
        if (type == 2 || (type & KJVesselNeedViewTypeDecorateBox)) {
            [self addSubview:self.decorateBoxView];
        }
        if (type == 0 || (type & KJVesselNeedViewTypeSkirtingLine)) {
            [self addSubview:self.skirtingLineView];
        }
        if (type == 3 || (type & KJVesselNeedViewTypeLamplight)) {
            [self.layer addSublayer:self.lamplightLayer];
        }
    }
    return self;
}
/// 移动识别贴图 - 内部做回调处理透视图片，可以指定类型
/// 特殊处理吊顶、墙壁装饰、踢脚线都可以识别处理情况则需要传入 KJVesselNeedViewTypeSuspended | KJVesselNeedViewTypeDecorateBox | KJVesselNeedViewTypeSkirtingLine
- (bool)kj_moveDiscernWithMaterialImage:(UIImage*)materialImage Point:(CGPoint)point VesselNeedViewType:(KJVesselNeedViewType)type{
    if (type == KJVesselNeedViewTypeFloor || type == KJVesselNeedViewTypeWallpaper || type == KJVesselNeedViewTypeDecorateBox) {
        
    }else{
        point = [self.superview convertPoint:point toView:self];
    }
    __weak typeof(self) weakself = self;
    /// 特殊处理吊顶、墙壁装饰、踢脚线都可以识别处理情况
    if (type == (KJVesselNeedViewTypeSuspended | KJVesselNeedViewTypeDecorateBox | KJVesselNeedViewTypeSkirtingLine)) {
        return [self kj_specialMoveDiscernWithMaterialImage:materialImage Point:point];
    }else if (type == KJVesselNeedViewTypeWallpaper || type == KJVesselNeedViewTypeFloor) { /// 墙纸或者地板
        if ([_KJIFinishTools kj_confirmCurrentPointWithPoint:point KnownPoints:self.knownPoints]) {
            [weakself kj_wallpaperAndFloorPaveWithMaterialImage:materialImage VesselNeedViewType:type];
            return true;
        }
    }else if (type == KJVesselNeedViewTypeSuspended) { /// 吊顶
        if ([self.suspendedView kj_chartletAndFixationWithMaterialImage:materialImage Point:point PerspectiveBlock:^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull image) {
            if (weakself.xxblock) return weakself.xxblock(weakself,KJVesselNeedViewTypeSuspended,points,image);
                return image;
            }]) {
                return true;
        }
    }else if (type == KJVesselNeedViewTypeDecorateBox) { /// 墙壁装饰
        if ([self.decorateBoxView kj_chartletAndFixationWithMaterialImage:materialImage Point:point PerspectiveBlock:^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull image) {
            if (weakself.xxblock) return weakself.xxblock(weakself,KJVesselNeedViewTypeDecorateBox,points,image);
                return image;
            }]) {
                return true;
        }
    }else if (type == KJVesselNeedViewTypeSkirtingLine) { /// 脚线
        if ([self.skirtingLineView kj_chartletAndFixationWithMaterialImage:materialImage Point:point PerspectiveBlock:^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull image) {
            if (weakself.xxblock) return weakself.xxblock(weakself,KJVesselNeedViewTypeSkirtingLine,points,image);
                return image;
            }]) {
                return true;
        }
    }
    return false;
}
/// 点击铺贴 - 应用于墙纸和地板，返回地板是否铺贴成功
- (bool)kj_tapPaveWithMaterialImage:(UIImage*)materialImage VesselNeedViewType:(KJVesselNeedViewType)type{
    [self kj_wallpaperAndFloorPaveWithMaterialImage:materialImage VesselNeedViewType:type];
    return true;
}
/// 处理灯光效果 - 内部做回调处理透视图片
- (void)kj_delLamplightWithLamplightModel:(KJLamplightModel*)lamplightModel UseSave:(bool)useSave{
    __weak typeof(self) weakself = self;
    [self.lamplightLayer kj_addLayerWithLamplightModel:lamplightModel PerspectiveBlock:^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull jointImage) {
        if (weakself.xxblock) return weakself.xxblock(weakself,KJVesselNeedViewTypeLamplight,points,jointImage);
        return jointImage;
    }];
    /// 数据存储
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (useSave) {
            [weakself.lamplightLayer kj_lamplightSaveWithLamplightModel:lamplightModel];
        }
    });
}
#pragma mark - 内部方法
/// 特殊处理吊顶、墙壁装饰、踢脚线都可以识别处理情况
- (bool)kj_specialMoveDiscernWithMaterialImage:(UIImage*)materialImage Point:(CGPoint)point{
    __weak typeof(self) weakself = self;
    /// 打开壁画开关的时候特殊处理
    if (self.decorateBoxView.openDrawDecorateBox) {
        if ([self.decorateBoxView kj_chartletAndFixationWithMaterialImage:materialImage Point:point PerspectiveBlock:^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull image) {
            if (weakself.xxblock) return weakself.xxblock(weakself,KJVesselNeedViewTypeDecorateBox,points,image);
            return image;
        }]) {
            return true;
        }
    }
    /// 1、先识别吊顶区域
    if ([self.suspendedView kj_chartletAndFixationWithMaterialImage:materialImage Point:point PerspectiveBlock:^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull image) {
        if (weakself.xxblock) return weakself.xxblock(weakself,KJVesselNeedViewTypeSuspended,points,image);
            return image;
        }]) {
            return true;
    }
    /// 2、识别壁画区域
    if ([self.decorateBoxView kj_chartletAndFixationWithMaterialImage:materialImage Point:point PerspectiveBlock:^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull image) {
        if (weakself.xxblock) return weakself.xxblock(weakself,KJVesselNeedViewTypeDecorateBox,points,image);
            return image;
        }]) {
            return true;
    }
    /// 3、设别脚线区域
    if ([self.skirtingLineView kj_chartletAndFixationWithMaterialImage:materialImage Point:point PerspectiveBlock:^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull image) {
        if (weakself.xxblock) return weakself.xxblock(weakself,KJVesselNeedViewTypeSkirtingLine,points,image);
            return image;
        }]) {
            return true;
    }
    return false;
}
/// 墙纸和地板铺贴处理
- (void)kj_wallpaperAndFloorPaveWithMaterialImage:(UIImage*)materialImage VesselNeedViewType:(KJVesselNeedViewType)type{
    if (type == KJVesselNeedViewTypeWallpaper) {
        [self kj_paveWallpaperWithMaterialImage:materialImage UseSave:true];
    }else if (type == KJVesselNeedViewTypeFloor) {
        [self kj_paveFloorWithMaterialImage:materialImage UseSave:true];
    }
    if (self.paveblock) self.paveblock(self.paveImageView.paveType);
}
/// 铺贴地板
- (bool)kj_paveFloorWithMaterialImage:(UIImage*)materialImage UseSave:(bool)useSave{
    KJPaveFloor.lineColor = materialImage.kj_floorLineColor;
    KJPaveFloor.lineWidth = 0.2;
    __weak typeof(self) weakself = self;
    weakself.paveImageView.paveType = KJVesselPavedTypeFloor;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGFloat w = 0.;
        if (weakself.vesselSize.height > weakself.vesselSize.width) {
            CGFloat h = weakself.vesselSize.height/12.;
            w = materialImage.size.width*h/materialImage.size.height;
        }else{
            w = weakself.vesselSize.width/12.;
        }
        UIImage *newImage = [KJPaveFloor kj_floorJointWithMaterialImage:materialImage Type:materialImage.kj_floorType TargetImageSize:weakself.vesselSize FloorWidth:w OpenAcross:materialImage.kj_floorOpenAcross OpenVertical:materialImage.kj_floorOpenVertical];
        newImage = [_KJIFinishTools kj_getImageAppointAreaWithImage:newImage ImageAppointType:(KJImageAppointTypeCustom) CustomFrame:CGRectMake(0, 0, weakself.vesselSize.width, weakself.vesselSize.height)];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakself.xxblock) {
                KJKnownPoints tempPoints = weakself.knownPoints;
                tempPoints.PointA = [weakself.superview convertPoint:tempPoints.PointA toView:weakself];
                tempPoints.PointB = [weakself.superview convertPoint:tempPoints.PointB toView:weakself];
                tempPoints.PointC = [weakself.superview convertPoint:tempPoints.PointC toView:weakself];
                tempPoints.PointD = [weakself.superview convertPoint:tempPoints.PointD toView:weakself];
                weakself.paveImageView.image = weakself.xxblock(weakself,KJVesselNeedViewTypeFloor,tempPoints,newImage);
                if (weakself.paveblock) weakself.paveblock(weakself.paveImageView.paveType);
            }
        });
        if (useSave) {
            KJInteriorSaveDatasInfo *info = [KJInteriorSaveDatasInfo new];
            info.vesselNeedType = KJVesselNeedViewTypeFloor;
            info.floorInfo.imageName = materialImage.kj_imageName;
            info.floorInfo.imageGetModeType = materialImage.kj_imageGetModeType;
            info.floorInfo.floorType = materialImage.kj_floorType;
            info.floorInfo.openAcross = materialImage.kj_floorOpenAcross;
            info.floorInfo.openVertical = materialImage.kj_floorOpenVertical;
            [weakself kj_saveDatasInfo:info];
        }
    });
    return true;
}
/// 铺贴墙纸
- (bool)kj_paveWallpaperWithMaterialImage:(UIImage*)materialImage UseSave:(bool)useSave{
    __weak typeof(self) weakself = self;
    weakself.paveImageView.paveType = KJVesselPavedTypeWallpaper;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGFloat w = 0.;
        if (weakself.vesselSize.height > weakself.vesselSize.width) {
            CGFloat h = weakself.vesselSize.height/12.;
            w = materialImage.size.width*h/materialImage.size.height;
        }else{
            w = weakself.vesselSize.width/12.;
        }
        UIImage *newImage = [KJPaveWallpaper kj_wallpaperPaveWithMaterialImage:materialImage TiledType:materialImage.kj_wallpaperType TargetImageSize:weakself.vesselSize Width:w];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakself.xxblock) {
                KJKnownPoints tempPoints = weakself.knownPoints;
                tempPoints.PointA = [weakself.superview convertPoint:tempPoints.PointA toView:weakself];
                tempPoints.PointB = [weakself.superview convertPoint:tempPoints.PointB toView:weakself];
                tempPoints.PointC = [weakself.superview convertPoint:tempPoints.PointC toView:weakself];
                tempPoints.PointD = [weakself.superview convertPoint:tempPoints.PointD toView:weakself];
                weakself.paveImageView.image = weakself.xxblock(weakself,KJVesselNeedViewTypeWallpaper,tempPoints,newImage);
                if (weakself.paveblock) weakself.paveblock(weakself.paveImageView.paveType);
            }
        });
        if (useSave) {
            KJInteriorSaveDatasInfo *info = [KJInteriorSaveDatasInfo new];
            info.vesselNeedType = KJVesselNeedViewTypeWallpaper;
            info.wallpaperInfo.imageName = materialImage.kj_imageName;
            info.wallpaperInfo.imageGetModeType = materialImage.kj_imageGetModeType;
            info.wallpaperInfo.wallpaperType = materialImage.kj_wallpaperType;
            info.wallpaperInfo.displayWallpaper = true;
            [weakself kj_saveDatasInfo:info];
        }
    });
    return true;
}
#pragma mark - 数据存储相关
- (void)kj_saveDatasInfo:(KJInteriorSaveDatasInfo*)info{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (weakself.sqlblock) {
            weakself.sqlblock(kInteriorVessel_Tableview,[NSString stringWithFormat:@"%lu",(unsigned long)weakself.saveNumber],info);
        }
    });
}
#pragma mark - geter/seter
@synthesize testPattern = _testPattern;
- (void)setTestPattern:(bool)testPattern{
    _testPattern = testPattern;
    if (testPattern) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.fillColor = [UIColor.redColor colorWithAlphaComponent:0.].CGColor;
        shapeLayer.strokeColor = UIColor.blueColor.CGColor;
        shapeLayer.lineWidth = 1.;
        shapeLayer.lineJoin = kCALineJoinRound;
        shapeLayer.lineCap = kCALineCapRound;
//        shapeLayer.position = [self convertPoint:CGPointZero fromView:self.superview];
        [self.superview.layer addSublayer:shapeLayer];
        shapeLayer.path = ({
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:self.knownPoints.PointA];
            [path addLineToPoint:self.knownPoints.PointB];
            [path addLineToPoint:self.knownPoints.PointC];
            [path addLineToPoint:self.knownPoints.PointD];
            [path closePath];
            path.CGPath;
        });
    }
}
- (void)setOpenDrawDecorateBox:(bool)openDrawDecorateBox{
    _openDrawDecorateBox = openDrawDecorateBox;
    if (openDrawDecorateBox) {
        self.decorateBoxView.openDrawDecorateBox = openDrawDecorateBox;
        return;
    }
    if (_decorateBoxView == nil) {
        _openDrawDecorateBox = false;
    }else{
        _decorateBoxView.openDrawDecorateBox = openDrawDecorateBox;
    }
}
#pragma mark - lazy
/// 创建吊顶、壁画、脚线
- (KJInteriorSuperclassView*)kj_creatViewWithVesselType:(KJVesselNeedViewType)type{
    Class clazz = nil;
    CGRect rect = CGRectZero;
    KJKnownPoints tempPoints = self.knownPoints;
    if (type == KJVesselNeedViewTypeSuspended) {
        clazz = NSClassFromString(@"KJSuspendedView");
        CGFloat x = -self.frame.origin.x-1;
        CGFloat y = -self.frame.origin.y;
        CGFloat w = [UIScreen mainScreen].bounds.size.width+2;
        CGFloat h = [UIScreen mainScreen].bounds.size.height;
        rect = CGRectMake(x, y, w, h);
    }else if (type == KJVesselNeedViewTypeDecorateBox) {
        clazz = NSClassFromString(@"KJDecorateBoxView");
        CGFloat x = -self.frame.origin.x;
        CGFloat y = -self.frame.origin.y;
        CGFloat w = [UIScreen mainScreen].bounds.size.width;
        CGFloat h = [UIScreen mainScreen].bounds.size.height;
        rect = CGRectMake(x, y, w, h);
    }else if (type == KJVesselNeedViewTypeSkirtingLine) {
        clazz = NSClassFromString(@"KJSkirtingLineView");
        rect = self.bounds;
        tempPoints.PointA = [self.superview convertPoint:tempPoints.PointA toView:self];
        tempPoints.PointB = [self.superview convertPoint:tempPoints.PointB toView:self];
        tempPoints.PointC = [self.superview convertPoint:tempPoints.PointC toView:self];
        tempPoints.PointD = [self.superview convertPoint:tempPoints.PointD toView:self];
    }
    __weak typeof(self) weakself = self;
    __block NSString *saveNumber = [NSString stringWithFormat:@"%lu",(unsigned long)self.saveNumber];
    KJInteriorSuperclassView *view = [[clazz alloc]kj_initWithKnownPoints:tempPoints ExtendParameterBlock:^(KJInteriorSuperclassView * _Nonnull obj) {
        obj.kUseOpenCV(weakself.opencv);
        obj.kOpenMaxRegion(NO).kOutsidePath(weakself.outsidePath);
        obj.kGetInfosPerspectiveBlock(^UIImage * _Nullable(KJKnownPoints points, UIImage * _Nonnull image) {
            if (weakself.xxblock) return weakself.xxblock(weakself,type,points,image);
            return image;
        });
        obj.kChartletImageBlock(^(KJInteriorSaveDatasInfo * _Nonnull info) {
            info.vesselNeedType = type;
            [weakself kj_saveDatasInfo:info];
        });
        obj.kLongPressDelBlock(^(KJInteriorSaveDatasInfo * _Nonnull info) {
            info.vesselNeedType = type;
            if (weakself.delblock) weakself.delblock(kInteriorVessel_Tableview, saveNumber, info);
        });
        obj.kLongPressResponseBlock(^BOOL(CGPoint point) {
            if (weakself.responseblock) return weakself.responseblock(type,point);
            return YES;
        });
    }];
    view.kPerspectiveBlock = ^UIImage * _Nonnull(KJKnownPoints points, UIImage * _Nonnull image) {
        if (weakself.xxblock) return weakself.xxblock(weakself,type,points,image);
        return image;
    };
    view.backgroundColor = [UIColor.redColor colorWithAlphaComponent:0.];
    view.vesselSuperview = self.superview;
    view.frame = rect;
    if (self.useLazy) [self addSubview:view];
    return view;
}
- (KJSuspendedView*)suspendedView{
    if (!_suspendedView) {
        _suspendedView = (KJSuspendedView*)[self kj_creatViewWithVesselType:(KJVesselNeedViewTypeSuspended)];
    }
    return _suspendedView;
}
- (KJDecorateBoxView*)decorateBoxView{
    if (!_decorateBoxView) {
        _decorateBoxView = (KJDecorateBoxView*)[self kj_creatViewWithVesselType:(KJVesselNeedViewTypeDecorateBox)];
    }
    return _decorateBoxView;
}
- (KJSkirtingLineView*)skirtingLineView{
    if (!_skirtingLineView) {
        _skirtingLineView = (KJSkirtingLineView*)[self kj_creatViewWithVesselType:(KJVesselNeedViewTypeSkirtingLine)];
    }
    return _skirtingLineView;
}
- (KJLamplightLayer*)lamplightLayer{
    if (!_lamplightLayer) {
        __weak typeof(self) weakself = self;
        KJLamplightLayer *layer = [[KJLamplightLayer alloc]kj_initWithKnownPoints:self.knownPoints];
        layer.saveblock = ^(KJInteriorSaveDatasInfo * _Nullable info) {
            info.vesselNeedType = KJVesselNeedViewTypeLamplight;
            [weakself kj_saveDatasInfo:info];
        };
        layer.backgroundColor = [UIColor.greenColor colorWithAlphaComponent:0.].CGColor;
        CGFloat x = -self.frame.origin.x;
        CGFloat y = -self.frame.origin.y;
        CGFloat w = [UIScreen mainScreen].bounds.size.width;
        CGFloat h = [UIScreen mainScreen].bounds.size.height;
        layer.frame = CGRectMake(x, y, w, h);
        if (self.useLazy) [self.layer addSublayer:layer];
        if (self.clipPave) {
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            maskLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
            maskLayer.path = self.outsidePath.CGPath;
            layer.mask = maskLayer;
        }
        _lamplightLayer = layer;
    }
    return _lamplightLayer;
}
- (KJPaveImageView*)paveImageView{
    if (!_paveImageView) {
        KJPaveImageView *view = [KJPaveImageView new];
        view.backgroundColor = [UIColor.yellowColor colorWithAlphaComponent:0.];
        view.userInteractionEnabled = NO;
        view.frame = self.bounds;
        if (self.useLazy) {
            [self addSubview:view];
            [self sendSubviewToBack:view];
        }
        if (self.clipPave) {
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            maskLayer.frame = CGRectMake(-self.frame.origin.x, -self.frame.origin.y, self.frame.size.width, self.frame.size.height);
            maskLayer.path = self.outsidePath.CGPath;
            view.layer.mask = maskLayer;
        }
        _paveImageView = view;
    }
    return _paveImageView;
}
- (CAShapeLayer*)tapSelectLayer{
    if (!_tapSelectLayer) {
        CAShapeLayer *shapeLayer = [CAShapeLayer layer];
        shapeLayer.fillColor = [UIColor.redColor colorWithAlphaComponent:0.].CGColor;
        shapeLayer.strokeColor = UIColor.redColor.CGColor;
        shapeLayer.lineWidth = 1.5;
        shapeLayer.lineJoin = kCALineJoinRound;
        shapeLayer.lineCap = kCALineCapRound;
        shapeLayer.position = [self convertPoint:CGPointZero fromView:self.superview];
        [self.layer addSublayer:shapeLayer];
        _tapSelectLayer = shapeLayer;
    }
    return _tapSelectLayer;
}
#pragma mark - ExtendParameterBlock 扩展参数
- (KJInteriorVesselView *(^)(CGRect))kFrame {
    return ^(CGRect rect){
        self.frame = rect;
        return self;
    };
}
- (KJInteriorVesselView *(^)(NSInteger))kViewTag {
    return ^(NSInteger tag){
        self.tag = tag;
        return self;
    };
}
- (KJInteriorVesselView *(^)(UIView*))kAddView {
    return ^(UIView *view){
        [view addSubview:self];
        return self;
    };
}
- (KJInteriorVesselView *(^)(UIColor *))kBackgroundColor {
    return ^(UIColor *color) {
        self.backgroundColor = color;
        return self;
    };
}
- (KJInteriorVesselView *(^)(NSUInteger))kSaveNumber {
    return ^(NSUInteger a){
        self.saveNumber = a;
        return self;
    };
}
- (KJInteriorVesselView *(^)(BOOL))kUseOpenCV {
    return ^(BOOL a){
        self.opencv = a;
        return self;
    };
}
- (KJInteriorVesselView *(^)(UIBezierPath*))kOutsidePath {
    return ^(UIBezierPath *path) {
        self.outsidePath = path;
        return self;
    };
}
- (KJInteriorVesselView *(^)(BOOL))kTestPattern {
    return ^(BOOL a){
        self.testPattern = a;
        return self;
    };
}
- (KJInteriorVesselView *(^)(BOOL))kClipPave {
    return ^(BOOL a){
        self.clipPave = a;
        return self;
    };
}
- (KJInteriorVesselView *(^)(void(^)(KJVesselPavedType paveType)))kPavedFloorBlock {
    return ^(void(^block)(KJVesselPavedType paveType)){
        self.paveblock = block;
        return self;
    };
}
- (KJInteriorVesselView *(^)(void(^)(KJLamplightModel *model)))kGetLamplightBlock {
    return ^(void(^block)(KJLamplightModel *model)){
        self.lamplightblock = block;
        return self;
    };
}
- (KJInteriorVesselView *(^)(bool(^)(bool state)))kSelectStateBlock {
    return ^(bool(^block)(bool state)){
        self.selectblock = block;
        return self;
    };
}
- (KJInteriorVesselView *(^)(kFmdbSqlBlock))kSaveFmdbBlock {
    return ^(kFmdbSqlBlock block){
        self.sqlblock = block;
        return self;
    };
}
- (KJInteriorVesselView *(^)(kGetDatasFromFmdbSqlBlock))kGetDatasFmdbBlock {
    return ^(kGetDatasFromFmdbSqlBlock block){
        self.datasblock = block;
        return self;
    };
}
- (KJInteriorVesselView *(^)(kFmdbSqlBlock))kLongPressDelBlock {
    return ^(kFmdbSqlBlock block){
        self.delblock = block;
        return self;
    };
}
- (KJInteriorVesselView *(^)(kResponseBlock))kLongPressResponseBlock {
    return ^(kResponseBlock block){
        self.responseblock = block;
        return self;
    };
}

@end
