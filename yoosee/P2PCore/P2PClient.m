//
//  P2PClient.m
//  Yoosee
//
//  Created by guojunyi on 14-3-25.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import "P2PClient.h"
#import "P2PCInterface.h"
#import "Utils.h"
#import "Constants.h"
#import "config.h"
#import "PAIOUnit.H"

#import "FListManager.h"
#import "mesg.h"
#import "des2.h"

#import "Alarm.h"
#import "AlarmDAO.h"

#import "RecommendInfo.h"
#import "RecommendInfoDAO.h"
#import "UDManager.h"
#import "LoginResult.h"
#import "AppDelegate.h"
//#import "MainController.h"
#import "MPNotificationView.h"
#import "CameraManager.h"
#import "RtspInterface.h"
#import "FfmpegInterface.h"
#import "UDPManager.h"

static sRecFilenameType playbackFiles[1024];//视频回放修复
static int playbackFilesLength  = 0;
static int playbackCurrentFileIndex = -1;

@implementation P2PClient

int Get3cidByIp(int dwIp)
{
    if (dwIp<256) {
        NSArray* deviceList = [[UDPManager sharedDefault]getLanDevices];
        for (int i=0; i<[deviceList count]; i++)
        {
            LocalDevice *localDevice = [deviceList objectAtIndex:i];
            NSString* address = localDevice.address;
            NSArray *array = [address componentsSeparatedByString:@"."];
            NSString* sID = [array objectAtIndex:3];
            if (sID.intValue == dwIp) {
                return localDevice.contactId.intValue;
            }
        }
    }
    return dwIp;
}

/*
 当设备密码为NULL时，
 1)初始化密码，一定要用IP连接，否则会收到sendack，却收不到msg.
 2)进行其他的SET或者GET,如果用IP,随便填个密码，都能正常进行
                    如果用ID，则会正常反应。
 所以，就有了判断“设置密码标志位”为过滤条件的情况。
 */

int GetIpBy3CID(int contactId)
{
    NSArray* deviceList = [[UDPManager sharedDefault]getLanDevices];
    
    for (int i=0; i<[deviceList count]; i++)
    {
        LocalDevice *localDevice = [deviceList objectAtIndex:i];
        if ((localDevice.contactId.intValue == contactId) &&
            (localDevice.flag == 1))
        {
            NSString* address = localDevice.address;
            NSArray *array = [address componentsSeparatedByString:@"."];
            NSString* sID = [array objectAtIndex:3];
            return sID.intValue;
        }
    }
    return contactId;
}

int GetIpBy3CIDx(int contactId)
{
    NSArray* deviceList = [[UDPManager sharedDefault]getLanDevices];
    for (int i=0; i<[deviceList count]; i++)
    {
        LocalDevice *localDevice = [deviceList objectAtIndex:i];
        if (localDevice.contactId.intValue == contactId)
        {
            NSString* address = localDevice.address;
            NSArray *array = [address componentsSeparatedByString:@"."];
            NSString* sID = [array objectAtIndex:3];
            return sID.intValue;
        }
    }
    return contactId;
}

-(void)dealloc{
    [self.callId release];
    [self.callPassword release];
    [self.loadedplaybackFiles release];//视频回放修复
    [super dealloc];
}

+ (id)sharedClient
{
    
    static P2PClient *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[P2PClient alloc] init];
        manager.isSendProcRunning = NO;
        manager.callPassword = @"";
        manager.loadedplaybackFiles = [NSMutableArray arrayWithCapacity:0];//视频回放修复add
    });
    return manager;
}

-(BOOL)p2pConnectWithId:(NSString *)contactId codeStr1:(NSString *)codeStr1 codeStr2:(NSString *)codeStr2{
    if(![contactId isValidateNumber]){
        return NO;
    }
    
    if(![codeStr1 isValidateP2PVerifyCode1OrP2PVerifyCode2]){
        return NO;
    }
    
    if(![codeStr2 isValidateP2PVerifyCode1OrP2PVerifyCode2]){
        return NO;
    }
    
    sP2PInitPrm mP2Pprm;
    mP2Pprm.dw3CID = contactId.intValue;
    mP2Pprm.dw3CID |= 0x80000000 ;
    mP2Pprm.dwCode1 = codeStr1.intValue;
    mP2Pprm.dwCode2 = codeStr2.intValue;
    
    mP2Pprm.pHostName = "|p2p1.cloudlinks.cn|p2p2.cloudlinks.cn|p2p3.cloud-links.net|p2p4.cloud-links.net";
    //mP2Pprm.pHostName = "|192.168.1.231";
    mP2Pprm.dwChNs         = 1;
	mP2Pprm.dwChBufSize[0] = 1024*512;
	mP2Pprm.dwChBufSize[1] = 1024*512;
	mP2Pprm.dwChBufSize[2] = 1024*512;
	mP2Pprm.dwChBufSize[3] = 1024*512;
	mP2Pprm.dwPassword     = 1792802871;
    
    //get CustomerID from Common-Configuration.plist
    NSString * plist = [[NSBundle mainBundle] pathForResource:@"Common-Configuration" ofType:@"plist"];
    NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:plist];
    NSArray *customerIDArray = dic[@"CustomerID"];
    mP2Pprm.dwCustomerID[0] = [customerIDArray[0] intValue];
    mP2Pprm.dwCustomerID[1] = [customerIDArray[1] intValue];
    mP2Pprm.dwCustomerID[2] = [customerIDArray[2] intValue];
    mP2Pprm.dwCustomerID[3] = [customerIDArray[3] intValue];
    mP2Pprm.dwCustomerID[4] = [customerIDArray[4] intValue];
    mP2Pprm.dwCustomerID[5] = [customerIDArray[5] intValue];
    mP2Pprm.dwCustomerID[6] = [customerIDArray[6] intValue];
    mP2Pprm.dwCustomerID[7] = [customerIDArray[7] intValue];
    mP2Pprm.dwCustomerID[8] = [customerIDArray[8] intValue];
    mP2Pprm.dwCustomerID[9] = [customerIDArray[9] intValue];
	mP2Pprm.vCallingSignal = vCallingSignal;
	mP2Pprm.vRejectSignal  = vRejectSignal;
	mP2Pprm.vAcceptSignal  = vAcceptSignal;
	mP2Pprm.vP2PConnReady  = vP2PConnReady;
    mP2Pprm.vRecvRemoteMessage = vRecvRemoteMessage;
	mP2Pprm.vSendMessageAck=    vSendMessageAck;
	mP2Pprm.vFriendsStatusUpdate = vFriendsStatusUpdate;
    mP2Pprm.vFlagUpdate = NULL;

    return fgP2PInit(&mP2Pprm);

}

//有新的系统消息回调函数
void vFlagUpdate(DWORD *pdwFlag)
{
    //     //friends update
    //    if(pdwFlag[0] > dwMyFlag[0] || dwMyFlag[0] - pdwFlag[0] > 32767)
    //    {
    //
    //    }
    
    //system message update
    //get RecommendFlag flag from local
    NSUInteger dwMyFlag = (NSUInteger)[[[NSUserDefaults standardUserDefaults] objectForKey:@"RecommendFlag"] integerValue];
    if(pdwFlag[1] > dwMyFlag || dwMyFlag - pdwFlag[1] > 32767)
    {
        return;//关闭推送
        
        //取服务器的数据  获取推荐内容列表
        // get storeID
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
            //能够推送过来，即调用vFlagUpdate，说明storeID存在
            //return ;
        }
        
        //取出最新的一条记录的Index传给服务器，获取最新的推荐列表信息（本地没有的）
        RecommendInfoDAO *recoDAO = [[RecommendInfoDAO alloc] init];
        NSArray *arr = [recoDAO findAll];
        int index = 0;
        if (arr.count > 0) {
            RecommendInfo *m = arr[0];//最新的一条记录
            index = m.messageID;
        }
        [recoDAO release];
        LoginResult * login = [UDManager getLoginInfo];
        NSInteger userID = login.contactId.integerValue | 0x80000000;
        NSString *sessionID = login.sessionId;
        NSString *urlString = [NSString stringWithFormat:@"http://192.168.1.231/Business/Seller/RecommendInfo.ashx?UserID=%d&SessionID=%@&StoreID=%@&Index=%d&PageIndex=1&PageSize=100",userID,sessionID,storeID,index];
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue ] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            
            if ((!error)) {//发送请求成功
                NSError *parseError;
                id dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
                
                int error_code = [[dictionary objectForKey:@"error_code"] intValue];
                int recordCount = [[dictionary objectForKey:@"RecordCount"] intValue];
                if (error_code == 0) {
                    //新的通知已经获取，映射
                    NSString *recommendFlag = [dictionary objectForKey:@"RecommendFlag"];
                    DWORD myFlag[4] = {0};
                    myFlag[1] = (NSUInteger)[recommendFlag integerValue];
                    vP2PSetUpdateFlag(myFlag);
                    //RecommendFlag
                    [[NSUserDefaults standardUserDefaults] setObject:recommendFlag forKey:@"RecommendFlag"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                if (error_code == 0 && recordCount > 0) {//成功获取到数据，且RL不为空
                    NSString *RL = [dictionary objectForKey:@"RL"];
                    
                    NSArray *array = [RL componentsSeparatedByString:@";"];
                    
                    for(NSString *record in array){
                        if([record isEqualToString:@""]){
                            continue;
                        }
                        
                        NSArray *detailArray = [record componentsSeparatedByString:@","];
                        RecommendInfo * recommendInfo = [[RecommendInfo alloc] init];
                        
                        for (int i = 0; i < detailArray.count; i++) {
                            switch (i) {
                                case 0://database key
                                {
                                    recommendInfo.messageID = [detailArray[i] integerValue];
                                }
                                    break;
                                case 1:
                                {
                                    NSString *title = [Utils getNormalStringByDecodedBase64String:detailArray[i]];
                                    recommendInfo.titleString = title;
                                }
                                    break;
                                case 2:
                                {
                                    NSString *content = [Utils getNormalStringByDecodedBase64String:detailArray[i]];
                                    recommendInfo.contentString = content;
                                }
                                    break;
                                case 3:
                                {
                                    recommendInfo.imageURLString = detailArray[i];
                                }
                                    break;
                                case 4:
                                {
                                    NSString *imageLinkURLString = [Utils getNormalStringByDecodedBase64String:detailArray[i]];
                                    recommendInfo.imageLinkURLString = imageLinkURLString;
                                }
                                    break;
                                case 5:
                                {
                                    //预览ID
                                }
                                    break;
                                case 6:
                                {
                                    recommendInfo.timeString = detailArray[i];
                                }
                                    break;
                                case 7:
                                {
                                    //状态
                                }
                                    break;
                            }
                        }
                        recommendInfo.isRead = NO;//YES表示已读
                        
                        //数据库的主键是唯一的，与主键相同的数据当然也插入不了。
                        RecommendInfoDAO *recoDAO = [[RecommendInfoDAO alloc] init];
                        [recoDAO insert:recommendInfo];
                        [recoDAO release];
                        [recommendInfo release];
                    }
                    
                    //新的通知已经获取，前台、后台推出告诉用户可以查看
                    
                    //需要做一些判断，有新的通知，则显示角标badge；查看新通知，清除角标
//                    MainController *mainController = [AppDelegate sharedDefault].mainController;
//                    mainController.bottomBar.isHavingNewInfo = YES;//显示、隐藏角标
//                    [mainController.bottomBar setNeedsLayout];
                    
                    //取出最新的一条记录，作为通知的推出内容
                    RecommendInfoDAO *recoDAO = [[RecommendInfoDAO alloc] init];
                    NSArray *arr = [recoDAO findAll];
                    if (arr.count > 0) {
                        RecommendInfo *m = arr[0];//最新的一条记录
                        NSString *title = m.titleString;
                        
//                        if ([AppDelegate sharedDefault].isGoBack) {
//                            //创建一个本地推送
//                            UILocalNotification *alarmNotify = [[[UILocalNotification alloc] init] autorelease];
//                            //设置3秒之后,推送时间
//                            alarmNotify.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
//                            //设置时区
//                            alarmNotify.timeZone = [NSTimeZone defaultTimeZone];
//                            //推送声音
//                            alarmNotify.soundName = @"default";
//                            //内容
//                            alarmNotify.alertBody = title;
//                            //显示在icon上的红色圈中的数子
//                            alarmNotify.applicationIconBadgeNumber = 1;
//                            //定义查看通知的操作名
//                            alarmNotify.alertAction = NSLocalizedString(@"open", nil);
//                            //添加推送到uiapplication
//                            [[UIApplication sharedApplication] scheduleLocalNotification:alarmNotify];
//                        }
                        
                        [MPNotificationView notifyWithText:NSLocalizedString(@"system_message", nil)  andDetail:title];
                    }
                    [recoDAO release];
                }else{//获取数据失败
                    //[self.view makeToast:NSLocalizedString(@"get_data_fail", nil)];
                }
                
                
            }else{//发送请求失败
                dispatch_async(dispatch_get_main_queue(), ^{
                    //[self.view makeToast:NSLocalizedString(@"send_request_fail", nil)];
                });
            }
        }];
    }
    
    //    //friends update
    //    if(pdwFlag[2] > dwMyFlag[2] || dwMyFlag[2] - pdwFlag[2] > 32767)
    //    {
    //
    //    }
    //
    //    //friends update
    //    if(pdwFlag[3] > dwMyFlag[3] || dwMyFlag[3] - pdwFlag[3] > 32767)
    //    {
    //        
    //    }
    //    
}

void commandSettingInAction(DWORD dwCmd, DWORD  dwOption , DWORD * pdwData,  DWORD  dwDataLen)
{
//    if (dwCmd == USR_CMD_REMOTLY_DEFENCE_CTL) {
//        if (dwOption == USR_CMD_OPTION_WRITE_DEFENCE_STATUS) {
//            DLog(@"NSNotificationCenter post");
//            //            [P2PClient sendNotificationMessage:pdwData[0]];
//            NSNumber *name   = [NSNumber numberWithInt:USR_CMD_REMOTLY_DEFENCE_CTL];
//            NSNumber *option = [NSNumber numberWithInt:USR_CMD_OPTION_WRITE_DEFENCE_STATUS];
//            NSNumber *value  = [NSNumber numberWithInt:pdwData[0]];
//            
//            NSDictionary *parameter = @{@"name": name,
//                                        @"option": option,
//                                        @"object" : value};
//            [[P2PClient sharedClient] receivePlayingCommand:parameter];
//            
//        }
//    }
    DLog(@"")
    if (dwCmd == USR_CMD_AUDIO_ONLY) {
        if (dwOption == 1) {
            DLog(@"开启");
        }else{
            DLog(@"关闭");
        }
        
        NSNumber *key = [NSNumber numberWithInt:RECEIVE_PLAYING_CMD_CHANGE_VIDEO_STATE];
        NSNumber *value  = [NSNumber numberWithBool:dwOption];
        NSDictionary *parameter = @{@"key": key,
                                    @"value" : value};
        [[P2PClient sharedClient] receivePlayingCommand:parameter];
       
    }
    
    if (dwCmd == USR_CMD_CURRENT_USERS_NS) {
        //NSLog(@"%i",dwOption);
        NSNumber *value  = [NSNumber numberWithInt:dwOption];
        NSDictionary *parameter = @{@"value" : value};
        [[P2PClient sharedClient] receivePlayingCommand:parameter];
    }
    
    if (dwCmd == USR_CMD_PLAY_CTL) {
        
        DLog(@"%i",dwOption);
        switch (dwOption) {
            case USR_CMD_OPTION_FILE_INFO:
            {
                [[P2PClient sharedClient] setPlaybackState:PLAYBACK_STATE_PLAYING];
                vSetSupperDrop(FALSE);
                
                [[P2PClient sharedClient] setPlayback_startTime:(((uint64_t)pdwData[0]<<32)|pdwData[1])];
                [[P2PClient sharedClient] setPlayback_endTime:(((uint64_t)pdwData[2]<<32)|pdwData[3])];
                
                UINT64 totalTime = [[P2PClient sharedClient] playback_endTime] - [[P2PClient sharedClient] playback_startTime];
                [[P2PClient sharedClient] setPlayback_totalTime:totalTime];
                
                
                //UINT64 hh = playback_totalTime/3600;
                //UINT64 mm = (playback_totalTime/60)%60;
                //UINT64 ss = playback_totalTime%60;
                
                //DLog(@"%llu %llu %llu",hh,mm,ss);
            }
                break;
            case USR_CMD_OPTION_FILE_END:
            {
                [[P2PClient sharedClient] setPlaybackState:PLAYBACK_STATE_STOP];
                NSNumber *key = [NSNumber numberWithInt:RECEIVE_PLAYING_CMD_PLAYBACK_STOP];
                
                NSDictionary *parameter = @{@"key": key};
                [[P2PClient sharedClient] receivePlayingCommand:parameter];
            }
                break;
            case USR_CMD_OPTION_STOP_RET:
            {
                [[P2PClient sharedClient] setPlaybackState:PLAYBACK_STATE_STOP];
                NSNumber *key = [NSNumber numberWithInt:RECEIVE_PLAYING_CMD_PLAYBACK_STOP];
                
                NSDictionary *parameter = @{@"key": key};
                [[P2PClient sharedClient] receivePlayingCommand:parameter];
            }
                break;
            case USR_CMD_OPTION_PLAY_RET:
            {
                 vSetSupperDrop(FALSE);
                [[P2PClient sharedClient] setPlaybackState:PLAYBACK_STATE_PLAYING];
               
                NSNumber *key = [NSNumber numberWithInt:RECEIVE_PLAYING_CMD_PLAYBACK_START];
                
                NSDictionary *parameter = @{@"key": key};
                [[P2PClient sharedClient] receivePlayingCommand:parameter];
            }
                break;
            case USR_CMD_OPTION_JUMP_RET:{
                 vSetSupperDrop(FALSE);
                [[P2PClient sharedClient] setPlaybackState:PLAYBACK_STATE_PLAYING];
                NSNumber *key = [NSNumber numberWithInt:RECEIVE_PLAYING_CMD_PLAYBACK_START];
                
                NSDictionary *parameter = @{@"key": key};
                [[P2PClient sharedClient] receivePlayingCommand:parameter];
                break;
            }
            case USR_CMD_OPTION_NEXT_FILE_RET:{
                [[P2PClient sharedClient] setPlaybackState:PLAYBACK_STATE_PLAYING];
                vSetSupperDrop(FALSE);
                NSNumber *key = [NSNumber numberWithInt:RECEIVE_PLAYING_CMD_PLAYBACK_START];
                NSDictionary *parameter = @{@"key": key};
                [[P2PClient sharedClient] receivePlayingCommand:parameter];
                break;
            }
            default:
                break;
        }
    }
    return;
}

