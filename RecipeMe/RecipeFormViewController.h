//
//  RecipeFormViewController.h
//  RecipeMe
//
//  Created by vsokoltsov on 18.07.15.
//  Copyright (c) 2015 vsokoltsov. All rights reserved.
//

#import "ViewController.h"

@interface RecipeFormViewController : ViewController
@property (strong, nonatomic) IBOutlet UITextField *recipeTitle;
@property (strong, nonatomic) IBOutlet UITextField *recipeTime;
@property (strong, nonatomic) IBOutlet UITextField *recipePersons;
@property (strong, nonatomic) IBOutlet UITextField *recipeDifficult;
@property (strong, nonatomic) IBOutlet UITextField *recipeCategory;
@property (strong, nonatomic) IBOutlet UITextField *recipeTags;
@property (strong, nonatomic) IBOutlet UIView *formView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *formViewHeightConstraint;

@end