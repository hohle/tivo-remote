/* TiVoDefaults

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

#import <stdio.h>
#import "TiVoDefaults.h"

@implementation TiVoDefaults

-(id) init
{
    [super init];
    NSMutableDictionary *temp;
    defaults = [[NSUserDefaults standardUserDefaults] retain];
    temp = [[NSMutableDictionary alloc] init];
    [temp setObject:@"192.168.1.100" forKey:@"IP Address"];

    [defaults registerDefaults:temp];
    [temp release];
    return self;
}
-(NSString *) getIpAddr
{
    return [defaults stringForKey:@"IP Address"];
}

-(void) setIpAddr:(NSString *)addr
{
    if (addr != NULL) {
        [defaults setObject:addr forKey:@"IP Address"];
    }
}

-(void) synchronize
{
    [defaults synchronize];
}

static TiVoDefaults *sharedDefaults = NULL;

+ (TiVoDefaults *) sharedDefaults
{
    @synchronized(self) {
        if (sharedDefaults == NULL) {
            sharedDefaults = [[self alloc] init];
        }
    }
    return sharedDefaults;
}

@end
