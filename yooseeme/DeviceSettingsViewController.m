//
//  DeviceSettingsViewController.m
//  yooseeme
//
//  Created by tony on 27/09/16.
//  Copyright © 2016 Tony. All rights reserved.
//

#import "DeviceSettingsViewController.h"
#import "P2PClient.h"

@interface DeviceSettingsViewController ()

@property (nonatomic, weak) IBOutlet UISwitch *guardSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *alarmSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *motionSwitch;

@end

@implementation DeviceSettingsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = _contact.contactName;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    
    [[P2PClient sharedClient] getDefenceState:_contact.contactId password:_contact.contactPassword];
    [[P2PClient sharedClient] getBindAccountWithId:_contact.contactId password:_contact.contactPassword];
    [[P2PClient sharedClient] getNpcSettingsWithId:_contact.contactId password:_contact.contactPassword];
}

- (void)receiveRemoteMessage:(NSNotification*)note
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, note.userInfo);
}

- (void)ack_receiveRemoteMessage:(NSNotification*)note
{
    NSDictionary *parameter = note.userInfo;
    int key   = [[parameter valueForKey:@"key"] intValue];
    int result   = [[parameter valueForKey:@"result"] intValue];
    
    switch (key) {
        case ACK_RET_GET_DEFENCE_STATE:
            [_guardSwitch setOn:result == 1];
            break;
        default:
            break;
    }
    NSLog(@"%s %@", __PRETTY_FUNCTION__, note.userInfo);
}

@end
