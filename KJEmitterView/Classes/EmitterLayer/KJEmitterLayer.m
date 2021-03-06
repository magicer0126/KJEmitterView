//
//  KJEmitterLayer.m
//  KJEmitterView
//
//  Created by 杨科军 on 2019/8/27.
//  Copyright © 2019 杨科军. All rights reserved.
//

#import "KJEmitterLayer.h"
#import "KJEmitterImagePixel.h"
@interface KJEmitterLayer ()
@property(nonatomic,strong) CADisplayLink *displayLink;
@property(nonatomic,assign) CGFloat animationTime;
@property(nonatomic,strong) NSArray *temps;

@property(nonatomic,strong) UIImage *image; ///
@property(nonatomic,assign) CGFloat lastPixelWaitTime; /// 完结粒子最后的等待时间，默认1秒

@property(nonatomic,assign) CGFloat pixelRandomPointRange; //[-n,n),n>=0,粒子随机范围
@property(nonatomic,assign) NSInteger pixelMaximum; /// 每行/列最大粒子数,设为0时，即每个像素一个粒子
@property(nonatomic,assign) CGPoint pixelBeginPoint;//粒子出生位置，默认 (0,0)
@property(nonatomic,strong) UIColor *pixelColor; //改变粒子的颜色
@property(nonatomic,assign) BOOL ignoredBlack; //忽略黑色，黑色当做透明处理，默认为NO
@property(nonatomic,assign) BOOL ignoredWhite; //忽略白色，白色当做透明处理，默认为NO
/// 绘制完成之后的回调
@property(nonatomic,copy,class) KJEmitterLayerDrawCompleteBlock xxblock;

@end

@implementation KJEmitterLayer
static KJEmitterLayerDrawCompleteBlock _xxblock = nil;
+ (KJEmitterLayerDrawCompleteBlock)xxblock{
    if (_xxblock == nil) {
        _xxblock = ^void(void){ };
    }
    return _xxblock;
}
+ (void)setXxblock:(KJEmitterLayerDrawCompleteBlock)xxblock{
    if (xxblock != _xxblock) {
        _xxblock = [xxblock copy];
    }
}
// 初始化
+ (instancetype)createEmitterLayerWaitTime:(CGFloat)waitTime ImageBlock:(UIImage*(^)(KJEmitterLayer *obj))block CompleteBlock:(KJEmitterLayerDrawCompleteBlock)complete{
    KJEmitterLayer *layer = [[self alloc] init];
    [layer config];
    if (block) layer.image = block(layer);
    layer.image = layer.image?:[UIImage imageNamed:@"KJEmitterLayer.bundle/EmitterLayerImage"];
    layer.lastPixelWaitTime = waitTime ? waitTime : 1.0;
    [layer setDatas];
    self.xxblock = complete;
    return layer;
}
- (void)config{
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(emitteraAnimation:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    _animationTime = 0;
    _ignoredWhite = NO;
    _ignoredBlack = NO;
    _pixelBeginPoint = CGPointMake(0, 0);
    _pixelMaximum = 0;
}
- (void)setDatas{
    self.temps = [self kj_resolutionImageToPixelWithImage:self.image];
}
/// 对CALayer继承,CALayer重新绘制
- (void)drawInContext:(CGContextRef)ctx {
    NSInteger count = 0;
    for (KJEmitterImagePixel *pixel in self.temps) {
        if (pixel.delayTime > _animationTime) continue;
        CGFloat curTime = _animationTime - pixel.delayTime;
        if (curTime >= _lastPixelWaitTime + pixel.delayDuration) { //到达了目的地的粒子原地等待下没到达的粒子
            curTime  = _lastPixelWaitTime + pixel.delayDuration;
            count ++;
        }
        CGFloat curX = [self easeInOutQuad:curTime begin:_pixelBeginPoint.x end:pixel.point.x + self.bounds.size.width/2-CGImageGetWidth(_image.CGImage)/2 duration:_lastPixelWaitTime + pixel.delayDuration];
        CGFloat curY = [self easeInOutQuad:curTime begin:_pixelBeginPoint.y end:pixel.point.y + self.bounds.size.height/2 - CGImageGetHeight(_image.CGImage)/2 duration:_lastPixelWaitTime + pixel.delayDuration];
        CGContextAddEllipseInRect(ctx, CGRectMake(curX , curY , 1, 1));
        const CGFloat *components = CGColorGetComponents(pixel.color.CGColor);
        CGContextSetRGBFillColor(ctx, components[0], components[1], components[2], components[3]);
        CGContextFillPath(ctx);
    }
    if (count == self.temps.count) {
        [self reset];
        _xxblock();
    }
}

#pragma mark - public
- (void)restart {
    [self reset];
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(emitteraAnimation:)];
    [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

#pragma mark - private
//- (void)pause {
//    _displayLink.paused = YES;
//}
//- (void)resume {
//    _displayLink.paused = NO;
//}

- (void)emitteraAnimation:(CADisplayLink*)displayLink {
    [self setNeedsDisplay];
    _animationTime += 0.2;
}
- (void)reset {
    if (_displayLink) {
        [_displayLink invalidate];
        _displayLink = nil;
        _animationTime = 0;
    }
}
/// 将图片拆分为像素粒子
- (NSArray*)kj_resolutionImageToPixelWithImage:(UIImage*)image{
    //1. get the image into your data buffer.
    CGImageRef imageRef = [image CGImage];
    NSUInteger imageW = CGImageGetWidth(imageRef);
    NSUInteger imageH = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSUInteger bytesPerPixel = 4; //一个像素4字节
    NSUInteger bytesPerRow = bytesPerPixel * imageW;
    unsigned char *rawData = (unsigned char*)calloc(imageH*imageW*bytesPerPixel, sizeof(unsigned char)); //元数据
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, imageW, imageH, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, imageW, imageH), imageRef);
    CGContextRelease(context);
    
    //2. Now your rawData contains the image data in the RGBA8888 pixel format.
    CGFloat addY = (_pixelMaximum == 0) ? 1 : MAX(1, (imageH / _pixelMaximum));
    CGFloat addX = (_pixelMaximum == 0) ? 1 : MAX(1, (imageW / _pixelMaximum));
    NSMutableArray *result = [NSMutableArray new];
    for (int y = 0; y < imageH; y+=addY) {
        for (int x = 0; x < imageW; x+=addX) {
            NSUInteger byteIndex = bytesPerRow*y + bytesPerPixel*x;
            //rawData一维数组存储方式RGBA(第一个像素)RGBA(第二个像素)...
            CGFloat red   = ((CGFloat) rawData[byteIndex]     ) / 255.0f;
            CGFloat green = ((CGFloat) rawData[byteIndex + 1] ) / 255.0f;
            CGFloat blue  = ((CGFloat) rawData[byteIndex + 2] ) / 255.0f;
            CGFloat alpha = ((CGFloat) rawData[byteIndex + 3] ) / 255.0f;
            
            if (alpha == 0 ||
               (_ignoredWhite && (red+green+blue == 3)) ||
               (_ignoredBlack && (red+green+blue == 0))) {
                //要忽略的粒子
                continue;
            }
            
            KJEmitterImagePixel *pixel = [KJEmitterImagePixel new];
            pixel.color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            pixel.point = CGPointMake(x, y);
            if (_pixelColor) pixel.pixelColor = _pixelColor;
            if (_pixelRandomPointRange > 0) pixel.randomPointRange = _pixelRandomPointRange;
            [result addObject:pixel];
        }
    }
    free(rawData);
    return result;
}
/*!参数描述
 * time 动画执行到当前帧所进过的时间
 * beginPosition 起始的位置
 * endPosition 结束的位置
 * duration 持续时间
 */