- (void)receivePlayingCommand:(NSDictionary *)dictionary
{
    [[NSNotificationCenter defaultCenter] postNotificationName:RECEIVE_PLAYING_CMD
                                                        object:self
                                                      userInfo:dictionary];
}

-(NSInteger)getPlaybackCurrentFileIndex{
    return playbackCurrentFileIndex;
}

-(NSInteger)getPlaybackFilesLength{
    return playbackFilesLength;
}

-(void)previous{
    if(playbackCurrentFileIndex==0){
        return;
    }
    
    [[P2PClient sharedClient] setPlaybackState:PLAYBACK_STATE_STOP];
    NSNumber *key = [NSNumber numberWithInt:RECEIVE_PLAYING_CMD_PLAYBACK_STOP];
    NSDictionary *parameter = @{@"key": key};
    [[P2PClient sharedClient] receivePlayingCommand:parameter];
    BYTE prm[8];
    playbackCurrentFileIndex -= 1;
    memcpy(prm, &(playbackFiles[playbackCurrentFileIndex]), sizeof(sRecFilenameType));
    fgSendUserData(USR_CMD_PLAY_CTL, USR_CMD_OPTION_NEXT_FILE, prm, sizeof(sRecFilenameType));
    
}

-(void)next{
    if(playbackCurrentFileIndex>=(playbackFilesLength-1)){
        return;
    }
    
    [[P2PClient sharedClient] setPlaybackState:PLAYBACK_STATE_STOP];
    NSNumber *key = [NSNumber numberWithInt:RECEIVE_PLAYING_CMD_PLAYBACK_STOP];
    NSDictionary *parameter = @{@"key": key};
    [[P2PClient sharedClient] receivePlayingCommand:parameter];
    
    BYTE prm[8];
    playbackCurrentFileIndex += 1;
    memcpy(prm, &(playbackFiles[playbackCurrentFileIndex]), sizeof(sRecFilenameType));
    fgSendUserData(USR_CMD_PLAY_CTL, USR_CMD_OPTION_NEXT_FILE, prm, sizeof(sRecFilenameType));
    vSetSupperDrop(TRUE);
}

-(void)jump:(UInt64)value{
    UInt64 jumpValue = (self.playback_startTime+value*1000000);
   

    fgSendUserData(USR_CMD_PLAY_CTL, USR_CMD_OPTION_JUMP, (BYTE*)(&jumpValue), sizeof(UInt64));
    vSetSupperDrop(TRUE);
}

-(void)p2pDisconnect{
    vP2PExit();
}

#define  FLAG_VIDEO_TRANS_QVGA 	 (0)  //
#define  FLAG_VIDEO_TRANS_HD     (1)  //
#define  FLAG_VIDEO_TRANS_VGA   (2)  //
-(void)p2pCallWithId:(NSString *)contactId password:(NSString*)password callType:(P2PCallType)type{
    self.p2pCallType = type;
    self.callId = contactId;
    if(!password){
        password = @"";
    }
    if (contactId)
    {
        UINT64 iCallId = [contactId intValue];
        if ([contactId hasPrefix:@"0"]){
            iCallId |= 0x80000000;
        }
        int iTargetID = GetIpBy3CID(contactId.intValue);
        if (iTargetID != contactId.intValue) {
            iCallId = iTargetID;
        }
        NSString *callMsg = @"test callMsg";
        DWORD dwCallPrm[4];
        switch (type) {
            case P2PCALL_TYPE_MONITOR:{
                dwCallPrm[0] = CONN_TYPE_MONITOR;
                dwCallPrm[1] = LOCAL_VIDEO_ABILITY ;
                dwCallPrm[2] = FLAG_VIDEO_TRANS_VGA ;
                dwCallPrm[3] = 0 ;
                
                
                if(fgP2PCall(iCallId, 1, [password intValue], dwCallPrm, (char *)[callMsg UTF8String])){
                    DLog(@"call success.");
                }else{
                    DLog(@"call failure.");
                }
                break;
            }
            case P2PCALL_TYPE_VIDEO:{
                
                dwCallPrm[0] = CONN_TYPE_VIDEO_CALL;
                dwCallPrm[1] = LOCAL_VIDEO_ABILITY ;
                dwCallPrm[2] = 0 ;
                dwCallPrm[3] = 0 ;
                
                fgP2PCall(iCallId, 0, 0, dwCallPrm, (char *)[callMsg UTF8String]);
                break;
            }
            
            default:
                break;
        }
        
    }

}

-(void)p2pPlaybackCallWithId:(NSString *)contactId password:(NSString *)password index:(NSInteger)index{
    if(index>=playbackFilesLength){
        return;
    }
    playbackCurrentFileIndex = index;
    self.p2pCallType = P2PCALL_TYPE_PLAYBACK;
    self.callId = contactId;
    if(!password){
        password = @"";
    }
    
    
    if (contactId)
    {
        UINT64 iCallId = [contactId intValue];
        if ([contactId hasPrefix:@"0"]){
            iCallId |= 0x80000000;
        }
        int iTargetID = GetIpBy3CID(contactId.intValue);
        if (iTargetID != contactId.intValue) {
            iCallId = iTargetID;
        }
        
        NSString *callMsg = @"";
        DWORD dwCallPrm[4];
        dwCallPrm[0] = CONN_TYPE_FILE_TRANS;
        dwCallPrm[1] = LOCAL_VIDEO_ABILITY ;
        dwCallPrm[2] = ((DWORD*)(&playbackFiles[index]))[0];
        dwCallPrm[3] = ((DWORD*)(&playbackFiles[index]))[1];
        
        fgP2PCall(iCallId, 1, [password intValue], dwCallPrm, (char *)[callMsg UTF8String]);
        
    }
}

- (void)p2pAccept {
    DWORD dwCallPrm[4];
    dwCallPrm[0] = CONN_TYPE_VIDEO_CALL;
    dwCallPrm[1] = LOCAL_VIDEO_ABILITY ;
    dwCallPrm[2] = 0 ;
    dwCallPrm[3] = 0 ;
    vP2PAccept(dwCallPrm);
}

- (void)p2pHungUp
{
    vStopRecvAndDec();//停止接收并且解码
    
    vStopAVEncAndSend();//停止编码且发送
    
    vP2PHungup(FALSE);//挂断视频通话或者监控...
}

-(void)rtspHungUp
{
    [self setP2pCallState:P2PCALL_STATUS_NONE];
    [[RtspInterface sharedDefault]DestroyRtspConnection];
    [[FfmpegInterface sharedDefault]vDestoryVideoDecoder];
}

- (void)sendCommandType:(int)type andOption:(int)option
{
    fgSendUserData(type, option, NULL, 0);
}

- (void)startCall
{
    DLog(@"startCall.");
    [UIView animateWithDuration:0.1 animations:^{
        
        
    } completion:^(BOOL finished) {
        
        //srecAndDecPrm.dwConnectType = self.chattingCallType;
        //        srecAndDecPrm.dwConnectType = 1;
        
        _srecAndDecPrm.dwConnectType = self.p2pCallType;
        _srecAndDecPrm.vRecvAVData = NULL;
        _srecAndDecPrm.vRecvAVHeader = NULL;
        _srecAndDecPrm.vRecvUserDataCallBack = commandSettingInAction;
        if(fgStartRecvAndDec(&(_srecAndDecPrm))){//接收并解码
            DLog(@"fgStartRecvAndDec success.");
        }
        if (self.p2pCallType == P2PCALL_TYPE_VIDEO || self.p2pCallType == P2PCALL_TYPE_MONITOR) {
            fgStartAVEncAndSend(VIDEO_FRAME_RATE);//编码并发送
        }
    }];
    
}

#pragma mark
#pragma mark - p2p call back

void vCallingSignal(sCallingPrmType *sCallPrm) {
    unsigned int fgBCalled;
    unsigned int dwHisID;
    unsigned int dwDevType;
    unsigned int fgInSameDomain;
    unsigned int fgMonitorOnly;
    unsigned int dwRemoteChNs;
    
    fgBCalled = sCallPrm->fgBCalled;
    dwHisID = sCallPrm->dwHisID;
    dwDevType = sCallPrm->dwHisDevType;
    fgInSameDomain = sCallPrm->fgInSameDomain;
    fgMonitorOnly = sCallPrm->fgSuperCall;
    dwRemoteChNs = sCallPrm->dwRemoteChNs;
    
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    
    if(fgBCalled==1){
        [info setObject:[NSString stringWithFormat:@"%i",dwHisID&0x7fffffff] forKey:@"callId"];
        [info setObject:@"YES" forKey:@"isBCalled"];
    }else{
        //[info setObject:@"0" forKey:@"callId"];
        [info setObject:@"NO" forKey:@"isBCalled"];
    }
    
    [[P2PClient sharedClient] performSelectorOnMainThread:@selector(delegateCalling:) withObject:info waitUntilDone:YES];
}

void vRejectSignal(unsigned int fgBCalled,  unsigned int dwErrorOption)
{
    NSString *rejectMsg = nil;
	switch((int)dwErrorOption)
	{
		case CALL_ERROR_NONE:
		{
			rejectMsg = @"none";
            
			break;
		}
		case CALL_ERROR_DESID_NOT_ENABLE:
		{
			rejectMsg = @"id_disabled";
            
			break;
		}
		case CALL_ERROR_DESID_OVERDATE:
		{
			rejectMsg = @"id_overdate";
            
			break;
		}
		case CALL_ERROR_DESID_NOT_ACTIVE:
		{
			rejectMsg = @"id_inactived";
            
			break;
		}
		case CALL_ERROR_DESID_OFFLINE:
		{
			rejectMsg = @"offline";
            
			break;
		}
		case CALL_ERROR_DESID_BUSY:
		{
			rejectMsg = @"busy";
            
			break;
		}
		case CALL_ERROR_DESID_POWERDOWN:
		{
			rejectMsg = @"powerdown";
            
			break;
		}
		case CALL_ERROR_NO_HELPER:
		{
			rejectMsg = @"nohelper";
            
			break;
		}
		case CALL_ERROR_HANGUP:
		{
			rejectMsg = @"hungup";
			break;
		}
		case CALL_ERROR_TIMEOUT:
		{
			rejectMsg = @"timeout";
            
			break;
		}
		case CALL_ERROR_INTER_ERROR:
		{
			rejectMsg = @"internal_error";
            
			break;
		}
		case CALL_ERROR_RING_TIMEOUT:
		{
			rejectMsg = @"no_body";
            
			break;
		}
		case CALL_ERROR_PW_WRONG:
		{
			rejectMsg = @"pw_incrrect";
            
			break;
		}
         case CALL_ERROR_NOT_SUPPORT:
        {
            rejectMsg = @"not_support";
            
        }
		default:
			rejectMsg = @"none";
            
			break;
	}
    
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    NSNumber *errorFlag = [NSNumber numberWithInt:dwErrorOption];
    [info setObject:errorFlag forKey:@"errorFlag"];
    [[P2PClient sharedClient] performSelectorOnMainThread:@selector(delegateReject:) withObject:info waitUntilDone:YES];
    
}
#define       VIDEO_ABILITY_16_9        (1<<7)
void vAcceptSignal(unsigned int fgBCalled, unsigned int  *pdwPrm)
{
    if (pdwPrm[1]==0) {
        [[P2PClient sharedClient] setIs960P:YES];
    }else{
        [[P2PClient sharedClient] setIs960P:NO];
    }
    
    
    BOOL is16b9 = NO;
    if(pdwPrm[0]==CONN_TYPE_MONITOR||pdwPrm[0]==CONN_TYPE_FILE_TRANS||pdwPrm[0]==CONN_TYPE_VIDEO_CALL){
        if(((pdwPrm[1] >> 24)& VIDEO_ABILITY_16_9 )||((pdwPrm[1] >> 16)& VIDEO_ABILITY_16_9 ))
        {
            is16b9 = YES;
        }
    }
    NSMutableDictionary * info = [NSMutableDictionary dictionary];
    [info setObject:[NSNumber numberWithBool:is16b9] forKey:@"is16b9"];
    [[P2PClient sharedClient] performSelectorOnMainThread:@selector(delegateAccept:) withObject:info waitUntilDone:YES];
}

void vP2PConnReady(void)
{
    
	[[P2PClient sharedClient] performSelectorOnMainThread:@selector(delegateReady:) withObject:nil waitUntilDone:YES];
}




//设备在线状态获取
-(void)getContactsStates:(NSArray *)contacts{
    if(!contacts||[contacts count]==0){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateContactState" object:nil];
    }
    unsigned int tables[[contacts count]];
    for(int i=0;i<[contacts count];i++){
        
        NSString *contactId = [contacts objectAtIndex:i];
        if([contactId characterAtIndex:0]=='0'){
            tables[i] = contactId.intValue|0x80000000;
        }else{
            tables[i] = contactId.intValue;
        }
    }
    fgP2PGetFriendsStatus(tables, [contacts count]);
}

