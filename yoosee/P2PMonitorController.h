//
//  P2PMonitorController.h
//  Yoosee
//
//  Created by guojunyi on 14-3-26.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "P2PClient.h"
#import <AVFoundation/AVFoundation.h>
#import "TouchButton.h"
#import "OpenGLView.h"
#import "CustomBorderButton.h"
#import "CustomView.h"
#import "YProgressView.h"//rtsp监控界面弹出修改

#define FocalLength_Elongation_btnTag 300
#define FocalLength_Shorten_btnTag 301
#define FocalLength_Change_sliderTag 302

@interface P2PMonitorController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate,UIGestureRecognizerDelegate,TouchButtonDelegate,OpenGLViewDelegate,UIScrollViewDelegate,UIAlertViewDelegate>//监控界面缩放
@property (nonatomic, strong) OpenGLView *remoteView;
@property (nonatomic) BOOL isReject;
@property (nonatomic) BOOL isFullScreen;
@property (nonatomic) BOOL isShowControllerBar;
@property (nonatomic) BOOL isVideoModeHD;

@property (nonatomic,strong) UIScrollView *scrollView;//监控界面缩放
@property (nonatomic) BOOL isScale;//监控界面缩放

@property (strong, nonatomic) UIView *bottomView;//重新调整监控画面
@property (strong, nonatomic) UIView *pressView;
@property (nonatomic) BOOL isTalking;

@property (strong, nonatomic) UIView *controllerRight;
@property (strong, nonatomic) UIView *controllerRightBg;//重新调整监控画面
@property (strong, nonatomic) UIView *bottomBarView;//重新调整监控画面

@property (strong, nonatomic) UILabel * numberViewer;
@property (nonatomic) int number;

@property (nonatomic) BOOL isAlreadyShowResolution;//重新调整监控画面

@property (nonatomic) BOOL isDefenceOn;//重新调整监控画面

//GPIO 口控制参数记录
@property(strong, nonatomic) CustomBorderButton *customBorderButton;
@property(strong, nonatomic) CustomView *leftView;
@property(nonatomic) BOOL isShowLeftView;

@property(nonatomic) int lastGroup;
@property(nonatomic) int lastPin;
@property(nonatomic) int lastValue;
@property(nonatomic) int *lastTime;

@property(nonatomic, strong) UIButton *clickGPIO0_0Button;
@property(nonatomic, strong) UIButton *clickGPIO0_1Button;
@property(nonatomic, strong) UIButton *clickGPIO0_2Button;
@property(nonatomic, strong) UIButton *clickGPIO0_3Button;
@property(nonatomic, strong) UIButton *clickGPIO0_4Button;
@property(nonatomic, strong) UIButton *clickGPIO2_6Button;

@property(nonatomic, strong) UIButton *lightButton;
@property (nonatomic) BOOL isLightSwitchOn;
@property (strong, nonatomic) UIActivityIndicatorView *progressView;

@property (nonatomic) BOOL isRtspConnection;

@property (strong, nonatomic) YProgressView *yProgressView;//rtsp监控界面弹出修改
@property (strong, nonatomic) UIView *topView;
@property (strong, nonatomic) UIView *topBarView;

@property (strong, nonatomic) UIView *focalLengthView;
@property (strong, nonatomic) UIPinchGestureRecognizer *pinchGestureRecognizer;

@end
