//
//  RecipeDetailViewController.m
//  RecipeMe
//
//  Created by vsokoltsov on 14.06.15.
//  Copyright (c) 2015 vsokoltsov. All rights reserved.
//

#import "RecipeDetailViewController.h"
#import "RecipesListTableViewCell.h"
#import "StepTableViewCell.h"
#import "StepHeaderTableViewCell.h"
#import "IngridientsTableViewCell.h"
#import "IngridientHeaderTableViewCell.h"
#import "CommentTableViewCell.h"
#import "CommentHeaderTableViewCell.h"
#import <MBProgressHUD.h>
#import "ServerConnection.h"
#import "Step.h"
#import "Comment.h"
#import "Ingridient.h"
#import "commentForm.h"
#import <FSImageViewer/FSBasicImage.h>
#import <FSImageViewer/FSBasicImageSource.h>
#import "ServerError.h"
#import "AuthorizationManager.h"
#import <UIScrollView+InfiniteScroll.h>

@interface RecipeDetailViewController (){
    int selectedIndex;
    float currentCellHeight;
    ServerConnection *connection;
    NSMutableArray *ingridients;
    NSMutableArray *steps;
    NSMutableArray *comments;
    UIRefreshControl *refreshControl;
    UIButton *errorButton;
    AuthorizationManager *auth;
}

@end

@implementation RecipeDetailViewController

float const stepHeight = 70.0;
float const commentHeight = 50.0;
float const commentFormHeight = 130.0;
float const ingridientHeight = 50.0;
float const defaultCellHeight = 44;
float const recipeCellInfoHeight = 250;

- (void)viewDidLoad {
    [super viewDidLoad];
    selectedIndex = -1;
    auth = [AuthorizationManager sharedInstance];
    connection = [ServerConnection sharedInstance];
    [self refreshInit];
    [self loadRecipe];
    [self.recipeInfoTableView registerClass:[RecipesListTableViewCell class] forCellReuseIdentifier:@"recipeCell"];
    [self.recipeInfoTableView registerNib:[UINib nibWithNibName:@"RecipesListTableViewCell" bundle:nil]
         forCellReuseIdentifier:@"recipeCell"];
    [self.stepsTableView registerClass:[StepTableViewCell class] forCellReuseIdentifier:@"stepCell"];
    [self.stepsTableView registerNib:[UINib nibWithNibName:@"StepTableViewCell" bundle:nil]
                   forCellReuseIdentifier:@"stepCell"];
    
    [self.stepsTableView registerClass:[StepHeaderTableViewCell class] forCellReuseIdentifier:@"stepHeaderCell"];
    [self.stepsTableView registerNib:[UINib nibWithNibName:@"StepHeaderTableViewCell" bundle:nil]
              forCellReuseIdentifier:@"stepHeaderCell"];
    
    [self.ingridientsTableView registerClass:[IngridientsTableViewCell class] forCellReuseIdentifier:@"ingridientsCell"];
    [self.ingridientsTableView registerNib:[UINib nibWithNibName:@"IngridientsTableViewCell" bundle:nil]
              forCellReuseIdentifier:@"ingridientsCell"];
    
    [self.ingridientsTableView registerClass:[IngridientHeaderTableViewCell class] forCellReuseIdentifier:@"ingridientsHeaderCell"];
    [self.ingridientsTableView registerNib:[UINib nibWithNibName:@"IngridientHeaderTableViewCell" bundle:nil]
                    forCellReuseIdentifier:@"ingridientsHeaderCell"];
    
    [self.commentsTableView registerClass:[CommentTableViewCell class] forCellReuseIdentifier:@"commentCell"];
    [self.commentsTableView registerNib:[UINib nibWithNibName:@"CommentTableViewCell" bundle:nil]
                    forCellReuseIdentifier:@"commentCell"];
    
    [self.commentsTableView registerClass:[CommentHeaderTableViewCell class] forCellReuseIdentifier:@"commentHeaderCell"];
    [self.commentsTableView registerNib:[UINib nibWithNibName:@"CommentHeaderTableViewCell" bundle:nil]
                    forCellReuseIdentifier:@"commentHeaderCell"];
    
    self.ingridientsTableView.separatorColor = [UIColor clearColor];

    self.scrollView.infiniteScrollIndicatorStyle = UIActivityIndicatorViewStyleGray;
    [self.scrollView addInfiniteScrollWithHandler:^(UIScrollView *scrollView){
        selectedIndex = 0;
        [self.stepsTableView reloadData];
        [self.commentsTableView reloadData];
        [self loadCommentsList];
        [scrollView finishInfiniteScroll];
    }];
}
- (void) setIngridientsTableViewHeight{
    self.ingiridnetsTableHeightConstraint.constant = (ingridients.count + 1) * ingridientHeight;
    self.stepTableViewHeightConstraint.constant = (steps.count + 1) * stepHeight;
    if(auth.currentUser){
        self.commentsTableViewHeightConstraint.constant = (comments.count + 1) * commentHeight + commentFormHeight;
    } else {
        self.commentsTableViewHeightConstraint.constant = (comments.count + 1) * commentHeight;
    }
    self.viewHeightConstraint.constant =  self.ingiridnetsTableHeightConstraint.constant + self.stepTableViewHeightConstraint.constant + self.commentsTableViewHeightConstraint.constant + self.recipeInfoTableView.frame.size.height;
}