//设备在线状态更新
void   vFriendsStatusUpdate(sFriendsType * pFriends )
{
    int count = pFriends->dwFriendsCount;
    
    
    for(int i=0;i<count;i++){
        //离线的设备和IP添加的设备的state = 0 //IP添加设备
        unsigned int state = (unsigned int)pFriends->bStatus[i]&0xf;
        unsigned int type = (unsigned int)pFriends->bType[i]&0xf;
        unsigned int iContactId = (unsigned int)pFriends->dwFriends[i]&0x7fffffff;
        NSString *contactId = nil;
        
        if(((unsigned int)pFriends->dwFriends[i]&0x80000000)!=0){
            contactId = [NSString stringWithFormat:@"0%d",iContactId];
        }else{
            contactId = [NSString stringWithFormat:@"%d",iContactId];
        }
        DLog("contactId:%@  onlineState:%i",contactId,state);
        FListManager *manager = [FListManager sharedFList];
        [manager setStateWithId:contactId state:state];//设备在线状态更新
        
        if(state==1){//离线的设备返回的type都是2（CONTACT_TYPE_NPC）//IP添加设备
            [manager setTypeWithId:contactId type:type];
        }
        
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateContactState" object:nil];
    DLog(@"vFriendsStatusUpdate");
}

- (void)setDelegate:(id<P2PClientDelegate>)delegate
{
    _delegate = delegate;
}

- (void)setPlaybackDelegate:(id<P2PPlaybackDelegate>)delegate{
    _playbackDelegate = delegate;
}

#pragma mark delegate method

//The selectors performed on main thread for delegate
- (void)delegateCalling:(NSDictionary*)info {
    NSString *isBCalled = [info objectForKey:@"isBCalled"];
    
    
    if([isBCalled isEqualToString:@"YES"]){
        NSString *callId = [info objectForKey:@"callId"];
        self.callId = callId;
        self.isBCalled = YES;
    }else{
        self.isBCalled = NO;
    }
    
    self.p2pCallState = P2PCALL_STATUS_CALLING;
    if(self.isBCalled){
        self.p2pCallType = P2PCALL_TYPE_VIDEO;
    }
    if(self.p2pCallType!=P2PCALL_TYPE_PLAYBACK){
        if (self.delegate && [self.delegate respondsToSelector:@selector(P2PClientCalling:)]) {
            [self.delegate P2PClientCalling:info];
        }
    }else{
        if (self.playbackDelegate && [self.playbackDelegate respondsToSelector:@selector(P2PPlaybackCalling:)]) {
            [self.playbackDelegate P2PPlaybackCalling:info];
        }
    }
}
- (void)delegateReject:(NSDictionary*)info {
    /*
     * isRun = NO表示停止处理摄像输出数据（captureOutput）
     * isFinishCaptureOutput = NO表示停留，不往下执行，是给时间captureOutput回调做最后1次处理摄像输出数据
     * 若不停留，captureOutput回调处理摄像输出数据，可能被释放了
     */
    if(self.p2pCallType==P2PCALL_TYPE_VIDEO){
        [[CameraManager sharedManager] setIsRun:NO];
        while (![[CameraManager sharedManager] isFinishCaptureOutput])
        {
            usleep(100000);
            NSLog(@"=======*while**while**while*=======");
        }
    }
    
    
    
    if (self.p2pCallState == P2PCALL_STATUS_READY_P2P) {
        [[PAIOUnit sharedUnit] stopAudio];
        [self p2pHungUp];
    }
    
    self.p2pCallState = P2PCALL_STATUS_NONE;
   
    if(self.p2pCallType!=P2PCALL_TYPE_PLAYBACK){
        if (self.delegate && [self.delegate respondsToSelector:@selector(P2PClientReject:)]) {
            [self.delegate P2PClientReject:info];
        }
    }else{
        if (self.playbackDelegate && [self.playbackDelegate respondsToSelector:@selector(P2PPlaybackReject:)]) {
            [self.playbackDelegate P2PPlaybackReject:info];
        }
    }
}
- (void)delegateAccept:(NSDictionary*)info {

    self.is16B9 = [[info valueForKey:@"is16b9"] intValue];
    if(self.p2pCallType!=P2PCALL_TYPE_PLAYBACK){
        if (self.delegate && [self.delegate respondsToSelector:@selector(P2PClientAccept:)]) {
            [self.delegate P2PClientAccept:info];
        }
    }else{
        if (self.playbackDelegate && [self.playbackDelegate respondsToSelector:@selector(P2PPlaybackAccept:)]) {
            [self.playbackDelegate P2PPlaybackAccept:info];
        }
    }
}

- (void)delegateReady:(NSDictionary*)info {

    self.p2pCallState = P2PCALL_STATUS_READY_P2P;
    [[PAIOUnit sharedUnit] startAudioWithCallType:self.p2pCallType];
    [self performSelectorOnMainThread:@selector(startCall) withObject:nil waitUntilDone:YES];
    if(self.p2pCallType!=P2PCALL_TYPE_PLAYBACK){
        if (self.delegate && [self.delegate respondsToSelector:@selector(P2PClientReady:)]) {
            [self.delegate P2PClientReady:info];
        }
        if([[P2PClient sharedClient] p2pCallType]==P2PCALL_TYPE_MONITOR){
            //rtsp监控界面弹出修改
            /*
             * 监控连接已经准备就绪，发送监控开始渲染通知
             * 在监控界面上，接收通知，并开始渲染监控画面
             */
            [[NSNotificationCenter defaultCenter] postNotificationName:MONITOR_START_RENDER_MESSAGE
                                                                object:self
                                                              userInfo:NULL];
        }
    }else{
        if (self.playbackDelegate && [self.playbackDelegate respondsToSelector:@selector(P2PPlaybackReady:)]) {
            [self.playbackDelegate P2PPlaybackReady:info];
        }
    }
}

/*********************************************************/
#define MESG_ID_GET_PLAYBACK_FILES 2000
#define MESG_ID_GET_PLAYBACK_FILES_BY_DATE 3000
#define MESG_ID_GET_DEVICE_TIME 4000
#define MESG_ID_SET_DEVICE_TIME 5000
#define MESG_ID_GET_NPC_SETTINGS 6000
#define MESG_ID_SET_VIDEO_FORMAT 7000
#define MESG_ID_SET_VIDEO_VOLUME 8000
#define MESG_ID_SET_DEVICE_PASSWORD 9000
#define MESG_ID_SET_BUZZER 10000
#define MESG_ID_SET_MOTION 11000
#define MESG_ID_GET_ALARM_EMAIL 12000
#define MESG_ID_SET_ALARM_EMAIL 13000
#define MESG_ID_GET_BIND_ACCOUNT 14000
#define MESG_ID_SET_BIND_ACCOUNT 15000
#define MESG_ID_SET_REMOTE_DEFENCE 16000
#define MESG_ID_SET_REMOTE_RECORD 17000
#define MESG_ID_SET_RECORD_TYPE 18000
#define MESG_ID_SET_RECORD_TIME 19000
#define MESG_ID_SET_RECORD_PLAN_TIME 20000
#define MESG_ID_SET_NET_TYPE 21000
#define MESG_ID_GET_WIFI_LIST 22000
#define MESG_ID_SET_WIFI 23000
#define MESG_ID_GET_DEFENCE_AREA_STATE 24000
#define MESG_ID_SET_DEFENCE_AREA_STATE 25000
#define MESG_ID_SET_INIT_PASSWORD 26000
#define MESG_ID_CHECK_DEVICE_UPDATE 27000
#define MESG_ID_SEND_MESSAGE 28000
#define MESG_ID_GET_DEFENCE_STATE 29000
#define MESG_ID_CANCEL_DEVICE_UPDATE 30000
#define MESG_ID_DO_DEVICE_UPDATE 31000
#define MESG_ID_GET_DEVICE_INFO 32000
#define MESG_ID_SEND_CUSTOM_CMD 33000
#define MESG_ID_SET_IMAGE_INVERSION 34000
#define MESG_ID_SET_AUTO_UPDATE 35000
#define MESG_ID_SET_HUMAN_INFRARED 36000
#define MESG_ID_SET_WIRED_ALARM_INPUT 37000
#define MESG_ID_SET_WIRED_ALARM_OUTPUT 38000
#define MESG_ID_SET_VISITOR_PASSWORD 39000
#define MESG_ID_SET_DEVICE_TIME_ZONE 40000
#define MESG_ID_GET_SDCARD_INFO 41000
#define MESG_ID_SET_SDCARD_INFO 42000
#define MESG_ID_GET_DEFENCE_SWITCH_STATE 43000
#define MESG_ID_SET_DEFENCE_SWITCH_STATE 44000
#define MESG_ID_SET_GPIO_CTL 48000
#define MESG_ID_GET_LIGHT_STATE 49000
#define MESG_ID_SET_LIGHT_STATE 50000
#define MESG_ID_SET_RECORD_PRE 51000
#define MESG_ID_SET_DELETE_ALARM_PUSHID 52000
#define MESG_ID_SET_STOP_DOORBELL_PUSH 53000
#define MESG_ID_GET_DEVICE_LANGUAGE 54000
#define MESG_ID_SET_DEVICE_LANGUAGE 55000

void  vSendMessageAck(DWORD dwDesID,DWORD dwMesgID, DWORD  dwError)
{
    if (dwDesID<256) {
        dwDesID = Get3cidByIp(dwDesID);
    }
    NSNumber *result = [NSNumber numberWithInt:dwError];
    NSNumber *mesgId = [NSNumber numberWithInt:dwMesgID];
    if(dwMesgID<MESG_ID_GET_PLAYBACK_FILES&&dwMesgID>=(MESG_ID_GET_PLAYBACK_FILES-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_PLAYBACK_FILES];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_PLAYBACK_FILES_BY_DATE&&dwMesgID>=(MESG_ID_GET_PLAYBACK_FILES_BY_DATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_PLAYBACK_FILES];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_DEVICE_TIME&&dwMesgID>=(MESG_ID_GET_DEVICE_TIME-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_DEVICE_TIME];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_DEVICE_TIME&&dwMesgID>=(MESG_ID_SET_DEVICE_TIME-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_DEVICE_TIME];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_NPC_SETTINGS&&dwMesgID>=(MESG_ID_GET_NPC_SETTINGS-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_NPC_SETTINGS];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_VIDEO_FORMAT&&dwMesgID>=(MESG_ID_SET_VIDEO_FORMAT-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_VIDEO_FORMAT];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_VIDEO_VOLUME&&dwMesgID>=(MESG_ID_SET_VIDEO_VOLUME-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_VIDEO_VOLUME];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_DEVICE_PASSWORD&&dwMesgID>=(MESG_ID_SET_DEVICE_PASSWORD-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_DEVICE_PASSWORD];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_BUZZER&&dwMesgID>=(MESG_ID_SET_BUZZER-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_BUZZER];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_MOTION&&dwMesgID>=(MESG_ID_SET_MOTION-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_MOTION];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_ALARM_EMAIL&&dwMesgID>=(MESG_ID_GET_ALARM_EMAIL-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_ALARM_EMAIL];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_ALARM_EMAIL&&dwMesgID>=(MESG_ID_SET_ALARM_EMAIL-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_ALARM_EMAIL];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_BIND_ACCOUNT&&dwMesgID>=(MESG_ID_GET_BIND_ACCOUNT-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_BIND_ACCOUNT];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_BIND_ACCOUNT&&dwMesgID>=(MESG_ID_SET_BIND_ACCOUNT-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_BIND_ACCOUNT];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_REMOTE_DEFENCE&&dwMesgID>=(MESG_ID_SET_REMOTE_DEFENCE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_REMOTE_DEFENCE];
        NSString *contactId = [NSString stringWithFormat:@"%i",dwDesID];
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result,@"contactId":contactId};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_REMOTE_RECORD&&dwMesgID>=(MESG_ID_SET_REMOTE_RECORD-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_REMOTE_RECORD];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_RECORD_TYPE&&dwMesgID>=(MESG_ID_SET_RECORD_TYPE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_RECORD_TYPE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_RECORD_TIME&&dwMesgID>=(MESG_ID_SET_RECORD_TIME-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_RECORD_TIME];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_RECORD_PLAN_TIME&&dwMesgID>=(MESG_ID_SET_RECORD_PLAN_TIME-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_RECORD_PLAN_TIME];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_NET_TYPE&&dwMesgID>=(MESG_ID_SET_NET_TYPE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_NET_TYPE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_WIFI_LIST&&dwMesgID>=(MESG_ID_GET_WIFI_LIST-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_WIFI_LIST];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_WIFI&&dwMesgID>=(MESG_ID_SET_WIFI-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_WIFI];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_DEFENCE_AREA_STATE&&dwMesgID>=(MESG_ID_GET_DEFENCE_AREA_STATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_DEFENCE_AREA_STATE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_DEFENCE_AREA_STATE&&dwMesgID>=(MESG_ID_SET_DEFENCE_AREA_STATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_DEFENCE_AREA_STATE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_DEFENCE_AREA_STATE&&dwMesgID>=(MESG_ID_SET_DEFENCE_AREA_STATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_INIT_PASSWORD];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_CHECK_DEVICE_UPDATE&&dwMesgID>=(MESG_ID_CHECK_DEVICE_UPDATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_CHECK_DEVICE_UPDATE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SEND_MESSAGE&&dwMesgID>=(MESG_ID_SEND_MESSAGE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SEND_MESSAGE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result,@"flag":mesgId};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_DEFENCE_STATE&&dwMesgID>=(MESG_ID_GET_DEFENCE_STATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_DEFENCE_STATE];
        NSString *contactId = [NSString stringWithFormat:@"%i",dwDesID];
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result,@"contactId":contactId};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_DO_DEVICE_UPDATE&&dwMesgID>=(MESG_ID_DO_DEVICE_UPDATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_DO_DEVICE_UPDATE];
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_DEVICE_INFO&&dwMesgID>=(MESG_ID_GET_DEVICE_INFO-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_DEVICE_INFO];
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SEND_CUSTOM_CMD&&dwMesgID>=(MESG_ID_SEND_CUSTOM_CMD-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_CUSTOM_CMD];
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_IMAGE_INVERSION&&dwMesgID>=(MESG_ID_SET_IMAGE_INVERSION-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_IMAGE_INVERSION];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_AUTO_UPDATE&&dwMesgID>=(MESG_ID_SET_AUTO_UPDATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_AUTO_UPDATE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_HUMAN_INFRARED&&dwMesgID>=(MESG_ID_SET_HUMAN_INFRARED-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_HUMAN_INFRARED];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_WIRED_ALARM_INPUT&&dwMesgID>=(MESG_ID_SET_WIRED_ALARM_INPUT-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_WIRED_ALARM_INPUT];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_WIRED_ALARM_OUTPUT&&dwMesgID>=(MESG_ID_SET_WIRED_ALARM_OUTPUT-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_WIRED_ALARM_OUTPUT];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_VISITOR_PASSWORD&&dwMesgID>=(MESG_ID_SET_VISITOR_PASSWORD-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_VISITOR_PASSWORD];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_DEVICE_TIME_ZONE&&dwMesgID>=(MESG_ID_SET_DEVICE_TIME_ZONE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_TIME_ZONE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_SDCARD_INFO&&dwMesgID>=(MESG_ID_GET_SDCARD_INFO-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_SDCARD_INFO];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_SDCARD_INFO&&dwMesgID>=(MESG_ID_SET_SDCARD_INFO-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_SDCARD_INFO];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_DEFENCE_SWITCH_STATE&&dwMesgID>=(MESG_ID_GET_DEFENCE_SWITCH_STATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_DEFENCE_SWITCH_STATE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_DEFENCE_SWITCH_STATE&&dwMesgID>=(MESG_ID_SET_DEFENCE_SWITCH_STATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_DEFENCE_SWITCH_STATE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_GPIO_CTL&&dwMesgID>=(MESG_ID_SET_GPIO_CTL-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_GPIO_CTL];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_GET_LIGHT_STATE&&dwMesgID>=(MESG_ID_GET_LIGHT_STATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_LIGHT_STATE];
        NSString *contactId = [NSString stringWithFormat:@"%i",dwDesID];
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result,@"contactId":contactId};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if(dwMesgID<MESG_ID_SET_LIGHT_STATE&&dwMesgID>=(MESG_ID_SET_LIGHT_STATE-1000)){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_LIGHT_STATE];
        NSString *contactId = [NSString stringWithFormat:@"%i",dwDesID];
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result,@"contactId":contactId};
        
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
    }else if (dwMesgID<MESG_ID_SET_RECORD_PRE&&dwMesgID>=MESG_ID_SET_RECORD_PRE-1000){
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_NPCSETTINGS_RECORD_PRE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
        
    }else if (dwMesgID<MESG_ID_SET_DELETE_ALARM_PUSHID&&dwMesgID>=MESG_ID_SET_DELETE_ALARM_PUSHID-1000){//删除绑定的报警推送ID
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_DELETE_ALARM_PUSHID];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
        
    }else if (dwMesgID<MESG_ID_SET_STOP_DOORBELL_PUSH&&dwMesgID>=MESG_ID_SET_STOP_DOORBELL_PUSH-1000){//告诉设备端不要再推送门铃
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_STOP_DOORBELL_PUSH];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
        
    }else if (dwMesgID<MESG_ID_GET_DEVICE_LANGUAGE&&dwMesgID>=MESG_ID_GET_DEVICE_LANGUAGE-1000){//获取设备支持的语言，以及当前显示的语言
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_GET_DEVICE_LANGUAGE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
        
    }else if (dwMesgID<MESG_ID_SET_DEVICE_LANGUAGE&&dwMesgID>=MESG_ID_SET_DEVICE_LANGUAGE-1000){//设置设备支持的语言
        NSNumber *key = [NSNumber numberWithInt:ACK_RET_SET_DEVICE_LANGUAGE];
        
        NSDictionary *parameter = @{@"key":key,
                                    @"result":result};
        [[P2PClient sharedClient] ack_receiveReceiveRemoteMessage:parameter];
        
    }

    

}

void  vRecvRemoteMessage(DWORD dwSrcID,  unsigned int fgHasCheckdPassword, void *pMesg, DWORD dwMesgSize)
{
    if (dwSrcID<256) {
        dwSrcID = Get3cidByIp(dwSrcID);
    }
    
    BYTE *pMesgBuffer = (BYTE *)pMesg;
    
    if(pMesgBuffer[0]==MESG_TYPE_RET_REC_LIST){
        sMesgRetRecListType *sRetRec = (sMesgRetRecListType*)pMesg;
        
        if(sRetRec->bFileNs>128){
            return;
        }
        
        
        //防止此类问题的出现：最近1个月界面，上拉加载更多，但是未得到及时的数据返回
        //同时，点击最近3天，获取最近3天的数据；此时，设备端返回了1个月上拉加载的数据和最近3天的数据
        //此现象是不正常，所以书写以下代码避免
        if ([[P2PClient sharedClient] currentLabel] == 1) {
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForThreeDay]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForThreeDay:NO];
                return;
            }
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForOneMon]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneMon:NO];
                return;
            }
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForCustom]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForCustom:NO];
                return;
            }
            
            [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneDay:NO];
        }else if ([[P2PClient sharedClient] currentLabel] == 2){
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForOneDay]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneDay:NO];
                return;
            }
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForOneMon]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneMon:NO];
                return;
            }
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForCustom]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForCustom:NO];
                return;
            }
            
            [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForThreeDay:NO];
        }else if ([[P2PClient sharedClient] currentLabel] == 3){
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForOneDay]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneDay:NO];
                return;
            }
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForThreeDay]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForThreeDay:NO];
                return;
            }
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForCustom]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForCustom:NO];
                return;
            }
            
            [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneMon:NO];
        }else if ([[P2PClient sharedClient] currentLabel] == 4){
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForOneDay]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneDay:NO];
                return;
            }
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForThreeDay]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForThreeDay:NO];
                return;
            }
            if ([[P2PClient sharedClient] isLoadMorePlaybackFilesForOneMon]) {
                [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForOneMon:NO];
                return;
            }
            
            [[P2PClient sharedClient] setIsLoadMorePlaybackFilesForCustom:NO];
        }
        
        
        if(sRetRec->bFileNs==0){
            NSNumber *key = [NSNumber numberWithInt:RET_GET_PLAYBACK_FILES];
            NSArray *files = [NSArray arrayWithObjects:nil];
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:files forKey:@"files"];
            
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
            
        }else{
            NSMutableArray *files = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *times = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *sizes = [NSMutableArray arrayWithCapacity:0];
            
            
            
            //每次在最近一天、最近三天...之间切换时，记录文件数量的变量清0，保存已获取回放文件的数组清空
            if ([[P2PClient sharedClient] isClearPlaybackFilesLength]) {
                playbackFilesLength = 0;
                [[P2PClient sharedClient] setIsClearPlaybackFilesLength:NO];
                [[[P2PClient sharedClient] loadedplaybackFiles] removeAllObjects];
            }
            
            
            
            //sRetRec->bFileNs录像文件的个数，最大值为64
            for(int i=0;i<sRetRec->bFileNs;i++){
                char buffer[64];
                memset(buffer, 0, 64);
                sprintf(buffer, "disc%d/%04d-%02d-%02d_%02d:%02d:%02d_%c.av",
                        sRetRec->sFileName[i].bMon>>4,
                        sRetRec->sFileName[i].wYear,
                        sRetRec->sFileName[i].bMon&0xf,
                        sRetRec->sFileName[i].bDay,
                        sRetRec->sFileName[i].bHour,
                        sRetRec->sFileName[i].bMin,
                        sRetRec->sFileName[i].bSec,
                        sRetRec->sFileName[i].cType);
                
                NSString *file = [NSString stringWithUTF8String:buffer];
                
                BOOL isNewPlaybackFile = NO;
                int loadedFileCount = [[[P2PClient sharedClient] loadedplaybackFiles] count];//已经加载的回放文件个数
                NSArray *loadedplaybackFiles = [[P2PClient sharedClient] loadedplaybackFiles];//已经加载的回放文件
                
                //判断file是否已经加载过
                if (loadedFileCount > 0) {
                    for (NSString *loadedFile in loadedplaybackFiles) {
                        if ([file isEqualToString:loadedFile]) {
                            isNewPlaybackFile = NO;
                            break;
                        }
                        isNewPlaybackFile = YES;
                    }
                }else{
                    isNewPlaybackFile = YES;
                }
                
                //保存未加载过的file
                if (isNewPlaybackFile) {
                    
                    //回放文件的名称，用于界面显示
                    [files addObject:file];
                    
                    //回放文件的播放时长
                    if ((sRetRec->bOption0 & 0x01) != 0) {//支持返回播放时长
                        WORD* pSize = (WORD*)&(sRetRec->sFileName[sRetRec->bFileNs]);
                        NSNumber* number = [NSNumber numberWithInt:pSize[i]];
                        [sizes addObject:number];
                    }
                    
                    //playbackFiles用于点击播放（要注意的是，与files保持一一对应）
                    memcpy(playbackFiles+loadedFileCount, sRetRec->sFileName+i, sizeof(sRecFilenameType)*(sRetRec->bFileNs-i));
                    
                    //回放文件的名称，用于记录用户已加载的回放文件和文件的数量
                    [[[P2PClient sharedClient] loadedplaybackFiles] addObject:file];
                }
                
            }
            //已经加载的回放文件个数
            playbackFilesLength = [[[P2PClient sharedClient] loadedplaybackFiles] count];
            
            
            for(int i=0;i<sRetRec->bFileNs;i++){
                char buffer[64];
                memset(buffer, 0, 64);
                sprintf(buffer, "%04d-%02d-%02d %02d:%02d",
                        sRetRec->sFileName[i].wYear,
                        sRetRec->sFileName[i].bMon&0xf,
                        sRetRec->sFileName[i].bDay,
                        sRetRec->sFileName[i].bHour,
                        sRetRec->sFileName[i].bMin);
                
                
                NSString *time = [NSString stringWithUTF8String:buffer];
                [times addObject:time];//重复添加
            }
            
            NSNumber *key = [NSNumber numberWithInt:RET_GET_PLAYBACK_FILES];
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:files forKey:@"files"];
            [parameter setValue:times forKey:@"times"];
            [parameter setValue:sizes forKey:@"sizes"];
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }
    }else if(pMesgBuffer[0]==MESG_TYPE_RET_DATETIME){
        sMesgDateTimeType *pDate = (sMesgDateTimeType*)pMesg;
        if(pDate->bOption==1){
           
        
            NSNumber *key = [NSNumber numberWithInt:RET_GET_DEVICE_TIME];
            NSString *time = [Utils getDeviceTimeByIntValue:pDate->sMesgSysTime.wYear month:pDate->sMesgSysTime.bMon day:pDate->sMesgSysTime.bDay hour:pDate->sMesgSysTime.bHour minute:pDate->sMesgSysTime.bMin];
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            //DLog(@"%@",time);
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:time forKey:@"time"];
        
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }else{
            NSNumber *key = [NSNumber numberWithInt:RET_SET_DEVICE_TIME];
            NSNumber *result = [NSNumber numberWithInt:pDate->bOption];
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:result forKey:@"result"];
            
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }
    }else if(pMesgBuffer[0]==MESG_TYPE_RET_SETTING){
        sMessageSettingsType *pSetting = (sMessageSettingsType*)pMesg;
        pSetting->wSettingCount &= 0xff;
        if(pSetting->wSettingCount<=0){
            return;
        }
        for(int i=0;i<pSetting->wSettingCount;i++){
            if((pSetting->bOption&0xff)==1){//GET RET
                if(pSetting->sSettings[i].dwSettingID==0){
                    
                }
                switch(pSetting->sSettings[i].dwSettingID){
                    case 0:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_REMOTE_DEFENCE];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        NSString *contactId = [NSString stringWithFormat:@"%i",dwSrcID];
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        [parameter setValue:contactId forKey:@"contactId"];
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                    break;
                    case 1:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_BUZZER];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 2:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_MOTION];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 3:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_RECORD_TYPE];
                        
                        NSNumber *type = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:type forKey:@"type"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                    break;
                    case 4:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_REMOTE_RECORD];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                    break;
                    case 5:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_RECORD_PLAN_TIME];
                        
                        NSNumber *time = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:time forKey:@"time"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 8:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_VIDEO_FORMAT];
                        
                        NSNumber *type = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:type forKey:@"type"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 11:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_RECORD_TIME];
                        
                        NSNumber *time = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:time forKey:@"time"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                    break;
                    case 13:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_NET_TYPE];
                        
                        NSNumber *type = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue&0xffff];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:type forKey:@"type"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 14:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_VIDEO_VOLUME];
                        
                        NSNumber *value = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:value forKey:@"value"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    
                    case 16:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_AUTO_UPDATE];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 17:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_HUMAN_INFRARED];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 18:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_WIRED_ALARM_INPUT];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 19:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_WIRED_ALARM_OUTPUT];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 20:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_TIME_ZONE];
                        
                        NSNumber *value = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:value forKey:@"value"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 21:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_VISITOR_PASSWORD_OLD];
                        
                        NSNumber *value = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:value forKey:@"value"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 24:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_IMAGE_INVERSION];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 25:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_NPCSETTINGS_PRERECORD];
                        
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                        
                    }
                        break;
                    case 34:
                    {
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_LIGHT_SWITCH_STATE];
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSString *contactId = [NSString stringWithFormat:@"%i",dwSrcID];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:state forKey:@"state"];
                        [parameter setValue:contactId forKey:@"contactId"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 37:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_VISITOR_PASSWORD_NEW];
                        
                        NSNumber *value = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:value forKey:@"value"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case MESG_SETTING_ID_FOCUS_ZOOM:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_GET_FOCUS_ZOOM];
                        
                        NSNumber *value = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:value forKey:@"value"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                }
            }else{//SET RET
                switch(pSetting->sSettings[i].dwSettingID){
                    case 0:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_REMOTE_DEFENCE];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSNumber *state = [NSNumber numberWithInt:pSetting->sSettings[i].dwSettingValue];
                        NSString *contactId = [NSString stringWithFormat:@"%i",dwSrcID];

                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        [parameter setValue:state forKey:@"state"];
                        [parameter setValue:contactId forKey:@"contactId"];
                        
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                    break;
                    case 1:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_BUZZER];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 2:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_MOTION];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 3:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_RECORD_TYPE];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                    break;
                    case 4:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_REMOTE_RECORD];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                    break;
                    case 5:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_RECORD_PLAN_TIME];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 8:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_VIDEO_FORMAT];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 9:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_DEVICE_PASSWORD];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 11:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_RECORD_TIME];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 13:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_NET_TYPE];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 14:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_VIDEO_VOLUME];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    
                    case 16:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_AUTO_UPDATE];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 17:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_HUMAN_INFRARED];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 18:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_WIRED_ALARM_INPUT];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 19:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_WIRED_ALARM_OUTPUT];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 20:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_TIME_ZONE];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 21:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_VISITOR_PASSWORD];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 24:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_IMAGE_INVERSION];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 25:
                    {
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_NPCSETTINGS_PRERECORD];
                        
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                    case 34:
                    {
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
                        
                        NSNumber *key = [NSNumber numberWithInt:RET_SET_LIGHT_SWITCH_STATE];
                        NSNumber *result = [NSNumber numberWithInt:pSetting->bOption];
                        
                        [parameter setValue:key forKey:@"key"];
                        [parameter setValue:result forKey:@"result"];
                        
                        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
                    }
                        break;
                }
            }
        }
    }else if(pMesgBuffer[0]==MESG_TYPE_RET_EMIAL){
        sMesgEmailType *pEmail = (sMesgEmailType*)pMesg;
        /*
          bOption值（8位）
          isGetOrSet最后1位，0时表示set的回调；1时表示get的回调
          isSMTP倒数第2位，0时表示不支持SMTP；1时表示支持SMTP
          isRightPwd倒数第3位，0时表示SMTP邮箱密码错误；1时表示SMTP邮箱密码正确
          isEmailVerified倒数第5位，0时表示SMTP邮箱已验证；1时表示SMTP邮箱未验证
         */
        int isGetOrSet = (pEmail->bOption>>0)&1;
        int isSMTP = (pEmail->bOption>>1)&1;
        int isRightPwd = (pEmail->bOption>>2)&1;
        int isEmailVerified = (pEmail->bOption>>4)&1;
        if(isGetOrSet==1 && pEmail->bOption != 15){//get
            
            
            NSNumber *key = [NSNumber numberWithInt:RET_GET_ALARM_EMAIL];
            NSNumber *isSMTP_N = [NSNumber numberWithInt:isSMTP];
            NSNumber *isRightPwd_N = [NSNumber numberWithInt:isRightPwd];
            NSNumber *isEmailVerified_N = [NSNumber numberWithInt:isEmailVerified];
            NSString *email = [NSString stringWithUTF8String:pEmail->cString];
            //Smtp地址
            pEmail->cSmtpServer[63] = '\0';//强制添加结束符，避免数据错乱
            NSString *smtpServer = [NSString stringWithUTF8String:pEmail->cSmtpServer];
            NSNumber *smtpPort = [NSNumber numberWithInt:pEmail->dwSmtpPort];
            NSString *smtpUser = [NSString stringWithUTF8String:pEmail->cSmtpUser];
            //解密
            unsigned char decodeKey[8] = {0x9c, 0xae, 0x6a, 0x5a, 0xe1,0xfc,0xb0, 0x82};
            unsigned char encodePwd[64] = {0};//密文
            
            for(int j=0; j<pEmail->wLen; j++){
                encodePwd[j] = pEmail->cSmtpPwd[j];
                
            }
            
            int encryCount = 0;//表示密码加密多少次才完成
            if(pEmail->wLen%8 == 0){
                encryCount = pEmail->wLen/8;
            }else{
                encryCount = pEmail->wLen/8 + 1;
            }
            
            unsigned char decodePwd[pEmail->wLen];//存放明文
            unsigned char decodePwdTemp[8];
            unsigned char pwdTemp[8];
            for(int i=0; i<encryCount; i++){
                memset(pwdTemp, 0, sizeof(pwdTemp));
                memcpy(pwdTemp, encodePwd + i * 8, 8);
                
                memset(decodePwdTemp, 0, sizeof(decodePwdTemp));
                des(pwdTemp, decodePwdTemp, decodeKey, 0);//对密文进行解密
                
                memcpy(decodePwd + i * 8, decodePwdTemp, 8);
            }
            NSMutableString *decodeString = [NSMutableString stringWithCapacity:0];
            for(int i=0; i<encryCount*8; i++){
                [decodeString appendFormat:@"%c",decodePwd[i]];//明文字符串
            }
            NSArray *smtpPwdArr = [decodeString componentsSeparatedByString:@"##"];
            //有效的明文密码smtpPwd
            NSString *smtpPwd = [NSString stringWithFormat:@"%@",smtpPwdArr[0]];
            //加密类型
            NSNumber *encryptType = [NSNumber numberWithInt:pEmail->bEncryptType];
            //bReserve =0x01则显示手工设置(固件新版本一律回0x01),  否则不显示
            NSNumber *reserve = [NSNumber numberWithInt:pEmail->bReserve];
            
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            //DLog(@"%@",time);
            [parameter setValue:isSMTP_N forKey:@"isSMTP"];
            [parameter setValue:isRightPwd_N forKey:@"isRightPwd"];
            [parameter setValue:isEmailVerified_N forKey:@"isEmailVerified"];
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:email forKey:@"email"];
            [parameter setValue:smtpServer forKey:@"smtpServer"];
            [parameter setValue:smtpPort forKey:@"smtpPort"];
            [parameter setValue:smtpUser forKey:@"smtpUser"];
            [parameter setValue:smtpPwd forKey:@"smtpPwd"];
            [parameter setValue:encryptType forKey:@"encryptType"];
            [parameter setValue:reserve forKey:@"reserve"];
            
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }else{//set
            NSNumber *key = [NSNumber numberWithInt:RET_SET_ALARM_EMAIL];
            NSNumber *result = [NSNumber numberWithInt:isGetOrSet];
            if (pEmail->bOption == 15) {//邮箱格式错误
                result = [NSNumber numberWithInt:pEmail->bOption];
            }
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:result forKey:@"result"];
            
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }
    }else if(pMesgBuffer[0]==MESG_TYPE_RET_APPID){
        sMesgGSetAppIdType *pAppId = (sMesgGSetAppIdType*)pMesg;
        if(pAppId->bOption==1){
            
            NSString *contactId = [NSString stringWithFormat:@"%i",dwSrcID];
            NSNumber *key = [NSNumber numberWithInt:RET_GET_BIND_ACCOUNT];
            NSNumber *count = [NSNumber numberWithInt:pAppId->bAppIdCount];
            NSNumber *maxCount = [NSNumber numberWithInt:pAppId->bAppIdMAXCount];
            NSMutableArray *datas = [NSMutableArray arrayWithCapacity:0];
            if([count intValue]==1&&pAppId->dwAppId[0]==0){
            
            }else{
                for(int i=0;i<pAppId->bAppIdCount;i++){
                    [datas addObject:[NSNumber numberWithInt:pAppId->dwAppId[i]]];
                }
            }
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            [parameter setValue:contactId forKey:@"contactId"];
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:count forKey:@"count"];
            [parameter setValue:maxCount forKey:@"maxCount"];
            [parameter setValue:datas forKey:@"datas"];
            
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }else{
            NSNumber *key = [NSNumber numberWithInt:RET_SET_BIND_ACCOUNT];
            NSNumber *result = [NSNumber numberWithInt:pAppId->bOption];
            NSString *contactId = [NSString stringWithFormat:@"%i",dwSrcID];
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:result forKey:@"result"];
            [parameter setValue:contactId forKey:@"contactId"];
            
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }
    }else if(pMesgBuffer[0]==MESG_TYPE_RET_WIFILIST){
        sMesgGetWifiListType *pWifi = (sMesgGetWifiListType*)pMesg;
        sNpcWifiListType *sList = &(pWifi->sNpcWifiList);
        
        
        if(pWifi->bOption==1){
            NSNumber *key = [NSNumber numberWithInt:RET_GET_WIFI_LIST];
            NSMutableArray *types = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *names = [NSMutableArray arrayWithCapacity:0];
            NSMutableArray *strengths = [NSMutableArray arrayWithCapacity:0];
            NSNumber *count = [NSNumber numberWithInt:sList->bWifiApNs];
            NSNumber *currentIndex = [NSNumber numberWithInt:sList->wCurrentConnSSIDIndex];
            for(int i=0;i<sList->bWifiApNs;i++){
                BYTE data = sList->bEncTpSigLev[i];
                
                [types addObject:[NSNumber numberWithInt:(int)data>>4]];
                [strengths addObject:[NSNumber numberWithInt:(int)((data&0xf)&0xff)]];
                
                
                
            }
            
            
            
            char buffer[128];
            int n = 0;
            for(int i=0;i<pWifi->wLen;i++){
                if(sList->cAllESSID[i]!='\0'){
                    buffer[n] = sList->cAllESSID[i];
                    n++;
                }else{
                    buffer[n] = '\0';
                    if([NSString stringWithUTF8String:buffer]){
                        [names addObject:[NSString stringWithUTF8String:buffer]];
                    }else{
                        [names addObject:@"Error Name"];
                    }
                    
                    n = 0;
                }
            }
            
            
            
            
            if([names count]!=sList->bWifiApNs){
                DLog(@"WIFI LIST ERROR");
                return;
            }
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            //DLog(@"%@",time);
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:types forKey:@"types"];
            [parameter setValue:names forKey:@"names"];
            [parameter setValue:strengths forKey:@"strengths"];
            [parameter setValue:count forKey:@"count"];
            [parameter setValue:currentIndex forKey:@"currentIndex"];
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }else{
            NSNumber *key = [NSNumber numberWithInt:RET_SET_WIFI];
            NSNumber *result = [NSNumber numberWithInt:pWifi->bOption];
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:result forKey:@"result"];
            
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }
    }else if(pMesgBuffer[0]==MESG_TYPE_RET_ALARMCODE_STATUS){
        sMesgGetAlarmCodeType *pCode = (sMesgGetAlarmCodeType*)pMesg;
        
        
        
        if(pCode->bOption==1){
            NSNumber *key = [NSNumber numberWithInt:RET_GET_DEFENCE_AREA_STATE];
                        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            NSMutableArray *status = [NSMutableArray arrayWithCapacity:0];
            
            NSMutableArray *keyGroup = [NSMutableArray arrayWithCapacity:0];
            int keyValue = pCode->bAlarmKeySta;
            
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>0)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>1)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>2)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>3)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>4)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>5)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>6)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>7)&0x1)]];
            DLog(@"%i %i %i %i %i %i %i %i",[[keyGroup objectAtIndex:0] intValue],
                 [[keyGroup objectAtIndex:1] intValue],
                 [[keyGroup objectAtIndex:2] intValue],
                 [[keyGroup objectAtIndex:3] intValue],
                 [[keyGroup objectAtIndex:4] intValue],
                 [[keyGroup objectAtIndex:5] intValue],
                 [[keyGroup objectAtIndex:6] intValue],
                 [[keyGroup objectAtIndex:7] intValue]);
            [status addObject:keyGroup];
            for(int i=0;i<pCode->bAlarmCodeCount;i++){
                NSMutableArray *group = [NSMutableArray arrayWithCapacity:0];
                int value = pCode->bAlarmCodeSta[i];
                
                [group addObject:[NSNumber numberWithInt:((value>>0)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>1)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>2)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>3)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>4)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>5)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>6)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>7)&0x1)]];
                [status addObject:group];
                DLog(@"%i %i %i %i %i %i %i %i",[[group objectAtIndex:0] intValue],
                     [[group objectAtIndex:1] intValue],
                     [[group objectAtIndex:2] intValue],
                     [[group objectAtIndex:3] intValue],
                     [[group objectAtIndex:4] intValue],
                     [[group objectAtIndex:5] intValue],
                     [[group objectAtIndex:6] intValue],
                     [[group objectAtIndex:7] intValue]);
            }
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:status forKey:@"status"];
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }else{
            NSNumber *key = [NSNumber numberWithInt:RET_SET_DEFENCE_AREA_STATE];
            NSNumber *result = [NSNumber numberWithInt:pCode->bOption];
            NSNumber *group = [NSNumber numberWithInt:(int)pCode->bAlarmCodeSta[0]];
            NSNumber *item = [NSNumber numberWithInt:(int)pCode->bAlarmCodeSta[4]];
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:result forKey:@"result"];
            [parameter setValue:group forKey:@"group"];
            [parameter setValue:item forKey:@"item"];
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }
    }else if(pMesgBuffer[0]==MESG_TYPE_RET_DEFENCE_SWITCH_STATE){
        sMesgGetDefenceSwitchType * pSwitchState = (sMesgGetDefenceSwitchType *)pMesg;
   
        if(pSwitchState->bOption==1){//表示获取成功
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            NSNumber *key = [NSNumber numberWithInt:RET_GET_DEFENCE_SWITCH_STATE];
            NSMutableArray *switchStatus = [NSMutableArray arrayWithCapacity:0];
            
            NSMutableArray *keyGroup = [NSMutableArray arrayWithCapacity:0];
            int keyValue = pSwitchState->bReserve;
            
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>0)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>1)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>2)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>3)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>4)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>5)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>6)&0x1)]];
            [keyGroup addObject:[NSNumber numberWithInt:((keyValue>>7)&0x1)]];

            [switchStatus addObject:keyGroup];
            for(int i=0;i<pSwitchState->bDefenceSetSwitchCount;i++){
                NSMutableArray *group = [NSMutableArray arrayWithCapacity:0];
                int value = pSwitchState->bDefenceSetSwitch[i];
                
                [group addObject:[NSNumber numberWithInt:((value>>0)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>1)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>2)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>3)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>4)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>5)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>6)&0x1)]];
                [group addObject:[NSNumber numberWithInt:((value>>7)&0x1)]];
                
                [switchStatus addObject:group];

            }
            
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:switchStatus forKey:@"switchStatus"];
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }else if (pSwitchState->bOption==0){//表示设置成功
            NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
            NSNumber *key = [NSNumber numberWithInt:RET_SET_DEFENCE_SWITCH_STATE];
            NSNumber *result = [NSNumber numberWithInt:pSwitchState->bOption];
            
            [parameter setValue:key forKey:@"key"];
            [parameter setValue:result forKey:@"result"];
            
            [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
        }
    }else if(pMesgBuffer[0]==MESG_TYPE_RET_INIT_PASSWD){
        sMesgSetInitPasswdType *pPassword = (sMesgSetInitPasswdType*)pMesg;
        
        NSNumber *key = [NSNumber numberWithInt:RET_SET_INIT_PASSWORD];
        NSNumber *result = [NSNumber numberWithInt:pPassword->bOption];
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        [parameter setValue:key forKey:@"key"];
        [parameter setValue:result forKey:@"result"];
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0]==MESG_TYPE_UPG_CHEK_VERSION_RET){
        sMesgUpgType *pUpg = (sMesgUpgType*)pMesg;
        
        int iCurVersion = pUpg->sRemoteUpgMesg.dwUpgID;
        int iUpgVersion = pUpg->sRemoteUpgMesg.dwUpgVal;
        
        int a = iCurVersion&0xff;
        int b = (iCurVersion>>8)&0xff;
        int c = (iCurVersion>>16)&0xff;
        int d = (iCurVersion>>24)&0xff;
        
        int e = iUpgVersion&0xff;
        int f = (iUpgVersion>>8)&0xff;
        int g = (iUpgVersion>>16)&0xff;
        int h = (iUpgVersion>>24)&0xff;
        
        NSNumber *key = [NSNumber numberWithInt:RET_CHECK_DEVICE_UPDATE];
        NSNumber *result = [NSNumber numberWithInt:pUpg->bOption];
        NSString *curVersion = [NSString stringWithFormat:@"%i.%i.%i.%i",d,c,b,a];
        NSString *upgVersion = [NSString stringWithFormat:@"%i.%i.%i.%i",h,g,f,e];
        NSString *contactId = [NSString stringWithFormat:@"%i",dwSrcID];//设备检查更新
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        [parameter setValue:key forKey:@"key"];
        [parameter setValue:curVersion forKey:@"curVersion"];
        [parameter setValue:upgVersion forKey:@"upgVersion"];
        [parameter setValue:result forKey:@"result"];
        [parameter setValue:contactId forKey:@"contactId"];//设备检查更新
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0]==MESG_TYPE_UPG_FILE_TO_DOWNLOAD_RET){
        sMesgUpgType *pUpg = (sMesgUpgType*)pMesg;
        
        
        NSNumber *key = [NSNumber numberWithInt:RET_DO_DEVICE_UPDATE];
        NSNumber *result = [NSNumber numberWithInt:pUpg->bOption];
        NSNumber *value = [NSNumber numberWithInt:pUpg->sRemoteUpgMesg.dwUpgVal];
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        [parameter setValue:key forKey:@"key"];
        [parameter setValue:value forKey:@"value"];
        [parameter setValue:result forKey:@"result"];
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0]==MESG_TYPE_DEVICE_NOT_SUPPORT_RET){
        
        NSNumber *key = [NSNumber numberWithInt:RET_DEVICE_NOT_SUPPORT];
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        [parameter setValue:key forKey:@"key"];
        
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0]==MESG_TYPE_MESSAGE){
        
        NSNumber *key = [NSNumber numberWithInt:RET_RECEIVE_MESSAGE];
        
        sMesgStringMesgType *pMessage = (sMesgStringMesgType*)pMesg;
        
        if(pMessage->wLen<=0) return;
        
        pMessage->cString[pMessage->wLen] = 0;
        NSString *message = [NSString stringWithUTF8String:pMessage->cString];
        NSString *contactId = [NSString stringWithFormat:@"0%d",dwSrcID&0x7fffffff];
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        [parameter setValue:key forKey:@"key"];
        [parameter setValue:message forKey:@"message"];
        [parameter setValue:contactId forKey:@"contactId"];
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0]==MESG_TYPE_ALARM_CALL){
        sMesgAlarmInfoType *pAlarm = (sMesgAlarmInfoType*)pMesg;
        
        int isSupport = 0;
        if((pMesgBuffer[2]&0x1)==1){
            isSupport = 1;
        }else{
            isSupport = 0;
        }
        
        //YES 表示删除绑定的报警推送ID
        BOOL isSupportDelAlarmPushId;//删除绑定的报警推送ID
        if(((pMesgBuffer[2]>>2)&0x01)==1){
            isSupportDelAlarmPushId = YES;
        }else{
            isSupportDelAlarmPushId = NO;
        }
        NSNumber *supportDelAlarmPushId = [NSNumber numberWithBool:isSupportDelAlarmPushId];
        
        NSString *contactId = [NSString stringWithFormat:@"%i",dwSrcID];
        NSNumber *type = [NSNumber numberWithInt:pMesgBuffer[1]];
        NSNumber *isSupportExternAlarm = [NSNumber numberWithInt:isSupport];
        NSNumber *group = [NSNumber numberWithInt:pAlarm->sAlarmCodes.dwAlarmCodeID];
        NSNumber *item = [NSNumber numberWithInt:pAlarm->sAlarmCodes.dwAlarmCodeIndex];
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        [parameter setValue:contactId forKey:@"contactId"];
        [parameter setValue:type forKey:@"type"];
        [parameter setValue:isSupportExternAlarm forKey:@"isSupportExternAlarm"];
        [parameter setValue:supportDelAlarmPushId forKey:@"isSupportDelAlarmPushId"];//删除绑定的报警推送ID
        [parameter setValue:group forKey:@"group"];
        [parameter setValue:item forKey:@"item"];
        [[P2PClient sharedClient] receiveReceiveAlarmMessage:parameter];
        
        NSString *deviceId   = [parameter valueForKey:@"contactId"];
        int alarmType   = [[parameter valueForKey:@"type"] intValue];
        int alarmGroup   = [[parameter valueForKey:@"group"] intValue];
        int alarmItem   = [[parameter valueForKey:@"item"] intValue];
        
        Alarm * alarm = [[Alarm alloc]init];
        AlarmDAO * alarmDAO = [[AlarmDAO alloc]init];
        alarm.deviceId = deviceId;
        alarm.alarmTime = [NSString stringWithFormat:@"%ld",[Utils getCurrentTimeInterval]];
        alarm.alarmType = alarmType;
        alarm.alarmGroup = alarmGroup;
        alarm.alarmItem = alarmItem;
        
        NSString * plist = [[NSBundle mainBundle] pathForResource:@"Common-Configuration" ofType:@"plist"];
        NSDictionary * dic = [NSDictionary dictionaryWithContentsOfFile:plist];
        BOOL isLocalAlarmRecord = [dic[@"isLocalAlarmRecord"] boolValue];
        if (isLocalAlarmRecord) {//YES则保存到本地
            [alarmDAO insert:alarm];
        }
        [alarm release];
        [alarmDAO release];

        
    }else if(pMesgBuffer[0]==MESG_TYPE_GET_SYS_VERSION_RET){
        sMesgSysVersionType *pVersion = (sMesgSysVersionType*)pMesg;
        int iCurVersion = pVersion->dwCurAppVersion;
        int iKernelVersion = pVersion->dwKernelVersion;
        int iRootfsVersion = pVersion->dwRootfsVersion;
        int iUbootVersion = pVersion->dwUbootVersion;
        int a = iCurVersion&0xff;
        int b = (iCurVersion>>8)&0xff;
        int c = (iCurVersion>>16)&0xff;
        int d = (iCurVersion>>24)&0xff;

        NSNumber *key = [NSNumber numberWithInt:RET_GET_DEVICE_INFO];
        NSNumber *result = [NSNumber numberWithInt:pVersion->bOption];
        NSString *curVersion = [NSString stringWithFormat:@"%i.%i.%i.%i",d,c,b,a];
        NSString *kernelVersion = [NSString stringWithFormat:@"%i",iKernelVersion];
        NSString *rootfsVersion = [NSString stringWithFormat:@"%i",iRootfsVersion];
        NSString *ubootVersion = [NSString stringWithFormat:@"%i",iUbootVersion];
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        [parameter setValue:key forKey:@"key"];
        [parameter setValue:curVersion forKey:@"curVersion"];
        [parameter setValue:ubootVersion forKey:@"ubootVersion"];
        [parameter setValue:kernelVersion forKey:@"kernelVersion"];
        [parameter setValue:rootfsVersion forKey:@"rootfsVersion"];
        [parameter setValue:result forKey:@"result"];
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0]==MESG_TYPE_USER_CMD_RET){
        UserCmdMesg *pMessage = (UserCmdMesg*)pMesg;
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        NSNumber *key = [NSNumber numberWithInt:RET_CUSTOM_CMD];
        [parameter setValue:key forKey:@"key"];
        
        if(pMessage->len<=0) return;
        
        NSString * result = [NSString stringWithFormat:@"%d",pMessage->bOption];
        [parameter setValue:result forKey:@"result"];
        
//        if (pMessage->bOption == 1) {
//            
//        }
        NSString *cmd = [NSString stringWithUTF8String:pMessage->Data];
        [parameter setValue:cmd forKey:@"cmd"];
        
        NSString *contactId = [NSString stringWithFormat:@"%i",dwSrcID];
        [parameter setValue:contactId forKey:@"contactId"];
        
        [[P2PClient sharedClient] receiveReceiveDoorBellAlarmMessage:parameter];
    }else if(pMesgBuffer[0] == MESG_TYPE_GET_SDCARD_INFO){
        sMesgSDCardInfoType * sSDCardInfo = (sMesgSDCardInfoType *)pMesg;
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        NSNumber *key = [NSNumber numberWithInt:RET_GET_SDCARD_INFO];
        [parameter setValue:key forKey:@"key"];
        
        NSString * result = [NSString stringWithFormat:@"%d",sSDCardInfo->bOption];
        [parameter setValue:result forKey:@"result"];
        
        if (sSDCardInfo->bOption == 1) {
            NSString * storageCount = [NSString stringWithFormat:@"%d",sSDCardInfo->wSDCardCount];
            [parameter setValue:storageCount forKey:@"storageCount"];
            
            int storageID;
            storageID = sSDCardInfo->sSDCard[0].bSDCardID;
            int storageType = storageID & 16;
            [parameter setValue:[NSString stringWithFormat:@"%d",storageType] forKeyPath:@"storageType"];
            
            if (storageType == SDCARD) {
                [parameter setValue:[NSString stringWithFormat:@"%d",storageID] forKeyPath:@"sdCardID"];
                
                NSString * sdTotalStorage = [NSString stringWithFormat:@"%llu",sSDCardInfo->sSDCard[0].u64SDTotalSpace/(1024*1024)];
                [parameter setValue:sdTotalStorage forKey:@"sdTotalStorage"];
                NSString * sdFreeStorage = [NSString stringWithFormat:@"%llu",sSDCardInfo->sSDCard[0].u64SDCardFreeSpace/(1024*1024)];
                [parameter setValue:sdFreeStorage forKey:@"sdFreeStorage"];
            }else{
                NSString * usbTotalStorage = [NSString stringWithFormat:@"%llu",sSDCardInfo->sSDCard[0].u64SDTotalSpace/(1024*1024)];
                [parameter setValue:usbTotalStorage forKey:@"usbTotalStorage"];
                NSString * usbFreeStorage = [NSString stringWithFormat:@"%llu",sSDCardInfo->sSDCard[0].u64SDCardFreeSpace/(1024*1024)];
                [parameter setValue:usbFreeStorage forKey:@"usbFreeStorage"];
            }
            
            if (sSDCardInfo->wSDCardCount > 1) {
                if (storageType == SDCARD) {
                    NSString * usbTotalStorage = [NSString stringWithFormat:@"%llu",sSDCardInfo->sSDCard[1].u64SDTotalSpace/(1024*1024)];
                    [parameter setValue:usbTotalStorage forKey:@"usbTotalStorage"];
                    NSString * usbFreeStorage = [NSString stringWithFormat:@"%llu",sSDCardInfo->sSDCard[1].u64SDCardFreeSpace/(1024*1024)];
                    [parameter setValue:usbFreeStorage forKey:@"usbFreeStorage"];
                }else{
                    NSString * sdTotalStorage = [NSString stringWithFormat:@"%llu",sSDCardInfo->sSDCard[0].u64SDTotalSpace/(1024*1024)];
                    [parameter setValue:sdTotalStorage forKey:@"sdTotalStorage"];
                    NSString * sdFreeStorage = [NSString stringWithFormat:@"%llu",sSDCardInfo->sSDCard[0].u64SDCardFreeSpace/(1024*1024)];
                    [parameter setValue:sdFreeStorage forKey:@"sdFreeStorage"];
                }
            }
        }else{//MESG_SDCARD_NO_EXIST
            //sd卡不存在
        }
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0] == MESG_TYPE_SET_FORMAT_SDCARD){
        sMesgSDCardFormatType * sSDCardFormat = (sMesgSDCardFormatType *)pMesg;
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        NSNumber *key = [NSNumber numberWithInt:RET_SET_SDCARD_FORMAT];
        [parameter setValue:key forKey:@"key"];
        NSNumber * result = [NSNumber numberWithInt:sSDCardFormat->bOption];
        [parameter setValue:result forKey:@"result"];
        
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0] == MESG_TYPE_RET_GPIO_CTL){
        sMesgSetGpioCtrl * sSetGpioCtrl = (sMesgSetGpioCtrl *)pMesg;
        
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        
        NSNumber *key = [NSNumber numberWithInt:RET_SET_GPIO_CTL];
        [parameter setValue:key forKey:@"key"];
        
        NSNumber * result = [NSNumber numberWithInt:sSetGpioCtrl->bOption];
        [parameter setValue:result forKey:@"result"];
        
        //还没实现接收函数
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0] == MESG_TYPE_CUSTOM_CMD_NO_VERRIFY_RET){
        sMesgCustomNoVerifyCmdType * sMessage = (sMesgCustomNoVerifyCmdType *)pMesg;//删除绑定推送ID或者告诉设备端不要再推送门铃
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        NSNumber *key = [NSNumber numberWithInt:RET_SET_DELETE_ALARM_PUSHID];
        [parameter setValue:key forKey:@"key"];
        //0表示解绑成功
        NSNumber * result = [NSNumber numberWithInt:sMessage->bOption];
        [parameter setValue:result forKey:@"result"];
        
        
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }else if(pMesgBuffer[0] == MESG_TYPE_RET_DEVICE_LANGUAGE){
        sMesgDeviceLanguageCmdType * sMessage = (sMesgDeviceLanguageCmdType *)pMesg;//设备语言消息结构体
        
        NSMutableDictionary *parameter = [NSMutableDictionary dictionaryWithCapacity:0];
        /*
         *bOption:
         *当 bOption == 0 时,表示设置语言成功;当 bOption == 1 时,表示获取语言信息成功;
         *当 bOption ==254 时,表示设置语言的参数错误,如设置了不支持的语言
         */
        if (sMessage->bOption == MESG_GET_OK) {
            //语言种类个数
            NSNumber * supportLanguageCount = [NSNumber numberWithInt:sMessage->bSupportLanguageCount];
            [parameter setValue:supportLanguageCount forKey:@"supportLanguageCount"];
            
            //当前的语言
            NSNumber * currentLanguage = [NSNumber numberWithInt:sMessage->bCurLanguage];
            [parameter setValue:currentLanguage forKey:@"currentLanguage"];
            
            //语言种类有
            NSMutableArray *languageSupports = [NSMutableArray arrayWithCapacity:0];
            for (int i=0; i<sMessage->bSupportLanguageCount; i++) {
                NSNumber * languageSupport = [NSNumber numberWithInt:sMessage->bLanguageSupport[i]];
                [languageSupports addObject:languageSupport];
            }
            [parameter setValue:languageSupports forKey:@"languageSupports"];
            
            
            NSNumber *key = [NSNumber numberWithInt:RET_GET_DEVICE_LANGUAGE];
            [parameter setValue:key forKey:@"key"];
            
        }else{
            //语言种类个数
            NSNumber * supportLanguageCount = [NSNumber numberWithInt:sMessage->bSupportLanguageCount];
            [parameter setValue:supportLanguageCount forKey:@"supportLanguageCount"];
            
            //当前的语言
            NSNumber * currentLanguage = [NSNumber numberWithInt:sMessage->bCurLanguage];
            [parameter setValue:currentLanguage forKey:@"currentLanguage"];
            
            //语言种类有
            NSMutableArray *languageSupports = [NSMutableArray arrayWithCapacity:0];
            for (int i=0; i<sMessage->bSupportLanguageCount; i++) {
                NSNumber * languageSupport = [NSNumber numberWithInt:sMessage->bLanguageSupport[i]];
                [languageSupports addObject:languageSupport];
            }
            [parameter setValue:languageSupports forKey:@"languageSupports"];
            
            
            NSNumber *key = [NSNumber numberWithInt:RET_SET_DEVICE_LANGUAGE];
            [parameter setValue:key forKey:@"key"];
        }
        
        NSNumber * result = [NSNumber numberWithInt:sMessage->bOption];
        [parameter setValue:result forKey:@"result"];
        
        [[P2PClient sharedClient] receiveReceiveRemoteMessage:parameter];
    }
    
    
}

