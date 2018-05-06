//
//  EmailValidator.h
//  EmailCheck
//
//  Created by Sergey Koval on 05/11/2016.
//  Copyright © 2016 Sergey Koval. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmailValidationDelegate <NSObject>
@required
-(void)didCancelEmailValidation;
-(void)didPassEmailValidation:(NSString*)email;
@end

@interface EmailValidator : UIViewController
@property (nonatomic, weak) id<EmailValidationDelegate> delegate;
@end
