//
//  FTAccountsViewController.m
//  iJenkins
//
//  Created by Ondrej Rafaj on 29/08/2013.
//  Copyright (c) 2013 Fuerte Innovations. All rights reserved.
//

#import "FTAccountsViewController.h"
#import "FTNoAccountCell.h"
#import "FTAccountCell.h"
#import "FTIconCell.h"
#import "FTSmallTextCell.h"
#import "GCNetworkReachability.h"
#import "NSData+Networking.h"
#import "FTServerHomeViewController.h"


@interface FTAccountsViewController () <FTAccountCellDelegate>

@property (nonatomic, strong) NSArray *data;

@property (nonatomic, strong) NSMutableDictionary *reachabilityCache;
@property (nonatomic, strong) NSMutableDictionary *reachabilityStatusCache;

@end


@implementation FTAccountsViewController


#pragma mark Initialization

- (id)init {
    self = [super init];
    if (self) {
        _reachabilityStatusCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark Layout

- (void)scrollToAccount:(FTAccount *)account {
    
}

#pragma mark Data

- (void)reloadData {
    [super.tableView reloadData];
}

- (NSArray *)datasourceForIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return _data;
            break;
            
        default:
            return nil;
            break;
    }
}

- (FTAccount *)accountForIndexPath:(NSIndexPath *)indexPath {
    return [[self datasourceForIndexPath:indexPath] objectAtIndex:indexPath.row];
}

#pragma mark Creating elements

- (void)createTableView {
    _data = [[FTAccountsManager sharedManager] accounts];
    
    [super createTableView];
}

- (void)createTopButtons {
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didCLickAddItem:)];
    [self.navigationItem setLeftBarButtonItem:add];
    
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithTitle:FTLangGet(@"Edit") style:UIBarButtonItemStylePlain target:self action:@selector(didCLickEditItem:)];
    //[edit registerTitleWithTranslationKey:@"Edit"];
    [self.navigationItem setRightBarButtonItem:edit];
}

- (void)createAllElements {
    [super createAllElements];
    
    [self createTableView];
    [self createTopButtons];
    
    [self setTitle:FTLangGet(@"Servers")];
}

#pragma mark View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [FTAPIConnector stopLoadingAll];
    
    //  Custom UIMenuController items for the accounts
    //  These are added only for this controller and are removed at the -viewWillDisappear
    UIMenuItem *copyUrlItem = [[UIMenuItem alloc] initWithTitle:FTLangGet(@"Copy URL") action:@selector(copyURL:)];
    UIMenuItem *openInBrowser = [[UIMenuItem alloc] initWithTitle:FTLangGet(@"Open in browser") action:@selector(openInBrowser:)];
    [[UIMenuController sharedMenuController] setMenuItems: @[copyUrlItem, openInBrowser]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //  Remove custom menu actions
    [[UIMenuController sharedMenuController] setMenuItems:nil];
}

#pragma mark Actions

- (void)didCLickAddItem:(UIBarButtonItem *)sender {
    FTAddAccountViewController *c = [[FTAddAccountViewController alloc] init];
    [c setIsNew:YES];
    FTAccount *acc = [[FTAccount alloc] init];
    [c setAccount:acc];
    [c setDelegate:self];
    [c setTitle:FTLangGet(@"New Instance")];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:c];
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)didCLickEditItem:(UIBarButtonItem *)sender {
    [super.tableView setEditing:!super.tableView.editing animated:YES];
    
    NSString *title;
    if (self.tableView.editing) {
        title = FTLangGet(@"Done");
    }
    else {
        title = FTLangGet(@"Edit");
    }
    
    UIBarButtonItem *edit = self.navigationItem.rightBarButtonItem;
    [edit setTitle:title];
}

#pragma mark Table view delegate and data source methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return ((_data.count > 0) ? _data.count : 1);
            break;
            
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _data.count == 0) {
        return 100;
    }
    else {
        return 54;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return FTLangGet(@"Your accounts");
            break;
            
        default:
            return nil;
            break;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == 0 && _data.count == 0) || indexPath.section) {
        return NO;
    }
    else return (indexPath.section == 0);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        FTAccount *acc = [_data objectAtIndex:indexPath.row];
        [[FTAccountsManager sharedManager] removeAccount:acc];
        [tableView reloadData];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0 && [_data count] > 1);
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    FTAccount *movedAccount = [self accountForIndexPath:sourceIndexPath];
    [[FTAccountsManager sharedManager] moveAccount:movedAccount toIndex:destinationIndexPath.row];
}

