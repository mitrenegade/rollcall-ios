#import "Util.h"

@implementation Util

+(NSString *)simpleDateFormat:(NSDate *)date {
    return [self simpleDateFormat:date local:YES];
}

+(NSString *)simpleDateFormat:(NSDate *)date local:(BOOL)local{
    // only check and generate once
    static NSDateFormatter *simpleDateFormatter;
    static dispatch_once_t a; dispatch_once(&a, ^{
        if (!simpleDateFormatter) {
            simpleDateFormatter = [[NSDateFormatter alloc] init];
            [simpleDateFormatter setDateFormat:@"MM/dd"];
        }
    });
    // update timezone if needed
    if (local)
        [simpleDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    else
        [simpleDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return [simpleDateFormatter stringFromDate:date];
}

+(NSString *)timeStringForDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yy HH:mm"];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)timeAgo:(NSDate *)date
{
    double deltaSeconds = fabs([date timeIntervalSinceNow]);
    double deltaMinutes = deltaSeconds / 60.0f;
    double deltaHours = deltaMinutes / 60.0f;
    double deltaDays = deltaHours / 24;
    double deltaWeeks = deltaDays / 7;
    double deltaMonths = deltaDays / 30; // rough estimate

    if(deltaSeconds < 5)
    {
        return @"Just now";
    }
    else if(deltaSeconds < 60)
    {
        return [NSString stringWithFormat:@"%d sec ago", (int)deltaSeconds];
    }
    else if (deltaMinutes < 60)
    {
        return [NSString stringWithFormat:@"%d min ago", (int)deltaMinutes];
    }
    else if (deltaHours < 24)
    {
        return [NSString stringWithFormat:@"%d hr ago", (int)deltaHours];
    }
    else if (deltaDays < 7)
    {
        if (deltaDays == 1)
            return @"1 day ago";
        return [NSString stringWithFormat:@"%d days ago", (int)deltaDays];
    }
    else if (deltaWeeks < 8)
    {
        return [NSString stringWithFormat:@"%d wk ago", (int)deltaWeeks];
    }
    else if (deltaMonths < 13)
    {
        return [NSString stringWithFormat:@"%d mon ago", (int)deltaMonths];
    }
    else if (deltaMonths < 24)
    {
        return @"Last year";
    }
    else
    {
        return @"In the past";
    }
}

+ (NSString *)simpleTimeAgo:(NSDate *)date {
    double deltaSeconds = fabs([date timeIntervalSinceNow]);
    if (deltaSeconds < 24*3600)
    {
        return @"Today";
    }
    return [self timeAgo:date];
}

+(NSDate *)beginningOfDate:(NSDate *)date localTimeZone:(BOOL)local {
    // warning: DST
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components =
    [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit |
                           NSDayCalendarUnit) fromDate:date];
    if (local) // local timezone...may display with time offsets
        [gregorian setTimeZone:[NSTimeZone localTimeZone]];
    else
        [gregorian setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    return [gregorian dateFromComponents:components];
}

+(NSDate *)beginningOfMonthForDate:(NSDate *)date localTimeZone:(BOOL)local {
    // warning: DST
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* components = [gregorian components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit fromDate:date]; // Get necessary date components
    if (local) // local timezone...may display with time offsets
        [gregorian setTimeZone:[NSTimeZone localTimeZone]];
    else
        [gregorian setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [components setDay:1];
    return [gregorian dateFromComponents:components];
}

+(NSDate *)endOfMonthForDate:(NSDate *)date localTimeZone:(BOOL)local {
    // warning: DST
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* components = [gregorian components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit fromDate:date]; // Get necessary date components
    if (local) // local timezone...may display with time offsets
        [gregorian setTimeZone:[NSTimeZone localTimeZone]];
    else
        [gregorian setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    components.day = 0;
    components.hour = 23;
    components.minute = 59;
    components.second = 59;
    [components setMonth:([components month]+1)];
    return [gregorian dateFromComponents:components];
}

+(BOOL)date:(NSDate *)date containedInWeekOfDate:(NSDate *)targetDate {
    // accounts for DST
    // takes week span for targetDate, and determines if date is contained inside it

    NSDate *start;
    NSTimeInterval extends;
    NSCalendar *cal=[NSCalendar autoupdatingCurrentCalendar];
    [cal setFirstWeekday:2]; // forces monday to be the beginning of the week
    [cal setTimeZone:[NSTimeZone localTimeZone]];
    BOOL success= [cal rangeOfUnit:NSWeekCalendarUnit startDate:&start
                          interval: &extends forDate:targetDate];
    NSTimeInterval dateInSecs = [date timeIntervalSinceReferenceDate];
    NSTimeInterval dayStartInSecs= [start timeIntervalSinceReferenceDate];
    if(dateInSecs >= dayStartInSecs && dateInSecs <= (dayStartInSecs+extends)){
        return YES;
    }
    else {
        return NO;
    }
}

+(NSString*)weekdayStringFromDate:(NSDate*)date localTimeZone:(BOOL)local {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    if (!local)
        [gregorian setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDateComponents *comps = [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSWeekdayCalendarUnit) fromDate:date];
    NSLog(@"Date: %@ weekday: %ld", date, (long)comps.weekday);
    int weekday = [comps weekday];
    // for some reason, weekday: 1 = sunday, 2 = mon, etc
    return [@[@"Sat", @"Sun", @"Mon", @"Tues", @"Wed", @"Thurs", @"Fri", @"Sat", @"Sun"] objectAtIndex:weekday]; // weekday ranges from 1 to 7
}

+(NSString *)shortMonthForDate:(NSDate *)date {
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components =
    [gregorian components:(NSYearCalendarUnit | NSMonthCalendarUnit |
                           NSDayCalendarUnit) fromDate:date];
    NSInteger monthNumber = [components month];
    NSDateFormatter *monthFormatter = [[NSDateFormatter alloc] init];
    NSString *monthName = [[monthFormatter monthSymbols] objectAtIndex:(monthNumber-1)];
    NSString *shortString = [[monthName substringToIndex:3] uppercaseString];
    return shortString;
}
@end
