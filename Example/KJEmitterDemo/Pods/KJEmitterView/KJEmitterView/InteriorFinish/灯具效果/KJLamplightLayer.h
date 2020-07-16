//
//  KJLamplightLayer.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/3.
//  Copyright © 2020 杨科军. All rights reserved.
//  灯具效果展示

#import <QuartzCore/QuartzCore.h>
#import "_KJIFinishTools.h"
@class KJLamplightModel;
NS_ASSUME_NONNULL_BEGIN
@interface KJLamplightLayer : CALayer
/// 改变角度后回调灯光大小处理
@property(nonatomic,readwrite,copy) void(^kAngleChangeSizeBlock)(CGFloat lamplightSize);
/// 存储回调
@property(nonatomic,readwrite,copy) kInteriorDatasInfoBlock saveblock;
/// 画布宽度
@property(nonatomic,assign,readonly) CGFloat canvasWidth;
/// 最大矩形框
@property(nonatomic,assign) CGRect maxRect;
/// 初始化
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points;
/// 重置
- (void)kj_clearLayers;
/// 处理灯光效果
- (UIImage*)kj_addLayerWithLamplightModel:(KJLamplightModel*)lamplightModel PerspectiveBlock:(UIImage *(^)(KJKnownPoints points,UIImage *jointImage))block;
/// 存储
- (void)kj_lamplightSaveWithLamplightModel:(KJLamplightModel*)lamplightModel;
@end

NS_ASSUME_NONNULL_END
