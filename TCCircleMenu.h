#import <UIKit/UIKit.h>
@class TCCircleMenuItem;

@interface TCCircleMenu : UIView
@property(nonatomic,readonly) NSMutableArray *menuItems;
-init;

-(void)presentAt:(CGPoint)p inView:(UIView*)view;
-(void)dismiss;

@property(nonatomic,readonly) TCCircleMenu *subMenu;
-(void)presentSubmenu:(TCCircleMenu*)menu fromItem:(TCCircleMenuItem*)item;
-(void)dismissSubmenu;
@end


@interface TCCircleMenuItem : UIView
+ (TCCircleMenuItem*)itemNamed:(NSString*)name whenTapped:(void(^)(TCCircleMenuItem *sender))block;
-(id)initNamed:(NSString*)name whenTapped:(void(^)(TCCircleMenuItem *sender))block;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) void(^action)(TCCircleMenuItem*);
@end
