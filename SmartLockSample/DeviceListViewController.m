//
//  DeviceListViewController.m
//  SmartLockSample
//
//  Created by lufei on 15/8/26.
//  Copyright (c) 2015年 lufei. All rights reserved.
//

#import "DeviceListViewController.h"

@interface DeviceListViewController ()

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    self.blunoManager.delegate=self;
    [self.blunoManager scan];
    [self.searchIndicator startAnimating];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self.blunoManager stop];
    [self.searchIndicator stopAnimating];
    self.blunoManager.delegate=nil;
}


- (IBAction)btnBackClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/




#pragma mark- TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger nCount = self.blunoManager.arrayBlunoDevices.count;
    return nCount;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"BleDeviceCell"];
    
    DFBlunoDevice* peripheral=[self.blunoManager.arrayBlunoDevices objectAtIndex:indexPath.row];

    cell.textLabel.text=peripheral.name;
    cell.detailTextLabel.text=peripheral.identifier;

    return cell;
}


#pragma mark- TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DFBlunoDevice* device = [self.blunoManager.arrayBlunoDevices objectAtIndex:indexPath.row];
    if (self.blunoDev == nil)
    {
        self.blunoDev = device;
        [self.blunoManager connectToDevice:self.blunoDev];
    }
    else if ([device isEqual:self.blunoDev])
    {
        if (!self.blunoDev.bReadyToWrite)
        {
            [self.blunoManager connectToDevice:self.blunoDev];
        }
    }
    else
    {
        if (self.blunoDev.bReadyToWrite)
        {
            [self.blunoManager disconnectToDevice:self.blunoDev];
            self.blunoDev = nil;
        }

        [self.blunoManager connectToDevice:device];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(void)didUpdateDeviceInfo
{
    [self.tableView reloadData];
}


@end
