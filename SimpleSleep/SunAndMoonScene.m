//
//  SunAndMoonScene.m
//  SimpleSleep
//
//  Created by Darren Tsung on 10/24/14.
//  Copyright (c) 2014 self.edu. All rights reserved.
//

#import "SunAndMoonScene.h"

@implementation SunAndMoonScene
{
    SKSpriteNode *sun, *moon, *gradientNode;
}

- (id)initWithSize:(CGSize)size
{
    self = [super initWithSize:size];
    if (!self) return nil;
    
    // create sun
    sun = [SKSpriteNode spriteNodeWithImageNamed:@"sun.png"];
    [self setRelativePosition:CGPointMake(0.5f, 0.5f) forSpriteNode:sun];
    sun.alpha = 0.7f;
    [self addChild:sun];
    
    // create moon
    moon = [SKSpriteNode spriteNodeWithImageNamed:@"moon.png"];
    [self setRelativePosition:CGPointMake(0.5f, 0.5f) forSpriteNode:moon];
    moon.alpha = 0.7f;
    [self addChild:moon];
    
    gradientNode = [SKSpriteNode spriteNodeWithColor:[UIColor blackColor] size:size];
    [self setRelativePosition:CGPointMake(0.5f, 0.5f) forSpriteNode:gradientNode];
    gradientNode.zPosition = -10;
    [self addChild:gradientNode];
    
    // create stars
    
    return self;
}

- (void)setRelativePosition:(CGPoint)pos forSpriteNode:(SKSpriteNode *)node
{
    [node setPosition:CGPointMake(pos.x*self.size.width, pos.y*self.size.height)];
}

- (void)updateWithMinute:(NSInteger)minuteValue
{
    // within 7 AM or 7 PM
    if (minuteValue >= 7*60 && minuteValue <= 19*60)
    {
        CGFloat lerpedValue = ((CGFloat)minuteValue - (13.0f*60.0f))/(6.0f*60.0f);
        
        CGFloat x = (lerpedValue + 1.0f)/2.0f;
        CGFloat y = 1.0f - (lerpedValue*lerpedValue + 0.2);
        
        //NSLog(@"With minuteValue:%d, sun is at (%f, %f)", minuteValue, x, y);
        
        [self setRelativePosition:CGPointMake(x, y) forSpriteNode:sun];
    }
    else
    {
        [self setRelativePosition:CGPointMake(-2.0f, -2.0f) forSpriteNode:sun];
    }
    
    
    // within 10 PM - 5 AM
    NSInteger moonMinuteValue = minuteValue;
    if (minuteValue >= 22*60) {
        moonMinuteValue -= 24*60;
    }
    if (moonMinuteValue >= -2*60 && moonMinuteValue <= 5*60)
    {
        CGFloat lerpedValue = ((CGFloat)moonMinuteValue - (1.5f*60.0f))/(3.5f*60.0f);
        
        CGFloat x = (lerpedValue + 1.0f)/2.0f;
        CGFloat y = 1.0f - (lerpedValue*lerpedValue + 0.2);
        
        //NSLog(@"With minuteValue:%d, sun is at (%f, %f)", minuteValue, x, y);
        
        [self setRelativePosition:CGPointMake(x, y) forSpriteNode:moon];
    }
    else
    {
        [self setRelativePosition:CGPointMake(-2.0f, -2.0f) forSpriteNode:moon];
    }
}

- (void)updateGradientWithTopColor:(UIColor *)topColor andBottomColor:(UIColor *)bottomColor {
    UIGraphicsBeginImageContext(self.size);       //For landscape mode.
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGGradientRef gradient;

    CGColorSpaceRef colorSpace;

    CGFloat location[] = {1};

    UIColor *colorOne = bottomColor;
    UIColor *colorTwo = topColor;

    NSArray *color = [NSArray arrayWithObjects:(id)colorTwo.CGColor,
                      (id)colorOne.CGColor, nil];

    colorSpace = CGColorSpaceCreateDeviceRGB();

    gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef) color, location);

    CGPoint startPoint, endPoint;
    startPoint.x = self.size.width/2.0f;
    startPoint.y = 0;

    endPoint.x = self.size.width/2.0f;
    endPoint.y = self.size.height;

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsAfterEndLocation);

    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);

    UIImage *newimage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    SKTexture *newte = [SKTexture textureWithImage:newimage];
    
    newte.filteringMode = SKTextureFilteringNearest;
    
    gradientNode.texture = newte;
}


@end
