//
//  HomeViewController.m
//  DownloadProgress
//
//  Created by Puneet Arora on 6/24/15.
//  Copyright (c) 2015 NA LLC. All rights reserved.
//

#import "HomeViewController.h"
#import "HelperService.h"
#import "WebService.h"
#import "Attachment.h"
#import "AttachmentCell.h"
#import "AppDelegate.h"

@interface HomeViewController ()

// queue to be used to download stuff for HomeViewController
@property (strong, nonatomic) NSOperationQueue *queue;

// attachments or files to be displayed
@property (strong, nonatomic) NSMutableArray *attachments;

// sortByIdentifier - to be used to for sorting
@property (assign, nonatomic) NSUInteger sortByIdentifier;

// sortBy - to sort attachments
@property (strong, nonatomic) NSMutableArray *sortBy;

// number of downloads in progress
@property (assign, nonatomic) NSUInteger numberOfDownloadsInProgress;

// maximum number of downloads allowed
@property (assign, nonatomic) NSUInteger maxNoOfDownloadsAllowed;

// for faster access ["urlString1":1,...]
@property (strong, nonatomic) NSMutableDictionary *urlStringForIndexPathRow;

// for faster access of attachments which are queued
@property (strong, nonatomic) NSMutableArray *downloadQueueArray;

// to store urlConnection associated with an attachment
@property (strong, nonatomic) NSMutableDictionary *urlConnectionForAttachmentIndex;

// managedObjectContext
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

// fetchRequest
@property (strong, nonatomic) NSFetchRequest *fetchRequest;

// attachmentEntityDescription
@property (strong, nonatomic) NSEntityDescription *attachmentEntityDescription;

// called when "Refresh" button is clicked
- (IBAction)refreshButtonClicked:(id)sender;
// called when "Sort" button is clicked
- (IBAction)sortButtonClicked:(id)sender;

@end

@implementation HomeViewController

#define ATTACHMENT_ENTITY_NAME @"Attachment"
#define HOME_VIEW_CONTROLLER_QUEUE_NAME @"HomeViewController Queue"
#define HOME_VIEW_CONTROLLER_TITLE @"Files - Sorted By"

#define SORT_BY_NAME @"name"
#define SORT_BY_AMOUNT_DOWNLOADED @"amountDownloaded"
#define SORT_BY_TOTAL_LENGTH @"totalLength"

#define ATTACHMENT_CELL_IDENTIFIER @"AttachmentCell"

#define DOWNLOAD_BUTTON_TITLE @"Download"
#define PAUSE_BUTTON_TITLE @"Pause"
#define DELETE_BUTTON_TITLE @"Delete"
#define RESUME_BUTTON_TITLE @"Resume"
#define CANCEL_BUTTON_TITLE @"Cancel"

#define STATUS_BLACK @"Black"
#define STATUS_ACTIVE @"Active"
#define STATUS_PAUSED @"Paused"
#define STATUS_QUEUED @"Queued"

