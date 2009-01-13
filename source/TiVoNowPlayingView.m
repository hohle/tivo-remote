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
#import <CoreGraphics/CoreGraphics.h>

#import "TiVoDefaults.h"
#import "TiVoNowPlayingView.h"
#import "TiVoPreferencesView.h"
#import "ConnectionManager.h"
#import "SimpleDialog.h"
#import "TiVoNPLConnection.h"
#import "TiVoContainerItem.h"
#import "TiVoBrowser.h"
#import "TiVoProgramView.h"

@implementation TiVoNowPlayingView

- (id)initWithFrame:(struct CGRect)rect
{
    [super initWithFrame:rect];

    struct CGRect navRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48);
    navBar = [[UINavigationBar alloc] initWithFrame: navRect];
    [navBar showButtonsWithLeftTitle:@"Remote" rightTitle:@"Settings" leftBack:YES];
    [navBar setBarStyle:5];
    [navBar setDelegate:self];

    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Now Playing"];
    [navBar pushNavigationItem:[navItem autorelease]];

    struct CGRect bottomNavRect = CGRectMake(rect.origin.x, rect.origin.y + rect.size.height - 48, rect.size.width, 48);
    bottomNavBar = [[UINavigationBar alloc] initWithFrame: bottomNavRect];
    [bottomNavBar showButtonsWithLeftTitle:@"Back" rightTitle:@"Refresh" leftBack:YES];
    [bottomNavBar setBarStyle:5];
    [bottomNavBar setDelegate:self];
    [bottomNavBar setButton:1 enabled:NO];
    [bottomNavBar setButton:0 enabled:NO];

    // bodyRect = CGRectMake(rect.origin.x, rect.origin.y + 48, rect.size.width, rect.size.height - 2 * 48);
    // body = [[UITransitionView alloc] initWithFrame:bodyRect];
    // bodyRect.origin.x = 0;
    // bodyRect.origin.y = 0;

    float progX = (rect.origin.x + 10);
    float progY = (rect.origin.y + 100);
    struct CGRect progRect = CGRectMake(progX, progY, rect.size.width - progX - 10, 150);
    progress = [[UIProgressView alloc] initWithFrame:progRect];
    [progress setText:@"Loading Now Playing Data"];
    [progress show:YES];

    views = [[NSMutableArray alloc] init];
    [self refresh:NULL];


    [self addSubview:navBar];
    [self addSubview:bottomNavBar];
    // [self addSubview:body];
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

- (void)showDetails:(TiVoContainerItemTableCell *) cell
{
NSLog(@"showDetails -- disclosure! %@", [views lastObject]);
NSLog(@"disclosure -- opening programView");
    // Open a detailed view for the recorded show
    TiVoProgramView *programView =  [[TiVoProgramView alloc] initWithFrame:bodyRect :[cell getValue]];
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:[cell title]];
    [navBar pushNavigationItem: navItem animated: YES];
    [navItem release];
     // [body transition:1 toView:programView];
     [views addObject: programView];
     [bottomNavBar setButton:1 enabled:YES];
}

- (void)tableRowSelected:(NSNotification *)notification
{
    TiVoContainerItemTableCell *cell = 
            [[notification object] cellAtRow: 
                    [[notification object]selectedRow] column:0];
    if ([[cell getValue] isKindOfClass:[TiVoContainerItem class]]) {
NSLog(@"not a disclosure -- playing");
        // play the show
        @try {
            TiVoContainerItem *item = [cell getValue];
            NSMutableArray *commands = [item getCommands];
            [commands addObject:@"TiVo Play"];
            id<RemoteConnection> conn = [[ConnectionManager getInstance] getConnection:@"TiVo"];
            [conn batchSend:commands];
        } @catch (NSString *exc) {
            [SimpleDialog showDialog:@"Connection Error" :exc];
        }
    } else {
        // open the group
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:[cell title]];
        [navBar pushNavigationItem: navItem animated: YES];
        [navItem release];
        [bottomNavBar setButton:1 enabled:YES];
        TiVoBrowser *browser = [[TiVoBrowser alloc] initWithFrame:bodyRect :[cell getValue]];
        // [body transition:1 toView:browser];
        [browser refresh:NULL];
        [[browser getTable] setDelegate: self];
        [views addObject: browser];
    }
    [[[notification object]cellAtRow:[[notification object]selectedRow]column:0] setSelected:FALSE withFade:TRUE];
}

