/*
 *      Copyright 2013, Chris Ruddell
 *      www.churchphoneapps.com
 *      All rights reserved.
 *      
 *
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
#import "BT_fileManager.h"
#import "BT_color.h"
#import "BT_viewUtilities.h"
#import "BT_strings.h"
#import "BT_downloader.h"
#import "BT_item.h"
#import "BT_debugger.h"

#import "CR_animated_splash.h"

@implementation CR_animated_splash
@synthesize backgroundImageView, backgroundImage, transitionType;
@synthesize imageName, imageURL, startTransitionAfterSeconds, transitionDurationSeconds;
@synthesize lastImageName;

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self theMessage:@"viewDidLoad"];
	[super viewDidLoad];
		
	//appDelegate 
	whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];	

	//transition properties
    startTransitionAfterSeconds = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"startTransitionAfterSeconds" defaultValue:@"1"] doubleValue];
	transitionDurationSeconds = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"transitionDurationSeconds" defaultValue:@"1"] doubleValue];
	transitionType = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"transitionType" defaultValue:@"fade"];

	//////////////////////////////////////////////////////////////
	// 1) Add a full-size sub-view to hold a possible solid color
	//solid background color
	
	//solid background properties..
	UIColor *solidBgColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"backgroundColor" defaultValue:@"clear"]];
	NSString *solidBgOpacity = [BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"backgroundColorOpacity" defaultValue:@"100"];
	if([solidBgOpacity isEqualToString:@"100"]) solidBgOpacity = @"99";
	solidBgOpacity = [NSString stringWithFormat:@".%@", solidBgOpacity];

	//sub-view for background color
	UIView *bgColorView;
	if([appDelegate.rootDevice isIPad]){
		bgColorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1500, 1500)];
	}else{
		bgColorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
	}
	[bgColorView setAlpha:[solidBgOpacity doubleValue]];
	[bgColorView setBackgroundColor:solidBgColor];

	//add view
	[self.view addSubview:bgColorView];
	
	//////////////////////////////////////////////////////////////
	// 2) Add a full-size sub-view to hold a possible gradient background
	//gradient background color goes "on top" of solid background color
			
	UIColor *gradBgColorTop = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"backgroundColorGradientTop" defaultValue:@"clear"]];
	UIColor *gradBgColorBottom = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"backgroundColorGradientBottom" defaultValue:@"clear"]];
			
	//sub-view for gradient background color
	UIView *bgGradientView;
	if([appDelegate.rootDevice isIPad]){
		bgGradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1500, 1500)];
	}else{
		bgGradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
	}			
	
	//apply gradient
	bgGradientView = [BT_viewUtilities applyGradient:bgGradientView colorTop:gradBgColorTop colorBottom:gradBgColorBottom];
	bgGradientView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	//add view
	[self.view addSubview:bgGradientView];

	
	//////////////////////////////////////////////////////////////
	// 3) Add a full-size image-view to hold the background image

	self.imageName = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"backgroundImageNameSmallDevice" defaultValue:@""];
	self.imageURL = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"backgroundImageURLSmallDevice" defaultValue:@""];
	if([appDelegate.rootDevice isIPad]){
		self.imageName = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"backgroundImageNameLargeDevice" defaultValue:@""];
		self.imageURL = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"backgroundImageURLLargeDevice" defaultValue:@""];
	}
	
	//get resizing mode
    NSString *backgroundScaling = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"backgroundImageScale" defaultValue:@"fullScreen"];
    
    UIViewContentMode resizeMode = UIViewContentModeScaleAspectFit;
    
    
    if ([backgroundScaling isEqualToString:@"fullScreen"]) resizeMode = UIViewContentModeScaleAspectFill;
    else if ([backgroundScaling isEqualToString:@"fullScreenPreserve"]) resizeMode = UIViewContentModeScaleAspectFit;
    else if ([backgroundScaling isEqualToString:@"center"]) resizeMode = UIViewContentModeCenter;
    else if ([backgroundScaling isEqualToString:@"top"]) resizeMode = UIViewContentModeTop;
    else if ([backgroundScaling isEqualToString:@"bottom"]) resizeMode = UIViewContentModeBottom;
    else if ([backgroundScaling isEqualToString:@"topLeft"]) resizeMode = UIViewContentModeTopLeft;
    else if ([backgroundScaling isEqualToString:@"topRight"]) resizeMode = UIViewContentModeTopRight;
    else if ([backgroundScaling isEqualToString:@"bottomLeft"]) resizeMode = UIViewContentModeBottomLeft;
    else if ([backgroundScaling isEqualToString:@"bottomRight"]) resizeMode = UIViewContentModeBottomRight;
    
	self.backgroundImageView = [[UIImageView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[self.backgroundImageView setContentMode:resizeMode];
	self.backgroundImageView. autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	[self.view addSubview:self.backgroundImageView];
	
	//set the image's opacity
	NSString *imageBgOpacity = [BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"backgroundImageOpacity" defaultValue:@"100"];
	if([imageBgOpacity isEqualToString:@"100"]) imageBgOpacity = @"99";
	imageBgOpacity = [NSString stringWithFormat:@".%@", imageBgOpacity];
	[self.backgroundImageView setAlpha:[imageBgOpacity doubleValue]];

	/* 
		Where is the background image?
		a) File exists in bundle. Use this image, ignore possible download URL
		b) File DOES NOT exist in bundle, but does exist in writeable data directory: Use it. (it was already downloaded and saved)
		c) File DOES NOT exist in bundle, and DOES NOT exist in writeable data directory and an imageURL is set: Download it, save it for next time, use it.
	*/
	
	//if we have an imageURL, and no imageName, figure out a name to use...
	if(self.imageName.length < 3 && self.imageURL.length > 3){
		self.imageName = [BT_strings getFileNameFromURL:self.imageURL];
	}		
	
	//get the image
	if([self.imageName length] > 1){
		
		if([BT_fileManager doesFileExistInBundle:imageName]){
			
			[BT_debugger showIt:self theMessage:@"Image for splash-screen exists in bundle - not downloading."];
			self.backgroundImage = [UIImage imageNamed:self.imageName];
			[self setImage:self.backgroundImage];
            
            
            
			
		}
	
	}else{
	
	
		//remove screen after X seconds if we have a startTransitionAfterSeconds
		if(startTransitionAfterSeconds > -1){
            NSLog(@"starting transition to app");
			[self performSelector:@selector(animateSplashScreen) withObject:nil afterDelay:startTransitionAfterSeconds];
		}
		
	}//imageName
	
	
	//if startTransitionAfterSeconds == -1 then we need a button to tap to trigger the animation
	if(startTransitionAfterSeconds < 0){
	
		[BT_debugger showIt:self theMessage:@"Splash screen will not animate automatically, user must tap screen (begin transition seconds = -1)."];
		UIButton *coverButton = [[UIButton alloc] init];
		coverButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[coverButton setFrame:CGRectMake(0, 0, 1500, 1500)];
		coverButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleRightMargin;
		[coverButton addTarget:self action:@selector(animateSplashScreen) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:coverButton];
	
	}
	

}

