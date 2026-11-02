/*
 * ad9371_init.c
 *
 *  Created on: 2018锟斤拷8锟斤拷1锟斤拷
 *      Author: liche
 */
#include <rf_config.h>
#include "mykonos_m3.h"
#include "mykonos_gpio.h"

static uint8_t pllLockStatus;
extern uint32_t axi_lite_addr;
extern mykonosTempSensorConfig_t tempSensor;
extern ad9528Device_t clockAD9528_;

mykonosTempSensorConfig_t tempSensorsdef =
{
    7,        /*!< 3-bit value that controls the AuxADC decimation factor when used for temp sensor calculations; AuxADC_decimation = 256 * 2^tempDecimation */
    0,      /*!< 8-bit offset that gets added to temp sensor code internally */
    1,         /*!< This bit overrides the factory-calibrated fuse offset and uses the value stored in the offset member */
    15       /*!< 4-bit code range above or below which windowExceeded member of the mykonosTempSensorStatus_t structure gets set during periodic measurements */
} ;
/*************************************************************************/
/*****                     ad9371_hard_reset                         *****/
/*************************************************************************/
mykonosErr_t ad9371_hard_reset(mykonosDevice_t *device){
	mykonosErr_t retval = MYKONOS_ERR_OK;
	/* Perform a hard reset on the MYKONOS DUT (Toggle RESETB pin on device) */
	if ((retval = MYKONOS_resetDevice(device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	return retval;
}
/*************************************************************************/
/*****                           ad9371_init                         *****/
/*************************************************************************/
mykonosErr_t ad9371_init(mykonosDevice_t *device) {
	mykonosErr_t retval = MYKONOS_ERR_OK;
	uint8_t mcsStatus;
	uint8_t arm_major;
	uint8_t arm_minor;
	uint8_t arm_release;
	mykonosBuild_t buildType;
	//Mykonos Initialization Sequence
	if ((retval = MYKONOS_initialize(device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	//Mykonos CLKPLL Status Check
	if ((retval = MYKONOS_checkPllsLockStatus(device, &pllLockStatus))!= MYKONOS_ERR_OK) {
		return retval;
	}
	//Mykonos Perform MultiChip Sync
	if ((retval = MYKONOS_enableMultichipSync(device, 1, &mcsStatus))!= MYKONOS_ERR_OK) {
		return retval;
	}
	mdelay(1);

	//Mykonos Verify MultiChip Sync
	if ((retval = MYKONOS_enableMultichipSync(device, 0, &mcsStatus))!= MYKONOS_ERR_OK) {
		return retval;
	}

	if ((mcsStatus & 0x0B) == 0x0B)
		printf("MCS successful\n");
	else
		printf("MCS failed\n");

	//Mykonos Load ARM file
	if (pllLockStatus & 0x01) {
		printf("CLKPLL locked\n");
		if ((retval = MYKONOS_initArm(device)) != MYKONOS_ERR_OK) {
			return retval;
		}
		if ((retval = MYKONOS_loadArmFromBinary(device, &firmware_Mykonos_M3_bin[0], firmware_Mykonos_M3_bin_len))!= MYKONOS_ERR_OK) {
			return retval;
		}
	} else {
		printf("CLKPLL not locked (0x%x)\n", pllLockStatus);
		return -1;
	}
	/* Read back the version of the ARM binary loaded into the Mykonos ARM memory */
	if ((retval = MYKONOS_getArmVersion(device, &arm_major, &arm_minor,&arm_release, &buildType)) != MYKONOS_ERR_OK){
		return retval;
	}
	else
		printf("AD9371 ARM version %d.%d.%d\n",arm_major, arm_minor,
				arm_release);
	return retval;
}
/*************************************************************************/
/*****                           ad9371_rf_init                      *****/
/*************************************************************************/
mykonosErr_t ad9371_rf_init(mykonosDevice_t *device) {
	mykonosErr_t retval = MYKONOS_ERR_OK;
	mykonosGpioErr_t mykGpioErr;
	//Mykonos Set RF PLL Frequencies
	if ((retval = MYKONOS_setRfPllFrequency(device, RX_PLL,device->rx->rxPllLoFrequency_Hz)) != MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setRfPllFrequency(device, TX_PLL,device->tx->txPllLoFrequency_Hz)) != MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setRfPllFrequency(device, SNIFFER_PLL,device->obsRx->snifferPllLoFrequency_Hz)) != MYKONOS_ERR_OK) {
		return retval;
	}
	/* Wait 200ms for PLLs to lock */
	mdelay(200);
	if ((retval = MYKONOS_checkPllsLockStatus(device, &pllLockStatus))!= MYKONOS_ERR_OK) {
		return retval;
	}
	if ((pllLockStatus & 0x0F) == 0x0F)
		printf("PLLs locked\n");
	else {
		printf("PLLs not locked (0x%x)\n",pllLockStatus);
		return -1;
	}
	//Mykonos Set GPIOs
	if ((mykGpioErr = MYKONOS_setRx1GainCtrlPin(device, 0, 0, 0, 0, 0))!= MYKONOS_ERR_GPIO_OK) {
		return retval;
	}
	if ((mykGpioErr = MYKONOS_setRx2GainCtrlPin(device, 0, 0, 0, 0, 0))!= MYKONOS_ERR_GPIO_OK) {
		return retval;
	}
	if ((mykGpioErr = MYKONOS_setTx1AttenCtrlPin(device, 0, 0, 0, 0, 0))!= MYKONOS_ERR_GPIO_OK) {
		return retval;
	}
	if ((mykGpioErr = MYKONOS_setTx2AttenCtrlPin(device, 0, 0, 0, 0))!= MYKONOS_ERR_GPIO_OK) {
		return retval;
	}
	if ((mykGpioErr = MYKONOS_setupGpio(device)) != MYKONOS_ERR_GPIO_OK) {
		return retval;
	}
	//Mykonos Set manual gains values
	if ((retval = MYKONOS_setRx1ManualGain(device, 255)) != MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setRx2ManualGain(device, 255)) != MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setObsRxManualGain(device, OBS_RX1_TXLO, 255))!= MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setObsRxManualGain(device, OBS_RX2_TXLO, 255))!= MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setObsRxManualGain(device, OBS_SNIFFER_A, 255))!= MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setObsRxManualGain(device, OBS_SNIFFER_B, 255))!= MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setObsRxManualGain(device, OBS_SNIFFER_C, 255))!= MYKONOS_ERR_OK) {
		return retval;
	}
	//Mykonos Initialize attenuations
	if ((retval = MYKONOS_setTx1Attenuation(device, 30000)) != MYKONOS_ERR_OK) { //range=0~41950
		return retval;
	}
	if ((retval = MYKONOS_setTx2Attenuation(device, 30000)) != MYKONOS_ERR_OK) { //range=0~41950
		return retval;
	}
	return retval;
}
/*************************************************************************/
/*****                           ad9371_init_Calibrations            *****/
/*************************************************************************/
mykonosErr_t ad9371_init_Calibrations(mykonosDevice_t *device) {
	mykonosErr_t retval = MYKONOS_ERR_OK;
	uint32_t initCalMask = TX_BB_FILTER | ADC_TUNER | TIA_3DB_CORNER | DC_OFFSET
			| TX_ATTENUATION_DELAY | RX_GAIN_DELAY | FLASH_CAL | PATH_DELAY
			| TX_LO_LEAKAGE_INTERNAL | TX_QEC_INIT | LOOPBACK_RX_LO_DELAY
			| LOOPBACK_RX_RX_QEC_INIT | RX_LO_DELAY | RX_QEC_INIT;
	uint8_t errorFlag = 0;
	uint8_t errorCode = 0;
	uint32_t initCalsCompleted;
	// Mykonos ARM Initialization Calibrations
	if ((retval = MYKONOS_runInitCals(device,(initCalMask & ~TX_LO_LEAKAGE_EXTERNAL))) != MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_waitInitCals(device, 60000, &errorFlag, &errorCode))!= MYKONOS_ERR_OK) {
		return retval;
	}
	if ((errorFlag != 0) || (errorCode != 0)) {
		/*** < Info: abort init cals > ***/
		if ((retval = MYKONOS_abortInitCals(device, &initCalsCompleted))!= MYKONOS_ERR_OK) {
			return retval;
		}
		if (initCalsCompleted)
			printf("Completed calibrations: %x\n",
					(unsigned int) initCalsCompleted);
	} else
		printf("Calibrations completed successfully\n");
	//Mykonos ARM Initialization External LOL Calibrations with PA
	/* Please ensure PA is enabled operational at this time */
	if (initCalMask & TX_LO_LEAKAGE_EXTERNAL) {
		if ((retval = MYKONOS_runInitCals(device, TX_LO_LEAKAGE_EXTERNAL))!= MYKONOS_ERR_OK) {
			return retval;
		}

		if ((retval = MYKONOS_waitInitCals(device, 60000, &errorFlag,&errorCode)) != MYKONOS_ERR_OK) {
			return retval;
		}

		if ((errorFlag != 0) || (errorCode != 0)) {
			/*** < Info: abort init cals > ***/
			if ((retval = MYKONOS_abortInitCals(device, &initCalsCompleted))!= MYKONOS_ERR_OK) {
				return retval;
			}
		} else
			printf("External LOL Calibrations completed successfully\n");
	}
	return retval;
}
/*************************************************************************/
/*****                    ad9371_jesd204b_init_dual                  *****/
/*************************************************************************/
mykonosErr_t ad9371_jesd204b_init(mykonosDevice_t *mykonos_device) {
	mykonosErr_t retval = MYKONOS_ERR_OK;
	/*************************************************************************/
	/*****          SYSTEM JESD bring up procedure for Device       *****/
	/*************************************************************************/
	if ((retval = MYKONOS_enableSysrefToRxFramer(mykonos_device, 0)) != MYKONOS_ERR_OK) {
			return retval;
	}
	if ((retval = MYKONOS_enableSysrefToObsRxFramer(mykonos_device, 0)) != MYKONOS_ERR_OK) {
			return retval;
	}
	if ((retval = MYKONOS_enableSysrefToRxFramer(mykonos_device, 1)) != MYKONOS_ERR_OK) {
		return retval;
	}
	/*** < Info: Mykonos is waiting for sysref in order to start
	 * transmitting CGS from the RxFramer> ***/
	if ((retval = MYKONOS_enableSysrefToObsRxFramer(mykonos_device, 1)) != MYKONOS_ERR_OK) {
		return retval;
	}
	/*** < Info: Mykonos is waiting for sysref in order to start
	 * transmitting CGS from the ObsRxFramer> ***/
	if ((retval = MYKONOS_enableSysrefToDeframer(mykonos_device, 0)) != MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_resetDeframer(mykonos_device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_enableSysrefToDeframer(mykonos_device, 1)) != MYKONOS_ERR_OK) {
		return retval;
	}
	return retval;
}
/*************************************************************************/
/*****                    fpga_jesd204b_init                         *****/
/*************************************************************************/
uint32_t fpga_jesd204b_init(jesd_core_array jesd_array,uint32_t jesd_phy_addr) {
	uint32_t status;
	status = jesd_phy_settings_singlephy(jesd_phy_addr);
	/* Initialize JESDs for Device rf1 */
	jesd_setup(jesd_array.tx_jesd);
	jesd_setup(jesd_array.rx_jesd);
	jesd_setup(jesd_array.orx_jesd);
	mdelay(100);
	return status;
}
/*************************************************************************/
/*****                    jesd204b_check                             *****/
/*************************************************************************/
mykonosErr_t jesd204b_check(mykonosDevice_t *device,
		jesd_core_array jesd_array) {
	mykonosErr_t retval = MYKONOS_ERR_OK;
	uint8_t framerStatus;
	uint8_t obsFramerStatus;
	uint8_t deframerStatus;
	// JESD core status for Device rf1
	uint32_t status_tx = jesd_status(jesd_array.tx_jesd);
	if (status_tx != -1)
		printf("tx_jesd_rf1 is locking!\n");
	else {
		printf("tx_jesd is error!\n");
		return MYKONOS_ERR_JESD_CONFIGURATION_FAILED;
	}
	uint32_t status_rx_rf1 = jesd_status(jesd_array.rx_jesd);
	if (status_rx_rf1 != -1)
		printf("rx_jesd_rf1 is locking!\n");
	else {
		printf("rx_jesd is error!\n");
		return MYKONOS_ERR_JESD_CONFIGURATION_FAILED;
	}
	uint32_t status_orx_rf1 = jesd_status(jesd_array.orx_jesd);
	if (status_orx_rf1 != -1)
		printf("orx_jesd, is locking!\n");
	else {
		printf("orx_jesd_rf1 is error!\n");
		return MYKONOS_ERR_JESD_CONFIGURATION_FAILED;
	}
	//Check Mykonos Framer Status for Device rf1
	if ((retval = MYKONOS_readRxFramerStatus(device, &framerStatus))
			!= MYKONOS_ERR_OK) {
		return retval;
	} else if (framerStatus != 0x3E) {
		printf("RxFramerStatus = 0x%x\n", framerStatus);
		return MYKONOS_ERR_JESD_CONFIGURATION_FAILED;
	}
	if ((retval = MYKONOS_readOrxFramerStatus(device, &obsFramerStatus))
			!= MYKONOS_ERR_OK) {
		return retval;
	} else if (obsFramerStatus != 0x3E) {
		printf("OrxFramerStatus = 0x%x\n", obsFramerStatus);
		return MYKONOS_ERR_JESD_CONFIGURATION_FAILED;
	}
	//Check Mykonos Deframer Status for Device rf1
	if ((retval = MYKONOS_readDeframerStatus(device, &deframerStatus))
			!= MYKONOS_ERR_OK) {
		return retval;
	} else if (deframerStatus != 0x68) {
		printf("DeframerStatus = 0x%x\n", deframerStatus);
		return MYKONOS_ERR_JESD_CONFIGURATION_FAILED;
	}
	return retval;
}
/*************************************************************************/
/*****                           ad9371_radio_on                     *****/
/*************************************************************************/
mykonosErr_t ad9371_radio_on(mykonosDevice_t *device) {
	mykonosErr_t retval = MYKONOS_ERR_OK;
	uint32_t trackingCalMask = TRACK_ORX1_QEC | TRACK_ORX2_QEC | TRACK_RX1_QEC
			| TRACK_RX2_QEC | TRACK_TX1_QEC | TRACK_TX2_QEC;
	//Mykonos enable tracking calibrations
	if ((retval = MYKONOS_enableTrackingCals(device, trackingCalMask))!= MYKONOS_ERR_OK) {
		return retval;
	}
	/*** < Info: Allow Rx1/2 QEC tracking and Tx1/2 QEC tracking to run when in the radioOn state
	 *  Tx calibrations will only run if radioOn and the obsRx path is set to OBS_INTERNAL_CALS > ***/
	/*** < Info: Function to turn radio on, Enables transmitters and receivers
	 * that were setup during MYKONOS_initialize() > ***/
	if ((retval = MYKONOS_radioOn(device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setRxFramerDataSource(device, 0)) != MYKONOS_ERR_OK) {
		return retval;
	}
	/*** < Info: Allow TxQEC to run when User: is not actively using ORx receive path > ***/
	if ((retval = MYKONOS_setObsRxPathSource(device, OBS_RXOFF))!= MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setObsRxPathSource(device, OBS_RX1_TXLO))!= MYKONOS_ERR_OK) {
		return retval;
	}
	if ((retval = MYKONOS_setObsRxPathSource(device, OBS_RX2_TXLO))!= MYKONOS_ERR_OK) {
		return retval;
	}
	return retval;
}
mykonosGpioErr_t ad9371_setup_auxadc_dac(mykonosDevice_t *device) {
	mykonosGpioErr_t mykGpioErr = MYKONOS_ERR_GPIO_OK;
	if ((mykGpioErr = MYKONOS_setupAuxDacs(device)) != MYKONOS_ERR_GPIO_OK) {
		return mykGpioErr;
	}
	if ((mykGpioErr = MYKONOS_setupTempSensor(device, &tempSensorsdef))!= MYKONOS_ERR_GPIO_OK) {
		return mykGpioErr;
	}
	if ((mykGpioErr = MYKONOS_setAuxAdcChannel(device, 16))!= MYKONOS_ERR_GPIO_OK) {
			return mykGpioErr;
	}
	return mykGpioErr;
}

