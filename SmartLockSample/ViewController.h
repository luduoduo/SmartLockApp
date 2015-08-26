//
//  ViewController.h
//  SmartLockSample
//
//  Created by lufei on 15/8/26.
//  Copyright (c) 2015年 lufei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>


@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet SCNView *sceneView;
@property (nonatomic, strong) SCNNode *mainObjectNode;

@property (nonatomic, strong) SCNNode *btnStartNode;
@property (nonatomic, strong) SCNNode *btnEndNode;
@property (nonatomic, strong) SCNNode *btnSearchNode;

@end