- (void) refresh:(id) param
{
    if ([[TiVoNPLConnection getInstance] getState] == NPL_NO_CONNECTION) {
        // no longer have a MAK defined, don't show this view anymore
        [self release];
    }

    // clear views
    UIView *view;
    while (view = [views lastObject])  {
        [views removeLastObject];
        [view removeFromSuperview];
        [view release];
    }

    NSArray *items = [[TiVoNPLConnection getInstance] getItems];
    if (items != NULL) {
        // take the items, and arrange them for display
        NSMutableDictionary *groups = [[NSMutableDictionary alloc] init];
        NSMutableArray *suggestions = [[NSMutableArray alloc] init];
        model = [[NSMutableArray alloc] init];
        int i;
        for (i = 0; i < [items count]; i++) {
            TiVoContainerItem *item = [items objectAtIndex:i];
            BOOL suggested = ([item getDetail:@"suggested"] != NULL);
            NSMutableArray *group = [groups objectForKey:[item getDetail:@"Title"]];
            TiVoContainerItemTableCell *cell = [[TiVoContainerItemTableCell alloc] init];
            [cell setTitle: [item getDetail:@"Title"]];
            [cell setEnabled:YES];
            [cell setValue:item];
            [cell setParent:self];
            [cell setDisclosureStyle: 1];
            [cell setShowDisclosure: YES];
            [cell setDisclosureClickable: YES];
            [[cell _disclosureView] addTarget:cell action:@selector(showDetails) forEvents:64];

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
            }
        }
        // each item has been examined, and placed into groups
        // we no longer need the map from name -> group
        [groups release];
        for (i = 0; i < [model count]; i++) {
            NSArray *group = [model objectAtIndex:i];
            if ([group count] == 1) {
                // this is a plain element
                [model replaceObjectAtIndex:i withObject: [group objectAtIndex:0]];
            } else {
                // this is a group
                int j;
                for (j = 0; j < [group count]; j++) {
                    TiVoContainerItemTableCell *cell = [group objectAtIndex:j];
                    NSString *episode = [[cell getValue] getDetail:@"EpisodeTitle"];
                    if (episode != NULL) {
                        [cell setTitle: episode];
                    }
                }
                // create the folder
                TiVoContainerItemTableCell *cell = [[TiVoContainerItemTableCell alloc] init];
                [cell setTitle: [[[group objectAtIndex: 0] getValue] getDetail:@"Title"]];
                [cell setDisclosureStyle: 2];
                [cell setShowDisclosure: YES];
                [cell setEnabled:YES];
                [cell setValue:group];
                [model replaceObjectAtIndex:i withObject: cell];
            }
        }
        // add suggestions
        TiVoContainerItemTableCell *cell = [[TiVoContainerItemTableCell alloc] init];
        [cell setTitle: @"TiVo Suggestions"];
        [cell setDisclosureStyle: 2];
        [cell setShowDisclosure: YES];
        [cell setEnabled:YES];
        [cell setValue:suggestions];
        [model addObject:cell];
       
        TiVoBrowser *browser = [[TiVoBrowser alloc] initWithFrame:bodyRect :model];
        [views addObject: browser];
        [[browser getTable] setDelegate: self];
        // [body transition:0 toView:browser];
        UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Now Playing"];
        [navBar pushNavigationItem: [navItem autorelease] animated: YES];
        [bottomNavBar setButton:1 enabled:NO];
    } else {
        NSString *text = @"";
        if ([[TiVoNPLConnection getInstance] getState] == NPL_ERROR) {
            text = @"\n\nError getting Now Playing data";
        }
        UITextView *flatView = [[UITextView alloc] initWithFrame:bodyRect];
        [flatView setEnabled:NO];
        [flatView setText:text];
        // [body transition:0 toView:flatView];
    }
    switch ([[TiVoNPLConnection getInstance] getState]) {
    case NPL_ERROR:
    case NPL_ORGANIZED:
        if (progress != NULL) {
            [progress show:NO];
            [progress removeFromSuperview];
            [progress release];
            progress = NULL;
        }
        [bottomNavBar setButton:0 enabled:YES];
        break;
    default:
        [bottomNavBar setButton:0 enabled:NO];
    }
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
    if (navbar == navBar) {
        switch(button) {
        case 0: // settings
        {
            struct CGRect rect = [[UIScreen mainScreen] bounds];
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
            UIView *oldView = [views lastObject];
            [views removeLastObject];
            UIView *newView = [views lastObject];
            [navBar popNavigationItem];
            [navBar popNavigationItemAnimated: YES];
            // [body transition:2 toView:newView];
            [bottomNavBar setButton:1 enabled:[views count] > 1];
            [oldView release];
            break;
        }
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Media Access Key" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Now Playing Data" object:nil];
    [navBar removeFromSuperview];
    [navBar release];
    [bottomNavBar removeFromSuperview];
    [bottomNavBar release];
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

            BOOL suggestions = [@"TiVo Suggestions" isEqualToString:[cell title]];
           
            int j;
            for (j = 0; j < [group count]; j++) {
                TiVoContainerItemTableCell *cell2 = [group objectAtIndex:j];
                BOOL suggested = [[cell2 getValue] getDetail:@"suggested"] != NULL;
                if (suggestions || !suggested) {
                    [cell2 release];
                }
            }
            [group release];
        }
        [cell release];
    }
    // release views
    UIView *view;
    while (view = [views lastObject])  {
        [views removeLastObject];
        [view removeFromSuperview];
        [view release];
    }
    [views release];
    // [body removeFromSuperview];
    // [body dealloc];
    [model release];
    [super dealloc];
}

@end

@implementation TiVoContainerItemTableCell

- (id)init
{
    [super init];
    value = NULL;
    parent = NULL;
    return self;
}

-(void)setParent:(id) val
{
    parent = val;
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

- (void)showDetails
{
    if (parent != NULL) {
        [parent showDetails: self];
    }
}
@end
