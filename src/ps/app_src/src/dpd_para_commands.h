/* Include once in headless.c, after register macros and axi_dpd_addr. */
#ifndef DPD_PARA_COMMANDS_H
#define DPD_PARA_COMMANDS_H
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include "dpd_io_timeouts.h"

#define DPD_PARAMETER_COUNT 576U

static int dpd_parse_address(const char *text, uint32_t *value)
{
    char *end;
    unsigned long parsed;
    if (!text || !*text || *text == '-' || *text == '+') return 0;
    errno = 0;
    parsed = strtoul(text, &end, 10);
    if (errno || *end || parsed > DPD_PARAMETER_COUNT) return 0;
    *value = (uint32_t)parsed;
    return 1;
}

static int dpd_parameter_range(int argc, char **argv, uint32_t *start, uint32_t *stop)
{
    if (argc != 3 || !dpd_parse_address(argv[1], start) ||
        !dpd_parse_address(argv[2], stop) || *start >= *stop) {
        dpd_reply("ERR RANGE\n");
        return 0;
    }
    return 1;
}

/* Stage the entire payload before touching PL: a short packet never partially writes. */
static int dpd_receive_payload(uint8_t *data, uint32_t size)
{
    return dpd_receive_bounded(data, size, (XTime)COUNTS_PER_SECOND * DPD_RX_TIMEOUT_SECONDS);
}

static void Para_Write(int argc, char **argv)
{
    static uint8_t payload[DPD_PARAMETER_COUNT * 2U];
    uint32_t start, stop, address, index, value;
    if (!dpd_parameter_range(argc, argv, &start, &stop)) return;
    if (!dpd_receive_payload(payload, (stop - start) * 2U)) {
        dpd_reply("ERR TIMEOUT\n");
        return;
    }
    AXI_REG_WRITE(axi_dpd_addr, DPD_COE_EN, 0);
    AXI_REG_WRITE(axi_dpd_addr, DPD_COE_WR, 1);
    for (address = start; address < stop; ++address) {
        index = (address - start) * 2U;
        value = (uint32_t)payload[index] | ((uint32_t)payload[index + 1U] << 8);
        /* EN is low while address/data change; assert only after both are stable. */
        AXI_REG_WRITE(axi_dpd_addr, DPD_COE_ADDR, address);
        AXI_REG_WRITE(axi_dpd_addr, DPD_COE_WDATA, value);
        AXI_REG_WRITE(axi_dpd_addr, DPD_COE_EN, 1);
        (void)AXI_REG_READ(axi_dpd_addr, DPD_COE_WDATA);
        AXI_REG_WRITE(axi_dpd_addr, DPD_COE_EN, 0);
    }
    AXI_REG_WRITE(axi_dpd_addr, DPD_COE_WR, 0);
    dpd_reply("\n");
}

static void Para_Read(int argc, char **argv)
{
    uint32_t start, stop, address, value;
    if (!dpd_parameter_range(argc, argv, &start, &stop)) return;
    AXI_REG_WRITE(axi_dpd_addr, DPD_COE_EN, 0);
    AXI_REG_WRITE(axi_dpd_addr, DPD_COE_WR, 0);
    for (address = start; address < stop; ++address) {
        AXI_REG_WRITE(axi_dpd_addr, DPD_COE_ADDR, address);
        AXI_REG_WRITE(axi_dpd_addr, DPD_COE_EN, 1);
        /* Read is synchronous in dpd_top.sv; discard the first bus read. */
        (void)AXI_REG_READ(axi_dpd_addr, DPD_COE_RDATA);
        value = AXI_REG_READ(axi_dpd_addr, DPD_COE_RDATA);
        XUartPs_SendByte(XPAR_XUARTPS_0_BASEADDR, (uint8_t)value);
        XUartPs_SendByte(XPAR_XUARTPS_0_BASEADDR, (uint8_t)(value >> 8));
        AXI_REG_WRITE(axi_dpd_addr, DPD_COE_EN, 0);
    }
    dpd_reply("\n");
}
#endif
