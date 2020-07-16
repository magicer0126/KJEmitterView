//
//  KJSaveDatasInfo.m
//  Pods
//
//  Created by 杨科军 on 2020/6/28.
//

#import "KJInteriorSaveDatasInfo.h"

@implementation KJInteriorSaveDatasInfo
- (instancetype)init{
    if (self==[super init]) {
        self.wallpaperInfo = [KJWallpaperInfo new];
        self.floorInfo = [KJFloorInfo new];
        self.lamplightModel = [KJLamplightModel new];
        self.suspendedInfo = [KJSuspendedInfo new];
    }
    return self;
}
+ (NSDictionary*)modelContainerPropertyGenericClass {
    return @{@"skirtingLineInfoTemps":KJSkirtingLineInfo.class,@"decorateBoxInfoTemps":KJDecorateBoxInfo.class};
}
@end
@implementation KJCustomInfo
@end
@implementation KJWallpaperInfo
@end
@implementation KJFloorInfo
@end
@implementation KJSkirtingLineInfo
@end
@implementation KJSuspendedFaceInfo
@end
@implementation KJSuspendedInfo
+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"suspendedFaceInfoTemps":KJSuspendedFaceInfo.class};
}
@end
@implementation KJDecorateBoxInfo
@end
@implementation KJLamplightModel
- (void)setLamplightNumber:(NSInteger)lamplightNumber{
    _lamplightNumber = lamplightNumber?:1;
}
- (void)setLamplightAngle:(CGFloat)lamplightAngle{
    _lamplightAngle = lamplightAngle>=360?fmodl(lamplightAngle,360):lamplightAngle;
}
@end