- (UITableViewCell *)cellForNoAccount {
    static NSString *identifier = @"noAccountCell";
    FTNoAccountCell *cell = [super.tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[FTNoAccountCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    return cell;
}

- (UITableViewCell *)accountCellForIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"accountCell";
    FTAccountCell *cell = [super.tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[FTAccountCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.delegate = self;
        
    }
    if (indexPath.section == 0) {
        [cell setAccessoryType:UITableViewCellAccessoryDetailDisclosureButton];
    }
    else {
        [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    }
    __block FTAccount *acc = [self accountForIndexPath:indexPath];
    [cell.textLabel setText:acc.name];
    NSString *port = (acc.port != 0) ? [NSString stringWithFormat:@":%ld", (long)acc.port] : @"";
    NSString *path = ([@"/" isEqualToString:acc.pathSuffix]) ? @"" : acc.pathSuffix;
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"%@%@%@", acc.host, port, path]];
    
    //  Status of the server
    NSNumber *key = @([acc hash]);
    NSNumber *statusNumber = _reachabilityStatusCache[key];
    
    if (indexPath.section == 1) {
        statusNumber = [NSNumber numberWithInt:FTAccountCellReachabilityStatusReachable];
    }
    else {
        if (acc.host.length > 0) {
            GCNetworkReachability *r = _reachabilityCache[acc.host];
            if (!r) {
                r = [GCNetworkReachability reachabilityWithHostName:acc.host];
                if (!_reachabilityCache) {
                    _reachabilityCache = [NSMutableDictionary dictionary];
                }
                _reachabilityCache[acc.host] = r;
                [r startMonitoringNetworkReachabilityWithHandler:^(GCNetworkReachabilityStatus status) {
                    __block FTAccountCellReachabilityStatus s = (status == GCNetworkReachabilityStatusNotReachable) ? FTAccountCellReachabilityStatusUnreachable : FTAccountCellReachabilityStatusReachable;
                    if (status == GCNetworkReachabilityStatusNotReachable) {
                        _reachabilityStatusCache[key] = @(s);
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    }
                    else {
                        _reachabilityStatusCache[key] = @(s);
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                        
                        // TODO: Finish the API request to check server API, not just reachability
                        /*
                         [[FTAccountsManager sharedManager] setSelectedAccount:acc];
                         FTAPIOverallLoadDataObject *loadObject = [[FTAPIOverallLoadDataObject alloc] init];
                         [FTAPIConnector connectWithObject:loadObject andOnCompleteBlock:^(id<FTAPIDataAbstractObject> dataObject, NSError *error) {
                         if (error) {
                         s = FTAccountCellReachabilityStatusUnreachable;
                         }
                         else {
                         s = FTAccountCellReachabilityStatusReachable;
                         }
                         _reachabilityStatusCache[key] = @(s);
                         [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                         }];
                         */
                    }
                }];
            }
        }
    }
    
    if (statusNumber) {
        cell.reachabilityStatus = [statusNumber unsignedIntegerValue];
    }
    else {
        cell.reachabilityStatus = FTAccountCellReachabilityStatusLoading;
        _reachabilityStatusCache[key] = @(FTAccountCellReachabilityStatusLoading);
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _data.count == 0) {
        return [self cellForNoAccount];
    }
    else {
        if (indexPath.section == 0) {
            return [self accountCellForIndexPath:indexPath];
        }
        
        return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0 && _data.count == 0) {
        [self didCLickAddItem:nil];
    } else {
        if ([self datasourceForIndexPath:indexPath].count > 0) {
            FTAccount *acc = [self accountForIndexPath:indexPath];
            [[FTAccountsManager sharedManager] setSelectedAccount:acc];
            [FTAPIConnector resetForAccount:acc];
            
            FTServerHomeViewController *c = [[FTServerHomeViewController alloc] init];
            [c setTitle:acc.name];
            [self.navigationController pushViewController:c animated:YES];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    FTAccount *acc = [self accountForIndexPath:indexPath];
    FTAddAccountViewController *c = [[FTAddAccountViewController alloc] init];
    [c setDelegate:self];
    [c setTitle:acc.name];
    [c setAccount:acc];
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:c];
    [self presentViewController:nc animated:YES completion:^{
        
    }];
}

//  Showing menu overlay
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return [cell isKindOfClass:[FTAccountCell class]];
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return [cell canPerformAction:action withSender:sender];
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    //  This method have to be present in order to make the UIMenuController work, however there is no imlementation needed as the functionality is handled using cell delegate
}

#pragma mark Add account view controller delegate methods

- (void)addAccountViewController:(FTAddAccountViewController *)controller didAddAccount:(FTAccount *)account {
    [[FTAccountsManager sharedManager] addAccount:account];
    [self reloadData];
    [self scrollToAccount:account];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)addAccountViewController:(FTAddAccountViewController *)controller didModifyAccount:(FTAccount *)account {
    [[FTAccountsManager sharedManager] updateAccount:account];
    [self reloadData];
    [self scrollToAccount:account];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)addAccountViewControllerCloseWithoutSave:(FTAddAccountViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:^{
        [controller resetAccountToOriginalStateIfNotNew];
    }];
}

#pragma mark Account cell delegate

- (void)accountCellMenuCopyURLSelected:(FTAccountCell *)cell {
    FTAccount *account = [self accountForCell:cell];
    NSURL *serverURL = [NSURL URLWithString:[account baseUrl]];
    [[UIPasteboard generalPasteboard] setURL:serverURL];
}

- (void)accountCellMenuOpenInBrowserSelected:(FTAccountCell *)cell {
    FTAccount *account = [self accountForCell:cell];
    NSURL *serverURL = [NSURL URLWithString:[account baseUrl]];
    [[UIApplication sharedApplication] openURL:serverURL];
}

#pragma mark Private methods

- (FTAccount *)accountForCell:(FTAccountCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    return [self accountForIndexPath:indexPath];
}

@end
