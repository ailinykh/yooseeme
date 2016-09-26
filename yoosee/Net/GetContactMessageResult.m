//
//  GetContactMessageResult.m
//  Yoosee
//
//  Created by guojunyi on 14-6-17.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "GetContactMessageResult.h"

@implementation GetContactMessageResult
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.contactId forKey:@"contactId"];
    [aCoder encodeObject:self.message forKey:@"message"];
    [aCoder encodeObject:self.time forKey:@"time"];
    [aCoder encodeInt:self.error_code forKey:@"error_code"];
    [aCoder encodeInt:self.flag forKey:@"flag"];
    [aCoder encodeBool:self.hasNext forKey:@"hasNext"];
}


-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self){
        self.hasNext = [aDecoder decodeBoolForKey:@"hasNext"];
        self.contactId = [aDecoder decodeObjectForKey:@"contactId"];
        self.message = [aDecoder decodeObjectForKey:@"message"];
        self.time = [aDecoder decodeObjectForKey:@"time"];
        self.error_code = [aDecoder decodeIntForKey:@"error_code"];
        self.flag = [aDecoder decodeIntForKey:@"flag"];
    }
    return self;
}

@end
