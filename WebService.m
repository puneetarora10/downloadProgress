//
//  Handles all interaction with the servers
//  WebService.m
//  DownloadProgress
//
//  Created by Puneet Arora on 6/24/15.
//  Copyright (c) 2015 NA LLC. All rights reserved.
//

#import "WebService.h"
#import "HelperService.h"

@interface WebService ()

// server's url string
@property (strong, nonatomic) NSString *serverURLString;

@end


@implementation WebService

#pragma mark - Initialization Methods

// returns a default instance of WebService to implement singleton
// in other words only one instance of WebService object exists in the application
+ (WebService *)defaultInstance {
    static WebService *_defaultInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultInstance = [[WebService alloc] init];
    });
    
    return _defaultInstance;
}

// initialize serverURLString
- (NSString *)serverURLString {
    if(!_serverURLString) {
        _serverURLString = @"http://sidechats.appspot.com/codingtest/files/";
    }
    return _serverURLString;
}

#pragma mark - Web service calls

#pragma mark Get Attachments' data
// make a web service call to get attachments' data
// if data is recieved from server then return that data
// else errorMessage
- (id)returnAttachmentsData {
    id dataToBeReturned;
    // make a post request to authenticate user
    // create URL
    NSString *serverURLString = self.serverURLString;
    NSURL *serverURL = [NSURL URLWithString:serverURLString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:serverURL];
    // setTimeoutInterval 15.0f so that the request should be finished in 15 seconds (successfully or unsuccessfully)
    [urlRequest setTimeoutInterval:15.0f];
    [urlRequest setHTTPMethod:@"GET"];
    
    // create an asynchronous request
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    @try {
        // no need for synchronous request as its called on a different queue
        NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
        if ([data length] > 0 && error == nil) {
            // serialize data returned from server
            id dataReturnedFromServer = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            
            if ([dataReturnedFromServer isKindOfClass:[NSArray class]]) {// dataReturnedFromServer is an instance of NSArray
                dataToBeReturned = [[NSMutableArray alloc] init];
                for (id element in dataReturnedFromServer) {
                    [dataToBeReturned addObject:[element mutableCopy]];
                }
            }
            else { // attachment's data couldn't be downloaded // append generic errorMessage
                dataToBeReturned = [[NSMutableDictionary alloc] init];
                [[HelperService defaultInstance] appendGenericErrorMessageTo:dataToBeReturned];
            }
        }
        else {// append generic errorMessage
            dataToBeReturned = [[NSMutableDictionary alloc] init];
            [[HelperService defaultInstance] appendGenericErrorMessageTo:dataToBeReturned];
        }
    }
    @catch (NSException *exception) { // append generic errorMessage
        [[HelperService defaultInstance] appendGenericErrorMessageTo:dataToBeReturned];
    }
    @finally {
        // no need to do anything right now
    }
    
    return dataToBeReturned;
}

@end