- (void)receiveReceiveAlarmMessage:(NSDictionary *)dictionary{
    [[NSNotificationCenter defaultCenter] postNotificationName:RECEIVE_ALARM_MESSAGE
                                                        object:self
                                                      userInfo:dictionary];
}

- (void)receiveReceiveDoorBellAlarmMessage:(NSDictionary *)dictionary{
    [[NSNotificationCenter defaultCenter] postNotificationName:RECEIVE_DOORBELL_ALARM_MESSAGE
                                                        object:self
                                                      userInfo:dictionary];
}

- (void)receiveReceiveRemoteMessage:(NSDictionary *)dictionary{
    [[NSNotificationCenter defaultCenter] postNotificationName:RECEIVE_REMOTE_MESSAGE
                                                        object:self
                                                      userInfo:dictionary];
}

- (void)ack_receiveReceiveRemoteMessage:(NSDictionary *)dictionary{
    [[NSNotificationCenter defaultCenter] postNotificationName:ACK_RECEIVE_REMOTE_MESSAGE
                                                        object:self
                                                      userInfo:dictionary];
}

-(void)getPlaybackFilesWithId:(NSString *)contactId password:(NSString *)password timeInterval:(NSInteger)interval{
    static int mesg_id = MESG_ID_GET_PLAYBACK_FILES-1000;
    if(mesg_id>=MESG_ID_GET_PLAYBACK_FILES){
        mesg_id = MESG_ID_GET_PLAYBACK_FILES-1000;
    }
    
    //today
    NSDate *nowDate = [NSDate date];
    //interval（1或3...）天前
    NSDate *startDate = [nowDate dateByAddingTimeInterval: -(interval*24*60*60)];
    NSDateComponents* nowCompents = [Utils getDateComponentsByDate:nowDate];
    NSDateComponents* startCompents = [Utils getDateComponentsByDate:startDate];
    
    sMesgGetRecListType sGetRec;
    sGetRec.bCmd = MESG_TYPE_GET_REC_LIST;
    sGetRec.bOption = 1;//1可以获取回放文件的播放时长
    sGetRec.wOption = 0;
    
    //获取播放文件的开始时间
    sGetRec.sBeginTime.wYear = (int)[startCompents year];
    sGetRec.sBeginTime.bMon = (int)[startCompents month];
    sGetRec.sBeginTime.bDay = (int)[startCompents day];
    sGetRec.sBeginTime.bHour = (int)[startCompents hour];
    sGetRec.sBeginTime.bMin = (int)[startCompents minute];
    
    //获取播放文件的结束时间
    sGetRec.sEndTime.wYear = (int)[nowCompents year];
    sGetRec.sEndTime.bMon = (int)[nowCompents month];
    sGetRec.sEndTime.bDay = (int)[nowCompents day];
    sGetRec.sEndTime.bHour = (int)[nowCompents hour];
    sGetRec.sEndTime.bMin = (int)[nowCompents minute];
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sGetRec, sizeof(sMesgGetRecListType), NULL, 0, 0);
    mesg_id++;
    
}

