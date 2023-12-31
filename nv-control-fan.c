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
 * nv-control-fan.c - a modification of nv-control-dvc.c to control fans.
 *
 * The attribute NV_CTRL_THERMAL_COOLER_LEVEL is the one to control.
 *
 * Please see the section "DISPLAY DEVICES" in NV-CONTROL-API.txt for
 * an explanation of display devices.
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
    Bool ret;
    int screen, retval, setval = -1;
    NVCTRLAttributeValidValuesRec valid_values;
    int *data;
    int len;
    int i;

    /*
     * If there is a commandline argument, interpret it as the value
     * to use to set the fan speed.
     */
    
    if (argc == 2) {
        setval = atoi(argv[1]);
    }


    /*
     * Open a display connection, and make sure the NV-CONTROL X
     * extension is present on the screen we want to use.
     */

    dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "Cannot open display '%s'.\n", XDisplayName(NULL));
        return 1;
    }
    
    screen = GetNvXScreen(dpy);


    /*
     * Get the list of enabled display devices on the X screen
     */

    ret = XNVCTRLQueryTargetBinaryData(dpy,
                                       NV_CTRL_TARGET_TYPE_GPU,
                                       screen,
                                       0,
                                       NV_CTRL_BINARY_DATA_COOLERS_USED_BY_GPU,
                                       (unsigned char **)&data,
                                       &len);
    if (!ret) {
        fprintf(stderr, "Unable to determine coolers used by gpu for "
                "screen %d of '%s'\n", screen, XDisplayName(NULL));
        return 1;
    }
    
    /*
     * loop over each enabled display device
     */

    for (i = 0; i < data[0]; i++) {

        int dpyId = i;

        /*
         * Query the valid values for NV_CTRL_THERMAL_COOLER_LEVEL
         */

        ret = XNVCTRLQueryValidTargetAttributeValues(dpy,
                                                     NV_CTRL_TARGET_TYPE_COOLER,
                                                     dpyId,
                                                     0,
                                                     NV_CTRL_THERMAL_COOLER_LEVEL,
                                                     &valid_values);
        if (!ret) {
            fprintf(stderr, "Unable to query the valid values for "
                    "NV_CTRL_THERMAL_COOLER_LEVEL on display device DPY-%d of "
                    "screen %d of '%s'.\n",
                    dpyId,
                    screen, XDisplayName(NULL));
            return 1;
        }

        /* we assume that NV_CTRL_THERMAL_COOLER_LEVEL is a range type */
        
        if (valid_values.type != ATTRIBUTE_TYPE_RANGE) {
            fprintf(stderr, "NV_CTRL_THERMAL_COOLER_LEVEL is not of "
                    "type RANGE.\n");
            return 1;
        }

        /* print the range of valid values */

        printf("Valid values for NV_CTRL_THERMAL_COOLER_LEVEL: "
               "(%" PRId64 " - %" PRId64 ").\n",
               valid_values.u.range.min, valid_values.u.range.max);
    
        /*
         * if a value was specified on the commandline, set it;
         * otherwise, query the current value
         */
        
        if (setval != -1) {
        
            XNVCTRLSetTargetAttribute(dpy,
                                      NV_CTRL_TARGET_TYPE_COOLER,
                                      dpyId,
                                      0,
                                      NV_CTRL_THERMAL_COOLER_LEVEL,
                                      setval);
            XFlush(dpy);

            printf("Set NV_CTRL_THERMAL_COOLER_LEVEL to %d on display device "
                   "DPY-%d of screen %d of '%s'.\n", setval, dpyId, screen,
                   XDisplayName(NULL));
        } else {
        
            ret = XNVCTRLQueryTargetAttribute(dpy,
                                              NV_CTRL_TARGET_TYPE_COOLER,
                                              dpyId,
                                              0,
                                              NV_CTRL_THERMAL_COOLER_CURRENT_LEVEL,
                                              &retval);

            printf("The current value of NV_CTRL_THERMAL_COOLER_CURRENT_LEVEL "
                   "is %d on display device DPY-%d of screen %d of '%s'.\n",
                   retval, dpyId, screen, XDisplayName(NULL));
        }
    }
    
    return 0;
}
