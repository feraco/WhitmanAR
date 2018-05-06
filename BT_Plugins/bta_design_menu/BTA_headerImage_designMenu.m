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
#import "BT_fileManager.h"
#import "whitmanar_appDelegate.h"
#import "BT_debugger.h"
#import "BT_strings.h"
#import "BT_item.h"
#import "BT_viewUtilities.h"
#import "BT_imageTools.h"
#import "BTA_headerImage_designMenu.h"

@implementation BTA_headerImage_designMenu
@synthesize theParentMenuScreenData;
@synthesize imageView, progressView, imageTop, imageLeft, imageHeight, imageWidth;
@synthesize imageName, imageURL, cornerRadius;

-(id)initWithScreenData:(BT_item *)theScreenData{
    if((self = [super init])){		
		[BT_debugger showIt:self theMessage:@"INIT"];
		
		//set buttons parent screen data
		[self setTheParentMenuScreenData:theScreenData];
		
		//appDelegate
		whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];	
		
		//default values. Sizes come from parent screen data
		imageTop = 0;
		imageLeft = 0;
		imageHeight = 0;
		imageWidth = 0;
		cornerRadius = 0;
		
		if([appDelegate.rootDevice isIPad]){
			
			//use large device settings
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageTopPosLargeDevice"]){
				imageTop = [[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageTopPosLargeDevice"] intValue];
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageNameLargeDevice"]){
				imageName = [[theParentMenuScreenData jsonVars] objectForKey:@"headerImageNameLargeDevice"];
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageURLLargeDevice"]){
				imageURL = [[theParentMenuScreenData jsonVars] objectForKey:@"headerImageURLLargeDevice"];
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageHeightLargeDevice"]){
				if([[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageHeightLargeDevice"] length] > 0){
					imageHeight = [[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageHeightLargeDevice"] intValue];
				}
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageWidthLargeDevice"]){
				if([[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageWidthLargeDevice"] length] > 0){
					imageWidth = [[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageWidthLargeDevice"] intValue];
				}
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageCornerRadiusLargeDevice"]){
				if([[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageCornerRadiusLargeDevice"] length] > 0){
					cornerRadius = [[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageCornerRadiusLargeDevice"] intValue];
				}
			}
			
		}else{

			//use small device settings
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageTopPosSmallDevice"]){
				imageTop = [[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageTopPosSmallDevice"] intValue];
			}
			
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageNameSmallDevice"]){
				imageName = [[theParentMenuScreenData jsonVars] objectForKey:@"headerImageNameSmallDevice"];
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageURLSmallDevice"]){
				imageURL = [[theParentMenuScreenData jsonVars] objectForKey:@"headerImageURLSmallDevice"];
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageHeightSmallDevice"]){
				if([[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageHeightSmallDevice"] length] > 0){
					imageHeight = [[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageHeightSmallDevice"] intValue];
				}
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageWidthSmallDevice"]){
				if([[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageWidthSmallDevice"] length] > 0){
					imageWidth = [[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageWidthSmallDevice"] intValue];
				}
			}
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageCornerRadiusSmallDevice"]){
				if([[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageCornerRadiusSmallDevice"] length] > 0){
					cornerRadius = [[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageCornerRadiusSmallDevice"] intValue];
				}
			}			
		}

		//if we have an imageURL, and no imageName, figure out a name to use...
		if(self.imageName.length < 3 && self.imageURL.length > 3){
			self.imageName = [BT_strings getFileNameFromURL:self.imageURL];
		}

		//we must have an image name and the image dimenstions to continue...
		if(imageHeight > 0 && imageWidth > 0 && [imageName length] > 0){
		
			//figure out the "left" value from the device's width and the images width. If somebody entered a 
			//width larger than the device, use zero for left and re-set the imageWidth value
			if([appDelegate.rootDevice deviceWidth] > imageWidth){
				imageLeft = ([appDelegate.rootDevice deviceWidth] - imageWidth) / 2;
			}else{
				imageWidth = [appDelegate.rootDevice deviceWidth];
			}
			
			//set views frame. The size is "imageTop" + "imageHeight"
			[self setFrame:CGRectMake(0, 0, imageWidth, (imageTop + imageHeight + 5))];
			self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

			//image view holds the image 
			imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, imageTop, imageWidth, imageHeight)];
			[imageView setClipsToBounds:TRUE];
			imageView = [BT_viewUtilities applyRoundedCornersToImageView:imageView radius:cornerRadius];
			
			imageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			[imageView setContentMode:UIViewContentModeCenter];
			[self addSubview:imageView];
			
			//add a transparent button on top of image if we have a "headerImageTapLoadScreen"
			if([[theParentMenuScreenData jsonVars] objectForKey:@"headerImageTapLoadScreenItemId"] ||
				[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageTapLoadScreenNickname"] ||
				[[theParentMenuScreenData jsonVars] objectForKey:@"headerImageTapLoadScreenObject"]){
				
				UIButton *headerImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
				headerImageButton.frame = CGRectMake(0, imageTop, imageWidth, imageHeight);
				headerImageButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
				[self addSubview:headerImageButton];
				
			}
			
			//activity indicator, gets hidden after image loads
			progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];		
			progressView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			[progressView setCenter:[imageView center]];
			[progressView setHidesWhenStopped:TRUE];
			[progressView startAnimating];
			[self addSubview:progressView];		
			
			//show the image (method will get local image or downoad image)
			[self showImage];
			
		}
		
		
    }
    return self;
}


//shows image
-(void)showImage{
	@synchronized(self) {      
		if ([[NSThread currentThread] isCancelled]) return;
		[thread cancel]; 
		thread = nil;
        
		
		//if we don't have an image name
		if([imageName length] < 4){
			[self performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
			return;
		}
		
		/* 
			Where is the image?
			a) Image exists in bundle. Use this image, ignore possible download URL
			b) Image exists in cache.. use this image
			c) Image DOES NOT exist in bundle, and DOES NOT exist in cache: Download it, save it for next time, use it.
		*/
		
		if([BT_fileManager doesFileExistInBundle:[self imageName]]){
		
			[BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"using image from bundle for header: %@", [self imageName]]];
			UIImage *tmpImg = [UIImage imageNamed:[self imageName]];
			[self setImage:tmpImg];
			[progressView performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
		
		}else{
			
			if([BT_fileManager doesLocalFileExist:[self imageName]]){
			
				[BT_debugger showIt:self theMessage:@"Image exists locally - not downloading."];
				UIImage *tmpImg = [BT_fileManager getImageFromFile:[self imageName]];
				[self setImage:tmpImg];
				[progressView performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
				
			}else{
			
				//must have URL
				if([self.imageURL length] > 3){
			
					[BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloading image for header: %@", [self imageURL]]];
					thread = [[NSThread alloc] initWithTarget:self selector:@selector(downloadImage) object:nil];
					[thread start];
				
				}else{
					
					[BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"image not in project, or in cache and no URL provided. Not downloadding %@", [self imageName]]];
					[self setImage:[UIImage imageNamed:@"noImage.png"]];
					[self.progressView stopAnimating];
				
				}
				
			}
		}
		
		
	}    
}

//trigers image download
-(void)downloadImage{
    
    
    //imageURL...
    NSString *imgURL = self.imageURL;
    if([imgURL length] > 3){
        
        //create an NSURL from the url string...
        NSURL *useURL = [NSURL URLWithString:imgURL];
        
        //download image using Grand Central Dispath, iOS handles queue automagically...
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
        dispatch_async(queue, ^{
            NSData *data = [NSData dataWithContentsOfURL:useURL];
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self setImage:image];
                [progressView performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];

                
            });
        });
        
    }
    
    
}

//sets image after download complete
-(void)setImage:(UIImage *)theImage{

	//do we round the corners?
	if(cornerRadius > 0){
		theImage = [BT_imageTools makeRoundCornerImage:theImage:cornerRadius:cornerRadius];
	}
	
	//add image to the image view
	[imageView setImage:theImage];
	
	//clean up
	theImage = nil;
	
}


@end