-(void)getPlaybackFilesWithIdByDate:(NSString *)contactId password:(NSString *)password startDate:(NSDate *)startDate endDate:(NSDate *)endDate{
    static int mesg_id = MESG_ID_GET_PLAYBACK_FILES_BY_DATE-1000;
    if(mesg_id>=MESG_ID_GET_PLAYBACK_FILES_BY_DATE){
        mesg_id = MESG_ID_GET_PLAYBACK_FILES_BY_DATE-1000;
    }
    
    NSDateComponents *startdateComponents = [Utils getDateComponentsByDate:startDate];
    
    int start_year = [startdateComponents year];
    int start_month = [startdateComponents month];
    int start_day = [startdateComponents day];
    int start_hour = [startdateComponents hour];
    int start_minute = [startdateComponents minute];
    
    NSDateComponents *enddateComponents = [Utils getDateComponentsByDate:endDate];
    
    int end_year = [enddateComponents year];
    int end_month = [enddateComponents month];
    int end_day = [enddateComponents day];
    int end_hour = [enddateComponents hour];
    int end_minute = [enddateComponents minute];
    
    
    sMesgGetRecListType sGetRec;
    sGetRec.bCmd = MESG_TYPE_GET_REC_LIST;
    sGetRec.bOption = 1;
    sGetRec.wOption = 0;
    sGetRec.sBeginTime.wYear = start_year;
    sGetRec.sBeginTime.bMon = start_month;
    sGetRec.sBeginTime.bDay = start_day;
    sGetRec.sBeginTime.bHour = start_hour;
    sGetRec.sBeginTime.bMin = start_minute;
    
    
    sGetRec.sEndTime.wYear = end_year;
    sGetRec.sEndTime.bMon = end_month;
    sGetRec.sEndTime.bDay = end_day;
    sGetRec.sEndTime.bHour = end_hour;
    sGetRec.sEndTime.bMin = end_minute;
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sGetRec, sizeof(sMesgGetRecListType), NULL, 0, 0);
    mesg_id++;

}

