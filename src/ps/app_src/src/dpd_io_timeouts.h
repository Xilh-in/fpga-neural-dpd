/* Shared bounded polling. BSP must provide a running XTime counter. */
#ifndef DPD_IO_TIMEOUTS_H
#define DPD_IO_TIMEOUTS_H
#include <stdint.h>
#include "xuartps_hw.h"
#ifdef SDT
#include "xiltimer.h"
#else
#include "xtime_l.h"
#endif

#ifndef DPD_ALIGN_TIMEOUT_SECONDS
#define DPD_ALIGN_TIMEOUT_SECONDS 2U
#endif
#ifndef DPD_RX_TIMEOUT_SECONDS
#define DPD_RX_TIMEOUT_SECONDS 2U
#endif
#ifndef DPD_UART_BAUD
#define DPD_UART_BAUD 115200U
#endif

static void dpd_reply(const char *text)
{
    while (*text) XUartPs_SendByte(XPAR_XUARTPS_0_BASEADDR, (uint8_t)*text++);
}

/* Limit both total receive duration and silence between successive bytes. */
static int dpd_receive_bounded(uint8_t *data, uint32_t size, XTime total_budget)
{
    XTime start, last_byte, now;
    uint32_t index = 0;
    XTime_GetTime(&start);
    last_byte = start;
    while (index < size) {
        XTime_GetTime(&now);
        if ((now - start) >= total_budget ||
            (now - last_byte) >= (XTime)COUNTS_PER_SECOND * DPD_RX_TIMEOUT_SECONDS) return 0;
        if (XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR)) {
            data[index++] = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);
            last_byte = now;
        }
    }
    return 1;
}

#endif
