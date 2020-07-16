//
//  UIBezierPath+KJPoints.m
//  AutoDecorate
//
//  Created by 杨科军 on 2020/7/8.
//  Copyright © 2020 songxf. All rights reserved.
//

#import "UIBezierPath+KJPoints.h"

@implementation UIBezierPath (KJPoints)
- (NSArray*)kj_points{
    NSMutableArray *points = [NSMutableArray array];
    CGPathApply(self.CGPath, (__bridge void *)points, getPointsFromBezier);
    return points.mutableCopy;
}
static void getPointsFromBezier(void *info,const CGPathElement *element){
    NSMutableArray *bezierPoints = (__bridge NSMutableArray *)info;
    CGPathElementType type = element->type;
    CGPoint *points = element->points;
    if (type != kCGPathElementCloseSubpath) {
        [bezierPoints addObject:[NSValue valueWithCGPoint:points[0]]];
        if ((type != kCGPathElementAddLineToPoint) && (type != kCGPathElementMoveToPoint)) {
            [bezierPoints addObject:[NSValue valueWithCGPoint:points[1]]];
        }
    }
    if (type == kCGPathElementAddCurveToPoint) {
        [bezierPoints addObject:[NSValue valueWithCGPoint:points[2]]];
    }
}

@end
