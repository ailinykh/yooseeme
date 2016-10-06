//
//  CustomView.h
//  Test
//
//  Created by gwelltime on 14-11-27.
//  Copyright (c) 2014年 nyshnukdny. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomView : UIView

@property (assign,nonatomic) BOOL needLineTop;
@property (assign,nonatomic) BOOL needLineLeft;
@property (assign,nonatomic) BOOL needLineBottom;
@property (assign,nonatomic) BOOL needLineRight;
//line width
@property (assign,nonatomic) CGFloat lineWidthTop;
@property (assign,nonatomic) CGFloat lineWidthLeft;
@property (assign,nonatomic) CGFloat lineWidthBottom;
@property (assign,nonatomic) CGFloat lineWidthRight;
//line color
@property (retain,nonatomic) UIColor *lineColorTop;
@property (retain,nonatomic) UIColor *lineColorLeft;
@property (retain,nonatomic) UIColor *lineColorBottom;
@property (retain,nonatomic) UIColor *lineColorRight;
//corner radius
@property (assign,nonatomic) CGFloat radiusTopLeft;
@property (assign,nonatomic) CGFloat radiusTopRight;
@property (assign,nonatomic) CGFloat radiusBottomLeft;
@property (assign,nonatomic) CGFloat radiusBottomRight;

//lack line length
@property(assign,nonatomic) CGFloat lackLineLength;

//内部填充颜色
@property (retain,nonatomic) UIColor *fillColor;
//根据自身形状根据边线进行裁剪
@property (assign,nonatomic) BOOL clipsToBoundsWithBorder;

-(void)setNeedLineTop:(BOOL)needTop left:(BOOL)needLeft bottom:(BOOL)needBottom right:(BOOL)needRight;
-(void)setLineWidthTop:(CGFloat)widthTop left:(CGFloat)widthLeft bottom:(CGFloat)widthBottom right:(CGFloat)widthRight;
-(void)setLineColorTop:(UIColor *)colorTop left:(UIColor *)colorLeft bottom:(UIColor *)colorBottom right:(UIColor *)colorRight;
-(void)setRadiusTopLeft:(CGFloat)topLeft topRight:(CGFloat)topRight bottomLeft:(CGFloat)bottomLeft bottomRight:(CGFloat)bottomRight;

@end
