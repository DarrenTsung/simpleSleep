//
//  ViewController.m
//  SimpleSleep
//
//  Created by Darren Tsung on 10/22/14.
//  Copyright (c) 2014 self.edu. All rights reserved.
//

#import "ViewController.h"
#import <SpriteKit/SpriteKit.h>
#import "SunAndMoonScene.h"

#define CLAMP(x, low, high) ({\
__typeof__(x) __x = (x); \
__typeof__(low) __low = (low);\
__typeof__(high) __high = (high);\
__x > __high ? __high : (__x < __low ? __low : __x);\
})

#define SLEEPING_CYCLE_TIME 90
#define AVERAGE_FALL_ASLEEP_TIME 15

#define STARTING_INDEX 5

#define PSUEDO_DELTA 0.016f

typedef enum {
    RIGHT,
    LEFT,
    NONE
} SlidingToType;

@interface ViewController ()

@property (strong, readonly) NSTimer *timer;
@property (strong, readonly) NSTimer *updateTimer;
@property (strong, readwrite) NSMutableArray *timeOffsets;

@property (assign, readwrite) int currentIndex;

@property (assign, readwrite) CGFloat lerpPosition;
@property (assign, readwrite) CGFloat grabbedLerpPosition;
@property (assign, readwrite) CGPoint startingTouchPosition;
@property (assign, readwrite) double startingTouchTime;

@property (strong, readwrite) NSArray *colorDataArray;

@property (assign, readwrite) bool beingTouched;
@property (assign, readwrite) SlidingToType slidingTo;

@property (strong, readwrite) SKView *skView;
@property (strong, readwrite) SunAndMoonScene *sunMoonScene;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _lerpPosition = 0.0f;
    _slidingTo = NONE;
    
    
    [self readColorData];
    [self scheduleUpdates];
    [self createSunMoonScene];
    [self createTimeOffsetArray];
    [self createTimeLabels];
    
}

- (void)scheduleUpdates
{
   _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimeLabels:) userInfo:nil repeats:YES];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:PSUEDO_DELTA target:self selector:@selector(update:) userInfo:nil repeats:YES];
}

- (void)readColorData
{
    _colorDataArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ColorMapping" ofType:@"plist"]];
    
    for (NSArray *colorData in _colorDataArray)
    {
        NSInteger time = [[colorData objectAtIndex:0] integerValue];
        NSArray *colors = [colorData objectAtIndex:1];
    }
}

- (UIColor *)colorForMinuteValue:(NSInteger)minuteValue
{
    NSInteger highestBelow = -1, lowestAbove = -1;
    UIColor *highestBelowColor, *lowestAboveColor;
    
    for (NSArray *colorData in _colorDataArray)
    {
        NSInteger time = [[colorData objectAtIndex:0] integerValue];
        NSArray *colors = [colorData objectAtIndex:1];
        
        if (time < minuteValue && (highestBelow == -1 || time > highestBelow))
        {
            highestBelow = time;
            highestBelowColor = [UIColor colorWithRed:[[colors objectAtIndex:0] floatValue]/255.0f
                                                green:[[colors objectAtIndex:1] floatValue]/255.0f
                                                 blue:[[colors objectAtIndex:2] floatValue]/255.0f alpha:1.0f];
        }
        else if (time >= minuteValue && (lowestAbove == -1 || time < lowestAbove))
        {
            lowestAbove = time;
            lowestAboveColor = [UIColor colorWithRed:[[colors objectAtIndex:0] floatValue]/255.0f
                                               green:[[colors objectAtIndex:1] floatValue]/255.0f
                                                blue:[[colors objectAtIndex:2] floatValue]/255.0f alpha:1.0f];
        }
    }
    
    // if we didn't find a time lower than the minuteValue, go to the highest time (last object in array)
    if (highestBelow == -1)
    {
        NSArray *colorData = [_colorDataArray objectAtIndex:[_colorDataArray count]-1];
        NSInteger time = [[colorData objectAtIndex:0] integerValue];
        NSArray *colors = [colorData objectAtIndex:1];
        
        highestBelow = time - 24*60;
        highestBelowColor = [UIColor colorWithRed:[[colors objectAtIndex:0] floatValue]/255.0f
                                            green:[[colors objectAtIndex:1] floatValue]/255.0f
                                             blue:[[colors objectAtIndex:2] floatValue]/255.0f alpha:1.0f];
    }
    
    if (lowestAbove == -1)
    {
        NSArray *colorData = [_colorDataArray objectAtIndex:0];
        NSInteger time = [[colorData objectAtIndex:0] integerValue];
        NSArray *colors = [colorData objectAtIndex:1];
        
        lowestAbove = 24*60 + time;
        lowestAboveColor = [UIColor colorWithRed:[[colors objectAtIndex:0] floatValue]/255.0f
                                           green:[[colors objectAtIndex:1] floatValue]/255.0f
                                            blue:[[colors objectAtIndex:2] floatValue]/255.0f alpha:1.0f];
    }
    
    CGFloat lerpedValue = ((CGFloat)minuteValue - (CGFloat)highestBelow)/((CGFloat)lowestAbove - (CGFloat)highestBelow);
    
    const CGFloat* belowComponents = CGColorGetComponents(highestBelowColor.CGColor);
    CGFloat belowRed = belowComponents[0];
    CGFloat belowGreen = belowComponents[1];
    CGFloat belowBlue = belowComponents[2];
    
    const CGFloat* aboveComponents = CGColorGetComponents(lowestAboveColor.CGColor);
    CGFloat aboveRed = aboveComponents[0];
    CGFloat aboveGreen = aboveComponents[1];
    CGFloat aboveBlue = aboveComponents[2];
    
    CGFloat lerpedRed = (aboveRed - belowRed)*lerpedValue + belowRed;
    CGFloat lerpedGreen = (aboveGreen - belowGreen)*lerpedValue + belowGreen;
    CGFloat lerpedBlue = (aboveBlue - belowBlue)*lerpedValue + belowBlue;
    UIColor *lerpedColor = [UIColor colorWithRed:lerpedRed
                                           green:lerpedGreen
                                            blue:lerpedBlue
                                           alpha:1.0f];
    
    return lerpedColor;
}

