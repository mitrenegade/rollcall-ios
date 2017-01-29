//
//  TutorialScrollView.m
//  cwsfroster
//
//  Created by Bobby Ren on 9/2/14.
//  Copyright (c) 2014 Bobby Ren. All rights reserved.
//

#import "TutorialScrollView.h"
#import <Parse/Parse.h>

@implementation TutorialScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib {
    self.backgroundColor = [UIColor clearColor];
    [self setupScroll];
    
    [super awakeFromNib];
}

-(void)setupScroll {
    CGFloat width = _appDelegate.window.frame.size.width;
    CGFloat height = _appDelegate.window.frame.size.height;
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [scrollView setPagingEnabled:YES];
    [scrollView setShowsHorizontalScrollIndicator:NO];
    [scrollView setShowsVerticalScrollIndicator:NO];
    [scrollView setDelegate:self];
    [scrollView setBounces:NO];

    pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
    pageControl.pageIndicatorTintColor = [UIColor whiteColor];
    pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:91.0/255.0 green:196.0/255.0 blue:188.0/255.0 alpha:1];

    [self addSubview:scrollView];
    [self addSubview:pageControl];
}

-(void)setTutorialPages:(NSArray *)pageNames {
    int page = 0;
    int width = self.bounds.size.width;
    for (NSString *name in pageNames) {
        NSArray *subviewArray = [[NSBundle mainBundle] loadNibNamed:name owner:self options:nil];
        UIView *tutorialPage = [subviewArray objectAtIndex:0];

        CGPoint center = CGPointMake(page * width + width/2, self.frame.size.height / 2 - 30);
        tutorialPage.center = center;
        [scrollView addSubview:tutorialPage];

        page++;
    }
    [pageControl setNumberOfPages:page];
    [scrollView setContentSize:CGSizeMake(page * width, self.bounds.size.height)];

    pageControl.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height - 40);
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    int currpage = scrollView.contentOffset.x / self.bounds.size.width;
    [pageControl setCurrentPage:currpage];

    [ParseLog logWithTypeString:@"TutorialScrolled" title:nil message:nil params:nil error:nil];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
