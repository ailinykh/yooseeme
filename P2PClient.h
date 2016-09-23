//
//  P2PClient.h
//  Yoosee
//
//  Created by guojunyi on 14-3-25.
//  Copyright (c) 2014年 guojunyi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Constants.h"
#import "P2PCInterface.h"
//test svn
//p2p setting value
#define SETTING_VALUE_VIDEO_FORMAT_TYPE_NTSC 0
#define SETTING_VALUE_VIDEO_FORMAT_TYPE_PAL 1

#define SETTING_VALUE_ALARM_STATE_OFF 0
#define SETTING_VALUE_ALARM_STATE_ON 1

#define SETTING_VALUE_MOTION_STATE_OFF 0
#define SETTING_VALUE_MOTION_STATE_ON 1

#define SETTING_VALUE_BUZZER_STATE_OFF 0
#define SETTING_VALUE_BUZZER_STATE_ON_ONE 1
#define SETTING_VALUE_BUZZER_STATE_ON_TWO 2
#define SETTING_VALUE_BUZZER_STATE_ON_THREE 3

#define SETTING_VALUE_REMOTE_DEFENCE_STATE_OFF 0
#define SETTING_VALUE_REMOTE_DEFENCE_STATE_ON 1

#define SETTING_VALUE_REMOTE_RECORD_STATE_OFF 0
#define SETTING_VALUE_REMOTE_RECORD_STATE_ON 1

#define SETTING_VALUE_RECORD_MANUAL 0
#define SETTING_VALUE_RECORD_ALARM 1
#define SETTING_VALUE_RECORD_TIMER 2

#define SETTING_VALUE_RECORD_TIME_ONE 0
#define SETTING_VALUE_RECORD_TIME_TWO 1
#define SETTING_VALUE_RECORD_TIME_THREE 2

#define SETTING_VALUE_NET_TYPE_WIRED 0
#define SETTING_VALUE_NET_TYPE_WIFI 1

#define SETTING_VALUE_IMAGE_INVERSION_STATE_OFF 0
#define SETTING_VALUE_IMAGE_INVERSION_STATE_ON 1

#define SETTING_VALUE_AUTO_UPDATE_STATE_OFF 0
#define SETTING_VALUE_AUTO_UPDATE_STATE_ON 1

#define SETTING_VALUE_HUMAN_INFRARED_STATE_OFF 0
#define SETTING_VALUE_HUMAN_INFRARED_STATE_ON 1

#define SETTING_VALUE_WIRED_ALARM_INPUT_STATE_OFF 0
#define SETTING_VALUE_WIRED_ALARM_INPUT_STATE_ON 1

#define SETTING_VALUE_WIRED_ALARM_OUTPUT_STATE_OFF 0
#define SETTING_VALUE_WIRED_ALARM_OUTPUT_STATE_ON 1
//p2p receive playing cmd
#define RECEIVE_PLAYING_CMD @"RECEIVE_PLAYING_CMD"
#define RECEIVE_PLAYING_CMD_CHANGE_VIDEO_STATE 0x11
#define RECEIVE_PLAYING_CMD_PLAYBACK_STOP 0X12
#define RECEIVE_PLAYING_CMD_PLAYBACK_START 0X13

//receive alarm message
#define RECEIVE_ALARM_MESSAGE @"RECEIVE_ALARM_MESSAGE"

//receive door bell alarm message
#define RECEIVE_DOORBELL_ALARM_MESSAGE @"RECEIVE_DOORBELL_ALARM_MESSAGE"

