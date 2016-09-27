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

@interface AppDelegate ()
@property (strong, nonatomic) NSString *token;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil];
    [application registerUserNotificationSettings:settings];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
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
                }];
                break;
            }
            default:
                break;
        }
    }];
}

@end
