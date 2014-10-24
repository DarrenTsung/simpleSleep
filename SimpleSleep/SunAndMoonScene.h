//
//  SunAndMoonScene.h
//  SimpleSleep
//
//  Created by Darren Tsung on 10/24/14.
//  Copyright (c) 2014 self.edu. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SunAndMoonScene : SKScene

- (void)updateWithMinute:(NSInteger)minuteValue;
- (void)updateGradientWithTopColor:(UIColor *)topColor andBottomColor:(UIColor *)bottomColor;

@end
