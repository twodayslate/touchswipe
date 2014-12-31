#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "libactivator/libactivator.h"

@interface SBUIBiometricEventMonitor : NSObject
-(void)_startFingerDetection;
-(void)_startMatching;
-(void)matchResult:(id)arg1 withDetails:(id)arg2 ;
@end

@interface SBUIBiometricEventObserver : NSObject
-(void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)arg2;
@end

@interface SBGestureRecognizer : NSObject
-(void)touchesBegan:(id)arg1 ;
-(void)touchesMoved:(id)arg1 ;
-(void)touchesEnded:(id)arg1 ;
@end

@interface SBUIController
-(void)_showControlCenterGestureBeganWithLocation:(CGPoint)arg1 ;
@end

@interface SBReachabilityTrigger
-(void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)arg2 ;
@end

@interface SBReachabilityTapTrigger : SBReachabilityTrigger
@end

static CFTimeInterval startTime = CACurrentMediaTime();
// http://stackoverflow.com/questions/741830/getting-the-time-elapsed-objective-c/17986909#17986909


%hook SBReachabilityTapTrigger 
-(void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)arg2 {
	%log;
	%orig;
	startTime = CACurrentMediaTime();
}
%end

%hook SBUIController
-(void)_showControlCenterGestureBeganWithLocation:(CGPoint)arg1 {
	%log;
	%orig;
	if(startTime) {
		CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
		NSLog(@"time interval = %f",elapsedTime);

		LAEvent *event = [LAEvent eventWithName:@"com.twodayslate.touchswipe.activate" mode:[LASharedActivator currentEventMode]];

		if(elapsedTime < 1) {
			NSLog(@"sending event");
			
			[LASharedActivator sendEventToListener:event];
		}
	    if (event.handled) {
	        NSLog(@"Event was handled by an assignment in Activator!");
	    }
	}
}
%end


@interface touchswipeDataSource: NSObject <LAEventDataSource>
@end
 
@implementation touchswipeDataSource
 
static touchswipeDataSource *myDataSource;
 
+ (void)load
{
        @autoreleasepool {
                myDataSource = [[touchswipeDataSource alloc] init];
        }
}
 
- (id)init {
        if ((self = [super init])) {
                [LASharedActivator registerEventDataSource:self forEventName:@"com.twodayslate.touchswipe.activate"];
        }
        return self;
}
 
- (void)dealloc {
        [LASharedActivator unregisterEventDataSourceWithEventName:@"com.twodayslate.touchswipe.activate"];
        [super dealloc];
}
 
- (NSString *)localizedTitleForEventName:(NSString *)eventName {
        return @"touchswipe Activated";
}
 
- (NSString *)localizedGroupForEventName:(NSString *)eventName {
        return @"touchswipe Activated";
}
 
- (NSString *)localizedDescriptionForEventName:(NSString *)eventName {
        return @"touchswipe Activated";
}
 
@end

%hook SpringBoard
-(id)init {
	dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
	// should I be registering my event here? The examples aren't doing this
	return %orig;
}
%end