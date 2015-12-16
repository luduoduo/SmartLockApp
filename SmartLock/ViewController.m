//
//  ViewController.m
//  SmartLock
//
//  Created by lufei on 15/8/26.
//  Copyright (c) 2015年 lufei. All rights reserved.
//

#import "ViewController.h"
#import "DeviceListViewController.h"
#import "AppDelegate.h"
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController ()

@end

@implementation ViewController
{
    float _angle_offset;
    float _angle_current;
}

SystemSoundID id_alarm;
SystemSoundID id_button;
SystemSoundID id_longpress;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setup3DScene];
    
    //adjust orientation of object
//    [self.mainObjectNode runAction:[SCNAction rotateByX:M_PI/2 y:0 z:0 duration:90]];
    
    //BLE settings
    self.blunoManager = [DFBlunoManager sharedInstance];
    _angle_offset=0;
    
    [self prepareSoundEffects];
}


-(void) prepareSoundEffects
{
    // Get the main bundle for the app
    CFBundleRef mainBundle = CFBundleGetMainBundle ();
    
    // Create a system sound object representing the sound file
    AudioServicesCreateSystemSoundID (CFBundleCopyResourceURL (mainBundle, CFSTR ("Sound/sms-received4"), CFSTR ("caf"), NULL),
                                      &id_alarm
                                      );
    AudioServicesCreateSystemSoundID (CFBundleCopyResourceURL (mainBundle, CFSTR ("Sound/Cartoon Accent 17"), CFSTR ("caf"), NULL),
                                      &id_button
                                      );
    AudioServicesCreateSystemSoundID (CFBundleCopyResourceURL (mainBundle, CFSTR ("Sound/Bell Transition"), CFSTR ("caf"), NULL),
                                      &id_longpress
                                      );
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    self.blunoManager.delegate = self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    self.blunoManager.delegate = nil;
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
    sphereGeometry.firstMaterial.diffuse.contents=[UIColor redColor];
    SCNNode *sphereNode=[SCNNode nodeWithGeometry:sphereGeometry];
    sphereNode.name=@"startButton";
    sphereNode.position=SCNVector3Make(-0.8, 2.2, 0);
    [rootNode addChildNode:sphereNode];
    self.btnUnlockNode=sphereNode;
    
    sphereGeometry=[SCNSphere sphereWithRadius:0.2];
    sphereGeometry.firstMaterial.diffuse.contents=[UIColor greenColor];
    sphereNode=[SCNNode nodeWithGeometry:sphereGeometry];
    sphereNode.name=@"endButton";
    sphereNode.position=SCNVector3Make(0, 2.2, 0);
    [rootNode addChildNode:sphereNode];
    self.btnLockNode=sphereNode;

    
    sphereGeometry=[SCNSphere sphereWithRadius:0.2];
    sphereGeometry.firstMaterial.diffuse.contents=[UIColor whiteColor];
    sphereNode=[SCNNode nodeWithGeometry:sphereGeometry];
    sphereNode.name=@"searchButton";
    sphereNode.position=SCNVector3Make(0.8, 2.2, 0);
    [rootNode addChildNode:sphereNode];
    self.btnSearchNode=sphereNode;
    self.btnSearchNode.hidden=YES;
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
    ambientLightNode.light.color = [UIColor colorWithWhite:0.4 alpha:1.0];
    [scene.rootNode addChildNode:ambientLightNode];
    self.ambientLightNode=ambientLightNode;
    self.ambientLightNode.hidden=YES;
    
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
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration=2.0f;
    
    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    [gestureRecognizers addObject:longPressGesture];
    
    // default gest
    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
    scnView.gestureRecognizers = gestureRecognizers;
}


#pragma mark - gesture processing for 3D scene
-(NSString *)generateSettingString: (BOOL) isLock
{
    NSString* stringHolder;
    int angle_i=(int)fabs(round(_angle_current));
    if (angle_i<10)
        stringHolder=@"00";
    else if (angle_i<100)
        stringHolder=@"0";
    else if (angle_i<1000)
        stringHolder=@"";
    
    NSString *stringData=[NSString stringWithFormat:@"#i%c%c%@%d", isLock?'l':'u', _angle_current>0?'+':'-', stringHolder, angle_i];
    return stringData;
}


