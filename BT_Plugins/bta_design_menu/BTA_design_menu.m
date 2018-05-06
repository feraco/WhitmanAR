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

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JSON.h"
#import "BT_fileManager.h"
#import "BT_color.h"
#import "whitmanar_appDelegate.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_downloader.h"
#import "BT_item.h"
#import "BT_device.h"
#import "BT_debugger.h"
#import "BTA_cell_designmenu.h"
#import "BTA_headerImage_designMenu.h"
#import "BTA_design_menu.h"
#import "FLAnimatedImage.h"
#import "FLAnimatedImageView.h"

@interface BTA_design_menu () {
    BOOL shouldLoadLocations;
}
@end

@implementation BTA_design_menu
@synthesize menuItems, myTableView, headerImageView, theParentMenuScreenData, theMenuItemData;
@synthesize saveAsFileName, downloader, isLoading, didInit;
@synthesize filteredMenuItems, displayMenuItems;
@synthesize searchBox, searchTimer, isSearching;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

//viewDidLoad
-(void)viewDidLoad {
    [BT_debugger showIt:self theMessage:@"viewDidLoad"];
    [super viewDidLoad];
    
    shouldLoadLocations = NO;
    
    //init screen properties
    [self setDidInit:0];
    
    //flag not loading
    [self setIsLoading:FALSE];
    
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //build the table that holds the menu items.
    self.myTableView = [BT_viewUtilities getTableViewForScreen:[self screenData]];
    self.myTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.myTableView setDataSource:self];
    [self.myTableView setDelegate:self];
    
    
    //prevent scrolling?
    if([[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"preventAllScrolling" defaultValue:@""] isEqualToString:@"1"]){
        [self.myTableView setScrollEnabled:FALSE];
    }
    [self.view addSubview:myTableView];
    
    
    ////////////////////////////////////////////////////////////////////////////////////////
    //if we have a headerImageName, create a BT_image_header_view with this screens data
    // this is added "before" the table so the table is on top of it.
    BOOL addHeaderImage = FALSE;
    NSString *headerImageName = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"headerImageNameSmallDevice" defaultValue:@""];
    NSString *headerImageURL = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"headerImageURLSmallDevice" defaultValue:@""];
    
    
    if([headerImageName length] > 3 || [headerImageURL length] > 3){
        addHeaderImage = TRUE;
    }
    
    if(addHeaderImage){
        whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];
        appDelegate.rootApp.currentScreenData = self.screenData;
        
        //create an image view from the screen data..It will size itself.
        headerImageView = [[BTA_headerImage_designMenu alloc] initWithScreenData:self.screenData];
        headerImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        
        //does header image scroll with the table?
        if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"headerImageScrollWithList" defaultValue:@"1"] isEqualToString:@"0"]){
            //add as sub-view
            if([appDelegate.rootDevice isIPad]){
                [self.view addSubview:headerImageView];
                [self.myTableView setFrame:CGRectMake(0, headerImageView.imageHeight, 768, 1024)];
            }else{
                [self.view addSubview:headerImageView];
                CGRect screenRect = [[UIScreen mainScreen] bounds];
                //CGFloat screenWidth = screenRect.size.width;
                CGFloat screenHeight = screenRect.size.height;
                [self.myTableView setFrame:CGRectMake(0, headerImageView.imageHeight, 320, screenHeight-headerImageView.imageHeight)];
            }
        }else{
            //add as table view header
            [self.myTableView setTableHeaderView:headerImageView];
            
        }
        
    }
    //end if using header image
    
    //create adView?
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"includeAds" defaultValue:@"0"] isEqualToString:@"1"]){
        [self createAdBannerView];
    }
    
}


