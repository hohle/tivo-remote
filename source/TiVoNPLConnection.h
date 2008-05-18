// TiVoNPLConnection
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

enum {
        NPL_ERROR = -1,
        NPL_NO_DATA = 0,
	NPL_NOT_PARSED,
        NPL_ITEMS,
        NPL_ITEMS_FINISHED,
        NPL_PARSED,
        NPL_ORGANIZED
};

@interface TiVoNPLConnection: NSObject
{
	NSMutableArray *items;
	int             state;
}

- (id)init;
- (void)refresh;
- (void)organize;
-(void) reloadData:(NSNotification *) notification;
- (NSArray *)getItems;
- (NSData *)getNowPlayingData;
- (int) getState;

+ (TiVoNPLConnection *)getInstance;

@end
