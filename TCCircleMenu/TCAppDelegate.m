#import "TCAppDelegate.h"
#import "TCCircleMenu.h"

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
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    UITapGestureRecognizer *grec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(grec:)];
    [self.window addGestureRecognizer:grec];
    
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
                [TCCircleMenuItem itemNamed:@"Sub 1" whenTapped:^(TCCircleMenuItem *sender){
                    NSLog(@"Sub 1!");
                }],
                [TCCircleMenuItem itemNamed:@"Go back" whenTapped:^(TCCircleMenuItem *sender){
                    [weakMenu dismissSubmenu];
                }],
                nil]];
                [weakMenu presentSubmenu:subMenu fromItem:sender];
            }],
            [TCCircleMenuItem itemNamed:@"c third button" whenTapped:^(TCCircleMenuItem *sender){
            
            }],
            [TCCircleMenuItem itemNamed:@"d fourth button" whenTapped:^(TCCircleMenuItem *sender){
            
            }],
            [TCCircleMenuItem itemNamed:@"x close" whenTapped:^(TCCircleMenuItem *sender){
                [weakMenu dismiss];
            }],
        nil]];
        
        [menu presentAt:p inView:self.window];
    }
}

@end
