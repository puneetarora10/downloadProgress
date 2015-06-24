//
//  Handles all interaction with the servers
//  WebService.h
//  DownloadProgress
//
//  Created by Puneet Arora on 6/24/15.
//  Copyright (c) 2015 NA LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebService : NSObject

#pragma mark Returns defaultInstance
// returns a default instance of WebService to implement singleton
// in other words only one instance of WebService object exists in the application
+ (WebService *)defaultInstance;

#pragma mark Download AttachmentsData
// web service call to download attachmentsData
- (id)returnAttachmentsData;


@end
