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
#import <CoreGraphics/CoreGraphics.h>

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initPages:) name:@"Show Standby" object:nil];

    pages = [[NSMutableArray alloc] init];

    NSArray *pagesArr= [[TiVoDefaults sharedDefaults] getPageSettings];
    int numPages = [[[TiVoDefaults sharedDefaults] getPageSettings] count];
    for (i = 0; i < numPages; i++) {
        RemotePage *pageView = [[RemotePage alloc] initWithFrame:CGRectMake(0, 0, rect.size.width, rect.size.height)];
        [pages addObject:pageView];
    }
    [self initPages:NULL];
    return self;
}

-(void) initPages:(NSNotification *) notification
{
    int i = 0;

    NSArray *pagesArr= [[TiVoDefaults sharedDefaults] getPageSettings];
    NSEnumerator *enumerator = [pagesArr objectEnumerator];
    NSDictionary *pageSettings;
    while (pageSettings = [enumerator nextObject]) {
        RemotePage *pageView = [pages objectAtIndex:i++];

        [pageView loadPage:pageSettings];

    }
/*
        if ([[TiVoDefaults sharedDefaults] showStandby]) {
           TiVoButton *standby = [self createButton:0:0:@"Standby":"STANDBY"];
           [standby setConfirm:YES];
           [pageView addButton:standby];
        }
*/
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

- (NSString *) nextTitle
{
    int nextPage = (page + 1) % [self numPages];
    RemotePage *pageView = [pages objectAtIndex:nextPage];
    return [pageView getTitle];
}

@end
