//
//  ZCCurvedText.h
//  Gridlike
//
//  Created by Amanda Rösler on 2011-01-11.
//  Copyright 2011 Zombie Cat Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ZCCurvedText : NSObject
+ (void)drawCurvedText:(NSString*)text
             inContext:(CGContextRef)context
               atAngle:(float)angle
                radius:(float)radius
                  font:(UIFont*)font;

+ (UIImage*)imageWithCurvedText:(NSString*)text
                        inColor:(UIColor*)color
                        atAngle:(float)angle 
                         radius:(float)radius
                           font:(UIFont*)font
                        inFrame:(CGRect)frame;

@end