//receive remote message
#define RECEIVE_REMOTE_MESSAGE @"RECEIVE_REMOTE_MESSAGE"
#define MONITOR_START_RENDER_MESSAGE @"MONITOR_START_RENDER_MESSAGE"//rtsp监控界面弹出修改
#define RET_GET_PLAYBACK_FILES 0x11
#define RET_GET_DEVICE_TIME 0x12
#define RET_SET_DEVICE_TIME 0x13
#define RET_GET_NPCSETTINGS_VIDEO_FORMAT 0x14
#define RET_SET_NPCSETTINGS_VIDEO_FORMAT 0x15
#define RET_GET_NPCSETTINGS_VIDEO_VOLUME 0x16
#define RET_SET_NPCSETTINGS_VIDEO_VOLUME 0x17
#define RET_SET_DEVICE_PASSWORD 0x18
#define RET_SET_NPCSETTINGS_MOTION 0x19
#define RET_GET_NPCSETTINGS_MOTION 0x20
#define RET_SET_NPCSETTINGS_BUZZER 0x21
#define RET_GET_NPCSETTINGS_BUZZER 0x22
#define RET_GET_ALARM_EMAIL 0x23
#define RET_SET_ALARM_EMAIL 0x24
#define RET_GET_BIND_ACCOUNT 0x25
#define RET_SET_BIND_ACCOUNT 0x26
#define RET_GET_NPCSETTINGS_REMOTE_DEFENCE 0x27
#define RET_GET_NPCSETTINGS_REMOTE_RECORD 0x28
#define RET_SET_NPCSETTINGS_REMOTE_DEFENCE 0x29
#define RET_SET_NPCSETTINGS_REMOTE_RECORD 0x30
#define RET_GET_NPCSETTINGS_RECORD_TYPE 0x31
#define RET_SET_NPCSETTINGS_RECORD_TYPE 0x32
#define RET_GET_NPCSETTINGS_RECORD_TIME 0x33
#define RET_SET_NPCSETTINGS_RECORD_TIME 0x34
#define RET_GET_NPCSETTINGS_RECORD_PLAN_TIME 0x35
#define RET_SET_NPCSETTINGS_RECORD_PLAN_TIME 0x36
#define RET_GET_NPCSETTINGS_NET_TYPE 0x37
#define RET_SET_NPCSETTINGS_NET_TYPE 0x38
#define RET_GET_WIFI_LIST 0x39
#define RET_SET_WIFI 0x40
#define RET_GET_DEFENCE_AREA_STATE 0x41
#define RET_SET_DEFENCE_AREA_STATE 0x42
#define RET_SET_INIT_PASSWORD 0x43
#define RET_CHECK_DEVICE_UPDATE 0x44
#define RET_DEVICE_NOT_SUPPORT 0x45
#define RET_RECEIVE_MESSAGE 0x46
#define RET_DO_DEVICE_UPDATE 0x47
#define RET_GET_DEVICE_INFO 0x48
#define RET_CUSTOM_CMD 0x49
#define RET_GET_NPCSETTINGS_IMAGE_INVERSION 0x50
#define RET_GET_NPCSETTINGS_AUTO_UPDATE 0x51
#define RET_GET_NPCSETTINGS_HUMAN_INFRARED 0x52
#define RET_GET_NPCSETTINGS_WIRED_ALARM_INPUT 0x53
#define RET_GET_NPCSETTINGS_WIRED_ALARM_OUTPUT 0x54
#define RET_SET_NPCSETTINGS_IMAGE_INVERSION 0x55
#define RET_SET_NPCSETTINGS_AUTO_UPDATE 0x56
#define RET_SET_NPCSETTINGS_HUMAN_INFRARED 0x57
#define RET_SET_NPCSETTINGS_WIRED_ALARM_INPUT 0x58
#define RET_SET_NPCSETTINGS_WIRED_ALARM_OUTPUT 0x59
#define RET_GET_VISITOR_PASSWORD_OLD 0x60
#define RET_GET_VISITOR_PASSWORD_NEW 0x61
#define RET_SET_VISITOR_PASSWORD 0x62
#define RET_GET_NPCSETTINGS_TIME_ZONE 0x63
#define RET_SET_NPCSETTINGS_TIME_ZONE 0x64
#define RET_GET_SDCARD_INFO 0x65
#define RET_SET_SDCARD_FORMAT 0x66
#define RET_GET_DEFENCE_SWITCH_STATE 0x67
#define RET_SET_DEFENCE_SWITCH_STATE 0x68
#define RET_SET_GPIO_CTL 0x69
#define RET_GET_LIGHT_SWITCH_STATE 0x70
#define RET_SET_LIGHT_SWITCH_STATE 0x71
#define RET_GET_NPCSETTINGS_PRERECORD 0x72
#define RET_SET_NPCSETTINGS_PRERECORD 0x73
#define RET_SET_DELETE_ALARM_PUSHID 0x74
#define RET_GET_DEVICE_LANGUAGE 0x75
#define RET_SET_DEVICE_LANGUAGE 0x76
#define RET_GET_FOCUS_ZOOM 0x77

