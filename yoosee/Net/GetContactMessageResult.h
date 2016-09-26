//
//  GetContactMessageResult.h
//  Yoosee
//
//  Created by guojunyi on 14-6-17.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GetContactMessageResult : NSObject
@property (nonatomic) BOOL hasNext;
@property (nonatomic) int error_code;
@property (nonatomic, strong) NSString *contactId;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *time;
@property (nonatomic) NSInteger flag;
@end
