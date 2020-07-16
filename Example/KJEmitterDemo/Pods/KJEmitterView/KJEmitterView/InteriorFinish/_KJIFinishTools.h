//
//  KJInteriorFinishTools.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/20.
//  Copyright © 2020 杨科军. All rights reserved.
//  装修公共方法类

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Accelerate/Accelerate.h>
#import "KJInteriorSaveDatasInfo.h"

NS_ASSUME_NONNULL_BEGIN
/// 像素粒子
@interface KJImagePixelInfo : NSObject
@property(nonatomic,strong) UIColor *pixelColor;/// 粒子颜色
@property(nonatomic,assign) CGPoint pixelPoint; /// 粒子坐标
@end
@interface _KJIFinishTools : NSObject
#pragma mark - 逻辑处理
/// 判断手势方向
+ (KJPanMoveDirectionType)kj_moveDirectionWithTranslation:(CGPoint)translation;
/// 确定滑动方向
+ (KJSlideDirectionType)kj_slideDirectionWithPoint:(CGPoint)point Point2:(CGPoint)point2;
/// 不同滑动方向转换为正确透视区域四点
+ (KJKnownPoints)kj_pointsWithKnownPoints:(KJKnownPoints)knownPoints BeginPoint:(CGPoint)beginPoint EndPoint:(CGPoint)endPoint DirectionType:(KJSlideDirectionType)directionType;
/// 平移之后透视点相对处理
+ (KJKnownPoints)kj_changePointsWithKnownPoints:(KJKnownPoints)points Translation:(CGPoint)translation;
/// 判断当前点是否在路径选区内
+ (bool)kj_confirmCurrentPointWithPoint:(CGPoint)point BezierPath:(UIBezierPath*)path;
/// 判断当前点是否在已知四点选区内
+ (bool)kj_confirmCurrentPointWithPoint:(CGPoint)point KnownPoints:(KJKnownPoints)points;
/// 判断当前点是否在Rect内
+ (bool)kj_confirmCurrentPointWithPoint:(CGPoint)point Rect:(CGRect)rect;
/// 获取对应的Rect
+ (CGRect)kj_rectWithPoints:(KJKnownPoints)points;
#pragma mark - 几何方程式
/// 已知AB和C点到B点的长度，求垂直AB的C点
+ (CGPoint)kj_perpendicularLineDotsWithPoint1:(CGPoint)A Point2:(CGPoint)B VerticalLenght:(CGFloat)len Positive:(BOOL)pos;
/// 已知ABCD，求AB与CD交点  备注：重合和平行返回（0,0）
+ (CGPoint)kj_linellaeCrosspointWithPoint1:(CGPoint)A Point2:(CGPoint)B Point3:(CGPoint)C Point4:(CGPoint)D;
/// 求两点线段长度
+ (CGFloat)kj_distanceBetweenPointsWithPoint1:(CGPoint)A Point2:(CGPoint)B;
/// 已知ABC，求AB线对应C的平行线上的点  y = kx + b
+ (CGPoint)kj_parallelLineDotsWithPoint1:(CGPoint)A Point2:(CGPoint)B Point3:(CGPoint)C;
/// 已知ABC，求C到AB线段的长度
+ (CGFloat)kj_dotToLineLenght:(CGPoint)A Point2:(CGPoint)B Point3:(CGPoint)C;
/// 椭圆求点方程
+ (CGPoint)kj_ovalPointWithRect:(CGRect)lpRect Angle:(CGFloat)angle;
#pragma mark - 图片处理
/// 获取图片指定区域
+ (UIImage*)kj_getImageAppointAreaWithImage:(UIImage*)image ImageAppointType:(KJImageAppointType)type CustomFrame:(CGRect)rect;
/// 旋转图片和镜像处理 orientation 图片旋转方向
+ (UIImage*)kj_rotationImageWithImage:(UIImage*)image Orientation:(UIImageOrientation)orientation;
/** 任意角度图片旋转 */
+ (UIImage*)kj_rotateImage:(UIImage*)image Radians:(CGFloat)radians;
/// 图片围绕任意点旋转任意角度
+ (UIImage*)kj_rotateImage:(UIImage*)image Rotation:(CGFloat)rotation Point:(CGPoint)point;
/// 将图片拆分为像素粒子，设置粒子的尺寸，是否忽略白色粒子或者黑色粒子
+ (NSArray<KJImagePixelInfo*>*)kj_resolutionImagePixel:(UIImage*)image PixelSize:(CGSize)pixelSize LoseWhite:(BOOL)loseWhite LoseBlack:(BOOL)loseBlack;
/// 矩形图扭曲变形成圆柱侧面图 - Up：是否向上
+ (UIImage*)kj_orthogonImageBecomeCylinderImage:(UIImage*)image Rect:(CGRect)rect Up:(BOOL)up;
/// 矩形图扭曲变形成椭圆图
+ (UIImage*)kj_orthogonImageBecomeOvalImage:(UIImage*)image Rect:(CGRect)rect;
/// 改变图片尺寸 - 缩小图片
+ (UIImage*)kj_changeImageSizeWithImage:(UIImage*)image SimpleImageWidth:(CGFloat)width;
/// 获取指定宽高的图片
+ (UIImage*)kj_changeImageSizeWithImage:(UIImage*)image SimpleImageSize:(CGSize)size;
/// 图片路径裁剪
+ (UIImage*)kj_clipImageWithImage:(UIImage*)image BezierPath:(UIBezierPath*)path ImageRect:(CGRect)rect;
/// 根据路径裁剪图片
+ (UIImage*)kj_clipAnyShapeImageWithImage:(UIImage*)image BezierPath:(UIBezierPath*)path;
/// 获取图片
+ (UIImage*)kj_getImageWithImageName:(NSString*)imageName;
/// 根据名字和类型获取图片数据
+ (UIImage*)kj_getImageWithType:(KJImageGetModeType)type ImageName:(NSString*)name;

@end

NS_ASSUME_NONNULL_END
