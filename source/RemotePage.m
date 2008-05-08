/* TiVoRemoteView

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
#import <Foundation/NSArray.h>
#import <Foundation/NSEnumerator.h>

#import "RemotePage.h"
#import "TiVoButton.h"

@implementation RemotePage
- (id)initWithFrame:(struct CGRect)rect
{
    [super initWithFrame:rect];
    buttons = [[NSMutableArray alloc] init];
    return self;
}

-(void) clear
{
    NSEnumerator *enumerator = [buttons objectEnumerator];
    TiVoButton *button;
    while (button = [enumerator nextObject]) {
        [button removeFromSuperview];
        [button release];
    }
    [buttons removeAllObjects];
}

-(void) addButton:(TiVoButton *) button
{
    [self addSubview:button];
    [buttons addObject:button];
}

@end
