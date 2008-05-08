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
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>
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
#import "TiVoDefaults.h"
#import "RemotePage.h"

@implementation TiVoRemoteView
- (id)initWithFrame:(struct CGRect)rect
{
    [super initWithFrame:rect];
    int i;
    butWidth = rect.size.width / WIDTH;
    butHeight = rect.size.height / HEIGHT;

    page = 0;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initPages:) name:@"Standby" object:nil];

    pages = [[NSMutableArray alloc] init];
    for (i = 0; i < 2; i++) {
        RemotePage *pageView = [[RemotePage alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)];
        [pages addObject:pageView];
    }
    [self initPages:NULL];
    return self;
}

- (TiVoButton *)createButton:(int) xLoc :(int) yLoc: (NSString *) title: (char *)cmd
{
    TiVoButton *button = [[TiVoButton alloc] initWithTitle: title];
    [button setFrame:  CGRectMake(butWidth * xLoc, butHeight* yLoc,  butWidth, butHeight)];

    [button setCommand: cmd];
    return button;
}

-(void) initPages:(NSNotification *) notification
{
    int i;

    for (i = 0; i < 2; i++) {
        RemotePage *pageView = [pages objectAtIndex:i];
        [pageView clear];

        if ([[TiVoDefaults sharedDefaults] showStandby]) {
           TiVoButton *standby = [self createButton:0:0:@"Standby":"STANDBY"];
           [standby setConfirm:YES];
           [pageView addButton:standby];
        }
        // tivo navigation
        [pageView addButton:[self createButton:2:0:@"/\\":"UP"]];
        [pageView addButton:[self createButton:4:0:@"LiveTV":"LIVETV"]];
        [pageView addButton:[self createButton:1:1:@"<":"LEFT"]];
        [pageView addButton:[self createButton:3:1:@">":"RIGHT"]];
        [pageView addButton:[self createButton:4:1:@"Info":"DISPLAY"]];
        [pageView addButton:[self createButton:0:2:@"Aspect":"WINDOW"]];
        [pageView addButton:[self createButton:2:2:@"\\/":"DOWN"]];
        [pageView addButton:[self createButton:4:2:@"Guide":"GUIDE"]];
        [pageView addButton:[self createButton:0:3:@"ThDn":"THUMBSDOWN"]];
        [pageView addButton:[self createButton:2:3:@"Select":"SELECT"]];
        [pageView addButton:[self createButton:4:3:@"ThUp":"THUMBSUP"]];
    
        if (i == 0) {
            // playback
            [pageView addButton:[self createButton:0:4:@"Rec":"RECORD"]];
            [pageView addButton:[self createButton:2:4:@"|>":"PLAY"]];
            [pageView addButton:[self createButton:4:4:@"Ch+":"CHANNELUP"]];
            [pageView addButton:[self createButton:1:5:@"<<":"REVERSE"]];
            [pageView addButton:[self createButton:2:5:@"||":"PAUSE"]];
            [pageView addButton:[self createButton:3:5:@">>":"FORWARD"]];
            [pageView addButton:[self createButton:4:5:@"Ch-":"CHANNELDOWN"]];
            [pageView addButton:[self createButton:0:6:@"Repl":"REPLAY"]];
            [pageView addButton:[self createButton:2:6:@"| |>":"SLOW"]];
            [pageView addButton:[self createButton:4:6:@"->|":"ADVANCE"]];
            [pageView addButton:[self createButton:0:7:@"Clear":"CLEAR"]];
            [pageView addButton:[self createButton:4:7:@"Enter":"ENTER"]];
        } else if (i == 1) {
            // channel
            [pageView addButton:[self createButton:0:4:@"Rec":"RECORD"]];
            [pageView addButton:[self createButton:1:4:@"1":"NUM1"]];
            [pageView addButton:[self createButton:2:4:@"2":"NUM2"]];
            [pageView addButton:[self createButton:3:4:@"3":"NUM3"]];
            [pageView addButton:[self createButton:4:4:@"Ch+":"CHANNELUP"]];
            [pageView addButton:[self createButton:1:5:@"4":"NUM4"]];
            [pageView addButton:[self createButton:2:5:@"5":"NUM5"]];
            [pageView addButton:[self createButton:3:5:@"6":"NUM6"]];
            [pageView addButton:[self createButton:4:5:@"Ch-":"CHANNELDOWN"]];
            [pageView addButton:[self createButton:1:6:@"7":"NUM7"]];
            [pageView addButton:[self createButton:2:6:@"8":"NUM8"]];
            [pageView addButton:[self createButton:3:6:@"9":"NUM9"]];
            [pageView addButton:[self createButton:4:6:@"->|":"ADVANCE"]];
            [pageView addButton:[self createButton:0:7:@"Clear":"CLEAR"]];
            [pageView addButton:[self createButton:2:7:@"0":"NUM0"]];
            [pageView addButton:[self createButton:4:7:@"Enter":"ENTER"]];
        }
    }
    [self setPage:page];
}


- (void) setPage:(int) newPage
{
    RemotePage *oldPage = [pages objectAtIndex:page];
    [oldPage removeFromSuperview];

    page = newPage;
    RemotePage *newPageView = [pages objectAtIndex:page];
    [self addSubview: newPageView];
}

- (int) numPages
{
    return [pages count];
}

@end
