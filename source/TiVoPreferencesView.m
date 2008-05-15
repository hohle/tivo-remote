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
#import <Foundation/NSEnumerator.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
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
#import "TiVoBeacon.h"

@implementation TiVoPreferencesView

int SAVED_ROW_START = 1;
int SAVE_ROW = 3;
int DETECTED_ROW_START = 5;

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
    [ipCell setAction:@selector(ipEdited)];
//    [ipCell setReturnAction:@selector(ipEdited)];
    nameCell = [[UIPreferencesTextTableCell alloc] init];
    [nameCell setTitle:@"Name"];
    [[nameCell textField] setText:[defaults getTiVoName]];
    [nameCell setEnabled:YES];
    [nameCell setTarget:self];
    [nameCell setAction:@selector(nameEdited)];
//    [nameCell setReturnAction:@selector(nameEdited)];

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
        [self addSaved: dict];
    }

    detectedCells = [[NSMutableArray alloc] init];
    NSDictionary *detected = [[TiVoBeacon getInstance] getDetectedTiVos];
    NSEnumerator *enumerator = [detected keyEnumerator];
    NSString *key;
    while ((key = [enumerator nextObject]) != NULL) {
        NSDictionary *dict = [detected objectForKey:key];
        [self addDetected: dict];
    }


    delete = [[UIPreferencesTableCell alloc] init];
    [delete setTitle:@"Delete"];;
    [delete setEnabled:([savedCells count] > 0)];

    add = [[UIPreferencesTableCell alloc] init];
    [add setTitle:@"Save"];

    refresh = [[UIPreferencesTableCell alloc] init];
    [refresh setTitle:@"Refresh"];;
    [refresh setEnabled:YES];

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
    row -= SAVED_ROW_START;
    if (row >= 0 && row < [savedCells count] && ![preferencesTable isRowDeletionEnabled]) {
        int i;
        [self setData:[[savedCells objectAtIndex:row] value]];
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
    } else if ((row -= [savedCells count] + 1) >= 0) {
       
        if (row == SAVE_ROW) {
           if (![self validateIP]) {
               return;
            }
            // need to reset focus so the table doesn't get messed up
            [preferencesTable _setEditingCell:NULL];
            [preferencesTable setKeyboardVisible:NO];
            NSString *ip = [[ipCell textField] text];
            NSString *name = [[nameCell textField] text];
            NSMutableDictionary *connInfo = [[NSMutableDictionary alloc] init];
            [connInfo setObject:ip forKey:@"IP Address"];
            [connInfo setObject:name forKey:@"TiVo Name"];
            [self addSaved:connInfo];
            [delete setEnabled:YES];
            [preferencesTable reloadData];
            return;
        }
        row -= DETECTED_ROW_START;
        if (row >= 0 && row < [detectedCells count]) {
            [self setData:[[detectedCells objectAtIndex:row] value]];
        } else {
//            [preferencesTable selectRow: 0 byExtendingSelection:NO withFade:YES];
            [self refresh];
            [[preferencesTable cellAtRow: [preferencesTable selectedRow] column:0] setSelected:NO withFade:YES];
        }
    }
}

- (void) table:(UITable *) table deleteRow:(int) row 
{
    row -= SAVED_ROW_START;
    if (row >= 0 && row < [savedCells count]) {
        id cell = [savedCells objectAtIndex:row];
        [savedCells removeObjectAtIndex:row];
        [cell release];
    }
}

- (void) ipEdited
{
}

- (void) nameEdited
{
    [preferencesTable setKeyboardVisible:NO];
}

- (BOOL) table:(UITable *) table canDeleteRow:(int) row 
{
    row -= SAVED_ROW_START;
    if (row >= 0 && row < [savedCells count]) {
        return YES;
    } else {
        return NO;
    }
}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
    return 4;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
    switch (group) {
    case 0:
        return [savedCells count] + 1;
    case 1:
        return 3;
    case 2:
        return [detectedCells count] + 1;
    case 3:
        return 1;
    }
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
    switch (group) {
    case 0:
        return @"Saved Settings";
    case 1:
        return @"Network Settings";
    case 2:
        return @"Detected TiVos";
    case 3:
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
       if (row < [savedCells count]) {
           return [savedCells objectAtIndex:row];
       } else {
           return delete;
       }
    case 1:
        switch (row) {
        case 0:
            return ipCell;
        case 1:
            return nameCell;
        case 2:
            return add;
        }
    case 2:
       if (row < [detectedCells count]) {
            return [detectedCells objectAtIndex:row];
       } else {
           return refresh;
       }
    case 3:
        switch (row) {
        case 0:
            return standbyCell;
        }
    }
}

