/*
 *	Copyright 2013, David Book, buzztouch.com
 *
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without modification, are 
 *	permitted provided that the following conditions are met:
 *
 *	Redistributions of source code must retain the above copyright notice which includes the
 *	name(s) of the copyright holders. It must also retain this list of conditions and the 
 *	following disclaimer. 
 *
 *	Redistributions in binary form must reproduce the above copyright notice, this list 
 *	of conditions and the following disclaimer in the documentation and/or other materials 
 *	provided with the distribution. 
 *
 *	Neither the name of David Book, or buzztouch.com nor the names of its contributors 
 *	may be used to endorse or promote products derived from this software without specific 
 *	prior written permission.
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
#import "whitmanar_appDelegate.h"
#import "BT_color.h"
#import "BT_viewUtilities.h"
#import "BT_downloader.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "BT_strings.h"

#import "BT_screen_settingsLogIn.h"

@implementation BT_screen_settingsLogIn
@synthesize text_loginId, isLoggedIn;
@synthesize text_password, button_submit, label_status;
@synthesize statusImageView, statusImage, dataURL, downloader;

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self theMessage:@"viewDidLoad"];
	[super viewDidLoad];

	//appDelegate 
	whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//assume not logged in...
	isLoggedIn = FALSE;
	
	//URL to validate login
	if([[self.screenData jsonVars] objectForKey:@"dataURL"]){
		[self setDataURL:[[self.screenData jsonVars] objectForKey:@"dataURL"]];		
	}
	
	//text color for labels comes from rootApp.rootTheme OR screenData if over-ridden
	UIColor *labelColor = [UIColor blackColor];
	if([[appDelegate.rootApp.rootTheme jsonVars] objectForKey:@"textOnBackgroundColor"]){
		if([[[appDelegate.rootApp.rootTheme jsonVars] objectForKey:@"textOnBackgroundColor"] rangeOfString:@"#" options:NSCaseInsensitiveSearch].location != NSNotFound){
			labelColor = [BT_color getColorFromHexString:[[appDelegate.rootApp.rootTheme jsonVars] objectForKey:@"textOnBackgroundColor"]];
		}
	}
	if([[self.screenData jsonVars] objectForKey:@"textOnBackgroundColor"]){
		if([[[self.screenData jsonVars] objectForKey:@"textOnBackgroundColor"] rangeOfString:@"#" options:NSCaseInsensitiveSearch].location != NSNotFound){
			labelColor = [BT_color getColorFromHexString:[[self.screenData jsonVars] objectForKey:@"textOnBackgroundColor"]];
		}
	}		
	
	//left is vertical center..
	int left = [appDelegate.rootDevice deviceWidth] / 2 - 160;
	int top = 0;
	
	//controls go in a box so we can center everything.
	/*
		IMPORTANT. If the screen uses a transparent navigation bar, the login box will be
		under it and it won't show. In this case, we need to move it down 44 pixels.
	*/
	if([[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"navBarStyle" defaultValue:@""] isEqualToString:@"transparent"]){
		top = (top + 44);
	}
	
	//controls go in a box so we can center everything
	UIView *box = [[UIView alloc] initWithFrame:CGRectMake(left, top, 320, 480)];
	box.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	
	//loginId text box	
	text_loginId = [[UITextField alloc] initWithFrame:CGRectMake(10, 10, 300, 35)];
	[text_loginId setBorderStyle:UITextBorderStyleRoundedRect];
	[text_loginId setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	[text_loginId setClearButtonMode:UITextFieldViewModeAlways];
	[text_loginId setKeyboardType:UIKeyboardTypeEmailAddress];
	[text_loginId setReturnKeyType:UIReturnKeyDone];
	[text_loginId setAutocorrectionType:UITextAutocorrectionTypeNo];
	[text_loginId setLeftViewMode:UITextFieldViewModeAlways];
	[text_loginId setFont:[UIFont systemFontOfSize:15]];
	[text_loginId setTag:1];
	[text_loginId setDelegate:self];
	
	//label for left of text_loginId
	UILabel *logInIdLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, 30)];
	[logInIdLabel setFont:[UIFont systemFontOfSize:14]];
	[logInIdLabel setBackgroundColor:[UIColor clearColor]];
	[logInIdLabel setTextColor:[UIColor lightGrayColor]];
	[logInIdLabel setTextAlignment:NSTextAlignmentRight];
	[logInIdLabel setText:@"Email:"];
	if([[self.screenData jsonVars] objectForKey:@"labelLogInId"]){
		if([[[self.screenData jsonVars] objectForKey:@"labelLogInId"] length] > 0){
			[logInIdLabel setText:[[self.screenData jsonVars] objectForKey:@"labelLogInId"]];
		}else{
			[logInIdLabel setText:NSLocalizedString(@"labelLogInId",@"Login Id")];
		}
	}else{
		[logInIdLabel setText:NSLocalizedString(@"labelLogInId",@"Login Id")];
	}
	[text_loginId setLeftView:logInIdLabel];
	[box addSubview:text_loginId];

	//password
	text_password = [[UITextField alloc] initWithFrame:CGRectMake(10, 50, 300, 35)];
	[text_password setBorderStyle:UITextBorderStyleRoundedRect];
	[text_password setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	[text_password setClearButtonMode:UITextFieldViewModeAlways];
	[text_password setKeyboardType:UIKeyboardTypeDefault];
	[text_password setReturnKeyType:UIReturnKeyDone];
	[text_password setSecureTextEntry:TRUE];
	[text_password setAutocorrectionType:UITextAutocorrectionTypeNo];
	[text_password setLeftViewMode:UITextFieldViewModeAlways];
	[text_password setFont:[UIFont systemFontOfSize:15]];
	[text_password setTag:2];
	[text_password setDelegate:self];
	
	//label for left of text_password
	UILabel *passwordLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 75, 30)];
	[passwordLabel setFont:[UIFont systemFontOfSize:14]];
	[passwordLabel setBackgroundColor:[UIColor clearColor]];
	[passwordLabel setTextColor:[UIColor lightGrayColor]];
	[passwordLabel setTextAlignment:NSTextAlignmentRight];
	[passwordLabel setText:@"Email:"];
	if([[self.screenData jsonVars] objectForKey:@"labelPassword"]){
		if([[[self.screenData jsonVars] objectForKey:@"labelPassword"] length] > 0){
			[passwordLabel setText:[[self.screenData jsonVars] objectForKey:@"labelPassword"]];
		}else{
			[passwordLabel setText:NSLocalizedString(@"labelPassword",@"Password:")];
		}
	}else{
		[passwordLabel setText:NSLocalizedString(@"labelPassword",@"Password:")];
	}
	[text_password setLeftView:passwordLabel];
	[box addSubview:text_password];
	
	//submit button
	button_submit = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[button_submit setFrame:CGRectMake(10, 90, 300, 35)];
	[button_submit addTarget:self action:@selector(submitClick) forControlEvents:UIControlEventTouchUpInside];
	[box addSubview:button_submit];
	
	//status label
	label_status = [[UILabel alloc] initWithFrame:CGRectMake(10, 130, 300, 20)];
	[label_status setBackgroundColor:[UIColor clearColor]];
	[label_status setNumberOfLines:1];
	[label_status setTextColor:labelColor];
	[label_status setTextAlignment:NSTextAlignmentCenter];
	[label_status setFont:[UIFont systemFontOfSize:15]];
	[box addSubview:label_status];
	
	//set status image view
	statusImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 160, 300, 35)];
	[statusImageView setContentMode:UIViewContentModeCenter];
	[box addSubview:statusImageView];

	//add the box
	[self.view addSubview:box];
	
	//update gui
	[self updateGui];
		

}

