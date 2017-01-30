//
//  ShellViewController.m
//  cwsfroster
//
//  Created by Bobby Ren on 8/31/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "ShellViewController.h"

@interface ShellViewController ()

@end

@implementation ShellViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // special tkd stuff
    [self updateTabBarIcons];
    [self listenFor:@"organization:name:changed" action:@selector(updateTabBarIcons)];
    [self listenFor:@"goToSettings" action:@selector(goToSettings:)];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"organization:is:new"]) {
        [self setSelectedIndex:1];
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"organization:is:new"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"organization:is:new"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSString *title = [NSString stringWithFormat: @"Welcome to %@", [[Organization currentOrganization] name]];
        [self simpleAlert:title message:@"Add some members to your new organization."];
    }
}

-(void)updateTabBarIcons {
    NSString *name = [[Organization currentOrganization].name lowercaseString];
    if (name &&
        ([[[Organization currentOrganization].name lowercaseString] rangeOfString:@"taekwondo"].location != NSNotFound || [[[Organization currentOrganization].name lowercaseString] rangeOfString:@"tkd"].location != NSNotFound || [[[Organization currentOrganization].name lowercaseString] rangeOfString:@"tae kwon do"].location != NSNotFound)) {
        [self setIcon:@"icon-tkd-paddle" forTabBar:0];
        [self setIcon:@"icon-tkd-helmet" forTabBar:1];
    }
    else {
        [self setIcon:@"icon-calendar" forTabBar:0];
        [self setIcon:@"icon-users" forTabBar:1];
    }
}

-(void)setIcon:(NSString *)iconName forTabBar:(int)tabBarIndex {
    UIViewController * controller = self.viewControllers[tabBarIndex];
    UITabBarItem *item = controller.tabBarItem;
    item.image = [UIImage imageNamed:iconName];
    item.selectedImage = item.image;
}

-(void)goToSettings:(NSNotification *)n {
    UINavigationController *nav = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingsNavigationController"];
    [self presentViewController:nav animated:YES completion:nil];
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

@end
