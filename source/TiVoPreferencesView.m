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
int SAVE_ROW = 6;

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
    makCell = [[UIPreferencesTextTableCell alloc] init];
    [makCell setTitle:@"Media Access Key"];
    [[makCell textField] setText:[defaults getMediaAccessKey]];
    [makCell setEnabled:YES];
    [makCell setTarget:self];
    [makCell setAction:@selector(makEdited)];
    [[makCell textField] setPreferredKeyboardType: 1];
    nameCell = [[UIPreferencesTextTableCell alloc] init];
    [nameCell setTitle:@"Name"];
    [[nameCell textField] setText:[defaults getTiVoName]];
    [nameCell setEnabled:YES];
    [nameCell setTarget:self];
    [nameCell setAction:@selector(nameEdited)];
//    [nameCell setReturnAction:@selector(nameEdited)];

    groupCell = [[UIPreferencesControlTableCell alloc] init];
    [groupCell setTitle:@"Uses Groups"];
    UISwitchControl *groupControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(bodyRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)];
    [groupControl setValue: [defaults useGroups]];
    [groupCell setControl:groupControl];

    sortCell = [[UIPreferencesControlTableCell alloc] init];
    [sortCell setTitle:@"Sorts By Date"];
    UISwitchControl *sortControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(bodyRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)];
    [sortControl setValue: [defaults sortByDate]];
    [sortCell setControl:sortControl];
    [self makEdited];

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
    [delete setTitle:@"Delete"];
    [delete setEnabled:([savedCells count] > 0)];

    add = [[UIPreferencesTableCell alloc] init];
    [add setTitle:@"Save"];

    preferencesTable = [[UIPreferencesTable alloc] initWithFrame:bodyRect];
    [preferencesTable setDataSource:self];
    [preferencesTable setDelegate:self];
    [preferencesTable reloadData];

    [self addSubview:navBar];
    [self addSubview:preferencesTable];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh:) name:@"Detected TiVo" object:nil];

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
           if (![self validateMAK]) {
               return;
            }
            // need to reset focus so the table doesn't get messed up
            [preferencesTable _setEditingCell:NULL];
            [preferencesTable setKeyboardVisible:NO];
            NSString *name = [[nameCell textField] text];
            NSString *ip = [[ipCell textField] text];
            NSString *mak  = [[makCell textField] text];
            NSNumber *group  = [[groupCell control] valueForKey:@"value"];
            NSNumber *sort = [[sortCell control] valueForKey:@"value"];
            NSMutableDictionary *connInfo = [[NSMutableDictionary alloc] init];
            [connInfo setObject:name forKey:@"TiVo Name"];
            [connInfo setObject:ip forKey:@"IP Address"];
            [connInfo setObject:mak forKey:@"Media Access Key"];
            [connInfo setObject:group  forKey:@"TiVo Uses Groups"];
            [connInfo setObject:sort forKey:@"TiVo Sorts By Date"];
            [self addSaved:connInfo];
            [delete setEnabled:YES];
            [preferencesTable reloadData];
            return;
        }
        row -= SAVE_ROW + 2;
        if (row >= 0 && row < [detectedCells count]) {
            NSDictionary *dict = [[detectedCells objectAtIndex:row] value];
            NSString *warnStr;
            if ([dict objectForKey:@"swversion"] != NULL) {
                warnStr =[NSString stringWithFormat:@"TiVo is version %@ %@, TiVoRemote requires Series3 9.1 or higher.",[dict objectForKey:@"platform"], [dict objectForKey:@"swversion"]];
            } else {
                warnStr =[NSString stringWithFormat:@"TiVo version is unknown, TiVoRemote requires Series3 9.1 or higher."];
            }
            [SimpleDialog showDialog:@"Detected TiVo" : warnStr];
            [self setData:[[detectedCells objectAtIndex:row] value]];
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

- (void) nameEdited
{
    [preferencesTable setKeyboardVisible:NO];
}

- (void) ipEdited
{
}

- (void) makEdited
{
    if ([[[makCell textField] text] length] > 0) {
        [groupCell setEnabled:YES];
        [sortCell setEnabled:YES];
    } else {
        [groupCell setEnabled:NO];
        [sortCell setEnabled:NO];
    }
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
        return 6;
    case 2:
        return [detectedCells count];
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
        return @"TiVo Settings";
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
            return nameCell;
        case 1:
            return ipCell;
        case 2:
            return makCell;
        case 3:
            return groupCell;
        case 4:
            return sortCell;
        case 5:
            return add;
        }
    case 2:
        return [detectedCells objectAtIndex:row];
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
        int row = SAVED_ROW_START + [savedCells count] + 2;
//        [preferencesTable _setEditingCell:row];
        [SimpleDialog showDialog:@"IP Verification" :@"Illegal character in IP Address"];
    }
    return ret;
}

