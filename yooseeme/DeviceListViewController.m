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

@interface DeviceListViewController ()
@property (nonatomic, strong) NSMutableArray *contacts;
@end

@implementation DeviceListViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveRemoteMessage:) name:RECEIVE_REMOTE_MESSAGE object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ack_receiveRemoteMessage:) name:ACK_RECEIVE_REMOTE_MESSAGE object:nil];
    
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

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _contacts.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    
    // Configure the cell...
    Contact *contact = _contacts[indexPath.row];
    cell.textLabel.text = contact.contactName;
    
    return cell;
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
