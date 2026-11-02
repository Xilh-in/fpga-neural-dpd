/*
 * ad9371_init.h
 *
 *  Created on: 2018��8��1��
 *      Author: liche
 */

#ifndef SRC_AD9371_CONFIG_H_
#define SRC_AD9371_CONFIG_H_
#include "mykonos.h"
#include "common.h"
#include "mykonos_gpio.h"
#include "jesd_core.h"
#include "jesd_phy.h"
#include "stdio.h"
#include "ad9528.h"

#define JESD_CON_FAILED 520
typedef struct {
	jesd_core		tx_jesd;
	jesd_core		rx_jesd;
	jesd_core		orx_jesd;
} jesd_core_array;


mykonosErr_t ad9371_init(mykonosDevice_t *device);
mykonosErr_t ad9371_rf_init(mykonosDevice_t *device);
mykonosErr_t ad9371_init_Calibrations(mykonosDevice_t *device);
mykonosErr_t ad9371_jesd204b_init(mykonosDevice_t *device_rf1);
uint32_t fpga_jesd204b_init(jesd_core_array jesd_array_rf1,
		uint32_t jesd_phy_addr);
mykonosErr_t jesd204b_check(mykonosDevice_t *device, jesd_core_array jesd_array);
mykonosErr_t ad9371_radio_on(mykonosDevice_t *device);
mykonosErr_t ad9371_initial(mykonosDevice_t *device_rf1,
		jesd_core_array jesd_array_rf1, uint32_t jesd_phy_addr);
#endif /* SRC_AD9371_CONFIG_H_ */
