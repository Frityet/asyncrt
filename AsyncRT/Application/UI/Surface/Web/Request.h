#pragma once

#import <AsyncRT/Core.h>

#pragma clang assume_nonnull begin

typedef struct AsyncWebUIRequest {
    OFString *nillable action;
    id nillable payload;
    OFString *nillable requestID;
} AsyncWebUIRequest;

typedef AsyncTask<OFString *> *nonnil (^AsyncWebUIActionHandler)(AsyncWebUIRequest request);

#pragma clang assume_nonnull end
