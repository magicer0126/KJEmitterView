//
//  UIImage+KJBlurImage.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/23.
//  Copyright © 2020 杨科军. All rights reserved.
//  模糊和着色效果处理图像

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (KJBlurImage)
/// 获取亮色模糊图像
- (UIImage*)kj_blurLightImage;
/// 获取亮色模糊图像
- (UIImage*)kj_blurExtraLightImage;
/// 获取黑色模糊图像
- (UIImage*)kj_blurDarkImage;
/// 获取指定颜色模糊图像
- (UIImage*)kj_blurTintImageWithColor:(UIColor*)tintColor;
/// 获取模糊的图像 - 黑色模糊图像
- (UIImage*)kj_blurImage;
/// 获取被另一张图像掩盖的模糊图像
- (UIImage*)kj_blurImageWithMask:(UIImage*)maskImage;
/// 获取模糊的图像，可设置模糊半径
- (UIImage*)kj_blurImageWithRadius:(CGFloat)radius;
/// 在指定的尺寸上获取模糊的图像
- (UIImage*)kj_blurImageWithFrame:(CGRect)frame;
@end

NS_ASSUME_NONNULL_END