//p2p ack receive remote message
#define ACK_RECEIVE_REMOTE_MESSAGE @"ACK_RECEIVE_REMOTE_MESSAGE"
#define ACK_RET_GET_PLAYBACK_FILES 0x11
#define ACK_RET_GET_DEVICE_TIME 0x12
#define ACK_RET_SET_DEVICE_TIME 0x13
#define ACK_RET_GET_NPC_SETTINGS 0x14
#define ACK_RET_SET_NPCSETTINGS_VIDEO_FORMAT 0x15
#define ACK_RET_SET_NPCSETTINGS_VIDEO_VOLUME 0x16
#define ACK_RET_SET_DEVICE_PASSWORD 0x17
#define ACK_RET_SET_NPCSETTINGS_MOTION 0x18
#define ACK_RET_SET_NPCSETTINGS_BUZZER 0x19
#define ACK_RET_GET_ALARM_EMAIL 0x20
#define ACK_RET_SET_ALARM_EMAIL 0x21
#define ACK_RET_GET_BIND_ACCOUNT 0x22
#define ACK_RET_SET_BIND_ACCOUNT 0x23
#define ACK_RET_SET_NPCSETTINGS_REMOTE_DEFENCE 0x24
#define ACK_RET_SET_NPCSETTINGS_REMOTE_RECORD 0x25
#define ACK_RET_SET_NPCSETTINGS_RECORD_TYPE 0x26
#define ACK_RET_SET_NPCSETTINGS_RECORD_TIME 0x27
#define ACK_RET_SET_NPCSETTINGS_RECORD_PLAN_TIME 0x28
#define ACK_RET_SET_NPCSETTINGS_NET_TYPE 0x29
#define ACK_RET_GET_WIFI_LIST 0x30
#define ACK_RET_SET_WIFI 0x31
#define ACK_RET_GET_DEFENCE_AREA_STATE 0x32
#define ACK_RET_SET_DEFENCE_AREA_STATE 0x33
#define ACK_RET_SET_INIT_PASSWORD 0x34
#define ACK_RET_CHECK_DEVICE_UPDATE 0x35
#define ACK_RET_SEND_MESSAGE 0x36
#define ACK_RET_GET_DEFENCE_STATE 0x37
#define ACK_RET_DO_DEVICE_UPDATE 0x38
#define ACK_RET_GET_DEVICE_INFO 0x39
#define ACK_RET_CUSTOM_CMD 0x40
#define ACK_RET_SET_NPCSETTINGS_IMAGE_INVERSION 0x41
#define ACK_RET_SET_NPCSETTINGS_AUTO_UPDATE 0x42
#define ACK_RET_SET_NPCSETTINGS_HUMAN_INFRARED 0x43
#define ACK_RET_SET_NPCSETTINGS_WIRED_ALARM_INPUT 0x44
#define ACK_RET_SET_NPCSETTINGS_WIRED_ALARM_OUTPUT 0x45
#define ACK_RET_SET_VISITOR_PASSWORD 0x46
#define ACK_RET_SET_TIME_ZONE 0x47
#define ACK_RET_GET_SDCARD_INFO 0x48
#define ACK_RET_SET_SDCARD_INFO 0x49
#define ACK_RET_GET_DEFENCE_SWITCH_STATE 0x50
#define ACK_RET_SET_DEFENCE_SWITCH_STATE 0x51
#define ACK_RET_SET_GPIO_CTL 0x55
#define ACK_RET_GET_LIGHT_STATE 0x56
#define ACK_RET_SET_LIGHT_STATE 0x57
#define ACK_RET_SET_NPCSETTINGS_RECORD_PRE 0X58
#define ACK_RET_SET_DELETE_ALARM_PUSHID 0X59
#define ACK_RET_SET_STOP_DOORBELL_PUSH 0x60
#define ACK_RET_GET_DEVICE_LANGUAGE 0x61
#define ACK_RET_SET_DEVICE_LANGUAGE 0x62

#define AP_ENTER_FORCEGROUND_MESSAGE @"ap_enter_forceground_message"

@protocol P2PClientDelegate <NSObject>

@optional
- (void)P2PClientCalling:(NSDictionary*)info;
- (void)P2PClientReject:(NSDictionary*)info;
- (void)P2PClientAccept:(NSDictionary*)info;
- (void)P2PClientReady:(NSDictionary*)info;
@end

@protocol P2PPlaybackDelegate <NSObject>

@optional
- (void)P2PPlaybackCalling:(NSDictionary*)info;
- (void)P2PPlaybackReject:(NSDictionary*)info;
- (void)P2PPlaybackAccept:(NSDictionary*)info;
- (void)P2PPlaybackReady:(NSDictionary*)info;
@end



