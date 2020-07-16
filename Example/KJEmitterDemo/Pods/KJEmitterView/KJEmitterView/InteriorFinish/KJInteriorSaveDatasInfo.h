//
//  KJSaveDatasInfo.h
//  Pods
//
//  Created by 杨科军 on 2020/6/28.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "_KJInteriorType.h"
#import "UIImage+KJInteriorExtendParameter.h"
NS_ASSUME_NONNULL_BEGIN
/// 数据模型
@class KJLamplightModel,KJSuspendedInfo,KJDecorateBoxInfo;
@class KJFloorInfo,KJWallpaperInfo,KJSkirtingLineInfo;
@interface KJInteriorSaveDatasInfo : NSObject
/// 当前操作容器类型
@property(nonatomic,assign) KJVesselNeedViewType vesselNeedType;
/// 墙纸模型
@property(nonatomic,strong) KJWallpaperInfo *_Nullable wallpaperInfo;
/// 地板模型
@property(nonatomic,strong) KJFloorInfo *_Nullable floorInfo;
/// 踢脚线模型
@property(nonatomic,strong) NSArray<KJSkirtingLineInfo*>*skirtingLineInfoTemps;
/// 壁画模型
@property(nonatomic,strong) NSArray<KJDecorateBoxInfo*>*decorateBoxInfoTemps;
/// 吊顶模型
@property(nonatomic,strong) KJSuspendedInfo *_Nullable suspendedInfo;
/// 灯光模型
@property(nonatomic,strong) KJLamplightModel *_Nullable lamplightModel;
@end

/// 通用模型
@interface KJCustomInfo : NSObject
@property(nonatomic,strong) NSString *imageName; /// 图片名称路径
@property(nonatomic,assign) KJImageGetModeType imageGetModeType; /// 图片获取方式
@property(nonatomic,strong) UIImage *_Nullable image; /// 图片
@end

/// 地板模型
@interface KJFloorInfo : KJCustomInfo
@property(nonatomic,assign) KJImageFloorJointType floorType; /// 地板拼接类型
@property(nonatomic,assign) bool openAcross; /// 是否开启横倒角
@property(nonatomic,assign) bool openVertical;/// 是否开启竖倒角
@end

/// 墙纸模型
@interface KJWallpaperInfo : KJCustomInfo
@property(nonatomic,assign) KJImageTiledType wallpaperType; /// 墙纸铺贴类型
@property(nonatomic,assign) bool displayWallpaper; /// 是否显示为墙纸
@end

/// 踢脚线模型
@interface KJSkirtingLineInfo : KJCustomInfo
@property(nonatomic,assign) CGFloat lenght;/// 脚线高度或者宽度
@property(nonatomic,assign) KJSkirtingLineType skirtingLineType;/// 脚线位置
@end

/// 吊顶每个面模型
@interface KJSuspendedFaceInfo : KJCustomInfo
@property(nonatomic,assign) NSInteger sixMark;/// 对应的六个面
@end
/// 吊顶模型
@interface KJSuspendedInfo : NSObject
@property(nonatomic,assign) KJDarwShapeType shapeType;/// 所画物体形状
@property(nonatomic,strong) NSString *topA,*botA;
@property(nonatomic,strong) NSString *topB,*botB;
@property(nonatomic,strong) NSString *topC,*botC;
@property(nonatomic,strong) NSString *topD,*botD;
@property(nonatomic,assign) CGFloat lineLenght; /// 线条长度
@property(nonatomic,assign) CGFloat ovalLen; /// 椭圆上下方向处理
@property(nonatomic,strong) NSArray<KJSuspendedFaceInfo*>*suspendedFaceInfoTemps;
@end

/// 壁画模型
@interface KJDecorateBoxInfo : KJCustomInfo
@property(nonatomic,strong) NSString *pointA;
@property(nonatomic,strong) NSString *pointB;
@property(nonatomic,strong) NSString *pointC;
@property(nonatomic,strong) NSString *pointD;
@end

/// 灯光模型
@interface KJLamplightModel : KJCustomInfo
@property(nonatomic,assign) NSInteger lamplightNumber;/// 灯光个数
@property(nonatomic,assign) CGFloat lamplightAngle;/// 灯光角度，0 - 360°
@property(nonatomic,assign) CGFloat lamplightMoveX;/// 灯光平移X轴
@property(nonatomic,assign) CGFloat lamplightMoveY;/// 灯光平移Y轴
@property(nonatomic,assign) CGFloat lamplightSpace;/// 灯光间隔，画布宽度5% - 50%
@property(nonatomic,assign) CGFloat lamplightSize; /// 灯光大小，画布宽度5% - 50%
@end


NS_ASSUME_NONNULL_END