//view will appear
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [BT_debugger showIt:self theMessage:@"viewWillAppear"];
    
    //do we want to use the search function?
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"searchdesignMenu" defaultValue:@"0"] isEqualToString:@"1"]){
        
        //custom view for title so we can insert a search bar
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 40)];
        [titleView setTag:88];
        titleView.backgroundColor = [UIColor clearColor];
        
        //left view for search box
        UIImageView *searchImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"DMsearch.png"]];
        
        //search hint...
        NSString *searchHint = NSLocalizedString(@"search", "search...");
        if(![[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"searchHint" defaultValue:@""] isEqualToString:@""]){
            searchHint = [BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"searchHint" defaultValue:@""];
        }
        
        //if we already searched reset the search hint (happens when coming "back" to this screen)
        NSString *searchdesignmenuText = @"";
        if([[BT_strings getPrefString:@"currentdesignmenuSearchValue"] length] > 0){
            searchdesignmenuText = [BT_strings getPrefString:@"currentdesignmenuSearchValue"];
        }
        
        
        //we have to have a unique search identifier to be able to use multiple searches in one designmenu.
        //This is on the todolist
        //NSString *uniqueSearch = [BT_strings getJsonPropertyValue:self.screenData.jsonVars:@"uniqueSearchIdentifier":@""];
        //[BT_debugger showIt:self:[NSString stringWithFormat:@"Unique search: %@", uniqueSearch]];
        
        
        //searchBar in title view
        searchBox = [[UITextField alloc] initWithFrame:CGRectMake(0, 5, 195, 30)];
        searchBox.clearButtonMode = UITextFieldViewModeAlways;
        searchBox.tag = 199;
        searchBox.text = searchdesignmenuText;
        searchBox.placeholder = searchHint;
        searchBox.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        searchBox.textColor = [UIColor blackColor];
        searchBox.font = [UIFont systemFontOfSize:14];
        searchBox.keyboardType = UIKeyboardTypeDefault;
        searchBox.borderStyle = UITextBorderStyleRoundedRect;
        searchBox.autocorrectionType = UITextAutocorrectionTypeNo;
        searchBox.autocapitalizationType = UITextAutocapitalizationTypeNone;
        searchBox.keyboardAppearance = UIKeyboardAppearanceAlert;
        searchBox.leftViewMode = UITextFieldViewModeAlways;
        searchBox.returnKeyType = UIReturnKeyDone;
        searchBox.leftView = searchImgView;
        searchBox.delegate = self;
        [searchBox addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        [titleView addSubview:searchBox];
        self.navigationItem.titleView = titleView;
    }//end search function
    
    //if we have not yet inited data..
    if(self.didInit == 0){
        [self performSelector:(@selector(loadData)) withObject:nil afterDelay:0.1];
        [self setDidInit:1];
    }
    
    //show adView?
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"includeAds" defaultValue:@"0"] isEqualToString:@"1"]){
        [self showHideAdView];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"HERE 1");
    NSLog(@"shouldLoadLocations 1 = %@", @(shouldLoadLocations));
    shouldLoadLocations = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldLoadLocations"];
    if (shouldLoadLocations == YES) {
        NSLog(@"HERE 2");
        shouldLoadLocations = NO;
        
        NSString *itemId = [[NSUserDefaults standardUserDefaults] objectForKey:@"destinationIdToLoad"];
        [self loadScreenWithItemId:itemId];
        
        [[NSUserDefaults standardUserDefaults] setBool:shouldLoadLocations forKey:@"shouldLoadLocationId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void)loadLocations {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    [self loadScreenFromRow:indexPath];
}

#pragma mark Animated Background
//Override Background top utilise animated background
-(void)configureBackground{
    whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];
    NSString * smallImageString = [BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"backgroundImageNameSmallDevice" defaultValue:@""];
    NSString * largeImageString = [BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"backgroundImageNameLargeDevice" defaultValue:@""];
    
    NSString *imageSize = @"";
    if (appDelegate.rootDevice.isIPad) {
        imageSize = largeImageString;
    }else{
        imageSize = smallImageString;
    }
    
    BOOL isGif = [[imageSize pathExtension]isEqualToString:@"gif"];
    NSString* imageName  = [[imageSize lastPathComponent] stringByDeletingPathExtension];
    
    if (isGif) {
        [self setAnimatedBackgroundWith:imageName];
    }else{
        [super configureBackground];
    }
}

