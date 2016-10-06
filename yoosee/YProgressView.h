//
//  YProgressView.h
//  Yoosee
//
//  Created by guojunyi on 14-7-23.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YProgressView : UIView
@property (nonatomic) CGFloat angle;
@property (nonatomic) BOOL isStartAnim;
@property (nonatomic,strong) UIImageView *backgroundView;

-(void)start;
-(void)stop;

@end