- (BOOL) validateMAK
{
    if ([[[makCell textField] text] length] == 0) {
        return YES;
    }
    // MAK should consist only of characters [0-9]
    // can't find regular expressions... this will be ugly
    const char *makChars = [[[makCell textField] text] UTF8String];
    BOOL ret = YES;
    int len = strlen(makChars);
    int i;
    for (i = 0; i < len; i++) {
        if ('0' <= makChars[i] && makChars[i] <= '9') {
            continue; // character is an integer
        }
        ret = NO;
        break;
    }
    if (!ret) {
        [makCell setHighlighted:YES];
        [[makCell textField] becomeFirstResponder];
        int row = SAVED_ROW_START + [savedCells count] + 3;
//        [preferencesTable _setEditingCell:row];
        [SimpleDialog showDialog:@"MAK Verification" :@"Illegal character in Media Access Key"];
    }
    return ret;
}

- (void) finished
{
    NSString *newName = [nameCell value];
    NSString *newIp = [ipCell value];
    NSString *newMak = [makCell value];
    int i;
    NSMutableArray *savedConnections = [[NSMutableArray alloc] init];
    for (i = 0; i < [savedCells count]; i++) {
        NSDictionary *dict = [[savedCells objectAtIndex:i] value];
        [savedConnections addObject:dict];
    }
    BOOL group  = [[[groupCell control] valueForKey:@"value"] boolValue];
    BOOL sort = [[[sortCell control] valueForKey:@"value"] boolValue];
    BOOL standby = [[[standbyCell control] valueForKey:@"value"] boolValue];
    [defaults setTiVoName: newName];
    [defaults setIpAddr: newIp];
    [defaults setMediaAccessKey: newMak];
    [defaults setUseGroups: group];
    [defaults setSortByDate: sort];
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

- (void) refresh:(id) param
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
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:[detected objectForKey:key]];
        [dict setObject:@"" forKey:@"Media Access Key"];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"TiVo Uses Groups"];
        [dict setObject:[NSNumber numberWithBool:YES] forKey:@"TiVo Sorts By Date"];
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
    NSString *makVal = [connInfo objectForKey:@"Media Access Key"];
    [makCell setValue: (makVal != NULL ? makVal : @"")];
    [nameCell setValue: [connInfo objectForKey:@"TiVo Name"]];
    [[groupCell control] setValue: [[connInfo objectForKey:@"TiVo Uses Groups"] boolValue]];
    [[sortCell control] setValue: [[connInfo objectForKey:@"TiVo Sorts By Date"]boolValue]];
    [self makEdited];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
    switch(button) {
    case 0: // done
    {
        if (![self validateIP]) {
            return;
        }
        if (![self validateMAK]) {
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"Detected TiVo" object:nil];
    [navBar release];
    [nameCell release];
    [ipCell release];
    [makCell release];
    [[groupCell control] release];
    [groupCell release];
    [[sortCell control] release];
    [sortCell release];
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
