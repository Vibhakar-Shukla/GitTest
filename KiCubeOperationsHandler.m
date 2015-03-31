//
//  KiCubeOperationsHandler.m
//  KiCube
//
//  Created by Vibhakar Shukla on 16/04/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "KiCubeOperationsHandler.h"
#import "KiCubeRequestHandler.h"
#import "Media.h"

@implementation KiCubeOperationsHandler

@synthesize url;
@synthesize mediaID;
@synthesize totalMediaCount;
@synthesize thumbnailURL;

-(id)initWithURL:(NSURL *)newURL forMediaID:(NSNumber *)theMediaID withTotalCount:(NSNumber*)TotalCount thumbnailURL:(NSURL*)thumbURL{
    if ( self = [super init] ) {
        self.url = newURL;
        self.thumbnailURL  = thumbURL;
        self.mediaID = theMediaID;
        self.totalMediaCount = TotalCount;
    }
    return self;
}

-(void)main {
    
    // NSLog(@"Count");
    
    if ( self.isCancelled ) return;
    if ( nil == self.url ) return;
    
    failed = NO;
    
    // NSLog(@"Download URL = %@",self.url);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    
    imageData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSDictionary *dictionary = [response allHeaderFields];
    NSString *downloadEtag = nil;
    if([dictionary objectForKey:kEtag] != nil )
    {
        downloadEtag = [dictionary objectForKey:kEtag];
        downloadEtag = [downloadEtag stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    }
    Media *theMediaInfo = nil;
    NSArray *theMediaDataInfo = [KiCubeCoreDataModel getTheResultsForTheEntity:kMedia andItsPredicate:self.mediaID WithPredicateKey:kmediaID WithSortDescriptor:kmediaName];
    if(theMediaDataInfo.count > 0 )
    {
        theMediaInfo = [theMediaDataInfo objectAtIndex:0];
        theMediaInfo.mediaDownloadVersion = downloadEtag;
        
    }
    
    
    
    //NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
    
    if ( self.isCancelled ) return;
    if (error)
    {
        /*UIAlertView *theOfflineAlert = [[UIAlertView alloc]initWithTitle:ERROR_HEADER_TEXT message:@"The connection with the server was lost unexpectedly. Please check your internet connectivity." delegate:self cancelButtonTitle:NSLocalizedString(kOK, @"") otherButtonTitles: nil];
         [theOfflineAlert show];
         [theOfflineAlert release];*/
        [self performSelectorOnMainThread:@selector(launchAnConnectionFailedAlertInCaseofError) withObject:nil waitUntilDone:YES];
        
        [[KiCubeRequestHandler sharedRequestHandler]cancelOperationQueueOperations];
        [KiCubeCoreDataModel setIsDownloadingFactorOfAllEntitiesToZero];
        failed = YES;
        
        return;
    }
    
    
    if ( nil != self.thumbnailURL && failed == NO)
    {
        NSMutableURLRequest *requestForThumbnail = [NSMutableURLRequest requestWithURL:self.thumbnailURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        
        
        NSError *ThumbnailError = nil;
        NSHTTPURLResponse *Thumbnailresponse;
        thumbanailData = [NSURLConnection sendSynchronousRequest:requestForThumbnail returningResponse:&Thumbnailresponse error:&ThumbnailError];
        NSDictionary *Thumbnaildictionary = [Thumbnailresponse allHeaderFields];
        NSString *ThumbnailDownloadEtag = nil;
        if([Thumbnaildictionary objectForKey:kEtag] != nil)
        {
            ThumbnailDownloadEtag = [Thumbnaildictionary objectForKey:kEtag];
            ThumbnailDownloadEtag = [ThumbnailDownloadEtag stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        }
        //NSURLConnection *connection = [[NSURLConnection alloc]initWithRequest:request delegate:self];
        // Media *theMediaInfo = nil;
        ///NSArray *theMediaDataInfo = [KiCubeCoreDataModel getTheResultsForTheEntity:kMedia andItsPredicate:self.mediaID WithPredicateKey:kmediaID WithSortDescriptor:kmediaName];
        
        if (theMediaInfo.thumbnailDownloadVersion !=nil)
        {
            
            if(theMediaDataInfo.count > 0 )
            {
                theMediaInfo = [theMediaDataInfo objectAtIndex:0];
                if(ThumbnailDownloadEtag.length > 0)
                {
                    theMediaInfo.thumbnailDownloadVersion = ThumbnailDownloadEtag;
                }
                
            }
        }
        
        
        if ( self.isCancelled ) return;
        if (ThumbnailError)
        {
            [self performSelectorOnMainThread:@selector(launchAnConnectionFailedAlertInCaseofError) withObject:nil waitUntilDone:YES];
            
            
            failed =YES;
            
            //return;
        }
    }
    
    if ( failed == NO)
    {
        [self performSelectorOnMainThread:@selector(callDownloadDone) withObject:nil waitUntilDone:YES];
    }
    else{
        [[KiCubeRequestHandler sharedRequestHandler]cancelOperationQueueOperations];
        [KiCubeCoreDataModel setIsDownloadingFactorOfAllEntitiesToZero];
        
    }
    
    
}

-(void)callDownloadDone
{
    
    //[[KiCubeRequestHandler sharedRequestHandler] handleDownloadResponseforSingleMedia:imageData withMediaID:self.mediaID TotalMediaCount:self.totalMediaCount];
    @try{
    [[KiCubeRequestHandler sharedRequestHandler] handleDownloadResponseforSingleMedia:imageData withMediaID:self.mediaID TotalMediaCount:self.totalMediaCount ThumbnailData:thumbanailData];
    }
    @catch (NSException *exception)
    {
        [[KiCubeRequestHandler sharedRequestHandler]cancelOperationQueueOperations];
        [KiCubeCoreDataModel setIsDownloadingFactorOfAllEntitiesToZero];

//        NSLog(@"Exception Occured: %@",exception);
    }
    @finally{
//        NSLog(@"In Finally");
//        [[KiCubeRequestHandler sharedRequestHandler]cancelOperationQueueOperations];
//        [KiCubeCoreDataModel setIsDownloadingFactorOfAllEntitiesToZero];

    }
}

/*
 -(void)getTheURLForMediaID
 {
 NSURL *AamazonFileURL = [[KiCubeRequestHandler sharedRequestHandler] getAmazonPathForMediaWithID:self.mediaID];
 
 if (AamazonFileURL == nil) {
 
 if ( [[KiCubeReachability reachabilityForInternetConnection] currentReachabilityStatus] != 0 || [[KiCubeReachability reachabilityForLocalWiFi] currentReachabilityStatus] != 0 )
 {
 [[KiCubeRequestHandler sharedRequestHandler] sendDownloadRequestforMediaID];
 
 }
 else
 {
 UIAlertView *theOfflineAlert = [[UIAlertView alloc]initWithTitle:ERROR_HEADER_TEXT message:kServerConnectionErrorMSG delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
 [theOfflineAlert show];
 [theOfflineAlert release];
 [mRequestTargetForMediaDownload performSelectorOnMainThread:@selector(hideCancelDownloadButton) withObject:nil waitUntilDone:YES];
 
 }
 
 
 }
 return;
 }
 }
 */
-(void)launchAnConnectionFailedAlertInCaseofError
{
    UIAlertView *theOfflineAlert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(ERROR_HEADER_TEXT, @"") message:NSLocalizedString(kServerConnectionErrorMSG, @"") delegate:nil cancelButtonTitle:NSLocalizedString(kOK, @"") otherButtonTitles: nil];
    [theOfflineAlert show];
}




@end
