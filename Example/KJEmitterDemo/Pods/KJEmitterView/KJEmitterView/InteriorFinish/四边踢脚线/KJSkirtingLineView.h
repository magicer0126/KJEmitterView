//
//  KJSkirtingLineView.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/27.
//  Copyright © 2020 杨科军. All rights reserved.
//  四边踢脚线处理 - 四周边线

#import <UIKit/UIKit.h>
#import "KJInteriorSuperclassView.h"
NS_ASSUME_NONNULL_BEGIN

@interface KJSkirtingLineView : KJInteriorSuperclassView
/// 指定边初始化
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points SkirtingLineType:(KJSkirtingLineType)type ExtendParameterBlock:(void(^_Nullable)(KJInteriorSuperclassView *obj))block;

@end

NS_ASSUME_NONNULL_END
