#include "fir.h"

void __attribute__((section(".mprjram"))) initfir()
{
	// initial your fir
	datalength = 64;
	// int taps[N] = {0,-10,-9,23,56,63,56,23,-9,-10,0};
	tap0 = 0;
	tap1 = -10;
	tap2 = -9;
	tap3 = 23;
	tap4 = 56;
	tap5 = 63;
	tap6 = 56;
	tap7 = 23;
	tap8 = -9;
	tap9 = -10;
	tap10 = 0;

	return;
}

int *__attribute__((section(".mprjram"))) fir()
{
	initfir();
	// write down your fir
	ap = 1;
	reg_mprj_datal = 0xA50000; // start latency timer

	for (int n = 0; n < 64; n++)
	{
		// while ((ap >> 4) & 1 != 1)
		// {
		// } // wait until Xn [4] is ready
		Xn = n;
		// while ((ap >> 5) & 1 != 1)
		// {
		// } // wait until Yn [5] is ready
		ans[n] = Yn;
	}

	// write output to mprj[31:24], endmark
	reg_mprj_datal = ((0xFF & ans[63]) << 24) | 0x5A0000;

	return ans;
}
