/**
 * \file common.c
 * \brief Contains Mykonos API common wrapper functions for user hardware platform drivers
 */

/**
* Legal Disclaimer
* Copyright 2015-2017 Analog Devices Inc.
* Released under the AD9371 API license, for more information see the "LICENSE.txt" file in this zip file.
*
*/

#include <stdio.h>
#include <time.h>
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include "common.h"
#include "no_os_spi.h"
#include "xilinx_gpio.h"
#include "no_os_delay.h"
#include "no_os_gpio.h"
#include "parameters.h"

#ifndef ALTERA_PLATFORM
#include <xparameters.h>
#include "xilinx_spi.h"
#else
#include "altera_spi.h"
#endif

ADI_LOGLEVEL CMB_LOGLEVEL = ADIHAL_LOG_NONE;

static uint32_t _desired_time_to_elapse_us = 0;
struct no_os_spi_desc 	*spi_ad_desc;
struct no_os_gpio_desc	*gpio_ad9371_resetb;
struct no_os_gpio_desc	*gpio_ad9528_resetb;
struct no_os_gpio_desc	*gpio_ad9528_sysref_req;

struct no_os_gpio_desc	*gpio_ad9371_test;
struct no_os_gpio_desc	*gpio_ad9371_rx2_enable;
struct no_os_gpio_desc	*gpio_ad9371_rx1_enable;
struct no_os_gpio_desc	*gpio_ad9371_tx2_enable;
struct no_os_gpio_desc	*gpio_ad9371_tx1_enable;

struct no_os_gpio_desc	*gpio_ad9528_cs;
struct no_os_gpio_desc	*gpio_ad9371_cs;