@interface P2PClient : NSObject
@property (nonatomic) sRecAndDecPrm srecAndDecPrm;
@property (nonatomic) P2PCallState p2pCallState;
@property (nonatomic) P2PCallType p2pCallType;
@property (nonatomic) PlaybackState playbackState;
@property (nonatomic) BOOL isBCalled;
@property (nonatomic) BOOL isSendProcRunning;
@property (nonatomic) NSInteger currentLabel;//当前显示的回放分类（最近1天、...）
@property (nonatomic) BOOL isLoadMorePlaybackFilesForOneDay;
@property (nonatomic) BOOL isLoadMorePlaybackFilesForThreeDay;
@property (nonatomic) BOOL isLoadMorePlaybackFilesForOneMon;
@property (nonatomic) BOOL isLoadMorePlaybackFilesForCustom;
@property (nonatomic) BOOL isClearPlaybackFilesLength;//视频回放修复
@property(retain, nonatomic) NSMutableArray *loadedplaybackFiles;//视频回放修复
@property (nonatomic) uint64_t playback_startTime;
@property (nonatomic) uint64_t playback_endTime;
@property (nonatomic) uint64_t playback_totalTime;

@property (nonatomic,retain) NSString *callId;
@property (nonatomic,retain) NSString *callPassword;
@property (nonatomic) BOOL is16B9;
@property (nonatomic) BOOL is960P;
@property (nonatomic, assign) id<P2PClientDelegate> delegate;
@property (nonatomic, assign) id<P2PPlaybackDelegate> playbackDelegate;

+ (id)sharedClient;
- (void)setDelegate:(id<P2PClientDelegate>)delegate;
- (void)setPlaybackDelegate:(id<P2PPlaybackDelegate>)delegate;

-(BOOL)p2pConnectWithId:(NSString*)contactId codeStr1:(NSString*)codeStr1 codeStr2:(NSString*)codeStr2;
-(void)p2pDisconnect;
-(void)p2pCallWithId:(NSString*)contactId password:(NSString*)password callType:(P2PCallType)type;
-(void)p2pPlaybackCallWithId:(NSString*)contactId password:(NSString*)password index:(NSInteger)index;
-(void)p2pAccept;
-(void)p2pHungUp;
-(void)rtspHungUp;
-(void)sendCommandType:(int)type andOption:(int)option;
-(void)getContactsStates:(NSArray*)contacts;

-(void)getPlaybackFilesWithId:(NSString*)contactId password:(NSString*)password timeInterval:(NSInteger)interval;

-(void)getPlaybackFilesWithIdByDate:(NSString*)contactId password:(NSString*)password startDate:(NSDate*)startDate endDate:(NSDate*)endDate;

-(NSInteger)getPlaybackCurrentFileIndex;
-(NSInteger)getPlaybackFilesLength;

-(void)previous;
-(void)next;
-(void)jump:(UInt64)value;


//p2psetting
-(void)getDeviceTimeWithId:(NSString*)contactId password:(NSString*)password;
-(void)setDeviceTimeWithId:(NSString*)contactId password:(NSString*)password year:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute;

-(void)getSDCardInfoWithId:(NSString *)contactId password:(NSString *)password;
-(void)setSDCardInfoWithId:(NSString *)contactId password:(NSString *)password sdcardID:(int)sdcardID;

-(void)getNpcSettingsWithId:(NSString*)contactId password:(NSString*)password;
-(void)setVideoFormatWithId:(NSString*)contactId password:(NSString*)password type:(NSInteger)type;

-(void)setVideoVolumeWithId:(NSString*)contactId password:(NSString*)password value:(NSInteger)value;

-(void)setDevicePasswordWithId:(NSString*)contactId password:(NSString*)password newPassword:(NSString*)newPassword;

-(void)setVisitorPasswordWithId:(NSString*)contactId password:(NSString*)password newPassword:(NSString*)newPassword;

//移动侦测蜂鸣器开关设置
-(void)setMotionWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state;
-(void)setBuzzerWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state;

-(void)setImageInversionWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state;
-(void)setAutoUpdateWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state;
-(void)setHumanInfraredWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state;
-(void)setWiredAlarmInputWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state;
-(void)setWiredAlarmOutputWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state;
-(void)setDeviceTimezoneWithId:(NSString*)contactId password:(NSString*)password value:(NSInteger)value;

