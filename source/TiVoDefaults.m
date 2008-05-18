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
#import "SimpleDialog.h"

@implementation TiVoDefaults

-(id) init
{
    [super init];
    NSMutableDictionary *temp;
    defaults = [[NSUserDefaults standardUserDefaults] retain];
    temp = [[NSMutableDictionary alloc] init];
    [temp setObject:@"192.168.1.100" forKey:@"IP Address"];
    [temp setObject:@"My TiVo" forKey:@"TiVo Name"];
    [temp setObject:@"" forKey:@"Media Access Key"];
    [temp setObject:[NSNumber numberWithInt: YES] forKey:@"TiVo Uses Groups"];
    [temp setObject:[NSNumber numberWithInt: YES] forKey:@"TiVo Sorts By Date"];
    [temp setObject:[NSNumber numberWithInt: NO] forKey:@"Show Standby"];
    [temp setObject:[[NSArray alloc] init] forKey:@"Saved Connections"];

    [defaults registerDefaults:temp];
    [temp release];

    NSString * path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"remote.xml"];
    @try {
// this crashes things?
//        dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
        dictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
        if ([dictionary count] == 0) {
            @throw @"Empty dictionary";
        }
    } @catch (id exc) {
        NSString *alertStr = [NSString stringWithFormat:@"Unable to parse file %@", path];
        [SimpleDialog showDialog:@"Parse Error":alertStr];
    }

    return self;
}

-(NSUserDefaults *) getDefaults
{
    return defaults;
}

-(NSString *) getIpAddr
{
    return [defaults stringForKey:@"IP Address"];
}

-(void) setIpAddr:(NSString *)addr
{
    if (addr != NULL && [addr compare:[self getIpAddr]]) {
        [defaults setObject:addr forKey:@"IP Address"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"IP Address" object:self];
    }
}

-(NSString *) getTiVoName
{
    return [defaults stringForKey:@"TiVo Name"];
}

-(void) setTiVoName:(NSString *)name
{
    if (name != NULL && [name compare:[self getTiVoName]]) {
        [defaults setObject:name forKey:@"TiVo Name"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TiVo Name" object:self];
    }
}

-(NSString *) getMediaAccessKey
{
    return [defaults stringForKey:@"Media Access Key"];
}

-(void) setMediaAccessKey:(NSString *)mak
{
    if (mak != NULL && [mak compare:[self getMediaAccessKey]]) {
        [defaults setObject:mak forKey:@"Media Access Key"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Media Access Key" object:self];
    }
}

-(BOOL) useGroups
{
    return [defaults boolForKey:@"TiVo Uses Groups"];
}

-(void) setUseGroups:(BOOL)use
{
    if ([self useGroups] != use) {
        [defaults setObject:[NSNumber numberWithInt: use] forKey:@"TiVo Uses Groups"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TiVo Navigation" object:self];
    }
}

-(BOOL) sortByDate
{
    return [defaults boolForKey:@"TiVo Sorts By Date"];
}

-(void) setSortByDate:(BOOL)sort
{
    if ([self sortByDate] != sort) {
        [defaults setObject:[NSNumber numberWithInt: sort] forKey:@"TiVo Sorts By Date"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TiVo Navigation" object:self];
    }
}

-(BOOL) showStandby
{
    return [defaults boolForKey:@"Show Standby"];
}

-(void) setShowStandby:(BOOL)standby
{
    if ([self showStandby] != standby) {
        [defaults setObject:[NSNumber numberWithInt: standby] forKey:@"Show Standby"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Show Standby" object:self];
    }
}

-(NSArray *) getSavedConnections
{
    return [defaults objectForKey:@"Saved Connections"];
}

-(void) setSavedConnections:(NSArray *) saved
{
    [defaults setObject:saved forKey:@"Saved Connections"];
}


-(NSDictionary *) getConnectionSettings:(NSString *)connection
{
    return [[dictionary objectForKey:@"connections"] objectForKey:connection];
}

-(NSDictionary *) getFunctionSettings:(NSString *)func
{
    return [[dictionary objectForKey:@"functions"] objectForKey:func];
}

-(NSDictionary *) getSectionSettings:(NSString *)section
{
    return [[dictionary objectForKey:@"sections"] objectForKey:section];
}

-(NSArray *) getPageSettings
{
    return [dictionary objectForKey:@"pages"];
}

-(int) getNavigationSetting:(NSString *) setting
{
    NSNumber *num = [[dictionary objectForKey:@"navigation"] objectForKey:setting];
    return [num intValue];
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
        return sharedDefaults;
    }
}

@end
