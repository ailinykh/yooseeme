//
//  DeviceListViewController.m
//  yooseeme
//
//  Created by Tony on 22.09.16.
//  Copyright © 2016 Tony. All rights reserved.
//

#import "DeviceListViewController.h"
#import "FListManager.h"
#import "Contact.h"
#import "P2PClient.h"
#import "DeviceSettingsViewController.h"
#import "ChangePasswordViewController.h"
#import "UDPManager.h"
#import "Utils.h"
#import "Reachability.h"
#import "P2PMonitorController.h"
#import "PasswordViewController.h"

@interface DeviceListViewController ()
@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic) NSArray *localDeviceArray;
@property (nonatomic) Reachability *hostReachability;
@end

@implementation DeviceListViewController

- (void)dealloc {
    [_hostReachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLanDevices) name:kReachabilityChangedNotification object:nil];
    
    _hostReachability = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    [_hostReachability startNotifier];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reloadContacts) forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self reloadContacts];
}

- (void)reloadContacts
{
    [self.refreshControl beginRefreshing];
    [self refreshLanDevices];
    _contacts = [[NSMutableArray alloc] initWithArray:[[FListManager sharedFList] getContacts]];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)receiveRemoteMessage:(NSNotification*)note
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, note.userInfo);
}

- (void)ack_receiveRemoteMessage:(NSNotification*)note
{
    NSLog(@"%s %@", __PRETTY_FUNCTION__, note.userInfo);
}

- (void)refreshLanDevices {
    NSArray *lanDeviceArray = [[UDPManager sharedDefault] getLanDevices];
    NSMutableArray *array = [Utils getNewDevicesFromLan:lanDeviceArray];
    if (array.count != _localDeviceArray.count) {
        _localDeviceArray = array;
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _localDeviceArray.count > 0 ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_localDeviceArray.count > 0 && section == 0) {
        return _localDeviceArray.count;
    }
    return _contacts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    if (_localDeviceArray.count > 0 && indexPath.section == 0) {
        LocalDevice *device = _localDeviceArray[indexPath.row];
        cell.textLabel.text = device.contactId;
    } else {
        Contact *contact = _contacts[indexPath.row];
        cell.textLabel.text = contact.contactName;
    }
    
    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    if (_localDeviceArray.count > 0 && indexPath.section == 0)
    {
        LocalDevice *device = _localDeviceArray[indexPath.row];
        PasswordViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"PasswordViewController"];
        vc.deviceId = device.contactId;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else
    {
        Contact *contact = _contacts[indexPath.row];
        NSString *weakPwd = [contact.contactPassword substringToIndex:1];
        if (![weakPwd isEqualToString:@"0"])
        {//弱（红）
            ChangePasswordViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"changePasswordViewController"];
            vc.contact = contact;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else
        {
            [[P2PClient sharedClient] setIsBCalled:NO];
            [[P2PClient sharedClient] setCallId:contact.contactId];
            [[P2PClient sharedClient] setP2pCallType:P2PCALL_TYPE_MONITOR];
            [[P2PClient sharedClient] setCallPassword:contact.contactPassword];
            
            P2PMonitorController *monitorController = [[P2PMonitorController alloc] init];
            [self presentViewController:monitorController animated:YES completion:nil];
            
            //        DeviceSettingsViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"deviceSettingsViewController"];
            //        vc.contact = contact;
            //        [self.navigationController pushViewController:vc animated:YES];
        }
    }
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:DeviceSettingsViewController.class]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Contact *contact = _contacts[indexPath.row];
        [(DeviceSettingsViewController*)segue.destinationViewController setContact:contact];
    }
}

@end
