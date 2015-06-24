//
//  AttachmentCell.h
//  DownloadProgress
//
//  Created by Puneet Arora on 6/24/15.
//  Copyright (c) 2015 NA LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AttachmentCell : UITableViewCell

// to display fileName
@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
// to display fileSize or Status (Active/ Paused/ Queued/ Black)
@property (weak, nonatomic) IBOutlet UILabel *fileSizeOrStatusLabel;
// to indicate progress of download
@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgressView;

@end