- (void) handleTap:(UIGestureRecognizer*)gestureRecognize
{
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.sceneView;
    
    // check what nodes are tapped
    CGPoint p = [gestureRecognize locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
    
    
    // check that we clicked on at least one object
    if([hitResults count] <= 0)
    {
        return;
    }

    // retrieved the first clicked object
    SCNHitTestResult *result = [hitResults objectAtIndex:0];

    //解锁位置按钮
    if (result.node==self.btnUnlockNode)
    {
        [self highlightObject:result.node duration:0.25 needToRecover:YES];
        AudioServicesPlaySystemSound(id_button);
//        AudioServicesPlaySystemSound(SystemSoundID inSystemSoundID);
        
        NSData* data = [[self generateSettingString:NO] dataUsingEncoding:NSUTF8StringEncoding];
        [self.blunoManager writeDataToDevice:data Device:self.blunoDev];
        
    }
    //上锁位置按钮
    else if (result.node==self.btnLockNode)
    {
        [self highlightObject:result.node duration:0.25 needToRecover:YES];
        AudioServicesPlaySystemSound(id_button);

        NSData* data = [[self generateSettingString:YES] dataUsingEncoding:NSUTF8StringEncoding];
        [self.blunoManager writeDataToDevice:data Device:self.blunoDev];
    }
    //搜索按钮
    else if (result.node==self.btnSearchNode)
    {
        [self highlightObject:result.node duration:0.25 needToRecover:YES];
        AudioServicesPlaySystemSound(id_button);

        self.ambientLightNode.hidden=YES;
        [self performSegueWithIdentifier:@"toSearchListView" sender:nil];
    }
    //主体按钮，用于设定初始状态，要求用户在开锁N区设定
    else if (result.node.parentNode==self.mainObjectNode)
    {
        [self highlightObject: result.node.parentNode duration:0.5 needToRecover:YES];
        AudioServicesPlaySystemSound(id_button);

        _angle_offset=_angle_current;
        
        
        NSData* data = [@"#ir" dataUsingEncoding:NSUTF8StringEncoding];
        [self.blunoManager writeDataToDevice:data Device:self.blunoDev];
    }
    
}




-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognize
{
//    NSLog(@"longpress:%ld",(long)gesture.state);
    // retrieve the SCNView
    SCNView *scnView = (SCNView *)self.sceneView;
    
    // check what nodes are tapped
    CGPoint p = [gestureRecognize locationInView:scnView];
    NSArray *hitResults = [scnView hitTest:p options:nil];
    
    if([hitResults count] <= 0)
        return;
    
    // retrieved the first clicked object
    SCNHitTestResult *result = [hitResults objectAtIndex:0];
    if (result.node.parentNode!=self.mainObjectNode)
        return;
    
    //在按下时生效
    if (gestureRecognize.state==UIGestureRecognizerStateBegan)
    {
        [self shadeObject:result.node.parentNode duration:0.25f color:[UIColor redColor] complete:^{

            SCNHitTestResult *result = [hitResults objectAtIndex:0];
            if (result.node.parentNode==self.mainObjectNode)
            {
                AudioServicesPlaySystemSound(id_longpress);
                UIAlertController *alertController=[UIAlertController alertControllerWithTitle:nil
                                                                                       message:nil
                                                                                preferredStyle:UIAlertControllerStyleActionSheet];
                
                [alertController addAction: [UIAlertAction actionWithTitle: @"Reset device"
                                                                     style: UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action)
                                             {
                                                 NSLog(@"RESET");
                                                 [self shadeObject:result.node.parentNode duration:0.25 color:[UIColor blackColor] complete:nil];
                                                 //重启Arduino
                                                 NSData* data = [[self generateSettingString:NO] dataUsingEncoding:NSUTF8StringEncoding];
                                                 [self.blunoManager writeDataToDevice:data Device:self.blunoDev];
                                             }]];
                
                [alertController addAction: [UIAlertAction actionWithTitle: self.viewIfLoaded.hidden?@"Show details":@"Hide details"
                                                                     style: UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action)
                                             {
                                                 [self shadeObject:result.node.parentNode duration:0.25 color:[UIColor blackColor] complete:nil];
                                                 self.viewInfomation.hidden=!self.viewInfomation.hidden;
                                            
                                             }]];
                
                [alertController addAction: [UIAlertAction actionWithTitle: @"Return"
                                                                     style: UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction *action)
                                             {
                                                 [self shadeObject:result.node.parentNode duration:0.25 color:[UIColor blackColor] complete:nil];
                                                 
                                             }]];
                
                [self presentViewController: alertController animated: YES completion:nil];
            }

        }];
    }
    
}


//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
//{
//    UITouch *touch = [touches anyObject];
//    SCNView *scnView = (SCNView *)self.sceneView;
//    CGPoint p=[touch locationInView:scnView];
//    
//    NSArray *hitResults = [scnView hitTest:p options:nil];
//    
//    if([hitResults count] <= 0)
//        return;
//    
//    // retrieved the first clicked object
//    SCNHitTestResult *result = [hitResults objectAtIndex:0];
//    if (result.node.parentNode!=self.mainObjectNode)
//        return;
//    
//    [self highlightObject:result.node.parentNode duration:0.25 needToRecover:YES];
//}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *vc=segue.destinationViewController;
    
    DeviceListViewController *destVC=vc.viewControllers[0];
    destVC.blunoManager=self.blunoManager;
    destVC.blunoDev=self.blunoDev;
}


