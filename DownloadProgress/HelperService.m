//
//  HelperService.m
//  DownloadProgress
//
//  Created by Puneet Arora on 6/24/15.
//  Copyright (c) 2015 NA LLC. All rights reserved.
//

#import "HelperService.h"
#import "QuartzCore/QuartzCore.h"

// private declarations
@interface HelperService ()
// activityIndicator
@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
// loading view
@property (strong, nonatomic) UIView *loadingView;
@end

@implementation HelperService

#define GENERIC_ERROR_MESSAGE @"Sorry, Slow Internet Connection on your device!!"

// returns a default instance of HelperService to implement singleton
// in other words only one instance of HelperService object exists in the application
+ (HelperService *)defaultInstance {
    static HelperService *_defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultInstance = [[HelperService alloc] init];
    });
    
    return _defaultInstance;
}

// appends generic errorMessage
- (void)appendGenericErrorMessageTo:(NSMutableDictionary *)appendGenericErrorMessageToIt {
    [appendGenericErrorMessageToIt setObject:GENERIC_ERROR_MESSAGE forKey:@"errorMessage"];
}

// show loading view (Loading... label with activity indicator) and NetworkActivityIndicator
- (void)showLoadingViewAndNetworkActivityIndicatorOnView:(UIView *)view {
    // show loadingView
    [self showLoadingViewOnView:view];
    
    // show NetworkActivityIndicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

// hide loading view (Loading... label with activity indicator) and NetworkActivityIndicator
- (void)hideLoadingViewAndNetworkActivityIndicator {
    // hide loadingView
    [self hideLoadingView];
    
    // hide NetworkActivityIndicator
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

// show loading view (Loading... label with activity indicator) on a view
- (void)showLoadingViewOnView:(UIView *)view {
    // modify activityIndicatorViewStyle
    self.activityIndicator.frame = CGRectMake(75, 75, 20, 20);
    self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    // add activityIndicator as subView to loadingView
    [self.loadingView addSubview:self.activityIndicator];
    // create Loading... label
    UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, 115, 130, 22)];
    // set properties
    loadingLabel.backgroundColor = [UIColor clearColor];
    loadingLabel.textColor = [UIColor whiteColor];
    loadingLabel.adjustsFontSizeToFitWidth = YES;
    loadingLabel.text = @"Loading...";
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    // add loadingLabel as subView to loadingView
    [self.loadingView addSubview:loadingLabel];
    // set loadingView's center to view's center
    self.loadingView.center = view.center;
    // add loadingView as subView to "view"
    [view addSubview:self.loadingView];
    // start activityIndicator
    [self.activityIndicator startAnimating];
}

// hide loading view (Loading... label with activity indicator)
- (void)hideLoadingView {
    // hideActivityIndicator
    [self hideActivityIndicator];
    // remove loadingView from superView
    [self.loadingView removeFromSuperview];
}

// hides activity indicator (already existing) on a view
- (void)hideActivityIndicator {
    [self.activityIndicator stopAnimating];
}

// show an alertView with a title, a message and a cancel button with buttonTitle
- (void)showAlertViewWithTitle:(NSString *)title andMessage:(NSString *)message andACancelButtonWithTitle:(NSString *)buttonTitle {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:buttonTitle otherButtonTitles:nil, nil];
    [alertView show];
}

// replaces all html entities in string
- (NSString *)replaceHTMLEntities:(NSString *)string {
    // string to return
    NSString  *stringWithReplacedHTMLEntities = nil;
    
    if (string) {
        // replace &amp;
        stringWithReplacedHTMLEntities = [string stringByReplacingOccurrencesOfString:@"&amp;" withString: @"&"];
        // replace &quot;
        stringWithReplacedHTMLEntities = [stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
        // replace &#x27;
        stringWithReplacedHTMLEntities = [stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&#x27;" withString:@"'"];
        // replace &#x39;
        stringWithReplacedHTMLEntities = [stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&#x39;" withString:@"'"];
        // replace &#x92;
        stringWithReplacedHTMLEntities = [stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&#x92;" withString:@"'"];
        // replace &#x96;
        stringWithReplacedHTMLEntities = [ stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&#x96;" withString:@"'"];
        // replace &gt;
        stringWithReplacedHTMLEntities = [stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        // replace &lt;
        stringWithReplacedHTMLEntities = [stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        // replace &#8211;
        stringWithReplacedHTMLEntities = [stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&#8211;" withString:@"-"];
        // replace &#8271;
        stringWithReplacedHTMLEntities = [stringWithReplacedHTMLEntities stringByReplacingOccurrencesOfString:@"&#8271;" withString:@";"];
    }
    
    return stringWithReplacedHTMLEntities;
}

// return a path where file with name = fileName would be created on the device
- (NSString *)returnLocalFilePathForFileName:(NSString *)fileName {
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [documentDir stringByAppendingPathComponent:fileName];
}

@end
