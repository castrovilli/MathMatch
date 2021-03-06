//
//  MMXResultsViewController.m
//  MathMatch
//
//  Created by Kyle O'Brien on 2014.4.18.
//  Copyright (c) 2014 Computer Lab. All rights reserved.
//

#import "MMXResultsViewController.h"
#import "MMXTimeIntervalFormatter.h"
#import "MMXTopScore.h"

@interface MMXResultsViewController ()

@end

NSString * const kMMXResultsDidSaveGameNotification = @"MMXResultsDidSaveGameNotification";

@implementation MMXResultsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.timeLabel.text = [MMXTimeIntervalFormatter stringWithInterval:self.gameData.completionTime.doubleValue
                                                         forFormatType:MMXTimeIntervalFormatTypeLong];
    self.incorrectMatchesLabel.text = [NSString stringWithFormat:@"%ld", (long)self.gameData.incorrectMatches.integerValue];
    self.penaltyMultiplierLabel.text = [NSString stringWithFormat:@"x %2.1fs", self.gameData.penaltyMultiplier.floatValue];
    
    NSTimeInterval penaltyTime = self.gameData.incorrectMatches.integerValue * self.gameData.penaltyMultiplier.floatValue;
    self.gameData.completionTimeWithPenalty = [NSNumber numberWithDouble:penaltyTime];
    self.penaltyTimeLabel.text = [MMXTimeIntervalFormatter stringWithInterval:penaltyTime
                                                                forFormatType:MMXTimeIntervalFormatTypeLong];
    
    self.gameData.completionTimeWithPenalty = @(self.gameData.completionTime.doubleValue + penaltyTime);
    self.totalTimeLabel.text = [MMXTimeIntervalFormatter stringWithInterval:self.gameData.completionTimeWithPenalty.floatValue
                                                              forFormatType:MMXTimeIntervalFormatTypeLong];
    
    if (self.gameData.gameType == MMXGameTypeCourse)
    {
        if (self.gameData.completionTimeWithPenalty.floatValue < self.gameData.threeStarTime.floatValue)
        {
            self.gameData.starRating = @3;
        }
        else if (self.gameData.completionTimeWithPenalty.floatValue < self.gameData.twoStarTime.floatValue)
        {
            self.gameData.starRating = @2;
        }
        else
        {
            self.gameData.starRating = @1;
        }
    }
    
    if (self.gameData.gameType == MMXGameTypeCourse)
    {
        // Pull out top score.
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"MMXTopScore"
                                                             inManagedObjectContext:self.managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:entityDescription];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lessonID == %@", self.gameData.lessonID];
        [fetchRequest setPredicate:predicate];
        
        NSError *fetchError = nil;
        NSArray *fetchedResults = [self.managedObjectContext executeFetchRequest:fetchRequest error:&fetchError];
        
        MMXTopScore *topScoreForLesson;
        if (fetchedResults.count > 0)
        {
            topScoreForLesson = fetchedResults[0];
            
            self.bestTimeLabel.text = [MMXTimeIntervalFormatter stringWithInterval:topScoreForLesson.time.floatValue
                                                                     forFormatType:MMXTimeIntervalFormatTypeLong];
            
            if (floorf(self.gameData.completionTimeWithPenalty.floatValue) < floorf(topScoreForLesson.time.floatValue))
            {
                topScoreForLesson.lessonID = [self.gameData.lessonID copy];
                topScoreForLesson.time = [self.gameData.completionTimeWithPenalty copy];
                topScoreForLesson.stars = [self.gameData.starRating copy];
                topScoreForLesson.gameData = self.gameData;
                
                // TODO: Play kid horray sound!
                self.recordLabel.hidden = NO;
                [self rainbowizeNewRecordLabel];
                [UIView animateWithDuration:0.75
                                      delay:0.0
                                    options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat
                                 animations:^
                                 {
                                     self.recordLabel.transform = CGAffineTransformMakeScale(1.25, 1.25);
                                 }
                                 completion:nil];
            }
        }
        else
        {
            topScoreForLesson = [NSEntityDescription insertNewObjectForEntityForName:@"MMXTopScore"
                                                              inManagedObjectContext:self.managedObjectContext];
            
            topScoreForLesson.lessonID = self.gameData.lessonID;
            topScoreForLesson.time = self.gameData.completionTimeWithPenalty;
            topScoreForLesson.stars = self.gameData.starRating;
            topScoreForLesson.gameData = self.gameData;
            
            self.bestTimeLabel.text = NSLocalizedString(@"---", nil);
        }
    }
    else
    {
        self.bestTimeLabel.text = NSLocalizedString(@"---", nil);
    }
    
    NSLog(@"%@", self.gameData);
    
    NSError *error = nil;
    [self.managedObjectContext save:&error];
    
    if (error)
    {
        NSLog(@"MOC: %@", error.description);
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMMXResultsDidSaveGameNotification object:nil];
    }
    
    if (self.gameData.gameType == MMXGameTypeCourse)
    {
        [self.menuButton changeButtonToColor:[UIColor mmx_blueColor]];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            [self beginStarAnimationForStar:1];
        });
    }
    else
    {
        self.rankContainerView.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.hidesBackButton = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)playerTappedMenuButton:(id)sender
{
    NSString *secondOption;
    if (self.gameData.gameType == MMXGameTypePractice)
    {
        secondOption = NSLocalizedString(@"Change Settings", nil);
    }
    else
    {
        secondOption = NSLocalizedString(@"Show Lessons", nil);
    }
    
    NSString *message = NSLocalizedString(@"The game is over. What would you like to do?", nil);
    NSArray *otherButtonTitles = @[NSLocalizedString(@"Main Menu", nil), NSLocalizedString(@"Try Again", nil), secondOption];
    KMODecisionView *decisionView = [[KMODecisionView alloc] initWithMessage:message
                                                                    delegate:self
                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                           otherButtonTitles:otherButtonTitles];
    decisionView.fontName = @"Futura-Medium";
    
    [decisionView showAndDimBackgroundWithPercent:0.50];
}

