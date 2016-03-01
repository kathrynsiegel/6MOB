//
//  CompassViewController.m
//  Anteater
//
//  Created by Sam Madden on 1/29/16.
//  Copyright © 2016 Sam Madden. All rights reserved.
//

#import "CompassViewController.h"
#import "AnteaterREST.h"

@interface CompassViewController ()

@end

@implementation CompassViewController {
    NSArray *_anthills;
    CLLocationManager *_mgr;
    UIImage *_image;
    BOOL gotLoc;
    CLLocationCoordinate2D _lastLoc, _userLoc, _targetLoc;
    CGFloat _curHeading, _lastHeading, _scale, _lastMagHeading;
}

- (void)viewDidLoad {
    _mgr = [[CLLocationManager alloc] init];
    _mgr.delegate = self;
    _mgr.desiredAccuracy = kCLLocationAccuracyBest;
    _mgr.distanceFilter = 0;
    _mgr.headingOrientation = CLDeviceOrientationPortrait;
    [_mgr startUpdatingHeading];
    [_mgr startUpdatingLocation];
    _anthills = @[];
    _picker.dataSource = self;
    _picker.delegate = self;
    [AnteaterREST getListOfAnthills:^(NSDictionary *hills) {
        if (hills)
            _anthills = [hills objectForKey:@"anthills"];
        [_picker reloadAllComponents];
        _targetLoc = [self curSelectedLocation];
        [self updateHeading];
    }];
    
    self.distanceLabel.text = @"";
    self.headingLabel.text = @"";

    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//TODO: Implement me
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    _lastHeading = _curHeading;
    _curHeading = newHeading.trueHeading;
    [self updateHeading];
}


//TODO: Implement me
-(void)locationManager:(CLLocationManager*)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations {
    _userLoc = [locations objectAtIndex:0].coordinate;
    [self updateHeading];
}


#pragma  mark - Picker View -

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [_anthills count];
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component __TVOS_PROHIBITED {
    return [[_anthills objectAtIndex:row] objectForKey:@"id"];
}

-(CLLocationCoordinate2D) curSelectedLocation {
    NSDictionary *d = [_anthills objectAtIndex:[_picker selectedRowInComponent:0]];
    CLLocationCoordinate2D hill = CLLocationCoordinate2DMake([[d objectForKey:@"lat"] floatValue] , [[d objectForKey:@"lon"] floatValue]);
    return hill;

}

//TODO: Implement me
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component __TVOS_PROHIBITED
{
    NSDictionary *d = [_anthills objectAtIndex:row];
    _targetLoc = CLLocationCoordinate2DMake([[d objectForKey:@"lat"] floatValue] , [[d objectForKey:@"lon"] floatValue]);
    [self updateHeading];
}

- (void) updateHeading {
    double lon2 = _targetLoc.longitude/180*M_PI;
    double lat2 = _targetLoc.latitude/180*M_PI;
    double lon1 = _userLoc.longitude/180*M_PI;
    double lat1 = _userLoc.latitude/180*M_PI;
    double theta1 = atan2(sin(lon2-lon1)*cos(lat2), cos(lat1)*sin(lat2)-sin(lat1)*cos(lat2)*cos(lon2-lon1));
    double theta2 = _curHeading/180*M_PI;
    double angle = theta1 - theta2;

    CLLocation* userLoc = [[CLLocation alloc] initWithLatitude:_userLoc.latitude longitude:_userLoc.longitude];
//    CLLocationCoordinate2D targetLocCoord = [self curSelectedLocation];
    CLLocation* targetLoc = [[CLLocation alloc] initWithLatitude:_targetLoc.latitude longitude:_targetLoc.longitude];
    double distance = [userLoc distanceFromLocation:targetLoc];
    self.distanceLabel.text = [NSString stringWithFormat:@"%f m", distance];
    self.headingLabel.text = [NSString stringWithFormat:@"%f degrees", angle/M_PI*180];
    [self.needle setTransform:CGAffineTransformMakeRotation(angle)];
}


@end
