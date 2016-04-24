//
//  InputDetailsTableViewController.m
//  Vigor
//
//  Created by Avikant Saini on 4/23/16.
//  Copyright © 2016 Dark Army. All rights reserved.
//

#import "InputDetailsTableViewController.h"
#import "BMRDetailsViewController.h"
#import "BMRDetailsTableViewController.h"

@interface InputDetailsTableViewController ()

@property (weak, nonatomic) IBOutlet UITextField *heightField;
@property (weak, nonatomic) IBOutlet UITextField *weightField;

@property (weak, nonatomic) IBOutlet UITextField *ageField;

@property (weak, nonatomic) IBOutlet UISegmentedControl *sexSegControl;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanLabel;

@end

@implementation InputDetailsTableViewController {
	VUserDetails *details;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	if ([[NSUserDefaults standardUserDefaults] integerForKey:@"VUAge"] > 0)
		details = [[VUserDetails alloc] init];
	
	_heightField.text = [NSString stringWithFormat:@"%.2f", details.height];
	_weightField.text = [NSString stringWithFormat:@"%.2f", details.weight];
	_ageField.text = [NSString stringWithFormat:@"%li", details.age];
	_sexSegControl.selectedSegmentIndex = (details.sex == VUserSexMale)?0:1;

}

- (void)viewWillAppear:(BOOL)animated {
	_currentPlanLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentProgram"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doneAction:(id)sender {
	// Done
	
	if (_heightField.text.length < 1) {
		SVHUD_FAILURE(@"Enter the height!")
		return;
	}
	if (_weightField.text.length < 1) {
		SVHUD_FAILURE(@"Enter the weight!")
		return;
	}
	if (_ageField.text.length < 1) {
		SVHUD_FAILURE(@"Enter the age!")
		return;
	}
	
	details = [[VUserDetails alloc] init];
	
	details.height = [_heightField.text doubleValue];
	details.weight = [_weightField.text doubleValue];
	details.age = [_ageField.text integerValue];
	if ([_sexSegControl selectedSegmentIndex] == 2)
		details.sex = VUserSexOther;
	else if ([_sexSegControl selectedSegmentIndex] == 1)
		details.sex = VUserSexFemale;
	else
		details.sex = VUserSexMale;
	
	[details saveToDefaults];
	
	UITabBarController *tabVC = [self.storyboard instantiateViewControllerWithIdentifier:@"TabBarVC"];
	UINavigationController *navc = [tabVC.viewControllers firstObject];
	BMRDetailsTableViewController *bdvc = [navc.viewControllers firstObject];
	bdvc.details = details;
	
	[self presentViewController:tabVC animated:YES completion:^{
		self.view.window.rootViewController = tabVC;
	}];
//
//	[self dismissViewControllerAnimated:tabVC completion:^{
//		self.view.window.rootViewController = tabVC;
//	}];
	
	NSLog(@"%@", details);
	
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == tableView.numberOfSections - 1) {
		// Done!
		[self doneAction:self];
	}
	
}

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation


@end
