/* ------ TiVoRemoteApp
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; version 2
   of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIWindow.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UITextView.h>
#import <UIKit/UIView.h>
#import <UIKit/UIKeyboard.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UINavigationItem.h>
#import <UIKit/UINavBarButton.h>
#import <UIKit/UIFontChooser.h>
#import <UIKit/UIProgressHUD.h>

#import "TiVoRemoteApp.h"
#import "TiVoRemoteView.h"
#import "TiVoPreferencesView.h"
#import "TiVoNowPlayingView.h"
#import "TiVoButton.h"
#import "TiVoDefaults.h"
#import "TiVoBeacon.h"
#import "TiVoNPLConnection.h"

#include <stdio.h>

@implementation TiVoRemoteApp
- (void) applicationDidFinishLaunching: (id) unused
{
    UIWindow *window;
    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
    rect.origin.x = rect.origin.y = 0.0f;

    window = [[UIWindow alloc] initWithContentRect: rect];
    mainView = [[UIView alloc] initWithFrame: rect];

    struct CGRect navRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48);
    navBar = [[UINavigationBar alloc] initWithFrame: navRect];
    [navBar setBarStyle:5];
    [navBar setDelegate:self];
    [window orderFront: self];
    [window makeKey: self];
    [window _setHidden: NO];
    [window setContentView: mainView];
    [mainView addSubview:navBar];
    [TiVoBeacon getInstance];
    [TiVoNPLConnection getInstance];

    page = 0;
    @try {
        remoteView = [[TiVoRemoteView alloc] initWithFrame:
          CGRectMake(0, 48, rect.size.width, rect.size.height - 48)];
        [remoteView setPage:page];

        NSDictionary *buttonDict = [[[[TiVoDefaults sharedDefaults] 
                  getPageSettings] objectAtIndex:0] objectForKey:@"button"];
        TiVoButton *navButton = [[TiVoButton alloc] initButton:buttonDict];
        [self setNavBarButtons];
        [navBar addSubview:navButton];

        [mainView addSubview:remoteView];
    } @catch (id) {
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingUpdate:) name:@"Now Playing Data" object:nil];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
    switch(button) {
    case 0: // settings
    {
        struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
        TiVoPreferencesView *newView;
        if ([[TiVoNPLConnection getInstance] getState] != NPL_ERROR) {
            TiVoNowPlayingView *newView= [[TiVoNowPlayingView alloc] initWithFrame:
                   CGRectMake(0, 0, rect.size.width, rect.size.height)];
            [mainView addSubview:newView];
        } else {
            TiVoPreferencesView *newView= [[TiVoPreferencesView alloc] initWithFrame:
                   CGRectMake(0, 0, rect.size.width, rect.size.height)];
            [mainView addSubview:newView];
        }

        break;
    }
    case 1: // page
    {
       page = (page + 1) % [remoteView numPages];
       [remoteView setPage:page];
       [self setNavBarButtons];
       break;
     }
     }
}

-(void) nowPlayingUpdate:(NSNotification *) notification
{
    [self setNavBarButtons];
}

- (void) setNavBarButtons
{
    NSLog(@"nav buttons");
    NSString *nextTitle = [remoteView nextTitle];
    NSString *rightButton = (([[TiVoNPLConnection getInstance] getState] != NPL_ERROR)
                                  ? @"Now Playing" : @"Settings");
    [navBar showButtonsWithLeftTitle:nextTitle rightTitle:rightButton];
}

- (void) applicationWillSuspend {
    [[ConnectionManager getInstance] close];
}   
@end