- (void) loadRecipe{
    [MBProgressHUD showHUDAddedTo:self.view
                         animated:YES];
    [refreshControl endRefreshing];
    [connection sendDataToURL:[NSString stringWithFormat:@"/recipes/%@", self.recipe.id] parameters:nil requestType:@"GET" andComplition:^(id data, BOOL success){
        if(success){
            errorButton.hidden = YES;
            [self parseRecipe:data];
        } else {
            ServerError *serverError = [[ServerError alloc] initWithData:data];
            serverError.delegate = self;
            [serverError handle];
        }
    }];
}
- (void) loadCommentsList{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [connection sendDataToURL:[NSString stringWithFormat:@"/recipes/%@/comments", self.recipe.id] parameters:nil requestType:@"GET" andComplition:^(id data, BOOL success){
        if(success){
            errorButton.hidden = YES;
            [self parseComments:data];
        } else {
            ServerError *serverError = [[ServerError alloc] initWithData:data];
            serverError.delegate = self;
            [serverError handle];
        }
    }];
}
- (void) refreshInit{
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [self.scrollView addSubview:refreshView]; //the tableView is a IBOutlet
    
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor whiteColor];
    refreshControl.backgroundColor = [UIColor grayColor];
    [refreshView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(loadRecipe) forControlEvents:UIControlEventValueChanged];
}

