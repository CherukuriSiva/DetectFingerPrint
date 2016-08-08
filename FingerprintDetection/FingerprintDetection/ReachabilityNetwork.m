//
//  Reachability.m
//  Lechal
//
//  Created by Alimi shalini on 16/06/16.
//  Copyright © 2016 Ducere. All rights reserved.
//

#import "ReachabilityNetwork.h"
#import <SystemConfiguration/SCNetworkReachability.h>

@implementation ReachabilityNetwork
+(bool)isNetworkAvailable
{
    SCNetworkReachabilityFlags flags;
    SCNetworkReachabilityRef address;
    address = SCNetworkReachabilityCreateWithName(NULL,"www.google.com" );
    Boolean success = SCNetworkReachabilityGetFlags(address, &flags);
    CFRelease(address);
    
    bool canReach = success
    && !(flags & kSCNetworkReachabilityFlagsConnectionRequired)
    && (flags & kSCNetworkReachabilityFlagsReachable);
    
    return canReach;
}
@end
