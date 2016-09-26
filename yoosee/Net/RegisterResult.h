//
//  RegisterResult.h
//  Yoosee
//
//  Created by guojunyi on 14-5-23.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RegisterResult : NSObject
@property (strong, nonatomic) NSString* contactId;
@property (nonatomic) int error_code;
@end
