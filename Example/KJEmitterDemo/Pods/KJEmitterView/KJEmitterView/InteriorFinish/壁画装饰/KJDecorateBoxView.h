//
//  KJDecorateBoxView.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/28.
//  Copyright © 2020 杨科军. All rights reserved.
//  墙壁装饰盒子 - 壁画、电箱、挂饰

#import <UIKit/UIKit.h>
#import "KJInteriorSuperclassView.h"
NS_ASSUME_NONNULL_BEGIN

@interface KJDecorateBoxView : KJInteriorSuperclassView
/// 是否开启绘制装饰
@property(nonatomic,assign) bool openDrawDecorateBox;

@end

NS_ASSUME_NONNULL_END
