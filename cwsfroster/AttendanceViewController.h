//
//  AttendanceViewController.h
//  cwsfroster
//
//  Created by Bobby Ren on 9/30/12.
//  Copyright (c) 2012 Bobby Ren. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RosterViewController.h"

@protocol AttendanceViewDelegate <NSObject>

-(void)getRosterWithBlock:(void(^)(NSArray *, NSError *))gotCurrentRoster;
-(void)didSaveWithDate:(NSDate*)date andNotes:(NSString*)notes andRoster:(NSMutableArray*)roster;
@end

@interface AttendanceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, RosterViewDelegate, UITextFieldDelegate>
{
    IBOutlet UIDatePicker * datePicker;    
}
@property (nonatomic, retain) RosterViewController * attendanceController;
@property (nonatomic, retain) RosterViewController * rosterController;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) AddMemberCallback addMemberCallback;
@property (nonatomic, retain) NSMutableArray * currentAttendance;
@property (nonatomic, retain) NSMutableSet * currentAttendanceIDs;
@property (nonatomic, strong) IBOutlet UITextField * inputNotes;
@end
