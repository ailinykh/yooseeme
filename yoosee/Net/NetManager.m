//
//  NetManager.m
//  Yoosee
//
//  Created by guojunyi on 14-3-21.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "NetManager.h"
#import "Constants.h"
#import "Utils.h"
#import "LoginResult.h"
#import "AccountResult.h"
#import "ModifyLoginPasswordResult.h"
#import "RegisterResult.h"
#import "CheckNewMessageResult.h"
#import "GetContactMessageResult.h"
#import "CheckAlarmMessageResult.h"
#import "GetAlarmRecordResult.h"
#import "Alarm.h"
#import "libPwdEncrypt.h"

static NSString *server1 = @"http://api1.cloudlinks.cn/";
static NSString *server2 = @"http://api2.cloudlinks.cn/";
static NSString *server3 = @"http://api3.cloud-links.net/";
static NSString *server4 = @"http://api4.cloud-links.net/";

//static NSString *server1 = @"http://192.168.1.231/";
//static NSString *server2 = @"http://192.168.1.231/";
//static NSString *server3 = @"http://192.168.1.231/";
//static NSString *server4 = @"http://192.168.1.231/";

static NSString *currentServer;
static NSMutableArray *servers;
static NSInteger reconnectCount;

@implementation NetManager

- (id)init
{
    if (self = [super init]) {
        
    }
    return self;
}

+(NetManager*)sharedManager{
    static NetManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[NetManager alloc] init];
        reconnectCount = 0;
        
        servers = [[NSMutableArray alloc] initWithCapacity:0];
        [manager randomServer];
    });
    return manager;
}

-(void)randomServer{
    [servers removeAllObjects];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    if([language hasPrefix:@"zh"]){
        int random = arc4random()%2;
        if(random==0){
            [servers addObject:[NSString stringWithFormat:@"%@",server1]];
            [servers addObject:[NSString stringWithFormat:@"%@",server2]];
        }else{
            [servers addObject:[NSString stringWithFormat:@"%@",server2]];
            [servers addObject:[NSString stringWithFormat:@"%@",server1]];
        }
        
        random = arc4random()%2;
        if(random==0){
            [servers addObject:[NSString stringWithFormat:@"%@",server3]];
            [servers addObject:[NSString stringWithFormat:@"%@",server4]];
        }else{
            [servers addObject:[NSString stringWithFormat:@"%@",server4]];
            [servers addObject:[NSString stringWithFormat:@"%@",server3]];
        }
    }else{
        int random = arc4random()%2;
        if(random==0){
            [servers addObject:[NSString stringWithFormat:@"%@",server3]];
            [servers addObject:[NSString stringWithFormat:@"%@",server4]];
        }else{
            [servers addObject:[NSString stringWithFormat:@"%@",server4]];
            [servers addObject:[NSString stringWithFormat:@"%@",server3]];
        }
        
        random = arc4random()%2;
        if(random==0){
            [servers addObject:[NSString stringWithFormat:@"%@",server1]];
            [servers addObject:[NSString stringWithFormat:@"%@",server2]];
        }else{
            [servers addObject:[NSString stringWithFormat:@"%@",server2]];
            [servers addObject:[NSString stringWithFormat:@"%@",server1]];
        }
    }
    
    currentServer = [[NSString alloc] initWithFormat:@"%@",[servers objectAtIndex:0]];
}

-(void)resetServer{
    [self randomServer];
    reconnectCount = 0;
}

-(void)onSessionIdError{
//    [UDManager setIsLogin:NO];
//    
//    [[GlobalThread sharedThread:NO] kill];
//    [[FListManager sharedFList] setIsReloadData:YES];
//    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
//    LoginController *loginController = [[LoginController alloc] init];
//    loginController.isSessionIdError = YES;
//    AutoNavigation *mainController = [[AutoNavigation alloc] initWithRootViewController:loginController];
//    
//    [AppDelegate sharedDefault].window.rootViewController = mainController;
//    [loginController release];
//    [mainController release];
//    
//    dispatch_queue_t queue = dispatch_queue_create(NULL, NULL);
//    dispatch_async(queue, ^{
//        [[P2PClient sharedClient] p2pDisconnect];
//        DLog(@"p2pDisconnect.");
//    });
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ON_SESSION_ERROR object:nil];
}

