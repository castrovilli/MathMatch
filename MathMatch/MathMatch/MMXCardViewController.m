//
//  MMXCardViewController.m
//  MathMatch
//
//  Created by Kyle O'Brien on 2014.2.11.
//  Copyright (c) 2014 Computer Lab. All rights reserved.
//

#import "MMXCardViewController.h"

@interface MMXCardViewController()

@property (nonatomic, strong) UIColor *edgeColor;
@property (nonatomic, strong) UIImage *faceDownImage;

@end

@implementation MMXCardViewController

- (id)initWithCardStyle:(MMXCardStyle)cardStyle
{
    self = [super initWithNibName:@"MMXCardViewController" bundle:[NSBundle mainBundle]];
    if (self)
    {
        if (cardStyle == MMXCardStyle01)
        {
            self.edgeColor = [UIColor colorWithRed:(1.0 / 255.0) green:(170.0 / 255.0) blue:(227.0 / 255.0) alpha:1.0];
            
            self.faceDownImage = [UIImage imageNamed:@"MMXCardStyleDots"];
            self.faceDownImage = [self.faceDownImage resizableImageWithCapInsets:UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0) resizingMode:UIImageResizingModeTile];
        }
        else
        {
            self.edgeColor = [UIColor colorWithRed:(0.0 / 255.0) green:(0.0 / 255.0) blue:(0.0 / 255.0) alpha:1.0];
            
            self.faceDownImage = nil;
        }
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.containerView.layer.cornerRadius = 6.0;
    self.containerView.layer.borderColor = self.edgeColor.CGColor;
    self.containerView.layer.borderWidth = 2.0;
    self.containerView.clipsToBounds = YES;
    
    self.faceUpButton.layer.cornerRadius = 6.0;
    self.faceUpButton.layer.borderColor = self.edgeColor.CGColor;
    self.faceUpButton.layer.borderWidth = 2.0;
    self.faceUpButton.clipsToBounds = YES;
    self.faceUpButton.backgroundColor = self.edgeColor;
    
    self.faceDownButton.layer.cornerRadius = 6.0;
    self.faceDownButton.layer.borderColor = self.edgeColor.CGColor;
    self.faceDownButton.layer.borderWidth = 2.0;
    self.faceDownButton.clipsToBounds = YES;
    
    [self.faceUpButton setTitle:[NSString stringWithFormat:@"%ld", self.card.value]
                       forState:UIControlStateNormal];
    
    [self.faceDownButton setBackgroundImage:self.faceDownImage forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
        
    self.faceUpButton.titleLabel.font = [UIFont fontWithName:@"Futura" size:self.fontSize];
    self.faceUpButton.titleLabel.adjustsFontSizeToFitWidth = NO;
}

- (IBAction)playerRequestedCardFlip:(id)sender
{
    if (self.card.isFaceUp)
    {
        // Don't let the player flip it back down.
    }
    else
    {
        if ([self.delegate playerRequestedFlipFor:self])
        {
            [self flipCardFaceUp];
        }
    }
}

- (void)flipCardFaceDown
{
    if (self.card.isFaceUp)
    {
        [self.card flip];
    }
    
    [UIView transitionWithView:self.containerView
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^
                    {
                        self.faceDownButton.hidden = NO;
                        self.faceUpButton.hidden = YES;
                    }
                    completion:^(BOOL finished)
                    {
                        if (finished)
                        {
                            if (self.delegate && [self.delegate respondsToSelector:@selector(finishedFlippingFor:)])
                            {
                                //[self.delegate finishedFlippingFor:self];
                                // TODO: This was causing a loop. Dod we need to know when this happens?
                            }
                        }
                    }];
}

- (void)flipCardFaceUp
{
    if (!self.card.isFaceUp)
    {
        [self.card flip];
        
        [UIView transitionWithView:self.containerView
                          duration:0.3
                           options:UIViewAnimationOptionTransitionFlipFromRight
                        animations:^
                        {
                            self.faceDownButton.hidden = YES;
                            self.faceUpButton.hidden = NO;
                        }
                        completion:^(BOOL finished)
                        {
                            if (finished)
                            {
                                if (self.delegate && [self.delegate respondsToSelector:@selector(finishedFlippingFor:)])
                                {
                                    [self.delegate finishedFlippingFor:self];
                                }
                            }
                        }];
    }
}

- (void)removeCardFromTable
{
    if (self.card.isFaceUp)
    {
        self.view.hidden = YES;
    }
}

@end
