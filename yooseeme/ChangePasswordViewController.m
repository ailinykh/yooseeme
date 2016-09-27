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

@interface ChangePasswordViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *oldPasswordTextField;
@property (nonatomic, weak) IBOutlet UITextField *renewPasswordTextField;
@property (nonatomic, weak) IBOutlet UITextField *confirmPasswordTextField;

@end

@implementation ChangePasswordViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
}

- (void)receiveRemoteMessage:(NSNotification *)notification {
    NSDictionary *parameter = [notification userInfo];
    int key   = [[parameter valueForKey:@"key"] intValue];
    switch(key){
            
        case RET_SET_DEVICE_PASSWORD:
        {
            
            NSInteger result = [[parameter valueForKey:@"result"] intValue];
            
            if (result==0) {
                _contact.contactPassword = _renewPasswordTextField.text;
                [[FListManager sharedFList] update:_contact];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
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
        [[P2PClient sharedClient] setDevicePasswordWithId:_contact.contactId password:_oldPasswordTextField.text newPassword:_renewPasswordTextField.text];
    }
}

@end
