//
//  EmailValidator.m
//  EmailCheck
//
//  Created by Sergey Koval on 05/11/2016.
//  Copyright © 2016 Sergey Koval. All rights reserved.
//

#import "EmailValidator.h"

@interface EmailValidator () <UITextFieldDelegate> {
    IBOutlet UITextField *emailTextField;
}

@end

@implementation EmailValidator

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    NSString *email = [[NSUserDefaults standardUserDefaults] valueForKey:@"emailTextField.text"];
    if (email) {
        emailTextField.text = email;
        [self checkEmail:email];
    }
}

#pragma mark - Helpers

-(void)checkEmail:(NSString*)email {
    emailTextField.backgroundColor = [UIColor whiteColor];
    BOOL isValid = [self validateEmailWithString:email];
    if (isValid || [emailTextField.text isEqualToString:@""]) {
        if ([self validateSchoolEmail:email]) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
            emailTextField.backgroundColor = [UIColor colorWithRed:225.0f/255.0f green:255.0f/255.0f blue:213.0f/255.0f alpha:1.0f];
        }
        else {
            emailTextField.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:213.0f/255.0f blue:213.0f/255.0f alpha:1.0f];
            [self wrongEmailError];
        }
    }
    else {
        emailTextField.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:213.0f/255.0f blue:213.0f/255.0f alpha:1.0f];
        [self wrongEmailError];
    }
}

-(IBAction)dismissKeyboard:(id)sender {
    [self.view endEditing:YES];
}

- (BOOL)validateEmailWithString:(NSString*)checkString {
    BOOL stricterFilter = NO;
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (BOOL)validateSchoolEmail:(NSString*)email {
    NSString *term = [email substringFromIndex:email.length - 10];
    return [term isEqualToString:@"shufsd.org"] ? YES : NO;
}

-(void)wrongEmailError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                     message:NSLocalizedString(@"Wrong email", nil)
                                                    delegate:nil
                                           cancelButtonTitle:@"ОК"
                                           otherButtonTitles:nil];
    [alert show];
}

#pragma mark - EmailValidationDelegate

-(IBAction)cancel:(id)sender {
    [self.delegate didCancelEmailValidation];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)save:(id)sender {
    [[NSUserDefaults standardUserDefaults] setValue:emailTextField.text forKey:@"emailTextField.text"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.delegate didPassEmailValidation:emailTextField.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    textField.backgroundColor = [UIColor colorWithRed:230.0f/255.0f green:230.0f/255.0f blue:230.0f/255.0f alpha:1.0f];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField{

    textField.backgroundColor = [UIColor whiteColor];
    BOOL isValid = [self validateEmailWithString:textField.text];
    if (isValid || [textField.text isEqualToString:@""]) {
        if ([self validateSchoolEmail:textField.text]) {
            self.navigationItem.rightBarButtonItem.enabled = YES;
            textField.backgroundColor = [UIColor colorWithRed:225.0f/255.0f green:255.0f/255.0f blue:213.0f/255.0f alpha:1.0f];
            return YES;
        }
        else {
            textField.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:213.0f/255.0f blue:213.0f/255.0f alpha:1.0f];
            [self wrongEmailError];
            return  NO;
        }
    }
    else {
        textField.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:213.0f/255.0f blue:213.0f/255.0f alpha:1.0f];
        [self wrongEmailError];
        return NO;
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    return [string isEqualToString:@"#"] ? NO : YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

@end
