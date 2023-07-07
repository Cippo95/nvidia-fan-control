/*
 * Copyright (c) 2004 NVIDIA, Corporation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * nv-control-core-temperature.c - trivial sample NV-CONTROL client that
 * demonstrates how to query current core temperature.
 *
 * Please see the section "DISPLAY DEVICES" in NV-CONTROL-API.txt for
 * an explanation of display devices.
 *
 * Derived from nv-control-dvc.c by Cippo95
 */

#define __STDC_FORMAT_MACROS
#include <inttypes.h>

#include <stdio.h>
#include <stdlib.h>

#include <X11/Xlib.h>

#include "NVCtrl.h"
#include "NVCtrlLib.h"

#include "nv-control-screen.h"


int main(int argc, char *argv[])
{
	Display *dpy;
	int retval;

	/*
	* Open a display connection, and make sure the NV-CONTROL X
	* extension is present on the screen we want to use.
	*/

	dpy = XOpenDisplay(NULL);
	if (!dpy) {
		fprintf(stderr, "Cannot open display '%s'.\n", XDisplayName(NULL));
		return 1;
	}
    
	/* print current core temperature */
	XNVCTRLQueryTargetAttribute(dpy,
			      NV_CTRL_TARGET_TYPE_GPU,
			      0,
			      0,
			      NV_CTRL_GPU_CORE_TEMPERATURE,
			      &retval);

	printf("%d",retval);

	return 0;
}
