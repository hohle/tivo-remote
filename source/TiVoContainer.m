/* TiVoContainer

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
#import "TiVoContainer.h"
#import "TiVoDefaults.h"

@implementation TiVoContainer

- (id)init
{
    [super init];
    children = [[NSMutableArray alloc] init];
    return self;
}

-(NSMutableArray *)getCommands
{
    NSMutableArray *ret;
    if (parent != NULL) {
        ret = [super getCommands];
        [ret addObject:@"TiVo Select"];
        int pageLoad = [[TiVoDefaults sharedDefaults] getNavigationSetting:@"Page Load"];
        [ret addObject:[NSNumber numberWithInt: pageLoad]];
    } else {
        ret = [[NSMutableArray alloc] init];
        [ret addObject:@"TiVo Now Playing"];
        int nowPlayingLoad = [[TiVoDefaults sharedDefaults] getNavigationSetting:@"Now Playing Load"];
        [ret addObject:[NSNumber numberWithInt: nowPlayingLoad]];
    }
    int entriesPerPage = [[TiVoDefaults sharedDefaults] getNavigationSetting:@"Entries Per Page"];
    int numPages = ([children count] / entriesPerPage) + 1;

    int i;
    for (i = 0; i < numPages; i++) {
        [ret addObject:@"TiVo Channel Up"];
    }

    return ret;
}

- (void) addChild: (TiVoContainerItem *) child
{
    [child setParent:self];
    [child setIndex: [children count]];
    [children addObject:child];
}

- (int) size
{
    return [children count];
}
@end
