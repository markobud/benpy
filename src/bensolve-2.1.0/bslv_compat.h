/*
 * Windows compatibility header for BENSOLVE
 * Provides cross-platform definitions for timing and system functions
 */

#ifndef BSLV_COMPAT_H
#define BSLV_COMPAT_H

#ifdef _WIN32
/* Windows-specific definitions */
/* Suppress MSVC warnings about deprecated CRT functions (strcpy, strcat, etc.) */
#ifndef _CRT_SECURE_NO_WARNINGS
#define _CRT_SECURE_NO_WARNINGS
#endif

/* Include winsock2.h before windows.h to get timeval definition
 * and avoid conflicts. winsock2.h must come before windows.h */
#include <winsock2.h>
#include <windows.h>
#include <time.h>

/* timeval is already defined in winsock2.h on Windows, so we don't redefine it */

/* Implement gettimeofday for Windows
 * Parameters:
 *   tv - pointer to timeval structure to fill (must not be NULL)
 *   tz - timezone parameter (ignored, provided for API compatibility)
 * Returns:
 *   0 on success
 */
static inline int gettimeofday(struct timeval *tv, void *tz)
{
    FILETIME ft;
    unsigned __int64 tmpres = 0;
    
    (void)tz;  /* Unused parameter - timezone info is not provided */
    
    if (tv != NULL) {
        GetSystemTimeAsFileTime(&ft);
        
        tmpres |= ft.dwHighDateTime;
        tmpres <<= 32;
        tmpres |= ft.dwLowDateTime;
        
        /* Converting file time to unix epoch */
        tmpres /= 10;  /* convert into microseconds */
        tmpres -= 11644473600000000ULL; /* UNIX epoch offset */
        
        tv->tv_sec = (long)(tmpres / 1000000UL);
        tv->tv_usec = (long)(tmpres % 1000000UL);
    }
    
    return 0;
}

/* MSVC doesn't support C99 VLAs (variable-length arrays).
 * Use _malloca for stack-like allocation with automatic cleanup via _freea.
 * _malloca allocates on stack if size is small, otherwise uses heap.
 */
#include <malloc.h>
#define BSLV_VLA_ALLOC(type, name, size) type *name = (type *)_malloca((size) * sizeof(type))
#define BSLV_VLA_FREE(name) _freea(name)

#else
/* Unix-like systems */
#include <sys/time.h>
#include <unistd.h>

/* On Unix/POSIX systems, VLAs are supported natively in C99 */
#define BSLV_VLA_ALLOC(type, name, size) type name[size]
#define BSLV_VLA_FREE(name) /* No-op on systems with native VLA support */

#endif /* _WIN32 */

#endif /* BSLV_COMPAT_H */
