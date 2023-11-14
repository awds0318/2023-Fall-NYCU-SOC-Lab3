#ifndef __FIR_H__
#define __FIR_H__

#define N 11

#include <defs.h>

#define ap (*(volatile uint32_t *)0x30000000)
#define datalength (*(volatile uint32_t *)0x30000010)

#define tap0 (*(volatile uint32_t *)0x30000040)
#define tap1 (*(volatile uint32_t *)0x30000044)
#define tap2 (*(volatile uint32_t *)0x30000048)
#define tap3 (*(volatile uint32_t *)0x3000004c)
#define tap4 (*(volatile uint32_t *)0x30000050)
#define tap5 (*(volatile uint32_t *)0x30000054)
#define tap6 (*(volatile uint32_t *)0x30000058)
#define tap7 (*(volatile uint32_t *)0x3000005c)
#define tap8 (*(volatile uint32_t *)0x30000060)
#define tap9 (*(volatile uint32_t *)0x30000064)
#define tap10 (*(volatile uint32_t *)0x30000068)

#define Xn (*(volatile uint32_t *)0x30000080)
#define Yn (*(volatile uint32_t *)0x30000084)

// int taps[N] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
// int inputbuffer[N];
// int inputsignal[N] = {1,2,3,4,5,6,7,8,9,10,11};
// int inputsignal;
// int outputsignal;
int ans[64];
#endif
