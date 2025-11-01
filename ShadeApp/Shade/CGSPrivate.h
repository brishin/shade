//
//  CGSPrivate.h
//  Shade
//
//  Private CoreGraphicsServices API declarations for Space detection
//  WARNING: These are undocumented APIs that may break in future macOS versions
//

#ifndef CGSPrivate_h
#define CGSPrivate_h

#import <Foundation/Foundation.h>

// Connection to the window server
typedef int CGSConnectionID;

// Get the default connection
extern CGSConnectionID CGSMainConnectionID(void);

// Space (desktop) management structures and functions
typedef uint64_t CGSSpaceID;

// Get information about all Spaces across all displays
extern CFArrayRef CGSCopyManagedDisplaySpaces(CGSConnectionID cid);

// Get the active Space for a display
extern CGSSpaceID CGSGetActiveSpace(CGSConnectionID cid);

// Get list of Spaces that a window belongs to
extern CFArrayRef CGSCopySpacesForWindows(CGSConnectionID cid, int selector, CFArrayRef windowIDs);

// Selector constants for CGSCopySpacesForWindows
enum {
    kCGSAllSpacesMask = 0x1F,
    kCGSCurrentSpaceMask = 0x01
};

#endif /* CGSPrivate_h */
