/***************************************************************************//**
 *   @file   ad9371/src/devices/adi_hal/parameters.h
 *   @brief  Platform dependent parameters.
 *   @author DBogdan (dragos.bogdan@analog.com)
********************************************************************************
 * Copyright 2019(c) Analog Devices, Inc.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of Analog Devices, Inc. nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES, INC. 鈥淎S IS鈥� AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ANALOG DEVICES, INC. BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*******************************************************************************/
#ifndef _PARAMETERS_H_
#define _PARAMETERS_H_

/******************************************************************************/
/***************************** Include Files **********************************/
/******************************************************************************/
#include "xparameters.h"

/******************************************************************************/
/********************** Macros and Constants Definitions **********************/

#ifdef SDT

#define SPI_BASEADDR    XPAR_XSPIPS_0_BASEADDR
#define GPIO_BASEADDR   XPAR_XGPIOPS_0_BASEADDR

/* SDT LookupConfig APIs use base addresses. */
#define GPIO_DEVICE_ID  GPIO_BASEADDR
#define SPI_DEVICE_ID   0U
#define UART_DEVICE_ID  XPAR_XUARTPS_0_BASEADDR

#else

#define SPI_BASEADDR    XPAR_PS7_SPI_0_BASEADDR
#define GPIO_BASEADDR   XPAR_PS7_GPIO_0_BASEADDR

#define GPIO_DEVICE_ID  XPAR_PS7_GPIO_0_DEVICE_ID
#define SPI_DEVICE_ID   XPAR_PS7_SPI_0_DEVICE_ID
#define UART_DEVICE_ID  XPAR_XUARTPS_1_DEVICE_ID

#endif

#define								XILINX

#define AD9528_CS					1
#define AD9371_CS					2

#define GPIO_OFFSET		  			54

#define ADRV_RESETB       			GPIO_OFFSET + 1
#define ADRV_TEST         			GPIO_OFFSET + 2
#define ADRV_RX2_ENABLE   			GPIO_OFFSET + 3
#define ADRV_RX1_ENABLE   			GPIO_OFFSET + 4
#define ADRV_TX2_ENABLE   			GPIO_OFFSET + 5
#define ADRV_TX1_ENABLE   			GPIO_OFFSET + 6
#define AD9528_SYSREQ         		GPIO_OFFSET + 7
#define AD9528_RESRT		  		GPIO_OFFSET + 8
#define AD9528_CS_PIN	        	GPIO_OFFSET + 9
#define AD9371_CS_PIN			  	GPIO_OFFSET + 10


#endif