int32_t platform_init(void)
{

	struct no_os_spi_init_param spi_param = {0};
	struct no_os_gpio_init_param gpio_ad9371_resetb_param;
	struct no_os_gpio_init_param gpio_ad9528_resetb_param;
	struct no_os_gpio_init_param gpio_ad9528_sysref_param;

	struct no_os_gpio_init_param gpio_ad9371_test_param;
	struct no_os_gpio_init_param gpio_ad9371_rx2_enable_param;
	struct no_os_gpio_init_param gpio_ad9371_rx1_enable_param;
	struct no_os_gpio_init_param gpio_ad9371_tx2_enable_param;
	struct no_os_gpio_init_param gpio_ad9371_tx1_enable_param;

	struct no_os_gpio_init_param gpio_ad9528_cs_param;
	struct no_os_gpio_init_param gpio_ad9371_cs_param;

	int32_t status = 0;

	gpio_ad9371_cs_param.number = AD9371_CS_PIN;
	gpio_ad9528_cs_param.number = AD9528_CS_PIN;

	gpio_ad9371_resetb_param.number = ADRV_RESETB;
	gpio_ad9528_resetb_param.number = AD9528_RESRT;
	gpio_ad9528_sysref_param.number = AD9528_SYSREQ;

	gpio_ad9371_test_param.number = ADRV_TEST;
	gpio_ad9371_rx2_enable_param.number = ADRV_RX2_ENABLE;
	gpio_ad9371_rx1_enable_param.number = ADRV_RX1_ENABLE;
	gpio_ad9371_tx2_enable_param.number = ADRV_TX2_ENABLE;
	gpio_ad9371_tx1_enable_param.number = ADRV_TX1_ENABLE;



	struct xil_spi_init_param xilinx_spi_param = {
		.type = SPI_PS,
		.flags = SPI_CS_DECODE
	};

	struct xil_gpio_init_param xilinx_gpio_param = {
		.type = GPIO_PS,
		.device_id = GPIO_DEVICE_ID
	};

	spi_param.device_id = SPI_DEVICE_ID;
	spi_param.extra = &xilinx_spi_param;
	spi_param.platform_ops = &xil_spi_ops;

	gpio_ad9371_cs_param.platform_ops = &xil_gpio_ops;
	gpio_ad9371_cs_param.extra = &xilinx_gpio_param;
	gpio_ad9528_cs_param.platform_ops = &xil_gpio_ops;
	gpio_ad9528_cs_param.extra = &xilinx_gpio_param;

	gpio_ad9371_resetb_param.platform_ops = &xil_gpio_ops;
	gpio_ad9371_resetb_param.extra = &xilinx_gpio_param;
	gpio_ad9528_resetb_param.platform_ops = &xil_gpio_ops;
	gpio_ad9528_resetb_param.extra = &xilinx_gpio_param;
	gpio_ad9528_sysref_param.platform_ops = &xil_gpio_ops;
	gpio_ad9528_sysref_param.extra = &xilinx_gpio_param;

	gpio_ad9371_test_param.platform_ops = &xil_gpio_ops;
	gpio_ad9371_test_param.extra = &xilinx_gpio_param;
	gpio_ad9371_rx2_enable_param.platform_ops = &xil_gpio_ops;
	gpio_ad9371_rx2_enable_param.extra = &xilinx_gpio_param;
	gpio_ad9371_rx1_enable_param.platform_ops = &xil_gpio_ops;
	gpio_ad9371_rx1_enable_param.extra = &xilinx_gpio_param;
	gpio_ad9371_tx2_enable_param.platform_ops = &xil_gpio_ops;
	gpio_ad9371_tx2_enable_param.extra = &xilinx_gpio_param;
	gpio_ad9371_tx1_enable_param.platform_ops = &xil_gpio_ops;
	gpio_ad9371_tx1_enable_param.extra = &xilinx_gpio_param;


	status |= no_os_gpio_get(&gpio_ad9371_cs, &gpio_ad9371_cs_param);
	status |= no_os_gpio_get(&gpio_ad9528_cs, &gpio_ad9528_cs_param);
	status = no_os_gpio_get(&gpio_ad9371_resetb, &gpio_ad9371_resetb_param);
	status |= no_os_gpio_get(&gpio_ad9528_resetb, &gpio_ad9528_resetb_param);
	status |= no_os_gpio_get(&gpio_ad9528_sysref_req, &gpio_ad9528_sysref_param);

	status |= no_os_gpio_get(&gpio_ad9371_test, &gpio_ad9371_test_param);
	status |= no_os_gpio_get(&gpio_ad9371_rx2_enable, &gpio_ad9371_rx2_enable_param);
	status |= no_os_gpio_get(&gpio_ad9371_rx1_enable, &gpio_ad9371_rx1_enable_param);
	status |= no_os_gpio_get(&gpio_ad9371_tx2_enable, &gpio_ad9371_tx2_enable_param);
	status |= no_os_gpio_get(&gpio_ad9371_tx1_enable, &gpio_ad9371_tx1_enable_param);

	no_os_gpio_direction_output(gpio_ad9528_cs, 1);
	no_os_gpio_direction_output(gpio_ad9371_cs, 1);

	no_os_gpio_direction_output(gpio_ad9371_test, 0);
	no_os_gpio_direction_output(gpio_ad9371_rx2_enable, 1);
	no_os_gpio_direction_output(gpio_ad9371_rx1_enable, 1);
	no_os_gpio_direction_output(gpio_ad9371_tx1_enable, 1);
	no_os_gpio_direction_output(gpio_ad9371_tx2_enable, 1);
	no_os_gpio_direction_output(gpio_ad9528_sysref_req, 0);


	spi_param.mode = NO_OS_SPI_MODE_0;
	spi_param.chip_select = AD9371_CS;
	spi_param.max_speed_hz = 2000000u;

	status |= no_os_spi_init(&spi_ad_desc, &spi_param);

	return status;
}

int32_t platform_remove(void)
{
	int32_t status;

	status = no_os_gpio_remove(gpio_ad9371_resetb);
	status |= no_os_gpio_remove(gpio_ad9528_resetb);
	status |= no_os_gpio_remove(gpio_ad9528_sysref_req);

	status |= no_os_spi_remove(spi_ad_desc);

	return status;
}