-(void)setAnimatedBackgroundWith:(NSString*)fileName{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"gif"];
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:filePath options:0 error:&error];
    FLAnimatedImage *image = [[FLAnimatedImage alloc]initWithAnimatedGIFData:data];
    FLAnimatedImageView  *gifBackground  = [[FLAnimatedImageView alloc]initWithFrame:self.view.bounds];
    gifBackground.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    gifBackground.animatedImage = image;
    [self.view addSubview:gifBackground];
    [self.view insertSubview:gifBackground atIndex:0];
}

//header image tapped
-(void)headerImageTap{
    [BT_debugger showIt:self theMessage:@"headerImageTap"];
    
    //appDelegate
    whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];
    
    //get possible itemId of the screen to load
    NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"headerImageTapLoadScreenItemId" defaultValue:@""];
    
    //get possible nickname of the screen to load
    NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"headerImageTapLoadScreenNickname" defaultValue:@""];
    
    //bail if load screen = "none"
    if([loadScreenItemId isEqualToString:@"none"]){
        return;
    }
    
    //check for loadScreenWithItemId THEN loadScreenWithNickname THEN loadScreenObject
    BT_item *screenObjectToLoad = nil;
    if([loadScreenItemId length] > 1){
        screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
    }else{
        if([loadScreenNickname length] > 1){
            screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
        }else{
            if([self.screenData.jsonVars objectForKey:@"headerImageTapLoadScreenObject"]){
                screenObjectToLoad = [[BT_item alloc] init];
                [screenObjectToLoad setItemId:[[self.screenData.jsonVars objectForKey:@"headerImageTapLoadScreenObject"] objectForKey:@"itemId"]];
                [screenObjectToLoad setItemNickname:[[self.screenData.jsonVars objectForKey:@"headerImageTapLoadScreenObject"] objectForKey:@"itemNickname"]];
                [screenObjectToLoad setItemType:[[self.screenData.jsonVars objectForKey:@"headerImageTapLoadScreenObject"] objectForKey:@"itemType"]];
                [screenObjectToLoad setJsonVars:[self.screenData.jsonVars objectForKey:@"headerImageTapLoadScreenObject"]];
            }
        }
    }
    
    //load next screen if it's not nil
    if(screenObjectToLoad != nil){
        
        //build a temp menu-item to pass to screen load method. We need this because the transition type is in the menu-item
        BT_item *tmpMenuItem = [[BT_item alloc] init];
        
        //build an NSDictionary of values for the jsonVars property
        NSDictionary *tmpDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"unused", @"itemId",
                                       [self.screenData.jsonVars objectForKey:@"headerImageTapLoadScreenTransitionType"], @"transitionType",
                                       nil];
        [tmpMenuItem setJsonVars:tmpDictionary];
        [tmpMenuItem setItemId:@"0"];
        
        //load the next screen
        [self handleTapToLoadScreen:screenObjectToLoad theMenuItemData:tmpMenuItem];
        
        
    }else{
        //show message
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
    }
    
}


//load data
-(void)loadData {
    [BT_debugger showIt:self theMessage:@"loadData"];
    self.isLoading = TRUE;
    
    //prevent interaction during operation
    [myTableView setScrollEnabled:FALSE];
    [myTableView setAllowsSelection:FALSE];
    
    /*
     Screen Data scenarios
     --------------------------------
     a)	No dataURL is provided in the screen data - use the info configured in the app's configuration file
     b)	A dataURL is provided, download now if we don't have a cache, else, download on refresh.
     */
    
    self.saveAsFileName = [NSString stringWithFormat:@"screenData_%@.txt", [self.screenData itemId]];
    
    //do we have a URL?
    BOOL haveURL = FALSE;
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""] length] > 10){
        haveURL = TRUE;
    }
    
    //start by filling the list from the configuration file, use these if we can't get anything from a URL
    if([[self.screenData jsonVars] objectForKey:@"childItems"]){
        NSLog(@"SCREEN DATA = %@", self.screenData.jsonVars);
        
        //init the items array
        self.menuItems = [[NSMutableArray alloc] init];
        self.filteredMenuItems = [[NSMutableArray alloc] init];
        self.displayMenuItems = [[NSMutableArray alloc] init];
        
        NSArray *tmpMenuItems = [[self.screenData jsonVars] objectForKey:@"childItems"];
        for(NSDictionary *tmpMenuItem in tmpMenuItems){
            BT_item *thisMenuItem = [[BT_item alloc] init];
            thisMenuItem.itemId = [tmpMenuItem objectForKey:@"itemId"];
            thisMenuItem.itemType = [tmpMenuItem objectForKey:@"itemType"];
            thisMenuItem.jsonVars = tmpMenuItem;
            [self.menuItems addObject:thisMenuItem];
        }
        
    }
    
    //if we have a URL, fetch..
    if(haveURL){
        
        //look for a previously cached version of this screens data...
        if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
            [BT_debugger showIt:self theMessage:@"parsing cached version of screen data"];
            NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:[self saveAsFileName] encodingFlag:-1];
            NSLog(@"CACHED DATA = %@", staleData);
            [self parseScreenData:staleData];
        }else{
            [BT_debugger showIt:self theMessage:@"no cached version of this screens data available."];
            [self downloadData];
        }
        
        
    }else{
        
        //show the child items in the config data
        [BT_debugger showIt:self theMessage:@"using menu items from the screens configuration data."];
        [self layoutScreen];
        
    }
    
}

