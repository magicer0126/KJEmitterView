//
//  KJReflectionImageView.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/7/8.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "KJReflectionImageView.h"
@interface KJReflectionImageView ()
@property(nonatomic,strong)KJInteriorVesselView *vesselView;
@property(nonatomic,strong)KJInteriorVesselView *floorView;
@property(nonatomic,assign)bool level;
@property(nonatomic,strong)kInteriorSizePerspectiveBlock xxxblock;
@end
@implementation KJReflectionImageView
/// 初始化
- (instancetype)kj_initWithVesselView:(KJInteriorVesselView*)vesselView ExtendParameterBlock:(void(^_Nullable)(KJReflectionImageView *obj))paramblock{
    if (self==[super init]) {
//        self.transform = CGAffineTransformMakeScale(1.0,-1.0); /// 垂直翻转
        self.alpha = 0.3;
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.backgroundColor = [UIColor.redColor colorWithAlphaComponent:0.];
        self.frame = vesselView.frame;
        self.vesselView = vesselView;
        /// 扩展参数回调处理
        if (paramblock) paramblock(self);
        if (self.xxxblock) {
            KJKnownPoints tempPoints = [self kj_correctImageWithknownPoints:vesselView.knownPoints];
            /// 获取容器图然后矫正透图片和裁剪图片
            UIImage *image = [self kj_captureScreen:[self kj_copyInteriorVesselView:vesselView]];
            UIImage *correctImage = self.xxxblock(vesselView.frame.size,tempPoints,image);
            UIImage *clipImage = [self kj_clipImage:correctImage Level:self.level];
            /// 寻找新的透视四点
            KJKnownPoints newPoints = [self kj_findNewPoints];
            self.frame =  [_KJIFinishTools kj_rectWithPoints:newPoints];
            newPoints.PointA = [self.superview convertPoint:newPoints.PointA toView:self];
            newPoints.PointB = [self.superview convertPoint:newPoints.PointB toView:self];
            newPoints.PointC = [self.superview convertPoint:newPoints.PointC toView:self];
            newPoints.PointD = [self.superview convertPoint:newPoints.PointD toView:self];
            /// 透视处理
            self.image = self.xxxblock(self.frame.size,newPoints,clipImage);
            /// 裁剪超出区域
            CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            maskLayer.frame = CGRectMake(-self.frame.origin.x, -self.frame.origin.y, self.frame.size.width, self.frame.size.height);
            maskLayer.path = self.floorView.outsidePath.CGPath;
            self.layer.mask = maskLayer;
        }
    }
    return self;
}
#pragma mark - privately method
/// 矫正透视图点处理
- (KJKnownPoints)kj_correctImageWithknownPoints:(KJKnownPoints)tempPoints{
    CGPoint pt = tempPoints.PointA;
    CGFloat x1 = fabs(tempPoints.PointA.x - tempPoints.PointD.x);
    CGFloat x2 = fabs(tempPoints.PointB.x - tempPoints.PointC.x);
    CGFloat y1 = fabs(tempPoints.PointA.y - tempPoints.PointB.y);
    CGFloat y2 = fabs(tempPoints.PointC.y - tempPoints.PointD.y);
    if (fabs(x1-x2)>fabs(y1-y2)) { /// 水平方向更趋近平行
        tempPoints.PointA = tempPoints.PointB;
        tempPoints.PointB = pt;
        pt = tempPoints.PointD;
        tempPoints.PointD = tempPoints.PointC;
        tempPoints.PointC = pt;
        self.level = true;
    }else{ /// 竖直方向更趋近平行
        tempPoints.PointA = tempPoints.PointD;
        tempPoints.PointD = pt;
        pt = tempPoints.PointB;
        tempPoints.PointB = tempPoints.PointC;
        tempPoints.PointC = pt;
        self.level = false;
    }
    tempPoints.PointA = [self.superview convertPoint:tempPoints.PointA toView:self];
    tempPoints.PointB = [self.superview convertPoint:tempPoints.PointB toView:self];
    tempPoints.PointC = [self.superview convertPoint:tempPoints.PointC toView:self];
    tempPoints.PointD = [self.superview convertPoint:tempPoints.PointD toView:self];
    return tempPoints;
}
/// 裁剪图片
- (UIImage*)kj_clipImage:(UIImage*)image Level:(bool)level{
    CGRect rect = CGRectZero;
    KJKnownPoints pts = self.vesselView.knownPoints;
    CGFloat AB = fabs(pts.PointA.y - pts.PointB.y);
    CGFloat CD = fabs(pts.PointC.y - pts.PointD.y);
    CGFloat AD = fabs(pts.PointA.x - pts.PointD.x);
    CGFloat CB = fabs(pts.PointC.x - pts.PointB.x);
    CGFloat w  = fabs(pts.PointA.x - pts.PointD.x);
    CGFloat h  = fabs(pts.PointC.y - pts.PointD.y);
    pts.PointA = [self.superview convertPoint:pts.PointA toView:self];
    pts.PointB = [self.superview convertPoint:pts.PointB toView:self];
    pts.PointC = [self.superview convertPoint:pts.PointC toView:self];
    pts.PointD = [self.superview convertPoint:pts.PointD toView:self];
    if (level) {
        rect = CGRectMake(AD>CB?pts.PointB.x:pts.PointA.x,pts.PointA.y,AD>CB?CB:AD,h);
    }else{
        rect = CGRectMake(pts.PointA.x,AB>CD?pts.PointD.y:pts.PointA.y,w,AB>CD?CD:AB);
    }
    UIImage *newImage = [self kj_cutImageWithImage:image Frame:rect];
    if (level == false) newImage = [self kj_rotationImageWithImage:newImage];
    return newImage;
}
/// 复制UIView
- (KJInteriorVesselView*)kj_copyInteriorVesselView:(KJInteriorVesselView*)view{
    NSData *tempArchive = [NSKeyedArchiver archivedDataWithRootObject:view];
    return [NSKeyedUnarchiver unarchiveObjectWithData:tempArchive];
}
/// 获取截图
- (UIImage*)kj_captureScreen:(UIView*)view{
    UIGraphicsBeginImageContext(view.bounds.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:ctx];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
/// 根据特定的区域对图片进行裁剪
- (UIImage*)kj_cutImageWithImage:(UIImage*)image Frame:(CGRect)frame{
    return ({
        CGImageRef tmp = CGImageCreateWithImageInRect([image CGImage], frame);
        UIImage *newImage = [UIImage imageWithCGImage:tmp scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(tmp);
        newImage;
    });
}
/// 图片旋转180°
- (UIImage*)kj_rotationImageWithImage:(UIImage*)image{
    CGRect rect = CGRectZero;
    rect.size.width = CGImageGetWidth(image.CGImage);
    rect.size.height = CGImageGetHeight(image.CGImage);
    CGRect bounds = rect;
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformMakeTranslation(rect.size.width,rect.size.height);
    transform = CGAffineTransformRotate(transform, M_PI);
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextTranslateCTM(context, 0.0, -rect.size.height);
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, image.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
/// 得到透视四点形成的所有边缘点
- (NSArray*)kj_getKnownPointFormationDots{
    NSMutableArray *temps = [NSMutableArray array];
    NSArray *ABDots = kj_findLineDots(self.floorView.knownPoints.PointA, self.floorView.knownPoints.PointB, 2);
    NSArray *BCDots = kj_findLineDots(self.floorView.knownPoints.PointB, self.floorView.knownPoints.PointC, 2);
    NSArray *CDDots = kj_findLineDots(self.floorView.knownPoints.PointC, self.floorView.knownPoints.PointD, 2);
    NSArray *DADots = kj_findLineDots(self.floorView.knownPoints.PointD, self.floorView.knownPoints.PointA, 2);
    [temps addObjectsFromArray:ABDots];
    [temps addObjectsFromArray:BCDots];
    [temps addObjectsFromArray:CDDots];
    [temps addObjectsFromArray:DADots];
    return temps.mutableCopy;
}
/// 寻找新的透视四点
- (KJKnownPoints)kj_findNewPoints{
    KJLineAndDot dp = kj_confirmTurnLine(self.floorView.knownPoints.PointA, self.floorView.knownPoints.PointB, self.floorView.knownPoints.PointC, self.floorView.knownPoints.PointD, self.vesselView.center);
    KJKnownPoints tempPoints = self.vesselView.knownPoints;
    CGPoint pointA = [self kj_point:tempPoints.PointA Line:dp];
    CGPoint pointB = [self kj_point:tempPoints.PointB Line:dp];
    CGPoint pointC = [self kj_point:tempPoints.PointC Line:dp];
    CGPoint pointD = [self kj_point:tempPoints.PointD Line:dp];
    return (KJKnownPoints){pointB,pointA,pointD,pointC};
}
#pragma mark - arithmetic 算法函数
typedef struct KJLineAndDot {CGPoint pointA; CGPoint pointB; CGPoint point;}KJLineAndDot;
- (CGPoint)kj_point:(CGPoint)point Line:(KJLineAndDot)line{
    CGPoint pt = kj_intersectionDot(line.pointA,line.pointB,point);
    return CGPointMake(pt.x, fabs(pt.y-point.y)+pt.y);
}
/// 确定翻转线，0：AB，1：BC，2：CD，3：DA
static inline KJLineAndDot kj_confirmTurnLine(CGPoint A,CGPoint B,CGPoint C,CGPoint D,CGPoint E){
    NSMutableArray *temp = [NSMutableArray array];
    NSArray *dots = kj_dotIntersections(A,B,C,D,E);
    for (int i=0; i<dots.count; i++) {
        if (dots[i] == [NSNull null]) {
            continue;
        }
        CGPoint ptA = CGPointZero, ptB = CGPointZero;
        if (i==0) {
            ptA = A;
            ptB = B;
        }else if (i==1) {
            ptA = B;
            ptB = C;
        }else if (i==2) {
            ptA = C;
            ptB = D;
        }else if (i==3) {
            ptA = D;
            ptB = A;
        }
        if (kj_dotIsLine(CGPointFromString(dots[i]),ptA,ptB)) {
            [temp addObject:dots[i]];
        }
    }
    CGPoint pt1 = E;
    CGPoint pt2 = CGPointFromString(temp[0]);
    CGFloat lenght = sqrt(pow(pt1.x-pt2.x,2) + pow(pt1.y-pt2.y,2));
    CGPoint pt = kj_findShortestPoint(pt1, temp, lenght);
    int index = 0;
    for (int i=0; i<dots.count; i++) {
        if (CGPointEqualToPoint(pt, CGPointFromString(dots[i]))) {
            index = i;
            break;
        }
    }
    if (index == 0) {
        return (KJLineAndDot){A,B,pt};
    }else if (index == 1) {
        return (KJLineAndDot){B,C,pt};
    }else if (index == 2) {
        return (KJLineAndDot){C,D,pt};
    }else {
        return (KJLineAndDot){D,A,pt};
    }
}
/// 判断点是否在线上
static inline bool kj_dotIsLine(CGPoint point,CGPoint A,CGPoint B){
    CGFloat x = point.x,x1 = A.x,x2 = B.x;
    if (x1>x2) {
        if (x2 <= x && x <= x1) return true;
    }else{
        if (x1 <= x && x <= x2) return true;
    }
    return false;
}
/// 已知ABCDE，求E竖直线与ABCD分别形成的线交点，空对象代表无交点
static inline NSArray * kj_dotIntersections(CGPoint A,CGPoint B,CGPoint C,CGPoint D,CGPoint E){
    NSMutableArray *temp = [NSMutableArray array];
    CGFloat x1 = A.x,x2 = B.x,x3 = C.x,x4 = D.x;
    if (x1==x2) {
        [temp addObject:[NSNull null]];
    }else{
        [temp addObject:NSStringFromCGPoint(kj_intersectionDot(A,B,E))];
    }
    if (x2==x3) {
        [temp addObject:[NSNull null]];
    }else{
        [temp addObject:NSStringFromCGPoint(kj_intersectionDot(B,C,E))];
    }
    if (x3==x4) {
        [temp addObject:[NSNull null]];
    }else{
        [temp addObject:NSStringFromCGPoint(kj_intersectionDot(C,D,E))];
    }
    if (x4==x1) {
        [temp addObject:[NSNull null]];
    }else{
        [temp addObject:NSStringFromCGPoint(kj_intersectionDot(D,A,E))];
    }
    return temp.mutableCopy;
}
/// 已知ABC，求C竖直线与AB的交点
static inline CGPoint kj_intersectionDot(CGPoint A,CGPoint B,CGPoint C){
    CGFloat x1 = A.x,y1 = A.y;
    CGFloat x2 = B.x,y2 = B.y;
    CGFloat k = x1 == x2 ? 1 : (y1-y2)/(x1-x2);
    CGFloat b = y1 - k*x1;
    CGFloat x = C.x;
    CGFloat y = k * x + b;
    return CGPointMake(x,y);
}
/// AB线上所有间距点
static inline NSArray * kj_findLineDots(CGPoint A,CGPoint B,CGFloat space){
    NSMutableArray *dots = [NSMutableArray array];
    CGFloat x1 = A.x,y1 = A.y;
    CGFloat x2 = B.x,y2 = B.y;
    CGFloat k = x1 == x2 ? 1 : (y1-y2)/(x1-x2);
    CGFloat b = y1 - k*x1;
    CGFloat AB = sqrt(pow(x1-x2,2) + pow(y1-y2,2));
    NSInteger count = AB / space;
    CGFloat x,y;
    CGPoint pt = CGPointZero;
    for (int i=0; i<=count; i++) {
        if (k==0) {
            x = space * i + x1;
            y = y1;
        }else{
            y = space * i * (y2-y1)/AB + y1;
            x = (y-b) / k;
        }
        pt = CGPointMake(x, y);
        [dots addObject:NSStringFromCGPoint(pt)];
    }
    if (CGPointEqualToPoint(pt,B)==false) {
        [dots addObject:NSStringFromCGPoint(B)];
    }
    return dots.mutableCopy;
}
/// 找出距离最近的点
- (CGPoint)kj_findShortestPointWithPoint:(CGPoint)pt1 Points:(NSArray*)points{
    CGPoint pt2 = CGPointFromString(points[0]);
    CGFloat lenght = sqrt(pow(pt1.x-pt2.x,2) + pow(pt1.y-pt2.y,2));
    return kj_findShortestPoint(pt1, points, lenght);
}
static inline CGPoint kj_findShortestPoint(CGPoint pt1,NSArray *points,CGFloat len){
    NSMutableArray *temp = [NSMutableArray arrayWithArray:points];
    for (NSString *str in points) {
        CGPoint pt2 = CGPointFromString(str);
        CGFloat lenght = sqrt(pow(pt1.x-pt2.x,2) + pow(pt1.y-pt2.y,2));
        if (lenght!=0 && lenght<len) {
            return kj_findShortestPoint(pt2, temp.mutableCopy, lenght);
        }else if (lenght>len) {
            [temp removeObject:str];
        }
    }
    temp = nil;
    return pt1;
}
#pragma mark - ExtendParameterBlock 扩展参数
- (KJReflectionImageView *(^)(UIView*))kAddView {
    return ^(UIView *view){
        [view addSubview:self];
        return self;
    };
}
- (KJReflectionImageView *(^)(KJInteriorVesselView*))kFloorVesselView {
    return ^(KJInteriorVesselView *view) {
        self.floorView = view;
        return self;
    };
}
- (KJReflectionImageView *(^)(kInteriorSizePerspectiveBlock))kCorrectImageBlock {
    return ^(kInteriorSizePerspectiveBlock block) {
        self.xxxblock = block;
        return self;
    };
}
@end
