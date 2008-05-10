// TiVoDefaults
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
#import <Foundation/Foundation.h>
@class NSUserDefaults;

@interface TiVoDefaults: NSObject
{
	NSUserDefaults *defaults;
	NSDictionary   *dictionary;
}

- (id) init;

- (NSUserDefaults *)getDefaults;

- (NSString *)getIpAddr;
- (void)setIpAddr:(NSString *)addr;
- (BOOL)showStandby;
- (void)setShowStandby:(BOOL)show;

- (NSDictionary *)getConnectionSettings:(NSString *) conn;
- (NSDictionary *)getFunctionSettings:(NSString *) func;
- (NSDictionary *)getSectionSettings: (NSString *) section;
- (NSArray *)getPageSettings;

- (void)synchronize;

+ (TiVoDefaults *)sharedDefaults;
@end
