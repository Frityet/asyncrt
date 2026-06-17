#include "AsyncWebUIApplication.h"

@implementation AsyncWebUIApplication

- (OFString *)title
{ return @"AsyncWebUIApplication"; }
- (OFString *)rootContent
{ return @"<html><body><h1>Hello, AsyncWebUIApplication!</h1></body></html>"; }
- (AsyncTask<OFString *> *)taskForContents
{ return [AsyncTask resolved: self.rootContent]; }

@end