-(void)requestHttp:(NSString*)baseUrlStr actionPath:(NSString*)path parameter:(NSMutableDictionary*)parameter
           success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON))success
           failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON))failure{
    
    NSURL *baseUrl = [NSURL URLWithString:[baseUrlStr stringByAppendingString:path]];
    [parameter setObject:@"2" forKey:@"AppOS"];
    [parameter setObject:@"1" forKey:@"VersionFlag"];
    
    NSArray *array = [APP_VERSION componentsSeparatedByString:@"."];
    int a = [[array objectAtIndex:0] intValue]<<24;
    int b = [[array objectAtIndex:1] intValue]<<16;
    int c = [[array objectAtIndex:2] intValue]<<8;
    int d = [[array objectAtIndex:3] intValue];
    
    [parameter setObject:[NSString stringWithFormat:@"%i",a|b|c|d] forKey:@"AppVersion"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:baseUrl];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:10];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:parameter.allKeys.count];
    [parameter enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [params addObject:[NSString stringWithFormat:@"%@=%@", key, [obj isKindOfClass:NSString.class] ? obj : [obj stringValue]]];
    }];
    [request setHTTPBody:[[params componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding]];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDictionary *JSON;
        if (data) {
            JSON = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        }
        if (error == nil) {
            success(request, response, JSON);
        } else {
            failure(request, response, error, JSON);
        }
    }] resume];
    /*
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseUrl];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:path parameters:parameter];
                  [request setTimeoutInterval:10];
                  [AFJSONRequestOperation addAcceptableContentTypes:[NSSet setWithObject:@"text/plain"]];
                  AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                                      success:success
                                                                                                      failure:failure];
                  [operation start];
     */
}

- (void)loginWithUserName:(NSString*)username password:(NSString*)password token:(NSString*)token
                   callBack:(void (^)(id result))callBack
{
    
    
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
   
    if([username isValidateNumber]){
        NSInteger iUsername = username.integerValue | 0x80000000;
        [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername]
                  forKey:@"User"];
    }else{
        [parameter setObject:username
                      forKey:@"User"];
    }
    [parameter setObject:[password getMd5_32Bit_String] forKey:@"Pwd"];
    if(token){
        [parameter setObject:token forKey:@"Token"];
    }
    
    // get storeID  作用是让服务器实现推荐信息通知推送给APP
    NSString *storeID = nil;
    
    //get isManualStoreID from Common-Configuration.plist
    NSString * plist = [[NSBundle mainBundle] pathForResource:@"Common-Configuration" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:plist];
    BOOL isManualStoreID = [dic[@"isManualStoreID"] boolValue];
    if (isManualStoreID) {
        //get ManualStoreID from Common-Configuration.plist
        storeID = dic[@"ManualStoreID"];
        if ([storeID isEqualToString:@""]) {
            storeID = nil;
        }
    }else{
        //get storeID from local
        storeID = [[NSUserDefaults standardUserDefaults] objectForKey:@"StoreID"];
    }
    if (!storeID) {
        //要不要提示一下呢（请求添加设备，获取商城ID,或者在.plist文件添加商城ID）
        [parameter setObject:@"0" forKey:@"StoreID"];
    }else{
        [parameter setObject:storeID forKey:@"StoreID"];
    }
    
    
    [self requestHttp:currentServer actionPath:@"Users/LoginCheck.ashx" parameter:parameter
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
            NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
            DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
            DLog(@"error:%@",[result valueForKey:@"error"]);
        
            int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
            if(error_code==1||error_code==29||error_code==999){
                if(reconnectCount<([servers count]-1)){
                    reconnectCount++;
                    currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                    DLog(@"change server:%@",currentServer);
                    [self loginWithUserName:username password:password token:token callBack:callBack];
                }else{
                    [self randomServer];
                    reconnectCount = 0;
                    
                    LoginResult *loginResult = [[LoginResult alloc] init];
                    loginResult.error_code = NET_RET_UNKNOWN_ERROR;
                    
                    
                    
                    callBack(loginResult);
                    [loginResult release];
                    
                    
                }
            }else{
                LoginResult *loginResult = [[LoginResult alloc] init];
                loginResult.error_code = error_code;
                if(loginResult.error_code == NET_RET_LOGIN_SUCCESS){
                    int iContactId = ((NSString*)[result valueForKey:@"UserID"]).intValue & 0x7fffffff;
            
                    loginResult.contactId = [NSString stringWithFormat:@"0%i",iContactId];
                    loginResult.rCode1 = [result valueForKey:@"P2PVerifyCode1"];
                    loginResult.rCode2 = [result valueForKey:@"P2PVerifyCode2"];
                    loginResult.phone = [result valueForKey:@"PhoneNO"];
                    loginResult.email = [result valueForKey:@"Email"];
                    loginResult.sessionId = [result valueForKey:@"SessionID"];
                    loginResult.countryCode = [result valueForKey:@"CountryCode"];
                }
        
        
                callBack(loginResult);
                [result release];
                [loginResult release];
                [self resetServer];
            }
        
        }
     
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
           
            if(reconnectCount<([servers count]-1)){
                reconnectCount++;
                currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                DLog(@"change server:%@",currentServer);
                [self loginWithUserName:username password:password token:token callBack:callBack];
            }else{
                [self randomServer];
                reconnectCount = 0;
                
                LoginResult *loginResult = [[LoginResult alloc] init];
                loginResult.error_code = NET_RET_UNKNOWN_ERROR;
                
                
                
                callBack(loginResult);
                [loginResult release];
                
                
            }
        
        }
     ];
    [parameter release];
}

