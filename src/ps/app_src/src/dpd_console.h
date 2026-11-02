#ifndef DPD_CONSOLE_H
#define DPD_CONSOLE_H
/* Waiting for a NEW command is intentional. A started/overlong line is bounded. */
static int console_get_command(char *command, unsigned int capacity)
{
    unsigned int length = 0;
    int overflow = 0;
    uint8_t received;
    XTime start, now;
    if (!capacity) return 0;
    received = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);
    XTime_GetTime(&start);
    for (;;) {
        if (received == '\n' || received == '\r') break;
        if (received == 0) overflow = 1;
        else if (length + 1U < capacity) command[length++] = (char)received;
        else overflow = 1;
        for (;;) {
            XTime_GetTime(&now);
            if ((now - start) >= (XTime)COUNTS_PER_SECOND * DPD_RX_TIMEOUT_SECONDS) {
                command[0] = '\0';
                dpd_reply("ERR LINE TIMEOUT\n");
                return 0;
            }
            if (XUartPs_IsReceiveData(XPAR_XUARTPS_0_BASEADDR)) {
                received = XUartPs_RecvByte(XPAR_XUARTPS_0_BASEADDR);
                break;
            }
        }
    }
    command[length] = '\0';
    if (overflow) dpd_reply("ERR LINE\n");
    return !overflow;
}
#endif
