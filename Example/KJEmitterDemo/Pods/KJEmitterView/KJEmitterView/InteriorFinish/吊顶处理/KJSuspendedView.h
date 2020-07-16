//
//  KJSuspendedView.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/13.
//  Copyright © 2020 杨科军. All rights reserved.
//  吊顶处理

#import <UIKit/UIKit.h>
#import "KJInteriorSuperclassView.h"

NS_ASSUME_NONNULL_BEGIN

@interface KJSuspendedView : KJInteriorSuperclassView
/// 所画物体形状，默认四边形
@property(nonatomic,assign) KJDarwShapeType shapeType;
/// 限制下拉最大距离，默认100px
@property(nonatomic,assign) CGFloat maxLen;
/// 是否开启绘制吊顶
@property(nonatomic,assign) bool openDrawSuspended;

@end

NS_ASSUME_NONNULL_END
