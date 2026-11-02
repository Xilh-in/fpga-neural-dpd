#ifndef DPD_ALIGNMENT_H
#define DPD_ALIGNMENT_H
static int dpd_wait_cap_done(uint32_t desired)
{
    XTime start, now;
    XTime_GetTime(&start);
    for (;;) {
        XTime_GetTime(&now);
        if ((now - start) >= (XTime)COUNTS_PER_SECOND * DPD_ALIGN_TIMEOUT_SECONDS) return 0;
        if (AXI_REG_READ(axi_dpd_addr, CAP_DONE) == desired) return 1;
    }
}

static void dpd_alignment_failed(const char *message)
{
    AXI_REG_WRITE(axi_dpd_addr, CAP_DATA_CMD, 0);
    AXI_REG_WRITE(axi_dpd_addr, ALIGN_EN, 0);
    AXI_REG_WRITE(axi_dpd_addr, TX_VLD, 0);
    AXI_REG_WRITE(axi_dpd_addr, DPD_EN, 0);
    dpd_reply(message);
}
#endif
