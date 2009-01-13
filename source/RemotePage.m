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

#import "RemotePage.h"
#import "TiVoDefaults.h"
#import "TiVoButton.h"

@implementation RemotePage

- (id)initWithFrame:(struct CGRect)rect
{
    [super initWithFrame:rect];
    buttons = [[NSMutableArray alloc] init];
    title = @"";
    background = [[UIImageView alloc] 
        initWithFrame:rect];
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    float backParts[4] = {0, 0, 0, 1};
//    [background  setBackgroundColor:CGColorCreate( colorSpace, backParts)];
//2.0
    [background  setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
    [self addSubview:background];
    return self;
}

-(void) loadPage:(NSDictionary *)pageSettings
{
    // title
    title = [pageSettings objectForKey:@"title"];

    NSEnumerator *enumerator = [buttons objectEnumerator];
    TiVoButton *button;
    while (button = [enumerator nextObject]) {
        [button removeFromSuperview];
        [button release];
    }
    [buttons removeAllObjects];

    // setbackground
    NSString *bgImage = [pageSettings objectForKey:@"background"];
    if (bgImage != NULL) {
        [background setImage:[UIImage applicationImageNamed:bgImage]];
    }

    // load sections
    enumerator = [[pageSettings objectForKey:@"sections"] objectEnumerator];
    NSString *sectionName;
    while (sectionName = [enumerator nextObject]) {
        [self loadSection:sectionName];
    }
}

- (void)loadSection:(NSString *)section
{
    NSDictionary *sectionSettings = [[TiVoDefaults sharedDefaults] getSectionSettings:section];
    NSArray *buttonArr = [sectionSettings objectForKey:@"buttons"];
    NSEnumerator *enumerator = [buttonArr objectEnumerator];
    NSDictionary *buttonSettings;
    while (buttonSettings = [enumerator nextObject]) {
        if ([@"Show Standby" compare:[buttonSettings objectForKey:@"tag"]] == 0) {
            if (![[TiVoDefaults sharedDefaults] showStandby]) {
                continue;
            }
        }
        TiVoButton *button = [[TiVoButton alloc] initButton:buttonSettings];
        [self addButton:button];
    }
}

-(void) addButton:(TiVoButton *) button
{
    [self addSubview:button];
    [buttons addObject:button];
}

-(NSString *) getTitle
{
    return title;
}

@end
