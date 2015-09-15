//
//  DFBlunoManager.m
//
//  Created by Seifer on 13-12-1.
//  Copyright (c) 2013年 DFRobot. All rights reserved.
//

#import "DFBlunoManager.h"

#define kBlunoService @"dfb0"
#define kBlunoDataCharacteristic @"dfb1"

@interface DFBlunoManager ()
{
    BOOL _bSupported;
}

@property (strong,nonatomic) CBCentralManager* centralManager;
@property (strong,nonatomic,readwrite) NSMutableDictionary* dictBleDevices;
@property (strong,nonatomic,readwrite) NSMutableDictionary* dictBlunoDevices;
@property (nonatomic, strong, readwrite) NSArray *arrayBlunoDevices;

@end

@implementation DFBlunoManager
{
    dispatch_queue_t _serialQueueForData;
}

#pragma mark- Functions

-(NSArray *)arrayBleDevices
{
    return [self.dictBleDevices allValues];
}

-(NSArray *)arrayBlunoDevices
{
    __block NSArray *array;
    dispatch_sync(_serialQueueForData, ^{ array=[self.dictBlunoDevices allValues];});
    return array;
}


+ (DFBlunoManager *)sharedInstance
{
    static DFBlunoManager *sharedDFBlunoManagerInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedDFBlunoManagerInstance = [[self alloc] initSingleTon];
    });
    return sharedDFBlunoManagerInstance;
}


-(id)initSingleTon
{
    if (self=[super init])
    {
        self.dictBleDevices = [[NSMutableDictionary alloc] init];
        self.dictBlunoDevices = [[NSMutableDictionary alloc] init];
        _bSupported=NO;
        self.centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:nil];
        _serialQueueForData = dispatch_queue_create("serialQueueForUpdateDeviceList", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)configureSensorTag:(CBPeripheral*)peripheral
{
    
    CBUUID *sUUID = [CBUUID UUIDWithString:kBlunoService];
    CBUUID *cUUID = [CBUUID UUIDWithString:kBlunoDataCharacteristic];
    
    [BLEUtility setNotificationForCharacteristic:peripheral sCBUUID:sUUID cCBUUID:cUUID enable:YES];
    NSString* key = [peripheral.identifier UUIDString];
    
    __block DFBlunoDevice* blunoDev;
    dispatch_sync(_serialQueueForData, ^{
        blunoDev = [self.dictBlunoDevices objectForKey:key];
    });

    blunoDev->_bReadyToWrite = YES;
    if ([((NSObject*)_delegate) respondsToSelector:@selector(readyToCommunicate:)])
    {
        [_delegate readyToCommunicate:blunoDev];
    }
    
}

- (void)deConfigureSensorTag:(CBPeripheral*)peripheral
{
    
    CBUUID *sUUID = [CBUUID UUIDWithString:kBlunoService];
    CBUUID *cUUID = [CBUUID UUIDWithString:kBlunoDataCharacteristic];
    
    [BLEUtility setNotificationForCharacteristic:peripheral sCBUUID:sUUID cCBUUID:cUUID enable:NO];
    
}

- (void)scan
{
    [self.centralManager stopScan];
    [self clearDevicesInfo];
    if (_bSupported)
    {
        [self.centralManager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:kBlunoService]] options:nil];
    }

}

- (void)stop
{
    [self.centralManager stopScan];
}

- (void)clearDevicesInfo
{
    dispatch_sync(_serialQueueForData, ^{
        [self.dictBleDevices removeAllObjects];
        [self.dictBlunoDevices removeAllObjects];
    });
}

- (void)connectToDevice:(DFBlunoDevice*)dev
{
    BLEDevice* bleDev = [self.dictBleDevices objectForKey:dev.identifier];
    [bleDev.centralManager connectPeripheral:bleDev.peripheral options:nil];
}

- (void)disconnectToDevice:(DFBlunoDevice*)dev
{
    BLEDevice* bleDev = [self.dictBleDevices objectForKey:dev.identifier];
    [self deConfigureSensorTag:bleDev.peripheral];
    [bleDev.centralManager cancelPeripheralConnection:bleDev.peripheral];
}

