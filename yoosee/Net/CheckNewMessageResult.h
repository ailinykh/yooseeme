//
//  CheckNewVersionResult.h
//  Yoosee
//
//  Created by guojunyi on 14-6-16.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CheckNewMessageResult : NSObject
@property (nonatomic) BOOL isNewContactMessage;
@property (nonatomic) int error_code;
@end
