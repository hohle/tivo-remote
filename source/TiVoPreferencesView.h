// TiVoPreferencesView
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

@class TiVoDefaults;

@interface TiVoPreferencesView: UIView
{
    TiVoDefaults                  *defaults;
    UINavigationBar               *navBar;
    UITableView            *preferencesTable;
    UITableViewCell    *nameCell;
    UITableViewCell    *ipCell;
    UITableViewCell    *makCell;
    UITableViewCell *groupCell;
    UITableViewCell *sortCell;
    UITableViewCell        *add;
    UITableViewCell *standbyCell;
    NSMutableArray                *savedCells;
    NSMutableArray                *detectedCells;
    UITableViewCell        *delete;
}

- (id)initWithFrame:(struct CGRect)rect;

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable;
- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group;
- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group;
- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group;
- (void) finished;

-(BOOL) validateIP;
-(BOOL) validateMAK;

-(void) makEdited;

-(void) addSaved:(NSDictionary *)connInfo;
-(void) addDetected:(NSDictionary *)connInfo;
-(void) setData:(NSDictionary *)connInfo;
-(void) refresh:(id) param;


@end
