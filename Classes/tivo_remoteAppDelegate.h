//
//  tivo_remoteAppDelegate.h
//  tivo-remote
//
//  Created by Jonathan Hohle on 1/2/09.
//  Copyright Jonathan Hohle, jonhohle@gmail.com 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface tivo_remoteAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    RootViewController *rootViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;

@end

