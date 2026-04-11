#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"
#import "Async/ObjFWAsync/OFStream+Promise.h"
#import "Async/ObjFWAsync/OFStreamSocket+Promise.h"
#import "Async/ObjFWAsync/OFDatagramSocket+Promise.h"
#import "Async/ObjFWAsync/OFSequencedPacketSocket+Promise.h"
#import "Async/ObjFWAsync/OFTCPSocket+Promise.h"
#import "Async/ObjFWAsync/OFTLSStream+Promise.h"
#import "Async/ObjFWAsync/OFDNSResolver+Promise.h"
#import "Async/ObjFWAsync/OFIRIHandler+Promise.h"
#import "Async/ObjFWAsync/OFHTTPClient+Promise.h"

#ifdef OF_HAVE_SCTP
#import "Async/ObjFWAsync/OFSCTPSocket+Promise.h"
#endif

#ifdef OF_HAVE_IPX
#import "Async/ObjFWAsync/OFSPXSocket+Promise.h"
#import "Async/ObjFWAsync/OFSPXStreamSocket+Promise.h"
#endif
