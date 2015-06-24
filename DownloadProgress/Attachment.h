//
//  Attachment.h
//  DownloadProgress
//
//  Created by Puneet Arora on 6/24/15.
//  Copyright (c) 2015 NA LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Attachment : NSManagedObject

// to store aid
@property (nonatomic, retain) NSString * aid;
// to store name
@property (nonatomic, retain) NSString * name;
// to store webURL
@property (nonatomic, retain) NSString * webURL;
// to store url
@property (nonatomic, retain) id url;
// amountDownloaded
@property (nonatomic, retain) NSNumber * amountDownloaded;
// localName of the file/ attachment
@property (nonatomic, retain) NSString * localName;
// path where the file is created
@property (nonatomic, retain) NSString * localPath;
// fileSize on the device
@property (nonatomic, retain) NSNumber * localFileSize;
// set fileSizeToBeIgnored when app is crashed or killed when a download was active
// or when download was resumed back, to ignore chunk of data that has already been downloaded
@property (nonatomic, retain) NSNumber * fileSizeToBeIgnored;
// mimeType
@property (nonatomic, retain) NSString * mimeType;
// totalLength coming from the server
@property (nonatomic, retain) NSNumber * totalLength;
// YES if download is in progress
@property (nonatomic, retain) NSNumber * downloadInProgress;
// YES if download is paused
@property (nonatomic, retain) NSNumber * downloadPaused;
// YES if download is completed
@property (nonatomic, retain) NSNumber * downloadCompleted;
// YES if download is queued
@property (nonatomic, retain) NSNumber * downloadQueued;

@end
