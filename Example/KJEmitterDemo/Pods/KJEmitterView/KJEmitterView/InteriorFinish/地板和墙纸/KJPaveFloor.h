//
//  KJPaveFloor.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/20.
//  Copyright © 2020 杨科军. All rights reserved.
//  地板拼接效果

#import <Foundation/Foundation.h>
#import "_KJIFinishTools.h"

NS_ASSUME_NONNULL_BEGIN

@interface KJPaveFloor : NSObject
/// 线条颜色，默认黑色
@property (nonatomic,strong,class) UIColor *lineColor;
/// 线条宽度，默认为1px
@property (nonatomic,assign,class) CGFloat lineWidth;
/// 地板拼接效果
+ (UIImage*)kj_floorJointWithMaterialImage:(UIImage*)xImage Type:(KJImageFloorJointType)type TargetImageSize:(CGSize)size FloorWidth:(CGFloat)w OpenAcross:(BOOL)openAcross OpenVertical:(BOOL)openVertical;

@end

NS_ASSUME_NONNULL_END
