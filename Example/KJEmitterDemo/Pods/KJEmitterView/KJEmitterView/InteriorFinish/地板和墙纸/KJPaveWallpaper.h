//
//  KJPaveWallpaper.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/20.
//  Copyright © 2020 杨科军. All rights reserved.
//  墙纸铺贴

#import <Foundation/Foundation.h>
#import "_KJIFinishTools.h"
NS_ASSUME_NONNULL_BEGIN

@interface KJPaveWallpaper : NSObject
/// 墙纸铺贴效果
+ (UIImage*)kj_wallpaperPaveWithMaterialImage:(UIImage*)xImage TiledType:(KJImageTiledType)type TargetImageSize:(CGSize)size Width:(CGFloat)w;
+ (UIImage*)kj_wallpaperPaveWithMaterialImage:(UIImage*)xImage TiledType:(KJImageTiledType)type TargetImageSize:(CGSize)size Row:(NSInteger)row Col:(NSInteger)col;
@end

NS_ASSUME_NONNULL_END
