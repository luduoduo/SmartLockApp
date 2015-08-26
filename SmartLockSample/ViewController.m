//
//  ViewController.m
//  SmartLockSample
//
//  Created by lufei on 15/8/26.
//  Copyright (c) 2015年 lufei. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // create a new scene
    SCNScene *scene=[[SCNScene alloc]init];
    
    //创建几何形状
    SCNCylinder *cylinderGeometry=[SCNCylinder cylinderWithRadius:1.0 height:0.3];
    cylinderGeometry.firstMaterial.diffuse.contents=[UIColor greenColor];
    
    //用几何形状创建node
    SCNNode *cylinderNode=[SCNNode nodeWithGeometry:cylinderGeometry];
    cylinderNode.name=@"cylinder";
    
    SCNCapsule *capsuleGeometry=[SCNCapsule capsuleWithCapRadius:0.2 height:0.8];
    capsuleGeometry.firstMaterial.diffuse.contents=[UIColor cyanColor];
    capsuleGeometry.firstMaterial.specular.contents=[UIColor whiteColor];
    
    SCNNode *capsuleNode=[SCNNode nodeWithGeometry:capsuleGeometry];
    capsuleNode.name=@"capsule";
    capsuleNode.position=SCNVector3Make(0, 0.12, -1.0);
    capsuleNode.eulerAngles=SCNVector3Make(M_PI/2, 0, 0);
    
    //设定主物体
    SCNNode *gyroNode=[[SCNNode alloc]init];
    gyroNode.name=@"gyro";
    [gyroNode addChildNode:cylinderNode];
    [gyroNode addChildNode:capsuleNode];
    gyroNode.position=SCNVector3Make(0, 0, 0);
    
    [scene.rootNode addChildNode:gyroNode];
    
    self.mainObjectNode=gyroNode;
    //设定地平面
    SCNPlane *planeGeometry=[SCNPlane planeWithWidth:200 height:200];
    planeGeometry.firstMaterial.diffuse.contents=[UIColor grayColor];
    
    SCNNode *planeNode=[SCNNode nodeWithGeometry:planeGeometry];
    planeNode.eulerAngles = SCNVector3Make(-M_PI/2, 0, 0);
    planeNode.position = SCNVector3Make(0, -1.5, 0);
    [scene.rootNode addChildNode:planeNode];
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = [SCNCamera camera];
    //    cameraNode.camera.usesOrthographicProjection=YES;
    [scene.rootNode addChildNode:cameraNode];
    
    // place the camera
    //摆放照相机
    cameraNode.position = SCNVector3Make(-2, 3.5, 4.5);
    //确保Camera朝向物体
    SCNLookAtConstraint *constraint = [SCNLookAtConstraint lookAtConstraintWithTarget:gyroNode];
    constraint.gimbalLockEnabled = YES;
    cameraNode.constraints= [NSArray arrayWithObjects:constraint, nil];
    
    
    // create and add a light to the scene
    //omni light
    //    SCNNode *lightNode = [SCNNode node];
    //    lightNode.light = [SCNLight light];
    //    lightNode.light.type = SCNLightTypeOmni;
    //    lightNode.light.castsShadow = YES;
    //    lightNode.position = SCNVector3Make(20, 50, 10);
    //
    //    [scene.rootNode addChildNode:lightNode];
    
    //spot light
    SCNNode *spotLightNode = [SCNNode node];
    spotLightNode.light = [SCNLight light];
    spotLightNode.light.type = SCNLightTypeSpot;
    spotLightNode.light.spotInnerAngle=20.0;
    spotLightNode.light.spotOuterAngle=80.0;
    
    spotLightNode.light.castsShadow = YES;
    spotLightNode.position = SCNVector3Make(3, 5, 10);
    //    lightNode.light.color = [UIColor greenColor];
    
    [scene.rootNode addChildNode:spotLightNode];
    
    //ambient光
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor colorWithWhite:0.5 alpha:1.0];
    [scene.rootNode addChildNode:ambientLightNode];
    
    
    // animate the 3d object
    //    [theNode runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:0.1 z:0 duration:1]]];    //每秒多少弧度
    
    [self.mainObjectNode runAction:[SCNAction rotateByX:M_PI/2 y:0 z:0 duration:1]];
    
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.sceneView;
    
    // set the scene to the view
    scnView.scene = scene;
    
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = NO;
    
    // show statistics such as fps and timing information
    scnView.showsStatistics = NO;
    
    // configure the view
    scnView.backgroundColor = [UIColor blackColor];
    
    // add a tap gesture recognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    
    //这些手势是自带的
    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
    scnView.gestureRecognizers = gestureRecognizers;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//捕获点击手势，相当于飞机被击中
- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.sceneView;
    
    // check what nodes are tapped
    CGPoint p = [gestureRecognize locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
    
    // check that we clicked on at least one object
    if([hitResults count] > 0)
    {
        // retrieved the first clicked object
        SCNHitTestResult *result = [hitResults objectAtIndex:0];
        
        
        if (result.node.parentNode==self.mainObjectNode)
        {
            //设定新的角度
            //            self.mainObjectNode.eulerAngles=SCNVector3Make(M_PI/2, M_PI/6, 0);
            
            // highlight it
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:1];
            
            for (SCNNode *node in self.mainObjectNode.childNodes) {
                // get its material
                SCNMaterial *material = node.geometry.firstMaterial;
                material.emission.contents = [UIColor redColor];
                
                [self.mainObjectNode runAction:[SCNAction rotateByX:0 y:0 z:M_PI/6 duration:1]];
                
            }
            
            // on completion - unhighlight
            [SCNTransaction setCompletionBlock:^{
                [SCNTransaction begin];
                [SCNTransaction setAnimationDuration:0.5];
                for (SCNNode *node in self.mainObjectNode.childNodes) {
                    SCNMaterial *material = node.geometry.firstMaterial;
                    material.emission.contents = [UIColor blackColor];
                }
                [SCNTransaction commit];
            }];
            
            [SCNTransaction commit];
        }
    }
}
@end
