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
    
    [self setup3DScene];
    
    //adjust orientation of object
    [self.mainObjectNode runAction:[SCNAction rotateByX:M_PI/2 y:0 z:0 duration:1]];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 3D scene

-(void) createMainObject: (SCNNode *)rootNode
{
    SCNCylinder *cylinderGeometry=[SCNCylinder cylinderWithRadius:1.0 height:0.3];
    cylinderGeometry.firstMaterial.diffuse.contents=[UIColor greenColor];
    SCNNode *cylinderNode=[SCNNode nodeWithGeometry:cylinderGeometry];
    cylinderNode.name=@"cylinder";
    
    SCNCapsule *capsuleGeometry=[SCNCapsule capsuleWithCapRadius:0.2 height:0.8];
    capsuleGeometry.firstMaterial.diffuse.contents=[UIColor cyanColor];
    capsuleGeometry.firstMaterial.specular.contents=[UIColor whiteColor];
    
    SCNNode *capsuleNode=[SCNNode nodeWithGeometry:capsuleGeometry];
    capsuleNode.name=@"capsule";
    capsuleNode.position=SCNVector3Make(0, 0.12, -1.0);
    capsuleNode.eulerAngles=SCNVector3Make(M_PI/2, 0, 0);
    
    //main object
    SCNNode *gyroNode=[[SCNNode alloc]init];
    gyroNode.name=@"lock";
    [gyroNode addChildNode:cylinderNode];
    [gyroNode addChildNode:capsuleNode];
    gyroNode.position=SCNVector3Make(0, 0, 0);

    [rootNode addChildNode:gyroNode];
    self.mainObjectNode=gyroNode;
}


-(void) create3DButtons: (SCNNode *)rootNode
{
    SCNSphere *sphereGeometry=[SCNSphere sphereWithRadius:0.2];
    sphereGeometry.firstMaterial.diffuse.contents=[UIColor yellowColor];
    SCNNode *sphereNode=[SCNNode nodeWithGeometry:sphereGeometry];
    sphereNode.name=@"startButton";
    sphereNode.position=SCNVector3Make(-0.8, 2.2, 0);
    [rootNode addChildNode:sphereNode];
    self.btnStartNode=sphereNode;
    
    sphereGeometry=[SCNSphere sphereWithRadius:0.2];
    sphereGeometry.firstMaterial.diffuse.contents=[UIColor yellowColor];
    sphereNode=[SCNNode nodeWithGeometry:sphereGeometry];
    sphereNode.name=@"endButton";
    sphereNode.position=SCNVector3Make(0, 2.2, 0);
    [rootNode addChildNode:sphereNode];
    self.btnEndNode=sphereNode;

    
    sphereGeometry=[SCNSphere sphereWithRadius:0.2];
    sphereGeometry.firstMaterial.diffuse.contents=[UIColor whiteColor];
    sphereNode=[SCNNode nodeWithGeometry:sphereGeometry];
    sphereNode.name=@"searchButton";
    sphereNode.position=SCNVector3Make(0.8, 2.2, 0);
    [rootNode addChildNode:sphereNode];
    self.btnSearchNode=sphereNode;
}


- (void) setup3DScene
{
    // create a new scene and main object
    SCNScene *scene=[[SCNScene alloc]init];
    [self createMainObject:scene.rootNode];
    [self create3DButtons: scene.rootNode];
    
    // create ground
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
    cameraNode.position = SCNVector3Make(-2, 3.5, 4.5);
    //make camera face to object
    SCNLookAtConstraint *constraint = [SCNLookAtConstraint lookAtConstraintWithTarget:self.mainObjectNode];
    constraint.gimbalLockEnabled = YES;
    cameraNode.constraints= [NSArray arrayWithObjects:constraint, nil];
    
    //spot light
    SCNNode *spotLightNode = [SCNNode node];
    spotLightNode.light = [SCNLight light];
    spotLightNode.light.type = SCNLightTypeSpot;
    spotLightNode.light.spotInnerAngle=20.0;
    spotLightNode.light.spotOuterAngle=80.0;
    spotLightNode.light.castsShadow = YES;
    spotLightNode.position = SCNVector3Make(3, 5, 10);
    [scene.rootNode addChildNode:spotLightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor colorWithWhite:0.5 alpha:1.0];
    [scene.rootNode addChildNode:ambientLightNode];
    
    // setup the SCNView
    SCNView *scnView = (SCNView *)self.sceneView;   //pre-cerated in storyboard
    
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
    
    // default gest
    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
    scnView.gestureRecognizers = gestureRecognizers;
}


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
        
        if (result.node==self.btnStartNode)
        {
            [self highlightObject:result.node duration:0.25];
            NSLog(@"marking start point");
        }
        else if (result.node==self.btnEndNode)
        {
            [self highlightObject:result.node duration:0.25];
            NSLog(@"marking end point");
        }
        else if (result.node==self.btnSearchNode)
        {
            [self highlightObject:result.node duration:0.25];
            NSLog(@"start searching");
        }
        else if (result.node.parentNode==self.mainObjectNode)
        {
            //specify new angle
            //self.mainObjectNode.eulerAngles=SCNVector3Make(M_PI/2, M_PI/6, 0);
            [self highlightObject: result.node.parentNode duration:1];
            
            [result.node.parentNode runAction:[SCNAction rotateByX:0 y:0 z:M_PI/6 duration:1]];
        }

        

    }
}

-(void) highlightObject:(SCNNode *)objectNode duration:(CFTimeInterval)sec
{
    // highlight it
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:sec];
    
    if (objectNode.childNodes.count>0)
    {
        for (SCNNode *node in objectNode.childNodes) {
            // get its material
            SCNMaterial *material = node.geometry.firstMaterial;
            material.emission.contents = [UIColor redColor];
        }
    }
    else
    {
        objectNode.geometry.firstMaterial.emission.contents=[UIColor redColor];
    }
    
    // on completion - unhighlight
    [SCNTransaction setCompletionBlock:^{
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:sec];
        if (objectNode.childNodes.count>0)
        {
            for (SCNNode *node in objectNode.childNodes) {
                // get its material
                SCNMaterial *material = node.geometry.firstMaterial;
                material.emission.contents = [UIColor blackColor];
            }
        }
        else
        {
            objectNode.geometry.firstMaterial.emission.contents=[UIColor blackColor];
        }        [SCNTransaction commit];
    }];
    
    [SCNTransaction commit];
}


@end
