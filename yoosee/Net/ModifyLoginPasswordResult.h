//
//  ModifyLoginPasswordResult.h
//  Yoosee
//
//  Created by guojunyi on 14-4-26.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ModifyLoginPasswordResult : NSObject
@property (strong, nonatomic) NSString* sessionId;
@property (nonatomic) int error_code;
@end
