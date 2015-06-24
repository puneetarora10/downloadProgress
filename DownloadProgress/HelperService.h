//
//  HelperService.h
//  DownloadProgress
//
//  Created by Puneet Arora on 6/24/15.
//  Copyright (c) 2015 NA LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HelperService : NSObject

#pragma mark Returns defaultInstance
// returns a default instance of HelperService to implement singleton
// in other words only one instance of HelperService object exists in the application
+ (HelperService *)defaultInstance;

#pragma mark appends generic errorMessage
// appends generic errorMessage
- (void)appendGenericErrorMessageTo:(NSMutableDictionary *)appendGenericErrorMessageToIt;

#pragma mark show loading view and NetworkActivityIndicator
// show loading view (Loading... label with activity indicator) and NetworkActivityIndicator
- (void)showLoadingViewAndNetworkActivityIndicatorOnView:(UIView *)view;

#pragma mark hide loading view and NetworkActivityIndicator
// hide loading view (Loading... label with activity indicator) and NetworkActivityIndicator
- (void)hideLoadingViewAndNetworkActivityIndicator;

#pragma mark shows a generic alertView
// show an alertView with a title, a message and a button with buttonTitle
- (void)showAlertViewWithTitle:(NSString *)title andMessage:(NSString *)message andACancelButtonWithTitle:(NSString *)buttonTitle;

#pragma mark replaces HTML entities
// replaces all html entities in string
- (NSString *)replaceHTMLEntities:(NSString *)string;

#pragma mark returns localFilePath
// return a path where file with name = fileName would be created on the device
- (NSString *)returnLocalFilePathForFileName:(NSString *)fileName;

@end
