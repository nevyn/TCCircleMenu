#import "TCCircleMenu.h"
#import "SPKVONotificationCenter.h"
#import "SPLowVerbosity.h"
#import "SPFunctional.h"
#import <QuartzCore/QuartzCore.h>

@interface TCCircleMenu ()
@property(nonatomic,assign) TCCircleMenu *parent; // root menu if nil
-(CGFloat)innerCircumference;
-(CGFloat)innerRadius;
-(CGFloat)outerRadius;

@property(nonatomic,retain) SPKVObservation *itemsObs;
@end
@interface TCCircleMenuItem ()
@property(nonatomic,assign) TCCircleMenu *parent;
@property(nonatomic) CGSize bodySize;
@property(nonatomic,retain) UIFont *font;
@property(nonatomic) CGFloat startAngle, endAngle;
@end

@implementation TCCircleMenu {
    NSMutableArray *_menuItems;
}
@synthesize subMenu = _subMenu;
@synthesize parent = _parent;
@synthesize itemsObs = _itemsObs;
@dynamic menuItems;
- (id)init; { return [self initWithFrame:CGRectZero]; }
- (id)initWithFrame:(CGRect)frame;
{
    if(!(self = [super initWithFrame:frame])) return nil;
    
    _menuItems = [NSMutableArray new];
    
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    
    self.contentMode = UIViewContentModeRedraw;
    
    __typeof(self) selff = self;
    self.itemsObs = [self sp_addObserver:self forKeyPath:@"menuItems" options:NSKeyValueObservingOptionNew callback:^(NSDictionary *how, id object, NSString *keyPath) {
            
        CGPoint p = selff.layer.position;
        //CGFloat ri = [selff innerRadius];
        CGFloat ro = [selff outerRadius];
        CGFloat ic = [self innerCircumference];
        selff.frame = CGRectMake(0, 0, ro*2 + 2, ro*2 + 2);
        selff.layer.position = p;

        CGFloat c = [selff->_menuItems count];        
        #define angleWidthForSegment(x) (([x bodySize].width/ic)*M_PI*2)
        CGFloat anglePen = -M_PI/2 - angleWidthForSegment([selff->_menuItems objectAtIndex:0])/2;
        

        for(TCCircleMenuItem *item in selff->_menuItems) {
            item.frame = CGRectMake(0, 0, item.bodySize.width, ro);
            
            item.startAngle = anglePen;
            anglePen += angleWidthForSegment(item);
            item.endAngle = anglePen;
                                    
            item.backgroundColor = [UIColor colorWithHue:[selff->_menuItems indexOfObject:item]/c saturation:1 brightness:1 alpha:.5];
        }
        
        [selff setNeedsDisplay];
    }];
    
    return self;
}
-(void)dealloc;
{
    [_menuItems release]; _menuItems = nil;
    [_itemsObs invalidate]; self.itemsObs = nil;
    [super dealloc];
}

#pragma mark Prettiness
-(void)drawRect:(CGRect)rect;
{
    [[UIColor clearColor] set];
    UIRectFill(rect);
    
    
    CGPoint mid = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    for(TCCircleMenuItem *item in _menuItems) {
        UIBezierPath *outer = [UIBezierPath bezierPathWithArcCenter:mid radius:[self outerRadius] startAngle:item.startAngle endAngle:item.endAngle clockwise:YES];
        UIBezierPath *inner = [UIBezierPath bezierPathWithArcCenter:mid radius:[self innerRadius] startAngle:item.endAngle endAngle:item.startAngle clockwise:NO];
        
        [[UIColor greenColor] set];
        [outer stroke];
        [[UIColor blueColor] set];
        [inner stroke];
        
        UIBezierPath *semicircle = [UIBezierPath bezierPath];
        [semicircle appendPath:outer];
        [semicircle addLineToPoint:CGPointMake(mid.x + cos(item.endAngle)*self.innerRadius, mid.y + sin(item.endAngle)*self.innerRadius)];
        [semicircle appendPath:inner];
        [semicircle addLineToPoint:CGPointMake(mid.x + cos(item.startAngle)*self.outerRadius, mid.y + sin(item.startAngle)*self.outerRadius)];
        [item.backgroundColor set];
        [semicircle fill];
        
    }
    
}