- (void)viewDidLoad {
    // set rowHeight
    self.tableView.rowHeight = 60.0;
    [super viewDidLoad];
    
    // initialize sortByIdentifier
    self.sortByIdentifier = 0;
    // initialize maxNoOfDownloadsAllowed
    self.maxNoOfDownloadsAllowed = 1;
    // initialize numberOfDownloadsInProgress
    self.numberOfDownloadsInProgress = 0;
    
    // intialize attachments
    [self initializeAttachmentsUsingAttachmentEntity];
    if ([self.attachments count] == 0) {// make a web service call as there are no Attachment Entities
        [self initializeAttachmentEntityAndAttachments];
    }
    
    // check for attachments with downloadInProgress = YES and downloadQueued = YES
    // to take care of the cases when app is killed/ crashed
    [self checkIfAnyDownloadsNeedToBeStartedOrQueued];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Initialization Methods

// initialize attachments
- (NSMutableArray *)attachments {
    // if attachments doesn't exist (eg. called for the first time)
    if (!_attachments) {
        _attachments = [[NSMutableArray alloc] init];
    }
    return _attachments;
}

// makes a web service call to fetch new data, parses the json, creates Attachment entities and adds them to self.attachments
- (void) initializeAttachmentEntityAndAttachments {
    // show loading view (Loading... label with activity indicator) and NetworkActivityIndicator
    [[HelperService defaultInstance] showLoadingViewAndNetworkActivityIndicatorOnView:self.view];
    // download attachments from the server
    [self.queue addOperationWithBlock:^{
        id dataReturnedFromWebServiceCall = [[WebService defaultInstance] returnAttachmentsData];
        if ([dataReturnedFromWebServiceCall isKindOfClass:[NSArray class]]) { // attachments data is recieved
            // loop through attachmentData and create attachment entities
            for (NSDictionary *attachmentData in dataReturnedFromWebServiceCall) {
                Attachment *attachment = [NSEntityDescription
                                          insertNewObjectForEntityForName:ATTACHMENT_ENTITY_NAME
                                          inManagedObjectContext:self.managedObjectContext];
                // set properties
                attachment.aid = [attachmentData objectForKey:@"id"];
                attachment.name = [[HelperService defaultInstance] replaceHTMLEntities:[attachmentData objectForKey:@"name"]];
                NSString *webURL = [[attachmentData objectForKey:@"url"] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
                attachment.webURL = webURL;
                attachment.url = [NSURL URLWithString:webURL];
                // set amountDownloaded and fileSize to be 0.0 to avoid any errors if the user clicks on Sort
                attachment.amountDownloaded = 0;
                attachment.localFileSize = 0;
                // sort attachments using sortByIdentifier
                [self sortAttachmentsBy:self.sortByIdentifier];
                // persist Data
                [self persistData];
            }
            
            // intialize self.attachments
            [self initializeAttachmentsUsingAttachmentEntity];
            // get hold of Main Queue to reload tableView
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                // hide loading view (Loading... label with activity indicator) and NetworkActivityIndicator
                [[HelperService defaultInstance] hideLoadingViewAndNetworkActivityIndicator];
                // reload tableView
                [self.tableView reloadData];
            }];
        }
        else { // some errorMessage show "UIAlertView"
            // get hold of Main Queue to show UIAlertView
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                // hide loading view (Loading... label with activity indicator) and NetworkActivityIndicator
                [[HelperService defaultInstance] hideLoadingViewAndNetworkActivityIndicator];
                // show alertView
                [[HelperService defaultInstance] showAlertViewWithTitle:@"Error" andMessage:[dataReturnedFromWebServiceCall objectForKey:@"errorMessage"] andACancelButtonWithTitle:@"OK"];
            }];
        }
    }];
}

// check for attachments with downloadInProgress = YES and downloadQueued = YES
// to take care of the cases when app is killed/ crashed
- (void) checkIfAnyDownloadsNeedToBeStartedOrQueued {
    // loop through self.attachments
    BOOL startDownloadingQueuedAttachments = YES;
    for (Attachment *attachment in self.attachments) {
        if ([attachment.downloadInProgress boolValue]) {// resume this attachment
            startDownloadingQueuedAttachments = NO; // because it will automatically get called as soon as this download ends
            // it was active so some data has been written to the file so to ignore those packets!
            attachment.fileSizeToBeIgnored = attachment.localFileSize;
            // save it in urlStringForIndexPathRow
            [self.urlStringForIndexPathRow setObject:[@([self.attachments indexOfObject:attachment]) stringValue] forKey:attachment.webURL];
            // start download
            // increment numberOfDownloadsInProgress
            self.numberOfDownloadsInProgress++;
            attachment.downloadInProgress = [NSNumber numberWithBool:YES];
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:[NSMutableURLRequest requestWithURL:attachment.url] delegate:self startImmediately:YES];
            // add this to urlConnectionForAttachmentIndex
            [self.urlConnectionForAttachmentIndex setObject:urlConnection forKey:[@([self.attachments indexOfObject:attachment]) stringValue]];
        }
        else if ([attachment.downloadQueued boolValue]) {// add it to the downloadQueueArray
            [self.urlStringForIndexPathRow setObject:[@([self.attachments indexOfObject:attachment]) stringValue] forKey:attachment.webURL];
            
            [self.downloadQueueArray addObject:attachment];
        }
    }
    // see if any queued attachments can be started
    if (startDownloadingQueuedAttachments) {
        [self startDownloadingQueuedAttachments];
    }
}

// intialize attachments using AttachmentEntity
- (void)initializeAttachmentsUsingAttachmentEntity {
    NSError *error;// no need to do anything right now
    [self.fetchRequest setEntity:self.attachmentEntityDescription];
    self.attachments = (NSMutableArray *)[self.managedObjectContext executeFetchRequest:self.fetchRequest error:&error];
    // sort attachments using sortByIdentifier
    [self sortAttachmentsBy:self.sortByIdentifier];
}