//view will appear
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self theMessage:@"viewWillAppear"];
	

}


//logout click
-(void)submitClick{

	//appDelegate 
	whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];	

	//logged in or out?
	if(self.isLoggedIn){
		
		[BT_debugger showIt:self theMessage:@"logoutClick"];
		
		//flag
		self.isLoggedIn = FALSE;
		
		//forget prefs
		[BT_strings setPrefString:@"userGuid" valueOfPref:@""];
		[BT_strings setPrefString:@"userDisplayName" valueOfPref:@""];
		[BT_strings setPrefString:@"userEmail" valueOfPref:@""];
		[BT_strings setPrefString:@"userLogInId" valueOfPref:@""];
		[BT_strings setPrefString:@"userLogInPassword" valueOfPref:@""];
		
		//forgot values in rootUser (logout)
		[appDelegate.rootUser setUserId:@""];
		[appDelegate.rootUser setUserDisplayName:@""];
		[appDelegate.rootUser setUserEmail:@""];
		[appDelegate.rootUser setUserLogInId:@""];
		[appDelegate.rootUser setUserLogInPassword:@""];
		[appDelegate.rootUser setUserIsLoggedIn:@"0"];

		//update gui
		[self updateGui];
	
	}else{
	
		[BT_debugger showIt:self theMessage:@"loginClick"];
		
		//validate...
		if([text_loginId.text length] < 1 || [text_password.text length] < 1){
			
			//show alert
			[self showAlert:nil theMessage:NSLocalizedString(@"loginSubmitError", @"Please enter your Username and Password then try again") alertTag:0];
			
		}else{
		
			//show progress
			[self showProgress];
			
			//hide keyboard, disable button
			[text_loginId resignFirstResponder];
			[text_password resignFirstResponder];
			[button_submit setEnabled:FALSE];
			
			//set rootUser vars so we can use them to fix-up validate URL 
			[appDelegate.rootUser setUserId:@""];
			[appDelegate.rootUser setUserDisplayName:@""];
			[appDelegate.rootUser setUserEmail:@""];
			[appDelegate.rootUser setUserLogInId:[text_loginId text]];
			[appDelegate.rootUser setUserLogInPassword:[text_password text]];

			//merge URL variables...
			NSString *useURL = [self dataURL];
			useURL = [BT_strings mergeBTVariablesInString:useURL];
			
			//start download
			downloader = [[BT_downloader alloc] init];
			[downloader setSaveAsFileName:@""];
			[downloader setSaveAsFileType:@"return"];
			[downloader setUrlString:useURL];
			[downloader setDelegate:self];
			[downloader downloadFile];
		
		}
	
	}//isLoggedIn
	
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//downloader delegate methods
-(void)downloadFileStarted:(NSString *)message{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileStarted: %@", message]];
}
-(void)downloadFileInProgress:(NSString *)message{
	//[BT_debugger showIt:self:[NSString stringWithFormat:@"downloadFileInProgress: %@", message]];
	if(self.progressView != nil){
		UILabel *tmpLabel = (UILabel *)[self.progressView.subviews objectAtIndex:2];
		[tmpLabel setText:message];
	}
}
-(void)downloadFileCompleted:(NSString *)message{
	[BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloadFileCompleted: %@", message]];
	[self hideProgress];
	
	//enable submit
	[button_submit setEnabled:TRUE];

	//appDelegate 
	whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];	

	//are returned results valid?
	SBJsonParser *parser = [SBJsonParser new];
  	id jsonData = [parser objectWithString:message];
  	if(jsonData){
	
		//assume login is invalid until we inspect the results
		BOOL isValid = FALSE;
		
		if([[jsonData objectForKey:@"result"] objectForKey:@"status"]){
			if([[[jsonData objectForKey:@"result"] objectForKey:@"status"] isEqualToString:@"valid"]){
				
				//save prefs
				[BT_strings setPrefString:@"userGuid" valueOfPref:[[jsonData objectForKey:@"result"] objectForKey:@"userGuid"]];
				[BT_strings setPrefString:@"userDisplayName" valueOfPref:[[jsonData objectForKey:@"result"] objectForKey:@"userDisplayName"]];
				[BT_strings setPrefString:@"userEmail" valueOfPref:[[jsonData objectForKey:@"result"] objectForKey:@"userEmail"]];
				[BT_strings setPrefString:@"userLogInId" valueOfPref:[text_loginId text]];
				[BT_strings setPrefString:@"userLogInPassword" valueOfPref:[text_password text]];
				
				//remember in rootUser
				[appDelegate.rootUser setUserId:[[jsonData objectForKey:@"result"] objectForKey:@"userGuid"]];
				[appDelegate.rootUser setUserDisplayName:[[jsonData objectForKey:@"result"] objectForKey:@"userDisplayName"]];
				[appDelegate.rootUser setUserEmail:[[jsonData objectForKey:@"result"] objectForKey:@"userEmail"]];
				[appDelegate.rootUser setUserLogInId:[text_loginId text]];
				[appDelegate.rootUser setUserLogInPassword:[text_password text]];
				[appDelegate.rootUser setUserIsLoggedIn:@"1"];

				//flag
				isValid = TRUE;
				[self setIsLoggedIn:TRUE];
				
			}			
		}
		
		//update gui if valid
		if(isValid){
			[self updateGui];
		}else{
		
			//flag
			self.isLoggedIn = FALSE;
		
			//parse error, show message
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"invalidLogin",@"~ Invalid Login ~")
			message:NSLocalizedString(@"invalidLoginMessage", @"Your login credentials could not be validated. Please try again.") delegate:self
			cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
			[alertView show];
			

		}//isValid
	
	}else{
	
		//download error, show message
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
		message:NSLocalizedString(@"noLocalDataAvailable", @"Data for this screen has not been downloaded. Please check your internet connection.") delegate:self
		cancelButtonTitle:NSLocalizedString(@"ok", "OK") otherButtonTitles:nil];
		[alertView show];
		
				
	}
}

