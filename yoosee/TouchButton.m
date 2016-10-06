//
//  TouchButton.m
//  Yoosee
//
//  Created by guojunyi on 14-4-22.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "TouchButton.h"

@implementation TouchButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
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

- (void)setDelegate:(id<TouchButtonDelegate>)delegate
{
    _delegate = delegate;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    if(self.delegate){
        [self.delegate onBegin:self widthTouches:touches withEvent:event];
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesCancelled:touches withEvent:event];
    if(self.delegate){
        [self.delegate onCancelled:self widthTouches:touches withEvent:event];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    if(self.delegate){
        [self.delegate onEnded:self widthTouches:touches withEvent:event];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    if(self.delegate){
        [self.delegate onMoved:self widthTouches:touches withEvent:event];
    }
}

@end
