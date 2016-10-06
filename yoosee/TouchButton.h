//
//  TouchButton.h
//  Yoosee
//
//  Created by guojunyi on 14-4-22.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TouchButton;
@protocol TouchButtonDelegate <NSObject>

@optional
-(void)onBegin:(TouchButton*)touchButton widthTouches:(NSSet*)touches withEvent:(UIEvent *)event;
-(void)onCancelled:(TouchButton*)touchButton widthTouches:(NSSet*)touches withEvent:(UIEvent *)event;
-(void)onEnded:(TouchButton*)touchButton widthTouches:(NSSet*)touches withEvent:(UIEvent *)event;
-(void)onMoved:(TouchButton*)touchButton widthTouches:(NSSet*)touches withEvent:(UIEvent *)event;
@end

@interface TouchButton : UIButton


@property (nonatomic, assign) id<TouchButtonDelegate> delegate;
- (void)setDelegate:(id<TouchButtonDelegate>)delegate;
@end


