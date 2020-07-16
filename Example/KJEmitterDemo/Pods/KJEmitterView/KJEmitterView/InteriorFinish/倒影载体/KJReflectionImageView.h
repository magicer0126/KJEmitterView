//
//  KJReflectionImageView.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/7/8.
//  Copyright © 2020 杨科军. All rights reserved.
//  倒影载体

#import <UIKit/UIKit.h>
#import "KJInteriorVesselView.h"
NS_ASSUME_NONNULL_BEGIN

@interface KJReflectionImageView : UIImageView
/// 初始化
- (instancetype)kj_initWithVesselView:(KJInteriorVesselView*)vesselView ExtendParameterBlock:(void(^_Nullable)(KJReflectionImageView *obj))paramblock;
#pragma mark - ExtendParameterBlock 扩展参数
@property(nonatomic,strong,readonly) KJReflectionImageView *(^kAddView)(UIView*);
/// 地板容器
@property(nonatomic,strong,readonly) KJReflectionImageView *(^kFloorVesselView)(KJInteriorVesselView*);
/// 透视和矫正处理
@property(nonatomic,strong,readonly) KJReflectionImageView *(^kCorrectImageBlock)(kInteriorSizePerspectiveBlock);

@end

NS_ASSUME_NONNULL_END