// initializing managedObjectContext
- (NSManagedObjectContext *)managedObjectContext {
    // if managedObjectContext doesn't exist (eg. called for the first time)
    if (!_managedObjectContext) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        _managedObjectContext = [appDelegate managedObjectContext];
    }
    return _managedObjectContext;
}

// initializing fetchRequest
- (NSFetchRequest *)fetchRequest {
    // if fetchRequest doesn't exist (eg. called for the first time)
    if (!_fetchRequest) {
        _fetchRequest = [[NSFetchRequest alloc] init];
    }
    return _fetchRequest;
}

// initializing attachmentEntityDescription
- (NSEntityDescription *) attachmentEntityDescription {
    // if attachmentEntityDescription doesn't exist (eg. called for the first time)
    if (!_attachmentEntityDescription) {
        _attachmentEntityDescription = [NSEntityDescription
                                        entityForName:ATTACHMENT_ENTITY_NAME inManagedObjectContext:self.managedObjectContext];
    }
    return _attachmentEntityDescription;
}

// initializing queue
- (NSOperationQueue *)queue {
    // if queue doesn't exist (eg. called for the first time)
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        _queue.name = HOME_VIEW_CONTROLLER_QUEUE_NAME;
    }
    return _queue;
}

// initializing sortBy
- (NSMutableArray *)sortBy {
    // if sortBy doesn't exist (eg. called for the first time)
    if (!_sortBy) {
        _sortBy = [[NSMutableArray alloc] init];
        [_sortBy addObject:SORT_BY_NAME];
        [_sortBy addObject:SORT_BY_AMOUNT_DOWNLOADED];
        [_sortBy addObject:SORT_BY_TOTAL_LENGTH];
    }
    return _sortBy;
}

// initializing downloadQueueArray
- (NSMutableArray *)downloadQueueArray {
    // if downloadQueueArray doesn't exist (eg. called for the first time)
    if (!_downloadQueueArray) {
        _downloadQueueArray = [[NSMutableArray alloc] init];
    }
    return _downloadQueueArray;
}

// initializing urlStringForIndexPathRow
- (NSMutableDictionary *)urlStringForIndexPathRow {
    // if urlStringForIndexPathRow doesn't exist (eg. called for the first time)
    if (!_urlStringForIndexPathRow) {
        _urlStringForIndexPathRow = [[NSMutableDictionary alloc] init];
    }
    return _urlStringForIndexPathRow;
}

// initializing urlConnectionForAttachmentIndex
- (NSMutableDictionary *)urlConnectionForAttachmentIndex {
    // if urlConnectionForAttachmentIndex doesn't exist (eg. called for the first time)
    if (!_urlConnectionForAttachmentIndex) {
        _urlConnectionForAttachmentIndex = [[NSMutableDictionary alloc] init];
    }
    return _urlConnectionForAttachmentIndex;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.attachments.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = ATTACHMENT_CELL_IDENTIFIER;
    AttachmentCell *attachmentCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!attachmentCell) {// create attachmentCell
        attachmentCell = [[AttachmentCell alloc] init];
    }
    // get attachment
    Attachment *attachment = [self.attachments objectAtIndex:indexPath.row];
    // Configure the cell
    attachmentCell.fileNameLabel.text = attachment.name;
    // update fileSizeOrStatusLabel
    [self updateFileSizeOrStatusLabelFor:attachmentCell andAttachment:attachment];
    // update downloadProgressView
    [self updateProgressForDownloadProgressViewFor:attachmentCell andAttachment:attachment];
    
    return attachmentCell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // find attachment for row selected
    Attachment *attachment = [self.attachments objectAtIndex:indexPath.row];
    // show alertView
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Choose?" message:@"Please click on a Button" delegate:self cancelButtonTitle:CANCEL_BUTTON_TITLE otherButtonTitles:nil, nil];
    // add Download/ Pause/ Resume button
    if (![attachment.downloadCompleted boolValue]) {// only if downloadCompleted = NO else just show Delete and Cancel buttons
        NSString *downloadButtonTitle = DOWNLOAD_BUTTON_TITLE;
        if ([attachment.downloadInProgress boolValue]) {
            downloadButtonTitle = PAUSE_BUTTON_TITLE;
        }
        else if ([attachment.downloadPaused boolValue]) {
            downloadButtonTitle = RESUME_BUTTON_TITLE;
        }
        // add button
        [alertView addButtonWithTitle:downloadButtonTitle];
    }
    // add Delete Button
    [alertView addButtonWithTitle:DELETE_BUTTON_TITLE];
    // to be used to get attachment
    alertView.tag = indexPath.row;
    [alertView show];
}

