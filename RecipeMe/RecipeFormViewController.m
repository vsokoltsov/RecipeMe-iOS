//
//  RecipeFormViewController.m
//  RecipeMe
//
//  Created by vsokoltsov on 18.07.15.
//  Copyright (c) 2015 vsokoltsov. All rights reserved.
//

#import "RecipeFormViewController.h"
#import "ServerConnection.h"
#import "AuthorizationManager.h"
#import "RecipeFormHeader.h"
#import "IngridientsFormTableViewCell.h"
#import "Ingridient.h"
#import "StepsFormTableViewCell.h"

@interface RecipeFormViewController (){
    ServerConnection *connection;
    AuthorizationManager *auth;
    UIPickerView *difficultPicker;
    UIPickerView *categoriesPicker;
    NSMutableArray *difficults;
    NSArray *difficultIDs;
    NSMutableArray *categories;
    NSString *selectedDifficult;
    NSNumber *selectedCategory;
    float previousDescHeight;
    float prevStepHeight;
    NSMutableArray *ingridients;
    NSMutableArray *steps;
    StepsFormTableViewCell *selectedCell;
    UIActionSheet *recipeImagePopup;
    UIActionSheet *stepImagePopup;
    UIImagePickerController *recipePicker;
    UIImagePickerController *stepPicker;
}

@end

@implementation RecipeFormViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    connection = [ServerConnection sharedInstance];
    auth = [AuthorizationManager sharedInstance];
    //Категории должны загружатся в первую очередь
    [self loadCategoriesList];
    [self defaultFormConfig];
    if(self.recipe){
        [self updateRecipe];
    } else {
        [self createRecipe];
    }
    [self setNamesForInputs];
    // Do any additional setup after loading the view.
}

- (void) registerCellClasses{
    [self.ingridientsTableView registerClass:[IngridientsFormTableViewCell class] forCellReuseIdentifier:@"ingridientsCell"];
    [self.ingridientsTableView registerNib:[UINib nibWithNibName:@"IngridientsFormTableViewCell" bundle:nil]
                   forCellReuseIdentifier:@"ingridientsCell"];
    
    [self.stepsTableView registerClass:[StepsFormTableViewCell class] forCellReuseIdentifier:@"stepsCell"];
    [self.stepsTableView registerNib:[UINib nibWithNibName:@"StepsFormTableViewCell" bundle:nil]
                    forCellReuseIdentifier:@"stepsCell"];
}
- (void) defaultFormConfig{
    [self registerCellClasses];
    self.formViewHeightConstraint.constant += 110.0;
    self.recipeDescription.delegate = self;
    [self setInputPlaceholders];
    ingridients = [NSMutableArray new];
    steps = [NSMutableArray new];
    difficultIDs = @[@"easy", @"medium", @"hard"];
    difficults = @[NSLocalizedString(@"recipes_difficult_easy", nil),
                   NSLocalizedString(@"recipes_difficult_medium", nil),
                   NSLocalizedString(@"recipes_difficult_hard", nil)];
    [self.recipeDescription sizeToFit];
    [self.recipeDescription layoutIfNeeded];
    [self setDifficultPickerView];
    [self setCategoryPickerView];
}

- (void) loadCategoriesList{
    [connection sendDataToURL:@"/categories" parameters:nil requestType:@"GET" andComplition:^(id data, BOOL success){
        if(success){
            [self parseCategories:data];
        } else {
            
        }
    }];
}

- (void) parseCategories:(id)data{
    categories = [NSArray arrayWithArray:data];
}


- (void) createRecipe{

}
- (void) setDifficultPickerView{
    difficultPicker = [[UIPickerView alloc] init];
    difficultPicker.delegate = self;
    difficultPicker.dataSource = self;
    self.recipeDifficult.inputView = difficultPicker;
}

- (void) setCategoryPickerView{
    categoriesPicker = [[UIPickerView alloc] init];
    categoriesPicker.delegate = self;
    categoriesPicker.dataSource = self;
    self.recipeCategory.inputView = categoriesPicker;
}
- (void) setInputPlaceholders{
    [self.recipeTitle setPlaceholder:NSLocalizedString(@"form_title", nil)];
    [self.recipeTime setPlaceholder:NSLocalizedString(@"form_time", nil)];
    [self.recipePersons setPlaceholder:NSLocalizedString(@"form_persons", nil)];
    [self.recipeDifficult setPlaceholder:NSLocalizedString(@"form_difficult", nil)];
    [self.recipeCategory setPlaceholder:NSLocalizedString(@"form_category", nil)];
    [self.recipeDifficult setPlaceholder:NSLocalizedString(@"form_difficult", nil)];
    [self.recipeTags setPlaceholder:NSLocalizedString(@"form_tags", nil)];
}

- (void) updateRecipe{

}

