//
//  CCLogin.m
//  Nextcloud iOS
//
//  Created by Marino Faggiana on 09/04/15.
//  Copyright (c) 2017 TWS. All rights reserved.
//
//  Author Marino Faggiana <m.faggiana@twsweb.it>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "CCLogin.h"
#import "AppDelegate.h"
#import "CCUtility.h"
#import "NCBridgeSwift.h"
#import "NCNetworkingSync.h"
#import "CCScanViewController.h"

@interface CCLogin ()
{
    UIView *rootView;
}

@property (nonatomic, strong) CCScanViewController *scanVC;
@end

@implementation CCLogin

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.imageBrand.image = [UIImage imageNamed:@"loginLogo"];
    self.login.backgroundColor = [NCBrandColor sharedInstance].customer;
    
    // Bottom label
    self.bottomLabel.text = NSLocalizedString([NCBrandOptions sharedInstance].textLoginProvider, nil);
    self.bottomLabel.userInteractionEnabled = YES;
    
    if ([NCBrandOptions sharedInstance].disable_linkLoginProvider) {
        self.bottomLabel.hidden = YES;
    } else {
    
        if (self.view.frame.size.width == ([[UIScreen mainScreen] bounds].size.width*([[UIScreen mainScreen] bounds].size.width<[[UIScreen mainScreen] bounds].size.height))+([[UIScreen mainScreen] bounds].size.height*([[UIScreen mainScreen] bounds].size.width>[[UIScreen mainScreen] bounds].size.height))) {
        
            // Portrait
            self.bottomLabel.hidden = NO;
        
        } else {
        
            // Landscape
            self.bottomLabel.hidden = YES;
        }
    }
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tabBottomLabel)];
    [self.bottomLabel addGestureRecognizer:tapGesture];
    
    self.annulla.tintColor = [NCBrandColor sharedInstance].customer;
    
    [self.baseUrl setDelegate:self];
    [self.password setDelegate:self];
    [self.user setDelegate:self];
    
    [self.baseUrl setFont:[UIFont systemFontOfSize:13]];
    [self.user setFont:[UIFont systemFontOfSize:13]];
    [self.password setFont:[UIFont systemFontOfSize:13]];
    
    self.imageBaseUrl.image = [CCGraphics changeThemingColorImage:[UIImage imageNamed:@"loginURL"] color:[NCBrandColor sharedInstance].customer];
    self.imageUser.image = [CCGraphics changeThemingColorImage:[UIImage imageNamed:@"loginUser"] color:[NCBrandColor sharedInstance].customer];
    self.imagePassword.image = [CCGraphics changeThemingColorImage:[UIImage imageNamed:@"loginPassword"] color:[NCBrandColor sharedInstance].customer];

    self.loadingBaseUrl.image = [UIImage animatedImageWithAnimatedGIFURL:[[NSBundle mainBundle] URLForResource: @"loading" withExtension:@"gif"]];
    self.loadingBaseUrl.hidden = YES;
    
    // Brand
    if ([NCBrandOptions sharedInstance].disable_request_login_url) {
        
        _baseUrl.text = [NCBrandOptions sharedInstance].loginBaseUrl;
        _imageBaseUrl.hidden = YES;
        _baseUrl.hidden = YES;
    }

    if (_loginType == loginAdd) {
        
    }
    
    if (_loginType == loginAddForced) {
        _annulla.hidden = YES;
    }
    
    if (_loginType == loginModifyPasswordUser) {
        
        _baseUrl.text = app.activeUrl;
        _baseUrl.userInteractionEnabled = NO;
        _baseUrl.textColor = [UIColor lightGrayColor];
        _user.text = app.activeUser;
        _user.userInteractionEnabled = NO;
        _user.textColor = [UIColor lightGrayColor];
    }
    
    self.baseUrl.placeholder = NSLocalizedString(@"_login_url_", nil);
    self.user.placeholder = NSLocalizedString(@"_username_", nil);
    self.password.placeholder = NSLocalizedString(@"_password_", nil);
    
    [self.annulla setTitle:NSLocalizedString(@"_cancel_", nil) forState:UIControlStateNormal];
    [self.login setTitle:NSLocalizedString(@"_login_", nil) forState:UIControlStateNormal];    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // verify URL
    if (_loginType == loginModifyPasswordUser && [self.baseUrl.text length] > 0)
        [self testUrl];
}

// E' apparsa
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

