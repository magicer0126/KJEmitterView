//
//  UIImage+KJInteriorExtendParameter.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/10.
//  Copyright © 2020 杨科军. All rights reserved.
//  装修类图片的扩展参数

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "_KJInteriorType.h"
NS_ASSUME_NONNULL_BEGIN
/// 图片获取方式
typedef NS_ENUM(NSInteger, KJImageGetModeType) {
    KJImageGetModeTypeSandbox  = 0,/// 沙盒路径方式
    KJImageGetModeTypeResource = 1,/// 资源包 imageNamed
    KJImageGetModeTypeUrl      = 2,/// 网络图片
};
@interface UIImage (KJInteriorExtendParameter)
//@property(nonatomic,assign) bool kj_opencv;/// 是否使用OpenCV透视，需要单独处理
@property(nonatomic,strong) NSString *kj_imageName; /// 图片名称路径
@property(nonatomic,assign) KJImageGetModeType kj_imageGetModeType; /// 图片获取方式
@property(nonatomic,assign) KJImageTiledType kj_wallpaperType; /// 墙纸铺贴类型

#pragma mark - 地板铺贴相关
@property(nonatomic,assign) KJImageFloorJointType kj_floorType; /// 地板铺贴类型
@property(nonatomic,strong) UIColor *kj_floorLineColor;/// 地板线条颜色
@property(nonatomic,assign) CGFloat kj_floorLineWidth;/// 地板线条宽度
@property(nonatomic,assign) bool kj_floorOpenAcross; /// 是否开启横倒角
@property(nonatomic,assign) bool kj_floorOpenVertical;/// 是否开启竖倒角
@end

NS_ASSUME_NONNULL_END

