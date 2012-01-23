#import "TCCircleMenu.h"
#import "SPKVONotificationCenter.h"
#import "SPLowVerbosity.h"
#import "SPFunctional.h"
#import "SPDepends.h"
#import <QuartzCore/QuartzCore.h>

@interface TCCircleMenu ()
@property(nonatomic,assign) TCCircleMenu *parent; // root menu if nil
@property(nonatomic,retain) UIView *touchInterceptorView;
@property(nonatomic,retain) UITapGestureRecognizer *touchInterceptorGrec;
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
@property(nonatomic,readonly) UIBezierPath *pathBounds;
@end

@implementation TCCircleMenu {
    NSMutableArray *_menuItems;
}
@synthesize subMenu = _subMenu;
@synthesize parent = _parent;
@synthesize itemsObs = _itemsObs;
@synthesize touchInterceptorView = _touchInterceptorView;
@synthesize touchInterceptorGrec = _touchInterceptorGrec;
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
		for(TCCircleMenuItem *removed in [how objectForKey:NSKeyValueChangeOldKey])
			[removed removeFromSuperview];
		for(TCCircleMenuItem *added in [how objectForKey:NSKeyValueChangeNewKey])
			[selff addSubview:added]; 
		
        CGPoint p = selff.layer.position;
        //CGFloat ri = [selff innerRadius];
        CGFloat ro = [selff outerRadius];
        CGFloat ic = [self innerCircumference];
        selff.frame = CGRectMake(0, 0, ro*2 + 2, ro*2 + 2);
        selff.layer.position = p;

        #define angleWidthForSegment(x) (([x bodySize].width/ic)*M_PI*2)
        CGFloat anglePen = -M_PI/2 - angleWidthForSegment([selff->_menuItems objectAtIndex:0])/2;        

        for(TCCircleMenuItem *item in selff->_menuItems) {
            item.frame = selff.bounds;
            
            item.startAngle = anglePen;
            anglePen += angleWidthForSegment(item);
            item.endAngle = anglePen;
        }
        
        [selff setNeedsDisplay];
    }];
    
    return self;
}
-(void)dealloc;
{
    [_menuItems release]; _menuItems = nil;
    [_itemsObs invalidate]; self.itemsObs = nil;
	[_touchInterceptorView removeFromSuperview]; self.touchInterceptorView = nil;
	self.touchInterceptorGrec = nil;
    [super dealloc];
}

#pragma mark Prettiness
-(void)drawRect:(CGRect)rect;
{
    [[UIColor clearColor] set];
    UIRectFill(rect);
    
    for(TCCircleMenuItem *item in _menuItems) {
		[[UIColor colorWithHue:[_menuItems indexOfObject:item]/(float)_menuItems.count saturation:1 brightness:1 alpha:.5] set];
        [item.pathBounds fill];
        
    }
}

#pragma mark Touch


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
	
	if(!_parent) {
		UIWindow *window = view.window;
		self.touchInterceptorView = [[[UIView alloc] initWithFrame:window.bounds] autorelease];
		[window insertSubview:_touchInterceptorView belowSubview:self];
		self.touchInterceptorGrec = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)] autorelease];
		[_touchInterceptorView addGestureRecognizer:_touchInterceptorGrec];
	}
}
-(void)backgroundTap:(UITapGestureRecognizer*)grec;
{
	if(grec.state == UIGestureRecognizerStateRecognized)
		[self dismiss];
}
-(void)dismiss;
{
	[UIView animateWithDuration:.3 delay:0 options:UIViewAnimationCurveEaseIn animations:^{
		self.alpha = 0;
		self.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI/4), 1.4, 1.4);
	} completion:^(BOOL finished) {
		[self removeFromSuperview];
	}];
	
	[_touchInterceptorView removeFromSuperview]; self.touchInterceptorView = nil;
	self.touchInterceptorGrec = nil;
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
@synthesize pathBounds = _pathBounds;
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
	
	$depends(@"angles", self, @"startAngle", @"endAngle", (id)^{
		[selff->_pathBounds release]; selff->_pathBounds = nil;
	}, nil);
	
    return self;
}
- (void)dealloc;
{
    self.title = nil;
    self.action = nil;
    self.font = nil;
	[_pathBounds release];
    [super dealloc];
}

-(UIBezierPath*)pathBounds;
{
	if(_pathBounds) return _pathBounds;
	
	TCCircleMenu *menu = $cast(TCCircleMenu, [self superview]);
	
    CGPoint mid = CGPointMake(menu.frame.size.width/2, menu.frame.size.height/2);
	
	UIBezierPath *outer = [UIBezierPath bezierPathWithArcCenter:mid radius:[menu outerRadius] startAngle:self.startAngle endAngle:self.endAngle clockwise:YES];
	UIBezierPath *inner = [UIBezierPath bezierPathWithArcCenter:mid radius:[menu innerRadius] startAngle:self.endAngle endAngle:self.startAngle clockwise:NO];
	
	UIBezierPath *semicircle = [UIBezierPath bezierPath];
	[semicircle appendPath:outer];
	[semicircle addLineToPoint:CGPointMake(mid.x + cos(self.endAngle)*menu.innerRadius, mid.y + sin(self.endAngle)*menu.innerRadius)];
	[semicircle appendPath:inner];
	[semicircle addLineToPoint:CGPointMake(mid.x + cos(self.startAngle)*menu.outerRadius, mid.y + sin(self.startAngle)*menu.outerRadius)];
	
	_pathBounds = [semicircle retain];
	return _pathBounds;
}
-(void)setTitle:(NSString *)title;
{
    [_title autorelease];
    _title = [title retain];
    
    CGSize sz = [_title sizeWithFont:_font];
    sz.width += 10*2;
    sz.height += 15*2;
    self.bodySize = sz;
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
{
	return [self.pathBounds containsPoint:point];
}
@end
