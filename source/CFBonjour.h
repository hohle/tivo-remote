//
//  CFBonjour.h
//  murmur
//
//  Created by ecume des jours on 10/28/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>


@interface CFBonjour : NSObject {

		 CFNetServiceRef netService;
}

-(void)CFBonjourPublishWithService:(NSString*)newServiceType machineID:(NSString*)userName onPort:(int)port;
-(void)CFBonjourStopCurrentService;
-(void)CFBonjourStartBrowsingForServices:(NSString*)serviceType inDomain:(NSString*)domain;
-(NSMutableArray*)CFBonjourClientsArray;
-(void)countClientsArray;

@end
