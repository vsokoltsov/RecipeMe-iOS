
@protocol AuthorizationDelegate <NSObject>

@optional
- (void) successAuthentication: (id) user;
- (void) failedAuthentication: (id) error;
- (void) failedRegistration: (id) error;
- (void) signInWithParams: (NSDictionary *) params;
- (void) signUpWithParams: (NSDictionary *) params;
- (void) keyboardWasShowOnField: (id) field withNotification: (id) notification;
@end