- (void)writeDataToDevice:(NSData*)data Device:(DFBlunoDevice*)dev
{
    if (!_bSupported || data == nil)
    {
        return;
    }
    else if(!dev.bReadyToWrite)
    {
        return;
    }
    BLEDevice* bleDev = [self.dictBleDevices objectForKey:dev.identifier];
    [BLEUtility writeCharacteristic:bleDev.peripheral sUUID:kBlunoService cUUID:kBlunoDataCharacteristic data:data];
}

#pragma mark - CBCentralManager delegate

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn)
    {
        _bSupported = NO;
        dispatch_sync(_serialQueueForData, ^{
            NSArray* aryDeviceKeys = [self.dictBlunoDevices allKeys];
            for (NSString* strKey in aryDeviceKeys)
            {
                DFBlunoDevice* blunoDev = [self.dictBlunoDevices objectForKey:strKey];
                blunoDev->_bReadyToWrite = NO;
            }
        });
    }
    else
    {
        _bSupported = YES;
        
    }
    
    if ([((NSObject*)_delegate) respondsToSelector:@selector(bleDidUpdateState:)])
    {
        [_delegate bleDidUpdateState:_bSupported];
    }
    
}

-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString* key = [peripheral.identifier UUIDString];

    __block BLEDevice* dev;
    dispatch_sync(_serialQueueForData, ^{dev = [self.dictBleDevices objectForKey:key];});
    
    if (dev !=nil )
    {
        dev.peripheral = peripheral;
        if ([((NSObject*)_delegate) respondsToSelector:@selector(didUpdateDeviceInfo:)])
        {
            __block DFBlunoDevice* blunoDev;
            dispatch_sync(_serialQueueForData, ^{
                blunoDev = [self.dictBlunoDevices objectForKey:key];
            });
            
            [_delegate didUpdateDeviceInfo];
//            [_delegate didDiscoverDevice:blunoDev];
            
        }
    }
    else
    {
        __block DFBlunoDevice* blunoDev = [[DFBlunoDevice alloc] init];

        dispatch_sync(_serialQueueForData, ^{
            BLEDevice* bleDev = [[BLEDevice alloc] init];
            bleDev.peripheral = peripheral;
            bleDev.centralManager = self.centralManager;
            [self.dictBleDevices setObject:bleDev forKey:key];
            
            blunoDev.identifier = key;
            blunoDev.name = peripheral.name;
            [self.dictBlunoDevices setObject:blunoDev forKey:key];
        });
        
        if ([((NSObject*)_delegate) respondsToSelector:@selector(didUpdateDeviceInfo)])
        {
            [_delegate didUpdateDeviceInfo];
//            [_delegate didDiscoverDevice:blunoDev];
        }
    }
}


-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSString* key = [peripheral.identifier UUIDString];
    
    __block DFBlunoDevice* blunoDev;
    dispatch_sync(_serialQueueForData, ^{blunoDev = [self.dictBlunoDevices objectForKey:key];});
    
    blunoDev->_bReadyToWrite = NO;
    if ([((NSObject*)_delegate) respondsToSelector:@selector(didDisconnectDevice)])
    {
        [_delegate didDisconnectDevice:blunoDev];
    }
}

#pragma  mark - CBPeripheral delegate
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *s in peripheral.services)
        [peripheral discoverCharacteristics:nil forService:s];
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:kBlunoService]])
    {
        [self configureSensorTag:peripheral];
    }

}


-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    if ([((NSObject*)_delegate) respondsToSelector:@selector(didReceiveData:Device:)])
    {
        NSString* key = [peripheral.identifier UUIDString];
        
        __block DFBlunoDevice* blunoDev;
        dispatch_sync(_serialQueueForData, ^{blunoDev = [self.dictBlunoDevices objectForKey:key];});
        [_delegate didReceiveData:characteristic.value Device:blunoDev];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([((NSObject*)_delegate) respondsToSelector:@selector(didWriteData:)])
    {
        NSString* key = [peripheral.identifier UUIDString];
        __block DFBlunoDevice* blunoDev;
        dispatch_sync(_serialQueueForData, ^{blunoDev = [self.dictBlunoDevices objectForKey:key];});
        
        [_delegate didWriteData:blunoDev];
    }
    
}

@end
