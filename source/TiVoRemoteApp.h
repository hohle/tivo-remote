// TiVoRemote

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

@class UIWindow;
@class UIApplication;
@class UIView;
@class UITextView;
@class UITransitionView;
@class UINavBarButton;
@class UIProgressHUD;
@class TiVoRemoteView;


enum PreferenceAnimationType;

@interface TiVoRemoteApp : UIApplication<UINavigationControllerDelegate>
{
    UIView* mainView;
    UINavigationController* navBar;
    TiVoRemoteView* remoteView;
    int page;
}

- (void)navigationBar:(UINavigationController*)navbar buttonClicked:(int)button;
- (void)setNavBarButtons;
@end
