/* TiVoBrowser

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

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>
#import <CoreGraphics/CoreGraphics.h>
#import <GraphicsServices/GraphicsServices.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UITable.h>
#import <UIKit/UIHardware.h>
#import <UIKit/UITableColumn.h>

#import "TiVoBrowser.h"

@implementation TiVoBrowser

- (id)initWithFrame:(struct CGRect)rect :(NSArray *)theCells
{
    [super initWithFrame:rect];

    browserTable = [[UITable alloc] initWithFrame:rect];
    [browserTable setDataSource:self];
    [browserTable setSeparatorStyle:1];

    col = [[UITableColumn alloc] initWithTitle:@"Browser" identifier:@"browser" width:rect.size.width];
    [browserTable addTableColumn:col];

    cells = theCells;
    [self refresh:NULL];

    [self addSubview:browserTable];
    return self;
}

- (void) table:(UITable *) table deleteRow:(int) row 
{
}

- (BOOL) table:(UITable *) table canDeleteRow:(int) row 
{
    return NO;
}

- (void) refresh:(id) param
{
    [browserTable reloadData];
}

-(UITableCell*)table:(UITable*)table cellForRow:(int)row column:(UITableColumn *)column
{
    return [cells objectAtIndex:row];
}

-(int)numberOfRowsInTable:(UITable *) table
{
    return [cells count];
}

-(UITable *)getTable
{
    return browserTable;
}

-(void)setCells:(NSArray *)theCells
{
    cells = theCells;
    [self refresh:NULL];
}

- (void)dealloc
{
    [browserTable release];
    [col release];
    [super dealloc];
}

@end