-(void)getDeviceTimeWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_DEVICE_TIME-1000;
    if(mesg_id>=MESG_ID_GET_DEVICE_TIME){
        mesg_id = MESG_ID_GET_DEVICE_TIME-1000;
    }
    sMesgDateTimeType sDate;
    sDate.bCmd = MESG_TYPE_GET_DATETIME;
    sDate.bOption = 0;
    sDate.wOption = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sDate, sizeof(sMesgDateTimeType), NULL, 0, 0);
    mesg_id++;
}

-(void)setDeviceTimeWithId:(NSString *)contactId password:(NSString *)password year:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute{
    static int mesg_id = MESG_ID_SET_DEVICE_TIME-1000;
    if(mesg_id>=MESG_ID_SET_DEVICE_TIME){
        mesg_id = MESG_ID_SET_DEVICE_TIME-1000;
    }
    sMesgDateTimeType sDate;
    sDate.bCmd = MESG_TYPE_SET_DATETIME;
    sDate.bOption = 0;
    sDate.wOption = 0;
    
    sDate.sMesgSysTime.wYear = year;
    sDate.sMesgSysTime.bMon = month;
    sDate.sMesgSysTime.bDay = day;
    sDate.sMesgSysTime.bHour = hour;
    sDate.sMesgSysTime.bMin = minute;
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sDate, sizeof(sMesgDateTimeType), NULL, 0, 0);
    mesg_id++;
}

-(void)getSDCardInfoWithId:(NSString *)contactId password:(NSString *)password
{
    static int mesg_id = MESG_ID_GET_SDCARD_INFO - 1000;
    if (mesg_id >= MESG_ID_GET_SDCARD_INFO) {
        mesg_id = MESG_ID_GET_SDCARD_INFO - 1000;
    }
    
    sMesgSDCardInfoType sSDCardInfo;
    sSDCardInfo.bCommandType = MESG_TYPE_GET_SDCARD_INFO;
    sSDCardInfo.bOption = 0;
    sSDCardInfo.wSDCardCount = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSDCardInfo, sizeof(sMesgSDCardInfoType), NULL, 0, 0);
    mesg_id++;
}

