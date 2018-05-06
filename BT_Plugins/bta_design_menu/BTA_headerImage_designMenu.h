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
#import "BT_item.h"

@interface BTA_headerImage_designMenu : UIView {

	BT_item *theParentMenuScreenData;

	UIImageView *imageView;
	NSString *imageName;
	NSString *imageURL;
	int imageTop;
	int imageLeft;
	int imageHeight;
	int imageWidth;
	int cornerRadius;
	UIActivityIndicatorView *progressView;
	NSThread *thread;


}

@property (nonatomic, retain) BT_item *theParentMenuScreenData;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) NSString *imageName;
@property (nonatomic, retain) NSString *imageURL;
@property (nonatomic) int imageTop;
@property (nonatomic) int imageLeft;
@property (nonatomic) int imageHeight;
@property (nonatomic) int imageWidth;
@property (nonatomic) int cornerRadius;
@property (nonatomic, retain) UIActivityIndicatorView *progressView;

-(id)initWithScreenData:(BT_item *)theScreenData;
-(void)showImage;
-(void)downloadImage;
-(void)setImage:(UIImage *)theImage;

@end






