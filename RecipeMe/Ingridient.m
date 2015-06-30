//
//  Ingridient.m
//  RecipeMe
//
//  Created by vsokoltsov on 25.06.15.
//  Copyright (c) 2015 vsokoltsov. All rights reserved.
//

#import "Ingridient.h"

@implementation Ingridient
+ (NSMutableArray *) initializeFromArray: (NSMutableArray *) ingridientsList{
    NSMutableArray *ingridients = [NSMutableArray new];
    for(NSDictionary *ingridientDictionary in ingridientsList){
        Ingridient *ingridient = [[Ingridient alloc] initWithParameters:ingridientDictionary];
        [ingridients addObject:ingridient];
    }
    return ingridients;
}
- (instancetype) initWithParameters: (NSDictionary *) params{
    if(self == [super init]){
        [self setParams:params];
    }
    return self;
}

- (void) setParams: (NSDictionary *) params{
    if(params[@"id"]) self.id = params[@"id"];
    if(params[@"name"]) self.name = params[@"name"];
    if(params[@"size"]) self.size = params[@"size"];
}

@end