- (void)logoutWithUserName:(NSString*)username sessionId:(NSString*)sessionId
                  callBack:(void (^)(id JSON))callBack{
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    [self requestHttp:currentServer actionPath:@"Users/Logout.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  
                  
                  if(error_code==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self logoutWithUserName:username sessionId:sessionId callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          NSString *unknownErrorString = [NSString stringWithFormat:@"%d",NET_RET_UNKNOWN_ERROR];
                          callBack(unknownErrorString);
                      }
                  }else{
                      NSString *errorCodeString = [result valueForKey:@"error_code"];
                      callBack(errorCodeString);
                      [self resetServer];
                  }
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self logoutWithUserName:username sessionId:sessionId callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      NSString *unknownErrorString = [NSString stringWithFormat:@"%d",NET_RET_UNKNOWN_ERROR];
                      callBack(unknownErrorString);
                  }
                  
              }
     ];
    [parameter release];
}

- (void)getAccountInfo:(NSString *)username sessionId:(NSString *)sessionId callBack:(void (^)(id))callBack{
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
   
    
    
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    [parameter setObject:@"GetParam" forKey:@"Opion"];
    [self requestHttp:currentServer actionPath:@"Users/UpdateSafeSet.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  
                  
                  if(error_code==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self getAccountInfo:username sessionId:sessionId callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          AccountResult *accountResult = [[AccountResult alloc] init];
                          accountResult.error_code = NET_RET_UNKNOWN_ERROR;
                          
                          callBack(accountResult);
                          [accountResult release];
                          
                          
                      }
                  }else{
                      AccountResult *accountResult = [[AccountResult alloc] init];
                      accountResult.error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                      if(accountResult.error_code == NET_RET_GET_ACCOUNT_SUCCESS){
                          accountResult.phone = [result valueForKey:@"PhoneNO"];
                          accountResult.email = [result valueForKey:@"Email"];
                          accountResult.countryCode = [result valueForKey:@"CountryCode"];
                      }
                      
                      
                      callBack(accountResult);
                      
                      [accountResult release];
                      [self resetServer];
                  }
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self getAccountInfo:username sessionId:sessionId callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      AccountResult *accountResult = [[AccountResult alloc] init];
                      accountResult.error_code = NET_RET_UNKNOWN_ERROR;
                      
                      callBack(accountResult);
                      [accountResult release];
                      
                      
                  }
                  
              }
     ];
    [parameter release];
}