- (void)createTimeOffsetArray
{
    _timeOffsets = [NSMutableArray array];
    for (int i=1; i<19; i++) {
        NSNumber *offset = [NSNumber numberWithInt:AVERAGE_FALL_ASLEEP_TIME + SLEEPING_CYCLE_TIME*i];
        [_timeOffsets addObject:offset];
    }
}

- (void)createSunMoonScene
{
    _skView = [[SKView alloc]initWithFrame:self.view.frame];
    
    _sunMoonScene = [[SunAndMoonScene alloc] initWithSize:self.view.frame.size];
    [_skView presentScene:_sunMoonScene];
    
    [self.view insertSubview:_skView atIndex:0];
}

- (void)createTimeLabels
{
    _currentIndex = STARTING_INDEX;
    
    UIFont *smallFont = [UIFont fontWithName:@"Noteworthy" size:20.0f];
    UIFont *largeFont = [UIFont fontWithName:@"Noteworthy" size:70.0f];
    
    _leftTimeLabel.font = largeFont;
    _leftTimeLabel.textColor = [UIColor whiteColor];
    _leftTimeLabel.text = @"LEFT";
    [_leftTimeLabel setTextAlignment:NSTextAlignmentCenter];
    
    _centerTimeLabel.font = largeFont;
    _centerTimeLabel.textColor = [UIColor whiteColor];
    _centerTimeLabel.text = @"CENTER";
    [_centerTimeLabel setTextAlignment:NSTextAlignmentCenter];
    
    _rightTimeLabel.font = largeFont;
    _rightTimeLabel.textColor = [UIColor whiteColor];
    _rightTimeLabel.text = @"RIGHT";
    [_rightTimeLabel setTextAlignment:NSTextAlignmentCenter];
    
    _offsetLabel.font = smallFont;
    _offsetLabel.textColor = [UIColor whiteColor];
    _offsetLabel.text = @"OFFSET";
    [_offsetLabel setTextAlignment:NSTextAlignmentCenter];
    
    // update the left, center, and right labels
    [self updateTimeLabels:nil];
    [self updateOffsetLabelToIndex:_currentIndex];
}

- (void)updateOffsetLabelToIndex:(NSInteger)index
{
    NSInteger minuteOffset = [[_timeOffsets objectAtIndex:index] integerValue];
    
    _offsetLabel.text = [NSString stringWithFormat:@"%.1f hrs", minuteOffset/60.0f];
    [self setNewRelativePosition:CGPointMake(0.5f, 0.6f) forObject:_offsetLabel];
}

- (void)updateTimeLabels:(NSTimer *)timer
{
    int leftIndex = _currentIndex-1;
    int centerIndex = _currentIndex;
    int rightIndex = _currentIndex+1;
    
    NSInteger minuteOffset;
    NSDate *currentDateWithOffset;
    
    if (leftIndex >= 0)
    {
        minuteOffset = [[_timeOffsets objectAtIndex:leftIndex] integerValue];
        currentDateWithOffset = [NSDate dateWithTimeIntervalSinceNow:minuteOffset*60];
        _leftTimeLabel.text = [self timestringForDate:currentDateWithOffset];
    }
    else
    {
        _leftTimeLabel.text = @"";
    }
    
    minuteOffset = [[_timeOffsets objectAtIndex:centerIndex] integerValue];
    currentDateWithOffset = [NSDate dateWithTimeIntervalSinceNow:minuteOffset*60];
    _centerTimeLabel.text = [self timestringForDate:currentDateWithOffset];
    
    if (rightIndex < [_timeOffsets count])
    {
        minuteOffset = [[_timeOffsets objectAtIndex:rightIndex] integerValue];
        currentDateWithOffset = [NSDate dateWithTimeIntervalSinceNow:minuteOffset*60];
        _rightTimeLabel.text = [self timestringForDate:currentDateWithOffset];
    }
    else
    {
        _rightTimeLabel.text = @"";
    }
    [self drawNewLerpPosition:0.0f];
}