-(void)setSDCardInfoWithId:(NSString *)contactId password:(NSString *)password sdcardID:(int)sdcardID
{
    static int mesg_id = MESG_ID_SET_SDCARD_INFO - 1000;
    if (mesg_id >= MESG_ID_SET_SDCARD_INFO) {
        mesg_id = MESG_ID_SET_SDCARD_INFO - 1000;
    }
    
    sMesgSDCardFormatType sSDCardFormat;
    sSDCardFormat.bCommandType = MESG_TYPE_SET_FORMAT_SDCARD;
    sSDCardFormat.bOption = 0;
    sSDCardFormat.wRemainByte = 0;
    sSDCardFormat.bSDCardID = sdcardID;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSDCardFormat, sizeof(sMesgSDCardFormatType), NULL, 0, 0);
    mesg_id++;
}

-(void)getNpcSettingsWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_NPC_SETTINGS-1000;
    if(mesg_id>=MESG_ID_GET_NPC_SETTINGS){
        mesg_id = MESG_ID_GET_DEVICE_TIME-1000;
    }
    BYTE pMessageBody[4];
    pMessageBody[0] = MESG_TYPE_GET_SETTING;
    pMessageBody[1] = 0;
    pMessageBody[2] = 0;
    pMessageBody[3] = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, pMessageBody, 4, NULL, 0, 0);
    mesg_id++;
}

-(void)getDefenceState:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_DEFENCE_STATE-1000;
    if(mesg_id>=MESG_ID_GET_DEFENCE_STATE){
        mesg_id = MESG_ID_GET_DEFENCE_STATE-1000;
    }
    BYTE pMessageBody[4];
    pMessageBody[0] = MESG_TYPE_GET_SETTING;
    pMessageBody[1] = 0;
    pMessageBody[2] = 0;
    pMessageBody[3] = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, pMessageBody, 4, NULL, 0, 0);
    mesg_id++;
}