- (void) parseRecipe: (id) data{
    if(data != [NSNull null]){
        self.recipe = [[Recipe alloc] initWithParameters:data];
        [self setStepsArrayWithArray:self.recipe.steps ingridietnsArrayWithArray:self.recipe.ingridients andCommentsArraWithArray:self.recipe.comments];
//        steps = [NSMutableArray arrayWithArray:self.recipe.steps];
//        ingridients = [NSMutableArray arrayWithArray:self.recipe.ingridients];
//        comments = [NSMutableArray arrayWithArray:self.recipe.comments];
////        [steps addObjectsFromArray:self.recipe.steps];
//        [self setIngridientsTableViewHeight];
//        [steps insertObject:NSLocalizedString(@"steps", nil) atIndex:0];
//        [ingridients insertObject:NSLocalizedString(@"ingridients", nil) atIndex:0];
//        [comments insertObject:NSLocalizedString(@"comments", nil) atIndex:0];
//        [self.recipeInfoTableView reloadData];
//        [self.stepsTableView reloadData];
//        [self.ingridientsTableView reloadData];
//        [self.commentsTableView reloadData];
    }
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}
- (void) parseComments: (id) data{
    if(data != [NSNull null]){
        [self removeTitlesFromTables];
        comments = [NSMutableArray arrayWithArray:[Comment initializeFromArray:data]];
        [self setStepsArrayWithArray:steps ingridietnsArrayWithArray:ingridients andCommentsArraWithArray:comments];
//        [comments insertObject:NSLocalizedString(@"comments", nil) atIndex:0];
//        self.viewHeightConstraint.constant -= self.commentsTableViewHeightConstraint.constant;
//        if(auth.currentUser){
//            self.commentsTableViewHeightConstraint.constant = comments.count * commentHeight + commentFormHeight;
//        } else {
//            self.commentsTableViewHeightConstraint.constant = comments.count * commentHeight;
//        }
//        self.viewHeightConstraint.constant += self.commentsTableViewHeightConstraint.constant;
        [self.commentsTableView reloadData];
    }
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if([tableView isEqual:self.recipeInfoTableView]){
        return 1;
    } else if([tableView isEqual:self.ingridientsTableView]){
        return ingridients.count;
    } else if([tableView isEqual:self.stepsTableView]){
        return steps.count;
    } else {
        return comments.count;
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([tableView isEqual:self.recipeInfoTableView]){
        static NSString *CellIdentifier = @"recipeCell";
        RecipesListTableViewCell *cell = (RecipesListTableViewCell *)[self.recipeInfoTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell == nil){
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"RecipesListTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
        [cell initWithRecipe:self.recipe];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
        singleTap.numberOfTapsRequired = 1;
        [cell.recipeImage setUserInteractionEnabled:YES];
        [cell.recipeImage addGestureRecognizer:singleTap];
        cell.delegate = self;
        return cell;
    } else if([tableView isEqual:self.ingridientsTableView]){
        if(indexPath.row ==0){
            static NSString *CellIdentifier = @"ingridientsHeaderCell";
            IngridientHeaderTableViewCell *cell = (IngridientHeaderTableViewCell *)[self.ingridientsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
            cell.title.text = ingridients[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else {
        static NSString *CellIdentifier = @"ingridientsCell";
        Ingridient *ingridient = ingridients[indexPath.row];
        IngridientsTableViewCell *cell = (IngridientsTableViewCell *)[self.ingridientsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if(cell == nil){
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"IngridientsTableViewCell" owner:self options:nil];
            cell = [nib objectAtIndex:0];
        }
            cell.ingridientName.text = ingridient.name;
            cell.ingridientSize.text = ingridient.size;
        return cell;
        }
    } else if([tableView isEqual:self.stepsTableView]){
        if(indexPath.row == 0){
            static NSString *CellIdentifier = @"stepHeaderCell";
            StepHeaderTableViewCell *cell = (StepHeaderTableViewCell *)[self.stepsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
            cell.title.text = steps[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else {
            static NSString *CellIdentifier = @"stepCell";
            Step *step = steps[indexPath.row];
            StepTableViewCell *cell = (StepTableViewCell *)[self.stepsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if(cell == nil){
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"StepTableViewCell" owner:self options:nil];
                cell = [nib objectAtIndex:0];
            }
            [cell setStepData:step];
            cell.delegate = self;

            return cell;
        }
    } else {
        if(indexPath.row == 0){
            static NSString *CellIdentifier = @"commentHeaderCell";
            CommentHeaderTableViewCell *cell = (CommentHeaderTableViewCell *)[self.commentsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
            cell.title.text = comments[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            return cell;
        } else {
            static NSString *CellIdentifier = @"commentCell";
            Comment *comment = comments[indexPath.row];
            CommentTableViewCell *cell = (CommentTableViewCell *)[self.commentsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
            [cell setCommentData:comment];
            return cell;
        }
        
    }
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([tableView isEqual:self.stepsTableView] || [tableView isEqual:self.commentsTableView]){
        [self rowWasSelected:tableView inIndexPath:indexPath];
    }
}

- (void) rowWasSelected: (UITableView *) tableView inIndexPath: (NSIndexPath *) indexPath{
        [self.view endEditing:YES];
        if(selectedIndex == indexPath.row){
            selectedIndex = -1;
            [self changeCellTextHeightForTable:tableView at:indexPath withCondition:NO];
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            return;
        }
        
        if(selectedIndex != -1){
            NSIndexPath *prevPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
            selectedIndex = indexPath.row;
            [self changeCellTextHeightForTable:tableView at:indexPath withCondition:NO];
            [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:prevPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        
        selectedIndex = indexPath.row;
        [self changeCellTextHeightForTable:tableView at:indexPath withCondition:YES];
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

}
- (void) changeViewHeightOfTable: (UITableView *) tableView toValue: (float) value to: (BOOL) condition{
    if([tableView isEqual:self.stepsTableView]){
        if(condition){
            if(value == stepHeight) return;
            self.stepTableViewHeightConstraint.constant += value;
            self.viewHeightConstraint.constant += value;
        } else {
            if(value == stepHeight) return;
            self.stepTableViewHeightConstraint.constant -= value;
            self.viewHeightConstraint.constant -= value;
        }
    } else {
        if(condition){
            if(value == commentHeight) return;
            self.commentsTableViewHeightConstraint.constant += value;
            self.viewHeightConstraint.constant += value;
        } else {
            if(value == commentHeight) return;
            self.commentsTableViewHeightConstraint.constant -= value;
            self.viewHeightConstraint.constant -= value;
        }
    }
}
- (void) changeCellTextHeightForTable: (UITableView *) tableView at:(NSIndexPath *)path withCondition: (BOOL) value{
    if([tableView isEqual:self.stepsTableView]){
        Step *step = steps[path.row];
        NSString *text = [steps[path.row] desc];
        CGSize size = [text sizeWithAttributes:nil];
        if(size.width / 9 < stepHeight){
            currentCellHeight = stepHeight;
        } else {
            currentCellHeight = size.width / 9;
        }
    } else {
        CGSize size = [[comments[path.row] text] sizeWithAttributes:nil];
        if(size.width / 9 < commentHeight){
            currentCellHeight = commentHeight;
        } else {
            currentCellHeight = size.width / 10;
        }
    }
    [self changeViewHeightOfTable:tableView toValue:currentCellHeight to:value];
}
-(void)tapped:(UITapGestureRecognizer *)recognizer{
    NSIndexPath *path = [self.stepsTableView indexPathForCell:[[recognizer.view superview] superview]];
    [self.stepsTableView selectRowAtIndexPath:path animated:NO scrollPosition:UITableViewScrollPositionNone];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([tableView isEqual:self.recipeInfoTableView]){
        return recipeCellInfoHeight;
    } else if([tableView isEqual:self.stepsTableView]){
        if(indexPath.row == 0){
            return defaultCellHeight;
        } else {
            if(selectedIndex == indexPath.row){
                if(currentCellHeight == stepHeight){
                    return stepHeight;
                } else {
                    return currentCellHeight;
                }
            } else {
                return stepHeight;
            }
        }
    } else if([tableView isEqual:self.commentsTableView]){
        if(indexPath.row == 0){
            return defaultCellHeight;
        } else {
            if(selectedIndex == indexPath.row){
                if(currentCellHeight == commentHeight){
                    return commentHeight;
                } else {
                    return currentCellHeight;
                }
            } else {
                return commentHeight;
            }
        }
        
    } else {
        return defaultCellHeight;
    }
    
}
//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//    if([tableView isEqual:self.commentsTableView]){
//        return 20;
//    } else {
//        return 0;
//    }
//}
//
//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    if([tableView isEqual:self.commentsTableView]){
//        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.commentsTableView.frame.size.width, 20)];
//        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.commentsTableView.frame.size.width, 20)];
//        label.text = @"Показать все комментарии";
//        [headerView addSubview:label];
//
//        return headerView;
//    } else {
//        return nil;
//    }
//}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if([tableView isEqual:self.commentsTableView]){
        return 110;
    } else {
        return 0;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if([tableView isEqual:self.commentsTableView]){
        commentForm *form = [[[NSBundle mainBundle] loadNibNamed:@"commentFormView" owner:self options:nil] firstObject];
        form.delegate = self;
        return form;
    } else {
        return nil;
    }   
}
- (void) tapDetected: (UIGestureRecognizer *) recognizer{
    FSBasicImage *firstPhoto = [[FSBasicImage alloc] initWithImageURL:[NSURL URLWithString:self.recipe.imageUrl] name:self.recipe.title];
    FSBasicImageSource *photoSource = [[FSBasicImageSource alloc] initWithImages:@[firstPhoto]];
    FSImageViewerViewController *imageViewController = [[FSImageViewerViewController alloc] initWithImageSource:photoSource];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imageViewController];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}
- (void) clickOnCellImage: (Step *) step{
    FSBasicImage *firstPhoto = [[FSBasicImage alloc] initWithImageURL:[NSURL URLWithString:step.imageUrl] name:step.desc];
    FSBasicImageSource *photoSource = [[FSBasicImageSource alloc] initWithImages:@[firstPhoto]];
    FSImageViewerViewController *imageViewController = [[FSImageViewerViewController alloc] initWithImageSource:photoSource];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:imageViewController];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}
- (void) clickOnUserImage:(User *)user{
    [self performSegueWithIdentifier:@"userProfile" sender:self];
}
- (void) handleServerErrorWithError:(id)error{
    if(errorButton){
        errorButton.hidden = NO;
    } else {
        errorButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 40)];
        errorButton.backgroundColor = [UIColor lightGrayColor];
        [errorButton setTitle:[error messageText] forState:UIControlStateNormal];
        [errorButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [errorButton addTarget:self action:@selector(loadRecipe) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:errorButton];
    }
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    [refreshControl endRefreshing];
}

- (void) createComment:(NSMutableDictionary *)comment{
    [MBProgressHUD showHUDAddedTo:self.view
                         animated:YES];
    [comment addEntriesFromDictionary:@{@"user_id": auth.currentUser.id, @"recipe_id": self.recipe.id}];
    Comment *com = [[Comment alloc] initWithParameters:comment];
    com.delegate = self;
    [com create:comment];
}
- (void) successCommentCreationCallback:(id)comment{
    Comment *com = [[Comment alloc] initWithParameters:comment];
    [comments insertObject:com atIndex:1];
    [self removeTitlesFromTables];
    [self setStepsArrayWithArray:steps ingridietnsArrayWithArray:ingridients andCommentsArraWithArray:comments];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}

- (void) failureCommentCreationCallback:(id)error{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}
- (void) setStepsArrayWithArray:(NSArray *) stepsArray ingridietnsArrayWithArray:(NSArray *) ingridientsArray andCommentsArraWithArray:(NSArray *) commentsArray{
    steps = [NSMutableArray arrayWithArray:stepsArray];
    ingridients = [NSMutableArray arrayWithArray:ingridientsArray];
    comments = [NSMutableArray arrayWithArray:commentsArray];;
    [self setIngridientsTableViewHeight];
    [steps insertObject:NSLocalizedString(@"steps", nil) atIndex:0];
    [ingridients insertObject:NSLocalizedString(@"ingridients", nil) atIndex:0];
    [comments insertObject:NSLocalizedString(@"comments", nil) atIndex:0];
    [self reloadTableViewsData];
}
-(void) reloadTableViewsData{
    [self.recipeInfoTableView reloadData];
    [self.stepsTableView reloadData];
    [self.ingridientsTableView reloadData];
    [self.commentsTableView reloadData];
};
- (void) removeTitlesFromTables{
    [comments removeObjectAtIndex:0];
    [steps removeObjectAtIndex:0];
    [ingridients removeObjectAtIndex:0];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
