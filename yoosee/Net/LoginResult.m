//
//  LoginResult.m
//  Yoosee
//
//  Created by guojunyi on 14-3-24.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "LoginResult.h"

@interface LoginResult ()

@end

@implementation LoginResult

-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.contactId forKey:@"contactId"];
    [aCoder encodeObject:self.rCode1 forKey:@"rCode1"];
    [aCoder encodeObject:self.rCode2 forKey:@"rCode2"];
    [aCoder encodeObject:self.phone forKey:@"phone"];
    [aCoder encodeObject:self.email forKey:@"email"];
    [aCoder encodeObject:self.sessionId forKey:@"sessionId"];
    [aCoder encodeObject:self.countryCode forKey:@"countryCode"];
    [aCoder encodeInt:self.error_code forKey:@"error_code"];
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        self.contactId = [aDecoder decodeObjectForKey:@"contactId"];
        self.rCode1 = [aDecoder decodeObjectForKey:@"rCode1"];
        self.rCode2 = [aDecoder decodeObjectForKey:@"rCode2"];
        self.phone = [aDecoder decodeObjectForKey:@"phone"];
        self.email = [aDecoder decodeObjectForKey:@"email"];
        self.sessionId = [aDecoder decodeObjectForKey:@"sessionId"];
        self.countryCode = [aDecoder decodeObjectForKey:@"countryCode"];
        self.error_code = [aDecoder decodeIntForKey:@"error_code"];
    }
    return self;
}
@end
