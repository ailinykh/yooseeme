//
//  YProgressView.m
//  Yoosee
//
//  Created by guojunyi on 14-7-23.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "YProgressView.h"

@implementation YProgressView

-(void)dealloc{
    [self.backgroundColor release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:backgroundView];
        self.backgroundView = backgroundView;
        
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)start{
    if(self.isStartAnim){
        return;
    }
    self.angle = 0.0;
    self.isStartAnim = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while(self.isStartAnim){
            dispatch_async(dispatch_get_main_queue(), ^{
                self.backgroundView.transform = CGAffineTransformMakeRotation(self.angle);
            });
            self.angle += 0.01;
            if(self.angle>6.28){
                self.angle = 0.0;
                usleep(300000);
            }else{
                usleep(1000);
            }
            
        }
        self.isStartAnim = NO;
    });

}

-(void)stop{
    self.isStartAnim = NO;
}

@end
