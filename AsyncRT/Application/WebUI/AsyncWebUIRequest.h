#import <AsyncRT/Core.h>

struct AsyncWebUIRequest {
    OFString *action;
    OFString *payloadJSON;
    OFString *requestID;
};

typedef AsyncTask<OFString *> *nonnil (^AsyncWebUIActionHandler)(struct AsyncWebUIRequest request);

