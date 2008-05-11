/* TiVoPreferencesView

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
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UIView.h>
#import <UIKit/UIImageView.h>
#import <UIKit/UIImage.h>
#import <UIKit/UISwitchControl.h>
#import <UIKit/UIViewTapInfo.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTextTableCell.h>

#import "TiVoDefaults.h"
#import "TiVoPreferencesView.h"
#import "SimpleDialog.h"

#import <Foundation/NSPathUtilities.h>

@implementation TiVoPreferencesView

int ADD_ROW = 3;
int SAVE_ROW_START = 5;

- (id)initWithFrame:(struct CGRect)rect
{
    [super initWithFrame:rect];
    defaults = [TiVoDefaults sharedDefaults];

    struct CGRect navRect = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 48);
    navBar = [[UINavigationBar alloc] initWithFrame: navRect];
    [navBar showButtonsWithLeftTitle:@"About" rightTitle:@"Done"];
    [navBar setBarStyle:5];
    [navBar setDelegate:self];

    struct CGRect bodyRect = CGRectMake(rect.origin.x, rect.origin.y + 48, rect.size.width, rect.size.height - 48);
    ipCell = [[UIPreferencesTextTableCell alloc] init];
    [ipCell setTitle:@"IP Address"];
    [[ipCell textField] setText:[defaults getIpAddr]];
    [ipCell setEnabled:YES];
    [ipCell setTarget:self];
    [[ipCell textField] setPreferredKeyboardType: 1];
    [ipCell setReturnAction:@selector(ipEdited)];
    nameCell = [[UIPreferencesTextTableCell alloc] init];
    [nameCell setTitle:@"Name"];
    [[nameCell textField] setText:[defaults getTiVoName]];
    [nameCell setEnabled:YES];
    [nameCell setTarget:self];
    [nameCell setReturnAction:@selector(nameEdited)];

    standbyCell = [[UIPreferencesControlTableCell alloc] init];
    [standbyCell setTitle:@"Show Standby"];
    UISwitchControl *standbyControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(bodyRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)];
    [standbyControl setValue: [defaults showStandby]];
    [standbyCell setControl:standbyControl];
    [standbyCell setEnabled:YES];

    savedCells = [[NSMutableArray alloc] init];
    NSArray *savedConns = [defaults getSavedConnections];
    int i;
    for (i = 0; i < [savedConns count]; i++) {
        NSMutableDictionary *dict = [savedConns objectAtIndex:i];
        [self performAdd: dict];
    }
    delete = [[UIPreferencesTableCell alloc] init];
    [delete setTitle:@"Delete"];;
    [delete setEnabled:([savedCells count] > 0)];

    add = [[UIPreferencesTableCell alloc] init];
    [add setTitle:@"Add"];
    [self checkIps];

    preferencesTable = [[UIPreferencesTable alloc] initWithFrame:bodyRect];
    [preferencesTable setDataSource:self];
    [preferencesTable setDelegate:self];
    [preferencesTable reloadData];

    [self addSubview:navBar];
    [self addSubview:preferencesTable];

    return self;
}

- (void)tableRowSelected:(NSNotification *)notification
{
    int row = [preferencesTable selectedRow];
    if (row == ADD_ROW) {
        NSString *ip = [[ipCell textField] text];
        NSString *name = [[nameCell textField] text];
        NSMutableDictionary *connInfo = [[NSMutableDictionary alloc] init];
        [connInfo setObject:ip forKey:@"IP Address"];
        [connInfo setObject:name forKey:@"TiVo Name"];
        [self performAdd:connInfo];
        [self checkIps];
        [delete setEnabled:YES];
        [preferencesTable reloadData];
        return;
    }
    row -= SAVE_ROW_START;
    if (row >= 0 && row < [savedCells count] && ![preferencesTable isRowDeletionEnabled]) {
        int i;
        for (i = 0; i < [savedCells count]; i++) {
            [[savedCells objectAtIndex:i] setChecked:NO];
        }
        [[savedCells objectAtIndex:row] setChecked:YES];
     } else if (row == [savedCells count]) {
         // delete button
         if ([preferencesTable isRowDeletionEnabled]) {
             [preferencesTable enableRowDeletion:NO animated:YES];
             [preferencesTable reloadData];
             [delete setTitle:@"Delete"];
             [delete setEnabled:([savedCells count] > 0)];
         } else {
             [preferencesTable enableRowDeletion:YES animated:YES];
             [preferencesTable reloadData];
             [delete setTitle:@"Done"];
         }
     }
}

- (void) table:(UITable *) table deleteRow:(int) row 
{
    row -= SAVE_ROW_START;
    if (row >= 0 && row < [savedCells count]) {
        id cell = [savedCells objectAtIndex:row];
        [savedCells removeObjectAtIndex:row];
        [cell release];
        [self checkIps];
    }
}

- (void) ipEdited
{
    [self checkIps];
} 

- (void) nameEdited
{
    [preferencesTable setKeyboardVisible:NO];
}

- (BOOL) table:(UITable *) table canDeleteRow:(int) row 
{
    row -= SAVE_ROW_START;
    if (row >= 0 && row < [savedCells count]) {
        return YES;
    } else {
        return NO;
    }
}


- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
    return 3;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
    switch (group) {
    case 0:
        return 3;
    case 1:
        return [savedCells count] + 1;
    case 2:
        return 1;
    }
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
    switch (group) {
    case 0:
        return @"Network Settings";
    case 1:
        return @"Saved Settings";
    case 2:
        return @"Interface";
    }
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight
{
    return 48.0;
}
- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
    switch (group) {
    case 0:
        switch (row) {
        case 0:
            return ipCell;
        case 1:
            return nameCell;
        case 2:
            return add;
        }
    case 1:
       if (row < [savedCells count]) {
           return [savedCells objectAtIndex:row];
       } else {
           return delete;
       }
    case 2:
        switch (row) {
        case 0:
            return standbyCell;
        }
    }
}

- (void) finished
{
    NSString *newIp = [ipCell value];
    NSString *newName = [nameCell value];
    int i;
    NSMutableArray *savedConnections = [[NSMutableArray alloc] init];
    for (i = 0; i < [savedCells count]; i++) {
        NSDictionary *dict = [[savedCells objectAtIndex:i] value];
        [savedConnections addObject:dict];
        if ([[savedCells objectAtIndex:i] isChecked]) {
            newIp = [dict objectForKey:@"IP Address"];
            newName = [dict objectForKey:@"TiVo Name"];
        }
    }
    BOOL standby = [[[standbyCell control] valueForKey:@"value"] boolValue];
    [defaults setIpAddr: newIp];
    [defaults setTiVoName: newName];
    [defaults setShowStandby: standby];
    [defaults setSavedConnections: savedConnections];
}

- (void) performAdd:(NSDictionary *) connInfo
{
    UIPreferencesTableCell *savedCell = [[UIPreferencesTableCell alloc] init];
    [savedCell setValue:connInfo];
    NSString *title = [NSString stringWithFormat:@"%@ : %@", [connInfo objectForKey:@"TiVo Name"], [connInfo objectForKey:@"IP Address"]];
    [savedCell setTitle:title];
    [savedCell setEnabled:YES];
    [savedCells addObject:savedCell];
}

- (void) checkIps
{
    BOOL addable = YES;
    int i;
    NSString *ip = [[ipCell textField] text];
    for (i = 0; i < [savedCells count]; i++) {
        NSDictionary *dict = [[savedCells objectAtIndex:i] value];
        if (0 == [ip compare:[dict objectForKey:@"IP Address"]]) {
            [[savedCells objectAtIndex:i] setChecked:YES];
            addable = NO;
        } else {
            [[savedCells objectAtIndex:i] setChecked:NO];
        }
    }
    [add setEnabled:addable];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
    switch(button) {
    case 0: // done
    {
        [self finished];
        [self removeFromSuperview];
        [self release];
        break;
    }
    case 1: // about
    {
        NSString *version = [[NSBundle mainBundle]
                objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (nil == version)
            version = @"??";
        NSString *bodyText = [NSString stringWithFormat:@"TiVoRemote.app version %@, by Dustin Puckett.", version];
        [SimpleDialog showDialog:@"About TiVoRemote":bodyText];
        break;
     }
     }
}

- (void)dealloc
{
    [navBar release];
    [ipCell release];
    [nameCell release];
    [add release];
    // loop through savedCells
    int i;
    for (i = 0; i < [savedCells count]; i++) {
        [[savedCells objectAtIndex:i] release];
    }
    [savedCells release];
    [delete release];
    [[standbyCell control] release];
    [standbyCell release];
    [preferencesTable release];
    [super dealloc];
}

@end