//
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if ([self.delegate respondsToSelector:@selector(loginDisappear)])
        [self.delegate loginDisappear];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        if (![NCBrandOptions sharedInstance].disable_linkLoginProvider) {
        
            if (self.view.frame.size.width == ([[UIScreen mainScreen] bounds].size.width*([[UIScreen mainScreen] bounds].size.width<[[UIScreen mainScreen] bounds].size.height))+([[UIScreen mainScreen] bounds].size.height*([[UIScreen mainScreen] bounds].size.width>[[UIScreen mainScreen] bounds].size.height))) {
            
                // Portrait
                self.bottomLabel.hidden = NO;
            
            } else {
            
                // Landscape
                self.bottomLabel.hidden = YES;
            }
        }
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark == Chech Server URL ==
#pragma --------------------------------------------------------------------------------------------

- (void)testUrl
{
    self.login.enabled = NO;
    self.loadingBaseUrl.hidden = NO;
    // Check whether baseUrl contain protocol. If not add https:// by default.
    if(![self.baseUrl.text hasPrefix:@"https"] && ![self.baseUrl.text hasPrefix:@"http"]) {
      self.baseUrl.text = [NSString stringWithFormat:@"https://%@",self.baseUrl.text];
    }
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.baseUrl.text] cachePolicy:0 timeoutInterval:20.0];
    [request addValue:[CCUtility getUserAgent] forHTTPHeaderField:@"User-Agent"];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.login.enabled = YES;
            self.loadingBaseUrl.hidden = YES;
        });

        if (error != nil) {
            
            NSLog(@"[LOG] Error: %ld - %@",(long)[error code] , [error localizedDescription]);
            
            // self signed certificate
            if ([error code] == NSURLErrorServerCertificateUntrusted) {
                
                NSLog(@"[LOG] Error NSURLErrorServerCertificateUntrusted");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[CCCertificate sharedManager] presentViewControllerCertificateWithTitle:[error localizedDescription] viewController:self delegate:self];
                });
            
            } else {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_connection_error_", nil) message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
                    
                    [alertController addAction:okAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            }
            
        }
    }];
    
    [task resume];
}

- (void)trustedCerticateAccepted
{
    NSLog(@"[LOG] Certificate trusted");
}

- (void)trustedCerticateDenied
{
    if (_loginType == loginModifyPasswordUser)
        [self handleAnnulla:self];
}

-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    // The pinnning check
    
    if ([[CCCertificate sharedManager] checkTrustedChallenge:challenge]) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark == Login ==
#pragma --------------------------------------------------------------------------------------------