//view will appear
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[BT_debugger showIt:self theMessage:@"viewWillAppear"];
	
	//flag this as the current screen
	whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];	
	appDelegate.rootApp.currentScreenData = self.screenData;
		
}


//do animatino then set delay to remove itself
-(void)animateSplashScreen {
	[BT_debugger showIt:self theMessage:@"animating splash screen"];
    
	//setup animation
	[UIView beginAnimations:nil context:nil]; 
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(removeSplashScreen)];

	//shrink
	if([transitionType rangeOfString:@"shrink" options: NSCaseInsensitiveSearch].location != NSNotFound){
		self.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
		[UIView setAnimationDuration:transitionDurationSeconds];
		self.view.transform = CGAffineTransformMakeScale(0.01, 0.01);
	}
	//fade
	if([transitionType rangeOfString:@"fade" options: NSCaseInsensitiveSearch].location != NSNotFound){
		[self.view setAlpha:1];
		[UIView setAnimationDuration:transitionDurationSeconds];
		[self.view setAlpha:0];
	}	
	//curl
	if([transitionType rangeOfString:@"curl" options: NSCaseInsensitiveSearch].location != NSNotFound){
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:[self view] cache:YES];
		[self.view setAlpha:0];
		[UIView setAnimationDuration:transitionDurationSeconds];
	}		
	
	//start animation
	[UIView commitAnimations];
	
}

