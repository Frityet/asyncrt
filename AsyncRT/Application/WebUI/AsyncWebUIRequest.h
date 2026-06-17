#import <AsyncRT/Core.h>

struct AsyncWebUIRequest {
    OFString *nillable action;
    OFString *nillable payloadJSON;
    OFString *nillable requestID;
};

typedef AsyncTask<OFString *> *nonnil (^AsyncWebUIActionHandler)(struct AsyncWebUIRequest request);

