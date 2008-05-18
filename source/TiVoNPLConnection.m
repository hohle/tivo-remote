/* TiVoNPLConnection

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

#import "TiVoDefaults.h"
#import "TiVoNPLConnection.h"
#import "TiVoContainerItem.h"
#import "TiVoContainer.h"
#import "SimpleDialog.h"

@interface NSURLRequest (SomePrivateAPIs)
+ (void)setAllowsAnyHTTPSCertificate:(BOOL)fp8 forHost:(id)fp12;
@end


@implementation TiVoNPLConnection

static TiVoNPLConnection *instance = NULL;

+(TiVoNPLConnection *) getInstance
{
    @synchronized (self) {
        if (instance == NULL) {
            instance = [[TiVoNPLConnection alloc] init];
        }
        return instance;
    }
}

- (id)init
{
    [super init];

    items = NULL;
    state = NPL_NO_DATA;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData:) name:@"Media Access Key" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orgChange:) name:@"TiVo Navigation" object:nil];

    [NSThread detachNewThreadSelector:@selector(run:) toTarget:self withObject:nil];
    return self;
}

- (void) run: (id) param
{
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    [self refresh];
    [autoreleasepool release];
}

- (NSData *) getNowPlayingData
{
    NSString *mak = [[TiVoDefaults sharedDefaults] getMediaAccessKey];
    NSString *ip = [[TiVoDefaults sharedDefaults] getIpAddr];

    NSError *nserror = NULL;
    @try {
        NSString *urlStr = [[NSString alloc] initWithFormat:
                    @"https://tivo:%@@%@/TiVoConnect?Command=QueryContainer&Container=%%2FNowPlaying&Recurse=Yes", 
                    mak, ip];
        NSLog(@"Using url = %@", urlStr);
        NSMutableURLRequest *theRequest=[NSMutableURLRequest 
                    requestWithURL: [NSURL URLWithString:urlStr]
                    cachePolicy:NSURLRequestUseProtocolCachePolicy
                    timeoutInterval:60.0];

        int i;
        for (i =0; i < 2; i++) {
            NSURLResponse *theResponse = NULL;
            [NSURLRequest setAllowsAnyHTTPSCertificate:YES 
                     forHost:ip];

            NSData *data =[[NSURLConnection sendSynchronousRequest: theRequest returningResponse: &theResponse error: &nserror] retain];
            if (nserror == NULL) {
                return data;
            }
            nserror = NULL;
        }
    } @catch(id exc) {
        NSLog(@"exception = %@", exc);
        NSLog(@"error = 0x%x code=%@ userInfo=%@", nserror, [nserror code], [nserror userInfo]);
    }
}

-(void) reloadData:(NSNotification *) notification
{
    [NSThread detachNewThreadSelector:@selector(run:) toTarget:self withObject:nil];
}

-(void) orgChange:(NSNotification *) notification
{
    if (state == NPL_ORGANIZED) {
        [self organize];
    }
}

- (NSArray *)getItems
{
    if (state != NPL_ORGANIZED) {
        return NULL;
    }
    return items;
}


- (void) refresh
{
    state = NPL_NO_DATA;
    NSString *mak = [[TiVoDefaults sharedDefaults] getMediaAccessKey];
    if (mak == NULL || [mak length] == 0) {
        state = NPL_ERROR;
        return;
    }
   
    NSData *data = [[self getNowPlayingData] retain];
    if (data == NULL) {
        state = NPL_ERROR;
        [self performSelectorOnMainThread: @selector(finishedOrganizing:) withObject:@"Error" waitUntilDone:NO];
        [self performSelectorOnMainThread: @selector(dataError:) withObject:@"Unable to retrieve Now Playing data" waitUntilDone:NO];
        items = NULL;
        return;
    }
    items = [[NSMutableArray alloc] init];
    Class NSXMLParserClass = NSClassFromString(@"NSXMLParser");
    NSXMLParser *xmlParser = [[[NSXMLParserClass alloc] initWithData:data] autorelease];
    [xmlParser setDelegate:self];

    state = NPL_NOT_PARSED;
    [xmlParser parse];
    state = NPL_PARSED;
    [self organize];
}

- (void) organize
{
    NSMutableArray *npl = [[NSMutableArray alloc] init];
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    NSMutableDictionary *potentialGroups = [[NSMutableDictionary alloc] init];
    BOOL suggested = NO;
    BOOL groups = [[TiVoDefaults sharedDefaults] useGroups];
    BOOL sortByDate = [[TiVoDefaults sharedDefaults] sortByDate];
    int i;
    for (i = 0; i < [items count]; i++) {
        TiVoContainerItem *item = [items objectAtIndex:i];
        // mark suggestions
        if (!suggested && i > 0) {
            NSString *prevCaptureDate = [[items objectAtIndex: i - 1] getDetail:@"CaptureDate"];
            NSString *captureDate = [item getDetail:@"CaptureDate"];
            if ([captureDate compare:prevCaptureDate] > 0) {
                suggested = YES;
            }
        }
        if (groups) {
            NSMutableArray *group = [potentialGroups objectForKey:[item getDetail:@"Title"]];
            if (group == NULL && !suggested) {
                group = [[NSMutableArray alloc] init];
                [potentialGroups setObject: group forKey:[item getDetail:@"Title"]];
                [npl addObject:group];
            }
            [group addObject:item];
        } else {
            [npl addObject:item];
        }
        if (suggested) {
            [item setDetail:@"suggested" :@"Yes"];
            [suggestions addObject:item];
        }
    }

    // TODO: sort npl
    if (!sortByDate) {
        [npl sortUsingSelector: @selector(compareByTitle:)];
    }
    if (groups) {
        [npl addObject:suggestions];
    }
    // create TiVoContainers
    TiVoContainer *nowPlaying = [[TiVoContainer alloc] init];
    for (i = 0; i < [npl count]; i++) {
       if (groups) {
           TiVoContainer *parent = nowPlaying;
           NSArray *tempGroup = [npl objectAtIndex:i];
           if ([tempGroup count] > 1) {
               parent = [[TiVoContainer alloc] init];
               [nowPlaying addChild:parent];
           }
           int j;
           for (j = 0; j < [tempGroup count]; j++) {
               TiVoContainerItem *item = [tempGroup objectAtIndex:j];
               [parent addChild:item];
           }
       } else {
           TiVoContainerItem *item = [npl objectAtIndex:i];
           [nowPlaying addChild:item];
       }
    }
    state = NPL_ORGANIZED;
    [self performSelectorOnMainThread: @selector(finishedOrganizing:) withObject:NULL waitUntilDone:NO];
}

- (int) getState
{
    return state;
}

- (void)finishedOrganizing:(id) param
{
    if (param == NULL) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Now Playing Data" object:self];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Now Playing Data" object:self];
    }
}
- (void) dataError:(NSString *) errmsg
{
    [SimpleDialog showDialog:@"NPL Error" :errmsg];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"Item"]) {
        state = NPL_ITEMS;
        TiVoContainerItem *item = [[TiVoContainerItem alloc] init];
        [items addObject:item];
        [item parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
}

@end