commonErr_t CMB_closeHardware(void)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_setGPIO(uint32_t GPIO)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_hardReset(uint8_t spiChipSelectIndex)
{
	struct no_os_gpio_desc *reset_gpio;

	switch (spiChipSelectIndex) {
	case AD9371_CS:
		reset_gpio = gpio_ad9371_resetb;
		break;
	case AD9528_CS:
		reset_gpio = gpio_ad9528_resetb;
		break;
	default:
		return(COMMONERR_FAILED);
	}

	no_os_gpio_direction_output(reset_gpio, 1);
	CMB_wait_ms(1);
	no_os_gpio_direction_output(reset_gpio, 0);
	CMB_wait_ms(1);
	no_os_gpio_direction_output(reset_gpio, 1);
	CMB_wait_ms(1);

	return(COMMONERR_OK);
}

commonErr_t CMB_setSPIOptions(spiSettings_t *spiSettings)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_setSPIChannel(uint16_t chipSelectIndex )
{
	return(COMMONERR_OK);
}

commonErr_t CMB_SPIWriteByte(spiSettings_t *spiSettings, uint16_t addr,
			     uint8_t data)
{
	uint8_t buf[3];


	switch (spiSettings->chipSelectIndex) {
	case AD9371_CS:
		no_os_gpio_direction_output(gpio_ad9371_cs, 0);
		break;
	case AD9528_CS:
		no_os_gpio_direction_output(gpio_ad9528_cs, 0);
		break;
	default:
		return(COMMONERR_FAILED);
	}

	buf[0] = (uint8_t) ((addr >> 8) & 0x7f);
	buf[1] = (uint8_t) (addr & 0xff);
	buf[2] = (uint8_t) data;

	// spi_ad_desc->chip_select = spiSettings->chipSelectIndex - 1;
	spi_ad_desc->chip_select = 1 - 1;
	no_os_spi_write_and_read(spi_ad_desc, buf, 3);

	switch (spiSettings->chipSelectIndex) {
	case AD9371_CS:
		no_os_gpio_direction_output(gpio_ad9371_cs, 1);
		break;
	case AD9528_CS:
		no_os_gpio_direction_output(gpio_ad9528_cs, 1);
		break;
	default:
		return(COMMONERR_FAILED);
	}

	return(COMMONERR_OK);
}

commonErr_t CMB_SPIWriteBytes(spiSettings_t *spiSettings, uint16_t *addr,
			      uint8_t *data, uint32_t count)
{
	uint32_t index;

	for (index = 0; index < count; index++)
		if (CMB_SPIWriteByte(spiSettings, *(addr + index),
				     *(data + index)) != COMMONERR_OK)
			return(COMMONERR_FAILED);

	return(COMMONERR_OK);
}

commonErr_t CMB_SPIReadByte(spiSettings_t *spiSettings, uint16_t addr,
			    uint8_t *readdata)
{
	uint8_t buf[3];

	switch (spiSettings->chipSelectIndex) {
	case AD9371_CS:
		no_os_gpio_direction_output(gpio_ad9371_cs, 0);
		break;
	case AD9528_CS:
		no_os_gpio_direction_output(gpio_ad9528_cs, 0);
		break;
	default:
		return(COMMONERR_FAILED);
	}

//	spi_ad_desc->chip_select = spiSettings->chipSelectIndex -1 ;
	spi_ad_desc->chip_select = 1 - 1 ;

	buf[0] = (uint8_t) ((addr >> 8) | 0x80);
	buf[1] = (uint8_t) (addr & 0xff);
	buf[2] = (uint8_t) 0x00;

	no_os_spi_write_and_read(spi_ad_desc, buf, 3);
	*readdata = buf[2];

	switch (spiSettings->chipSelectIndex) {
	case AD9371_CS:
		no_os_gpio_direction_output(gpio_ad9371_cs, 1);
		break;
	case AD9528_CS:
		no_os_gpio_direction_output(gpio_ad9528_cs, 1);
		break;
	default:
		return(COMMONERR_FAILED);
	}

	return(COMMONERR_OK);
}

