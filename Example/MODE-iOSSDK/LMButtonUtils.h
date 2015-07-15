#import <UIKit/UIKit.h>

UIButton* setupEditButton(UIView* view, id target, SEL edit);
UIButton* setupAddButton(UIView* view, id target, SEL add);
void setupProfileButton(UINavigationItem* navigationItem, id target, SEL selector);
void setupRightBarButtonItem(UINavigationItem* navigationItem, NSString* title, id target, SEL selector);