//获取和设置报警邮箱
-(void)getAlarmEmailWithId:(NSString*)contactId password:(NSString*)password;
-(void)setAlarmEmailWithId:(NSString*)contactId password:(NSString*)password email:(NSString*)email smtpServer:(NSString *)smtpServer smtpPort:(int)smtpPort smtpUser:(NSString *)smtpUser smtpPwd:(NSString *)smtpPwd encryptType:(int)encryptType subject:(NSString *)subject content:(NSString *)content isSupportSMTP:(BOOL)isSupportSMTP;

//获取和设置报警推送账号
-(void)getBindAccountWithId:(NSString*)contactId password:(NSString*)password;
    
-(void)setBindAccountWithId:(NSString*)contactId password:(NSString*)password datas:(NSMutableArray*)datas;

-(void)setRemoteDefenceWithId:(NSString*)contactId password:(NSString*)password state:(NSInteger)state;
-(void)setRemoteRecordWithId:(NSString*)contactId password:(NSString*)password state:(unsigned int)state;

-(void)setRecordPreWithId:(NSString*)contactId password:(NSString*)password state:(unsigned int)state;
    
-(void)setRecordTypeWithId:(NSString*)contactId password:(NSString*)password type:(unsigned int)type;

-(void)setRecordTimeWithId:(NSString*)contactId password:(NSString*)password value:(NSInteger)value;

-(void)setRecordPlanTimeWithId:(NSString*)contactId password:(NSString*)password time:(NSInteger)time;

-(void)setNetTypeWithId:(NSString*)contactId password:(NSString*)password type:(NSInteger)type;

-(void)getWifiListWithId:(NSString*)contactId password:(NSString*)password;

-(void)setWifiWithId:(NSString*)contactId password:(NSString*)password type:(NSInteger)type name:(NSString*)name wifiPassword:(NSString*)wifiPassword;

-(void)getDefenceAreaState:(NSString*)contactId password:(NSString*)password;

-(void)setDefenceAreaState:(NSString*)contactId password:(NSString*)password group:(NSInteger)group item:(NSInteger)item type:(NSInteger)type;

- (void) getDefenceSwitchStateWithId:(NSString *)contactId password:(NSString *)password;
- (void) setDefenceSwitchStateWithId:(NSString *)contactId password:(NSString *)password switchId:(int)switchId alarmCodeId:(int)alarmCodeId alarmCodeIndex:(int)alarmCodeIndex;

-(void)setInitPasswordWithId:(NSString*)contactId initPassword:(NSString*)initPassword;


-(void)checkDeviceUpdateWithId:(NSString*)contactId password:(NSString*)password;
-(void)doDeviceUpdateWithId:(NSString*)contactId password:(NSString*)password;
-(void)cancelDeviceUpdateWithId:(NSString*)contactId password:(NSString*)password;
-(NSInteger)sendMessageToFriend:(NSString*)contactId message:(NSString*)message;

-(void)getDefenceState:(NSString*)contactId password:(NSString*)password;

-(void)getDeviceInfoWithId:(NSString*)contactId password:(NSString*)password;

//开锁接口
-(void)sendCustomCmdWithId:(NSString*)contactId password:(NSString*)password cmd:(NSString*)cmd;

//设置GPIO中值
-(void)setGpioCtrlWithId:(NSString *)contactId password:(NSString *)password group:(int)group pin:(int)pin value:(int)value time:(int [])time;

//灯控制接口-获取灯的状态（开或关）
-(void)getLightStateWithDeviceId:(NSString *)contactId password:(NSString *)password;

//灯控制接口-设置灯的状态（开或关）
-(void)setLightStateWithDeviceId:(NSString *)contactId password:(NSString *)password switchState:(int)state;

//用户命令无密码验证删除绑定推送ID
-(void)deleteAlarmPushIDWithId:(NSString *)contactId;

//告诉设备端不要再推送门铃
-(void)stopDoorbellPushWithId:(NSString *)contactId;

//获取设备支持的语言，以及当前显示的语言
-(void)getDeviceSupportedLanguageAndCurrentLanguageWithId:(NSString *)contactId password:(NSString *)password;

//设置设备当前要显示的语言
//currentLanguage代表某种语言的数字编号
-(void)setDeviceCurrentLanguageWithId:(NSString *)contactId password:(NSString *)password currentLanguage:(int)currentLanguage;

@end
