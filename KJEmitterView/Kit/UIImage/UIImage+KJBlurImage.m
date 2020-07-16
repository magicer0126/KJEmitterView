//
//  UIImage+KJBlurImage.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/23.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "UIImage+KJBlurImage.h"
#import <Accelerate/Accelerate.h>
#import <float.h>
@implementation UIImage (KJBlurImage)
- (UIImage*)kj_blurLightImage{
    return [self kj_blurImageWithRadius:30 TintColor:[UIColor colorWithWhite:1.0 alpha:0.3] Saturation:1.8 MaskImage:nil];
}
- (UIImage*)kj_blurExtraLightImage {
    return [self kj_blurImageWithRadius:20 TintColor:[UIColor colorWithWhite:0.97 alpha:0.82] Saturation:1.8 MaskImage:nil];
}

- (UIImage*)kj_blurDarkImage {
    return [self kj_blurImageWithRadius:20 TintColor:[UIColor colorWithWhite:0.11 alpha:0.73] Saturation:1.8 MaskImage:nil];
}
- (UIImage*)kj_blurTintImageWithColor:(UIColor*)tintColor {
    const CGFloat EffectColorAlpha = 0.6;
    UIColor *effectColor  = tintColor;
    int componentCount = (int)CGColorGetNumberOfComponents(tintColor.CGColor);
    if (componentCount == 2) {
        CGFloat b;
        if ([tintColor getWhite:&b alpha:NULL]) {
            effectColor = [UIColor colorWithWhite:b alpha:EffectColorAlpha];
        }
    }else {
        CGFloat r, g, b;
        if ([tintColor getRed:&r green:&g blue:&b alpha:NULL]) {
            effectColor = [UIColor colorWithRed:r green:g blue:b alpha:EffectColorAlpha];
        }
    }
    return [self kj_blurImageWithRadius:20 TintColor:effectColor Saturation:1.4 MaskImage:nil];
}

- (UIImage*)kj_blurImage {
    return [self kj_blurImageWithRadius:20 TintColor:[UIColor colorWithWhite:0 alpha:0.0] Saturation:1.4 MaskImage:nil];
}

- (UIImage*)kj_blurImageWithRadius:(CGFloat)radius {
    return [self kj_blurImageWithRadius:radius TintColor:[UIColor colorWithWhite:0 alpha:0.0] Saturation:1.4 MaskImage:nil];
}

- (UIImage*)kj_blurImageWithMask:(UIImage *)maskImage {
    return [self kj_blurImageWithRadius:20 TintColor:[UIColor colorWithWhite:0 alpha:0.0] Saturation:1.4 MaskImage:maskImage];
}

- (UIImage*)kj_blurImageWithFrame:(CGRect)frame {
    return [self applyBlurWithRadius:20
                           tintColor:[UIColor colorWithWhite:0 alpha:0.0]
               saturationDeltaFactor:1.4
                           maskImage:nil
                             atFrame:frame];
}
#pragma mark - 内部方法
- (UIImage*)kj_blurImageWithRadius:(CGFloat)radius
                         TintColor:(UIColor*)tintColor
                        Saturation:(CGFloat)saturation
                         MaskImage:(UIImage*_Nullable)maskImage {
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    if (!self.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }

    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    BOOL hasBlur = radius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturation - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);

        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
    
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);

        if (hasBlur) {
            CGFloat inputRadius = radius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
        }
        
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturation;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                                  0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            } else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        
        if (!effectImageBuffersAreSwapped) {
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
        if (effectImageBuffersAreSwapped) {
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
    }

    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);

    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);

    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }

    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }

    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return outputImage;
}

- (UIImage *)addImageToImage:(UIImage*)img atRect:(CGRect)cropRect {
    CGSize size = CGSizeMake(self.size.width, self.size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    CGPoint pointImg1 = CGPointMake(0,0);
    [self drawAtPoint:pointImg1];
    CGPoint pointImg2 = cropRect.origin;
    [img drawAtPoint: pointImg2];
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius
                       tintColor:(UIColor*)tintColor
           saturationDeltaFactor:(CGFloat)saturationDeltaFactor
                       maskImage:(UIImage*)maskImage
                         atFrame:(CGRect)frame{
    UIImage *blurredFrame = [[self croppedImageAtFrame:frame] kj_blurImageWithRadius:blurRadius
                                                TintColor:tintColor
                                    Saturation:saturationDeltaFactor
                                                MaskImage:maskImage];
    
    return [self addImageToImage:blurredFrame atRect:frame];
}
- (UIImage *)croppedImageAtFrame:(CGRect)frame {
    frame = CGRectMake(frame.origin.x * self.scale,frame.origin.y * self.scale,frame.size.width * self.scale,frame.size.height * self.scale);
    CGImageRef sourceImageRef = [self CGImage];
    CGImageRef newImageRef    = CGImageCreateWithImageInRect(sourceImageRef, frame);
    UIImage   *newImage       = [UIImage imageWithCGImage:newImageRef scale:[self scale] orientation:[self imageOrientation]];
    CGImageRelease(newImageRef);
    return newImage;
}

@end