#pragma mark - Navigation Bar Button clicks
// refresh button is clicked
- (IBAction)refreshButtonClicked:(id)sender {
    // cancel all urlConnections
    NSArray *activeURLConnections = [self.urlConnectionForAttachmentIndex allValues];
    for (NSURLConnection *urlConnection in activeURLConnections) {
        [urlConnection cancel];
    }
    // empty previous urlConnection related data
    self.urlConnectionForAttachmentIndex = nil;
    self.downloadQueueArray = nil;
    self.urlStringForIndexPathRow = nil;
    self.numberOfDownloadsInProgress = 0;
    // empty current attachments
    self.attachments = nil;
    // delete Attachment entities
    [self deleteAllEntities:ATTACHMENT_ENTITY_NAME];
    // download JSON again from the server
    [self initializeAttachmentEntityAndAttachments];
}

// sort button is clicked
- (IBAction)sortButtonClicked:(id)sender {
    if (self.sortByIdentifier == 2) {// set to 0
        self.sortByIdentifier = 0;
    }
    else { // increment identifier
        self.sortByIdentifier = self.sortByIdentifier + 1;
    }
    
    [self sortAttachmentsBy:self.sortByIdentifier];
}

// sorts attachment and change's navigationItem's title to show curent ordering key
- (void) sortAttachmentsBy:(NSUInteger) sortByIdentifier {
    // find what to soryBy
    NSString *sortBy = [self.sortBy objectAtIndex:sortByIdentifier];
    // ascending = NO for amountDownloaded and totalFileLength
    BOOL ascending = NO;
    if ([sortBy isEqualToString:@"name"]) {
        ascending = YES;
    }
    // create a sortDescriptor
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:sortBy ascending:ascending];
    // sort attachments
    self.attachments = (NSMutableArray *)[self.attachments sortedArrayUsingDescriptors:@[sortDescriptor]];
    // reload tableView with sorted attachments
    [self.tableView reloadData];
    // change title
    [self.navigationItem setTitle:[NSString stringWithFormat:@"%@ %@",HOME_VIEW_CONTROLLER_TITLE,sortBy]];
}

#pragma mark - Other Methods
#pragma mark Delete Attachment
// deletes attachment from the device..
- (void) deleteAttachment:(Attachment *)attachment {
    // cancel urlconnection if it exists
    NSURLConnection *urlConnection = [self.urlConnectionForAttachmentIndex objectForKey:[@([self.attachments indexOfObject:attachment]) stringValue]];
    if (urlConnection) {// user deleted the attachment while it was getting downloaded
        // cancel urlConnection
        [urlConnection cancel];
        urlConnection = nil;
        // decrement numberOfDownloadsInProgress
        self.numberOfDownloadsInProgress > 0 ? self.numberOfDownloadsInProgress-- : 0;
    }
    
    // delete the file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:attachment.localPath error:&error];
    if (success) {// file has been deleted
        // update attachment
        attachment.downloadCompleted = [NSNumber numberWithBool:NO];
        attachment.downloadInProgress = [NSNumber numberWithBool:NO];
        attachment.downloadPaused = [NSNumber numberWithBool:NO];
        attachment.localFileSize = 0;
        attachment.localPath = nil;
        attachment.totalLength = 0;
        
        // show alertView indicating the file has been deleted..
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"File Deleted!" message:@"" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alertView show];
        
        // find NSIndex
        NSUInteger attachmentsIndex = [self.attachments indexOfObject:attachment];
        NSIndexPath *indexPathForAttachment = [NSIndexPath indexPathForRow:attachmentsIndex inSection:0];
        if([self.tableView.indexPathsForVisibleRows containsObject:indexPathForAttachment]) {// cell is visible
            AttachmentCell * attachmentCell = (AttachmentCell *)[self.tableView cellForRowAtIndexPath:indexPathForAttachment];
            // update downloadProgressView
            [self updateProgressForDownloadProgressViewFor:attachmentCell andAttachment:attachment];
            // update fileSizeOrStatusLabel
            [self updateFileSizeOrStatusLabelFor:attachmentCell andAttachment:attachment];
        }
        
        // persist data
        [self persistData];
        // startDownloadingQueuedAttachments if possible
        [self startDownloadingQueuedAttachments];
    }
    else {// no need to do anything right now...
        
    }
}

