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

#import "TiVoButton.h"
#import "TiVoDefaults.h"
#import "ConnectionManager.h"
#import "SimpleDialog.h"

@implementation TiVoButton
- (id)initButton:(NSDictionary *) buttonProps
{
    if (self = [super init])
    {
        [self setTitle: [buttonProps objectForKey: @"title"] forState: UIControlStateNormal];
        [self setAutoresizesSubviews: NO];
        
        UIImage *buttonImg = [UIImage imageNamed:[buttonProps objectForKey:@"icon"]];
        UIImage *pressedImg = buttonImg;
        NSString *pressedIcon = [buttonProps objectForKey:@"pressed-icon"];
        if (pressedIcon != NULL) {
            pressedImg = [UIImage imageNamed:[buttonProps objectForKey:@"pressed-icon"]];
        }
        
        functionKey = [buttonProps objectForKey:@"function"];
        confirm = [buttonProps objectForKey:@"confirm"];
        
        //    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        //    float backParts[4] = {0, 0, 0, .9};
        //    [self setTitleColor : CGColorCreate( colorSpace, backParts) forState:0];
        //2.0
        [self setTitleColor : [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.9]
                    forState: UIControlStateNormal];
        
        // [self setDrawContentsCentered: YES];
        [self setBackgroundImage: buttonImg forState: UIControlStateNormal];
        // [self setBackground:buttonImg forState:0];
        [self setBackgroundImage: pressedImg forState: UIControlStateSelected];
        // [self setBackground:pressedImg forState:1];
        [self addTarget: self action: @selector(buttonEvent:) forControlEvents: UIControlEventTouchDown];
        // [self addTarget: self action:@selector(buttonEvent:) forEvents:1];
        
        int xCoord = [[buttonProps objectForKey:@"xCoord"] intValue];
        int yCoord = [[buttonProps objectForKey:@"yCoord"] intValue];
        [self setFrame:  CGRectMake(xCoord, yCoord,  [buttonImg size].width, [buttonImg size].height)];
        
        connection = [[ConnectionManager getInstance] getConnection: [buttonProps objectForKey:@"connection"]];
        
        
    }
    return self;
}

- (void) buttonEvent:(UIButton *) button
{
    if (confirm != NULL) {
        [self showConfirm:confirm];
    } else {
        @try {
            [connection sendCommand: functionKey];
        } @catch (NSString *alert) {
            [SimpleDialog showDialog: @"Connection Error":alert];
        }
    }
}

- (void)showConfirm:(NSString *) alert
{
    NSString *bodyText = [NSString stringWithFormat:alert];
    CGRect rect = [[UIScreen mainScreen] bounds];
    alertSheet = [[UIActionSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
    [alertSheet setTitle:@"Alert!"];
    // TODO add as UILabel
    //[alertSheet setBodyText:bodyText];
    [alertSheet addButtonWithTitle:@"Cancel"];
    [alertSheet addButtonWithTitle:@"OK"];
    [alertSheet setDelegate: self];
    // [alertSheet popupAlertAnimated:YES];
    // TODO: Verify
    [alertSheet showInView: [[UIApplication sharedApplication] keyWindow]];
}

- (void)alertSheet:(UIActionSheet *)sheet buttonClicked:(int) button
{
    [sheet dismissWithClickedButtonIndex: button animated: YES];
    if (button == 2) {
        @try {
            [connection sendCommand: functionKey];
        } @catch (NSString *alert) {
            [SimpleDialog showDialog: @"Connection Error":alert];
        }
    }
}

@end
