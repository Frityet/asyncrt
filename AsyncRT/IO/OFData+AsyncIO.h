#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

@interface OFData(AsyncIO)

+ (AsyncTask<OFData *> *)taskToReadDataWithContentsOfFile: (OFString *)path;
+ (AsyncTask<OFData *> *)taskToReadDataWithContentsOfIRI: (OFIRI *)IRI;

@end

#pragma clang assume_nonnull end