#pragma mark Update DownloadProgressView
// update progress for attachment's attachmentCell's progressView
- (void)updateProgressForDownloadProgressViewFor:(AttachmentCell *)attachmentCell andAttachment:(Attachment *)attachment {
    // calculate progress
    float progress = 0.0;
    // get attachment's localFileSize and totalLength
    float attachmentLocalFileSize = [attachment.localFileSize floatValue];
    float attachmentTotalLength = [attachment.totalLength floatValue];
    
    if (attachmentLocalFileSize > 0.0 && attachmentTotalLength > 0.0) {
        progress = attachmentLocalFileSize / attachmentTotalLength;
    }
    // update amountDownloaded (no need to convert it to percentage but may be useful)
    attachment.amountDownloaded = [NSNumber numberWithFloat:(progress * 100)];
    // update downloadProgressView
    [attachmentCell.downloadProgressView setProgress:progress animated:YES];
    // update fileSizeOrStatusLabel
    if (progress == 1.0) {// download complete
        [self updateFileSizeOrStatusLabelFor:attachmentCell andAttachment:attachment];
    }
}

#pragma mark Update FileSizeOrStatusLabel
// update AttachmentCell's fileSizeOrSatus Label
- (void)updateFileSizeOrStatusLabelFor:(AttachmentCell *)attachmentCell andAttachment:(Attachment *)attachment {
    NSString *fileSizeOrStatus = STATUS_BLACK;
    if ([attachment.downloadCompleted boolValue]) {// downloadCompleted -> show fileSize
        long attachmentLocalFileSize = [attachment.localFileSize longValue] / 1024; // KB
        NSString *measure;
        if (attachmentLocalFileSize > 1024) {
            attachmentLocalFileSize = attachmentLocalFileSize / 1024; // MB
            measure = @"MB";
        }
        else {
            measure = @"KB";
        }
        fileSizeOrStatus = [@(attachmentLocalFileSize) stringValue];
        fileSizeOrStatus = [fileSizeOrStatus stringByAppendingString:measure];
    }
    else if ([attachment.downloadInProgress boolValue]) {// downloadInProgress
        fileSizeOrStatus = STATUS_ACTIVE;
    }
    else if ([attachment.downloadPaused boolValue]) {// downloadPaused
        fileSizeOrStatus = STATUS_PAUSED;
    }
    else if ([attachment.downloadQueued boolValue]) {// downloadQueued
        fileSizeOrStatus = STATUS_QUEUED;
    }
    // update fileSizeOrStatusLabel
    [attachmentCell.fileSizeOrStatusLabel setText:fileSizeOrStatus];
}

#pragma mark StartDownloadingQueuedAttachments
// starts downloading an attachment from downloadQueueArray
- (void)startDownloadingQueuedAttachments {
    // numberOfDownloads that can be started
    NSUInteger numberOfDownloadsToStart = self.maxNoOfDownloadsAllowed - self.numberOfDownloadsInProgress;
    for (int i = 0; i < numberOfDownloadsToStart; i++) {// loop through and start downloading
        if (i < [self.downloadQueueArray count]) {// attachment exists
            Attachment *attachment = [self.downloadQueueArray objectAtIndex:i];
            // increment numberOfDownloadsInProgress
            self.numberOfDownloadsInProgress++;
            // start downloading
            NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:[NSMutableURLRequest requestWithURL:attachment.url] delegate:self startImmediately:YES];
            // add this to urlConnection
            [self.urlConnectionForAttachmentIndex setObject:urlConnection forKey:[@([self.attachments indexOfObject:attachment]) stringValue]];
            // update downloadQueued for attachment
            attachment.downloadQueued = [NSNumber numberWithBool:NO];
            // update downloadInProgress
            attachment.downloadInProgress = [NSNumber numberWithBool:YES];
            // remove attachment from downloadQueueArray
            [self.downloadQueueArray removeObjectAtIndex:i];
        }
    }
}

#pragma mark Persist Data
// persists data in other words calls save on self.managedObjectContext
- (void) persistData {
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        // no need to do anything right now
    }
}

#pragma mark Delete Entities
// deletes all entities fror Entity with name = entityName
- (void)deleteAllEntities:(NSString *)entityName {
    // get fetchRequest
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setIncludesPropertyValues:NO];
    
    NSError *error;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects) {
        [self.managedObjectContext deleteObject:object];
    }
    
    error = nil;
    [self.managedObjectContext save:&error];
}

@end
