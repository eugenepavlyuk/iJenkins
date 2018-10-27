//
//  UIImage+ImageWithColor.m
//  TeamApp
//
//  Created by Eugene Pavluk on 4/30/14.
//  Copyright (c) 2014 Eugene Pavlyuk. All rights reserved.
//

#import "UIImage+ImageWithColor.h"

@implementation UIImage (ImageWithColor)

+ (UIImage *)resizeableImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 3.0f, 3.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(1, 1, 1, 1)];

    return image;
}

- (UIImage *)changeColorFromColor:(UIColor *)fromColor toColor:(UIColor *)toColor {
    CGImageRef originalImage = [self CGImage];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = NULL;
    //(unsigned char *)calloc(CGImageGetHeight(originalImage) * CGImageGetWidth(originalImage) * 4, sizeof(unsigned char));
    CGContextRef bitmapContext =
        CGBitmapContextCreate(rawData, CGImageGetWidth(originalImage), CGImageGetHeight(originalImage), 8, CGImageGetWidth(originalImage) * 4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGBitmapContextGetWidth(bitmapContext), CGBitmapContextGetHeight(bitmapContext)), originalImage);
    rawData = CGBitmapContextGetData(bitmapContext);
    int numComponents = 4;
    NSInteger bytesInContext = CGBitmapContextGetHeight(bitmapContext) * CGBitmapContextGetBytesPerRow(bitmapContext);
    double redIn, greenIn, blueIn, alphaIn;
    CGFloat fromRed = 0.0, fromGreen = 0.0, fromBlue = 0.0, fromAlpha;
    CGFloat toRed = 0.0, toGreen = 0.0, toBlue = 0.0, toAlpha = 0.0;

    // Get RGB values of fromColor
    size_t fromCountComponents = CGColorGetNumberOfComponents([fromColor CGColor]);
    if (fromCountComponents == 4) {
        const CGFloat *_components = CGColorGetComponents([fromColor CGColor]);
        fromRed = _components[0] * 255;
        fromGreen = _components[1] * 255;
        fromBlue = _components[2] * 255;
        fromAlpha = _components[3] * 255;
    }

    // Get RGB values for toColor
    size_t toCountComponents = CGColorGetNumberOfComponents([toColor CGColor]);
    if (toCountComponents == 4) {
        const CGFloat *_components = CGColorGetComponents([toColor CGColor]);
        toRed = _components[0] * 255;
        toGreen = _components[1] * 255;
        toBlue = _components[2] * 255;
        toAlpha = _components[3] * 255;
    }

    // Now iterate through each pixel in the image..
    for (NSInteger i = 0; i < bytesInContext; i += numComponents) {
        // rgba value of current pixel..
        redIn = (double)rawData[i];
        greenIn = (double)rawData[i + 1];
        blueIn = (double)rawData[i + 2];
        alphaIn = (double)rawData[i + 3];
        // now you got current pixel rgb values...check it curresponds with your fromColor

        if (redIn == fromRed && greenIn == fromGreen && blueIn == fromBlue) {
            // image color matches fromColor, then change current pixel color to toColor
            rawData[i] = toRed;
            rawData[i + 1] = toGreen;
            rawData[i + 2] = toBlue;
            rawData[i + 3] = toAlpha;
        }
    }
    CGImageRef outImage = CGBitmapContextCreateImage(bitmapContext);
    UIImage *myImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    // free(rawData);
    return myImage;
}

@end
