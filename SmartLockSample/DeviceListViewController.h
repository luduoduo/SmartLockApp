//
//  DeviceListViewController.h
//  SmartLockSample
//
//  Created by lufei on 15/8/26.
//  Copyright (c) 2015年 lufei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DFBlunoManager.h"

@interface DeviceListViewController : UIViewController
    <UITableViewDataSource, UITableViewDelegate>

@property(strong, nonatomic) DFBlunoManager* blunoManager;
@property(strong, nonatomic) DFBlunoDevice* blunoDev;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchIndicator;
- (IBAction)btnBackClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