-(void)setAccountInfo:(NSString *)username password:(NSString *)password phone:(NSString *)phone email:(NSString *)email countryCode:(NSString *)countryCode phoneCheckCode:(NSString *)phoneCheckCode flag:(NSString *)flag sessionId:(NSString *)sessionId callBack:(void (^)(id))callBack{
    
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    
    
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:[password getMd5_32Bit_String] forKey:@"UserPwd"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    [parameter setObject:email forKey:@"Email"];
    [parameter setObject:phone forKey:@"PhoneNO"];
    [parameter setObject:countryCode forKey:@"CountryCode"];
    [parameter setObject:flag forKey:@"BindFlag"];
    [parameter setObject:phoneCheckCode forKey:@"PhoneCheckCode"];
    [parameter setObject:@"SetParam" forKey:@"Opion"];
    [self requestHttp:currentServer actionPath:@"Users/UpdateSafeSet.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  
                  if(error_code==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self setAccountInfo:username password:password phone:phone email:email countryCode:countryCode phoneCheckCode:phoneCheckCode flag:flag sessionId:sessionId callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          callBack(NET_RET_UNKNOWN_ERROR);
                      }
                  }else{
                      callBack(((NSString*)[result valueForKey:@"error_code"]).intValue);
                      [self resetServer];
                  }

                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self setAccountInfo:username password:password phone:phone email:email countryCode:countryCode phoneCheckCode:phoneCheckCode flag:flag sessionId:sessionId callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      callBack(NET_RET_UNKNOWN_ERROR);
                      
                  }
                  
              }
     ];
    [parameter release];
}

-(void)modifyLoginPasswordWithUserName:(NSString *)username sessionId:(NSString *)sessionId oldPwd:(NSString *)oldPwd newPwd:(NSString *)newPwd rePwd:(NSString *)rePwd callBack:(void (^)(id))callBack{
    
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];

    
    
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    [parameter setObject:[oldPwd getMd5_32Bit_String] forKey:@"OldPwd"];
    [parameter setObject:[newPwd getMd5_32Bit_String] forKey:@"Pwd"];
    [parameter setObject:[rePwd getMd5_32Bit_String] forKey:@"RePwd"];

    [self requestHttp:currentServer actionPath:@"Users/ModifyPwd.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  
                  if(error_code==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self modifyLoginPasswordWithUserName:username sessionId:sessionId oldPwd:oldPwd newPwd:newPwd rePwd:rePwd callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          callBack(NET_RET_UNKNOWN_ERROR);
                          
                      }
                  }else{
                      ModifyLoginPasswordResult *modifyLoginPasswordResult = [[ModifyLoginPasswordResult alloc] init];
                      modifyLoginPasswordResult.error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                      modifyLoginPasswordResult.sessionId = [result valueForKey:@"SessionID"];
                      callBack(modifyLoginPasswordResult);
                      [modifyLoginPasswordResult release];
                      [self resetServer];
                  }
                  [result release];
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self modifyLoginPasswordWithUserName:username sessionId:sessionId oldPwd:oldPwd newPwd:newPwd rePwd:rePwd callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      callBack(NET_RET_UNKNOWN_ERROR);
                      
                  }
                  
              }
     ];
    [parameter release];
}

-(void)getPhoneCodeWithPhone:(NSString *)phone countryCode:(NSString *)countryCode callBack:(void (^)(id))callBack{
    
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    [parameter setObject:countryCode forKey:@"CountryCode"];
    [parameter setObject:phone forKey:@"PhoneNo"];
    
    
    [self requestHttp:currentServer actionPath:@"Users/PhoneCheckCode.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  
                  if(error_code==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self getPhoneCodeWithPhone:phone countryCode:countryCode callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          callBack(NET_RET_UNKNOWN_ERROR);
                          
                      }
                  }else{
                      callBack(((NSString*)[result valueForKey:@"error_code"]).intValue);
                      [self resetServer];
                  }
                  
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self getPhoneCodeWithPhone:phone countryCode:countryCode callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      callBack(NET_RET_UNKNOWN_ERROR);
                      
                  }
                  
              }
     ];
    [parameter release];
}

