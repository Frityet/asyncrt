#import <AsyncRT/Core/AsyncTask.h>

#pragma clang assume_nonnull begin

extern int AsyncRT_OFData_AsyncIO_anchor;
static int *const AsyncRT_OFData_AsyncIO_anchor_reference __attribute__((used)) = &AsyncRT_OFData_AsyncIO_anchor;

@interface OFData(AsyncIO)

+ (AsyncTask<OFData *> *)taskToReadDataWithContentsOfFile: (OFString *)path;
+ (AsyncTask<OFData *> *)taskToReadDataWithContentsOfIRI: (OFIRI *)IRI;

@end

#pragma clang assume_nonnull end
