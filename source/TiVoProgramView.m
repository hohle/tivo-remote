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
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UITextView.h>
#import <UIKit/UITable.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UITableColumn.h>
#import <UIKit/UITextLabel.h>
#import <UIKit/UIImageAndTextTableCell.h>
#import <UIKit/UIAlertSheet.h>
#import <UIKit/UIView-Geometry.h>

#import "TiVoProgramView.h"
#import "ConnectionManager.h"
#import "SimpleDialog.h"
#import "TiVoNPLConnection.h"
#import "TiVoContainerItem.h"

@implementation TiVoProgramView

- (id)initWithFrame:(struct CGRect)rect :(TiVoContainerItem *)theItem
{
    [super initWithFrame:rect];

    detailTable = [[UIPreferencesTable alloc] initWithFrame:rect];
    [detailTable setDataSource:self];
    [detailTable setDelegate:self];

    item = theItem;

    descriptionCell = [[UIPreferencesTextTableCell alloc] init];
    [descriptionCell setTitle:[item getDetail:@"Description"]];
    [[descriptionCell textField] setText:@""];
    [[descriptionCell titleTextLabel] setWrapsText:YES];
    [descriptionCell setEnabled:NO];

    durationCell = [[UIPreferencesTextTableCell alloc] init];
    [durationCell setTitle:@"Duration"];
    int minutes = [[item getDetail:@"Duration"] intValue] / (60 * 1000);
    [[durationCell textField] setText:[NSString stringWithFormat:@"%d minutes", minutes]];
    [durationCell setEnabled:NO];

    hdCell = [[UIPreferencesTextTableCell alloc] init];
    [hdCell setTitle:@"High Definition"];
    [[hdCell textField] setText:[item getDetail:@"HighDefinition"]];
    [hdCell setEnabled:NO];

    stationCell = [[UIPreferencesTextTableCell alloc] init];
    [stationCell setTitle:@"Station"];
    [[stationCell textField] setText:[item getDetail:@"SourceStation"]];
    [stationCell setEnabled:NO];

    captureCell = [[UIPreferencesTextTableCell alloc] init];
    [captureCell setTitle:@"Recorded"];
    [[captureCell textField] setText:[item getDetail:@"CaptureDate"]];
    [captureCell setEnabled:NO];

    play = [[UIPreferencesTableCell alloc] init];
    [play setTitle:@"Play"];

    delete = [[UIPreferencesTableCell alloc] init];
    [delete setTitle:@"Delete"];


    [self addSubview:detailTable];
    [detailTable reloadData];

    return self;
}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
    return 3;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
    switch (group) {
    case 0:
        return 4;
    case 1:
        return 1;
    case 2:
        return 1;
    }
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
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

- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
    switch (group) {
    case 0:
        switch(row) {
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
}

- (void)tableRowSelected:(NSNotification *)notification
{
    int row = [detailTable selectedRow];
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
        CGRect rect = [[UIWindow keyWindow] bounds];
        alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
        [alertSheet setTitle:@"Alert!"];
        [alertSheet setBodyText:@"Deleting is not 100% reliable.  Are you sure?"];
        [alertSheet addButtonWithTitle:@"Cancel"];
        [alertSheet addButtonWithTitle:@"OK"];
        [alertSheet setDelegate: self];
        [alertSheet popupAlertAnimated:YES];
    }
    [[[notification object]cellAtRow:[[notification object]selectedRow]column:0] setSelected:FALSE withFade:TRUE];
}

- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int) button
{
    [sheet dismissAnimated:YES];
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
