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
#import "BTA_designMenuCustomLabel.h"

@interface BTA_cell_designMenu : UITableViewCell {
	BT_item *theParentMenuScreenData;
	BT_item *theMenuItemData;
	UICustomLabeldesignMenu *titleLabel;
	UICustomLabeldesignMenu *descriptionLabel;
	UIView *imageBox;
	UIImageView *cellImageView;
    UIImageView *cellBG;
	UIImageView *glossyMaskView;
	UIActivityIndicatorView *imageLoadingView;
	NSThread *thread;
    
}
@property (nonatomic, retain) BT_item *theParentMenuScreenData;
@property (nonatomic, retain) BT_item *theMenuItemData;
@property (nonatomic, retain) UICustomLabeldesignMenu *titleLabel;
@property (nonatomic, retain) UIView *imageBox;
@property (nonatomic, retain) UICustomLabeldesignMenu *descriptionLabel;
@property (nonatomic, retain) UIImageView *cellImageView;
@property (nonatomic, retain) UIImageView *cellBG;
@property (nonatomic, retain) UIImageView *glossyMaskView;
@property (nonatomic, retain) UIActivityIndicatorView *imageLoadingView;


-(void)configureCell;
-(void)showImage;
-(void)downloadImage;


@end
