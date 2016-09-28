//
//  ChangePasswordViewController.m
//  yooseeme
//
//  Created by Tony on 27.09.16.
//  Copyright © 2016 Tony. All rights reserved.
//

#import "ChangePasswordViewController.h"
#import "P2PClient.h"
#import "FListManager.h"
#import "Utils.h"
#import "MD5Manager.h"

@interface ChangePasswordViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *oldPasswordTextField;
@property (nonatomic, weak) IBOutlet UITextField *renewPasswordTextField;
@property (nonatomic, weak) IBOutlet UITextField *confirmPasswordTextField;

@property (strong, nonatomic) NSString *lastSetOriginPassowrd;
@property (strong, nonatomic) NSString *lastSetNewPassowrd;

@end

@implementation ChangePasswordViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
}

- (void)receiveRemoteMessage:(NSNotification *)notification {
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    switch(key){
            
        case RET_SET_DEVICE_PASSWORD:
        {
            
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            NSLog(@"Change password result is: %d", result);
            if (result==0) {
                _contact.contactPassword = _lastSetNewPassowrd;
                [[FListManager sharedFList] update:_contact];
                dispatch_async(dispatch_get_main_queue(), ^{
                   [self.navigationController popToRootViewControllerAnimated:YES];
                });
            }
        }
            break;
    }
    
}

- (void)ack_receiveRemoteMessage:(NSNotification *)notification {
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    int result   = [[parameter valueForKey:@"result"] intValue];
    switch(key){
        case ACK_RET_SET_DEVICE_PASSWORD:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(result==1){
                    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Error"
                                                                                message:@"Original password is wrong"
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                    [ac addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:ac animated:YES completion:nil];
                }else if(result==2){
                    DLog(@"resend set device password");
                    [[P2PClient sharedClient] setDevicePasswordWithId:_contact.contactId password:_lastSetOriginPassowrd newPassword:_lastSetNewPassowrd];
                }
            });
            DLog(@"ACK_RET_SET_DEVICE_PASSWORD:%i",result);
        }
        break;
    }
}

#pragma mark - text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 3)
    {
        NSString *originalPassword = _oldPasswordTextField.text;
        NSString *newPassword = _renewPasswordTextField.text;
        
        if ([Utils IsNeedEncrypt:newPassword]) {
            unsigned int ret = [MD5Manager EncryptGW1:[newPassword UTF8String]];
            newPassword = [NSString stringWithFormat:@"0%d", ret];
        }
        
        if ([Utils IsNeedEncrypt:originalPassword]) {
            unsigned int ret = [MD5Manager EncryptGW1:[originalPassword UTF8String]];
            originalPassword = [NSString stringWithFormat:@"0%d", ret];
        }
        
        _lastSetOriginPassowrd = originalPassword;
        _lastSetNewPassowrd = newPassword;
        
        [[P2PClient sharedClient] setDevicePasswordWithId:_contact.contactId password:originalPassword newPassword:newPassword];
    }
}

@end