//download data
-(void)downloadData{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloading screen data from: %@", [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""]]];
    
    //flag this as the current screen
    whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.rootApp.currentScreenData = self.screenData;
    
    //prevent interaction during operation
    [myTableView setScrollEnabled:FALSE];
    [myTableView setAllowsSelection:FALSE];
    
    //show progress
    [self showProgress];
    
    NSString *tmpURL = @"";
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""] length] > 3){
        
        //merge url variables
        tmpURL = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""];
        
        ///merge possible variables in URL
        NSString *useURL = [BT_strings mergeBTVariablesInString:tmpURL];
        NSString *escapedUrl = [useURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        //fire downloader to fetch and results
        downloader = [[BT_downloader alloc] init];
        [downloader setSaveAsFileName:[self saveAsFileName]];
        [downloader setSaveAsFileType:@"text"];
        [downloader setUrlString:escapedUrl];
        [downloader setDelegate:self];
        [downloader downloadFile];
    }
}

//parse screen data
-(void)parseScreenData:(NSString *)theData{
    [BT_debugger showIt:self theMessage:@"parseScreenData"];
    
    //prevent interaction during operation
    [myTableView setScrollEnabled:FALSE];
    [myTableView setAllowsSelection:FALSE];
    
    @try {
        
        //arrays for screenData
        self.menuItems = [[NSMutableArray alloc] init];
        
        //create dictionary from the JSON string
        SBJsonParser *parser = [SBJsonParser new];
        id jsonData = [parser objectWithString:theData];
        
        
        if(!jsonData){
            
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"ERROR parsing JSON: %@", parser.errorTrace]];
            [self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~") theMessage:NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed") alertTag:0];
            [BT_fileManager deleteFile:[self saveAsFileName]];
            
        }else{
            
            if([jsonData objectForKey:@"childItems"]){
                NSArray *tmpMenuItems = [jsonData objectForKey:@"childItems"];
                for(NSDictionary *tmpMenuItem in tmpMenuItems){
                    BT_item *thisMenuItem = [[BT_item alloc] init];
                    thisMenuItem.itemId = [tmpMenuItem objectForKey:@"itemId"];
                    thisMenuItem.itemType = [tmpMenuItem objectForKey:@"itemType"];
                    thisMenuItem.jsonVars = tmpMenuItem;
                    [self.menuItems addObject:thisMenuItem];
                }
            }
            
            //layout screen
            [self layoutScreen];
            
        }
        
    }@catch (NSException * e) {
        
        //delete bogus data, show alert
        [BT_fileManager deleteFile:[self saveAsFileName]];
        [self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~") theMessage:NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed") alertTag:0];
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"error parsing screen data: %@", e]];
        
    }
    
}

