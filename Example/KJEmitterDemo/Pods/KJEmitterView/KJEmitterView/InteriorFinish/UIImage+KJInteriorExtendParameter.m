//
//  UIImage+KJInteriorExtendParameter.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/10.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "UIImage+KJInteriorExtendParameter.h"

@implementation UIImage (KJInteriorExtendParameter)
//- (bool)kj_opencv{
//    return [objc_getAssociatedObject(self, @selector(kj_opencv)) integerValue];
//}
//- (void)setKj_opencv:(bool)kj_opencv{
//    objc_setAssociatedObject(self, @selector(kj_opencv), @(kj_opencv), OBJC_ASSOCIATION_ASSIGN);
//}
- (NSString*)kj_imageName{
    return objc_getAssociatedObject(self, @selector(kj_imageName));
}
- (void)setKj_imageName:(NSString*)kj_imageName{
    objc_setAssociatedObject(self, @selector(kj_imageName), kj_imageName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (KJImageGetModeType)kj_imageGetModeType{
    return [objc_getAssociatedObject(self, @selector(kj_imageGetModeType)) integerValue];
}
- (void)setKj_imageGetModeType:(KJImageGetModeType)kj_imageGetModeType{
    objc_setAssociatedObject(self, @selector(kj_imageGetModeType), @(kj_imageGetModeType), OBJC_ASSOCIATION_ASSIGN);
}
- (KJImageTiledType)kj_wallpaperType{
    return [objc_getAssociatedObject(self, @selector(kj_wallpaperType)) integerValue];
}
- (void)setKj_wallpaperType:(KJImageTiledType)kj_wallpaperType{
    objc_setAssociatedObject(self, @selector(kj_wallpaperType), @(kj_wallpaperType), OBJC_ASSOCIATION_ASSIGN);
}
- (KJImageFloorJointType)kj_floorType{
    return [objc_getAssociatedObject(self, @selector(kj_floorType)) integerValue];
}
- (void)setKj_floorType:(KJImageFloorJointType)kj_floorType{
    objc_setAssociatedObject(self, @selector(kj_floorType), @(kj_floorType), OBJC_ASSOCIATION_ASSIGN);
}
- (UIColor*)kj_floorLineColor{
    return objc_getAssociatedObject(self, @selector(kj_floorLineColor));
}
- (void)setKj_floorLineColor:(UIColor*)kj_floorLineColor{
    objc_setAssociatedObject(self, @selector(kj_floorLineColor), kj_floorLineColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CGFloat)kj_floorLineWidth{
    return [objc_getAssociatedObject(self, @selector(kj_floorLineWidth)) doubleValue];
}
- (void)setKj_floorLineWidth:(CGFloat)kj_floorLineWidth{
    objc_setAssociatedObject(self, @selector(kj_floorLineWidth), @(kj_floorLineWidth), OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (bool)kj_floorOpenAcross{
    return [objc_getAssociatedObject(self, @selector(kj_floorOpenAcross)) integerValue];
}
- (void)setKj_floorOpenAcross:(bool)kj_floorOpenAcross{
    objc_setAssociatedObject(self, @selector(kj_floorOpenAcross), @(kj_floorOpenAcross), OBJC_ASSOCIATION_ASSIGN);
}
- (bool)kj_floorOpenVertical{
    return [objc_getAssociatedObject(self, @selector(kj_floorOpenVertical)) integerValue];
}
- (void)setKj_floorOpenVertical:(bool)kj_floorOpenVertical{
    objc_setAssociatedObject(self, @selector(kj_floorOpenVertical), @(kj_floorOpenVertical), OBJC_ASSOCIATION_ASSIGN);
}
@end
