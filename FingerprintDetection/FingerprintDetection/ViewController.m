//
//  ViewController.m
//  FingerprintDetection
//
//  Created by Ducere on 08/08/16.
//  Copyright © 2016 Ducere. All rights reserved.
//

#import "ViewController.h"
#import "APIRequestManager.h"
#import "KeychainItemWrapper.h"
#import "ReachabilityNetwork.h"

@import LocalAuthentication;

#define KSERVER_END_POINT  @"http://requestb.in/1kiw3yb1"
#define KFINGERPRINTSTATUS  @"fingerPrintAdded"

@interface ViewController (){
    KeychainItemWrapper *keychainItem;
}
@property (weak, nonatomic) IBOutlet UIButton* fingerPrintRecogntionButton;
-(IBAction)fingerPrintRecogntionButtonTapped:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.title = @"Finger Print Status";
    
    /**
     KeychainItemWrapper initialization
    */
    keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"com.fingerprint.statuscheck14" accessGroup:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appCameToForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    /**
     *  Check whether finger print added in the settings or not
     */
    [self checkSettingsFingerPrintStatus];

}

/**
 *  Called as part of the transition from the background to the inactive state
 *
 */
- (void)appCameToForeground:(NSNotification *)notification {
    
    [self checkSettingsFingerPrintStatus];
}

/**
 *  Open finger print settings on click of UIButton
 *
 */
-(IBAction)fingerPrintRecogntionButtonTapped:(id)sender{
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=TOUCHID_PASSCODE"]];

}


-(void)checkSettingsFingerPrintStatus{
    
    LAContext *context = [[LAContext alloc] init];
    
    [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:nil];
    
    if(![keychainItem objectForKey:(id)kSecAttrService] && (context.evaluatedPolicyDomainState)){
        
        //Save initial domain state in the Keychain
        [keychainItem setObject:context.evaluatedPolicyDomainState forKey:(id)kSecAttrService];
        
        //Finger print is already added in the settings, send this data to server for the first time in app life time
        [self pushFingerPrintStausToServer];
        
    }else{
        
        /**
         *  Check whether 'Initial domain state' and 'Updated domain state' equal or not? If not equal... then new finger print is added to iPhone settings
         *
         */
        if((context.evaluatedPolicyDomainState) && (![context.evaluatedPolicyDomainState isEqualToData:[keychainItem objectForKey:(id)kSecAttrService]])){
            
            //2.New fingerprint added to iPhone settings

            NSLog(@"Finger Print Added/removed");

            [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:KFINGERPRINTSTATUS];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            //Save updated domain state in the Keychain
            [keychainItem setObject:context.evaluatedPolicyDomainState forKey:(id)kSecAttrService];
            
            [self.fingerPrintRecogntionButton setTitle:@"Fingerprint added/removed" forState:UIControlStateNormal];
            
            NSString* randomString = [self getRandomString];
            
            //1.Store random string in keychain
            [self storeRandomStringInKeyChain:randomString];
            
            /**
             *  Push updated time stamp to server
             */
            [self pushFingerPrintStausToServer];
            
        }else if(([[NSUserDefaults standardUserDefaults] integerForKey:KFINGERPRINTSTATUS]) && !context.evaluatedPolicyDomainState){
            
            NSLog(@"All finger Prints Removed");

            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:KFINGERPRINTSTATUS];
            [[NSUserDefaults standardUserDefaults] synchronize];
         
            /**
             *  Push updated time stamp to server
             */
            [self pushFingerPrintStausToServer];

        }
        
    }

}

-(NSString *)getRandomString{
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    NSMutableString *randomString = [NSMutableString stringWithCapacity:10];
    
    for (int i=0; i<10; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform((int)[letters length])]];
    }
    return randomString;
}

-(NSString*)getCurrentTimeStamp{
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"]; //Eg:2016-08-09 08:07:13
    return [dateFormat stringFromDate:[NSDate date]];
    
}

-(void)storeRandomStringInKeyChain:(NSString*)randomString{
    
    // Store string in Keychain
    [keychainItem setObject:(id)randomString forKey:(id)kSecAttrLabel];
}

-(void)pushFingerPrintStausToServer{
    
    if([ReachabilityNetwork isNetworkAvailable]){
        
        //3.Send finger print modified information to server
        NSMutableDictionary* paramsForRequest = [NSMutableDictionary new];
        
        [paramsForRequest setObject:[keychainItem objectForKey:(id)kSecAttrLabel] forKey:@"randomstring"];
        [paramsForRequest setObject:[self getCurrentTimeStamp] forKey:@"newfinger"];
        
        [APIRequestManager PostWithUrl:[NSString stringWithFormat:@"%@",KSERVER_END_POINT] Parameters:paramsForRequest success:^(id json) {
            NSLog(@"Successfully sent finger print data to server");
            
        } failure:^(NSError *error) {
            
            NSLog(@"Failed to send finger print data to server %@",error.description);
        }];
        
    }else{
        NSLog(@"Please check your internet connection");
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
