//
//  BLEMananger.m
//  Anteater
//
//  Created by Sam Madden on 1/13/16.
//  Copyright © 2016 Sam Madden. All rights reserved.
//

#import "SensorModel.h"
#import "AnteaterREST.h"
#import "SettingsModel.h"

@interface SensorModel ()
@property (atomic, readwrite) NSMutableArray *sensorReadings;
@end

static id _instance;
@implementation SensorModel {
    CBCentralManager* CM;
    bool shouldScan;
    CBPeripheral* currAnthill;
    NSString* currString;
}

-(id) init {
    self = [super init];
    if (self) {
        CM = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        shouldScan = false;
        currString = @"";
        _sensorReadings = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"centralManagerDidUpdateState");
    if (CM.state == CBCentralManagerStatePoweredOn && shouldScan) {
        [self scan];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,
                        id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    NSLog(@"Did discover peripheral");
    currAnthill = peripheral;
    peripheral.delegate = self;
    [CM connectPeripheral:peripheral
                options:[NSDictionary
                dictionaryWithObject:[NSNumber numberWithBool:YES]
                forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
}

- (void)centralManager:(CBCentralManager *)central
  didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Did connect peripheral");
    [self.delegate bleDidConnect];
    [peripheral discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error {
    NSLog(@"Did disconnect peripheral");
    currAnthill = nil;
    [self.delegate bleDidDisconnect];
    currString = @"";
    if (shouldScan) {
        [self scan];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error {
    for (CBService *s in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:s];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error {
    if ([[[service UUID] UUIDString] isEqualToString:@RBL_SERVICE_UUID]) {
        for (CBCharacteristic *c in service.characteristics) {
            currString = @"";
            if ([[[c UUID] UUIDString] isEqualToString:@RBL_CHAR_TX_UUID]) {
                [peripheral setNotifyValue:YES forCharacteristic:c];
            }
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    unsigned char data[20];
    unsigned long data_len = MIN(20,characteristic.value.length);
    [characteristic.value getBytes:data length:data_len];
    unsigned long length = strlen(data);
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    currString = [NSString stringWithFormat:@"%@%@", currString, s];
    [self updateReadingsTableForPeripheral: peripheral];
}

- (void)updateReadingsTableForPeripheral:(CBPeripheral*)peripheral {
    NSString* firstChar;
    NSRange endMarker = [currString rangeOfString:@"D"];
    while (endMarker.location != NSNotFound) {
        firstChar = [currString substringToIndex:1];
        if (!([firstChar isEqualToString:@"T"] ||
               [firstChar isEqualToString:@"H"] ||
              [firstChar isEqualToString:@"E"] )) {
            currString = [currString substringFromIndex:1];
            endMarker = [currString rangeOfString:@"D"];
        } else {
            if ([firstChar isEqualToString:@"E"]) {
                NSLog(@"Anthill reports error");
            } else {
                SensorReadingType readingType;
                if ([firstChar isEqualToString:@"T"]) {
                    readingType = kTemperatureReading;
                } else {
                    readingType = kHumidityReading;
                }
                float readingValue = [currString substringWithRange:
                                      NSMakeRange(1, endMarker.location-1)].floatValue;
                NSLog([NSString stringWithFormat:@"reading value: %f", readingValue]);
                BLESensorReading* reading = [[BLESensorReading alloc] initWithReadingValue:readingValue andType:readingType atTime:[NSDate date] andSensorId:peripheral.name];
                _sensorReadings = [_sensorReadings arrayByAddingObject: reading];
                [self.delegate bleGotSensorReading:reading];
                [AnteaterREST postListOfSensorReadings:@[reading] andCallCallback:NULL];
            }
            currString = [currString substringFromIndex:endMarker.location+endMarker.length];
            endMarker = [currString rangeOfString:@"D"];
        }
    }
}

-(void)scan {
    NSLog(@"scanning");
    [CM scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@RBL_SERVICE_UUID]] options:nil];
}

-(void)startScanning {
    shouldScan = true;
    [self scan];
}

-(void)stopScanning {
    shouldScan = false;
    [CM stopScan];
}

-(BOOL)isConnected {
    return currAnthill != nil;
}

-(NSString *)currentSensorId {
    return currAnthill.name;
}



+(SensorModel *) instance {
    if (!_instance) {
        _instance = [[SensorModel alloc] init];
    }
    return _instance;
}


@end
