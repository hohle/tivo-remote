/* TiVoProgramView

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

#import "TiVoProgramView.h"
#import "ConnectionManager.h"
#import "SimpleDialog.h"
#import "TiVoNPLConnection.h"
#import "TiVoContainerItem.h"

@implementation TiVoProgramView

- (id)initWithFrame:(struct CGRect)rect :(TiVoContainerItem *)theItem
{
    [super initWithFrame:rect];

    detailTable = [[UITableView alloc] initWithFrame:rect];
    [detailTable setDataSource:self];
    [detailTable setDelegate:self];

    item = theItem;

    descriptionCell = [[UITableViewCell alloc] init];
    [descriptionCell setText:[item getDetail:@"Description"]];
    //[[descriptionCell textField] setText:@""];
    // [[descriptionCell titleTextLabel] setWrapsText:YES];
    // TODO [descriptionCell setEnabled:NO];

    durationCell = [[UITableViewCell alloc] init];
    [durationCell setText:@"Duration"];
    int minutes = [[item getDetail:@"Duration"] intValue] / (60 * 1000);
    [[durationCell textField] setText:[NSString stringWithFormat:@"%d minutes", minutes]];
    // TODO [durationCell setEnabled:NO];

    hdCell = [[UITableViewCell alloc] init];
    [hdCell setText:@"High Definition"];
    //[[hdCell textField] setText:[item getDetail:@"HighDefinition"]];
    // TODO [hdCell setEnabled:NO];

    stationCell = [[UITableViewCell alloc] init];
    [stationCell setText:@"Station"];
    //[[stationCell textField] setText:[item getDetail:@"SourceStation"]];
    // TODO [stationCell setEnabled:NO];

    captureCell = [[UITableViewCell alloc] init];
    [captureCell setText:@"Recorded"];
    //[[captureCell textField] setText:[item getDetail:@"CaptureDate"]];
    // TODO [captureCell setEnabled:NO];

    play = [[UITableViewCell alloc] init];
    [play setText:@"Play"];

    delete = [[UITableViewCell alloc] init];
    [delete setText:@"Delete"];


    [self addSubview:detailTable];
    [detailTable reloadData];

    return self;
}



- (NSUInteger) numberOfGroupsInPreferencesTable:(id)preferencesTable
{
    return 3;
}


-(NSInteger) tableView: (UITableView*) table numberOfRowsInSection: (int) section
{
    switch (section) {
        case 0:
            return 4;
        case 1:
            return 1;
        case 2:
            return 1;
    }
    return 0;
}

- (NSString*) preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
    switch (group) {
    case 0:
        if ([item getDetail:@"EpisodeTitle"] != NULL) {
            return [NSString stringWithFormat:@"%@ - %@", [item getDetail:@"Title"], [item getDetail:@"EpisodeTitle"]];
        } else {
            return [item getDetail:@"Title"];
        }
    case 1:
        return @"";
    case 2:
        return @"";
    }
    return nil;
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight
{
    switch (group) {
    case 0:
        if (row == 0) {
            return 192.0;
        }
    }
    return proposedHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([indexPath section]) {
        case 0:
            switch([indexPath row]) {
                case 0:
                    return descriptionCell;
                case 1:
                    return durationCell;
                case 2:
                    return hdCell;
                case 3:
                    return stationCell;
            }
        case 1:
            return play;
        case 2:
            return delete;
    }
    return nil;
}

- (void)tableRowSelected:(NSNotification *)notification
{
    NSIndexPath* indexPath = [detailTable indexPathForSelectedRow];
    NSUInteger row = [indexPath row];
    if (row == 6) {
        @try {
            NSMutableArray *commands = [item getCommands];
            [commands addObject:@"TiVo Play"];
            id<RemoteConnection> conn = [[ConnectionManager getInstance] getConnection:@"TiVo"];
            [conn batchSend:commands];
        } @catch (NSString *exc) {
            [SimpleDialog showDialog:@"Connection Error" :exc];
        }
    } else if (row == 8) {
        CGRect rect = [[[UIApplication sharedApplication] keyWindow] bounds];
        alertSheet = [[UIActionSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
        [alertSheet setTitle:@"Alert!"];
        [alertSheet setBodyText:@"Deleting is not 100% reliable.  Are you sure?"];
        [alertSheet addButtonWithTitle:@"Cancel"];
        [alertSheet addButtonWithTitle:@"OK"];
        [alertSheet setDelegate: self];
        [alertSheet popupAlertAnimated:YES];
    }
    UITableView* t = [notification object];
    [[t cellForRowAtIndexPath: [t indexPathForSelectedRow]] setSelected: NO animated: YES];
}

- (void)alertSheet:(UIActionSheet *)sheet buttonClicked:(int) button
{
    [sheet dismissWithClickedButtonIndex: button animated: YES];
    if (button == 2) {
        @try {
            NSMutableArray *commands = [item getCommands];
            [commands addObject:@"TiVo Clear"];
            id<RemoteConnection> conn = [[ConnectionManager getInstance] getConnection:@"TiVo"];
            [conn batchSend:commands];
            
            [[TiVoNPLConnection getInstance] removeItem:item];
        } @catch (NSString *exc) {
            [SimpleDialog showDialog:@"Connection Error" :exc];
        }
    }
}

- (void)dealloc
{
    [detailTable release];
    [play release];
    [delete release];
    [descriptionCell release];
    [durationCell release];
    [hdCell release];
    [stationCell release];
    [captureCell release];
    [super dealloc];
}


@end
