#import <UIKit/UIKit.h>
@class TCCircleMenuItem;

@interface TCCircleMenu : UIView
@property(nonatomic,readonly) NSMutableArray *menuItems;
+(id)menuWithItems:(NSArray*)items;
-(id)init;

-(void)presentAt:(CGPoint)p inView:(UIView*)view;
-(void)dismiss;

@property(nonatomic,retain,readonly) TCCircleMenu *subMenu;
-(void)presentSubmenu:(TCCircleMenu*)menu fromItem:(TCCircleMenuItem*)item;
-(void)dismissSubmenu;
@end


@interface TCCircleMenuItem : UIButton
+ (TCCircleMenuItem*)itemNamed:(NSString*)name whenTapped:(void(^)(TCCircleMenuItem *sender))block;
-(id)initNamed:(NSString*)name whenTapped:(void(^)(TCCircleMenuItem *sender))block;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) void(^action)(TCCircleMenuItem*);
@end
