//
//  AddDeviceViewController.m
//  yooseeme
//
//  Created by Tony on 22.09.16.
//  Copyright © 2016 Tony. All rights reserved.
//

#import "AddDeviceViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "elian.h"
#import "GCDAsyncUdpSocket.h"

@interface AddDeviceViewController () <UITextFieldDelegate> {
    void *_context;
}
@property (nonatomic, weak) IBOutlet UITextField *ssidTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) GCDAsyncUdpSocket *socket;

@end

@implementation AddDeviceViewController

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self scanWiFiNetwork];
    [self prepareSocket];
}

- (void)scanWiFiNetwork {
    NSLog(@"Scanning wi-fi...");
    NSDictionary *ifs = [self fetchSSIDInfo];
    NSString *ssid = [ifs objectForKey:@"SSID"];
    if(nil != ssid)
    {
        self.ssidTextField.text = ssid;
    }
    else
    {
        [self performSelector:@selector(scanWiFiNetwork) withObject:nil afterDelay:2];
    }
}

- (id)fetchSSIDInfo
{
    NSArray *ifs = (id)CFBridgingRelease(CNCopySupportedInterfaces());
    NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((CFStringRef)ifnam));
        if (info && [info count]) {
            break;
        }
    }
    return info;
}

#pragma mark - Smart connection

- (void)initSmartConnection
{
    if (!_context) {
        //ssid
        const char *ssid = [self.ssidTextField.text cStringUsingEncoding:NSUTF8StringEncoding];
        //authmode
        int authmode = 9;//delete
        //pwd
        const char *password = [self.passwordTextField.text cStringUsingEncoding:NSUTF8StringEncoding];//NSASCIIStringEncoding
        //target
        unsigned char target[] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
        
        
        _context = elianNew(NULL, 0, target, ELIAN_SEND_V1 | ELIAN_SEND_V4);
        elianPut(_context, TYPE_ID_AM, (char *)&authmode, 1);//delete
        elianPut(_context, TYPE_ID_SSID, (char *)ssid, strlen(ssid));
        elianPut(_context, TYPE_ID_PWD, (char *)password, strlen(password));
        
        [self startSmartConnection];
    }
}

- (void)startSmartConnection {
    static int attemps = 0;
    if (attemps++ < 3)
    {
        [_activityIndicator startAnimating];
        elianStart(_context);
        [self performSelector:@selector(stopSmartConnection) withObject:nil afterDelay:20];
    }
}

- (void)stopSmartConnection {
    elianStop(_context);
    [_activityIndicator stopAnimating];
    [self performSelector:@selector(startSmartConnection) withObject:nil afterDelay:10];
}

#pragma mark - Socket

- (void)prepareSocket {
    GCDAsyncUdpSocket *socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSError *error = nil;
    
    if (![socket bindToPort:9988 error:&error])
    {
        NSLog(@"Error binding: %@", [error localizedDescription]);
    }
    if (![socket beginReceiving:&error])
    {
        NSLog(@"Error receiving: %@", [error localizedDescription]);
    }
    
    if (![socket enableBroadcast:YES error:&error])
    {
        NSLog(@"Error enableBroadcast: %@", [error localizedDescription]);
    }
    
    self.socket = socket;
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.ssidTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self initSmartConnection];
    }
    return YES;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self initSmartConnection];
}

#pragma mark - GCDAsyncUdpSocket
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"did send");
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error
{
    NSLog(@"error %@", error);
}

#pragma mark 搜索设备
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    if (data) {
        Byte receiveBuffer[1024];
        [data getBytes:receiveBuffer length:1024];
        
        if(receiveBuffer[0]==1){
            NSString *host = nil;
            uint16_t port = 0;
            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
            
            int contactId = *(int*)(&receiveBuffer[16]);
            int type = *(int*)(&receiveBuffer[20]);
            int flag = *(int*)(&receiveBuffer[24]);
            
            NSLog(@"GOT DATA!!! %@ %d %d %d", host, contactId, type, flag);
        }
    }
}

@end
