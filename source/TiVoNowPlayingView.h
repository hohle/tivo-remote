// TiVoNowPlayingView
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
#import <UIKit/UIView.h>
#import <UIKit/UIView-Hierarchy.h>
#import <UIKit/UITextView.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UINavigationItem.h>
#import <UIKit/UIProgressHUD.h>
#import <UIKit/UIImageAndTextTableCell.h>

@interface TiVoNowPlayingView: UIView
{
    UINavigationBar *navBar;
    UINavigationBar *bottomNavBar;
    UINavigationItem *navItem;
    UIProgressHUD   *progress;
    UITable         *nowPlayingTable;
    UITableColumn   *col;
    UITextView      *detailView;
    NSMutableArray  *cells;
    NSMutableArray  *model;
}

- (id)initWithFrame:(struct CGRect)rect;
- (void) refresh:(id) param;

@end

@interface TiVoContainerItemTableCell:UIImageAndTextTableCell
{
    id value;
}
-(void)setValue:(id) value;
-(id)getValue;
@end
