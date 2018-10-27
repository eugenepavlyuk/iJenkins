//
//  UIImage+ImageWithColor.h
//  TeamApp
//
//  Created by Eugene Pavluk on 4/30/14.
//  Copyright (c) 2014 Eugene Pavlyuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageWithColor)

+ (UIImage *)resizeableImageWithColor:(UIColor *)color;
- (UIImage *)changeColorFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor;

@end
