//
//  KJVesselView.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/12.
//  Copyright © 2020 杨科军. All rights reserved.
//  选区容器类

#import <UIKit/UIKit.h>
#import "KJSuspendedView.h"
#import "KJDecorateBoxView.h"
#import "KJSkirtingLineView.h"
#import "KJLamplightLayer.h"
#import "KJPaveImageView.h"
NS_ASSUME_NONNULL_BEGIN
@interface KJInteriorVesselView : UIView
extern NSString * const kInteriorVessel_Tableview; /// 容器表名
/// 壁画开关状态
@property(nonatomic,assign) bool openDrawDecorateBox;
/// 容器独有标签
@property(nonatomic,assign,readonly) NSUInteger saveNumber;
/// 是否为选中状态
@property(nonatomic,assign,readonly) bool selectState;
/// 容器最大尺寸
@property(nonatomic,assign,readonly) CGSize vesselSize;
/// 容器选区透视四点
@property(nonatomic,assign,readonly) KJKnownPoints knownPoints;
/// 外界选区路径
@property(nonatomic,strong,readonly) UIBezierPath *outsidePath;
/// 修改当前选中状态
- (void)kj_setSelectState:(bool)state;
/// 初始化 - 推荐使用，内部做懒加载处理和追加扩展参数
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points PerspectiveBlock:(kInteriorVesselPerspectiveBlock)block ExtendParameterBlock:(void(^_Nullable)(KJInteriorVesselView *obj))paramblock;
/// 初始化
- (instancetype)kj_initWithKnownPoints:(KJKnownPoints)points VesselNeedViewType:(KJVesselNeedViewType)type PerspectiveBlock:(kInteriorVesselPerspectiveBlock)block DEPRECATED_MSG_ATTRIBUTE("Please use new init [kj_initWithKnownPoints:PerspectiveBlock:ExtendParameterBlock:]");
/// 移动识别贴图，内部做回调处理透视图片
- (bool)kj_moveDiscernWithMaterialImage:(UIImage*)materialImage Point:(CGPoint)point VesselNeedViewType:(KJVesselNeedViewType)type;
/// 墙纸和地板点击铺贴，返回是否铺贴成功
- (bool)kj_tapPaveWithMaterialImage:(UIImage*)materialImage VesselNeedViewType:(KJVesselNeedViewType)type;
/// 处理灯光效果，内部做回调处理透视图片
- (void)kj_delLamplightWithLamplightModel:(KJLamplightModel*)lamplightModel UseSave:(bool)useSave;

#pragma mark - UI相关
/// 吊顶
@property(nonatomic,strong,readonly) KJSuspendedView *suspendedView;
/// 墙壁装饰
@property(nonatomic,strong,readonly) KJDecorateBoxView *decorateBoxView;
/// 四边踢脚线
@property(nonatomic,strong,readonly) KJSkirtingLineView *skirtingLineView;
/// 灯光个数
@property(nonatomic,strong,readonly) KJLamplightLayer *lamplightLayer;
/// 墙纸和地板载体，二者互斥
@property(nonatomic,strong,readonly) KJPaveImageView *paveImageView;

#pragma mark - ExtendParameterBlock 扩展参数
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kViewTag)(NSInteger);
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kFrame)(CGRect);
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kAddView)(UIView*);
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kBackgroundColor)(UIColor*);
/// 调试模式，默认关闭
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kTestPattern)(BOOL);
/// 容器独有数据存储标签，必须最先设置
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kSaveNumber)(NSUInteger);
/// 是否使用OpenCV透视，需要单独处理
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kUseOpenCV)(BOOL);
/// 外界选区路径
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kOutsidePath)(UIBezierPath*);
/// 是否根据外界选区路径裁剪墙纸和地板
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kClipPave)(BOOL);
/// 地板铺贴之后操作，针对用于倒影处理
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kPavedFloorBlock)(void(^)(KJVesselPavedType paveType));
/// 读取的数据赋值给外界UI，针对用于灯光处理
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kGetLamplightBlock)(void(^)(KJLamplightModel *model));
/// 当前容器选中状态改变
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kSelectStateBlock)(bool(^)(bool state));
/// 数据读取回调
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kGetDatasFmdbBlock)(kGetDatasFromFmdbSqlBlock);
/// 数据存储回调
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kSaveFmdbBlock)(kFmdbSqlBlock);
/// 数据长按删除回调处理
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kLongPressDelBlock)(kFmdbSqlBlock);
/// 长按删除事件响应
@property(nonatomic,strong,readonly) KJInteriorVesselView *(^kLongPressResponseBlock)(kResponseBlock);
@end

NS_ASSUME_NONNULL_END
