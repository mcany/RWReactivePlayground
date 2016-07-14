//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>


@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.signInService = [RWDummySignInService new];
    
    // initially hide the failure message
    self.signInFailureText.hidden = YES;
    
    /*
     // first test 1
     [[[self.usernameTextField.rac_textSignal
     map:^id(NSString *value) {
     return @(value.length);
     }
     
     ]filter:^BOOL(NSNumber *value) {
     return [value integerValue] > 3;
     }
     ]subscribeNext:^(id x) {
     NSLog(@"%@",x);
     }];
     */
    
    /*
     // first test 2
     RACSignal *usernameSourceSignal = self.usernameTextField.rac_textSignal;
     
     RACSignal *filteredUserName = [usernameSourceSignal filter:^BOOL(id value) {
     NSString *text = value;
     return [text length] > 3;
     }];
     
     [filteredUserName subscribeNext:^(id x) {
     NSLog(@"%@",x);
     }];
     */
    
    // second test 1
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *value) {
        return @([self isValidUsername:value]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *value) {
        return @([self isValidPassword:value]);
    }];
    
    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:^id(NSNumber *passwordValid) {
        return [passwordValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    RAC(self.usernameTextField, backgroundColor) = [validUsernameSignal map:^id(NSNumber *usernameValid) {
        return [usernameValid boolValue] ? [UIColor clearColor] : [UIColor yellowColor];
    }];
    
    RACSignal *validSignInButton = [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal]
                                                     reduce:^id(NSNumber *userNameValid, NSNumber *passwordValid){
                                                         return @([userNameValid boolValue] && [passwordValid boolValue]);
                                                     }];
    
    [validSignInButton subscribeNext:^(NSNumber *signUpActive) {
        self.signInButton.enabled = [signUpActive boolValue];
    }];
    
    [[[[self.signInButton
        rac_signalForControlEvents:UIControlEventTouchUpInside]
       doNext:^(id x) {
           self.signInButton.enabled = NO;
           self.signInFailureText.hidden = YES;
           NSLog(@"%@",x);
       }]
      flattenMap:^id(id x) {
          return [self signInSignal];
      }]
     subscribeNext:^(NSNumber *signedIn) {
         BOOL success = [signedIn boolValue];
         self.signInFailureText.hidden = success;
         if (success) {
             [self performSegueWithIdentifier:@"signInSuccess" sender:self];
         }
     }];
}

- (BOOL)isValidUsername:(NSString *)username {
    return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
    return password.length > 3;
}



-(RACSignal *)signInSignal{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

- (IBAction)signInButtonTouched:(id)sender {
    // disable all UI controls
    self.signInButton.enabled = NO;
    self.signInFailureText.hidden = YES;
    
    // sign in
    [self.signInService signInWithUsername:self.usernameTextField.text
                                  password:self.passwordTextField.text
                                  complete:^(BOOL success) {
                                      self.signInButton.enabled = YES;
                                      self.signInFailureText.hidden = success;
                                      if (success) {
                                          [self performSegueWithIdentifier:@"signInSuccess" sender:self];
                                      }
                                  }];
}

@end
