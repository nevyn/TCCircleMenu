#import "TCAppDelegate.h"
#import "TCCircleMenu.h"

@interface TCAppDelegate () <UIGestureRecognizerDelegate>
@end

@implementation TCAppDelegate
@synthesize window = _window;

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    [self.window makeKeyAndVisible];
	
	UIView *rootView = [[[UIView alloc] initWithFrame:self.window.bounds] autorelease];
    rootView.backgroundColor = [UIColor whiteColor];
	[self.window addSubview:rootView];
    
    UITapGestureRecognizer *grec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(grec:)];
    grec.delegate = self;
    [rootView addGestureRecognizer:grec];
    
    return YES;
}
-(void)grec:(UITapGestureRecognizer*)grec;
{
    if(grec.state == UIGestureRecognizerStateRecognized) {
        CGPoint p = [grec locationInView:nil];
        TCCircleMenu *menu = [TCCircleMenu new];
        __block TCCircleMenu *weakMenu = menu;
        
        [menu.menuItems setArray:[NSArray arrayWithObjects:
            [TCCircleMenuItem itemNamed:@"a first button" whenTapped:^(TCCircleMenuItem *sender){
                NSLog(@"Testing 123!");
            }],
            [TCCircleMenuItem itemNamed:@"b! opens menu" whenTapped:^(TCCircleMenuItem *sender){
                TCCircleMenu *subMenu = [TCCircleMenu new];
                [subMenu.menuItems setArray:[NSArray arrayWithObjects:
                    [TCCircleMenuItem itemNamed:@"Sub 1 omg omg om gom g" whenTapped:^(TCCircleMenuItem *sender){
                        NSLog(@"Sub 1!");
                    }],
                    [TCCircleMenuItem itemNamed:@"Go back" whenTapped:^(TCCircleMenuItem *sender){
                        [weakMenu dismissSubmenu];
                    }],
                nil]];
                [weakMenu presentSubmenu:subMenu fromItem:sender];
            }],
            [TCCircleMenuItem itemNamed:@"c third button" whenTapped:^(TCCircleMenuItem *sender){
                NSLog(@"Third");
            }],
            [TCCircleMenuItem itemNamed:@"d fourth button" whenTapped:^(TCCircleMenuItem *sender){
                NSLog(@"Fourth");
            }],
            [TCCircleMenuItem itemNamed:@"x close" whenTapped:^(TCCircleMenuItem *sender){
                [weakMenu dismiss];
            }],
        nil]];
        
        [menu presentAt:p inView:grec.view];
    }
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
{
    UIView *view = touch.view;
    do {
        if([view isKindOfClass:[TCCircleMenu class]]) return NO;
    } while((view = view.superview));
    
    return YES;
}

@end