//build screen
-(void)layoutScreen{
    [BT_debugger showIt:self theMessage:@"layoutScreen"];
    
    //if we did not have any menu items...
    if(self.menuItems.count < 1){
        
        for(int i = 0; i < 5; i++){
            
            //create a dictionary for an empty BT_item
            NSDictionary *dict1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"", @"titleText",
                                   @"", @"introText",
                                   @"", @"cellBackground",
                                   @"none", @"rowAccessoryType", nil];
            
            //create a menu item from the data
            BT_item *thisMenuItemData = [[BT_item alloc] init];
            [thisMenuItemData setJsonVars:dict1];
            [thisMenuItemData setItemId:@""];
            [thisMenuItemData setItemType:@"BT_menuItem"];
            [self.menuItems addObject:thisMenuItemData];
            
        }
        
        //show message
        //[self showAlert:nil:NSLocalizedString(@"noListItems",@"This menu has no list items?"):0];
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"noListItems",@"This menu has no list items?")]];
        
    }
    //assign display menu items
    displayMenuItems = menuItems;
    
    BT_item *item = displayMenuItems[0];
    NSLog(@"item.itemId = %@", item.itemId);
    NSLog(@"item.itemNickname = %@", item.itemNickname);
    NSLog(@"item.itemType = %@", item.itemType);
    NSLog(@"item.sortableColumnValue = %@", item.sortableColumnValue);
    NSLog(@"item.jsonVars = %@", item.jsonVars);
    NSLog(@"item.image = %@", item.image);
    NSLog(@"item.imageName = %@", item.imageName);
    NSLog(@"item.imageURL = %@", item.imageURL);
    NSLog(@"item.isHomeScreen = %@", @(item.isHomeScreen));
    
    //trigger the search (needed if we have a previously entered value)
    [self textFieldDidChange:NULL];
    
    //enable interaction again (unless owner turned it off)
    if([[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"preventAllScrolling" defaultValue:@""] isEqualToString:@"1"]){
        [self.myTableView setScrollEnabled:FALSE];
    }else{
        [myTableView setScrollEnabled:TRUE];
    }
    [myTableView setAllowsSelection:TRUE];
    
    //reload table
    [self.myTableView reloadData];
    
    //flag done loading
    self.isLoading = FALSE;
    
    
}


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//UITableView delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// number of rows
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.displayMenuItems count];
}



//table view cells
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = [NSString stringWithFormat:@"cell_%i", indexPath.row];
    BTA_cell_designMenu *cell = (BTA_cell_designMenu *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        
        //init our custom cell
        cell = [[BTA_cell_designMenu alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    
    //this menu item
    BT_item *thisMenuItemData = [self.displayMenuItems objectAtIndex:indexPath.row];
    [cell setTheMenuItemData:thisMenuItemData];
    [cell setTheParentMenuScreenData:[self screenData]];
    [cell configureCell];
    
    
    //custom background view. Must be done here so we can retain the "round" corners if this is a round table
    //this method refers to this screen's "listRowBackgroundColor" and it's position in the tap. Top and
    //bottom rows may need to be rounded if this is screen uses "listStyle":"round"
    [cell setBackgroundView:[BT_viewUtilities getCellBackgroundForListRow:[self screenData] theIndexPath:indexPath numRows:[self.menuItems count]]];
    [cell setBackgroundColor:[UIColor clearColor]];
    
    //return
    return cell;
    
}

//on row select
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"didSelectRowAtIndexPath: Selected Row: %li", (long)indexPath.row]];
    
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"AR" bundle:nil];
//    FF_gpsar *arViewController = [storyboard instantiateInitialViewController];
//    arViewController.title = NSLocalizedString(@"AR Locations", nil);
//    arViewController.delegate = self;
//    
//    whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];
//    if (indexPath.row == 1) {
//        [appDelegate.rootApp.rootNavController pushViewController:arViewController animated:YES];
//        return;
//    }
    
    [self loadScreenFromRow:indexPath];
}

