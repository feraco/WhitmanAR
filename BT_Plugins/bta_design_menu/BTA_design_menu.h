/*
 *	Copyright 2012, PSMDanny, bt-addons.com
 *
 *	All rights reserved.
 *
 *	This software was created to use as a plugin in the buzztouch control panel software. 
 *	Some of the source code contained in this file was derived from a freely available and
 *	open source plugin package downloaded from buzztouch.com.
 *	
 *	Since this is a commercial plugin it's not allowed to resell, give away (free or not)
 *	or distribute it in any way. Modifying for own use is of course permitted.
 *
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 *	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
 *	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 *	OF SUCH DAMAGE. 
 */


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BT_viewController.h"
#import "BT_item.h"
#import "BT_downloader.h"
#import "BTA_headerImage_designMenu.h"
#import "FF_gpsar.h"

@interface BTA_design_menu : BT_viewController <BT_downloadFileDelegate, 
UITableViewDelegate,
UITableViewDataSource, UITextFieldDelegate>{
	NSMutableArray *menuItems;
    NSMutableArray *filteredMenuItems;
    NSMutableArray *displayMenuItems;
    BT_item *theParentMenuScreenData;
	BT_item *theMenuItemData;
	UITableView *myTableView;
    BTA_headerImage_designMenu *headerImageView;
	BT_downloader *downloader;
	NSString *saveAsFileName;	
	BOOL isLoading;	
	int didInit;
    UITextField *searchBox;
	NSTimer *searchTimer;
	BOOL isSearching;
    
}

@property (nonatomic, retain) NSMutableArray *menuItems;
@property (nonatomic, retain) NSMutableArray *filteredMenuItems;
@property (nonatomic, retain) NSMutableArray *displayMenuItems;
@property (nonatomic, retain) BT_item *theParentMenuScreenData;
@property (nonatomic, retain) BT_item *theMenuItemData;
@property (nonatomic, retain) UITableView *myTableView;
@property (nonatomic, retain) BTA_headerImage_designMenu *headerImageView;
@property (nonatomic, retain) NSString *saveAsFileName;
@property (nonatomic, retain) BT_downloader *downloader;
@property (nonatomic) BOOL isLoading;
@property (nonatomic) int didInit;
@property (nonatomic, retain) UITextField *searchBox;
@property (nonatomic, retain) NSTimer *searchTimer;
@property (nonatomic) BOOL isSearching;

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
-(void)headerImageTap;
-(void)loadData;
-(void)downloadData;
-(void)layoutScreen;
-(void)parseScreenData:(NSString *)theData;
-(void)checkIsLoading;
-(void)textFieldDidChange:(id)sender;

@end










