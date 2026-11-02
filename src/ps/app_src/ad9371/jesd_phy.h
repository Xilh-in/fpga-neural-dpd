#ifndef SRC_JESD_PHY_H_
#define SRC_JESD_PHY_H_
#include <stdint.h>
#include "mykonos.h"

typedef struct {
	uint32_t refclk_div;
	uint32_t out_div;
	uint32_t fbdiv_45;
	uint32_t fbdiv;
	uint32_t fbdiv_ratio;
	uint32_t lowband;
	uint16_t cfg0;
	uint16_t cfg1;
	uint16_t cfg2;
	uint16_t cfg3;
	uint16_t cfg4;
} phy_jesd_clk;
typedef struct {
	uint32_t ref_rate_khz;
	uint32_t lane_rate_khz;
	uint32_t cpll_enable;
} phy_jesd;

#define drp_write(jesd_phy_addr, reg, mask, val) \
		__drp_write (jesd_phy_addr, reg, mask, find_first_bit(mask), val)
#define drp_write2(jesd_phy_addr, reg, mask, val) \
		__drp_write2 (jesd_phy_addr, reg, mask, find_first_bit(mask), val)
int32_t xcvr_calc_cpll_settings(uint32_t refclk_kHz,
								uint32_t laneRate_kHz,
								uint32_t *refclk_div, uint32_t *out_div,
								uint32_t *fbdiv_45, uint32_t *fbdiv);
int32_t xcvr_calc_qpll_settings(uint32_t refclk_kHz,
								uint32_t laneRate_kHz,
								uint32_t *refclk_div, uint32_t *out_div,
								uint32_t *fbdiv, uint32_t *fbdiv_ratio,
								uint32_t *lowband);
int32_t jesd_phy_settings_dualphy(mykonosDevice_t *mykDevice, uint32_t jesd_phy0_addr,
		uint32_t jesd_phy1_addr);
int32_t jesd_phy_settings_singlephy(uint32_t jesd_phyaddr);
#endif
