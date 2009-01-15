/* TiVoConnection

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
#import <netdb.h>
#import <sys/types.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <stdlib.h>
#import <stdio.h>
#import <string.h>
#include <sys/time.h>

#import "TiVoDefaults.h"
#import "TiVoConnection.h"

@implementation TiVoConnection

- (id)initWithName:(NSString *)connName
{
    [super init];
    fd = -1;
    defaults = [TiVoDefaults sharedDefaults];
    NSDictionary *connSettings = [defaults getConnectionSettings:connName];
    ipField = [connSettings objectForKey:@"ipField"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connChange:) name:ipField object:nil];
    return self;
}

- (int)getSocket
{
    if (fd < 0) {
        struct hostent *he;
        struct sockaddr_in their_addr; // connector's address information 
        long arg;

        he = (struct hostent *)gethostbyname([[defaults getIpAddr] UTF8String]);
        their_addr.sin_family = AF_INET;
        their_addr.sin_port = htons(31339);
        their_addr.sin_addr = *((struct in_addr *) he->h_addr);
        memset(their_addr.sin_zero, '\0', sizeof their_addr.sin_zero);

        fd = socket(PF_INET, SOCK_STREAM, 0);
        if (fd >= 0) {
            arg = fcntl(fd, F_GETFL, NULL);
            if (arg < 0) {
                [self close];
                @throw @"fcntl get failed.";
            }
            arg |= O_NONBLOCK;
            if (fcntl(fd, F_SETFL, arg) < 0) {
                [self close];
                @throw @"fcntl set failed.";
            }
            int res = connect(fd, (struct sockaddr *) &their_addr, sizeof their_addr);
            if (res < 0) {
                fd_set myset;
                struct timeval tv; 
                int valopt;
                if (errno == EINPROGRESS || 1) {
                    tv.tv_sec = 1; 
                    tv.tv_usec = 0; 
                    FD_ZERO(&myset); 
                    FD_SET(fd, &myset);
                    res = select (fd + 1, NULL, &myset, NULL, &tv);
                    if (res > 0) {
                        unsigned int lon = sizeof(int);
                        getsockopt(fd, SOL_SOCKET, SO_ERROR, (void*)(&valopt), &lon);
                        if (valopt) {
                            [self close];
                            @throw @"getsockopt failed.";
                        }
                    } else {
                        [self close];
                        @throw @"Unable to connect to socket.";
                    }
                }
            }
            arg = fcntl(fd, F_GETFL, NULL); 
            arg &= (~O_NONBLOCK); 
            fcntl(fd, F_SETFL, arg); 
            gettimeofday(&lastCmdSent, NULL);
        } else {
            @throw @"Unable to create socket.";
        }
    }
    return fd;
}

-(void)waitForResponse:(int) sockFD :(NSString *)expectedResponse
{
    const char *exp = [expectedResponse UTF8String];
    struct timeval tv;
    fd_set readfds;
    tv.tv_sec = 0;
    tv.tv_usec = 50000;
    int i;
    for (i = 0; i < 40; i++) {
        FD_ZERO(&readfds);
        FD_SET(sockFD, &readfds);
        select(sockFD + 1, &readfds, NULL, NULL, &tv);
        if (FD_ISSET(sockFD, &readfds)) {
            char response[128]; 
            int numBytes = read(sockFD, response, 128);
            if (numBytes > 0) {
                NSLog(@"received '%s' (%d)", response, numBytes);
              
                if (expectedResponse == NULL || strstr(response, exp)) {
                    return;
                }
            }
        }
        if (expectedResponse == NULL) {
            return;
        }
    }
    @throw @"Did not receive response.";
}

- (void)close
{
    if (fd >= 0) {
NSLog(@"Closing");
        close(fd);;
        fd = -1;
    }
}

- (void)sendCommand:(NSString *) functionKey
{
    if (functionKey == NULL) {
        return;
    }
    NSDictionary *function = [defaults getFunctionSettings:functionKey];
    const char *buffer = [[NSString stringWithFormat:@"%@\r", [function objectForKey:@"command"]] UTF8String];
    NSLog(@"sending '%s' (%d)", buffer, strlen(buffer));
    int sockFD = [self getSocket];
    @synchronized (self) {
        struct timeval curTime;
        gettimeofday(&curTime, NULL);
        int diff = (curTime.tv_sec - lastCmdSent.tv_sec) * 1000 
             + ((curTime.tv_usec / 1000) - (lastCmdSent.tv_usec / 1000));
        if (diff < 50) {
            NSLog(@"Sleeping for %d", 50 - diff);
            usleep( (50 - diff) * 1000);
        }
        if (sockFD>= 0) {
            send(sockFD, buffer, strlen(buffer), 0);
            gettimeofday(&lastCmdSent, NULL);
            [self waitForResponse:sockFD :[function objectForKey:@"response"]];
        }
    }
}

- (void)batchSend:(NSArray *) functions
{
    int i;
    for (i = 0; i < [functions count]; i++) {
        if ([[functions objectAtIndex:i] isKindOfClass:[NSString class]]) {
            [self sendCommand:[functions objectAtIndex:i]];
        } else {
            int sleepTime = [[functions objectAtIndex:i] intValue];
            usleep(1000 * sleepTime);
        }
    }
}

-(void) connChange:(NSNotification *) notification
{
    [self close];
}

@end
