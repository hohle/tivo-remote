// TiVoButton
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
#import <UIKit/UIAlertSheet.h>
#import "ConnectionManager.h"

@class UIPushButton;

@interface TiVoButton: UIPushButton
{
	char             *cmd;
	id <RemoteConnection> connection;
	UIAlertSheet    *alertSheet;
        BOOL             confirm;
}

- (id) initWithTitle: (NSString *)title;
- (char *) getCommand;
- (void) setCommand: (char *) command;
- (void) buttonEvent:(UIPushButton *) button;
- (void) setConfirm:(BOOL) conf;
- (void) showAlert:(NSString *) alert:(BOOL) conf;

@end
