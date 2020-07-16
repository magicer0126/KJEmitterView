//
//  KJInteriorFinishTools.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/20.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "_KJIFinishTools.h"
@implementation KJImagePixelInfo
@end
@implementation _KJIFinishTools

#pragma mark - 逻辑处理
/// 判断手势方向
+ (KJPanMoveDirectionType)kj_moveDirectionWithTranslation:(CGPoint)translation{
    CGFloat absX = fabs(translation.x);
    CGFloat absY = fabs(translation.y);
    // 设置滑动有效距离
    if (MAX(absX, absY) < 1.0) return 0;
    if (absY > absX) {
        if (translation.y<0) {
            return 1;//向上滑动
        }else{
            return 2;//向下滑动
        }
    }else if (absX > absY) {
        if (translation.x<0) {
            return 3;//向左滑动
        }else{
            return 4;//向右滑动
        }
    }
    return KJPanMoveDirectionTypeNoMove;
}
/// 确定滑动方向
+ (KJSlideDirectionType)kj_slideDirectionWithPoint:(CGPoint)point Point2:(CGPoint)point2{
    bool boo = (point.x - point2.x) < 0 ? true : false;
    bool booo= (point.y - point2.y) < 0 ? true : false;
    if (boo&booo) return KJSlideDirectionTypeLeftBottom;
    if (!boo&!booo) return KJSlideDirectionTypeRightTop;
    if (boo) return KJSlideDirectionTypeLeftTop;
    return KJSlideDirectionTypeRightBottom;
}
/// 不同滑动方向转换为正确透视区域四点
+ (KJKnownPoints)kj_pointsWithKnownPoints:(KJKnownPoints)knownPoints BeginPoint:(CGPoint)beginPoint EndPoint:(CGPoint)endPoint DirectionType:(KJSlideDirectionType)directionType{
    CGPoint A = knownPoints.PointA;
    CGPoint B = knownPoints.PointB;
    CGPoint C = knownPoints.PointC;
    CGPoint D = knownPoints.PointD;
    CGPoint E = beginPoint;
    CGPoint F = CGPointZero;
    CGPoint G = endPoint;
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
/// 平移之后透视点相对处理
+ (KJKnownPoints)kj_changePointsWithKnownPoints:(KJKnownPoints)points Translation:(CGPoint)translation{
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
/// 判断当前点是否在路径选区内
+ (bool)kj_confirmCurrentPointWithPoint:(CGPoint)point BezierPath:(UIBezierPath*)path{
    return [path containsPoint:point];
}
/// 判断当前点是否在已知四点选区内
+ (bool)kj_confirmCurrentPointWithPoint:(CGPoint)point KnownPoints:(KJKnownPoints)points{
    UIBezierPath *path = ({
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:points.PointA];
        [path addLineToPoint:points.PointB];
        [path addLineToPoint:points.PointC];
        [path addLineToPoint:points.PointD];
        [path closePath];
        path;
    });
    return [self kj_confirmCurrentPointWithPoint:point BezierPath:path];
}
/// 判断当前点是否在Rect内
+ (bool)kj_confirmCurrentPointWithPoint:(CGPoint)point Rect:(CGRect)rect{
    return CGRectContainsPoint(rect, point);
}
/// 获取对应的Rect
+ (CGRect)kj_rectWithPoints:(KJKnownPoints)points{
    NSArray *temp = @[NSStringFromCGPoint(points.PointA),
                      NSStringFromCGPoint(points.PointB),
                      NSStringFromCGPoint(points.PointC),
                      NSStringFromCGPoint(points.PointD)];
    CGFloat minX = points.PointA.x;
    CGFloat maxX = points.PointA.x;
    CGFloat minY = points.PointA.y;
    CGFloat maxY = points.PointA.y;
    CGPoint pt = CGPointZero;
    for (NSString *string in temp) {
        pt = CGPointFromString(string);
        minX = pt.x < minX ? pt.x : minX;
        maxX = pt.x > maxX ? pt.x : maxX;
        minY = pt.y < minY ? pt.y : minY;
        maxY = pt.y > maxY ? pt.y : maxY;
    }
    return CGRectMake(minX-1, minY-1, maxX - minX+2, maxY - minY+2);
}

#pragma mark - 几何方程式
/// 已知A、B两点和C点到B点的长度，求垂直AB的C点
+ (CGPoint)kj_perpendicularLineDotsWithPoint1:(CGPoint)A Point2:(CGPoint)B VerticalLenght:(CGFloat)len Positive:(BOOL)pos{
    return kj_perpendicularLineDots(A,B,len,pos);
}
static inline CGPoint kj_perpendicularLineDots(CGPoint A,CGPoint B,CGFloat len,BOOL positive){
    CGFloat x1 = A.x,y1 = A.y;
    CGFloat x2 = B.x,y2 = B.y;
    if (x1 == x2) {/// 垂直线
        return positive ? CGPointMake(x2 + len, y2) : CGPointMake(x2 - len, y2);
    }else if (y1 == y2) {/// 水平线
        return positive ? CGPointMake(x2, y2 + len) : CGPointMake(x2, y2 - len);
    }
    /// 既非垂直又非水平处理
    CGFloat k1 = (y1-y2)/(x1-x2);
    CGFloat k = -1/k1;
    CGFloat b = y2 - k*x2;
    /// 根据 len² = (x-x2)² + (y-y2)²  和  y = kx + b 推倒出x、y
    CGFloat t = k*k + 1;
    CGFloat g = k*(b-y2) - x2;
    CGFloat f = x2*x2 + (b-y2)*(b-y2);
    CGFloat m = g/t;
    CGFloat n = (len*len - f)/t + m*m;
    
    CGFloat xa = sqrt(n) - m;
    CGFloat ya = k * xa + b;
    CGFloat xb = -sqrt(n) - m;
    CGFloat yb = k * xb + b;
    if (positive) {
        return yb>ya ? CGPointMake(xb, yb) : CGPointMake(xa, ya);
    }else{
        return yb>ya ? CGPointMake(xa, ya) : CGPointMake(xb, yb);
    }
}
/// 已知ABCD，求AB与CD交点  备注：重合和平行返回（0,0）
+ (CGPoint)kj_linellaeCrosspointWithPoint1:(CGPoint)A Point2:(CGPoint)B Point3:(CGPoint)C Point4:(CGPoint)D{
    return kj_linellaeCrosspoint(A,B,C,D);
}
static inline CGPoint kj_linellaeCrosspoint(CGPoint A,CGPoint B,CGPoint C,CGPoint D){
    CGFloat x1 = A.x,y1 = A.y;
    CGFloat x2 = B.x,y2 = B.y;
    CGFloat x3 = C.x,y3 = C.y;
    CGFloat x4 = D.x,y4 = D.y;
    
    CGFloat k1 = (y1-y2)/(x1-x2);
    CGFloat k2 = (y3-y4)/(x3-x4);
    CGFloat b1 = y1-k1*x1;
    CGFloat b2 = y4-k2*x4;
    if (x1==x2&&x3!=x4) {
        return CGPointMake(x1, k2*x1+b2);
    }else if (x3==x4&&x1!=x2){
        return CGPointMake(x3, k1*x3+b1);
    }else if (x3==x4&&x1==x2){
        return CGPointZero;
    }else{
        if (y1==y2&&y3!=y4) {
            return CGPointMake((y1-b2)/k2, y1);
        }else if (y3==y4&&y1!=y2){
            return CGPointMake((y4-b1)/k1, y4);
        }else if (y3==y4&&y1==y2){
            return CGPointZero;
        }else{
            if (k1==k2){
                return CGPointZero;
            }else{
                CGFloat x = (b2-b1)/(k1-k2);
                CGFloat y = k2*x+b2;
                return CGPointMake(x, y);
            }
        }
    }
}
/// 求两点线段长度
+ (CGFloat)kj_distanceBetweenPointsWithPoint1:(CGPoint)A Point2:(CGPoint)B{
    return kj_distanceBetweenPoints(A,B);
}
static inline CGFloat kj_distanceBetweenPoints(CGPoint point1,CGPoint point2) {
    CGFloat deX = point2.x - point1.x;
    CGFloat deY = point2.y - point1.y;
    return sqrt(deX*deX + deY*deY);
};
/// 已知ABC，求AB线对应C的平行线上的点  y = kx + b
+ (CGPoint)kj_parallelLineDotsWithPoint1:(CGPoint)A Point2:(CGPoint)B Point3:(CGPoint)C{
    return kj_parallelLineDots(A,B,C);
}
static inline CGPoint kj_parallelLineDots(CGPoint A,CGPoint B,CGPoint C){
    CGFloat x1 = A.x,y1 = A.y;
    CGFloat x2 = B.x,y2 = B.y;
    CGFloat x3 = C.x,y3 = C.y;
    CGFloat k = 0;
    if (x1 == x2) k = 1;/// 水平线
    k = (y1-y2)/(x1-x2);
    CGFloat b = y3 - k*x3;
    CGFloat x = x1;
    CGFloat y = k * x + b;/// y = kx + b
    return CGPointMake(x, y);
}
/// 已知ABC，求C到AB线段的长度
+ (CGFloat)kj_dotToLineLenght:(CGPoint)A Point2:(CGPoint)B Point3:(CGPoint)C{
    return kj_dotToLineLenght(A,B,C);
}
/// 已知ABC，求C到AB线段的长度
static inline CGFloat kj_dotToLineLenght(CGPoint A,CGPoint B,CGPoint C){
    CGFloat x1 = A.x,y1 = A.y;
    CGFloat x2 = B.x,y2 = B.y;
    CGFloat x3 = C.x,y3 = C.y;
    CGFloat AB = sqrt(pow(x1-x2,2) + pow(y1-y2,2));
    CGFloat AC = sqrt(pow(x1-x3,2) + pow(y1-y3,2));
    CGFloat BC = sqrt(pow(x2-x3,2) + pow(y2-y3,2));
    return (AB*AC*BC)/(AC*AC+BC*BC);
}
/// 椭圆求点方程
+ (CGPoint)kj_ovalPointWithRect:(CGRect)lpRect Angle:(CGFloat)angle{
    double a = lpRect.size.width / 2.0f;
    double b = lpRect.size.height / 2.0f;
    if (a == 0 || b == 0) return CGPointMake(lpRect.origin.x, lpRect.origin.y);
    double radian = angle * M_PI / 180.0f;/// 弧度
    double yc = sin(radian);/// 获取弧度正弦值
    double xc = cos(radian);/// 获取弧度余弦值
    /// 获取曲率 r = ab/Sqrt((a.Sinθ)^2+(b.Cosθ)^2
    double radio = (a * b) / sqrt(pow(yc * a, 2.0) + pow(xc * b, 2.0));
    return CGPointMake(lpRect.origin.x + a + radio * xc, lpRect.origin.y + b + radio * yc);
}

#pragma mark - 图片处理
/** 获取图片指定区域 */
+ (UIImage*)kj_getImageAppointAreaWithImage:(UIImage*)image ImageAppointType:(KJImageAppointType)type CustomFrame:(CGRect)rect{
    CGFloat w = image.size.width;
    CGFloat h = image.size.height;
    switch (type) {
        case KJImageAppointTypeCustom:
            break;
        case KJImageAppointTypeTop21:
            rect = CGRectMake(0, 0, w, h/2.);
            break;
        case KJImageAppointTypeCenter21:
            rect = CGRectMake(0, h/4., w, h/2.);
            break;
        case KJImageAppointTypeBottom21:
            rect = CGRectMake(0, h/2., w, h/2.);
            break;
        case KJImageAppointTypeTop31:
            rect = CGRectMake(0, 0, w, h/3.);
            break;
        case KJImageAppointTypeCenter31:
            rect = CGRectMake(0, h/3., w, h/3.);
            break;
        case KJImageAppointTypeBottom31:
            rect = CGRectMake(0, h/3.*2, w, h/3.);
            break;
        case KJImageAppointTypeTop41:
            rect = CGRectMake(0, 0, w, h/4.);
            break;
        case KJImageAppointTypeCenter41:
            rect = CGRectMake(0, h/4., w, h/4.);
            break;
        case KJImageAppointTypeBottom41:
            rect = CGRectMake(0, h/4.*2, w, h/4.);
            break;
        case KJImageAppointTypeTop43:
            rect = CGRectMake(0, 0, w, h/4.*3);
            break;
        case KJImageAppointTypeCenter43:
            rect = CGRectMake(0, h/8., w, h/4.*3);
            break;
        case KJImageAppointTypeBottom43:
            rect = CGRectMake(0, h/4., w, h/4.*3);
            break;
        default:
            rect = CGRectMake(0, 0, w, h);
            break;
    }
    /// 获取裁剪图片区域 - 从原图片中取小图
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *img = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return img;
}
/** 旋转图片和镜像处理 orientation 图片旋转方向 */
+ (UIImage*)kj_rotationImageWithImage:(UIImage*)image Orientation:(UIImageOrientation)orientation{
    CGRect rect = CGRectZero;
    rect.size.width = CGImageGetWidth(image.CGImage);
    rect.size.height = CGImageGetHeight(image.CGImage);
    CGRect bounds = rect;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (orientation){
        case UIImageOrientationUp:
            break;
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeTranslation(rect.size.width,rect.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, rect.size.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeft:
            bounds = kj_swapWidthAndHeight(bounds);
            transform = CGAffineTransformMakeTranslation(0.0, rect.size.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeftMirrored:
            bounds = kj_swapWidthAndHeight(bounds);
            transform = CGAffineTransformMakeTranslation(rect.size.height,rect.size.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRight:
            bounds = kj_swapWidthAndHeight(bounds);
            transform = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored:
            bounds = kj_swapWidthAndHeight(bounds);
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
    }
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    switch (orientation){
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
        CGContextScaleCTM(context, -1.0, 1.0);
        CGContextTranslateCTM(context, -rect.size.height, 0.0);
        break;
        default:
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, 0.0, -rect.size.height);
        break;
    }

    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, image.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}
static inline CGRect kj_swapWidthAndHeight(CGRect rect){
    CGFloat swap = rect.size.width;
    rect.size.width  = rect.size.height;
    rect.size.height = swap;
    return rect;
}
/** 任意角度图片旋转 */
+ (UIImage*)kj_rotateImage:(UIImage*)image Radians:(CGFloat)radians{
    if (!(&vImageRotate_ARGB8888)) return nil;
    const size_t width  = image.size.width;
    const size_t height = image.size.height;
    const size_t bytesPerRow = width * 4;
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, space, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(space);
    if (!bmContext) return nil;
    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = height}, image.CGImage);
    UInt8 *data = (UInt8*)CGBitmapContextGetData(bmContext);
    if (!data){
        CGContextRelease(bmContext);
        return nil;
    }
    vImage_Buffer src  = {data, height, width, bytesPerRow};
    vImage_Buffer dest = {data, height, width, bytesPerRow};
    Pixel_8888 bgColor = {0, 0, 0, 0};
    vImageRotate_ARGB8888(&src, &dest, NULL, radians, bgColor, kvImageBackgroundColorFill);
    CGImageRef rotatedImageRef = CGBitmapContextCreateImage(bmContext);
    UIImage *newImg = [UIImage imageWithCGImage:rotatedImageRef];
    CGImageRelease(rotatedImageRef);
    CGContextRelease(bmContext);
    return newImg;
}
/// 图片围绕任意点旋转任意角度
+ (UIImage*)kj_rotateImage:(UIImage*)image Rotation:(CGFloat)rotation Point:(CGPoint)point{
    NSInteger num = (NSInteger)(floor(rotation));
    if (num == rotation && num % 360 == 0) return image;
    double radius = rotation * M_PI / 180;
    CGFloat w = image.size.width;
    CGFloat h = image.size.height;
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextTranslateCTM(bitmap, point.x, -point.y);
    CGContextRotateCTM(bitmap, radius);
    CGFloat x = -point.x;
    CGFloat y = -h + point.y;
    CGContextDrawImage(bitmap, CGRectMake(x, y, w, h), image.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
/// 将图片拆分为像素粒子，设置粒子的尺寸，是否忽略白色粒子或者黑色粒子
+ (NSArray<KJImagePixelInfo*>*)kj_resolutionImagePixel:(UIImage*)image PixelSize:(CGSize)pixelSize LoseWhite:(BOOL)loseWhite LoseBlack:(BOOL)loseBlack{
    CGImageRef imageRef = [image CGImage];
    NSUInteger width  = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4; /// 一个像素4字节
    NSUInteger bitsPerComponent = 8;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    /// 读取图片中的所有像素点数据
    unsigned char *_data = (unsigned char*)calloc(height*width*bytesPerPixel, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(_data, width, height, bitsPerComponent, bytesPerRow, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    //2. 读取像素粒子块
    NSMutableArray *temp = [NSMutableArray new];
    for (int y = 0; y < height; y+=pixelSize.height) {
        for (int x = 0; x < width; x+=pixelSize.width) {
            NSUInteger byteIndex = bytesPerRow*y + bytesPerPixel*x;
            /// 读取颜色值
            CGFloat red   = ((CGFloat)_data[byteIndex]) / 255.0f;
            CGFloat green = ((CGFloat)_data[byteIndex + 1]) / 255.0f;
            CGFloat blue  = ((CGFloat)_data[byteIndex + 2]) / 255.0f;
            CGFloat alpha = ((CGFloat)_data[byteIndex + 3]) / 255.0f;
            /// 要忽略的粒子
            if (alpha == 0 || (loseWhite && (red+green+blue == 3)) || (loseBlack && (red+green+blue == 0))) {
                continue;
            }
            KJImagePixelInfo *pixel = [KJImagePixelInfo new];
            pixel.pixelColor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            pixel.pixelPoint = CGPointMake(x, y);
            [temp addObject:pixel];
        }
    }
    free(_data);
    return temp.mutableCopy;
}
/// 矩形图扭曲变形成椭圆弧形图 - Up：是否向上
+ (UIImage*)kj_orthogonImageBecomeCylinderImage:(UIImage*)image Rect:(CGRect)rect Up:(BOOL)up{
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGRect ovalRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGSize pixelSize = CGSizeMake(2, 2);
    NSArray *temps = [self kj_resolutionImagePixel:image PixelSize:pixelSize LoseWhite:NO LoseBlack:NO];
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height+rect.size.height+4, 8, width*4, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    /// 数组倒序遍历绘制像素点
    if (up) {
        [temps enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(KJImagePixelInfo *pixel, NSUInteger idx, BOOL *stop) {
            CGFloat angle = pixel.pixelPoint.x * 1.0f / width * 180.0f;
            /// 计算椭圆坐标
            SEL selector = NSSelectorFromString(@"kj_ovalPointWithRect:Angle:");
            IMP imp = [self methodForSelector:selector];
            CGPoint (*func)(id, SEL, CGRect, CGFloat) = (void *)imp;
            CGPoint point = func(self, selector, ovalRect, angle);
            CGContextAddEllipseInRect(ctx, CGRectMake(pixel.pixelPoint.x, height - pixel.pixelPoint.y + point.y, 4, 4));
            const CGFloat *components = CGColorGetComponents(pixel.pixelColor.CGColor);
            CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], components[3]);
            CGContextFillPath(ctx);
        }];
    }else{
        [temps enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(KJImagePixelInfo *pixel, NSUInteger idx, BOOL *stop) {
            CGFloat angle = pixel.pixelPoint.x * 1.0f / width * 180.0f;
            /// 计算椭圆坐标
            SEL selector = NSSelectorFromString(@"kj_ovalPointWithRect:Angle:");
            IMP imp = [self methodForSelector:selector];
            CGPoint (*func)(id, SEL, CGRect, CGFloat) = (void *)imp;
            CGPoint point = func(self, selector, ovalRect, angle);
    //        CGPoint point = [self kj_ovalPointWithRect:CGRectMake(0, 0, rect.size.width, rect.size.height) Angle:angle];
    //        CGContextAddEllipseInRect(ctx, CGRectMake(pixel.pixelPoint.x, height - pixel.pixelPoint.y + point.y, 4, 4));
            CGContextAddEllipseInRect(ctx, CGRectMake(pixel.pixelPoint.x, height - pixel.pixelPoint.y - point.y + rect.size.height, 4, 4));
            const CGFloat *components = CGColorGetComponents(pixel.pixelColor.CGColor);
            CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], components[3]);
            CGContextFillPath(ctx);
        }];
    }
    temps = nil;
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    UIImage *newImage = [UIImage imageWithCGImage:cgImage];
    CGContextRelease(ctx);
    CGImageRelease(cgImage);
    return newImage;
}
/// 矩形图扭曲变形成椭圆图
+ (UIImage*)kj_orthogonImageBecomeOvalImage:(UIImage*)image Rect:(CGRect)rect{
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGRect ovalRect = CGRectMake(0, 0, rect.size.width, rect.size.height);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGSize pixelSize = CGSizeMake(2, 2);
    NSArray *temps = [self kj_resolutionImagePixel:image PixelSize:pixelSize LoseWhite:NO LoseBlack:NO];
    CGContextRef ctx = CGBitmapContextCreate(NULL, width, height+rect.size.height+4, 8, width*4, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(space);
    /// 数组倒序遍历绘制像素点
    [temps enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(KJImagePixelInfo *pixel, NSUInteger idx, BOOL *stop) {
        CGFloat angle = pixel.pixelPoint.x * 1.0f / width * 180.0f;
        /// 计算椭圆坐标
        SEL selector = NSSelectorFromString(@"kj_ovalPointWithRect:Angle:");
        IMP imp = [self methodForSelector:selector];
        CGPoint (*func)(id, SEL, CGRect, CGFloat) = (void *)imp;
        CGPoint point = func(self, selector, ovalRect, angle);
        CGFloat y = 0;
        if (pixel.pixelPoint.y>=height/2.) {
            y = height - pixel.pixelPoint.y - point.y + rect.size.height*2;
        }else{
            y = height - pixel.pixelPoint.y + point.y;
        }
        CGContextAddEllipseInRect(ctx, CGRectMake(pixel.pixelPoint.x, y, 4, 4));
        const CGFloat *components = CGColorGetComponents(pixel.pixelColor.CGColor);
        CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], components[3]);
        CGContextFillPath(ctx);
    }];
    temps = nil;
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    UIImage *newImage = [UIImage imageWithCGImage:cgImage];
    CGContextRelease(ctx);
    CGImageRelease(cgImage);
    return newImage;
}
/// 改变图片尺寸 - 缩小图片
+ (UIImage*)kj_changeImageSizeWithImage:(UIImage*)image SimpleImageWidth:(CGFloat)width{
    CGSize size = CGSizeMake(width, width * image.size.height / image.size.width);
    return [self kj_changeImageSizeWithImage:image SimpleImageSize:size];
}
/// 获取指定宽高的图片
+ (UIImage*)kj_changeImageSizeWithImage:(UIImage*)image SimpleImageSize:(CGSize)size{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0,size.width,size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
/// 图片路径裁剪
+ (UIImage*)kj_clipImageWithImage:(UIImage*)image BezierPath:(UIBezierPath*)path ImageRect:(CGRect)rect{
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [path addClip];
    [image drawInRect:CGRectMake(0, 0, rect.size.width, rect.size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
/// 根据路径裁剪图片
+ (UIImage*)kj_clipAnyShapeImageWithImage:(UIImage*)image BezierPath:(UIBezierPath*)path{
    CGRect myRect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, myRect);
    UIGraphicsBeginImageContextWithOptions(myRect.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawImage(context, myRect, imageRef);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    UIGraphicsEndImageContext();
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, path.CGPath);
    CGContextClip(context);
    [newImage drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    CGContextDrawPath(context, kCGPathFill);
    UIImage *rusImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rusImage;
}
/// 获取图片
+ (UIImage*)kj_getImageWithImageName:(NSString*)imageName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory=[paths objectAtIndex:0];//Documents目录
    NSString *filePath = [NSString stringWithFormat:@"%@/Images/%@.png",documentsDirectory,imageName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSData *imageData;
    //如果存在存储图片的文件，则根据路径取出图片
    if ([fileManager fileExistsAtPath:filePath]) {
        imageData = [NSData dataWithContentsOfFile:filePath];
    }
    UIImage * image = [UIImage imageWithData:imageData];
    return image;
}
/// 根据名字和类型获取图片数据
+ (UIImage*)kj_getImageWithType:(KJImageGetModeType)type ImageName:(NSString*)name{
    if (type == KJImageGetModeTypeResource) {
        return [UIImage imageNamed:name];
    }else if (type == KJImageGetModeTypeSandbox) {
        return [_KJIFinishTools kj_getImageWithImageName:name];
    }else if (type == KJImageGetModeTypeUrl) {
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:name]];
//        NSData *imageData = [self kj_getURLDatas:[NSURL URLWithString:name]];
        return [UIImage imageWithData:imageData];
    }
    return nil;
}
/// 同步执行 判断当前URL的数据
+ (NSData*)kj_getURLDatas:(NSURL*)url{
    __block NSData *_data = nil;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);//创建信号量初始值为0
    dispatch_group_async(dispatch_group_create(), queue, ^{
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"HEAD"];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            _data = data;
            dispatch_semaphore_signal(sem); //发送信号量 信号量+1
        }] resume];
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);//阻塞等待 信号量-1
    return _data;
}

@end
