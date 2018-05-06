/*
 *	Copyright 2016, Frederick Feraco
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


#import "FF_domainLogin.h"
#import "EmailValidator.h"

@interface FF_domainLogin () <EmailValidationDelegate> {
    NSString *selfTitle;
}

@end

@implementation FF_domainLogin

//viewDidLoad
-(void)viewDidLoad{
	[BT_debugger showIt:self theMessage:@"viewDidLoad"];
	[super viewDidLoad];
    
    selfTitle = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"navBarTitleText" defaultValue:@""];
    
    [self showEmailValidator];
}

-(void)showEmailValidator {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"FF_domainLogin" bundle:nil];
    UINavigationController *navController = [storyboard instantiateViewControllerWithIdentifier:@"showEmailValidatorNav"];
    EmailValidator *addController = navController.viewControllers.firstObject;
    addController.title = selfTitle;
    addController.delegate = self;
    addController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:NULL];
}

-(void)launchNextScreen {
    NSString *loadScreenItemId = @"E955BB795DAF797D1B730A0";
    [self loadScreenWithItemId:loadScreenItemId];
}

#pragma mark - EmailValidationDelegate

-(void)didCancelEmailValidation {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)didPassEmailValidation:(NSString *)email {
    NSLog(@"%@ with email: %@", NSStringFromSelector(_cmd), email);
    [self.navigationController popViewControllerAnimated:YES];
    [self launchNextScreen];
}


@end







