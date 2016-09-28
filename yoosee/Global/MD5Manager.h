//
//  MD5Manager.h
//  2cu
//
//  Created by wutong on 15/12/16.
//  Copyright © 2015年 guojunyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MD5Manager : NSObject


+(unsigned int)EncryptGW1:(const char*) szInputBuffer;

+(BOOL)isWeakPasswordStrengthWithPWD:(unsigned int)dwPassword;
@end
