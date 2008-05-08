/* TiVoButton

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
#import <UIKit/UIViewTapInfo.h>
#import <UIKit/UIView-Geometry.h>

#import "TiVoButton.h"
#import "ConnectionManager.h"


static UIPushButton * buttonImg = NULL;

@implementation TiVoButton
- (id)initWithTitle:(NSString *)title
{
    [super initWithTitle:title autosizesToFit:NO];
    if (buttonImg == NULL) {
        buttonImg = [UIImage applicationImageNamed:@"button.png"];
    }
    cmd = NULL;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    float backParts[4] = {0, 0, 0, .9};
    [self setTitleColor : CGColorCreate( colorSpace, backParts) forState:0];

    [self setDrawContentsCentered: YES];
    [self setBackground:buttonImg forState:0];
    [self setBackground:buttonImg forState:1];
    [self addTarget: self action:@selector(buttonEvent:) forEvents:1];

    connection = [[ConnectionManager getInstance] getConnection: @"TiVo"];

    return self;
}

- (char *)getCommand
{
    return cmd;
}

- (void)setCommand:(char *)command
{
    cmd = command;
}

- (void) setConfirm:(BOOL)conf
{
    confirm = conf;
}

- (void) buttonEvent:(UIPushButton *) button
{
    if (confirm) {
        [self showAlert:@"Are you sure?": YES];
    } else {
        @try {
            [connection sendCommand: cmd];
        } @catch (NSString *alert) {
            [self showAlert:alert : NO];
        }
    }
}

- (void)showAlert:(NSString *) alert:(BOOL) conf
{
    NSString *bodyText = [NSString stringWithFormat:alert];
    CGRect rect = [[UIWindow keyWindow] bounds];
    alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
    [alertSheet setTitle:@"Alert!"];
    [alertSheet setBodyText:bodyText];
    if (conf) {
        [alertSheet addButtonWithTitle:@"Cancel"];
    }
    [alertSheet addButtonWithTitle:@"OK"];
    [alertSheet setDelegate: self];
    [alertSheet popupAlertAnimated:YES];
}

- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int) button
{
    [sheet dismissAnimated:YES];
NSLog(@"button = %d", button);
    if (button == 2) {
        @try {
            [connection sendCommand: cmd];
        } @catch (NSString *alert) {
            [self showAlert:alert : NO];
        }
    }
}

@end
