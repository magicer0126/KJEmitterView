//
//  KJProjectionVC.m
//  KJEmitterView
//
//  Created by 杨科军 on 2020/6/23.
//  Copyright © 2020 杨科军. All rights reserved.
//

#import "KJProjectionVC.h"
#import "UIImage+KJBlurImage.h"
@interface KJProjectionVC ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView2;
@property (weak, nonatomic) IBOutlet UISlider *slider3;
@end

@implementation KJProjectionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    /// 获取模糊图片
    UIImage *image = [self.imageView.image kj_blurTintImageWithColor:UIColor.blackColor];
    self.imageView2.image = image;
    
    self.imageView.image = [self.imageView.image kj_blurImageWithMask:image];
}
- (IBAction)slider3:(UISlider *)sender {
    
}

@end
