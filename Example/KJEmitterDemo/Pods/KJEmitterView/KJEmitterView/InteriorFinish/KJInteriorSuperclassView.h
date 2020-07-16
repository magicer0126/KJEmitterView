//
//  KJInteriorSuperclassView.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/5/28.
//  Copyright © 2020 杨科军. All rights reserved.
//  装修父类

#import <UIKit/UIKit.h>
#import "_KJIFinishTools.h"
NS_ASSUME_NONNULL_BEGIN
@interface KJInteriorSuperclassView : UIView
/// 调试模式，绘制四点半透明红色选区
@property(nonatomic,assign) bool testPattern;
/// 是否使用OpenCV透视，需要单独处理
@property(nonatomic,assign) bool opencv;
/// 容器的存放类
@property(nonatomic,strong) UIView *vesselSuperview;
/// 所绘虚线颜色，默认黑色
@property(nonatomic,strong) UIColor *dashPatternColor;
/// 所绘虚线宽度，默认1px
@property(nonatomic,assign) CGFloat dashPatternWidth;
/// 外界区域四点
@property(nonatomic,assign) KJKnownPoints knownPoints;
/// 外界四点的最大矩形框
@property(nonatomic,assign) CGRect maxKnownRect;
/// 外界选区的路径
@property(nonatomic,strong) UIBezierPath *outsidePath;
/// 透视处理回调处理过后的透视图片
@property(nonatomic,readwrite,copy) UIImage *(^kPerspectiveBlock)(KJKnownPoints points,UIImage *image);
/// 长按删除处理
@property(nonatomic,readwrite,copy) kInteriorDatasInfoBlock longblock;
/// 初始化方法 -- 可携带扩展参数
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points ExtendParameterBlock:(void(^_Nullable)(KJInteriorSuperclassView *obj))block;
/// 改变KnownPoints的已知四点的相关操作
- (void)kj_changeKnownPoints:(KJKnownPoints)points;
/// 重置
- (void)kj_clearLayers;
/// 加载数据库数据
- (void)kj_loadFmdbDatasInfoWithSaveDatasInfo:(KJInteriorSaveDatasInfo*)info;
/// 贴图并且固定图片到相应区域，回调透视图片处理
- (bool)kj_chartletAndFixationWithMaterialImage:(UIImage*)materialImage Point:(CGPoint)point PerspectiveBlock:(UIImage *(^)(KJKnownPoints points,UIImage *image))block;
/// 调用存储处理的回调
- (void)kj_saveToFmdbBlock;

#pragma mark - 子类处理
/// 判断触摸点手势是否需要被使用
- (bool)kj_gestureIsUsedWithPoint:(CGPoint)point;
/// 点击处理
- (void)kj_tapWithPoint:(CGPoint)tempPoint;
/// 开始触摸的点
- (void)kj_moveWithStartPoint:(CGPoint)tempPoint;
/// 移动处理
- (void)kj_moveWithChangePoint:(CGPoint)tempPoint;
/// 移动结束
- (void)kj_moveWithEndPoint:(CGPoint)tempPoint;
/// 长按删除处理
- (void)kj_longPressDelPoint:(CGPoint)tempPoint SaveDatasInfo:(KJInteriorSaveDatasInfo*)info;
/// 获取到存储数据
- (void)kj_setSaveDatasInfos:(KJInteriorSaveDatasInfo*)info PerspectiveBlock:(kInteriorPerspectiveBlock)block;
/// 子类传递数据至父类
- (KJInteriorSaveDatasInfo*)kj_getSaveDatasInfo;

#pragma mark - ExtendParameterBlock 扩展参数
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kViewTag)(NSInteger);
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kAddView)(UIView*);
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kBackgroundColor)(UIColor*);
/// 外界选区路径
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kOutsidePath)(UIBezierPath*);
/// 是否使用OpenCV透视，需要单独处理
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kUseOpenCV)(BOOL);
/// 最小移动有效距离，默认为1px
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kMinLenght)(CGFloat);
/// 是否限制最大滑动区域，默认开启限制
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kOpenMaxRegion)(BOOL);
/// 透视图处理
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kGetInfosPerspectiveBlock)(kInteriorPerspectiveBlock);
/// 贴图成功处理，告知外界数据存储
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kChartletImageBlock)(kInteriorDatasInfoBlock);
/// 长按删除处理 ，同时删除数据库数据
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kLongPressDelBlock)(kInteriorDatasInfoBlock);
/// 长按事件响应，外界判断是否执行删除命令
@property(nonatomic,strong,readonly) KJInteriorSuperclassView *(^kLongPressResponseBlock)(kLongPressResponseBlock);
@end

NS_ASSUME_NONNULL_END