- (NSString *)timestringForDate:(NSDate*)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"h:mm a"];
    
    return [[df stringFromDate:date] lowercaseString];
}

- (void)update:(NSTimer *)timer
{
    CGFloat delta = PSUEDO_DELTA;
    
    [self updateLerpPosition:delta];
    [self drawNewLerpPosition:delta];
}

- (void)updateLerpPosition:(CGFloat)delta
{
    CGFloat omega = 0.05f;
    
    // if not being touched, normalize to -1, 0, or 1 (whichever one is closest)
    if (!_beingTouched)
    {
        CGFloat vel;
        CGFloat constVel = 3.0f;
        
        if ((_slidingTo == RIGHT || _lerpPosition < -0.5f) && _currentIndex < [_timeOffsets count]-1)
            vel = -constVel;
        else if (_lerpPosition < -omega)
            vel = constVel;
        else if (_lerpPosition >= -omega && _lerpPosition <= omega)
        {
            vel = 0;
            _lerpPosition = 0.0f;
        }
        else if ((_slidingTo == LEFT || _lerpPosition > 0.5f) && _currentIndex > 0)
            vel = constVel;
        else if (_lerpPosition > omega)
            vel = -constVel;
        
        _lerpPosition += delta*vel;
        _lerpPosition = CLAMP(_lerpPosition, -1.0f, 1.0f);
        
        if (fabs(_lerpPosition) >= 1.0f)
        {
            if (_lerpPosition >= 1.0f && _currentIndex > 0)
            {
                _currentIndex--;
                _lerpPosition = 0.0f;
            }
            else if (_lerpPosition <= -1.0f && _currentIndex < [_timeOffsets count]-1)
            {
                _currentIndex++;
                _lerpPosition = 0.0f;
            }
            [self updateTimeLabels:nil];
            [self updateOffsetLabelToIndex:_currentIndex];
            
            _slidingTo = NONE;
        }
    }
}

- (void)drawNewLerpPosition:(CGFloat)delta
{
    CGPoint pos;
    
    pos = CGPointMake(0.0f + (_lerpPosition/2.0f), 0.5f);
    [self setAlphaAndSizeForLabel:_leftTimeLabel withRelativePosition:pos];
    [self setNewRelativePosition:pos forObject:_leftTimeLabel];
    pos = CGPointMake(0.5f + (_lerpPosition/2.0f), 0.5f);
    CGRect frame = _centerTimeLabel.frame;
    [self setAlphaAndSizeForLabel:_centerTimeLabel withRelativePosition:pos];
    [self setNewRelativePosition:pos forObject:_centerTimeLabel];
    pos = CGPointMake(1.0f + (_lerpPosition/2.0f), 0.5f);
    frame = _rightTimeLabel.frame;
    [self setAlphaAndSizeForLabel:_rightTimeLabel withRelativePosition:pos];
    [self setNewRelativePosition:pos forObject:_rightTimeLabel];
    
    NSInteger leftMinutes = [self getMinutesForIndex:_currentIndex-1];
    NSInteger centerMinutes = [self getMinutesForIndex:_currentIndex];
    if (abs(leftMinutes - centerMinutes) > 180) {
        leftMinutes -= 24*60;
    }
    NSInteger rightMinutes = [self getMinutesForIndex:_currentIndex+1];
    if (abs(centerMinutes - rightMinutes) > 180) {
        rightMinutes += 24*60;
    }
    
    NSInteger minutesForLerpPosition;
    NSInteger bottomColorMinute;
    NSInteger topColorMinute;
    if (_lerpPosition >= 0.0f) {
        minutesForLerpPosition = centerMinutes - (centerMinutes - leftMinutes)*_lerpPosition;
    }
    else if (_lerpPosition < 0.0f) {
        minutesForLerpPosition = (rightMinutes - centerMinutes)*(-_lerpPosition) + centerMinutes;
    }
    NSInteger minutesInDay = 24*60;
    
    //NSLog(@"Minute: %ld || lerp_pos:%f", (long)minutesForLerpPosition, _lerpPosition);
    
    bottomColorMinute = minutesForLerpPosition - 30.0f;
    if (bottomColorMinute > minutesInDay) {
        bottomColorMinute %= minutesInDay;
    }
    else if (bottomColorMinute < 0) {
        bottomColorMinute = minutesInDay - bottomColorMinute;
    }
    topColorMinute = minutesForLerpPosition + 30.0f;
    if (topColorMinute > minutesInDay) {
        topColorMinute %= minutesInDay;
    }
    else if (topColorMinute < 0) {
        topColorMinute = minutesInDay - topColorMinute;
    }
    
    UIColor *bottomColor = [self colorForMinuteValue:bottomColorMinute];
    UIColor *topColor = [self colorForMinuteValue:topColorMinute];
    
    [_sunMoonScene updateGradientWithTopColor:topColor andBottomColor:bottomColor];
    [_sunMoonScene updateWithMinute:minutesForLerpPosition];
}

