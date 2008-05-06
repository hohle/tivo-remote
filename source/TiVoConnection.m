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

#import "TiVoDefaults.h"
#import "TiVoConnection.h"

@implementation TiVoConnection

- (id)init
{
    fd = -1;
    defaults = [TiVoDefaults sharedDefaults];
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
        } else {
            @throw @"Unable to create socket.";
        }
    }
    return fd;
}

- (void)close
{
    if (fd >= 0) {
NSLog(@"Closing");
        close(fd);;
        fd = -1;
    }
}

- (void)sendCommand:(char *) cmd
{
    if (cmd == NULL) {
        return;
    }
    char *buffer = malloc(25);
    sprintf(buffer, "IRCODE %s\r\n", cmd);
    NSLog(@"sending '%s' (%d)", buffer, strlen(buffer));
    int sockFD = [self getSocket];
    if (sockFD>= 0) {
        send(sockFD, buffer, strlen(buffer), 0);
    }
}

@end