- (CGFloat)easeInOutQuad:(CGFloat)time begin:(CGFloat)beginPosition end:(CGFloat)endPosition duration:(CGFloat)duration {
    CGFloat coverDistance = endPosition - beginPosition;
    time /= duration/2;
    if (time < 1) {
        return coverDistance/2 * pow(time, 2) + beginPosition;
    }
    time --;
    return -coverDistance / 2 * (time*(time-2)-1) + beginPosition;
}

#pragma mark - 链式属性
- (KJEmitterLayer *(^)(BOOL ignoredBlack,BOOL ignoredWhite))KJIgnored {
    return ^(BOOL ignoredBlack,BOOL ignoredWhite){
        self.ignoredBlack = ignoredBlack;
        self.ignoredWhite = ignoredWhite;
        return self;
    };
}
- (KJEmitterLayer *(^)(UIColor *pixelColor,NSInteger pixelMaximum,CGPoint pixelBeginPoint,CGFloat pixelRandomPointRange))KJPixel {
    return ^(UIColor *pixelColor,NSInteger pixelMaximum,CGPoint pixelBeginPoint,CGFloat pixelRandomPointRange){
        if (pixelColor && pixelColor != UIColor.clearColor) {
            self.pixelColor = pixelColor;
        }
        if (pixelMaximum) {
            self.pixelMaximum = pixelMaximum;
        }
        if (!CGPointEqualToPoint(pixelBeginPoint, CGPointZero)) {
            self.pixelBeginPoint = pixelBeginPoint;
        }
        if (pixelRandomPointRange) {
            self.pixelRandomPointRange = pixelRandomPointRange;
        }
        return self;
    };
}


@end
