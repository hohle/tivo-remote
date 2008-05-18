// TiVoContainerItem
/*

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

#import<Foundation/Foundation.h>

enum {
    CONTAINER_NO_STATE = 0,
    CONTAINER_DETAILS,
    CONTAINER_DETAILS_FINISHED,
    CONTAINER_LINK,
    CONTAINER_LINK_FINISHED
};

@class TiVoContainer;

@interface TiVoContainerItem: NSObject
{
	NSMutableDictionary *details;
	id                   parentDelegate;
	NSMutableString     *currentStringValue;

	int                  index;
	TiVoContainer       *parent;

        int                  state;
}

- (id)init;

- (NSString *) getDetail:(NSString *)key;
- (void) setDetail:(NSString *)key :(NSString *) value;
- (NSMutableArray *) getCommands;

- (void) setIndex: (int) index;
- (void) setParent: (TiVoContainer *) parent;

+ (NSString *)cleanTitle:(NSString *)title;

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict;

@end

@interface NSMutableArray (TiVoContainerItem)
- (NSComparisonResult)compareByTitle:(NSMutableArray *)that;
@end