-(void)registerWithVersionFlag:(NSString *)versionFlag email:(NSString *)email countryCode:(NSString *)countryCode phone:(NSString *)phone password:(NSString *)password repassword:(NSString *)repassword phoneCode:(NSString *)phoneCode callBack:(void (^)(id))callBack{
    
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    
    
    [parameter setObject:@"1" forKey:@"VersionFlag"];
    [parameter setObject:email forKey:@"Email"];
    [parameter setObject:countryCode forKey:@"CountryCode"];
    [parameter setObject:phone forKey:@"PhoneNo"];
    [parameter setObject:[password getMd5_32Bit_String] forKey:@"Pwd"];
    [parameter setObject:[repassword getMd5_32Bit_String] forKey:@"RePwd"];
    [parameter setObject:phoneCode forKey:@"VerifyCode"];
    [parameter setObject:@"1" forKey:@"IgnoreSafeWarning"];
    [self requestHttp:currentServer actionPath:@"Users/RegisterCheck.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  
                  if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self registerWithVersionFlag:versionFlag email:email countryCode:countryCode phone:phone password:password repassword:repassword phoneCode:phoneCode callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          callBack(NET_RET_UNKNOWN_ERROR);
                          
                      }
                  }else{
                      RegisterResult *registerResult = [[RegisterResult alloc] init];
                      registerResult.error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                      int iContactId = ((NSString*)[result valueForKey:@"UserID"]).integerValue & 0x7fffffff;
                      registerResult.contactId = [NSString stringWithFormat:@"0%i",iContactId];
                      callBack(registerResult);
                      [registerResult release];
                      [result release];
                      [self resetServer];
                  }
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self registerWithVersionFlag:versionFlag email:email countryCode:countryCode phone:phone password:password repassword:repassword phoneCode:phoneCode callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      callBack(NET_RET_UNKNOWN_ERROR);
                      
                  }
                  
              }
     ];
    [parameter release];
}

-(void)verifyPhoneCodeWithCode:(NSString *)phoneCode phone:(NSString *)phone countryCode:(NSString *)countryCode callBack:(void (^)(id))callBack{
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    [parameter setObject:countryCode forKey:@"CountryCode"];
    [parameter setObject:phone forKey:@"PhoneNo"];
    [parameter setObject:phoneCode forKey:@"VerifyCode"];
    
    [self requestHttp:currentServer actionPath:@"Users/PhoneVerifyCodeCheck.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  if(((NSString*)[result valueForKey:@"error_code"]).intValue==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self verifyPhoneCodeWithCode:phoneCode phone:phone countryCode:countryCode callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          callBack(NET_RET_UNKNOWN_ERROR);
                          
                      }
                  }else{
                      callBack(((NSString*)[result valueForKey:@"error_code"]).intValue);
                      [self resetServer];
                  }
                  
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self verifyPhoneCodeWithCode:phoneCode phone:phone countryCode:countryCode callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      callBack(NET_RET_UNKNOWN_ERROR);
                      
                  }
                  
              }
     ];
    [parameter release];
}

-(void)checkNewMessage:(NSString *)username sessionId:(NSString *)sessionId callBack:(void (^)(id JSON))callBack{
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    

    
    
    
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    
    
    [self requestHttp:currentServer actionPath:@"MSG/IsAnyMsgEx.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  if(((NSString*)[result valueForKey:@"error_code"]).intValue==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self checkNewMessage:username sessionId:sessionId callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          CheckNewMessageResult *checkNewMessageResult = [[CheckNewMessageResult alloc] init];
                          checkNewMessageResult.error_code = NET_RET_UNKNOWN_ERROR;
                          callBack(checkNewMessageResult);
                          [checkNewMessageResult release];

                      }
                  }else{
                      NSString *trl = [result valueForKey:@"TRL"];
                      //NSString *srl = [result valueForKey:@"SRL"];
                      DLog(@"%@",trl);
                      //DLog(@"%@",srl);
                      
                      BOOL isNewContactMessage = NO;
                      NSArray *array = [trl componentsSeparatedByString:@";"];
                      for(NSString *str in array){
                          NSArray *temp = [str componentsSeparatedByString:@":"];
                          if([[temp objectAtIndex:0] integerValue]==2&&[[temp objectAtIndex:1] integerValue]>0){
                              isNewContactMessage = YES;
                              break;
                          }
                      }
                      CheckNewMessageResult *checkNewMessageResult = [[CheckNewMessageResult alloc] init];
                      checkNewMessageResult.error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                      checkNewMessageResult.isNewContactMessage = isNewContactMessage;
                      callBack(checkNewMessageResult);
                      [checkNewMessageResult release];
                      [self resetServer];
                  }
                  
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self checkNewMessage:username sessionId:sessionId callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      CheckNewMessageResult *checkNewMessageResult = [[CheckNewMessageResult alloc] init];
                      checkNewMessageResult.error_code = NET_RET_UNKNOWN_ERROR;
                      callBack(checkNewMessageResult);
                      [checkNewMessageResult release];
                      
                  }
                  
              }
     ];
    [parameter release];

}

