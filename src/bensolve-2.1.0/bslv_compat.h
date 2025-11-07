/*
 * Windows compatibility header for BENSOLVE
 * Provides cross-platform definitions for timing functions
 */

#ifndef BSLV_COMPAT_H
#define BSLV_COMPAT_H

#ifdef _WIN32
/* Windows-specific definitions */
#include <windows.h>
#include <time.h>

/* Define timeval structure for Windows */
#ifndef _TIMEVAL_DEFINED
#define _TIMEVAL_DEFINED
struct timeval {
    long tv_sec;
    long tv_usec;
};
#endif

/* Implement gettimeofday for Windows */
static inline int gettimeofday(struct timeval *tv, void *tz)
{
    FILETIME ft;
    unsigned __int64 tmpres = 0;
    
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

#else
/* Unix-like systems */
#include <sys/time.h>
#include <unistd.h>

#endif /* _WIN32 */

#endif /* BSLV_COMPAT_H */