- (void) setNamesForInputs{
    [self.navigationBar.items[0] setTitle:@"Recipe Form"];
    [self.saveButton setTitle:NSLocalizedString(@"save_recipe", nil)];
    [self.cancelButton setTitle:NSLocalizedString(@"cancel_recipe", nil)];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    [self.recipeImage setUserInteractionEnabled:YES];
    [self.recipeImage addGestureRecognizer:singleTap];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) tapDetected: (id) sender{
    recipeImagePopup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"recipe_image_cancel", nil) destructiveButtonTitle:nil otherButtonTitles:
                            NSLocalizedString(@"recipe_image_collection", nil),
                            NSLocalizedString(@"recipe_image_camera", nil),
                            nil];
    recipeImagePopup.tag = 1;
    [recipeImagePopup showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    if([popup isEqual:recipeImagePopup]){
        switch(buttonIndex){
            case 0:
                [self callImagePicker:UIImagePickerControllerSourceTypePhotoLibrary andValue:YES];
                break;
            case 1:
                [self callImagePicker:UIImagePickerControllerSourceTypeCamera andValue:YES];
                break;
            case 2:
                break;
        }
    }
    if([popup isEqual:stepImagePopup]){
        switch(buttonIndex){
            case 0:
                [self callImagePicker:UIImagePickerControllerSourceTypePhotoLibrary andValue:NO];
                break;
            case 1:
                [self callImagePicker:UIImagePickerControllerSourceTypeCamera andValue:NO];
                break;
            case 2:
                break;
        }
    }
}

- (void) callImagePicker: (UIImagePickerControllerSourceType *) type andValue: (BOOL) value{
    if(value){
        recipePicker = [[UIImagePickerController alloc] init];
        recipePicker.delegate = self;
        recipePicker.allowsEditing = YES;
        recipePicker.sourceType = type;
        [self presentViewController:recipePicker animated:YES completion:NULL];
    } else {
        stepPicker = [[UIImagePickerController alloc] init];
        stepPicker.delegate = self;
        stepPicker.allowsEditing = YES;
        stepPicker.sourceType = type;
        [self presentViewController:stepPicker animated:YES completion:NULL];
    }
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    NSString *imageableType;
    if([picker isEqual:recipePicker]){
        self.recipeImage.image = chosenImage;
        imageableType = @"Recipe";
    }
    if([picker isEqual:stepPicker]){
        selectedCell.stepImage.image = chosenImage;
        imageableType = @"Step";
    }
    [connection uploadImage:chosenImage withParams:@{@"imageable_type": imageableType} andComplition:^(id data, BOOL success){
        if(success){
            if([picker isEqual:recipePicker]){
                self.recipeImageId = data[@"id"];
            }
            if([picker isEqual:stepPicker]){
                selectedCell.stepImageId = data[@"id"];
                selectedCell.step.imageId = data[@"id"];
            }
        } else {
            
        }
    }];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void) changeAllViewsHeights:(float) value result: (BOOL) result{
    if(result){
        self.formViewHeightConstraint.constant += value;
        self.recipeDescriptionTextViewHeight.constant += value;
    } else {
        self.formViewHeightConstraint.constant -= value;
        self.recipeDescriptionTextViewHeight.constant -= value;
    }
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - PickerView delegate methods
- (NSInteger)numberOfComponentsInPickerView:
(UIPickerView *)pickerView{
    return 1;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component{
    if([pickerView isEqual:difficultPicker]){
        return difficults.count;
    } else {
        return categories.count;
    }
}
- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component{
    if([pickerView isEqual:difficultPicker]){
        return difficults[row];
    } else {
        return categories[row][@"title"];
    }
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if([pickerView isEqual:difficultPicker]){
        self.recipeDifficult.text = difficults[row];
        selectedDifficult = difficultIDs[row];
    } else {
        self.recipeCategory.text = categories[row][@"title"];
        selectedCategory = categories[row][@"id"];
    }
//    pickerView.removeFromSuperview;
}

#pragma mark - Save and Cancel Form event handlers
- (NSDictionary *) getRecipeFormData{
    return @{@"title": self.recipeTitle.text, @"category_id": selectedCategory, @"tag_list": self.recipeTags.text,
             @"image": @{@"id": self.recipeImageId}, @"description": self.recipeDescription.text, @"difficult": selectedDifficult, @"user_id": auth.currentUser.id, @"time": self.recipeTime.text, @"persons": self.recipePersons.text};
}
- (IBAction)saveRecipe:(id)sender {
    NSString *url;
    NSString *requestType;
    if(self.recipe){
        url = [NSString stringWithFormat:@"/recipes/%@", self.recipe.id];
        requestType = @"PUT";
    } else {
        url = @"/recipes";
        requestType = @"POST";
    }
    [connection sendDataToURL:url parameters:[self getRecipeFormData] requestType:requestType andComplition:^(id data, BOOL success){
        if(success){
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_async(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                for(Ingridient *ingridient in ingridients){
                    ingridient.recipeId = data[@"id"];
                    [ingridient save];
                }
                for(Step *step in steps){
                    step.recipeId = data[@"id"];
                    [step save];
                }
               //Save steps and ingridien
            });
            dispatch_group_notify(group,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^ {
                // block3
               [self dismissViewControllerAnimated:YES completion:nil];
            });
        } else {
        
        }
    }];
}

- (IBAction)dismissForm:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) increaseViewsHeight: (BOOL) value{
    if(value){
        float tableViewHeight = 44.0;
        self.ingridientsTableViewHeightConstraint.constant += tableViewHeight;
        self.formViewHeightConstraint.constant += tableViewHeight;
        [self.ingridientsTableView reloadData];
    } else {
        float tableViewHeight = 60.0;
        self.stepsTableViewHeightConstraint.constant += tableViewHeight;
        self.formViewHeightConstraint.constant += tableViewHeight;
        [self.stepsTableView reloadData];
    }
}