- (void)loginCloud
{
    self.login.enabled = NO;
    self.loadingBaseUrl.hidden = NO;

    // remove last char if /
    if ([[self.baseUrl.text substringFromIndex:[self.baseUrl.text length] - 1] isEqualToString:@"/"])
        self.baseUrl.text = [self.baseUrl.text substringToIndex:[self.baseUrl.text length] - 1];
    
    NSError *error = [[NCNetworkingSync sharedManager] checkServer:[NSString stringWithFormat:@"%@%@", self.baseUrl.text, webDAV] user:self.user.text userID:self.user.text password:self.password.text];

    if (!error) {
        
        // account
        NSString *account = [NSString stringWithFormat:@"%@ %@", self.user.text, self.baseUrl.text];
        
        if (_loginType == loginModifyPasswordUser) {
            
            // Change Password
            tableAccount *tbAccount = [[NCManageDatabase sharedInstance] setAccountPassword:account password:self.password.text];
            
            // Setting App active account
            [app settingActiveAccount:tbAccount.account activeUrl:tbAccount.url activeUser:tbAccount.user activeUserID:tbAccount.userID activePassword:tbAccount.password];

            // Dismiss
            if ([self.delegate respondsToSelector:@selector(loginSuccess:)])
                [self.delegate loginSuccess:_loginType];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            
        } else {

            [[NCManageDatabase sharedInstance] deleteAccount:account];
            [[NCManageDatabase sharedInstance] addAccount:account url:self.baseUrl.text user:self.user.text password:self.password.text];
            
            // Read User Profile
            CCMetadataNet *metadataNet = [[CCMetadataNet alloc] initWithAccount:account];
            metadataNet.action = actionGetUserProfile;
            [app.netQueue addOperation:[[OCnetworking alloc] initWithDelegate:self metadataNet:metadataNet withUser:self.user.text withUserID:self.user.text withPassword:self.password.text withUrl:self.baseUrl.text]];
        }
        
    } else {
        
        if ([error code] != NSURLErrorServerCertificateUntrusted) {
            
            NSString *description = [error.userInfo objectForKey:@"NSLocalizedDescription"];
            NSString *message = [NSString stringWithFormat:@"%@.\n%@", NSLocalizedStringFromTable(@"_not_possible_connect_to_server_", @"Error", nil), description];
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_error_", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
        
    self.login.enabled = YES;
    self.loadingBaseUrl.hidden = YES;
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark ==== User Profile  ====
#pragma --------------------------------------------------------------------------------------------

- (void)getUserProfileFailure:(CCMetadataNet *)metadataNet message:(NSString *)message errorCode:(NSInteger)errorCode
{
    [[NCManageDatabase sharedInstance] deleteAccount:metadataNet.account];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_error_", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
    
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)getUserProfileSuccess:(CCMetadataNet *)metadataNet userProfile:(OCUserProfile *)userProfile
{
    // Verify if the account already exists
    if (userProfile.id.length > 0 && self.baseUrl.text.length > 0 && self.user.text.length > 0) {
    
        tableAccount *accountAlreadyExists = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"url = %@ AND user = %@ AND userID != %@", self.baseUrl.text, userProfile.id, self.user.text]];
        
        if (accountAlreadyExists) {
            
            [[NCManageDatabase sharedInstance] deleteAccount:metadataNet.account];
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"_error_", nil) message:[NSString stringWithFormat:NSLocalizedString(@"_account_already_exists_", nil), userProfile.id] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"_ok_", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
            
            [alertController addAction:okAction];
            [self presentViewController:alertController animated:YES completion:nil];
            
            return;
        }
    }
    
    // Verify if account is a valid account
    tableAccount *account = [[NCManageDatabase sharedInstance] getAccountWithPredicate:[NSPredicate predicateWithFormat:@"account = %@", metadataNet.account]];
    
    if (account) {
    
        // Update User (+ userProfile.id)
        [[NCManageDatabase sharedInstance] setAccountsUserProfile:userProfile];
        
        // Set this account as default
        tableAccount *account = [[NCManageDatabase sharedInstance] setAccountActive:metadataNet.account];
        if (account) {
        
            // Setting App active account
            [app settingActiveAccount:account.account activeUrl:account.url activeUser:account.user activeUserID:account.userID activePassword:account.password];
    
            // Ok ! Dismiss
            if ([self.delegate respondsToSelector:@selector(loginSuccess:)])
                [self.delegate loginSuccess:_loginType];
        
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark == TextField ==
#pragma --------------------------------------------------------------------------------------------

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == self.password) {
        self.toggleVisiblePassword.hidden = NO;
        self.password.defaultTextAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0f], NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    }
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField == self.password) {
        self.toggleVisiblePassword.hidden = YES;
        self.password.defaultTextAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0f], NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    }
}

#pragma --------------------------------------------------------------------------------------------
#pragma mark == Action ==
#pragma --------------------------------------------------------------------------------------------

- (void)tabBottomLabel
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NCBrandOptions sharedInstance].linkLoginProvider]];
}

- (IBAction)handlebaseUrlchange:(id)sender
{
    if ([self.baseUrl.text length] > 0)
        [self performSelector:@selector(testUrl) withObject:nil];
}

- (IBAction)handleButtonLogin:(id)sender
{
    if ([self.baseUrl.text length] > 0 && [self.user.text length] && [self.password.text length])
        [self performSelector:@selector(loginCloud) withObject:nil];
}

- (IBAction)handleAnnulla:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)handleToggleVisiblePassword:(id)sender
{
    NSString *currentPassword = self.password.text;
    
    self.password.secureTextEntry = ! self.password.secureTextEntry;
    
    self.password.text = @"";
    self.password.text = currentPassword;
    self.password.defaultTextAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0f], NSForegroundColorAttributeName: [UIColor darkGrayColor]};
}

- (IBAction)handleScanQRCode:(id)sender {
    //��ȡ.storyboard ��ͼ
    CCScanViewController *scanViewController  = [[UIStoryboard storyboardWithName:@"CCScanViewController" bundle:nil] instantiateViewControllerWithIdentifier:@"scanStoryboard"];

    __weak typeof(self) weakSelf = self;
    //��ȡɨ��ֵ
    scanViewController.resultBlock = ^(NSString *str) {
        weakSelf.baseUrl.text = str;
        // verify URL
        if ([weakSelf.baseUrl.text length] > 0)
            [weakSelf testUrl];
    };
    
    [self presentViewController:scanViewController animated:YES completion:nil];
}

@end