#pragma mark Circle math
-(CGFloat)innerCircumference;
{
    return [[_menuItems sp_collect:$numf(0) with:^id(id sum, id obj) {
        return $numf([sum doubleValue] + [obj bodySize].width);
    }] doubleValue];
}
-(CGFloat)innerRadius;
{
    if(_parent) return [_parent outerRadius];
    
    CGFloat innerCircumference = [self innerCircumference];
    CGFloat innerRadius = innerCircumference/(2*M_PI);
    
    return innerRadius;
    
}
-(CGFloat)outerRadius;
{
    return [self innerRadius] + [[_menuItems lastObject] bodySize].height;
}


#pragma mark Presentation
-(void)presentAt:(CGPoint)p inView:(UIView*)view;
{
    self.layer.position = p;
    self.alpha = 0;
    self.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI/4), .6, .6);
    [view addSubview:self];
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}
-(void)dismiss;
{

}


#pragma mark Submenus
-(void)presentSubmenu:(TCCircleMenu*)menu fromItem:(TCCircleMenuItem*)item;
{
    if(_parent)
        return [_parent presentSubmenu:menu fromItem:item];
    
}
-(void)dismissSubmenu;
{

}


#pragma mark KVO to-many hack

-(NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
	if (sel == @selector(menuItems)) {
		return [super methodSignatureForSelector:@selector(mutableArrayValueForKey:)];
	} else {
		return [super methodSignatureForSelector:sel];
	}
}
-(BOOL)respondsToSelector:(SEL)sel;
{
	if (sel == @selector(menuItems))
        return YES;
    return [super respondsToSelector:sel];
}

-(void)forwardInvocation:(NSInvocation *)invocation {
	NSString *selName = NSStringFromSelector(invocation.selector);
	if (invocation.selector == @selector(menuItems)) {
		id value = [self mutableArrayValueForKey:selName];
		[invocation setReturnValue:&value];
	} else
        [super forwardInvocation:invocation];
}

@end



@implementation TCCircleMenuItem
@synthesize title = _title;
@synthesize action = _action;
@synthesize parent = _parent;
@synthesize font = _font;
@synthesize bodySize = _bodySize;
@synthesize startAngle = _startAngle, endAngle = _endAngle;
+ (TCCircleMenuItem*)itemNamed:(NSString*)name whenTapped:(void(^)(TCCircleMenuItem *sender))block;
{
    return [[[TCCircleMenuItem alloc] initNamed:name whenTapped:block] autorelease];
}
-(id)initNamed:(NSString*)name whenTapped:(void(^)(TCCircleMenuItem *sender))block;
{
    if(!(self = [super initWithFrame:CGRectZero])) return nil;
    self.font = [UIFont boldSystemFontOfSize:14];
    self.title = name;
    self.action = block;
    return self;
}
- (void)dealloc;
{
    self.title = nil;
    self.action = nil;
    self.font = nil;
    [super dealloc];
}
-(void)setTitle:(NSString *)title;
{
    [_title autorelease];
    _title = [title retain];
    
    CGSize sz = [_title sizeWithFont:_font];
    sz.width += 10*2;
    sz.height += 15*2;
    self.bodySize = sz;
    
    [[self subviews] valueForKey:@"removeFromSuperview"];
    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    l.opaque = NO; l.backgroundColor = [UIColor clearColor];
    l.text = title;
    l.textAlignment = UITextAlignmentCenter;
    l.font = _font;
    l.frame = (CGRect){.size = sz};
    l.textColor = [UIColor blackColor];
    [self addSubview:l];
}
@end
