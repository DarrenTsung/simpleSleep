//
//  ViewController.m
//  SimpleSleep
//
//  Created by Darren Tsung on 10/22/14.
//  Copyright (c) 2014 self.edu. All rights reserved.
//

#import "ViewController.h"

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

@property (strong, readwrite) UIView *sun;

@property (assign, readwrite) bool beingTouched;
@property (assign, readwrite) SlidingToType slidingTo;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _lerpPosition = 0.0f;
    _slidingTo = NONE;
    
    [self scheduleUpdates];
    [self createSun];
    [self createGradientBackground];
    [self createTimeOffsetArray];
    [self createTimeLabels];
}

- (void)scheduleUpdates
{
   _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimeLabels:) userInfo:nil repeats:YES];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:PSUEDO_DELTA target:self selector:@selector(update:) userInfo:nil repeats:YES];
}

- (void)createGradientBackground
{
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    NSArray *colors = [NSArray arrayWithObjects:
                       (id)[[UIColor colorWithRed:215.0f/255.0f green:168.0f/255.0f blue:55.0f/255.0f alpha:1.0f] CGColor],
                       (id)[[UIColor colorWithRed:237.0f/255.0f green:214.0f/255.0f blue:159.0f/255.0f alpha:1.0f] CGColor],
                       nil];
    [gradientLayer setColors:colors];
    
    [gradientLayer setStartPoint:CGPointMake(0.0f, 0.0f)];
    [gradientLayer setEndPoint:CGPointMake(0.0f, 1.0f)];
    
    gradientLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [[[self view] layer] insertSublayer:gradientLayer atIndex:0];
}

- (void)createTimeOffsetArray
{
    _timeOffsets = [NSMutableArray array];
    for (int i=1; i<9; i++) {
        NSNumber *offset = [NSNumber numberWithInt:AVERAGE_FALL_ASLEEP_TIME + SLEEPING_CYCLE_TIME*i];
        [_timeOffsets addObject:offset];
    }
}

- (void)createSun
{
    int diameter = 100;
    
    _sun = [[UIView alloc] initWithFrame:CGRectMake(0,0,diameter,diameter)];
    
    CGPoint pos = CGPointMake(0.5f, 0.43f);
    [self moveSunToRelativePosition:pos];
    
    _sun.alpha = 1.0f;
    _sun.layer.cornerRadius = diameter/2.0f;
    _sun.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:221.0f/255.0f blue:34.0f/255.0f alpha:1.0f];
    
    [self.view insertSubview:_sun atIndex:0];
}

- (void)moveSunToRelativePosition:(CGPoint)position
{
    CGSize viewSize = self.view.frame.size;
    
    _sun.frame = CGRectMake(position.x*viewSize.width - _sun.frame.size.width/2.0f,
                            position.y*viewSize.height - _sun.frame.size.height/2.0f,
                            _sun.frame.size.width,
                            _sun.frame.size.height);
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
        CGFloat constVel = 4.0f;
        
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
        
        NSLog(@"xVelocity is: %f || cutoff is: %f", xVelocity, cutoff);
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
