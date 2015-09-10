//
//  ViewController.h
//  SmartLockSample
//
//  Created by lufei on 15/8/26.
//  Copyright (c) 2015年 lufei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import "DFBlunoManager.h"

@interface ViewController : UIViewController <DFBlunoDelegate>

@property (weak, nonatomic) IBOutlet SCNView *sceneView;
@property (nonatomic, strong) SCNNode *mainObjectNode;
@property (nonatomic, strong) SCNNode *ambientLightNode;

@property (nonatomic, strong) SCNNode *btnUnlockNode;
@property (nonatomic, strong) SCNNode *btnLockNode;
@property (nonatomic, strong) SCNNode *btnSearchNode;


@property(strong, nonatomic) DFBlunoManager* blunoManager;
@property(strong, nonatomic) DFBlunoDevice* blunoDev;

@end