- (NSInteger)getMinutesForIndex:(NSInteger)index
{
    int offset = 0;
    if (index < 0) {
        index = 0;
        offset = -90;
    }
    else if (index >= [_timeOffsets count])
    {
        index = [_timeOffsets count]-1;
        offset = 90;
    }
    
    NSInteger minuteOffset = [[_timeOffsets objectAtIndex:index] integerValue];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:minuteOffset*60];
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date];
    
    NSInteger hour= [components hour];
    NSInteger minute = [components minute];
    
    NSInteger computedMinuteValue = hour*60 + minute + offset;
    
    return computedMinuteValue;
}

- (void)setNewRelativePosition:(CGPoint)pos forObject:(UILabel *)label
{
    CGSize viewSize = self.view.frame.size;
    CGRect labelRect = [label.text
                        boundingRectWithSize:CGSizeMake(270.0f, 270.0f)
                        options:NSStringDrawingUsesLineFragmentOrigin
                        attributes:@{
                                     NSFontAttributeName : label.font
                                     }
                        context:nil];
    label.frame = CGRectMake(pos.x*viewSize.width - labelRect.size.width/2.0f,
                             pos.y*viewSize.height - labelRect.size.height/2.0f,
                             labelRect.size.width,
                             labelRect.size.height);
}

#define MAX_CENTER_SIZE  70.0f
#define MIN_CENTER_SIZE  50.0f

- (void)setAlphaAndSizeForLabel:(UILabel *)label withRelativePosition:(CGPoint)pos
{
    // the closer the x position is to 0.5, the more opaque it is
    label.alpha = 1.0f - CLAMP(fabs(0.5f - pos.x)/0.5f, 0.0f, 1.0f);
    
    // the closer the x position is to 0.5, the larger it is
    CGFloat size = (MAX_CENTER_SIZE - MIN_CENTER_SIZE)*label.alpha + MIN_CENTER_SIZE;
    
    NSString *hourMinuteString = [label.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" ampm"]];
    NSString *amPmString = [label.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" 0123456789:"]];
    
    NSMutableAttributedString *aText = [[NSMutableAttributedString alloc] initWithString:@""];
    [aText appendAttributedString:[[NSAttributedString alloc] initWithString:hourMinuteString attributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Noteworthy" size:size]}]];
    [aText appendAttributedString:[[NSAttributedString alloc] initWithString:amPmString attributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Noteworthy" size:size-40.0f]}]];
    
    label.attributedText = aText;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TOUCH HANDLING

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _beingTouched = true;
    for (UITouch *touch in touches)
    {
        _startingTouchPosition = [touch locationInView:self.view];
        _startingTouchTime = CACurrentMediaTime();
        _grabbedLerpPosition = _lerpPosition;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint loc = [touch locationInView:self.view];
        
        CGFloat xDiff = loc.x - _startingTouchPosition.x;
        CGFloat interpolatedDiff = CLAMP(xDiff / (0.55f*[self.view frame].size.width), -1.0f, 1.0f);
        
        if (interpolatedDiff > 0 && _currentIndex == 0)
            interpolatedDiff /= 2.5f;
        else if (interpolatedDiff < 0 && _currentIndex == [_timeOffsets count]-1)
            interpolatedDiff /= 2.5f;
        
        _lerpPosition = _grabbedLerpPosition + interpolatedDiff;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in touches)
    {
        CGPoint loc = [touch locationInView:self.view];
        
        CGFloat xVelocity = (loc.x - _startingTouchPosition.x)/(CACurrentMediaTime()-_startingTouchTime);
        
        CGFloat cutoff = self.view.frame.size.width*1.6f;
        
        if (xVelocity > cutoff) {
            _slidingTo = LEFT;
        }
        else if (xVelocity < -cutoff) {
            _slidingTo = RIGHT;
        }
    }
    
    _beingTouched = false;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    _beingTouched = false;
}

@end
