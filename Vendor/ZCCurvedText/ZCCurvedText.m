//
//  ZCCurvedText.m
//  Gridlike
//
//  Created by Amanda Rösler on 2011-01-11.
//  Copyright 2011 Zombie Cat Software. All rights reserved.
//

#import "ZCCurvedText.h"

@implementation ZCCurvedText

+ (void)drawCurvedText:(NSString*)text
             inContext:(CGContextRef)context
               atAngle:(float)angle
                radius:(float)radius
                  font:(UIFont*)font;
{
    char* fontName = (char*)[font.fontName cStringUsingEncoding:NSMacOSRomanStringEncoding];
    CGContextSelectFont(context, fontName, font.pointSize, kCGEncodingMacRoman);
    
    CGSize textSize = [text sizeWithFont:font];
	
    float perimeter = 2 * M_PI * radius;
    float textAngle = textSize.width / perimeter * 2 * M_PI;
	
	angle += textAngle / 2;
	
	NSRange aRange = {0, 1};
	NSString* firstLetter = [text substringWithRange:aRange];     
	CGSize firstCharSize = [firstLetter sizeWithFont:font];
	float firstLetterAngle = (firstCharSize.width / perimeter * -2 * M_PI);
	
	angle -= (firstLetterAngle/2);
	
    for (int index = 0; index < [text length]; index++)
    {
        NSRange range = {index, 1};
        NSString* letter = [text substringWithRange:range];     
        char* c = (char*)[letter cStringUsingEncoding:NSASCIIStringEncoding];
        CGSize charSize = [letter sizeWithFont:font];
		
        float letterAngle = (charSize.width / perimeter * -2 * M_PI);	
		
		angle += letterAngle/2;
		
		float x = radius * cos(angle-(letterAngle/2));
        float y = radius * sin(angle-(letterAngle/2));
		
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, x, y);
		CGContextRotateCTM(context, (angle - 0.5 * M_PI));
        CGContextShowTextAtPoint(context, 0, 0, c, strlen(c));
        CGContextRestoreGState(context);
		
		angle += letterAngle/2;
    }
}

+ (UIImage*)imageWithCurvedText:(NSString*)text
                        inColor:(UIColor*)color
                        atAngle:(float)angle 
                         radius:(float)radius
                           font:(UIFont*)font
                        inFrame:(CGRect)frame;
{
    CGPoint centerPoint = CGPointMake(frame.size.width / 2, frame.size.height / 2);
		
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, frame.size.width, frame.size.height, 8, 4 * frame.size.width, colorSpace, kCGImageAlphaPremultipliedFirst);
	
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	
    CGContextSetFillColorWithColor(context, color.CGColor);
	
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, centerPoint.x, centerPoint.y);
	
	[self drawCurvedText:text inContext:context atAngle:angle radius:radius font:font];
	
    CGContextRestoreGState(context);
	
    CGImageRef contextImage = CGBitmapContextCreateImage(context);
	
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
	
	UIImage* finalImage = [UIImage imageWithCGImage:contextImage];
	CGImageRelease(contextImage);
	
    return finalImage;
	
}

@end
