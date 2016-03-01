//
//  ViewController.m
//  PositionLogger
//
//  Created by Sam Madden on 2/3/16.
//  Copyright © 2016 Sam Madden. All rights reserved.
//

#import "ViewController.h"

#define kDATA_FILE_NAME @"log.csv"

@interface ViewController ()
@end

@implementation ViewController {
    CLLocationManager *_locmgr;
    BOOL _isRecording;
    NSFileHandle *_f;
    UIAlertController *_alert;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //location manager setup
    _locmgr = [[CLLocationManager alloc] init];
    [_locmgr requestAlwaysAuthorization];
    _locmgr.delegate = self;
    _locmgr.distanceFilter = kCLHeadingFilterNone;
    _locmgr.allowsBackgroundLocationUpdates = TRUE;
    [_locmgr disallowDeferredLocationUpdates];
    
    //battery logging setup
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:TRUE];
    //UI setup
    self.recordingIndicator.hidesWhenStopped = TRUE;
    self.startStopButton.layer.borderWidth = 1.0;
    self.startStopButton.layer.cornerRadius = 5.0;
    _f  = [self openFileForWriting];
    if (!_f)
        NSAssert(_f,@"Couldn't open file for writing.");
    [self logLineToDataFile:@"Time,Lat,Lon,Altitude,Accuracy,Heading,Speed,Battery\n"];
    // Do any additional setup after loading the view, typically from a nib.
}

-(NSString *)getPathToLogFile {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:kDATA_FILE_NAME];
    return filePath;
}


-(NSFileHandle *)openFileForWriting {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSFileHandle *f;
    [fileManager createFileAtPath:[self getPathToLogFile] contents:nil attributes:nil];
    f = [NSFileHandle fileHandleForWritingAtPath:[self getPathToLogFile]];
    return f;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)logLineToDataFile:(NSString *)line {
    [_f writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void)resetLogFile {
    [_f closeFile];
    _f = [self openFileForWriting];
    if (!_f)
        NSAssert(_f,@"Couldn't open file for writing.");
}

//TODO: Implement me
-(void)startRecordingLocationWithAccuracy:(LocationAccuracy)acc {
    if (acc == GPS) {
        [_locmgr setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
    } else if (acc == WiFi) {
        [_locmgr setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
    } else {
        [_locmgr setDesiredAccuracy:kCLLocationAccuracyKilometer];
    }
    [_locmgr startUpdatingLocation];
}

//TODO: Implement me
-(void)stopRecordingLocationWithAccuracy {
    [_locmgr stopUpdatingLocation];
}

-(IBAction)hitRecordStopButton:(UIButton *)b {
    if (!_isRecording) {
        [self.accuracyControl setEnabled:FALSE];
        [b setTitle:@"Stop" forState:UIControlStateNormal];
        _isRecording = TRUE;
        [self.recordingIndicator startAnimating];
        [self startRecordingLocationWithAccuracy:(LocationAccuracy)[self.accuracyControl selectedSegmentIndex]];
    } else {
        [self.accuracyControl setEnabled:TRUE];
        [b setTitle:@"Start" forState:UIControlStateNormal];
        _isRecording = FALSE;
        [self.recordingIndicator stopAnimating];
        [self stopRecordingLocationWithAccuracy];

    }
}

-(IBAction)hitClearButton:(UIButton *)b {
    [self resetLogFile];
}

-(IBAction)emailLogFile:(UIButton *)b {
    
    if (![MFMailComposeViewController canSendMail]) {
//        [appDelegate cycleGlobalMailComposer];
        _alert = [UIAlertController alertControllerWithTitle:@"Can't send mail" message:@"Please set up an email account on this phone to send mail" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action)
                             {
                                 [self dismissViewControllerAnimated:YES completion:nil];
                             }];
        [_alert addAction:ok]; // add action to uialertcontroller
        [self presentViewController:_alert animated:YES completion:nil];
        return;
    }
    NSData *fileData = [NSData dataWithContentsOfFile:[self getPathToLogFile]];

    if (!fileData || [fileData length] == 0)
        return;
    NSString *emailTitle = @"Position File";
    NSString *messageBody = @"Data from PositionLogger";

//    [appDelegate.mc setToRecipients: @[@"ksiegel@mit.edu"] ];
//    [appDelegate.mc setSubject: emailTitle];
//    [appDelegate.mc setMessageBody:messageBody isHTML:NO];
//    appDelegate.mc.mailComposeDelegate = self;
//    [self presentViewController:appDelegate.mc animated:YES completion:nil];
    
    MFMailComposeViewController* mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setMessageBody:messageBody isHTML:NO];
    
    // Determine the MIME type
    NSString *mimeType = @"text/plain";
    
    // Add attachment
//    [appDelegate.mc addAttachmentData:fileData mimeType:mimeType fileName:kDATA_FILE_NAME];
    [mc addAttachmentData:fileData mimeType:mimeType fileName:kDATA_FILE_NAME];
    
    // Present mail view controller on screen
//    [self presentViewController:appDelegate.mc animated:YES completion:NULL];
    [self presentViewController:mc animated:YES completion:NULL];
    
}

#pragma mark - CLLocationManagerDelegate Methods -

//TODO: Implement me
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    for (int i = 0; i < locations.count; i++) {
        CLLocation *currLoc = [locations objectAtIndex:i];
        NSString *logString = [NSString stringWithFormat: @"%@,%f,%f,%f,%f,%f,%f,%f\n",
                              currLoc.timestamp,
                              currLoc.coordinate.latitude,
                              currLoc.coordinate.longitude,
                              currLoc.altitude,
                              currLoc.horizontalAccuracy,
                              currLoc.course,
                              currLoc.speed,
                              [[UIDevice currentDevice] batteryLevel]];
        [self logLineToDataFile: logString];
    }
}


#pragma mark - MFMailComposeViewControllerDelegate Methods -

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
        
    }
//    [appDelegate cycleGlobalMailComposer];
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];

}


@end
