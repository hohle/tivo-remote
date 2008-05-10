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
#import "TiVoDefaults.h"
#import "ConnectionManager.h"
#import "SimpleDialog.h"


static UIPushButton * buttonImg = NULL;

@implementation TiVoButton
- (id)initButton:(NSDictionary *) buttonProps
{
    [super initWithTitle: [buttonProps objectForKey:@"title"] autosizesToFit:NO];
    UIImage *buttonImg = [UIImage applicationImageNamed:[buttonProps objectForKey:@"icon"]];
    NSDictionary *function = [[TiVoDefaults sharedDefaults] getFunctionSettings:[buttonProps objectForKey:@"function"]];


    cmd = strdup([[function objectForKey:@"command"] UTF8String]);
    confirm = [buttonProps objectForKey:@"confirm"];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    float backParts[4] = {0, 0, 0, .9};
    [self setTitleColor : CGColorCreate( colorSpace, backParts) forState:0];

    [self setDrawContentsCentered: YES];
    [self setBackground:buttonImg forState:0];
    [self setBackground:buttonImg forState:1];
    [self addTarget: self action:@selector(buttonEvent:) forEvents:1];

    int xCoord = [[buttonProps objectForKey:@"xCoord"] intValue];
    int yCoord = [[buttonProps objectForKey:@"yCoord"] intValue];
    [self setFrame:  CGRectMake(xCoord, yCoord,  [buttonImg size].width, [buttonImg size].height)];

    connection = [[ConnectionManager getInstance] getConnection: [buttonProps objectForKey:@"connection"]];

    return self;
}

- (void) buttonEvent:(UIPushButton *) button
{
    if (confirm != NULL) {
        [self showConfirm:confirm];
    } else {
        @try {
            [connection sendCommand: cmd];
        } @catch (NSString *alert) {
            [SimpleDialog showDialog: @"Connection Error":alert];
        }
    }
}

- (void)showConfirm:(NSString *) alert
{
    NSString *bodyText = [NSString stringWithFormat:alert];
    CGRect rect = [[UIWindow keyWindow] bounds];
    alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
    [alertSheet setTitle:@"Alert!"];
    [alertSheet setBodyText:bodyText];
    [alertSheet addButtonWithTitle:@"Cancel"];
    [alertSheet addButtonWithTitle:@"OK"];
    [alertSheet setDelegate: self];
    [alertSheet popupAlertAnimated:YES];
}

- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int) button
{
    [sheet dismissAnimated:YES];
    if (button == 2) {
        @try {
            [connection sendCommand: cmd];
        } @catch (NSString *alert) {
            [SimpleDialog showDialog: @"Connection Error":alert];
        }
    }
}

@end
