//
//  BMRDetailsViewController.m
//  Vigor
//
//  Created by Avikant Saini on 4/23/16.
//  Copyright © 2016 Dark Army. All rights reserved.
//

#import "BMRDetailsViewController.h"

@interface BMRDetailsViewController () <ORKTaskViewControllerDelegate>
{
    ORKInstructionStep *instructUser;
    ORKQuestionStep *sendFeedback;
    ORKFormStep *fillForm;
    
    KCSAppdataStore *store;
}


@property (weak, nonatomic) IBOutlet UILabel *howmuchLabel;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *workoutSelectionButtons;

@property (weak, nonatomic) IBOutlet UILabel *abfpLabel;
@property (weak, nonatomic) IBOutlet UILabel *bmiLabel;
@property (weak, nonatomic) IBOutlet UILabel *bmrCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *tciCountLabel;


@end

@implementation BMRDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    store = [KCSAppdataStore storeWithOptions:@{KCSStoreKeyCollectionName:@"Feedback",
                                                KCSStoreKeyCollectionTemplateClass:[OnlineFeedback class]}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {

	if (self.details) {
		[self updateIntake:1.22];
	}
    if (![KCSUser activeUser])
    {
        [KCSUser createAutogeneratedUser:nil completion:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)   {
            if (errorOrNil != nil)
            {
                //load failed
                NSLog(@"load fail user auth");
            }
            else
            {
            }
        }];
    }
    else
    {
    }
}

- (IBAction)setWorkOutMode:(id)sender {
	NSInteger tag = [sender tag];
	switch (tag) {
		case 1:
			[self updateIntake:1.22];
			break;
		case 2:
			[self updateIntake:1.34];
			break;
		case 3:
			[self updateIntake:1.51];
			break;
		case 4:
			[self updateIntake:1.66];
			break;
		case 5:
			[self updateIntake:1.79];
			break;
	  default:
			break;
	}
}

- (void)updateIntake:(CGFloat)multiplier
{
	CGFloat totalIntake = self.details.bmr * multiplier;
	_bmrCountLabel.text = [NSString stringWithFormat:@"%.2f KCal", self.details.bmr];
	_tciCountLabel.text = [NSString stringWithFormat:@"%.2f KCal", totalIntake];
	_bmiLabel.text = [NSString stringWithFormat:@"%.3f", self.details.bmi];
	_abfpLabel.text = [NSString stringWithFormat:@"%.3f", self.details.abfp];
}

- (IBAction)giveFeedbackAction:(id)sender
{
    instructUser = [[ORKInstructionStep alloc] initWithIdentifier:@"intro"];
    instructUser.title = @"Enter Your Feedback";
    
    fillForm = [[ORKFormStep alloc] initWithIdentifier:@"FeedbackForm" title:@"Comments" text:@""];
    ORKFormItem *feedbackItem = [[ORKFormItem alloc] initWithIdentifier:@"formItem" text:@"Give Your Feedback" answerFormat:[ORKAnswerFormat textAnswerFormat] optional:NO];
    fillForm.formItems = @[feedbackItem];
    
    ORKOrderedTask *task = [[ORKOrderedTask alloc] initWithIdentifier:@"task" steps:@[fillForm]];
    
    ORKTaskViewController *taskViewController =
    [[ORKTaskViewController alloc] initWithTask:task taskRunUUID:nil];
    taskViewController.delegate = self;
    
    [self presentViewController:taskViewController animated:YES completion:nil];
}

- (void)taskViewController:(ORKTaskViewController *)taskViewController didFinishWithReason:(ORKTaskViewControllerFinishReason)reason error:(NSError *)error
{
    ORKTaskResult *feedbackComplete = [taskViewController result];
    
    ORKStepResult *feedbackProvided = (ORKStepResult *) [feedbackComplete.results lastObject];
    
    if (reason == ORKTaskViewControllerFinishReasonCompleted)
    {
	
        NSString *feedbackString = [[feedbackProvided.results firstObject] valueForKey:@"answer"];
        
        // obtain input value from [[finalResult.results firstObject] valueForKey:@"answer"]
        // send this value to haven api, then send results of that to kinvey
        
        NSURL *URL = [NSURL URLWithString:@"https://api.havenondemand.com/1/api/sync/analyzesentiment/v1"];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        
        NSString *httpBody = [NSString stringWithFormat:@"apikey=72e6bddf-7f53-4779-90e9-7b27688792a5&text=%@", feedbackString];
        request.HTTPBody = [httpBody dataUsingEncoding:NSUTF8StringEncoding];
        
        SVHUD_SHOW;
        
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error)
                return;
            
            @try {
                id jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                NSLog(@"analyzesentiment:\n%@", jsonData);
                
                CGFloat aggscore = [[jsonData valueForKeyPath:@"aggregate.score"] doubleValue];
                NSString *aggString = [jsonData valueForKeyPath:@"aggregate.sentiment"];
                
                NSLog(@"Agg score = %.4f | Agg string = %@", aggscore, aggString);
                
                // Save to core data
                [Feedback createNewFeedbackWithDate:[NSDate date] review:aggString value:aggscore];
                
                // Push to server
                
                OnlineFeedback *feedback = [[OnlineFeedback alloc] init];
                feedback.dateOfUpload = [NSDate date];
                feedback.valueForFeedback = [NSNumber numberWithFloat:aggscore];
                feedback.review = aggString;
    //            feedback.programName = [NSString stringWithFormat:@"SorteSwag%i", arc4random_uniform(9)+1];
                feedback.programName = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentProgram"];
                
                [store saveObject:feedback withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil)
                 {
                     if (errorOrNil != nil)
                     {
                         //save failed
                         NSLog(@"Save failed, with error: %@", [errorOrNil localizedFailureReason]);
                     } else
                     {
                         //save was successful
                         NSLog(@"successful save");
                     }
                 } withProgressBlock:nil];
                
                SVHUD_HIDE;
                [self dismissViewControllerAnimated:YES completion:nil];
                
            }
            @catch (NSException *exception)
            {
                
            }
            
        }] resume];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
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

@end
