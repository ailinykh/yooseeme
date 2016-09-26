//
//  AccountResult.m
//  Yoosee
//
//  Created by guojunyi on 14-4-25.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "AccountResult.h"

@implementation AccountResult
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.phone forKey:@"phone"];
    [aCoder encodeObject:self.email forKey:@"email"];
    [aCoder encodeObject:self.countryCode forKey:@"countryCode"];
    [aCoder encodeInt:self.error_code forKey:@"error_code"];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        self.phone = [aDecoder decodeObjectForKey:@"phone"];
        self.email = [aDecoder decodeObjectForKey:@"email"];
        self.countryCode = [aDecoder decodeObjectForKey:@"countryCode"];
        self.error_code = [aDecoder decodeIntForKey:@"error_code"];
    }
    return self;
}
@end
