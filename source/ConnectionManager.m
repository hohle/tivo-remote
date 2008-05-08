/* ConnectionManager

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
#import <Foundation/NSEnumerator.h>
#import <stdio.h>
#import "ConnectionManager.h"
#import "TiVoConnection.h"

@implementation ConnectionManager

static ConnectionManager *instance = NULL;

+ (ConnectionManager *) getInstance 
{
    @synchronized(self) {
        if (instance == NULL) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}

- (id)init
{
    connections = [[NSMutableDictionary alloc] init];
    return self;
}

- (void)close
{
    NSEnumerator *enumerator = [connections keyEnumerator];
    NSString *key;
    while ( key = [enumerator nextObject] ) {
        [[connections objectForKey: key] close];
    }
}

- (id <RemoteConnection>)getConnection:(NSString *) connName
{
    id<RemoteConnection> conn = [connections objectForKey: connName];
    if (conn == NULL) {
        conn = [[TiVoConnection alloc] init];
        [connections setObject: conn forKey: connName];
    }
    return conn;
}

@end
