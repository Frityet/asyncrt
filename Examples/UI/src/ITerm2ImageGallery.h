#pragma once

#import <AsyncRT/Core/AsyncRuntime.h>
#import <AsyncRT/Networking/HTTP.h>

#pragma clang assume_nonnull begin

typedef enum TerminalGraphicsProtocol: unsigned char {
    TerminalGraphicsProtocolITerm2,
    TerminalGraphicsProtocolKitty
} TerminalGraphicsProtocol;

[[subclassing_restricted, direct_members]]
@interface ITerm2InlineImage : OFObject

@property(readonly, copy, nonatomic) OFString *filename;
@property(readonly, nonatomic) OFData *data;

- (instancetype)initWithFilename: (OFString *)filename
                            data: (OFData *)data [[designated_initailiser]];
- (instancetype)init OF_UNAVAILABLE;
- (void)writeWithDisplayWidth: (OFString *)displayWidth;

@end

@namespace(ITerm2ImageGallery)

+ (AsyncTask<ITerm2InlineImage *> *)taskToLoadImageAtIRI: (OFIRI *)iri
                                        usingClient: (AsyncHTTPClient *)client
                                         refererIRI: (OFIRI *)refererIRI
                                       maxPixelEdge: (size_t)maxPixelEdge
                                        jpegQuality: (double)jpegQuality;
+ (OFString *)displayWidthForColumns: (size_t)columns
                                scale: (double)scale;
+ (OFString *)displayWidthForImageCount: (size_t)imageCount
                                  scale: (double)scale;
+ (void)writeImages: (OFArray<ITerm2InlineImage *> *)images
            columns: (size_t)columns
       displayWidth: (OFString *)displayWidth
        jpegQuality: (double)jpegQuality;
+ (void)writeImages: (OFArray<ITerm2InlineImage *> *)images
            columns: (size_t)columns
              scale: (double)scale
        jpegQuality: (double)jpegQuality
    graphicsProtocol: (TerminalGraphicsProtocol)graphicsProtocol;
+ (void)writeImages: (OFArray<ITerm2InlineImage *> *)images
            columns: (size_t)columns
       displayWidth: (OFString *)displayWidth
        jpegQuality: (double)jpegQuality
    graphicsProtocol: (TerminalGraphicsProtocol)graphicsProtocol;

@end

#pragma clang assume_nonnull end
