#pragma once

#import "Async/ObjFWAsync/ObjFWAsyncSupport.h"
#import "Async/ObjFWAsync/OFStream+Future.h"
#import "Async/ObjFWAsync/OFStreamSocket+Future.h"
#import "Async/ObjFWAsync/OFDatagramSocket+Future.h"
#import "Async/ObjFWAsync/OFSequencedPacketSocket+Future.h"
#import "Async/ObjFWAsync/OFTCPSocket+Future.h"
#import "Async/ObjFWAsync/OFTLSStream+Future.h"
#import "Async/ObjFWAsync/OFDNSResolver+Future.h"
#import "Async/ObjFWAsync/OFIRIHandler+Future.h"
#import "Async/ObjFWAsync/OFHTTPClient+Future.h"

#ifdef OF_HAVE_SCTP
#import "Async/ObjFWAsync/OFSCTPSocket+Future.h"
#endif

#ifdef OF_HAVE_IPX
#import "Async/ObjFWAsync/OFSPXSocket+Future.h"
#import "Async/ObjFWAsync/OFSPXStreamSocket+Future.h"
#endif
