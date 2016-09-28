//
//  AppDelegate.m
//  yooseeme
//
//  Created by Tony on 22.09.16.
//  Copyright © 2016 Tony. All rights reserved.
//

#import "AppDelegate.h"
#import "NetManager.h"
#import "LoginResult.h"
#import "AccountResult.h"
#import "UDManager.h"
#import "P2PClient.h"
#import "Contact.h"
#import "ContactDAO.h"
#import "PAIOUnit.h"

@interface AppDelegate () {
    UIBackgroundTaskIdentifier _backgroundTaskID;
    AVAudioPlayer *_audioPlayer;
}
@property (strong, nonatomic) NSString *token;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
    [application registerUserNotificationSettings:settings];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onReceiveAlarmMessage:) name:RECEIVE_ALARM_MESSAGE object:nil];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    if ([[P2PClient sharedClient] p2pCallState] == P2PCALL_STATUS_READY_P2P) {
        [[P2PClient sharedClient] setP2pCallState:P2PCALL_STATUS_NONE];
        [[PAIOUnit sharedUnit] stopAudio];
    }
    [[P2PClient sharedClient] p2pHungUp];
    [[P2PClient sharedClient] rtspHungUp];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _backgroundTaskID = [application beginBackgroundTaskWithExpirationHandler:^{
        [[P2PClient sharedClient] p2pDisconnect];
        [application endBackgroundTask:_backgroundTaskID];
    }];
    
    if (_backgroundTaskID == UIBackgroundTaskInvalid) {
        [[P2PClient sharedClient] p2pDisconnect];
        NSLog(@"Failed to start background task!");
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (_backgroundTaskID != UIBackgroundTaskInvalid) {
            sleep(1.0);
        }
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    application.applicationIconBadgeNumber = 0;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    _token = [[[[deviceToken description]
                stringByReplacingOccurrencesOfString: @"<" withString: @""]
                stringByReplacingOccurrencesOfString: @">" withString: @""]
                stringByReplacingOccurrencesOfString: @" " withString: @""];
    [self initConnection];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [self initConnection];
}

- (void)initConnection {
    NSString *username = @"wificamera@mail.ru";
    NSString *password = @"123456";
    
    [[NetManager sharedManager] loginWithUserName:username password:password token:_token callBack:^(id JSON) {
        LoginResult *loginResult = (LoginResult*)JSON;
        switch (loginResult.error_code) {
            case NET_RET_LOGIN_SUCCESS: {
                [UDManager setIsLogin:YES];
                [UDManager setLoginInfo:loginResult];
                [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"USER_NAME"];
                [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"LOGIN_TYPE"];
                
                [[NetManager sharedManager] getAccountInfo:loginResult.contactId sessionId:loginResult.sessionId callBack:^(id JSON){
                    AccountResult *accountResult = (AccountResult*)JSON;
                    loginResult.email = accountResult.email;
                    loginResult.phone = accountResult.phone;
                    loginResult.countryCode = accountResult.countryCode;
                    [UDManager setLoginInfo:loginResult];
                    
                    [[P2PClient sharedClient] p2pConnectWithId:loginResult.contactId codeStr1:loginResult.rCode1 codeStr2:loginResult.rCode2];
                }];
                break;
            }
            default:
                break;
        }
    }];
}

- (void)onReceiveAlarmMessage:(NSNotification *)notification {
    
    NSDictionary *parameter = [notification userInfo];
    
    //contact name
    NSString *contactId   = [parameter valueForKey:@"contactId"];
    ContactDAO *contactDAO = [[ContactDAO alloc] init];
    Contact *contact = [contactDAO isContact:contactId];
    NSString *contactName = contact.contactName;
    NSString *typeStr = NSLocalizedString(@"motion_dect_alarm", nil);
    
    NSLog(@"ALARM MESSAGE RECEIVED!");
    
    if (_backgroundTaskID != UIBackgroundTaskInvalid) {
        UILocalNotification *alarmNotify = [[UILocalNotification alloc] init];
        alarmNotify.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
        alarmNotify.timeZone = [NSTimeZone defaultTimeZone];
        alarmNotify.soundName = [self playAlarmMessageRingWithAlarmType:13 isBeBackground:YES];
        if ([contactId isEqualToString:contactName] || contactName == nil) {
            alarmNotify.alertBody = [NSString stringWithFormat:@"%@:%@",contactId,typeStr];
        }else{
            alarmNotify.alertBody = [NSString stringWithFormat:@"%@:%@",contactName,typeStr];
        }
        alarmNotify.applicationIconBadgeNumber = 1;
        alarmNotify.alertAction = NSLocalizedString(@"open", nil);
        [[UIApplication sharedApplication] scheduleLocalNotification:alarmNotify];
    }
    else {
        [self playAlarmMessageRingWithAlarmType:13 isBeBackground:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Alert"
                                                                        message:@"Motion detected"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
            [ac addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
            [_window.rootViewController presentViewController:ac animated:YES completion:nil];
        });
    }
}

-(NSString *)playAlarmMessageRingWithAlarmType:(int)alarmType isBeBackground:(BOOL)isBackground {
    if (isBackground) {
        return @"alarm_push_ring.caf";
    }
    
    NSURL *ringUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alarm_push_ring" ofType:@"caf"]];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:ringUrl error:nil];
    [_audioPlayer prepareToPlay];
    [_audioPlayer setVolume:1.0f];
    [_audioPlayer setNumberOfLoops:0];
    [_audioPlayer play];
    return nil;
}

@end
