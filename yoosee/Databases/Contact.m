//
//  Contact.m
//  Yoosee
//
//  Created by guojunyi on 14-4-14.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "Contact.h"
#import "Constants.h"
@implementation Contact

-(id)init{
    self = [super init];
    if (self) {
        self.messageCount = 0;
        self.defenceState = DEFENCE_STATE_LOADING;
        self.isClickDefenceStateBtn = NO;
    }
    return self;
}

@end