-(void) shadeObject:(SCNNode *)objectNode duration:(CFTimeInterval)sec color:(UIColor *)color complete:(void (^)(void))block
{
    // highlight it
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:sec];
    
    if (objectNode.childNodes.count>0)
    {
        for (SCNNode *node in objectNode.childNodes) {
            // get its material
            SCNMaterial *material = node.geometry.firstMaterial;
            material.emission.contents = color;
        }
    }
    else
    {
        objectNode.geometry.firstMaterial.emission.contents=color;
    }
        
    // on completion - unhighlight
    if (block)
        [SCNTransaction setCompletionBlock:block];
 
    [SCNTransaction commit];
}




-(void) highlightObject:(SCNNode *)objectNode duration:(CFTimeInterval)sec needToRecover:(bool)needToRecover
{
    // highlight it
    [self shadeObject:objectNode duration:sec color:[UIColor redColor] complete:^{
        [self shadeObject:objectNode duration:sec color:[UIColor blackColor] complete:nil];
    }];
}



#pragma mark- DFBlunoDelegate

-(void)bleDidUpdateState:(BOOL)bleSupported
{
    NSLog(@"%s",__FUNCTION__);
    if(bleSupported)
    {
        self.btnSearchNode.hidden=NO;
//        [self.blunoManager scan];
    }
    else
    {
        self.ambientLightNode.hidden=YES;
        self.btnSearchNode.hidden=YES;
    }
}

-(void)didDiscoverDevice:(DFBlunoDevice*)dev
{
    NSLog(@"%s",__FUNCTION__);
    NSLog(@"%@",dev.name);
//    BOOL bRepeat = NO;
//    for (DFBlunoDevice* bleDevice in self.arrayDevices)
//    {
//        if ([bleDevice isEqual:dev])
//        {
//            bRepeat = YES;
//            break;
//        }
//    }
//    if (!bRepeat)
//    {
//        [self.arrayDevices addObject:dev];
//    }
//    [self.tableDevices reloadData];
}

-(void)readyToCommunicate:(DFBlunoDevice*)dev
{
    NSLog(@"%s",__FUNCTION__);

    self.blunoDev = dev;
    self.ambientLightNode.hidden=NO;

}

-(void)didDisconnectDevice:(DFBlunoDevice*)dev
{
    NSLog(@"%s",__FUNCTION__);

    self.ambientLightNode.hidden=YES;

//    self.labelReady.text = @"Not Ready!";
}

-(void)didWriteData:(DFBlunoDevice*)dev
{
    NSLog(@"%s",__FUNCTION__);

}