-(void)setVideoFormatWithId:(NSString *)contactId password:(NSString *)password type:(NSInteger)type{
    static int mesg_id = MESG_ID_SET_VIDEO_FORMAT-1000;
    if(mesg_id>=MESG_ID_SET_VIDEO_FORMAT){
        mesg_id = MESG_ID_SET_VIDEO_FORMAT-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 8;
    sSetting.sSettings[0].dwSettingValue = type;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setVideoVolumeWithId:(NSString *)contactId password:(NSString *)password value:(NSInteger)value{
    static int mesg_id = MESG_ID_SET_VIDEO_VOLUME-1000;
    if(mesg_id>=MESG_ID_SET_VIDEO_VOLUME){
        mesg_id = MESG_ID_SET_VIDEO_VOLUME-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 14;
    sSetting.sSettings[0].dwSettingValue = value;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setDevicePasswordWithId:(NSString *)contactId password:(NSString *)password newPassword:(NSString *)newPassword{
    
    static int mesg_id = MESG_ID_SET_DEVICE_PASSWORD-1000;
    if(mesg_id>=MESG_ID_SET_DEVICE_PASSWORD){
        mesg_id = MESG_ID_SET_DEVICE_PASSWORD-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 9;
    sSetting.sSettings[0].dwSettingValue = newPassword.intValue;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setVisitorPasswordWithId:(NSString *)contactId password:(NSString *)password newPassword:(NSString *)newPassword{
    static int mesg_id = MESG_ID_SET_VISITOR_PASSWORD-1000;
    if(mesg_id>=MESG_ID_SET_VISITOR_PASSWORD){
        mesg_id = MESG_ID_SET_VISITOR_PASSWORD-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 21;
    sSetting.sSettings[0].dwSettingValue = newPassword.intValue;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setBuzzerWithId:(NSString *)contactId password:(NSString *)password state:(NSInteger)state{
    static int mesg_id = MESG_ID_SET_BUZZER-1000;
    if(mesg_id>=MESG_ID_SET_BUZZER){
        mesg_id = MESG_ID_SET_BUZZER-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 1;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setMotionWithId:(NSString *)contactId password:(NSString *)password state:(NSInteger)state{
    static int mesg_id = MESG_ID_SET_MOTION-1000;
    if(mesg_id>=MESG_ID_SET_MOTION){
        mesg_id = MESG_ID_SET_MOTION-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 2;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setImageInversionWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state{
    static int mesg_id = MESG_ID_SET_IMAGE_INVERSION-1000;
    if(mesg_id>=MESG_ID_SET_IMAGE_INVERSION){
        mesg_id = MESG_ID_SET_IMAGE_INVERSION-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 24;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}


-(void)setAutoUpdateWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state{
    static int mesg_id = MESG_ID_SET_AUTO_UPDATE-1000;
    if(mesg_id>=MESG_ID_SET_AUTO_UPDATE){
        mesg_id = MESG_ID_SET_AUTO_UPDATE-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 16;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setHumanInfraredWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state{
    static int mesg_id = MESG_ID_SET_HUMAN_INFRARED-1000;
    if(mesg_id>=MESG_ID_SET_HUMAN_INFRARED){
        mesg_id = MESG_ID_SET_HUMAN_INFRARED-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 17;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setWiredAlarmInputWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state{
    static int mesg_id = MESG_ID_SET_WIRED_ALARM_INPUT-1000;
    if(mesg_id>=MESG_ID_SET_WIRED_ALARM_INPUT){
        mesg_id = MESG_ID_SET_WIRED_ALARM_INPUT-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 18;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setWiredAlarmOutputWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state{
    static int mesg_id = MESG_ID_SET_WIRED_ALARM_OUTPUT-1000;
    if(mesg_id>=MESG_ID_SET_WIRED_ALARM_OUTPUT){
        mesg_id = MESG_ID_SET_WIRED_ALARM_OUTPUT-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 19;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setDeviceTimezoneWithId:(NSString *)contactId password:(NSString *)password value:(NSInteger)value{
    static int mesg_id = MESG_ID_SET_DEVICE_TIME_ZONE-1000;
    if(mesg_id>=MESG_ID_SET_DEVICE_TIME_ZONE){
        mesg_id = MESG_ID_SET_DEVICE_TIME_ZONE-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 20;
    sSetting.sSettings[0].dwSettingValue = value;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 获取报警邮箱地址信息
-(void)getAlarmEmailWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_ALARM_EMAIL-1000;
    if(mesg_id>=MESG_ID_GET_ALARM_EMAIL){
        mesg_id = MESG_ID_GET_ALARM_EMAIL-1000;
    }
    sMesgEmailType sEmail;
    sEmail.bCmd = MESG_TYPE_GET_EMIAL;
    sEmail.bOption = 0x03;
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sEmail, sizeof(sMesgEmailType), NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 设置报警邮箱地址信息
-(void)setAlarmEmailWithId:(NSString *)contactId password:(NSString *)password email:(NSString *)email smtpServer:(NSString *)smtpServer smtpPort:(int)smtpPort smtpUser:(NSString *)smtpUser smtpPwd:(NSString *)smtpPwd encryptType:(int)encryptType subject:(NSString *)subject content:(NSString *)content isSupportSMTP:(BOOL)isSupportSMTP{
    static int mesg_id = MESG_ID_SET_ALARM_EMAIL-1000;
    if(mesg_id>=MESG_ID_SET_ALARM_EMAIL){
        mesg_id = MESG_ID_SET_ALARM_EMAIL-1000;
    }
    sMesgEmailType sEmail;
    
    sEmail.bCmd = MESG_TYPE_SET_EMIAL;
    
    sEmail.bOption = 0x03;//参数bOption只需传0x03（0x03兼容了0x00和0x01，0表示系统默认邮箱）
    
    //sEmail.wLen = email.length;
    
    //邮件地址
    char *tempStr = (char *)[email UTF8String];
    memcpy(sEmail.cString,tempStr,strlen(tempStr));
    sEmail.cString[strlen(tempStr)] = 0;//结束位
    
    if(isSupportSMTP){//新设备
        //SMTP服务器
        char *tempStr2 = (char *)[smtpServer UTF8String];
        memcpy(sEmail.cSmtpServer,tempStr2,strlen(tempStr2));
        sEmail.cSmtpServer[strlen(tempStr2)] = 0;//结束位
        
        //SMTP端口
        sEmail.dwSmtpPort = smtpPort;
        
        //Smtp账号
        char *tempStr3 = (char *)[smtpUser UTF8String];
        memcpy(sEmail.cSmtpUser,tempStr3,strlen(tempStr3));
        sEmail.cSmtpUser[strlen(tempStr3)] = 0;//结束位
        
        //Smtp密码
        unsigned char key[8] = {0x9c, 0xae, 0x6a, 0x5a, 0xe1,0xfc,0xb0, 0x82};
        NSString *newPwdString = [NSString stringWithFormat:@"%@##",smtpPwd];
        unsigned char *pwd  = (unsigned char *)[newPwdString UTF8String];
        int len = (int)[newPwdString length];//密码长度
        
        //要加密的密码bSrcPwd
        unsigned char bSrcPwd[64]  = {0};
        for(int i=0; i<64; i++){//初始化为'0'
            bSrcPwd[i] = '0';
        }
        memcpy(bSrcPwd, pwd, len);
        
        int encryCount = 0;//表示密码加密多少次才完成
        if(len%8 == 0){
            encryCount = len/8;
        }else{
            encryCount = len/8 + 1;
        }
        sEmail.wLen = encryCount*8;
        
        //加密后的字符串
        unsigned char encodePwd[len];
        unsigned char encodePwdTemp[8];
        unsigned char pwdTemp[8];
        for(int i=0; i<encryCount; i++){
            memset(pwdTemp, 0, sizeof(pwdTemp));
            memcpy(pwdTemp, bSrcPwd + i * 8, 8);
            
            memset(encodePwdTemp, 0, sizeof(encodePwdTemp));
            des(pwdTemp, encodePwdTemp, key, 1);
            
            memcpy(encodePwd + i * 8, encodePwdTemp, 8);
        }
        
        
        for(int i=0; i<encryCount*8; i++){
            sEmail.cSmtpPwd[i] = encodePwd[i];
        }
        sEmail.cSmtpPwd[encryCount*8] = 0;//结束位
        
        //加密类型
        sEmail.bEncryptType = encryptType;
        
        
        //主题内容的UI没有实现，只在此传参测试
        //主题 格式通常是Attention:XXXX:xxxx alarm!
        //XXXX：xxxx是加入3CID号和告警类型的信息
        char *subjectTemp = (char *)[subject UTF8String];
        memcpy(sEmail.cEmailSubject,subjectTemp,strlen(subjectTemp));
        sEmail.cEmailSubject[strlen(subjectTemp)] = 0;//结束位
        //内容
        //长度小于100字符,英文
        char *contentTemp = (char *)[content UTF8String];
        memcpy(sEmail.cEmailContent,contentTemp,strlen(contentTemp));
        sEmail.cEmailContent[strlen(contentTemp)] = 0;//结束位
        
        //针对新设备，结构体长度sizeof(sMesgEmailType)
        int iTargetID = GetIpBy3CID(contactId.intValue);
        fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sEmail, sizeof(sMesgEmailType), NULL, 0, 0);
    }else{
        //针对旧设备，结构体长度36
        int iTargetID = GetIpBy3CID(contactId.intValue);
        fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sEmail, 36, NULL, 0, 0);
    }
    mesg_id++;
}

-(void)getBindAccountWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_BIND_ACCOUNT-1000;
    if(mesg_id>=MESG_ID_GET_BIND_ACCOUNT){
        mesg_id = MESG_ID_GET_BIND_ACCOUNT-1000;
    }
    sMesgGSetAppIdType sAppId;
    sAppId.bCmd = MESG_TYPE_GET_APPID;
    sAppId.bOption = 0;
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sAppId, sizeof(sMesgGSetAppIdType), NULL, 0, 0);
    mesg_id++;
}
    
-(void)setBindAccountWithId:(NSString *)contactId password:(NSString *)password datas:(NSMutableArray *)datas{
    static int mesg_id = MESG_ID_SET_BIND_ACCOUNT-1000;
    if(mesg_id>=MESG_ID_SET_BIND_ACCOUNT){
        mesg_id = MESG_ID_SET_BIND_ACCOUNT-1000;
    }
    
    NSMutableArray *setDatas = [NSMutableArray arrayWithArray:datas];
    int count = [setDatas count];
    if(count==0){
        [setDatas addObject:[NSNumber numberWithInt:0]];
        count = 1;
    }
    int ids[count];
    
    for(int i=0;i<count;i++){
        NSNumber *bindId = [setDatas objectAtIndex:i];
        ids[i] = [bindId intValue];
    }
    BYTE buffer[256];
    sMesgGSetAppIdType *sAppId = (sMesgGSetAppIdType*)buffer;
    sAppId->bCmd = MESG_TYPE_SET_APPID;
    sAppId->bAppIdCount = count;
    memcpy(sAppId->dwAppId, ids, count*sizeof(int));
    int length = sizeof(sMesgGSetAppIdType)+(count-1)*sizeof(int);
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, sAppId, length, NULL, 0, 0);
    mesg_id++;
}
    
-(void)setRemoteDefenceWithId:(NSString *)contactId password:(NSString *)password state:(NSInteger)state{
    static int mesg_id = MESG_ID_SET_REMOTE_DEFENCE-1000;
    if(mesg_id>=MESG_ID_SET_REMOTE_DEFENCE){
        mesg_id = MESG_ID_SET_REMOTE_DEFENCE-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 0;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}
    

-(void)setRemoteRecordWithId:(NSString *)contactId password:(NSString *)password state:(unsigned int)state{
    static int mesg_id = MESG_ID_SET_REMOTE_RECORD-1000;
    if(mesg_id>=MESG_ID_SET_REMOTE_RECORD){
        mesg_id = MESG_ID_SET_REMOTE_RECORD-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 4;
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setRecordPreWithId:(NSString *)contactId password:(NSString *)password state:(unsigned int)state{
    static int mesg_id = MESG_ID_SET_RECORD_PRE-1000;
    if(mesg_id>=MESG_ID_SET_RECORD_PRE){
        mesg_id = MESG_ID_SET_RECORD_PRE-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 25;
    sSetting.sSettings[0].dwSettingValue = state;
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}
    
-(void)setRecordTypeWithId:(NSString *)contactId password:(NSString *)password type:(unsigned int)type{
    static int mesg_id = MESG_ID_SET_RECORD_TYPE-1000;
    if(mesg_id>=MESG_ID_SET_RECORD_TYPE){
        mesg_id = MESG_ID_SET_RECORD_TYPE-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 3;
    sSetting.sSettings[0].dwSettingValue = type;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setRecordTimeWithId:(NSString *)contactId password:(NSString *)password value:(NSInteger)value{
    static int mesg_id = MESG_ID_SET_RECORD_TIME-1000;
    if(mesg_id>=MESG_ID_SET_RECORD_TIME){
        mesg_id = MESG_ID_SET_RECORD_TIME-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 11;
    sSetting.sSettings[0].dwSettingValue = value;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setRecordPlanTimeWithId:(NSString *)contactId password:(NSString *)password time:(NSInteger)time{
    static int mesg_id = MESG_ID_SET_RECORD_PLAN_TIME-1000;
    if(mesg_id>=MESG_ID_SET_RECORD_PLAN_TIME){
        mesg_id = MESG_ID_SET_RECORD_PLAN_TIME-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 5;
    sSetting.sSettings[0].dwSettingValue = time;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)setNetTypeWithId:(NSString *)contactId password:(NSString *)password type:(NSInteger)type{
    static int mesg_id = MESG_ID_SET_NET_TYPE-1000;
    if(mesg_id>=MESG_ID_SET_NET_TYPE){
        mesg_id = MESG_ID_SET_NET_TYPE-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 13;
    sSetting.sSettings[0].dwSettingValue = type;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

-(void)getWifiListWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_WIFI_LIST-1000;
    if(mesg_id>=MESG_ID_GET_WIFI_LIST){
        mesg_id = MESG_ID_GET_WIFI_LIST-1000;
    }
    sMesgGetWifiListType sWifi;
    sWifi.bCmd = MESG_TYPE_GET_WIFILIST;
    sWifi.bOption = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sWifi, sizeof(sMesgGetWifiListType), NULL, 0, 0);
    mesg_id++;
}

-(void)setWifiWithId:(NSString *)contactId password:(NSString *)password type:(NSInteger)type name:(NSString *)name wifiPassword:(NSString *)wifiPassword{
    static int mesg_id = MESG_ID_SET_WIFI-1000;
    if(mesg_id>=MESG_ID_SET_WIFI){
        mesg_id = MESG_ID_SET_WIFI-1000;
    }
    sMesgSetWifiListType sWifi;
    sWifi.bCmd = MESG_TYPE_SET_WIFILIST;
    sWifi.bOption = 0;
    
    sWifi.sPhoneWifiInfo.dwEncType = type;
    memcpy(sWifi.sPhoneWifiInfo.cESSID, [name UTF8String], [name length]);
    memcpy(sWifi.sPhoneWifiInfo.cPassword, [wifiPassword UTF8String], [wifiPassword length]);
    
    sWifi.sPhoneWifiInfo.cESSID[[name length]] = 0;
    sWifi.sPhoneWifiInfo.cPassword[[wifiPassword length]] = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sWifi, sizeof(sMesgSetWifiListType), NULL, 0, 0);
    mesg_id++;
}

-(void)getDefenceAreaState:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_DEFENCE_AREA_STATE-1000;
    if(mesg_id>=MESG_ID_GET_DEFENCE_AREA_STATE){
        mesg_id = MESG_ID_GET_DEFENCE_AREA_STATE-1000;
    }
    sMesgGetAlarmCodeType sCode;
    sCode.bCmd = MESG_TYPE_GET_ALARMCODE_STATUS;
    sCode.bOption = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sCode, sizeof(sMesgGetAlarmCodeType), NULL, 0, 0);
    mesg_id++;
}

-(void)setDefenceAreaState:(NSString *)contactId password:(NSString *)password group:(NSInteger)group item:(NSInteger)item type:(NSInteger)type{
    static int mesg_id = MESG_ID_SET_DEFENCE_AREA_STATE-1000;
    if(mesg_id>=MESG_ID_SET_DEFENCE_AREA_STATE){
        mesg_id = MESG_ID_SET_DEFENCE_AREA_STATE-1000;
    }
    sMesgSetAlarmCodeType sCode;
    sCode.bCmd = MESG_TYPE_SET_ALARMCODE_STATUS;
    sCode.bOption = 0;
    sCode.bSetAlarmCodeId = type;
    sCode.bAlarmCodeCount = 1;
    sCode.sAlarmCodes[0].dwAlarmCodeID = group;
    sCode.sAlarmCodes[0].dwAlarmCodeIndex = item;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sCode, sizeof(sMesgSetAlarmCodeType), NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 学习对码，添加启用或禁用开关
#pragma mark 获取启用或禁用开关
- (void) getDefenceSwitchStateWithId:(NSString *)contactId password:(NSString *)password
{
    static int mesg_id = MESG_ID_GET_DEFENCE_SWITCH_STATE - 1000;
    if (mesg_id >= MESG_ID_GET_DEFENCE_SWITCH_STATE) {
        mesg_id = MESG_ID_GET_DEFENCE_SWITCH_STATE - 1000;
    }
    
    sMesgGetDefenceSwitchType sGetDefenceSwitch;
    sGetDefenceSwitch.bCmd = MESG_TYPE_GET_DEFENCE_SWITCH_STATE;
    sGetDefenceSwitch.bOption = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sGetDefenceSwitch, sizeof(sMesgGetDefenceSwitchType), NULL, 0, 0);
    mesg_id++;
}

#pragma mark 设置启用或禁用开关
- (void) setDefenceSwitchStateWithId:(NSString *)contactId password:(NSString *)password switchId:(int)switchId alarmCodeId:(int)alarmCodeId alarmCodeIndex:(int)alarmCodeIndex
{
    static int mesg_id = MESG_ID_SET_DEFENCE_SWITCH_STATE - 1000;
    if (mesg_id >= MESG_ID_SET_DEFENCE_SWITCH_STATE) {
        mesg_id = MESG_ID_SET_DEFENCE_SWITCH_STATE - 1000;
    }
    
    sMesgSetDefenceSwitchType sSetDefenceSwitch;
    sSetDefenceSwitch.bCmd = MESG_TYPE_SET_DEFENCE_SWITCH_STATE;
    sSetDefenceSwitch.bOption = 0;
    sSetDefenceSwitch.bSetDefenceSetSwitchId = switchId;
    sSetDefenceSwitch.sAlarmCodes[0].dwAlarmCodeID = alarmCodeId;
    sSetDefenceSwitch.sAlarmCodes[0].dwAlarmCodeIndex = alarmCodeIndex;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetDefenceSwitch, sizeof(sMesgSetDefenceSwitchType), NULL, 0, 0);
    mesg_id++;
}

-(void)setInitPasswordWithId:(NSString *)contactId initPassword:(NSString *)initPassword{
    static int mesg_id = MESG_ID_SET_INIT_PASSWORD-1000;
    if(mesg_id>=MESG_ID_SET_INIT_PASSWORD){
        mesg_id = MESG_ID_SET_INIT_PASSWORD-1000;
    }
    sMesgSetInitPasswdType sPassword;
    sPassword.bCmd = MESG_TYPE_SET_INIT_PASSWD;
    BYTE souceBuf[8];
    BYTE desBuf[8];
    BYTE key[8] = {0x9c, 0xae, 0x6a, 0x5a, 0xe1,0xfc,0xb0, 0x82};
    DWORD password = [initPassword intValue];
    memcpy(souceBuf, &password, sizeof(DWORD));
    
    des(souceBuf,desBuf,key,0);
    memcpy(sPassword.bPasswd, desBuf, 8);
    
    int iTargetID = GetIpBy3CIDx(contactId.intValue);       //设置初始密码必须用ip地址，所以搜索设备的时候不判断密码标志位
    fgP2PSendRemoteMessage(iTargetID, 0, mesg_id, &sPassword, sizeof(sMesgSetInitPasswdType), NULL, 0, 0);
    mesg_id++;
}


-(void)checkDeviceUpdateWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_CHECK_DEVICE_UPDATE-1000;
    if(mesg_id>=MESG_ID_CHECK_DEVICE_UPDATE){
        mesg_id = MESG_ID_CHECK_DEVICE_UPDATE-1000;
    }
    sMesgUpgType sUpg;
    sUpg.bCmd = MESG_TYPE_UPG_CHEK_VERSION;
    sUpg.sRemoteUpgMesg.dwUpgVal = 1;
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sUpg, sizeof(sMesgUpgType), NULL, 0, 0);
    mesg_id++;
}

-(void)doDeviceUpdateWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_DO_DEVICE_UPDATE-1000;
    if(mesg_id>=MESG_ID_DO_DEVICE_UPDATE){
        mesg_id = MESG_ID_DO_DEVICE_UPDATE-1000;
    }
    sMesgUpgType sUpg;
    sUpg.bCmd = MESG_TYPE_UPG_FILE_TO_DOWNLOAD;

    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sUpg, sizeof(sMesgUpgType), NULL, 0, 0);
    mesg_id++;
}

-(void)cancelDeviceUpdateWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_CANCEL_DEVICE_UPDATE-1000;
    if(mesg_id>=MESG_ID_CANCEL_DEVICE_UPDATE){
        mesg_id = MESG_ID_CANCEL_DEVICE_UPDATE-1000;
    }
    sMesgUpgType sUpg;
    sUpg.bCmd = MESG_TYPE_UPG_FILE_CANCEL_DOWNLOAD;
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sUpg, sizeof(sMesgUpgType), NULL, 0, 0);
    mesg_id++;
}

-(NSInteger)sendMessageToFriend:(NSString *)contactId message:(NSString *)message{
    static int mesg_id = MESG_ID_SEND_MESSAGE-1000;
    if(mesg_id>=MESG_ID_SEND_MESSAGE){
        mesg_id = MESG_ID_SEND_MESSAGE-1000;
    }
    
    char *messageStr = (char*)[message UTF8String];
    int length = strlen(messageStr);
    
    if(!message||length<=0||length>1024){
        return -1;
    }
    
    
    
    
    sMesgStringMesgType sMessage;
    
    sMessage.bCmd = MESG_TYPE_MESSAGE;
    sMessage.bOption = 0;
    sMessage.wLen = length;
    
    memcpy(sMessage.cString, messageStr, length);
    mesg_id++;
    fgP2PSendRemoteMessage(contactId.intValue|0x80000000, 0, mesg_id, &sMessage, length+4, sMessage.cString, length, (DWORD)PUSH_MESG_FRIEND);
    return mesg_id;
}

-(void)getDeviceInfoWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_DEVICE_INFO-1000;
//    if(mesg_id == MESG_ID_GET_DEVICE_INFO-1000){
//        mesg_id = MESG_ID_GET_DEVICE_INFO-(random()%1000);
//    }
    if(mesg_id>=MESG_ID_GET_DEVICE_INFO){
        mesg_id = MESG_ID_GET_DEVICE_INFO-1000;
    }
    sMesgSysVersionType sVersion;
    sVersion.bCmd = MESG_TYPE_GET_SYS_VERSION;

    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sVersion, sizeof(sMesgSysVersionType), NULL, 0, 0);
    mesg_id++;
}

//开锁接口
-(void)sendCustomCmdWithId:(NSString *)contactId password:(NSString *)password cmd:(NSString *)cmd{
    static int mesg_id = MESG_ID_SEND_CUSTOM_CMD-1000;
    if(mesg_id>=MESG_ID_SEND_CUSTOM_CMD){
        mesg_id = MESG_ID_SEND_CUSTOM_CMD-1000;
    }
    
    char *cmdStr = (char*)[cmd UTF8String];
    int length = strlen(cmdStr);
    
    BYTE pMessageBody[252] = {0};
    pMessageBody[0] = MESG_TYPE_USER_CMD;
    pMessageBody[1] = 0;
    pMessageBody[2] = length;
    pMessageBody[3] = 0;
    for (int i = 0; i < length; i++) {
        pMessageBody[4+i] = cmdStr[i];
    }
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, pMessageBody, length+4, NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 设置GPIO中值
-(void)setGpioCtrlWithId:(NSString *)contactId password:(NSString *)password group:(int)group pin:(int)pin value:(int)value time:(int [])time{
    static int mesg_id = MESG_ID_SET_GPIO_CTL-1000;
    if(mesg_id>=MESG_ID_SET_GPIO_CTL){
        mesg_id = MESG_ID_SET_GPIO_CTL-1000;
    }
    sMesgSetGpioCtrl sSetGpioCtrl;
    sSetGpioCtrl.bCmd = MESG_TYPE_SET_GPIO_CTL;
    sSetGpioCtrl.bOption = 0;
    sSetGpioCtrl.bGroup = group;
    sSetGpioCtrl.bPin = pin;
    sSetGpioCtrl.bValueNs = value;
    for (int i = 0; i < 8; i++) {
        sSetGpioCtrl.iTimer_ms[i] = time[i];
    }
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetGpioCtrl, sizeof(sMesgSetGpioCtrl), NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 灯控制接口-获取灯的状态（开或关）
-(void)getLightStateWithDeviceId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_LIGHT_STATE-1000;
    if(mesg_id>=MESG_ID_GET_LIGHT_STATE){
        mesg_id = MESG_ID_GET_LIGHT_STATE-1000;
    }
    BYTE pMessageBody[4];
    pMessageBody[0] = MESG_TYPE_GET_SETTING;
    pMessageBody[1] = 0;
    pMessageBody[2] = 0;
    pMessageBody[3] = 0;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, pMessageBody, 4, NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 灯控制接口-设置灯的状态（开或关）
-(void)setLightStateWithDeviceId:(NSString *)contactId password:(NSString *)password switchState:(int)state{
    static int mesg_id = MESG_ID_SET_LIGHT_STATE-1000;
    if(mesg_id>=MESG_ID_SET_LIGHT_STATE){
        mesg_id = MESG_ID_SET_LIGHT_STATE-1000;
    }
    sMessageSettingsType sSetting;
    sSetting.bCmd = MESG_TYPE_SET_SETTING;
    sSetting.bOption = 0;
    sSetting.wSettingCount = 1;
    sSetting.sSettings[0].dwSettingID = 34;//灯控制接口
    sSetting.sSettings[0].dwSettingValue = state;
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sSetting, sizeof(sMessageSettingsType), NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 用户命令无密码验证删除绑定推送ID或者告诉设备端不要再推送门铃
-(void)deleteAlarmPushIDWithId:(NSString *)contactId{//删除绑定的报警推送ID
    static int mesg_id = MESG_ID_SET_DELETE_ALARM_PUSHID - 1000;
    if (mesg_id >= MESG_ID_SET_DELETE_ALARM_PUSHID) {
        mesg_id = MESG_ID_SET_DELETE_ALARM_PUSHID - 1000;
    }
    
    sMesgCustomNoVerifyCmdType sMessage;
    sMessage.bCmd = MESG_TYPE_CUSTOM_CMD_NO_VERRIFY_SET;
    sMessage.bOption = 0;
    sMessage.wLen = sizeof(sMesgCustomNoVerifyCmdType);
    sMessage.dwMesgVersion = 0;
    sMessage.sCmdData.dwCmdID = CUSTOMER_CMDNOVER_ID_DEL_ALARM_ACCOUNT;
    sMessage.sCmdData.dwCmdVal = 0;
    
    
    NSString *password = @"0";
    //注意，contactId是3C Id，不可以是IP
    fgP2PSendRemoteMessage(contactId.intValue, password.intValue, mesg_id, &sMessage, sizeof(sMesgCustomNoVerifyCmdType), NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 告诉设备端不要再推送门铃
-(void)stopDoorbellPushWithId:(NSString *)contactId{
    static int mesg_id = MESG_ID_SET_STOP_DOORBELL_PUSH - 1000;
    if (mesg_id >= MESG_ID_SET_STOP_DOORBELL_PUSH) {
        mesg_id = MESG_ID_SET_STOP_DOORBELL_PUSH - 1000;
    }
    
    sMesgCustomNoVerifyCmdType sMessage;
    sMessage.bCmd = MESG_TYPE_CUSTOM_CMD_NO_VERRIFY_SET;
    sMessage.bOption = 0;
    sMessage.wLen = sizeof(sMesgCustomNoVerifyCmdType);
    sMessage.dwMesgVersion = 0;
    sMessage.sCmdData.dwCmdID = CUSTOMER_CMDNOVER_ID_STOP_DOORBELL_PUSH;
    sMessage.sCmdData.dwCmdVal = 1;
    
    
    NSString *password = @"0";
    //注意，contactId是3C Id，不可以是IP
    fgP2PSendRemoteMessage(contactId.intValue, password.intValue, mesg_id, &sMessage, sizeof(sMesgCustomNoVerifyCmdType), NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 获取设备支持的语言，以及当前显示的语言
-(void)getDeviceSupportedLanguageAndCurrentLanguageWithId:(NSString *)contactId password:(NSString *)password{
    static int mesg_id = MESG_ID_GET_DEVICE_LANGUAGE - 1000;
    if (mesg_id >= MESG_ID_GET_DEVICE_LANGUAGE) {
        mesg_id = MESG_ID_GET_DEVICE_LANGUAGE - 1000;
    }
    
    sMesgDeviceLanguageCmdType sMessage;
    sMessage.bCmd = MESG_TYPE_GET_DEVICE_LANGUAGE;
    sMessage.bOption = 0;
    sMessage.wReserve = 0;
    sMessage.bSupportLanguageCount = 0;
    sMessage.bCurLanguage = 0;
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sMessage, sizeof(sMesgDeviceLanguageCmdType), NULL, 0, 0);
    mesg_id++;
}

#pragma mark - 设置设备当前要显示的语言
-(void)setDeviceCurrentLanguageWithId:(NSString *)contactId password:(NSString *)password currentLanguage:(int)currentLanguage{
    static int mesg_id = MESG_ID_SET_DEVICE_LANGUAGE - 1000;
    if (mesg_id >= MESG_ID_SET_DEVICE_LANGUAGE) {
        mesg_id = MESG_ID_SET_DEVICE_LANGUAGE - 1000;
    }
    
    sMesgDeviceLanguageCmdType sMessage;
    sMessage.bCmd = MESG_TYPE_SET_DEVICE_LANGUAGE;
    sMessage.bOption = 0;
    sMessage.wReserve = 0;
    sMessage.bSupportLanguageCount = 0;
    sMessage.bCurLanguage = currentLanguage;//currentLanguage代表某种语言的数字编号
    
    int iTargetID = GetIpBy3CID(contactId.intValue);
    fgP2PSendRemoteMessage(iTargetID, password.intValue, mesg_id, &sMessage, sizeof(sMesgDeviceLanguageCmdType), NULL, 0, 0);
    mesg_id++;
}

@end
