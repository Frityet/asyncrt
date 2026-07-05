#import "OFData+AsyncIO.h"

#import <AsyncRT/IO/OFHTTPClient+AsyncIO.h>

#pragma clang assume_nonnull begin

@implementation OFData(AsyncIO)

+ (AsyncTask<OFData *> *)taskToReadDataWithContentsOfFile: (OFString *)path
{
    return [AsyncTask<OFData *> spawnOffloaded: ^OFData *{
        return [OFData dataWithContentsOfFile: path];
    }];
}

+ (AsyncTask<OFData *> *)taskToReadDataWithContentsOfIRI: (OFIRI *)IRI
{
    auto scheme = IRI.scheme.lowercaseString;

    if ([scheme isEqual: @"http"] or [scheme isEqual: @"https"]) {
        auto request = [OFHTTPRequest requestWithIRI: IRI];
        auto client = [OFHTTPClient client];
        return [client taskToReadBodyForRequest: request];
    }

    return [AsyncTask<OFData *> spawnOffloaded: ^OFData *{
        return [OFData dataWithContentsOfIRI: IRI];
    }];
}

@end

#pragma clang assume_nonnull end
