/*
 *	Copyright 2016, Andy Kitts
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

#import "AK_wikitudeARtracking.h"
#import <WikitudeNativeSDK/WikitudeNativeSDK.h>
#import "StrokedRectangle.h"

@interface AK_wikitudeARtracking () <WTWikitudeNativeSDKDelegate, WTClientTrackerDelegate, WTCloudTrackerDelegate>

@property (nonatomic, strong) WTWikitudeNativeSDK *wikitudeSDK;
@property (nonatomic, strong) WTClientTracker *clientTracker;
@property (nonatomic, strong) WTEAGLView *wikitudeEAGLView;
@property (nonatomic, strong) WTRenderer *wikitudeRenderer;
@property (nonatomic, assign) BOOL isTracking;
@property (nonatomic, strong) StrokedRectangle *renderableRectangle;
@property (nonatomic, strong) UIButton * ARButton;
@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, strong) NSString* currentTrackerId;

@property (nonatomic, strong) NSString* overlayImageName;
@property (nonatomic, strong) WTCloudTracker *cloudTracker;
@end

@implementation AK_wikitudeARtracking

//viewDidLoad
-(void)viewDidLoad{
    [BT_debugger showIt:self theMessage:@"viewDidLoad"];
    [super viewDidLoad];
}

-(void)buttonTapped:(id)sender{
    NSString *loadScreen = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"loadScreen" defaultValue:@"0"];
    if ([loadScreen isEqualToString:@"1"] && self.currentTrackerId != nil ) {
        whitmanar_appDelegate *appDelegate = (whitmanar_appDelegate *)[[UIApplication sharedApplication] delegate];
        BT_item * screenDataToLoad = [appDelegate.rootApp getScreenDataByNickname:self.currentTrackerId];
        BT_item *tmpMenuItem = [[BT_item alloc]init];
        NSDictionary *tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:@"unused",@"itemId",[self.screenData.jsonVars objectForKey:@"transitionType"],@"transitionType", nil];
        [tmpMenuItem setJsonVars:tmpDict];
        [tmpMenuItem setItemId:@""];
        [self handleTapToLoadScreen:screenDataToLoad theMenuItemData:tmpMenuItem];
    }
    [self.wikitudeSDK stop];
    [self.cloudTracker stopContinuousRecognition];
    _isTracking = NO;
    self.clientTracker = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        _imageView.hidden = true;
    });
}

//view will appear
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [BT_debugger showIt:self theMessage:@"viewWillAppear"];
    self.renderableRectangle = [[StrokedRectangle alloc] init];
    self.wikitudeSDK = [[WTWikitudeNativeSDK alloc] initWithRenderingMode:WTRenderingMode_Internal delegate:self];
    NSString *licenceKey = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"licenceKey" defaultValue:@"INCORRECT KEY"];
    NSLog(@"%@",licenceKey);
    
    [self.wikitudeSDK setLicenseKey:licenceKey];
    self.wikitudeRenderer = [self.wikitudeSDK createRenderer];
    self.wikitudeEAGLView = [self.wikitudeSDK createEAGLView];
    [self.wikitudeEAGLView setRenderer:self.wikitudeRenderer];
    [self.view addSubview:self.wikitudeEAGLView];
    [self.wikitudeEAGLView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_wikitudeEAGLView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_wikitudeEAGLView]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_wikitudeEAGLView]|" options:0 metrics:nil views:views]];
    
    NSString * wtcFileName = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"wtcFileName" defaultValue:@""];
    NSString *clientToken = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"clientToken" defaultValue:@""];
    NSString *collectionId = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"targetCollectionId" defaultValue:@""];
    
    [self.wikitudeSDK start:nil completion:^(BOOL isRunning, NSError * __nonnull error) {
        if ( !isRunning ) {
            [BT_debugger showIt:self message:[NSString stringWithFormat:@"Wikitude SDK is not running. Reason: %@", [error localizedDescription]]];
        }
        else
        {
            if (wtcFileName.length > 0){
                NSURL *clientTrackerURL = [[NSBundle mainBundle] URLForResource:wtcFileName withExtension:@"wtc"];
                self.clientTracker = [self.wikitudeSDK.trackerManager create2DClientTrackerFromURL:clientTrackerURL extendedTargets:nil andDelegate:self];
            }else{
                self.cloudTracker = [self.wikitudeSDK.trackerManager createCloudTrackerWithToken:clientToken targetCollectionId:collectionId extendedTargets:nil andDelegate:self];
            }
        }
    }];
    
    [self.cloudTracker startContinuousRecognitionWithInterval:1.5 successHandler:^(WTCloudRecognitionResponse *response) {
        NSLog(@"received continuous response...");
        if ( response.recognized ) {
            _overlayImageName = [response.metadata objectForKey:@"itemId"];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.cloudTracker stopContinuousRecognition];
            });
        }
    } interruptionHandler:nil errorHandler:^(NSError *error) {
        NSLog(@"Cloud recognition error %ld occured. %@", (long)error.code, [error localizedDescription]);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveApplicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveApplicationDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.wikitudeSDK stop];
    [self.cloudTracker stopContinuousRecognition];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.wikitudeSDK stop];
    [self.cloudTracker stopContinuousRecognition];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.wikitudeSDK shouldTransitionToSize:size withTransitionCoordinator:coordinator];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    [self.wikitudeSDK shouldTransitionToSize:self.view.bounds.size withTransitionCoordinator:nil];
}

- (void)didReceiveMemoryWarning{
    [super didReceiveMemoryWarning];
}

#pragma mark - Notifications
- (void)didReceiveApplicationWillResignActiveNotification:(NSNotification *)notification{
    [self.wikitudeSDK stop];
    [self.cloudTracker stopContinuousRecognition];
    [self.renderableRectangle releaseProgram];
}

- (void)didReceiveApplicationDidBecomeActiveNotification:(NSNotification *)notification{
    [self.wikitudeSDK start:nil completion:^(BOOL isRunning, NSError * __nonnull error){
        if ( !isRunning ) {
            [BT_debugger showIt:self message:[NSString stringWithFormat:@"Wikitude SDK is not running. Reason: %@", [error localizedDescription]]];
        }
    }];
}

#pragma mark - Delegation
#pragma mark WTWikitudeNativeSDKDelegte
- (WTCustomUpdateHandler)wikitudeNativeSDKNeedsExternalUpdateHandler:(WTWikitudeNativeSDK * __nonnull)wikitudeNativeSDK{
    /* Intentionally returning a nil handler here */
    return ^(){};
}

