//
//  FacebookSingleton.m
//  Blade Dash
//
//  Created by Matt Revell on 11/05/2013.
//  Copyright (c) 2013 ADM. All rights reserved.
//

#import "FacebookSingleton.h"
#import "ImageFetcher.h"
#include "SBJson.h"

static FacebookSingleton *sharedManager = nil;

@implementation FacebookSingleton {
    NSDictionary<FBGraphUser> *me;
}

#pragma mark - Singleton Methods

+ (id) sharedManager {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        if(sharedManager == nil) {
            sharedManager = [[self alloc] init];
        }
    });
    
    return sharedManager;
    
}

-(id) init {
    
    if(self = [super init]) {
        
        FBSession* session = [[FBSession alloc] init];
        [FBSession setActiveSession: session];
        
        [self login];
        
    }
    
    return self;
    
}

-(void) login {
    
    NSArray *permissions = [[NSArray alloc] initWithObjects:
                            @"email",
                            nil];
    
    // Attempt to open the session. If the session is not open, show the user the Facebook login UX
    [FBSession openActiveSessionWithReadPermissions:permissions allowLoginUI:true completionHandler:^(FBSession *session,
                                                                                                      FBSessionState status,
                                                                                                      NSError *error)
     {
         // Did something go wrong during login? I.e. did the user cancel?
         if (status == FBSessionStateClosedLoginFailed || status == FBSessionStateCreatedOpening) {
             
             // If so, just send them round the loop again
             [[FBSession activeSession] closeAndClearTokenInformation];
             [FBSession setActiveSession:nil];
             //FB_CreateNewSession();
         }
         else
         {
             // Update our game now we've logged in
             //            if (m_kGameState == kGAMESTATE_FRONTSCREEN_LOGGEDOUT) {
             //                UpdateView(true);
             //            }
                          
             // Provide some social context to the game by requesting the basic details of the player from Facebook
             
             // Start the Facebook request
             [[FBRequest requestForMe]
              startWithCompletionHandler:
              ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *result, NSError *error)
              {
                  
                  me = result;
                  // Did everything come back okay with no errors?
                  if (!error && me)
                  {
//                      // If so we can extract out the player's Facebook ID and first name
//                      unsigned long long playerFBID = [me.id longLongValue];
//                      
//                      NSString *resourceAddress = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%llu/picture?width=256&height=256", playerFBID];
//                      [self getProfilePic:resourceAddress];
                      _authenticated = YES;
                  }
                  
              }];
             
         }
     }];
}

-(void) makeRequest {
    
//    NSArray *permissions = [[NSArray alloc] initWithObjects:
//                            @"publish_actions", nil];
//    
//    [[FBSession activeSession] requestNewPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceFriends completionHandler:^(FBSession *session, NSError *error) {
//        NSLog(@"Reauthorized with publish permissions.");
//    }];
    
    NSLog(@"Session is: %@",[FBSession activeSession]);
    
    NSMutableDictionary* params =   [NSMutableDictionary dictionaryWithObjectsAndKeys:nil];
    [FBWebDialogs presentRequestsDialogModallyWithSession:[FBSession activeSession]
                                                  message:[NSString stringWithFormat:@"I just smashed %d friends! Can you beat it?", 10]
                                                    title:nil
                                               parameters:params
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
                                                      if (error) {
                                                          // Case A: Error launching the dialog or sending request.
                                                          NSLog(@"Error sending request.");
                                                      } else {
                                                          if (result == FBWebDialogResultDialogNotCompleted) {
                                                              // Case B: User clicked the "x" icon
                                                              NSLog(@"User canceled request.");
                                                          } else {
                                                              NSLog(@"Request Sent.");
                                                          }
                                                      }}];
    
}

-(CCSprite*) getMyProfilePic {
    
    if(_authenticated)
    {
        // If so we can extract out the player's Facebook ID and first name
        unsigned long long playerFBID = [me.id longLongValue];
        NSString *resourceAddress = [[NSString alloc] initWithFormat:@"https://graph.facebook.com/%llu/picture?width=64&height=64", playerFBID];
        return [self getProfilePic:resourceAddress];
    }
   
    return nil;
    
}


-(CCSprite*) getProfilePic:(NSString*)resourceAddress {
    
    ImageFetcher* fetcher = [[ImageFetcher alloc] init];
    
    __block CCSprite *profileSprite;
    
    [fetcher fetchImageWithUrl:resourceAddress andCompletionBlock:^bool(UIImage *image) {
        
        if (image == nil) {
            return false;
        }
     
     profileSprite = [CCSprite spriteWithCGImage:image.CGImage key:@"mainSprite"];
     
     return YES;
     
    }];
    
    return profileSprite;
    
}

-(id) friendsNotInstalled {
    
    __block NSString *results;
    
    [[FBRequest requestForMe] startWithCompletionHandler: ^(FBRequestConnection *connection,
                                      NSDictionary<FBGraphUser> *my,
                                      NSError *error) {
        
        FBRequest *fql = [FBRequest requestForGraphPath:@"fql"];
        [fql.parameters setObject:
         [NSString stringWithFormat:@"SELECT name,uid, pic_small FROM user WHERE is_app_user = 0 AND uid IN (SELECT uid2 FROM friend WHERE uid1 = %@) order by concat(first_name,last_name) asc",my.id]
                           forKey:@"q"];
        
        [fql startWithCompletionHandler:^(FBRequestConnection *connection,
                                          id result,
                                          NSError *error) {
            if (result) {
                NSLog(@"result:%@", result);
                results = result;
            }
        }];
        
    }];
    
    return results;
    
}

-(id) friendsInstalled {
    
    __block NSString *results;
    
    [[FBRequest requestForMe] startWithCompletionHandler: ^(FBRequestConnection *connection,
                                                            NSDictionary<FBGraphUser> *my,
                                                            NSError *error) {
        
        FBRequest *fql = [FBRequest requestForGraphPath:@"fql"];
        [fql.parameters setObject:
         [NSString stringWithFormat:@"SELECT name,uid, pic_small FROM user WHERE is_app_user = 1 AND uid IN (SELECT uid2 FROM friend WHERE uid1 = %@) order by concat(first_name,last_name) asc",my.id]
                           forKey:@"q"];
        
        [fql startWithCompletionHandler:^(FBRequestConnection *connection,
                                          id result,
                                          NSError *error) {
            if (result) {
                NSLog(@"result:%@", result);
                results = result;
            }
        }];
        
    }];
    
    return results;
    
}


@end
