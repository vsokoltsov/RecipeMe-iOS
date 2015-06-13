//
//  User.m
//  RecipeMe
//
//  Created by vsokoltsov on 13.06.15.
//  Copyright (c) 2015 vsokoltsov. All rights reserved.
//

#import "User.h"
#import "ServerConnection.h"

@implementation User
- (instancetype) initWithParams: (NSDictionary *) params{
    if(self == [super init]){
        [self setParams:params];
    }
    return self;
}
- (void) setParams: (NSDictionary *) params{
    if(params[@"avatar"] && params[@"avatar"][@"url"]) self.avatarUrl = [[ServerConnection sharedInstance] returnCorrectUrlPrefix:params[@"avatar"][@"url"]];;
//    if(params[@"id"]) self.id = params[@"id"];
//    if(params[@"user_id"]) self.userId = params[@"user_id"];
//    if(params[@"category_id"]) self.categoryId = params[@"category_id"];
//    if(params[@"title"]) self.title = params[@"title"];
//    if(params[@"image"] != [NSNull null] && params[@"image"][@"name"][@"url"]) self.imageUrl = [[ServerConnection sharedInstance] returnCorrectUrlPrefix:params[@"image"][@"name"][@"url"]];
//    if(params[@"description"]) self.desc = params[@"description"];
//    if(params[@"rate"]) self.rate = params[@"rate"];
//    if(params[@"comments_count"]) self.commentsCount = params[@"comments_count"];
//    if(params[@"steps_count"]) self.stepsCount = params[@"steps_count"];
//    if(params[@"time"]) self.time = params[@"time"];
//    if(params[@"persons"]) self.persons = params[@"persons"];
//    if(params[@"difficult"]) self.difficult = params[@"difficult"];
//    if(params[@"user"]) self.user = [[User alloc] ];
}

@end