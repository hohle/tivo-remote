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

@implementation TiVoPreferencesView
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

    standbyCell = [[UIPreferencesControlTableCell alloc] init];
    [standbyCell setTitle:@"Show Standby"];
    UISwitchControl *standbyControl = [[UISwitchControl alloc] initWithFrame:CGRectMake(bodyRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)];
    [standbyControl setValue: [defaults showStandby]];
    [standbyCell setControl:standbyControl];
    [standbyCell setEnabled:YES];

    preferencesTable = [[UIPreferencesTable alloc] initWithFrame:bodyRect];
    [preferencesTable setDataSource:self];
    [preferencesTable setDelegate:self];
    [preferencesTable reloadData];

    [self addSubview:navBar];
    [self addSubview:preferencesTable];
    return self;
}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
    return 2;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
    switch (group) {
    case 0:
        return 1;
    case 1:
        return 1;
    }
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
    switch (group) {
    case 0:
        return @"Network Settings";
    case 1:
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
        }
    case 1:
        switch (row) {
        case 0:
            return standbyCell;
        }
    }
}

- (void) finished {
    NSString *newIp = [ipCell value];
    BOOL standby = [[[standbyCell control] valueForKey:@"value"] boolValue];
    [defaults setIpAddr: newIp];
    if ([defaults showStandby] != standby) {
        [defaults setShowStandby: standby];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Standby" object:self];
    }
}

- (void)aboutAlert
{
    NSString *version = [[NSBundle mainBundle]
                objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (nil == version)
        version = @"??";
    NSString *bodyText = [NSString stringWithFormat:@"TiVoRemote.app version %@, by Dustin Puckett.", version];
    CGRect rect = [[UIWindow keyWindow] bounds];
    alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
    [alertSheet setTitle:@"About TiVoRemote"];
    [alertSheet setBodyText:bodyText];
    [alertSheet addButtonWithTitle:@"OK"];
    [alertSheet setDelegate: self];
    [alertSheet popupAlertAnimated:YES];
}

- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int) button
{
    [sheet dismissAnimated:YES];
    [alertSheet release];
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
        [self aboutAlert];
        break;
     }
     }
}

- (void)dealloc
{
    [navBar release];
    [ipCell release];
    [[standbyCell control] release];
    [standbyCell release];
    [preferencesTable release];
    [super dealloc];
}

@end
