/* SimpleDialog

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
#import "SimpleDialog.h"

@implementation SimpleDialog


- (id)init
{
    return self;
}

- (void)alertSheet:(UIActionSheet *)sheet buttonClicked:(int) button
{
    [sheet dismissWithClickedButtonIndex: button animated: YES];
    [sheet release];
}

+ (void)showDialog:(NSString *) title: (NSString *)alert
{
    NSString *bodyText = [NSString stringWithFormat:alert];
    CGRect rect = [[[UIApplication sharedApplication] keyWindow] bounds];
    UIActionSheet *alertSheet = [[UIActionSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
    [alertSheet setTitle:title];
    // TODO: create a UILabel for this text
    // [alertSheet setBodyText:bodyText];
    [alertSheet addButtonWithTitle:@"OK"];
    [alertSheet setDelegate: [[SimpleDialog alloc] init]];
    // TODO: verify
    [alertSheet showInView: [[UIApplication sharedApplication] keyWindow]];
    // [alertSheet popupAlertAnimated:YES];
}

@end
