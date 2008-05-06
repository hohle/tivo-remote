// TiVoRemoteView
/*

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
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TiVoConnection.h"

@class UIView;
@class UIImageView;
@class UISliderControl;

#define WIDTH 5
#define HEIGHT 8

@interface TiVoRemoteView : UIView
{
	TiVoConnection *connection;
	int             page;
	NSMutableArray *buttons;
	int	        butWidth;
	int             butHeight;
	UIAlertSheet   *alertSheet;
}

- (id)initWithFrame:(struct CGRect)rect;
- (void)buttonEvent:(UIPushButton *)button;
- (void)setPage:(int) page;
- (void)addButton:(int) xLoc :(int) yLoc: (NSString *) title: (char *)cmd;
- (void)showAlert:(NSString *)alert;
- (void)close;

@end