//unloads view from stack
-(void)removeSplashScreen{
	[self.view removeFromSuperview];
}


//downloadImage 
-(void)downloadImage{

	//only do this if we have an image URL
	if([self.imageURL length] > 3 && [self.imageName length] > 3){

		[BT_debugger showIt:self theMessage:@"downloadImage"];

		//start download
		BT_downloader *tmpDownloader = [[BT_downloader alloc] init];
		[tmpDownloader setUrlString:imageURL];
		[tmpDownloader setSaveAsFileName:imageName];
		[tmpDownloader setSaveAsFileType:@"image"];
		[tmpDownloader setDelegate:self];
		[tmpDownloader downloadFile];
	
		//clean up
		tmpDownloader = nil;

	}
}


//stop animation
-(void)stopAnimating: (NSString *)lastImage {
    
    //first, stop the draw animation
    [self.backgroundImageView stopAnimating];
    NSLog(@"animation stopped.");
    NSLog(@"Setting image to:%@",lastImage);
    [self.backgroundImageView setImage:[UIImage imageNamed:lastImage]];
    
}

//set image
-(void)setImage:(UIImage *)theImage{
	[BT_debugger showIt:self theMessage:@"setImage"];
	
	if(theImage && self.backgroundImageView){
		[self.backgroundImageView setImage:theImage];
	}
    
    //animationDuration
    CGFloat animationDuration = [[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"animationDuration" defaultValue:@"1"] floatValue];
    
    NSString *imageWithoutExt = [[self.imageName lastPathComponent] stringByDeletingPathExtension];
    NSString *myExtension = [self.imageName pathExtension];
    NSString *firstImageNoExt = [imageWithoutExt substringToIndex:[imageWithoutExt length]-1];
    //NSString *firstImageName = [firstImageNoExt stringByAppendingString:myExtension];
    //NSString *firstImageName = [self.imageName substringToIndex:[self.imageName length] - 1];
    NSLog(@" ");
    NSLog(@" ");
    NSLog(@" ");
    NSLog(@"loading images for animation");
    NSLog(@"first image will be named %@%i.%@",firstImageNoExt,1,myExtension);
    
    NSMutableArray *animatedSplashArray = [[NSMutableArray alloc]init];
    for (int i=0; i>=0; i++) {
        //infinite loop created - will need to break
        //this loop will check to see if the next image in line exists in bundle
        //if so, add it to the array
        //if not, break
        
            NSString *tmpImageName = [NSString stringWithFormat:@"%@%i.%@",firstImageNoExt,(i+1),myExtension];
        
        if([BT_fileManager doesFileExistInBundle:tmpImageName]){

            NSLog(@"image %@ found in bundle, adding to animation array",tmpImageName);
            [animatedSplashArray addObject:[UIImage imageNamed:tmpImageName]];
            lastImageName = tmpImageName;
        }
        else break;
        
    }
    NSLog(@" ");
    NSLog(@"lastImageName is:%@",lastImageName);
    self.backgroundImageView.animationImages = animatedSplashArray;
    self.backgroundImageView.animationDuration = animationDuration;
    [self.backgroundImageView startAnimating];
    
    
    
    [self performSelector:@selector(stopAnimating:) withObject:lastImageName afterDelay:animationDuration];
    
    
    
    
	//animate splash..
	if(startTransitionAfterSeconds > -1){
		[self performSelector:@selector(animateSplashScreen) withObject:nil afterDelay:startTransitionAfterSeconds];
	}
		
}

//////////////////////////////////////////////////////////////
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
	
	//set image we just downloaded and saved.
	if([BT_fileManager doesLocalFileExist:imageName]){
		self.backgroundImage = [BT_fileManager getImageFromFile:imageName];
	}else{
		self.backgroundImage = [UIImage imageNamed:@"blank.png"];
	}
	
	//set image
	[self setImage:self.backgroundImage];
	
}



@end