int alarm_count=0;
char recv_buffer[260];
int last_index=0;
-(void)didReceiveData:(NSData*)data Device:(DFBlunoDevice*)dev
{
//    NSString *strData=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"data is <%@>", strData);    
    char *p=(char *)data.bytes;
    if (last_index+data.length>255)
    {
        NSLog(@"ERROR!!!!!!!!!!!!!!!!!!");
        recv_buffer[last_index]='\r';
        recv_buffer[last_index+1]='\n';
        last_index+=2;
    }
    memcpy(recv_buffer+last_index, p, data.length);
    last_index+=(int)data.length;
    
    if (p[data.length-2]=='\r' && p[data.length-1]=='\n')
    {
        //"short text for float" mode
        //for exmaple, @-1653-0043+1620 means -165.3, -4.3, +162
        if (last_index==18 && recv_buffer[0]=='@')
        {
            char temp[16];
            memcpy(temp, recv_buffer+1, 15);
            temp[15]=0;
            
            NSString *str=[NSString stringWithUTF8String:temp];
            float yaw= [[str substringWithRange:NSMakeRange(0, 5)] floatValue]/10.0;
            float pitch= [[str substringWithRange:NSMakeRange(5, 5)] floatValue]/10.0;
            float roll= [[str substringWithRange:NSMakeRange(10, 5)] floatValue]/10.0;
            
            NSLog(@"update:  Y=%f, P=%f, R=%f,   %@", yaw, pitch, roll, str);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                //YPR相当于绕SceneKit的-y, x, -z
                float rorateX=pitch/180.0*M_PI;
                float rorateY=-(yaw-_angle_offset)/180.0*M_PI;
                float rorateZ=-roll/180.0*M_PI;
                
                SCNMatrix4 dcmYaw=SCNMatrix4MakeRotation(rorateY, 0, 1, 0);
                SCNMatrix4 dcmPitch=SCNMatrix4MakeRotation(rorateX, 1, 0, 0);
                SCNMatrix4 dcmRoll=SCNMatrix4MakeRotation(rorateZ, 0, 0, 1);
                self.mainObjectNode.transform= SCNMatrix4Mult(SCNMatrix4Mult(dcmRoll, dcmPitch),dcmYaw);
                
    //            NSLog(@"rotate=%f,   %f,   %f",
    //                  rorateY/M_PI*180,
    //                  rorateX/M_PI*180,
    //                  rorateZ/M_PI*180);

                _angle_current=yaw;
                
            });
            
        }
        else if (last_index==10 && recv_buffer[0]=='%')  //for lock status
        {
            char temp[8];
            memcpy(temp, recv_buffer+1, 7); //skip first %
            temp[7]=0;
            
            NSString *str=[NSString stringWithUTF8String:temp];
            float angle= [[str substringWithRange:NSMakeRange(0, 5)] floatValue]/10.0;
            int status= [[str substringWithRange:NSMakeRange(6, 1)] intValue];

            NSLog(@"update:  angle=%f,   status=%d,  %@", angle, status, str);

            dispatch_async(dispatch_get_main_queue(), ^{
                self.labelAngle.text=[NSString stringWithFormat:@"%.3f", angle];
                self.labelStatus.text=[NSString stringWithFormat:@"%d", status];
                
                SCNMatrix4 dcmYaw=SCNMatrix4MakeRotation(-angle/180.0*M_PI, 0, 1, 0);
                SCNMatrix4 dcmPitch=SCNMatrix4MakeRotation(M_PI/2, 1, 0, 0);
                self.mainObjectNode.transform= SCNMatrix4Mult(dcmYaw, dcmPitch);
 
                _angle_current=angle;
                if (status<=0)  //lock is open
                {
                    if ([[UIApplication sharedApplication] applicationState]== UIApplicationStateBackground)
                    {
                        AppDelegate *delegate=(AppDelegate *)[UIApplication sharedApplication].delegate;
                        if (delegate.appIconBadgeNumber==0)
                        {
                            //收到数据, 设置推送
                            UILocalNotification *noti = [[UILocalNotification alloc] init];
                            if (noti)
                            {
                                //设置时区
                                noti.timeZone = [NSTimeZone defaultTimeZone];
                                //设置重复间隔
//                                noti.repeatInterval = NSCalendarUnitMinute;
                                //推送声音
                                noti.soundName = UILocalNotificationDefaultSoundName;
                                //内容
                                noti.alertBody = @"DOOR UNLOCKED!";
                                noti.alertAction = @"open the app to check the lock";
                                //显示在icon上的红色圈中的数子
                                delegate.appIconBadgeNumber=delegate.appIconBadgeNumber+1;
                                noti.applicationIconBadgeNumber = delegate.appIconBadgeNumber;
                                //设置userinfo 方便在之后需要撤销的时候使用
    //                            NSDictionary *infoDic = [NSDictionary dictionaryWithObject:@"name" forKey:@"key"];
    //                            noti.userInfo = infoDic;  
                                //添加推送到uiapplication
    //                            UIApplication *app = [UIApplication sharedApplication];  
    //                            [app scheduleLocalNotification:noti];
                                
                                [[UIApplication sharedApplication] presentLocalNotificationNow:noti];
                            }
                        }
                    }
                    
                    [self.mainObjectNode.childNodes.firstObject geometry].firstMaterial.diffuse.contents=[UIColor redColor];
                    [self highlightObject: self.mainObjectNode duration:0.005 needToRecover:YES];
                    
                    alarm_count++;
                    if (alarm_count%20==1)
                        AudioServicesPlaySystemSound(id_alarm);
                }
                else
                {
                    alarm_count=0;
                    
                    if (status==1)
                        [self.mainObjectNode.childNodes.firstObject geometry].firstMaterial.diffuse.contents=[UIColor greenColor];
                    else if (status==2)
                        [self.mainObjectNode.childNodes.firstObject geometry].firstMaterial.diffuse.contents=[UIColor yellowColor];
                    else if (status>=3)
                        [self.mainObjectNode.childNodes.firstObject geometry].firstMaterial.diffuse.contents=[UIColor orangeColor];
                    

                    //                    [self highlightObject: self.mainObjectNode duration:0 needToRecover:YES];
                }
            });

        }
        else
        {
            NSString *strData=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"data is <%@>", strData);
    //        self.labelReceivedMsg.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        }

        last_index=0;   //this line is over
    }
}

-(void)didUpdateDeviceInfo
{
    NSLog(@"didUpdatedDeviceInfo");
}
@end