//on accessory view tap (details arrow tap)
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"accessoryButtonTappedForRowWithIndexPath: Selected Row: %i", indexPath.row]];
    
    //pass this menu item to the tapForMenuItem method
    BT_item *thisMenuItem = [self.menuItems objectAtIndex:indexPath.row];
    if([thisMenuItem jsonVars] != nil){
        
        //appDelegate
        whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];
        
        //get possible itemId of the screen to load
        NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars nameOfProperty:@"loadScreenWithItemId" defaultValue:@""];
        
        //get possible nickname of the screen to load
        NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars nameOfProperty:@"loadScreenWithNickname" defaultValue:@""];
        
        //bail if load screen = "none"
        if([loadScreenItemId isEqualToString:@"none"]){
            return;
        }
        
        //check for loadScreenWithItemId THEN loadScreenWithNickname THEN loadScreenObject
        BT_item *screenObjectToLoad = nil;
        if([loadScreenItemId length] > 1){
            screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
        }else{
            if([loadScreenNickname length] > 1){
                screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
            }else{
                if([thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]){
                    screenObjectToLoad = [[BT_item alloc] init];
                    [screenObjectToLoad setItemId:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemId"]];
                    [screenObjectToLoad setItemNickname:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemNickname"]];
                    [screenObjectToLoad setItemType:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemType"]];
                    [screenObjectToLoad setJsonVars:[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]];
                }
            }
        }
        
        
        //load next screen if it's not nil
        if(screenObjectToLoad != nil){
            [self handleTapToLoadScreen:screenObjectToLoad theMenuItemData:thisMenuItem];
        }else{
            //show error alert
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
        }
        
    }else{
        //show error alert
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
    }
    
}



//////////////////////////////////////////////
//search text delegate methods..


//begin edit
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    //NSLog(@"textFieldDidBeginEditing");
}

//end edit
-(void)textFieldDidEndEditing:(UITextField *)textField{
    //NSLog(@"textFieldDidEndEditing");
    
    //remember the searched value
    [BT_strings setPrefString:@"currentdesignmenuSearchValue" valueOfPref:[searchBox text]];
    
}

//should begin editing
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    //NSLog(@"textFieldShouldBeginEditing");
    //deselect previously selected row
    NSIndexPath* selection = [myTableView indexPathForSelectedRow];
    if(selection){
        [myTableView deselectRowAtIndexPath:selection animated:NO];
    }
    return YES;
}

//should end editing
-(BOOL)textFieldShouldEndEditing:(UITextField *)textField{
    //NSLog(@"textFieldShouldEndEditing");
    return YES;
}

//return tapped
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    //NSLog(@"textFieldShouldReturn");
    [self.searchBox resignFirstResponder];
    return TRUE;
}

//should clear
-(BOOL)textFieldShouldClear:(UITextField *)textField{
    //NSLog(@"textFieldShouldClear");
    //forward event to textFieldDidChange
    [self textFieldDidChange:NULL];
    return YES;
}


