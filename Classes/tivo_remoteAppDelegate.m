//
//  tivo_remoteAppDelegate.m
//  tivo-remote
//
//  Created by Jonathan Hohle on 1/2/09.
//  Copyright Jonathan Hohle, jonhohle@gmail.com 2009. All rights reserved.
//

#import "tivo_remoteAppDelegate.h"
#import "RootViewController.h"

@implementation tivo_remoteAppDelegate


@synthesize window;
@synthesize rootViewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    [window addSubview:[rootViewController view]];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [rootViewController release];
    [window release];
    [super dealloc];
}

@end