mykonosErr_t ad9371_initial(mykonosDevice_t *mykonos_device,
		jesd_core_array jesd_array, uint32_t jesd_phy_addr) {

	mykonosErr_t retval = MYKONOS_ERR_OK;
	mykonosGpioErr_t mykGpioErr;
	//hard reset
	if ((retval = ad9371_hard_reset(mykonos_device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	//AD9371 SPI Init
	if ((retval = ad9371_init(mykonos_device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	//AD9371 rf Init PLL、Gain
	if ((retval = ad9371_rf_init(mykonos_device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	//AD9371 Calibration
	if ((retval = ad9371_init_Calibrations(mykonos_device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	//AD9371 aux_adc_dac none
	if ((mykGpioErr = ad9371_setup_auxadc_dac(mykonos_device)) != MYKONOS_ERR_GPIO_OK) {
		return retval=-1;
	}
	mdelay(1000);
	//JESD204B Init
	retval= MYKONOS_ERR_JESD_CONFIGURATION_FAILED;
	while (retval == MYKONOS_ERR_JESD_CONFIGURATION_FAILED)
	{
		//FPGA jesd204_reset = 1 : fpga jesd reset
		AXI_REG_WRITE(axi_lite_addr, 2 * 4, 1);
		//ad9371 jesd204b init by spi
		retval = ad9371_jesd204b_init(mykonos_device);
		//fpga jesd204b init by axi lite
		retval = fpga_jesd204b_init(jesd_array, jesd_phy_addr);
		//release reset : fpga no reset
		AXI_REG_WRITE(axi_lite_addr, 2 * 4, 0);
		//jesd204b check status
		retval = jesd204b_check(mykonos_device, jesd_array);
		mdelay(100);
	}
	mdelay(500);
	//ad9371 rf on
	if ((retval = ad9371_radio_on(mykonos_device)) != MYKONOS_ERR_OK) {
		return retval;
	}
	return retval;
}
