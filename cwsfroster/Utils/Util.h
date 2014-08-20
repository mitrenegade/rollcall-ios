#import <Foundation/Foundation.h>

@interface Util : NSObject

+(void)easyRequest:(NSString *)endpoint method:(NSString *)method params:(id)params completion:(void(^)(NSDictionary *, NSError *))completion;

+(NSString *)simpleDateFormat:(NSDate *)date;
+(NSString *)simpleDateFormat:(NSDate *)date local:(BOOL)local;
+(NSString *)timeStringForDate:(NSDate *)date;
+ (NSString *)timeAgo:(NSDate *)date;
+ (NSString *)simpleTimeAgo:(NSDate *)date;

+(NSDate *)beginningOfDate:(NSDate *)date localTimeZone:(BOOL)local;
+(NSDate *)beginningOfMonthForDate:(NSDate *)date localTimeZone:(BOOL)local;
+(NSDate *)endOfMonthForDate:(NSDate *)date localTimeZone:(BOOL)local;
+(BOOL)date:(NSDate *)date containedInWeekOfDate:(NSDate *)targetDate;
+(NSString*)weekdayStringFromDate:(NSDate*)date localTimeZone:(BOOL)local;
+(NSString *)shortMonthForDate:(NSDate *)date;
@end
