/* TiVoNowPlayingView

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
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UITable.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UITableColumn.h>

#import "TiVoDefaults.h"
#import "TiVoNowPlayingView.h"
#import "TiVoPreferencesView.h"
#import "ConnectionManager.h"
#import "SimpleDialog.h"
#import "TiVoNPLConnection.h"
#import "TiVoContainerItem.h"

@implementation TiVoNowPlayingView

- (id)initWithFrame:(struct CGRect)rect
{
    [super initWithFrame:rect];

    struct CGRect navRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48);
    navBar = [[UINavigationBar alloc] initWithFrame: navRect];
    [navBar showButtonsWithLeftTitle:@"Remote" rightTitle:@"Settings" leftBack:YES];
    [navBar setBarStyle:5];
    [navBar setDelegate:self];

    navItem = [[UINavigationItem alloc] initWithTitle:@"Now Playing"];
    [navBar pushNavigationItem:navItem];

    struct CGRect bottomNavRect = CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - 48, rect.size.width, 48);
    bottomNavBar = [[UINavigationBar alloc] initWithFrame: bottomNavRect];
    [bottomNavBar showButtonsWithLeftTitle:@"Back" rightTitle:@"Refresh" leftBack:YES];
    [bottomNavBar setBarStyle:5];
    [bottomNavBar setDelegate:self];
    [bottomNavBar setButton:1 enabled:NO];
    [bottomNavBar setButton:0 enabled:NO];

    struct CGRect bodyRect = CGRectMake(rect.origin.x, rect.origin.y + 48, rect.size.width, rect.size.height - 2 * 48);

    nowPlayingTable = [[UITable alloc] initWithFrame:bodyRect];
    [nowPlayingTable setDataSource:self];
    [nowPlayingTable setDelegate:self];
    [nowPlayingTable setSeparatorStyle:1];

    detailView = [[UITextView alloc] initWithFrame:bodyRect];

    float progX = (rect.origin.x + 10);
    float progY = (rect.origin.y + 100);
    struct CGRect progRect = CGRectMake(progX, progY, rect.size.width - progX - 10, 150);
    progress = [[UIProgressHUD alloc] initWithFrame:progRect];
    [progress setText:@"Loading Now Playing Data"];
    [progress show:YES];

    col = [[UITableColumn alloc] initWithTitle:@"Now Playing" identifier:@"nowplaying" width:320];
    [nowPlayingTable addTableColumn:col];

    cells = NULL;
    [self refresh:NULL];

    [self addSubview:navBar];
    [self addSubview:bottomNavBar];
    [self addSubview:nowPlayingTable];
    [self addSubview:progress];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(makChange:) name:@"Media Access Key" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:@"Now Playing Data" object:nil];

    return self;
}

-(void)makChange:(NSNotification *)notification
{
    if ([[[TiVoDefaults sharedDefaults] getMediaAccessKey] length] == 0) {
        [self removeFromSuperview];
        [self release];
    }
}

- (void)tableRowSelected:(NSNotification *)notification
{
    int row = [nowPlayingTable selectedRow];
    TiVoContainerItemTableCell *cell = [cells objectAtIndex:row];
    [cell setSelected:NO withFade:NO];
    [[[notification object]cellAtRow:[[notification object]selectedRow]column:0] setSelected:FALSE withFade:FALSE];
    if ([[cell getValue] isKindOfClass:[TiVoContainerItem class]]) {
        TiVoContainerItem *item = [cell getValue];
        NSArray *commands = [item getCommands];
        id<RemoteConnection> conn = [[ConnectionManager getInstance] getConnection:@"TiVo"];
        int i;
        for (i = 0; i < [commands count]; i++) {
            int sleepTime = [[commands objectAtIndex:i] intValue];
            if (sleepTime > 0) {
                usleep(1000 * sleepTime);
            } else {
                NSDictionary *function = [[TiVoDefaults sharedDefaults] getFunctionSettings:[commands objectAtIndex:i]];
                [conn sendCommand:[[function objectForKey:@"command"] UTF8String]];
            }
        }
        NSDictionary *function = [[TiVoDefaults sharedDefaults] getFunctionSettings:@"TiVo Play"];
        [conn sendCommand:[[function objectForKey:@"command"] UTF8String]];
        [[[notification object]cellAtRow:[[notification object]selectedRow]column:0] setSelected:FALSE withFade:TRUE];
    } else {
        [navItem setTitle:[cell title]];
        [bottomNavBar setButton:1 enabled:YES];
        cells = [cell getValue];
        [nowPlayingTable reloadData];
        [[[notification object]cellAtRow:[[notification object]selectedRow]column:0] setSelected:FALSE withFade:FALSE];
    }
}

- (void) table:(UITable *) table deleteRow:(int) row 
{
}

- (BOOL) table:(UITable *) table canDeleteRow:(int) row 
{
    return NO;
}

- (void) refresh:(id) param
{
    if ([[TiVoNPLConnection getInstance] getState] == NPL_ERROR) {
        [self release];
    }
    int i;
    for (i = 0; i < [cells count]; i++) {
        [[cells objectAtIndex:i] release];
    }
    [cells removeAllObjects];

    NSArray *items = [[TiVoNPLConnection getInstance] getItems];
    if (items != NULL) {
        NSMutableDictionary *groups = [[NSMutableDictionary alloc] init];
        NSMutableArray *suggestions = [[NSMutableArray alloc] init];
        model = [[NSMutableArray alloc] init];
        for (i = 0; i < [items count]; i++) {
            TiVoContainerItem *item = [items objectAtIndex:i];
            BOOL suggested = ([item getDetail:@"suggested"] != NULL);
            NSMutableArray *group = [groups objectForKey:[item getDetail:@"Title"]];
            TiVoContainerItemTableCell *cell = [[TiVoContainerItemTableCell alloc] init];
            [cell setTitle: [item getDetail:@"Title"]];
            [cell setEnabled:YES];
            [cell setValue:item];

            if (group == NULL && !suggested) {
                group = [[NSMutableArray alloc] init];
                [groups setObject:group forKey:[item getDetail:@"Title"]];
                [model addObject: group];
            }
            if (group != NULL) {
                [group addObject: cell];
            }
            if (suggested) {
                [suggestions addObject: cell];
            } else {
                [cells addObject:cell];
            }
        }
        [groups release];
        for (i = 0; i < [model count]; i++) {
            NSArray *group = [model objectAtIndex:i];
            if ([group count] == 1) {
                [model replaceObjectAtIndex:i withObject: [group objectAtIndex:0]];
            } else {
                int j;
                for (j = 0; j < [group count]; j++) {
                    TiVoContainerItemTableCell *cell = [group objectAtIndex:j];
                    NSString *episode = [[cell getValue] getDetail:@"EpisodeTitle"];
                    if (episode != NULL) {
                        [cell setTitle: episode];
                    }
                }
                TiVoContainerItemTableCell *cell = [[TiVoContainerItemTableCell alloc] init];
                [cell setTitle: [[[group objectAtIndex: 0] getValue] getDetail:@"Title"]];
                [cell setDisclosureStyle: 1];
                [cell setShowDisclosure: YES];
                [cell setEnabled:YES];
                [cell setValue:group];
                [model replaceObjectAtIndex:i withObject: cell];
            }
        }
        TiVoContainerItemTableCell *cell = [[TiVoContainerItemTableCell alloc] init];
        [cell setTitle: @"TiVo Suggestions"];
        [cell setDisclosureStyle: 1];
        [cell setShowDisclosure: YES];
        [cell setEnabled:YES];
        [cell setValue:suggestions];
        [model addObject:cell];
       
        cells = model;
        if (progress != NULL) {
            [progress show:NO];
            [progress removeFromSuperview];
            [progress release];
            progress = NULL;
            [nowPlayingTable setEnabled:YES];
        }
    } else {
    }
    if ([[TiVoNPLConnection getInstance] getState] == NPL_ORGANIZED) {
        [bottomNavBar setButton:0 enabled:YES];
    } else {
        [bottomNavBar setButton:0 enabled:NO];
    }
    [nowPlayingTable reloadData];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
    if (navbar == navBar) {
        switch(button) {
        case 0: // settings
        {
            struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
            TiVoPreferencesView *prefs = 
                   [[TiVoPreferencesView alloc] initWithFrame:
                       CGRectMake(0, 0, rect.size.width, rect.size.height)];
            [self addSubview:prefs];
            break;
        }
        case 1: // remote
        {
            [self removeFromSuperview];
            [self release];
            break;
        }
        }
    } else {
        switch(button) {
        case 0: // refresh
        {
            [bottomNavBar setButton:0 enabled:NO];
            [[TiVoNPLConnection getInstance] reloadData:NULL];
            break;
        }
        case 1: // back
        {
            [navItem setTitle: @"Now Playing"];
            [bottomNavBar setButton:1 enabled:NO];
            cells = model;
            [nowPlayingTable reloadData];
            break;
        }
        }
    }
}

-(UITableCell*)table:(UITable*)table cellForRow:(int)row column:(UITableColumn *)column
{
    return [cells objectAtIndex:row];
}

-(int)numberOfRowsInTable:(UITable *) table
{
    return [cells count];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Media Access Key" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Now Playing Data" object:nil];
    [navBar release];
    [bottomNavBar release];
    [navItem release];
    [nowPlayingTable release];
    [col release];
    [detailView release];
    if (progress != NULL) {
        [progress removeFromSuperview];
        [progress release];
        progress = NULL;
    }
    int i;
    for (i = 0; i < [model count]; i++) {
        TiVoContainerItemTableCell *cell = [model objectAtIndex:i];
        if (![[cell getValue] isKindOfClass:[TiVoContainerItem class]]) {
            NSArray *group = [cell getValue];
            int j;
            for (j = 0; j < [group count]; j++) {
                TiVoContainerItemTableCell *cell2 = [group objectAtIndex:j];
                [cell2 release];
            }
            [group release];
        }
        [cell release];
    }
    [model release];
    [super dealloc];
}

@end

@implementation TiVoContainerItemTableCell

- (id)init
{
    [super init];
    value = NULL;
    return self;
}

-(void)setValue:(id) val
{
    value = val;
}

-(id)getValue
{
    return value;
}
- (void)dealloc
{
    [super dealloc];
}
@end
