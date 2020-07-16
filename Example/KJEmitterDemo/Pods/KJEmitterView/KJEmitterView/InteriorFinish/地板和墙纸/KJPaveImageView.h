//
//  KJPaveImageView.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/29.
//  Copyright © 2020 杨科军. All rights reserved.
//  墙纸铺贴和地板拼接载体

#import <UIKit/UIKit.h>
#import "_KJIFinishTools.h"
NS_ASSUME_NONNULL_BEGIN

@interface KJPaveImageView : UIImageView
/// 当前地板和墙纸铺贴类型
@property(nonatomic,assign) KJVesselPavedType paveType;
@end

NS_ASSUME_NONNULL_END