- (WTCustomDrawHandler)wikitudeNativeSDKNeedsExternalDrawHandler:(WTWikitudeNativeSDK * __nonnull)wikitudeNativeSDK{
    __weak typeof(self) weakSelf = self;
    return ^(){
        if ( weakSelf.isTracking ) {
            [weakSelf.renderableRectangle drawInContext:[EAGLContext currentContext]];
        }
    };
}

- (void)wikitudeNativeSDK:(WTWikitudeNativeSDK * __nonnull)wikitudeNativeSDK didEncounterInternalError:(NSError * __nonnull)error{
    [BT_debugger showIt:self message:[NSString stringWithFormat:@"Internal Wikitude SDK error encounterd. %@", [error localizedDescription]]];
    [self showAlert:@"Camera Access Required" theMessage:@"Access to the camera is needed to display augmented reality content on top of your camera image. Please allow this app access to the camera in settings." alertTag:99999];
    [self navLeftTap];
}

#pragma mark WTClientTrackerDelegate

- (void)baseTracker:(nonnull WTBaseTracker *)baseTracker didRecognizedTarget:(nonnull WTImageTarget *)recognizedTarget{
    self.currentTrackerId = [recognizedTarget name];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        _imageView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:[recognizedTarget name]]];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        _ARButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_ARButton setTitle: @"" forState: UIControlStateNormal];
        _ARButton.backgroundColor = [UIColor clearColor];
        [_ARButton addTarget:recognizedTarget action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        _imageView.frame = CGRectMake(0, 0, 100, 100);
        _imageView.userInteractionEnabled = true;
        _ARButton.frame = _imageView.frame;
        [self.view addSubview:_imageView];
        [_imageView addSubview:_ARButton];
        _imageView.hidden = true;
        _isTracking = YES;
    });
}

