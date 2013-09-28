//
//  GravatarCardViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 9/28/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "GravatarCardViewController.h"
#import "GravatarCardView.h"
#import "WPAvatarSource.h"

@interface GravatarCardViewController ()

@end

@implementation GravatarCardViewController {
    GravatarCardView *_cardView;

    NSString *_avatarHash;
    UIImage *_placeholderImage;

    UIImage *_avatarImage;
    NSDictionary *_profile;
}

- (id)initWithAvatarHash:(NSString *)hash placeholder:(UIImage *)image
{
    self = [super init];
    if (self) {
        _avatarHash = hash;
        _placeholderImage = image;
    }
    return self;
}

- (void)loadView
{
    _cardView = [[GravatarCardView alloc] init];
    _cardView.avatarImageView.image = _placeholderImage;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cardViewTapped:)];
    [_cardView addGestureRecognizer:recognizer];
    self.view = _cardView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _cardView.avatarLoading = YES;
    _cardView.profileLoading = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[WPAvatarSource sharedSource] fetchImageForAvatarHash:_avatarHash
                                                    ofType:WPAvatarSourceTypeGravatar
                                                  withSize:_cardView.avatarImageView.frame.size
                                                   success:^(UIImage *image) {
                                                       _avatarImage = image;
                                                       _cardView.avatarImageView.image = image;
                                                       _cardView.avatarLoading = NO;
                                                   }];
    NSString *profileUrl = [NSString stringWithFormat:@"https://en.gravatar.com/%@.json", _avatarHash];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:profileUrl]];
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                            _profile = JSON;
                                                                                            [self updateProfile];
                                                                                            _cardView.profileLoading = NO;
                                                                                            WPFLog(@"Got profile for %@: %@", _avatarHash, _profile);
                                                                                        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
                                                                                            _cardView.profileLoading = NO;
                                                                                            WPFLog(@"Error getting profile for %@: %@", _avatarHash, error);
                                                                                        }];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

- (void)updateProfile
{
    if (!_profile) {
        return;
    }
    NSDictionary *profile = [[_profile arrayForKey:@"entry"] firstObject];
    if (!profile) {
        return;
    }
    NSString *name = [profile stringForKey:@"displayName"];
    NSString *bio = [profile stringForKey:@"aboutMe"];

    _cardView.nameLabel.text = name;
    _cardView.bioTextView.text = bio;
}

- (void)cardViewTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
