//
//  PasswordViewController.m
//  yooseeme
//
//  Created by tony on 23/09/16.
//  Copyright © 2016 Tony. All rights reserved.
//

#import "PasswordViewController.h"

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
        
    }
}

@end