- (void) decreaseViewsHeight: (BOOL) value{
    if(value){
        float tableViewHeight = 44.0;
        self.ingridientsTableViewHeightConstraint.constant -= tableViewHeight;
        self.formViewHeightConstraint.constant -= tableViewHeight;
        [self.ingridientsTableView reloadData];
    } else {
        float tableViewHeight = 60.0;
        self.stepsTableViewHeightConstraint.constant -= tableViewHeight;
        self.formViewHeightConstraint.constant -= tableViewHeight;
        [self.stepsTableView reloadData];
    }
}

#pragma - mark UITextView delegate
- (void) textViewDidChange:(UITextView *)textView{
    if([textView isEqual:self.recipeDescription]){
        if(previousDescHeight - self.recipeDescription.contentSize.height != 0){
            previousDescHeight = self.recipeDescription.contentSize.height;
            self.recipeDescriptionTextViewHeight.constant = self.recipeDescription.contentSize.height;
            self.formViewHeightConstraint.constant += self.recipeDescription.contentSize.height / 5;
        }
    }
    
}

#pragma mark - UITableView Delegate and DataSource
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([tableView isEqual:self.ingridientsTableView]){
        return 44;
    } else {
        return 60.0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    if (tableView == self.ingridientsTableView) {
        return ingridients.count;
        
    } else {
        return steps.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([tableView isEqual:self.ingridientsTableView]){
        static NSString *CellIdentifier = @"ingridientsCell";
        IngridientsFormTableViewCell *cell = (IngridientsFormTableViewCell *) [self.ingridientsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell.ingridient = ingridients[indexPath.row];
         [cell.deleteButton addTarget:self action:@selector(deleteButton:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    } else {
        static NSString *CellIdentifier = @"stepsCell";
        StepsFormTableViewCell *cell = (StepsFormTableViewCell *) [self.stepsTableView dequeueReusableCellWithIdentifier:CellIdentifier];
        cell.step = steps[indexPath.row];
        cell.delegate = self;
        [cell.deleteButton addTarget:self action:@selector(deleteStepButton:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
}

- (void) deleteButton: (id) sender{
    NSIndexPath *indexPath = [self.ingridientsTableView indexPathForCell:[[sender superview] superview]];
    [ingridients removeObjectAtIndex:indexPath.row];
    [self decreaseViewsHeight:YES];

}

- (void) deleteStepButton: (id) sender{
    NSIndexPath *indexPath = [self.stepsTableView indexPathForCell:[[sender superview] superview]];
    [steps removeObjectAtIndex:indexPath.row];
    [self decreaseViewsHeight:NO];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    RecipeFormHeader *view = [[[NSBundle mainBundle] loadNibNamed:@"RecipeFormHeader" owner:self options:nil] firstObject];
    if([tableView isEqual:self.ingridientsTableView]){
        view.headerTitle.text = NSLocalizedString(@"ingridients", nil);
        [view.headerButton addTarget:self action:@selector(addIngridient:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        view.headerTitle.text = NSLocalizedString(@"steps", nil);
        [view.headerButton addTarget:self action:@selector(addStep:) forControlEvents:UIControlEventTouchUpInside];
    }
    return view;
}
#pragma mark - Steps and Ingridients adding on form
- (void) addIngridient: (id) sender{
    Ingridient *ingridient = [[Ingridient alloc] init];
    [ingridients addObject:ingridient];
    [self increaseViewsHeight:YES];
}
- (void) addStep: (id) sender{
    Step *step = [[Step alloc] init];
    [steps addObject:step];
    [self increaseViewsHeight:NO];
}

#pragma mark - StepCellDelegate methods
- (void) increaseStepsTableViewBy: (float) value{
    if(prevStepHeight - value != 0){
        prevStepHeight = value;
        if(value > 0){
            self.stepsTableViewHeightConstraint.constant += value;
            self.formViewHeightConstraint.constant += value;
        } else {
            self.stepsTableViewHeightConstraint.constant -= value;
            self.formViewHeightConstraint.constant -= value;
        }
    }
}

- (void) selectImageForCell:(StepsFormTableViewCell *) cell{
    selectedCell = cell;
    stepImagePopup = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"recipe_image_cancel", nil) destructiveButtonTitle:nil otherButtonTitles:
                        NSLocalizedString(@"recipe_image_collection", nil),
                        NSLocalizedString(@"recipe_image_camera", nil),
                        nil];
    stepImagePopup.tag = 1;
    [stepImagePopup showInView:self.view];
}

@end