-(void)getContactMessageWithUsername:(NSString *)username sessionId:(NSString *)sessionId callBack:(void (^)(id))callBack{
    
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    [parameter setObject:@"2" forKey:@"MsgType"];
    
    [self requestHttp:currentServer actionPath:@"MSG/GetMsgEx.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  if(((NSString*)[result valueForKey:@"error_code"]).intValue==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self getContactMessageWithUsername:username sessionId:sessionId callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          callBack(NET_RET_UNKNOWN_ERROR);
                      }
                  }else{
                      NSString *rl = [result valueForKey:@"RL"];
                      NSString *surplus = [result valueForKey:@"Surplus"];
                      
                      NSMutableArray *datas = [NSMutableArray arrayWithCapacity:0];
                      
                      NSArray *array = [rl componentsSeparatedByString:@";"];
                      for(NSString *str in array){
                          if([str isEqualToString:@""]){
                              continue;
                          }
                          NSArray *temp = [str componentsSeparatedByString:@"&"];
                          GetContactMessageResult *getContactMessageResult = [[GetContactMessageResult alloc] init];
                          getContactMessageResult.flag = [[temp objectAtIndex:0] integerValue];
                          getContactMessageResult.contactId = [NSString stringWithFormat:@"0%d",[[temp objectAtIndex:1] integerValue]&0x7fffffff];
                          getContactMessageResult.message = [NSString stringWithFormat:@"%@",[temp objectAtIndex:3]];
                          
                          NSString *timeStr = [temp objectAtIndex:4];
                          long timeInterval = [[Utils dateFromString2:timeStr] timeIntervalSince1970];
                          getContactMessageResult.time = [NSString stringWithFormat:@"%ld",timeInterval];
                          [datas addObject:getContactMessageResult];
                          [getContactMessageResult release];
                      }

                      DLog(@"%@",rl);
                      callBack(datas);
                      
                      [self resetServer];
                  }
                  
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self getContactMessageWithUsername:username sessionId:sessionId callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      callBack(NET_RET_UNKNOWN_ERROR);
                      
                  }
                  
              }
     ];
    [parameter release];
}

-(void)checkAlarmMessage:(NSString *)username sessionId:(NSString *)sessionId callBack:(void (^)(id))callBack{
    
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    
    
    
    
    
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    
    
    [self requestHttp:currentServer actionPath:@"MSG/IsAnyMsgEx.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  if(((NSString*)[result valueForKey:@"error_code"]).intValue==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self checkNewMessage:username sessionId:sessionId callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          CheckAlarmMessageResult *checkAlarmMessageResult = [[CheckAlarmMessageResult alloc] init];
                          checkAlarmMessageResult.error_code = NET_RET_UNKNOWN_ERROR;
                          callBack(checkAlarmMessageResult);
                          [checkAlarmMessageResult release];
                      }
                  }else{
                      NSString *trl = [result valueForKey:@"TRL"];
                      NSString *srl = [result valueForKey:@"SRL"];
                      DLog(@"%@",trl);
                      DLog(@"%@",srl);
                      
                      BOOL isNewAlarmMessage = NO;
                      NSArray *array = [trl componentsSeparatedByString:@";"];
                      for(NSString *str in array){
                          NSArray *temp = [str componentsSeparatedByString:@":"];
                          if([[temp objectAtIndex:0] integerValue]==3&&[[temp objectAtIndex:1] integerValue]>0){
                              isNewAlarmMessage = YES;
                              break;
                          }
                      }
                      CheckAlarmMessageResult *checkAlarmMessageResult = [[CheckAlarmMessageResult alloc] init];
                      checkAlarmMessageResult.error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                      checkAlarmMessageResult.isNewAlarmMessage = isNewAlarmMessage;
                      callBack(checkAlarmMessageResult);
                      [checkAlarmMessageResult release];
                      [self resetServer];
                  }
                  
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self checkAlarmMessage:username sessionId:sessionId callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      CheckAlarmMessageResult *checkAlarmMessageResult = [[CheckAlarmMessageResult alloc] init];
                      checkAlarmMessageResult.error_code = NET_RET_UNKNOWN_ERROR;
                      callBack(checkAlarmMessageResult);
                      [checkAlarmMessageResult release];
                      
                  }
                  
              }
     ];
    [parameter release];
}

