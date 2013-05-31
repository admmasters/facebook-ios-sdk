//
//  FacebookSingleton.h
//  Blade Dash
//
//  Created by Matt Revell on 11/05/2013.
//  Copyright (c) 2013 ADM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FacebookSingleton : NSObject

//Public API
+ (id)sharedManager;
-(CCSprite*) getMyProfilePic;
-(void) makeRequest;

@property (nonatomic, assign, getter = isAuthenticated) BOOL authenticated;

@end
