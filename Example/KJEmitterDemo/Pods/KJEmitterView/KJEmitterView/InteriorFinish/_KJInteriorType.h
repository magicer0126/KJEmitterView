//
//  _KJInteriorType.h
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/6.
//  Copyright © 2020 杨科军. All rights reserved.
//  枚举文件夹

#ifndef KJInteriorType_h
#define KJInteriorType_h
#define ksw ([UIScreen mainScreen].bounds.size.width)
#define ksh ([UIScreen mainScreen].bounds.size.height)
#pragma mark - 枚举管理
/// 透视选区四点
typedef struct KJKnownPoints {
    CGPoint PointA;
    CGPoint PointB;
    CGPoint PointC;
    CGPoint PointD;
}KJKnownPoints;
/// 滑动方向
typedef NS_ENUM(NSInteger, KJSlideDirectionType) {
    KJSlideDirectionTypeLeftBottom, /// 左下
    KJSlideDirectionTypeRightBottom,/// 右下
    KJSlideDirectionTypeRightTop,   /// 右上
    KJSlideDirectionTypeLeftTop,    /// 左上
};
/// 手势移动方向
typedef NS_ENUM(NSInteger, KJPanMoveDirectionType) {
    KJPanMoveDirectionTypeNoMove = 0,/// 没有移动
    KJPanMoveDirectionTypeTop,   /// 向上
    KJPanMoveDirectionTypeBottom,/// 向下
    KJPanMoveDirectionTypeLeft,  /// 向左
    KJPanMoveDirectionTypeRight, /// 向右
};
/// 图片指定区域
typedef NS_ENUM(NSInteger, KJImageAppointType) {
    KJImageAppointTypeCustom,   /// 自定义区域，需要传入指定frame
    KJImageAppointTypeTop21,    /// 顶部二分之一
    KJImageAppointTypeCenter21, /// 中间二分之一
    KJImageAppointTypeBottom21, /// 底部二分之一
    KJImageAppointTypeTop31,    /// 顶部三分之一
    KJImageAppointTypeCenter31, /// 中间三分之一
    KJImageAppointTypeBottom31, /// 底部三分之一
    KJImageAppointTypeTop41,    /// 顶部四分之一
    KJImageAppointTypeCenter41, /// 中间四分之一
    KJImageAppointTypeBottom41, /// 底部四分之一
    KJImageAppointTypeTop43,    /// 顶部四分之三
    KJImageAppointTypeCenter43, /// 中间四分之三
    KJImageAppointTypeBottom43, /// 底部四分之三
};
/// 踢脚线位置
typedef NS_ENUM(NSInteger, KJSkirtingLineType) {
    KJSkirtingLineTypeUnknown= 1 << 0,/// 未知边
    KJSkirtingLineTypeTop    = 1 << 1,/// 上边
    KJSkirtingLineTypeBottom = 1 << 2,/// 下边
    KJSkirtingLineTypeLeft   = 1 << 3,/// 左边
    KJSkirtingLineTypeRight  = 1 << 4,/// 右边
};
/// 吊顶所画物体形状
typedef NS_ENUM(NSInteger, KJDarwShapeType) {
    KJDarwShapeTypeQuadrangle = 0, /// 四边形
    KJDarwShapeTypeOval, /// 椭圆
};
/// 吊顶凹凸方向
typedef NS_ENUM(NSInteger, KJConcaveConvexType) {
    KJConcaveConvexTypeConcave = 0,/// 向内凹
    KJConcaveConvexTypeConvex, /// 向外凸
};
/// 墙纸对花效果
typedef NS_ENUM(NSInteger, KJImageTiledType) {
    KJImageTiledTypeCustom = 0,  /// 默认，平铺
    KJImageTiledTypeAcross,  /// 横对花
    KJImageTiledTypeVertical,/// 竖对花
    KJImageTiledTypePositively, /// 正斜对花
    KJImageTiledTypeBackslash,  /// 反斜对花
};
static NSString * const _Nonnull KJImageTiledTypeStringMap[] = {
    [KJImageTiledTypeCustom]     = @"平铺",
    [KJImageTiledTypeAcross]     = @"横对花",
    [KJImageTiledTypeVertical]   = @"竖对花",
    [KJImageTiledTypePositively] = @"正斜对花",
    [KJImageTiledTypeBackslash]  = @"反斜对花",
};
/// 地板拼接效果
typedef NS_ENUM(NSInteger, KJImageFloorJointType) {
    KJImageFloorJointTypeCustom = 0, /// 默认，正常平铺（艺术拼法）
    KJImageFloorJointTypeDouble,     /// 两拼法
    KJImageFloorJointTypeThree,      /// 三拼法
    KJImageFloorJointTypeLengthMix,  /// 长短混合
    KJImageFloorJointTypeClassical,  /// 古典拼法
    KJImageFloorJointTypeConcaveConvex,  /// 凹凸效果
    KJImageFloorJointTypeLongShortThird, /// 长短三分之一效果
};
/// 选区容器类需要添加的控件
typedef NS_OPTIONS(NSInteger, KJVesselNeedViewType) {
    KJVesselNeedViewTypeSkirtingLine= 1 << 0,/// 四边踢脚线
    KJVesselNeedViewTypeSuspended   = 1 << 1,/// 吊顶
    KJVesselNeedViewTypeDecorateBox = 1 << 2,/// 壁纸装饰
    KJVesselNeedViewTypeLamplight   = 1 << 3,/// 灯光个数
    KJVesselNeedViewTypeWallpaper   = 1 << 4,/// 墙纸
    KJVesselNeedViewTypeFloor       = 1 << 5,/// 地板
};
/// 选区当前铺设的类型，墙纸or地板
typedef NS_OPTIONS(NSInteger, KJVesselPavedType) {
    KJVesselPavedTypeNone = 0,/// 都没铺设
    KJVesselPavedTypeFloor,   /// 地板
    KJVesselPavedTypeWallpaper,/// 墙纸
};

#pragma mark - 回调声明管理
@class KJInteriorSaveDatasInfo,KJInteriorVesselView;
/// 透视图处理
typedef UIImage *_Nullable(^kInteriorPerspectiveBlock)(KJKnownPoints points,UIImage * _Nonnull image);
typedef UIImage *_Nullable(^kInteriorSizePerspectiveBlock)(CGSize targetSize,KJKnownPoints points,UIImage * _Nonnull image);
typedef UIImage *_Nullable(^kInteriorVesselPerspectiveBlock)(KJInteriorVesselView * _Nullable vesselView,KJVesselNeedViewType vesselType,KJKnownPoints points,UIImage * _Nullable image);
/// 长按删除响应事件处理
typedef BOOL (^kLongPressResponseBlock)(CGPoint point);
typedef BOOL (^kResponseBlock)(KJVesselNeedViewType vesselNeedType,CGPoint point);
/// 模型数据传递处理
typedef void (^kInteriorDatasInfoBlock)(KJInteriorSaveDatasInfo * _Nullable info);
/// 数据库存储和替换处理
typedef BOOL(^kFmdbSqlBlock)(NSString * _Nullable tableview,NSString * _Nullable saveNumber,KJInteriorSaveDatasInfo * _Nullable info);
/// 获取数据库数据
typedef KJInteriorSaveDatasInfo *_Nullable(^kGetDatasFromFmdbSqlBlock)(NSString * _Nullable tableview,NSString * _Nullable saveNumber);

#endif /* KJInteriorType_h */