-(void)getAlarmMessageWithUsername:(NSString *)username sessionId:(NSString *)sessionId callBack:(void (^)(id))callBack{
    
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    [parameter setObject:@"2" forKey:@"MsgType"];
    
    [self requestHttp:currentServer actionPath:@"MSG/GetMsgEx.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  if(((NSString*)[result valueForKey:@"error_code"]).intValue==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self getContactMessageWithUsername:username sessionId:sessionId callBack:callBack];
                      }else{
                          [self randomServer];
                          reconnectCount = 0;
                          callBack(NET_RET_UNKNOWN_ERROR);
                      }
                  }else{
                      NSString *rl = [result valueForKey:@"RL"];
                      NSString *surplus = [result valueForKey:@"Surplus"];
                      
                      NSMutableArray *datas = [NSMutableArray arrayWithCapacity:0];
                      
                      NSArray *array = [rl componentsSeparatedByString:@";"];
                      for(NSString *str in array){
                          if([str isEqualToString:@""]){
                              continue;
                          }
                          NSArray *temp = [str componentsSeparatedByString:@"&"];
                          GetContactMessageResult *getContactMessageResult = [[GetContactMessageResult alloc] init];
                          getContactMessageResult.flag = [[temp objectAtIndex:0] integerValue];
                          getContactMessageResult.contactId = [NSString stringWithFormat:@"0%d",[[temp objectAtIndex:1] integerValue]&0x7fffffff];
                          getContactMessageResult.message = [NSString stringWithFormat:@"%@",[temp objectAtIndex:3]];
                          
                          NSString *timeStr = [temp objectAtIndex:4];
                          long timeInterval = [[Utils dateFromString2:timeStr] timeIntervalSince1970];
                          getContactMessageResult.time = [NSString stringWithFormat:@"%ld",timeInterval];
                          [datas addObject:getContactMessageResult];
                          [getContactMessageResult release];
                      }
                      
                      DLog(@"%@",rl);
                      callBack(datas);
                      
                      [self resetServer];
                  }
                  
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self getAlarmMessageWithUsername:username sessionId:sessionId callBack:callBack];
                  }else{
                      [self randomServer];
                      reconnectCount = 0;
                      callBack(NET_RET_UNKNOWN_ERROR);
                      
                  }
                  
              }
     ];
    [parameter release];
}

