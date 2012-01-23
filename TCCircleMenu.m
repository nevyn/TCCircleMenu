#import "TCCircleMenu.h"
#import "SPKVONotificationCenter.h"
#import "SPLowVerbosity.h"
#import "SPFunctional.h"
#import "SPDepends.h"
#import <QuartzCore/QuartzCore.h>
#import "ZCCurvedText.h"

@interface TCCircleMenu () <UIGestureRecognizerDelegate>
@property(nonatomic,assign) TCCircleMenu *parent; // root menu if nil
@property(nonatomic,retain) UIView *touchInterceptorView;
@property(nonatomic,retain,readwrite) TCCircleMenu *subMenu;
@property(nonatomic,retain) TCCircleMenuItem *submenuItem;
@property(nonatomic,retain) UITapGestureRecognizer *touchInterceptorGrec;
-(CGFloat)innerCircumference;
-(CGFloat)innerRadius;
-(CGFloat)outerRadius;
-(void)updateAngles;

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
@synthesize submenuItem = _submenuItem;
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
		
        [selff updateAngles];
    }];
    $depends(@"parent", self, @"parent", (id)^{
        [selff updateAngles];
    });
    
    return self;
}
-(void)dealloc;
{
    [_menuItems release]; _menuItems = nil;
    [_itemsObs invalidate]; self.itemsObs = nil;
	[_touchInterceptorView removeFromSuperview]; self.touchInterceptorView = nil;
    [self dismissSubmenu];
    self.subMenu = nil;
	self.touchInterceptorGrec = nil;
    [super dealloc];
}

#pragma mark Prettiness
-(void)drawRect:(CGRect)rect;
{
    [[UIColor clearColor] set];
    UIRectFill(rect);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat midRadius = (self.innerRadius + self.outerRadius)/2.;
    CGPoint mid = CGPointMake(self.frame.size.width/2., self.frame.size.height/2.);
    
    for(TCCircleMenuItem *item in _menuItems) {
		[[UIColor colorWithHue:[_menuItems indexOfObject:item]/(float)_menuItems.count saturation:.6 brightness:1 alpha:.8] set];
        [item.pathBounds fill];
        
        CGFloat midAngle = (item.startAngle + item.endAngle)/2.;
        
        [[UIColor blackColor] set];
        
        CGContextSaveGState(ctx);
        CGContextTranslateCTM(ctx, mid.x, mid.y);
        CGContextRotateCTM(ctx, midAngle);
        if(midAngle > 0 && midAngle < M_PI) // Turn upside-down
            CGContextSetTextMatrix(ctx, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
        else {
            //CGContextSetTextMatrix(ctx, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
            CGContextScaleCTM(ctx, 1, -1);
            //CGContextSetTextMatrix(ctx, CGAffineTransformScale(CGAffineTransformIdentity, -1, -1));
        }
        [ZCCurvedText drawCurvedText:item.title inContext:ctx atAngle:0 radius:midRadius font:item.font];
        CGContextRestoreGState(ctx);
    }
}

#pragma mark Touch
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
    // Touched inside the circle
    TCCircleMenu *menu = self.subMenu;
    do {} while(menu.subMenu && (menu = menu.subMenu));
    if(menu)
        [menu.parent dismissSubmenu];
    else
        [self dismiss];
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
{
    if(!_parent)
        return [super pointInside:point withEvent:event];
    else return [[_menuItems sp_collect:$num(0) with:^id(id sum, id obj) {
        return $num([sum boolValue] || [obj pointInside:point withEvent:event]);
    }] boolValue];
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

-(void)updateAngles;
{
    if(_menuItems.count == 0) return;
    
    CGPoint p = self.layer.position;
    //CGFloat ri = [self innerRadius];
    CGFloat ro = [self outerRadius];
    CGFloat ic = [self innerCircumference];
    self.frame = CGRectMake(0, 0, ro*2 + 2, ro*2 + 2);
    self.layer.position = p;

    #define angleWidthForSegment(x) (([x bodySize].width/ic)*M_PI*2)
    CGFloat anglePen = -M_PI/2 - angleWidthForSegment([_menuItems objectAtIndex:0])/2;        

    for(TCCircleMenuItem *item in _menuItems) {
        item.frame = self.bounds;
        
        item.startAngle = anglePen;
        anglePen += angleWidthForSegment(item);
        item.endAngle = anglePen;
    }
    
    [self setNeedsDisplay];
}



#pragma mark Presentation
-(void)presentAt:(CGPoint)p inView:(UIView*)view;
{
    self.layer.position = p;
    self.alpha = 0;
    self.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(-M_PI/4), .6, .6);
    
    if(_parent)
        [view insertSubview:self belowSubview:_parent];
    else
        [view addSubview:self];
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 1;
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
    
	if(!_parent) {
		self.touchInterceptorView = [[[UIView alloc] initWithFrame:view.bounds] autorelease];
		[view insertSubview:_touchInterceptorView belowSubview:self];
		self.touchInterceptorGrec = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)] autorelease];
        _touchInterceptorGrec.delegate = self;
		[_touchInterceptorView addGestureRecognizer:_touchInterceptorGrec];
	}
	
}
-(void)backgroundTap:(UITapGestureRecognizer*)grec;
{
	if(grec.state == UIGestureRecognizerStateRecognized)
		[self dismiss];
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
{
    if([touch.view isDescendantOfView:self])
        return NO;
    return YES;
}
-(void)dismiss;
{
    [self dismissSubmenu];
	[UIView animateWithDuration:.3 delay:0 options:UIViewAnimationCurveEaseIn animations:^{
		self.alpha = 0;
        self.transform = CGAffineTransformScale(CGAffineTransformMakeRotation(M_PI/4), .6, .6);
	} completion:^(BOOL finished) {
		[self removeFromSuperview];
	}];
	
	[_touchInterceptorView removeFromSuperview]; self.touchInterceptorView = nil;
	self.touchInterceptorGrec = nil;
}


#pragma mark Submenus
-(void)presentSubmenu:(TCCircleMenu*)menu fromItem:(TCCircleMenuItem*)item;
{
    menu.parent = self;
    self.subMenu = menu;
    [menu presentAt:self.layer.position inView:self.superview];
    
    item.selected = YES;
    self.submenuItem = item;
}
-(void)dismissSubmenu;
{
    self.submenuItem.selected = NO;
    self.submenuItem = nil;
    [self.subMenu dismiss];
    self.subMenu = nil;
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
	});
    
    [self addTarget:self action:@selector(touched) forControlEvents:UIControlEventTouchUpInside];
	
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

-(void)touched;
{
    if(self.action)
        self.action(self);
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
