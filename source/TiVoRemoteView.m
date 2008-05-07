/* TiVoRemoteView

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
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIView.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIViewTapInfo.h>
#import <UIKit/UIView-Geometry.h>

#import "TiVoRemoteView.h"
#import "TiVoButton.h"

@implementation TiVoRemoteView
- (id)initWithFrame:(struct CGRect)rect
{
    [super initWithFrame:rect];
    connection = NULL;
    butWidth = rect.size.width / WIDTH;
    butHeight = rect.size.height / HEIGHT;

    connection = [[TiVoConnection alloc] init];
    buttons = [[NSMutableArray alloc] init];

    return self;
}

- (void)addButton:(int) xLoc :(int) yLoc: (NSString *) title: (char *)cmd
{
    float yOffs = 0.0;
    TiVoButton *button = [[TiVoButton alloc] initWithTitle: title];
    [button setFrame:  CGRectMake(butWidth * xLoc, butHeight* yLoc + yOffs,  butWidth, butHeight)];

    [button addTarget: self action:@selector(buttonEvent:) forEvents:1];
    [button setCommand: cmd];
    [self addSubview:button];
    [buttons addObject: button];
}


- (void) setPage:(int) newPage
{
    page = newPage;
    TiVoButton *button;
    NSEnumerator *enumerator = [buttons objectEnumerator];
    while ( button = [enumerator nextObject]) {
        [button removeFromSuperview];
        [button release];
    }
    [buttons removeAllObjects];


    // tivo navigation
    [self addButton:2:0:@"/\\":"UP"];
    [self addButton:4:0:@"LiveTV":"LIVETV"];
    [self addButton:1:1:@"<":"LEFT"];
    [self addButton:3:1:@">":"RIGHT"];
    [self addButton:4:1:@"Info":"DISPLAY"];
    [self addButton:0:2:@"Aspect":"WINDOW"];
    [self addButton:2:2:@"\\/":"DOWN"];
    [self addButton:4:2:@"Guide":"GUIDE"];
    [self addButton:0:3:@"ThDn":"THUMBSDOWN"];
    [self addButton:2:3:@"Select":"SELECT"];
    [self addButton:4:3:@"ThUp":"THUMBSUP"];

    if (page == 0) {
        // playback
        [self addButton:0:4:@"Rec":"RECORD"];
        [self addButton:2:4:@"|>":"PLAY"];
        [self addButton:4:4:@"Ch+":"CHANNELUP"];
        [self addButton:1:5:@"<<":"REVERSE"];
        [self addButton:2:5:@"||":"PAUSE"];
        [self addButton:3:5:@">>":"FORWARD"];
        [self addButton:4:5:@"Ch-":"CHANNELDOWN"];
        [self addButton:0:6:@"Repl":"REPLAY"];
        [self addButton:2:6:@"| |>":"SLOW"];
        [self addButton:4:6:@"->|":"ADVANCE"];
        [self addButton:0:7:@"Clear":"CLEAR"];
        [self addButton:4:7:@"Enter":"ENTER"];
    } else if (page == 1) {
        // channel
        [self addButton:0:4:@"Rec":"RECORD"];
        [self addButton:1:4:@"1":"NUM1"];
        [self addButton:2:4:@"2":"NUM2"];
        [self addButton:3:4:@"3":"NUM3"];
        [self addButton:4:4:@"Ch+":"CHANNELUP"];
        [self addButton:1:5:@"4":"NUM4"];
        [self addButton:2:5:@"5":"NUM5"];
        [self addButton:3:5:@"6":"NUM6"];
        [self addButton:4:5:@"Ch-":"CHANNELDOWN"];
        [self addButton:1:6:@"7":"NUM7"];
        [self addButton:2:6:@"8":"NUM8"];
        [self addButton:3:6:@"9":"NUM9"];
        [self addButton:4:6:@"->|":"ADVANCE"];
        [self addButton:0:7:@"Clear":"CLEAR"];
        [self addButton:2:7:@"0":"NUM0"];
        [self addButton:4:7:@"Enter":"ENTER"];
    }
}
- (void)showAlert:(NSString *) alert
{
    NSString *bodyText = [NSString stringWithFormat:alert];
    CGRect rect = [[UIWindow keyWindow] bounds];
    alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
    [alertSheet setTitle:@"Alert!"];
    [alertSheet setBodyText:bodyText];
    [alertSheet addButtonWithTitle:@"OK"];
    [alertSheet setDelegate: self];
    [alertSheet popupAlertAnimated:YES];
}

- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int) button
{
    [sheet dismissAnimated:YES];
}


- (void) buttonEvent:(UIPushButton *) button
{
    char *command = [(TiVoButton *) button getCommand];
    if (command != NULL && connection != NULL) {
        @try {
            [connection sendCommand:command];
        } @catch (NSString *alert) {
            [self showAlert:alert];
        }
    }
}

- (void)close
{
    if (connection != NULL) {
        [connection close];
     }
}
@end