//text field changed
-(void)textFieldDidChange:(id)sender{
    //NSLog(@"textFieldDidChange");
    
    //remove filtered items
    [filteredMenuItems removeAllObjects];
    
    //remember the searched value for next time (in case we leave the screen and come back)
    [BT_strings setPrefString:@"currentdesignmenuSearchValue" valueOfPref:[searchBox text]];
    
    //search on every character...
    if([searchBox.text length] > 0){
        
        //loop through items in menu data...
        for(int i = 0; i < [self.menuItems count]; i++){
            BT_item *thisItem = [self.menuItems objectAtIndex:i];
            NSRange t = [[thisItem.jsonVars objectForKey:@"titleText"] rangeOfString:searchBox.text options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
            // NSRange i = [[thisItem.jsonVars objectForKey:@"introText"] rangeOfString:searchBox.text options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
            //if(t.location != NSNotFound || i.location != NSNotFound){
            if(t.location != NSNotFound){
                
                [self.filteredMenuItems addObject:thisItem];
            }
            
        }
    }
    
    //show the filtered list if searching...
    if([searchBox.text length] > 0){
        displayMenuItems = self.filteredMenuItems;
    }else{
        displayMenuItems = self.menuItems;
    }
    
    //reload
    [myTableView reloadData];
    
}


//////////////////////////////////////////////////////////////////////////////////////////////////
//downloader delegate methods
-(void)downloadFileStarted:(NSString *)message{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloadFileStarted: %@", message]];
}
-(void)downloadFileInProgress:(NSString *)message{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloadFileInProgress: %@", message]];
    if(self.progressView != nil){
        UILabel *tmpLabel = (UILabel *)[self.progressView.subviews objectAtIndex:2];
        [tmpLabel setText:message];
    }
}
-(void)downloadFileCompleted:(NSString *)message{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloadFileCompleted: %@", message]];
    [self hideProgress];
    
    //if message contains "error", look for previously cached data...
    if([message rangeOfString:@"ERROR-1968" options:NSCaseInsensitiveSearch].location != NSNotFound){
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"download error: There was a problem downloading data from the internet.%@", message]];
        //NSLog(@"Message: %@", message);
        
        //show alert
        [self showAlert:nil theMessage:NSLocalizedString(@"downloadError", @"There was a problem downloading some data. Check your internet connection then try again.") alertTag:0];
        
        //show local data if it exists
        if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
            
            //use stale data if we have it
            NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName encodingFlag:-1];
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"building screen from stale configuration data: %@", [self saveAsFileName]]];
            [self parseScreenData:staleData];
            
        }else{
            
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"There is no local data availalbe for this screen?%@", @""]];
            
            //if we have items... else.. show alert
            if(self.menuItems.count > 0){
                [self layoutScreen];
            }
            
        }
        
        
    }else{
        
        //parse previously saved data
        if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"parsing downloaded screen data.%@", @""]];
            NSString *downloadedData = [BT_fileManager readTextFileFromCacheWithEncoding:[self saveAsFileName] encodingFlag:-1];
            [self parseScreenData:downloadedData];
            
        }else{
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Error caching downloaded file: %@", [self saveAsFileName]]];
            [self layoutScreen];
            
            //show alert
            [self showAlert:nil theMessage:NSLocalizedString(@"appDownloadError", @"There was a problem saving some data downloaded from the internet.") alertTag:0];
            
        }
        
    }
    
}

//allows us to check to see if we pulled-down to refresh
-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    [self checkIsLoading];
}

-(void)checkIsLoading {
    if(isLoading){
        return;
    }else{
        //how far down did we pull?
        double down = myTableView.contentOffset.y;
        if(down <= -65){
            [BT_debugger showIt:self  theMessage:[NSString stringWithFormat:@"data reloaded: %f", down]];
            if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""] length] > 3){
                [self downloadData];
            }
        }
    }
}

-(void)loadScreenFromRow:(NSIndexPath*)indexPath {
    
    NSLog(@"%@, %li", NSStringFromSelector(_cmd), (long)indexPath.row);
    NSLog(@"");
    //pass this menu item to the tapForMenuItem method
    BT_item *thisMenuItem = [self.displayMenuItems objectAtIndex:indexPath.row];
    NSLog(@"thisMenuItem = %@", self.displayMenuItems);
    if([thisMenuItem jsonVars] != nil) {
        
        //appDelegate
        whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];
        
        //get possible itemId of the screen to load
        NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars nameOfProperty:@"loadScreenWithItemId" defaultValue:@""];
        
        //get possible nickname of the screen to load
        NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars nameOfProperty:@"loadScreenWithNickname" defaultValue:@""];
        
        //bail if load screen = "none"
        if([loadScreenItemId isEqualToString:@"none"]){
            return;
        }
        
        //check for loadScreenWithItemId THEN loadScreenWithNickname THEN loadScreenObject
        BT_item *screenObjectToLoad = nil;
        if([loadScreenItemId length] > 1){
            screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
        }else{
            if([loadScreenNickname length] > 1){
                screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
            }else{
                if([thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]){
                    screenObjectToLoad = [[BT_item alloc] init];
                    [screenObjectToLoad setItemId:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemId"]];
                    [screenObjectToLoad setItemNickname:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemNickname"]];
                    [screenObjectToLoad setItemType:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemType"]];
                    [screenObjectToLoad setJsonVars:[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]];
                }
            }
        }
        
        
        //load next screen if it's not nil
        if(screenObjectToLoad != nil){
            [self handleTapToLoadScreen:screenObjectToLoad theMenuItemData:thisMenuItem];
        }else{
            //show message
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this click?")]];
        }
        NSLog(@"screenObjectToLoad = %@", screenObjectToLoad);
    }else{
        
        //show message
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
        
    }
}

@end