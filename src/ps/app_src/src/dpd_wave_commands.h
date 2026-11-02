#ifndef DPD_WAVE_COMMANDS_H
#define DPD_WAVE_COMMANDS_H
#ifndef DPD_WAVE_SAMPLE_COUNT
#define DPD_WAVE_SAMPLE_COUNT 17536U
#endif

static int dpd_wave_address(const char *text, uint32_t *value)
{
    char *end;
    unsigned long parsed;
    if (!text || !*text || *text == '-' || *text == '+') return 0;
    errno = 0;
    parsed = strtoul(text, &end, 10);
    if (errno || *end || parsed > DPD_WAVE_SAMPLE_COUNT) return 0;
    *value = (uint32_t)parsed;
    return 1;
}

/* Shared static staging costs 70144 bytes of BSS, not the small PS stack. */
static void dpd_wave_write(int argc, char **argv, uint32_t enable_reg,
                           uint32_t write_reg, uint32_t address_reg, uint32_t data_reg)
{
    static uint8_t payload[DPD_WAVE_SAMPLE_COUNT * 4U];
    uint32_t start, stop, size, index, address, value;
    XTime budget;
    if (argc != 3 || !dpd_wave_address(argv[1], &start) ||
        !dpd_wave_address(argv[2], &stop) || start >= stop) {
        dpd_reply("ERR RANGE\n");
        return;
    }
    size = (stop - start) * 4U;
    budget = (XTime)COUNTS_PER_SECOND * DPD_RX_TIMEOUT_SECONDS +
             ((XTime)size * 10U * 3U * COUNTS_PER_SECOND + DPD_UART_BAUD - 1U) / DPD_UART_BAUD;
    if (!dpd_receive_bounded(payload, size, budget)) {
        AXI_REG_WRITE(axi_dpd_addr, enable_reg, 0);
        AXI_REG_WRITE(axi_dpd_addr, write_reg, 0);
        dpd_reply("ERR RX TIMEOUT\n");
        return;
    }
    AXI_REG_WRITE(axi_dpd_addr, enable_reg, 0);
    AXI_REG_WRITE(axi_dpd_addr, write_reg, 1);
    for (address = start; address < stop; ++address) {
        index = (address - start) * 4U;
        value = (uint32_t)payload[index] | ((uint32_t)payload[index + 1U] << 8) |
                ((uint32_t)payload[index + 2U] << 16) | ((uint32_t)payload[index + 3U] << 24);
        AXI_REG_WRITE(axi_dpd_addr, address_reg, address);
        AXI_REG_WRITE(axi_dpd_addr, data_reg, value);
        AXI_REG_WRITE(axi_dpd_addr, enable_reg, 1);
        (void)AXI_REG_READ(axi_dpd_addr, data_reg);
        AXI_REG_WRITE(axi_dpd_addr, enable_reg, 0);
    }
    AXI_REG_WRITE(axi_dpd_addr, write_reg, 0);
    dpd_reply("\n");
}

static void TX_DATA_Write(int argc, char **argv)
{
    dpd_wave_write(argc, argv, TX_DATA_EN, TX_DATA_WR, TX_DATA_ADDR, TX_DATA_WDATA);
}

static void Cyclic_Data_Write(int argc, char **argv)
{
    dpd_wave_write(argc, argv, CYCLIC_DATA_EN, CYCLIC_DATA_WR, CYCLIC_DATA_ADDR, CYCLIC_DATA_WDATA);
}
#endif
