/* TiVoContainerItem

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
#import "TiVoContainerItem.h"
#import "TiVoContainer.h"
#import "TiVoDefaults.h"

@implementation TiVoContainerItem

- (id)init
{
    [super init];
    details = [[NSMutableDictionary alloc] init];
    parentDelegate = NULL;
    currentStringValue = NULL;
    parent = NULL;
    index = -1;
    state = CONTAINER_NO_STATE;
    return self;
}

- (NSString *) getDetail:(NSString *)key
{
    return [details objectForKey:key];
}

- (void) setDetail:(NSString *)key :(NSString *) value
{
    [details setObject:value forKey:key];
}

- (void) setIndex:(int) newIndex
{
    index = newIndex;
}

- (void) setParent:(TiVoContainer *) newParent
{
    parent = newParent;
}

- (void) removeFromParent
{
NSLog(@"removing %@ %d ", [self getDetail:@"Title"], index);
    [parent removeChild:index];
}

- (NSMutableArray *) getCommands
{
    NSMutableArray *ret;
    int folderSize = 0;
    if (parent != NULL) {
        ret = [parent getCommands];
        folderSize = [parent size];
    } else {
        ret = [[NSMutableArray alloc] init];
    }
    int entriesPerPage = [[TiVoDefaults sharedDefaults] getNavigationSetting:@"Entries Per Page"];
    int i;
    int chanDowns = index / entriesPerPage;
    for (i = 0; i < chanDowns; i++) {
        [ret addObject:@"TiVo Channel Down"];
    }
    int downs = index % entriesPerPage;
    for (i = 0; i < downs; i++) {
        [ret addObject:@"TiVo Down"];
    }

    int basePage = [[TiVoDefaults sharedDefaults] getNavigationSetting:@"Base Page"];
    int folderSizeFactor = [[TiVoDefaults sharedDefaults] getNavigationSetting:@"Folder Size Factor"];
    int pageDownFactor = [[TiVoDefaults sharedDefaults] getNavigationSetting:@"Page Down Factor"];
    int downFactor = [[TiVoDefaults sharedDefaults] getNavigationSetting:@"Down Factor"];

    [ret addObject:[NSNumber numberWithInt: basePage + folderSize * folderSizeFactor + chanDowns * pageDownFactor + downs * downFactor]];
//    [ret addObject:@"TiVo Select"];

    return ret;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"Item"]) {
        // push self onto delegate stack
        parentDelegate = [parser delegate];
        [parser setDelegate:self];
    } else if ([elementName isEqualToString:@"Details"]) {
       state = CONTAINER_DETAILS;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (!currentStringValue) {
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    }

    [currentStringValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"Item"]) {
        // pop self off delegate stack
        [parser setDelegate:parentDelegate];
    } else if ([elementName isEqualToString:@"Details"]) {
        state = CONTAINER_DETAILS_FINISHED;
    } else if (state == CONTAINER_DETAILS) {
        [details setObject:currentStringValue forKey:elementName];
    }
    [currentStringValue release];
    currentStringValue = NULL;
}

- (NSComparisonResult) compareByTitle:(TiVoContainerItem *) that
{
    NSString *title1 = [TiVoContainerItem cleanTitle: [self getDetail:@"Title"]];
    NSString *title2 = [TiVoContainerItem cleanTitle: [that getDetail:@"Title"]];
    int comp = [title1 caseInsensitiveCompare: title2];
    if (comp != 0) {
        return comp;
    }
    return [[that getDetail:@"CaptureDate"] compare:[self getDetail:@"CaptureDate"]];
}

- (NSComparisonResult) compareByDate:(TiVoContainerItem *) that
{
    NSString *date1 = [self getDetail:@"CaptureDate"];
    NSString *date2 = [that getDetail:@"CaptureDate"];
    return [date2 compare:date1];
}

+ (NSString *) cleanTitle:(NSString *) title
{
    if ([title hasPrefix:@"The "]) {
        return [title substringFromIndex:4];
    } else if ([title hasPrefix:@"A "]) {
        return [title substringFromIndex:2];
    } else if ([title hasPrefix:@"An "]) {
        return [title substringFromIndex:3];
    }
    return title;
}

@end

@implementation NSMutableArray (TiVoContainerItem)
- (NSComparisonResult)compareByTitle:(NSMutableArray *)that
{
    TiVoContainerItem *item1 = [self objectAtIndex:0];
    TiVoContainerItem *item2 = [that objectAtIndex:0];
    return [item1 compareByTitle:item2];
}

- (NSComparisonResult)compareByDate:(NSMutableArray *)that
{
    TiVoContainerItem *item1 = [self objectAtIndex:0];
    TiVoContainerItem *item2 = [that objectAtIndex:0];
    return [item1 compareByDate:item2];
}
@end