- (BOOL) validateIP
{
    // IP should consist only of characters [A-Za-z0-9\.]
    // can't find regular expressions... this will be ugly
    const char *ipChars = [[[ipCell textField] text] UTF8String];
    BOOL ret = YES;
    int len = strlen(ipChars);
    int i;
    for (i = 0; i < len; i++) {
        if ('.' == ipChars[i]) {
            continue; // character is a period
        }
        if ('0' <= ipChars[i] && ipChars[i] <= '9') {
            continue; // character is an integer
        }
        if ('A' <= ipChars[i] && ipChars[i] <= 'Z') {
            continue; // character is an upper case alpha
        }
        if ('a' <= ipChars[i] && ipChars[i] <= 'z') {
            continue; // character is a lower case alpha
        }
        ret = NO;
        break;
    }
    if (!ret) {
        [ipCell setHighlighted:YES];
        [[ipCell textField] becomeFirstResponder];
        int row = SAVED_ROW_START + [savedCells count] + 1;
//        [preferencesTable _setEditingCell:row];
        [SimpleDialog showDialog:@"IP Verification" :@"Illegal character in IP Address"];
    }
    return ret;
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
    }
    BOOL standby = [[[standbyCell control] valueForKey:@"value"] boolValue];
    [defaults setIpAddr: newIp];
    [defaults setTiVoName: newName];
    [defaults setShowStandby: standby];
    [defaults setSavedConnections: savedConnections];
}

- (void) addSaved:(NSDictionary *) connInfo
{
    int i;
    // search through saved find matching ip
    for (i = 0; i < [savedCells count]; i++) {
        NSDictionary *dict = [[savedCells objectAtIndex:i] value];
        if ([[dict objectForKey:@"IP Address"] compare:[connInfo objectForKey:@"IP Address"]] == 0) {
            // going to update
            id old = [savedCells objectAtIndex:i];
            [savedCells removeObjectAtIndex:i];
            [old release];
            break;
        }
    }
    // or add
    UIPreferencesTableCell *savedCell = [[UIPreferencesTableCell alloc] init];
    [savedCell setValue:connInfo];
    NSString *title = [NSString stringWithFormat:@"%@ : %@", [connInfo objectForKey:@"TiVo Name"], [connInfo objectForKey:@"IP Address"]];
    [savedCell setTitle:title];
    [savedCell setEnabled:YES];
    [savedCells addObject:savedCell];
}

- (void) refresh
{
    UIPreferencesTableCell *detectedCell;
    NSEnumerator *enumerator = [detectedCells  objectEnumerator];
    while ((detectedCell = [enumerator nextObject]) != NULL) {
        [detectedCell release];
    }
    [detectedCells removeAllObjects];
    
    NSDictionary *detected = [[TiVoBeacon getInstance] getDetectedTiVos];
    enumerator = [detected keyEnumerator];
    NSString *key;
    while ((key = [enumerator nextObject]) != NULL) {
        NSDictionary *dict = [detected objectForKey:key];
        [self addDetected: dict];
    }
    [preferencesTable reloadData];
}

- (void) addDetected:(NSDictionary *) connInfo
{
    NSString *title = [NSString stringWithFormat:@"%@ : %@", [connInfo objectForKey:@"TiVo Name"], [connInfo objectForKey:@"IP Address"]];
    UIPreferencesTableCell *detectedCell = [[UIPreferencesTableCell alloc] init];
    [detectedCell setValue:connInfo];
    [detectedCell setTitle:title];
    [detectedCell setEnabled:YES];
    [detectedCells addObject:detectedCell];
}


- (void) setData:(NSDictionary *) connInfo
{
    [ipCell setValue: [connInfo objectForKey:@"IP Address"]];
    [nameCell setValue: [connInfo objectForKey:@"TiVo Name"]];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
    switch(button) {
    case 0: // done
    {
        if (![self validateIP]) {
            return;
        }
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
