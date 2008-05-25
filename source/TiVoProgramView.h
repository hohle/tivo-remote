// TiVoProgramView
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
#import <UIKit/UIPreferencesTable.h>
#import <UIKit/UIPreferencesTextTableCell.h>
#import <UIKit/UIImageAndTextTableCell.h>
#import <UIKit/UIAlertSheet.h>

@class TiVoContainerItem;

@interface TiVoProgramView: UIView
{
    TiVoContainerItem *item;
    UIPreferencesTable *detailTable;
    UIPreferencesTextTableCell    *descriptionCell;
    UIPreferencesTextTableCell    *durationCell;
    UIPreferencesTextTableCell    *stationCell;
    UIPreferencesTextTableCell    *hdCell;
    UIPreferencesTextTableCell    *captureCell;
    UIPreferencesTableCell    *play;
    UIPreferencesTableCell    *delete;
    UIAlertSheet              *alertSheet;
}

- (id)initWithFrame:(struct CGRect)rect :(TiVoContainerItem*) item;

@end
