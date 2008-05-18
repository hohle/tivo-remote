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
#import <Foundation/Foundation.h>
#import <netdb.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <stdlib.h>
#import <stdio.h>
#import "TiVoBeacon.h"
#import "SimpleDialog.h"

@implementation TiVoBeacon

static TiVoBeacon *instance = NULL;

+ (TiVoBeacon *) getInstance 
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
    detected = [[NSMutableDictionary alloc] init];
    [NSThread detachNewThreadSelector:@selector(run:) toTarget:self withObject:nil];
    return self;
}

- (NSDictionary *)getDetectedTiVos
{
    return detected;
}

- (void) run:(id) param
{
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    struct sockaddr_in my_addr;
    struct sockaddr_in their_addr;
    char buf[512];
    int fd = socket (PF_INET, SOCK_DGRAM, 0);
    my_addr.sin_family = AF_INET;
    my_addr.sin_port = htons(2190);
    my_addr.sin_addr.s_addr = INADDR_ANY;
    memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);
    if (bind (fd, (struct sockaddr *) &my_addr, sizeof my_addr) == -1) {
        NSLog(@"Unable to bind listening socket!");
        return;
    }

    int numbytes;
    unsigned int addr_len = sizeof their_addr;
    while (true) {
        if ((numbytes = recvfrom(fd, buf, 512 - 1, 0, (struct sockaddr *) &their_addr, &addr_len)) == -1) {
            NSLog(@"Did not receive anything!");
            continue;
        }
        NSString *recvd = [[NSString alloc] initWithUTF8String: buf];
        NSArray *components = [recvd componentsSeparatedByString:@"\n"];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        int i = 0;
        for (i = 0; i < [components count]; i++) {
            if ([[components objectAtIndex:i] rangeOfString:@"machine"].location == 0) {
                [dict setObject:[[components objectAtIndex:i] substringFromIndex:8] forKey:@"TiVo Name"];
            }
        }
        [components release];
        [recvd release];
        NSString *ipAddr = [[NSString alloc] initWithUTF8String: (const char *)inet_ntoa(their_addr.sin_addr)];
        [dict setObject:ipAddr forKey:@"IP Address"];
        @synchronized (detected) {
            if ([detected objectForKey:ipAddr] == NULL) {
                [detected setObject:dict forKey:ipAddr];
                [self performSelectorOnMainThread: @selector(newTiVo:) withObject: NULL waitUntilDone:NO];
            } else {
                [dict release];
                [ipAddr release];
            }
        }
    }
    [autoreleasepool release];
}

-(void) newTiVo:(id) param
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"Detected TiVo" object:self];
}

@end
