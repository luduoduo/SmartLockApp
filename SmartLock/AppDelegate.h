//
//  AppDelegate.h
//  SmartLock
//
//  Created by lufei on 15/8/26.
//  Copyright (c) 2015年 lufei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

//记录图标上的通知数字
@property (nonatomic, assign) NSInteger appIconBadgeNumber;
@end