#pragma mark - 获取报警记录
- (void) getAlarmRecordWithUsername:(NSString *)username sessionId:(NSString *)sessionId option:(NSString*)option msgIndex:(NSString *)msgIndex senderList:(NSString *)senderList checkLevelType:(NSString *)checkLevelType vKey:(NSString *)vKey callBack:(void (^)(id JSON))callBack{
    if([username isEqual:@"0517400"]){
        return;
    }
    
    NSMutableDictionary *parameter = [[NSMutableDictionary alloc] init];
    
    NSInteger iUsername = username.integerValue | 0x80000000;
    [parameter setObject:[NSString stringWithFormat:@"%d",(int)iUsername] forKey:@"UserID"];
    [parameter setObject:sessionId forKey:@"SessionID"];
    if (msgIndex) {
        [parameter setObject:msgIndex forKey:@"MsgIndex"];
    }
    [parameter setObject:@"20" forKey:@"PageSize"];
    [parameter setObject:option forKey:@"Option"];
    
    [parameter setObject:senderList forKey:@"SenderList"];
    [parameter setObject:checkLevelType forKey:@"CheckLevelType"];
    
    // password encrypt
    NSString *encryptPwd = [libPwdEncrypt passwordEncryptWithPassword:vKey];
    [parameter setObject:encryptPwd forKey:@"VKey"];
    
    
    [self requestHttp:currentServer actionPath:@"Alarm/AlarmRecordEx.ashx" parameter:parameter
              success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                  
                  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithDictionary:JSON];
                  DLog(@"error_code:%@",[result valueForKey:@"error_code"]);
                  DLog(@"error:%@",[result valueForKey:@"error"]);
                  
                  int error_code = ((NSString*)[result valueForKey:@"error_code"]).intValue;
                  if(error_code==NET_RET_SESSION_ERROR){
                      [self onSessionIdError];
                  }else if(error_code==1||error_code==29||error_code==999){
                      if(reconnectCount<([servers count]-1)){
                          reconnectCount++;
                          currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                          DLog(@"change server:%@",currentServer);
                          [self getAlarmRecordWithUsername:username  sessionId:sessionId option:option msgIndex:msgIndex senderList:senderList checkLevelType:checkLevelType vKey:vKey callBack:callBack];
                      }else{
                          GetAlarmRecordResult *alarmresult = [[GetAlarmRecordResult alloc]init];
                          alarmresult.error_code = NET_RET_UNKNOWN_ERROR;
                          [self randomServer];
                          reconnectCount = 0;
                          callBack(alarmresult);
                          [alarmresult release];
                      }
                  }else{
                      GetAlarmRecordResult *alarmresult = [[GetAlarmRecordResult alloc] init];
                      alarmresult.error_code = error_code;
                      NSString *RL = [result objectForKey:@"RL"];
                      
                      NSMutableArray *alarmRecord = [NSMutableArray arrayWithCapacity:0];
                      
                      NSArray *array = [RL componentsSeparatedByString:@";"];
                      for(NSString *record in array){
                          if([record isEqualToString:@""]){
                              continue;
                          }
                          
                          NSArray *detailArray = [record componentsSeparatedByString:@"&"];
                           Alarm * alarm = [[Alarm alloc] init];
                          for (int i = 0; i < detailArray.count; i++) {                             
                              switch (i) {
                                  case 0:
                                  {
                                      alarm.msgIndex = detailArray[i];
                                  }
                                      break;
                                  case 1:
                                  {
                                      alarm.deviceId = detailArray[i];
                                  }
                                      break;
                                  case 2:
                                  {
                                      alarm.alarmTime = detailArray[i];
                                  }
                                      break;
                                  case 4:
                                  {
                                      alarm.alarmType = [detailArray[i] intValue];
                                  }
                                      break;
                                  case 5:
                                  {
                                      alarm.alarmGroup = [detailArray[i] intValue];
                                  }
                                      break;
                                  case 6:
                                  {
                                      alarm.alarmItem = [detailArray[i] intValue];
                                  }
                                      break;
                              }
                          }
                          [alarmRecord addObject:alarm];
                          [alarm release];
                      }
                      
                      alarmresult.alarmRecord = alarmRecord;
                      callBack(alarmresult);
                      [self resetServer];
                      [alarmresult release];
                  }
                  
                  [result release];
                  
                  
              }
     
              failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                  if(reconnectCount<([servers count]-1)){
                      reconnectCount++;
                      currentServer = [NSString stringWithFormat:@"%@",[servers objectAtIndex:reconnectCount]];
                      DLog(@"change server:%@",currentServer);
                      [self getAlarmRecordWithUsername:username  sessionId:sessionId option:option msgIndex:msgIndex senderList:senderList checkLevelType:checkLevelType vKey:vKey callBack:callBack];
                  }else{
                      GetAlarmRecordResult *alarmresult = [[GetAlarmRecordResult alloc]init];
                      alarmresult.error_code   = NET_RET_UNKNOWN_ERROR;
                      [self randomServer];
                      reconnectCount = 0;
                      callBack(alarmresult);
                      [alarmresult release];
                  }
                  
              }
     ];
    [parameter release];
}

@end