//update gui
-(void)updateGui{

	//appDelegate 
	whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];	
	
	//image depends on status
	if([[appDelegate.rootUser userIsLoggedIn] isEqualToString:@"1"]){
		statusImage = [UIImage imageNamed:@"dot_green.png"];
		isLoggedIn = TRUE;
	}else{
		statusImage = [UIImage imageNamed:@"dot_red.png"];
	}
	
	//set status image view
	[statusImageView setImage:statusImage];

	//value of text boxes
	[self.text_loginId setText:[BT_strings getPrefString:@"userLogInId"]];
	[self.text_password setText:[BT_strings getPrefString:@"userLogInPassword"]];

	//login or logout depends on current state...Set button and text box values.
	NSString *tmp;
	if(!self.isLoggedIn){
		tmp = [NSString stringWithFormat:@"%@", NSLocalizedString(@"loggedOutMessage",@"You are not logged in")];
		[button_submit setTitle:NSLocalizedString(@"loginButton",@"Login") forState:UIControlStateNormal];
	}else{
		tmp = [NSString stringWithFormat:@"%@", NSLocalizedString(@"loggedInMessage",@"You are logged in")];
		[button_submit setTitle:NSLocalizedString(@"logoutButton",@"Logout") forState:UIControlStateNormal];
	}
	[label_status setText:tmp];

}

//////////////////////////////////////////////////////////////////////////////////////////////////
//text field delegate methods
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
	//hide keyboard
	if(textField.tag == 1){
		[text_loginId resignFirstResponder];
	}
	if(textField.tag == 2){
		[text_password resignFirstResponder];
	}
	return FALSE;	
}

//make sure characters are allowed
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)textEntered {
  	if(textEntered.length > 0){
    	
		//look at each character in the text box...
		for(int i = 0; i < [textEntered length]; i++) {
       		
            //this loop gives you an opportunity to filter out non-allowed characters.
            //return NO in this loop if you run into a character you don't want to allow.
            
            
    	}
		
	}
    return YES;
}



@end







