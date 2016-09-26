//
//  PasswordViewController.m
//  yooseeme
//
//  Created by tony on 23/09/16.
//  Copyright © 2016 Tony. All rights reserved.
//

#import "PasswordViewController.h"
#import "Contact.h"
#import "FListManager.h"
#import "P2PClient.h"

@interface PasswordViewController () <UITextFieldDelegate> {
}
@property (nonatomic, weak) IBOutlet UITextField *nameTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;

@end

@implementation PasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _nameTextField.text = [@"Cam" stringByAppendingString:_deviceId];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_passwordTextField becomeFirstResponder];
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        Contact *contact = [[Contact alloc] init];
        contact.contactId = _deviceId;
        contact.contactName = _nameTextField.text;
        contact.contactPassword = _passwordTextField.text;
        contact.contactType = CONTACT_TYPE_UNKNOWN;
        [[FListManager sharedFList] insert:contact];
        
        [[P2PClient sharedClient] getContactsStates:@[contact.contactId]];
        [[P2PClient sharedClient] getDefenceState:contact.contactId password:contact.contactPassword];
        
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

@end
