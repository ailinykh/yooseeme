//
//  NetManager.h
//  Yoosee
//
//  Created by guojunyi on 14-3-21.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetManager : NSObject
#define NOTIFICATION_ON_SESSION_ERROR @"NOTIFICATION_ON_SESSION_ERROR"

#define NET_RET_UNKNOWN_ERROR 999
#define NET_RET_SESSION_ERROR 23
#define NET_RET_NO_RECORD 13
#define NET_RET_NO_PERMISSION 35


#define NET_RET_LOGIN_SUCCESS 0
#define NET_RET_LOGIN_USER_UNEXIST 2
#define NET_RET_LOGIN_PWD_ERROR 3
#define NET_RET_LOGIN_EMAIL_FORMAT_ERROR 4

#define NET_RET_LOGOUT_SUCCESS 0

#define NET_RET_GET_ACCOUNT_SUCCESS 0

#define NET_RET_SET_ACCOUNT_SUCCESS 0 
#define NET_RET_SET_ACCOUNT_PASSWORD_ERROR 3
#define NET_RET_SET_ACCOUNT_EMAIL_FORMAT_ERROR 4
#define NET_RET_SET_ACCOUNT_PHONE_USED 6
#define NET_RET_SET_ACCOUNT_EMAIL_USED 7

#define NET_RET_MODIFY_LOGIN_PASSWORD_SUCCESS 0
#define NET_RET_MODIFY_LOGIN_PASSWORD_NOT_MATCH 10
#define NET_RET_MODIFY_LOGIN_PASSWORD_ORIGINAL_PASSWORD_ERROR 11

#define NET_RET_GET_PHONE_CODE_SUCCESS 0
#define NET_RET_GET_PHONE_CODE_PHONE_USED 6
#define NET_RET_GET_PHONE_CODE_FORMAT_ERROR 9
#define NET_RET_GET_PHONE_CODE_TOO_TIMES 27

#define NET_RET_REGISTER_SUCCESS 0
#define NET_RET_REGISTER_EMAIL_FORMAT_ERROR 4
#define NET_RET_REGISTER_PHONE_USED 6
#define NET_RET_REGISTER_EMAIL_USED 7
#define NET_RET_REGISTER_PHONE_CODE_ERROR 18
#define NET_RET_REGISTER_PHONE_FORMAT_ERROR 9

#define NET_RET_VERIFY_PHONE_CODE_SUCCESS 0
#define NET_RET_VERIFY_PHONE_CODE_ERROR 18
#define NET_RET_VERIFY_PHONE_CODE_TIME_OUT 21

#define NET_RET_CHECK_NEW_MESSAGE_SUCCESS 0
#define NET_RET_CHECK_ALARM_MESSAGE_SUCCESS 0
+(NetManager*)sharedManager;

- (void)loginWithUserName:(NSString*)username password:(NSString*)password token:(NSString*)token
                 callBack:(void (^)(id JSON))callBack;
- (void)logoutWithUserName:(NSString*)username sessionId:(NSString*)sessionId
              callBack:(void (^)(id JSON))callBack;


- (void)getAccountInfo:(NSString*)username sessionId:(NSString*)sessionId
                 callBack:(void (^)(id JSON))callBack;

-(void)setAccountInfo:(NSString*)username password:(NSString*)password phone:(NSString*)phone email:(NSString*)email countryCode:(NSString*)countryCode phoneCheckCode:(NSString*)phoneCheckCode flag:(NSString*)flag sessionId:(NSString*)sessionId
             callBack:(void (^)(id JSON))callBack;
-(void)modifyLoginPasswordWithUserName:(NSString*)username sessionId:(NSString*)sessionId oldPwd:(NSString*)oldPwd newPwd:(NSString*)newPwd rePwd:(NSString*)rePwd callBack:(void (^)(id JSON))callBack;

-(void)getPhoneCodeWithPhone:(NSString*)phone countryCode:(NSString*)countryCode
           callBack:(void (^)(id JSON))callBack;

-(void)registerWithVersionFlag:(NSString*)versionFlag email:(NSString*)email countryCode:(NSString*)countryCode phone:(NSString*)phone password:(NSString*)password repassword:(NSString*)repassword phoneCode:(NSString*)phoneCode callBack:(void (^)(id JSON))callBack;

-(void)verifyPhoneCodeWithCode:(NSString*)phoneCode phone:(NSString*)phone countryCode:(NSString*)countryCode callBack:(void (^)(id JSON))callBack;

-(void)checkNewMessage:(NSString*)username sessionId:(NSString*)sessionId callBack:(void (^)(id JSON))callBack;

-(void)getContactMessageWithUsername:(NSString*)username sessionId:(NSString*)sessionId callBack:(void (^)(id JSON))callBack;

-(void)checkAlarmMessage:(NSString*)username sessionId:(NSString*)sessionId callBack:(void (^)(id JSON))callBack;

-(void)getAlarmMessageWithUsername:(NSString*)username sessionId:(NSString*)sessionId callBack:(void (^)(id JSON))callBack;

- (void) getAlarmRecordWithUsername:(NSString *)username sessionId:(NSString *)sessionId option:(NSString*)option msgIndex:(NSString *)msgIndex senderList:(NSString *)senderList checkLevelType:(NSString *)checkLevelType vKey:(NSString *)vKey callBack:(void (^)(id JSON))callBack;

@end
