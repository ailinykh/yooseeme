//
//  DeviceSettingsViewController.m
//  yooseeme
//
//  Created by tony on 27/09/16.
//  Copyright © 2016 Tony. All rights reserved.
//

#import "DeviceSettingsViewController.h"
#import "P2PClient.h"
#import "UDManager.h"
#import "LoginResult.h"

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
    NSDictionary *parameter = [note userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    switch(key) {
        case RET_GET_NPCSETTINGS_REMOTE_DEFENCE:
        {
            NSInteger state = [[parameter valueForKey:@"state"] intValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_guardSwitch setOn:state];
            });
        }
            break;
        case RET_SET_NPCSETTINGS_REMOTE_DEFENCE:
        {
            NSLog(@"RET_SET_NPCSETTINGS_REMOTE_DEFENCE");
        }
            break;
        case RET_GET_BIND_ACCOUNT:
        {
            NSLog(@"RET_GET_BIND_ACCOUNT %@", parameter);
            LoginResult *loginResult = [UDManager getLoginInfo];
            NSArray *binds = [parameter valueForKey:@"datas"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_alarmSwitch setOn:[binds containsObject:@(loginResult.contactId.intValue)]];
            });
        }
            break;
        case RET_SET_BIND_ACCOUNT:
        {
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            if (result == 0) {
                NSLog(@"Account binded/unbinded");
            } else {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Error"
                                                                            message:@"Account bind error"
                                                                     preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:ac animated:YES completion:nil];
            }
        }
            break;
        case RET_GET_NPCSETTINGS_MOTION:
        {
            NSInteger state = [[parameter valueForKey:@"state"] intValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_motionSwitch setOn:state];
            });
            DLog(@"motion state:%i",state);
        }
            break;
        case RET_SET_NPCSETTINGS_MOTION:
            NSLog(@"Motion set: %@", _motionSwitch.isOn ? @"YES" : @"NO");
            break;
        default:
            NSLog(@"%s %@", __PRETTY_FUNCTION__, note.userInfo);
            break;
    }
}

- (void)ack_receiveRemoteMessage:(NSNotification*)note
{
    NSDictionary *parameter = note.userInfo;
    int key   = [[parameter valueForKey:@"key"] intValue];
    int result   = [[parameter valueForKey:@"result"] intValue];
    
    if (result == 1) { // wrong password
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Error"
                                                                        message:@"Password is wrong"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:ac animated:YES completion:nil];
        });
    }
    else if (result == 2) {
        switch (key) {
            case ACK_RET_GET_DEFENCE_STATE:
                NSLog(@"ACK_RET_GET_DEFENCE_STATE: %@", result == 1 ? @"YES" : @"NO");
                break;
            case ACK_RET_GET_NPC_SETTINGS:
                NSLog(@"ACK_RET_GET_NPC_SETTINGS");
                break;
            default:
                NSLog(@"%s %@", __PRETTY_FUNCTION__, note.userInfo);
                break;
        }
    }
}

- (IBAction)guardSwitchChanged:(UISwitch*)sender {
    [[P2PClient sharedClient] setRemoteDefenceWithId:_contact.contactId password:_contact.contactPassword state:sender.isOn];
}

- (IBAction)alarmSwitchChanged:(UISwitch*)sender {
    NSMutableArray *binds = [NSMutableArray arrayWithCapacity:1];
    if (sender.isOn) {
        LoginResult *loginResult = [UDManager getLoginInfo];
        [binds addObject:@(loginResult.contactId.intValue)];
    }
    [[P2PClient sharedClient] setBindAccountWithId:_contact.contactId password:_contact.contactPassword datas:binds];
}

- (IBAction)motionSwitchChanged:(UISwitch*)sender {
    [[P2PClient sharedClient] setMotionWithId:_contact.contactId
                                     password:_contact.contactPassword
                                        state:sender.isOn];
}

@end
