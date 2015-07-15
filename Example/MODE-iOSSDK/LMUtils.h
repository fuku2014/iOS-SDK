@interface NumericTextFieldDelegate : NSObject<UITextFieldDelegate>

@end

@interface PhoneNumberFieldDelegate : NSObject<UITextFieldDelegate>

- (id)initWithTextField:(UITextField*)textField;

@end

// These functions are for mixin to restrict UITextField only for numbers and phone numbers.
// You could make your subclasses derived from UITextField.
NumericTextFieldDelegate* setupNumericTextField(UITextField* textField, NSString* name, NSString* iconName);
PhoneNumberFieldDelegate* setupPhoneNumberField(UITextField* textField);

void setupStandardTextField(UITextField* textField, NSString* name, NSString* iconName);

void setupMessage(UILabel* message, NSString* text);
void setupMessageWithColor(UILabel* message, NSString* text, UIColor* color);

NSString* formatPhonenumberFromString(NSString* phonenumber);

UILabel* setupTitle(NSString* title);

void showAlert(NSError* err);
