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
                    timeoutInterval:15.0];

        int i;
        for (i =0; i < 2; i++) {
            NSURLResponse *theResponse = NULL;
            [NSURLRequest setAllowsAnyHTTPSCertificate:YES 
                     forHost:ip];

            NSData *data =[[NSURLConnection 
                               sendSynchronousRequest: theRequest 
                               returningResponse: &theResponse 
                               error: &nserror] retain];
            if (nserror == NULL) {
                return data;
            }
            if ([nserror code] != NSURLErrorServerCertificateUntrusted) {
                return NULL;
            }
            nserror = NULL;
        }
    } @catch(id exc) {
        NSLog(@"exception = %@", exc);
        NSLog(@"error = 0x%x code=%d userInfo=%@", nserror, [nserror code], [nserror userInfo]);
    }
    return NULL;
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
        state = NPL_NO_CONNECTION;
        return;
    }
   
    NSData *data = [[self getNowPlayingData] retain];
    if (state != NPL_NO_DATA) {
        // there must be some other request changing our state
        return;
    }
    if (data == NULL) {
        state = NPL_ERROR;
        [self performSelectorOnMainThread: @selector(finishedOrganizing:) 
                      withObject:@"Error" waitUntilDone:NO];
        [self performSelectorOnMainThread: @selector(dataError:) 
                      withObject:@"Unable to retrieve Now Playing data" 
                      waitUntilDone:NO];
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
    NSMutableArray *hdrecordings = [[NSMutableArray alloc] init];
    NSMutableDictionary *potentialGroups = [[NSMutableDictionary alloc] init];
    BOOL suggested = NO;
    BOOL groups = [[TiVoDefaults sharedDefaults] useGroups];
    BOOL sortByDate = [[TiVoDefaults sharedDefaults] sortByDate];
    int i;
    for (i = 0; i < [items count]; i++) {
        TiVoContainerItem *item = [items objectAtIndex:i];

        // determine if this is the start of the suggested recordings
        if (!suggested && i > 0) {
            NSString *prevCaptureDate = [[items objectAtIndex: i - 1] getDetail:@"CaptureDate"];
            NSString *captureDate = [item getDetail:@"CaptureDate"];

            // first suggestion will have a capture date more recent than
            // the previous entry.
            if ([captureDate compare:prevCaptureDate] > 0) {
                suggested = YES;
            }
        }
        if (groups) {
            NSMutableArray *group = [potentialGroups objectForKey:[item getDetail:@"Title"]];
            // suggested items do not create new groups, but can be added to
            // existing groups
            if (group == NULL && !suggested) {
                // group does not exist already
                group = [[NSMutableArray alloc] init];
                [potentialGroups setObject: group forKey:[item getDetail:@"Title"]];
                [npl addObject:group];
            }
            [group addObject:item];

            // while the results are sorted by date, suggested recordings are
            // separated from normal recordings, groups need to have those
            // suggested recordings in their appropriate date sorted position.
            [group sortUsingSelector: @selector(compareByDate:)];

            if ([[item getDetail:@"HighDefinition"] isEqualToString:@"Yes"]) {
                [hdrecordings addObject:item];
            }
        } else {
            // no groups, add everything to npl
            [npl addObject:item];
        }
        // mark suggestions
        if (suggested) {
            [item setDetail:@"suggested" :@"Yes"];
            [suggestions addObject:item];
        }
    }

    if (sortByDate && groups) {
        // if a group has a suggested recording as the most recent element,
        // we need to make sure that this group is sorted according to that
        // suggested recording
        [npl sortUsingSelector: @selector(compareByDate:)];
    } else if (!sortByDate) {
        // sort by alpha
        [npl sortUsingSelector: @selector(compareByTitle:)];
    }
    if (groups) {
        // now that the npl is sorted, add the hd and suggested folders
        if ([hdrecordings count] > 0) {
            [npl addObject:hdrecordings];
        }
        [npl addObject:suggestions];
    }
    // create TiVoContainers
    TiVoContainer *nowPlaying = [[TiVoContainer alloc] init];
    for (i = 0; i < [npl count]; i++) {
       if (groups) {
           TiVoContainer *parent = nowPlaying;
           NSArray *tempGroup = [npl objectAtIndex:i];
           // if our array has more than one element, create a new group for it
           // it will be the parent for each element in the array
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

- (void) removeItem:(TiVoContainerItem *) item
{
    [item removeFromParent];
    int index = [items indexOfObject:item];
    if (index >= 0) {
        [items removeObjectAtIndex:index];
    }
    [self performSelectorOnMainThread: @selector(finishedOrganizing:) withObject:NULL waitUntilDone:NO];
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