commonErr_t CMB_SPIWriteField(spiSettings_t *spiSettings, uint16_t addr,
			      uint8_t field_val, uint8_t mask, uint8_t start_bit)
{
	uint8_t data;

	if (CMB_SPIReadByte(spiSettings, addr, &data) != COMMONERR_OK)
		return(COMMONERR_FAILED);

	data = (data & ~mask) | ((field_val << start_bit) & mask);

	if (CMB_SPIWriteByte(spiSettings, addr, data) != COMMONERR_OK)
		return(COMMONERR_FAILED);

	return(COMMONERR_OK);
}

/* read a field in a single register space (not multibyte fields) */
commonErr_t CMB_SPIReadField(spiSettings_t *spiSettings, uint16_t addr,
			     uint8_t *field_val, uint8_t mask, uint8_t start_bit)
{
	uint8_t data;

	if (CMB_SPIReadByte(spiSettings, addr, &data) != COMMONERR_OK)
		return(COMMONERR_FAILED);

	data = (data & mask) >> start_bit;
	*field_val = data;

	return(COMMONERR_OK);
}

commonErr_t CMB_writeToLog(ADI_LOGLEVEL level, uint8_t deviceIndex,
			   uint32_t errorCode, const char *comment)
{

	if((CMB_LOGLEVEL & ADIHAL_LOG_ERROR) && (level == ADIHAL_LOG_ERROR)) {
		xil_printf("ERROR: %d: %s", (int)errorCode, comment);
	} else if((CMB_LOGLEVEL & ADIHAL_LOG_WARNING)
		  && (level == ADIHAL_LOG_WARNING)) {
		xil_printf("WARNING: %d: %s",(int)errorCode, comment);
	} else if((CMB_LOGLEVEL & ADIHAL_LOG_MESSAGE)
		  && (level == ADIHAL_LOG_MESSAGE)) {
		xil_printf("MESSAGE: %d: %s",(int)errorCode, comment);
	} else if(CMB_LOGLEVEL == ADIHAL_LOG_NONE ) {
		//printf("MESSAGE: %d: %s",(int)errorCode, comment);
	} else {
		xil_printf("Undefined Log Level: 0x%X", level);
	}

	return(COMMONERR_OK);
}

/* if filename null, a default path will be used in logging.c */
commonErr_t CMB_openLog(const char *filename)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_closeLog(void)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_flushLog(void)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_wait_ms(uint32_t time_ms)
{
	mdelay(time_ms);

	return(COMMONERR_OK);
}

commonErr_t CMB_wait_us(uint32_t time_us)
{
	udelay(time_us);

	return(COMMONERR_OK);
}

commonErr_t CMB_setTimeout_ms(uint32_t timeOut_ms)
{
    _desired_time_to_elapse_us = timeOut_ms * 1000U;

    return COMMONERR_OK;
}

commonErr_t CMB_setTimeout_us(uint32_t timeOut_us)
{
	_desired_time_to_elapse_us = timeOut_us;

	return(COMMONERR_OK);
}

commonErr_t CMB_hasTimeoutExpired()
{
	udelay(1);

	_desired_time_to_elapse_us--;
	if (_desired_time_to_elapse_us > 0)
		return(COMMONERR_OK);

	return(COMMONERR_FAILED);
}

commonErr_t CMB_regRead(uint32_t offset, uint32_t *data)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_regWrite(uint32_t offset, uint32_t data)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_memRead(uint32_t offset, uint32_t *data, uint32_t len)
{
	return(COMMONERR_OK);
}

commonErr_t CMB_memWrite(uint32_t offset, uint32_t *data, uint32_t len)
{
	return(COMMONERR_OK);
}