- (void)baseTracker:(nonnull WTBaseTracker *)baseTracker didTrackTarget:(nonnull WTImageTarget *)trackedTarget{
    [self.renderableRectangle setProjectionMatrix:trackedTarget.projection];
    [self.renderableRectangle setModelViewMatrix:trackedTarget.modelView];
    CATransform3D drawableTransform;
    drawableTransform.m11 = trackedTarget.modelViewProjection[0];
    drawableTransform.m12 = trackedTarget.modelViewProjection[1];
    drawableTransform.m13 = trackedTarget.modelViewProjection[2];
    drawableTransform.m14 = trackedTarget.modelViewProjection[3];
    drawableTransform.m21 = trackedTarget.modelViewProjection[4];
    drawableTransform.m22 = trackedTarget.modelViewProjection[5];
    drawableTransform.m23 = trackedTarget.modelViewProjection[6];
    drawableTransform.m24 = trackedTarget.modelViewProjection[7];
    drawableTransform.m31 = trackedTarget.modelViewProjection[8];
    drawableTransform.m32 = trackedTarget.modelViewProjection[9];
    drawableTransform.m33 = trackedTarget.modelViewProjection[10];
    drawableTransform.m34 = trackedTarget.modelViewProjection[11];
    drawableTransform.m41 = trackedTarget.modelViewProjection[12];
    drawableTransform.m42 = trackedTarget.modelViewProjection[13];
    drawableTransform.m43 = trackedTarget.modelViewProjection[14];
    drawableTransform.m44 = trackedTarget.modelViewProjection[15];
    
    /// ======== Convert iOS to Core so that the core matrix can be applied correctly ========
    
    CGSize _drawableSize = CGSizeMake(0.15, 0.15);
    CATransform3D translateDrawable = CATransform3DMakeTranslation(-0.2f, 0.2f, 0.3f);
    drawableTransform = CATransform3DConcat(translateDrawable, drawableTransform);
    CATransform3D convertScale = CATransform3DMakeScale(1.f/_drawableSize.width, -1.f/_drawableSize.height, 1.f);
    drawableTransform = CATransform3DConcat(convertScale, drawableTransform);
    
    /// ======== Core matrix is now applied => Convert Core back to iOS ========
    
    CATransform3D screenScale = CATransform3DMakeScale(self.view.bounds.size.width*.5f, -self.view.bounds.size.height*.5f, 1.f);
    drawableTransform = CATransform3DConcat(drawableTransform, screenScale);
    
    CATransform3D screenTranslation = CATransform3DMakeTranslation(self.view.bounds.size.width*.5f, self.view.bounds.size.height*.5f, 0.f);
    drawableTransform = CATransform3DConcat(drawableTransform, screenTranslation);
    
    CATransform3D distanceTranslation = CATransform3DMakeScale(1.f, 1.f, 1.f);
    drawableTransform = CATransform3DConcat(drawableTransform, distanceTranslation);
    
    // apply the converted matrix
    dispatch_async(dispatch_get_main_queue(), ^{
        [_imageView.layer setTransform:drawableTransform];
        _imageView.hidden = false;
    });
}

- (void)baseTracker:(nonnull WTBaseTracker *)baseTracker didLostTarget:(nonnull WTImageTarget *)lostTarget{
    _isTracking = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        _imageView.hidden = true;
    });
    [BT_debugger showIt:self message:[NSString stringWithFormat:@"lost target '%@'", [lostTarget name]]];
    self.currentTrackerId = nil;
}

- (void)clientTracker:(nonnull WTClientTracker *)clientTracker didFinishedLoadingTargetCollectionFromURL:(nonnull NSURL *)URL{
    [BT_debugger showIt:self message:@"Client tracker loaded"];
}

- (void)clientTracker:(nonnull WTClientTracker *)clientTracker didFailToLoadTargetCollectionFromURL:(nonnull NSURL *)URL withError:(nonnull NSError *)error{
    [BT_debugger showIt:self message:[NSString stringWithFormat:@"Unable to load client tracker from URL '%@'. Reason: %@", [URL absoluteString], [error localizedDescription]]];
    NSString * wtcFileName = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"wtcFileName" defaultValue:@""];
    [self showAlert:@"WTC Error" theMessage:[NSString stringWithFormat:@"You have not added %@.wtc to your project. Check the file is in the bundle and check for typos.", wtcFileName] alertTag:99999];
    [self navLeftTap];
}

- (void)cloudTrackerFinishedLoading:(WTCloudTracker * __nonnull)cloudTracker
{
    NSLog(@"Cloud tracker is loaded");
}

- (void)cloudTracker:(WTCloudTracker * __nonnull)cloudTracker failedToLoadWithError:(NSError * __nonnull)error
{
    NSLog(@"Cloud tracker failed to load with error: %@", [error localizedDescription]);
}

@end