- (void)rainbowizeNewRecordLabel
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.recordLabel.attributedText.string];
    NSArray *colors = @[[UIColor mmx_redColor], [UIColor mmx_blueColor], [UIColor mmx_greenColor],
                        [UIColor mmx_orangeColor], [UIColor mmx_purpleColor]];
    
    [attributedString beginEditing];
    for (NSInteger i = 0; i < self.recordLabel.text.length; i++)
    {
        [attributedString addAttribute:NSForegroundColorAttributeName
                                 value:colors[i % colors.count]
                                 range:NSMakeRange(i, 1)];
    }
    [attributedString endEditing];
    
    self.recordLabel.attributedText = attributedString;
}

- (void)beginStarAnimationForStar:(NSInteger)starNumber
{
    CGAffineTransform scaleStart = CGAffineTransformMakeScale(25.0, 25.0);
    CGAffineTransform rotateStart = CGAffineTransformMakeRotation(-M_PI_4);
    CGAffineTransform scaleAndRotateStart = CGAffineTransformConcat(scaleStart, rotateStart);
    
    if (starNumber == 1)
    {
        self.rankStar1ImageView.transform = scaleAndRotateStart;
        self.rankStar1ImageView.hidden = NO;
    }
    else if (starNumber == 2)
    {
        self.rankStar2ImageView.transform = scaleAndRotateStart;
        self.rankStar2ImageView.hidden = NO;
    }
    else if (starNumber == 3)
    {
        self.rankStar3ImageView.transform = scaleAndRotateStart;
        self.rankStar3ImageView.hidden = NO;
    }

    __block NSInteger starNumberForBlock = starNumber;
    
    [UIView animateWithDuration:0.20
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
                     {
                         CGAffineTransform scaleEnd = CGAffineTransformMakeScale(1.0, 1.0);
                         CGAffineTransform rotateEnd = CGAffineTransformMakeRotation(0.0);
                         CGAffineTransform scaleAndRotateEnd = CGAffineTransformConcat(scaleEnd, rotateEnd);
                         
                         if (starNumber == 1)
                         {
                             self.rankStar1ImageView.transform = scaleAndRotateEnd;
                         }
                         else if (starNumber == 2)
                         {
                             self.rankStar2ImageView.transform = scaleAndRotateEnd;
                         }
                         else if (starNumber == 3)
                         {
                             self.rankStar3ImageView.transform = scaleAndRotateEnd;
                         }
                     }
                     completion:^(BOOL finished)
                     {
                         if (starNumber < self.gameData.starRating.integerValue)
                         {
                             [self beginStarAnimationForStar:(starNumberForBlock + 1)];
                         }
                     }];
}

#pragma mark - KMODecisionViewDelegate

- (void)decisionView:(KMODecisionView *)decisionView tappedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        // Player cancelled. Do nothing.
    }
    else if (buttonIndex == 1) // Player decided to return to the main menu.
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else if (buttonIndex == 2) // Player wants to try again.
    {
         [self performSegueWithIdentifier:@"MMXUnwindToGameSegue" sender:self];
    }
    else if (buttonIndex == 3)
    {
        // Player wanted to change the settings or the course.
        if (self.gameData.gameType == MMXGameTypePractice)
        {
            [self performSegueWithIdentifier:@"MMXUnwindToPracticeConfigurationSegue" sender:self];
        }
        else // Player wanted to view the list of lessons for the current course.
        {
            [self performSegueWithIdentifier:@"MMXUnwindToLessonsSegue" sender:self];
        }
    }
}

@end
