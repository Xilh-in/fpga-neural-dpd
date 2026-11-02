#include <stdint.h>
#include <stdio.h>
#include "mykonos.h"
//extern mykonosDevice_t mykDevice;
mykonosErr_t mykError;
const char *errorString;
uint8_t pllLockStatus;
uint32_t initCalMask = TX_QEC_INIT | LOOPBACK_RX_LO_DELAY
		| LOOPBACK_RX_RX_QEC_INIT | RX_LO_DELAY | RX_QEC_INIT;
uint8_t errorFlag = 0;
uint8_t errorCode = 0;
uint32_t initCalsCompleted;
uint8_t status;


void change_rfpll(mykonosDevice_t mykDevice, mykonosRfPllName_t pllName, uint64_t new_freq) {
	uint64_t parent_freq;
	MYKONOS_getRfPllFrequency(&mykDevice, pllName, &parent_freq);
	if (new_freq < parent_freq + 100e6 && new_freq > parent_freq - 100e6)
	//change RF freq less than 100MHz
			{
		if ((mykError = MYKONOS_radioOff(&mykDevice)) != MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
		if ((mykError = MYKONOS_setRfPllFrequency(&mykDevice, pllName, new_freq))
				!= MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
		/*** < Action: wait 200ms for PLLs to lock > ***/
		if ((mykError = MYKONOS_resetExtTxLolChannel(&mykDevice, TX1_TX2))
				!= MYKONOS_ERR_OK)
			; //where TX1_TX2 is part of the enum mykonosTxChannels_t
		{
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
		if ((mykError = MYKONOS_radioOn(&mykDevice)) != MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
	} else {
		if ((mykError = MYKONOS_radioOff(&mykDevice)) != MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
		if ((mykError = MYKONOS_setRfPllFrequency(&mykDevice, pllName, new_freq))
				!= MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
		/*** < Action: wait 200ms for PLLs to lock > ***/
		if ((mykError = MYKONOS_checkPllsLockStatus(&mykDevice, &pllLockStatus))
				!= MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
		if ((pllLockStatus & 0x0F) == 0x07) {
			/*** < Info: Clock, Rx and Tx PLLs locked > ***/
		} else {
			/*** < Info: Clock, Rx and Tx PLLs not locked > ***/
			/*** < Action: Ensure lock before proceeding - User code here > ***/
		}
		if ((mykError = MYKONOS_runInitCals(&mykDevice, initCalMask))
				!= MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
		if ((mykError = MYKONOS_waitInitCals(&mykDevice, 60000, &errorFlag,
				&errorCode)) != MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
		mykonosInitCalStatus_t initCalStatus;
		uint16_t errorWord;
		uint16_t statusWord;
		if ((errorFlag != 0) || (errorCode != 0)) {
			if ((mykError = MYKONOS_getInitCalStatus(&mykDevice, &initCalStatus))
					!= MYKONOS_ERR_OK) {
				/*** < Info: errorString will contain log error string in order to debug failure > ***/
				errorString = getMykonosErrorMessage(mykError);
			}
			/*** < Info: abort init cals > ***/
			if ((mykError = MYKONOS_abortInitCals(&mykDevice,
					&initCalsCompleted)) != MYKONOS_ERR_OK) {
				/*** < Info: errorString will contain log error string in order to debug failure > ***/
				errorString = getMykonosErrorMessage(mykError);
			}
			if (initCalsCompleted) {
				/*** < Info: which calls had completed, per the mask > ***/
			}
			if ((mykError = MYKONOS_readArmCmdStatus(&mykDevice, &errorWord,
					&statusWord)) != MYKONOS_ERR_OK) {
				/*** < Info: errorString will contain log error string in order to debug failure > ***/
				errorString = getMykonosErrorMessage(mykError);
			}
			if ((mykError = MYKONOS_readArmCmdStatusByte(&mykDevice, 2, &status))
					!= MYKONOS_ERR_OK) {
				/*** < Info: errorString will contain log error string in order to debug why failed > ***/
				errorString = getMykonosErrorMessage(mykError);
			}
			if (status != 0) {
				/*** < Info: Arm Mailbox Status Error errorWord > ***/
				/*** < Info: Pending Flag per opcode statusWord, this follows the mask > ***/
			}
		} else {
			/*** < Info: Calibrations completed successfully > ***/
		}
		if ((mykError = MYKONOS_radioOn(&mykDevice)) != MYKONOS_ERR_OK) {
			/*** < Info: errorString will contain log error string in order to debug failure > ***/
			errorString = getMykonosErrorMessage(mykError);
		}
	}
	if (pllName == TX_PLL)
		printf("change_rfpll TX freq %lldHz ok!\r\n", new_freq);
	else
		printf("change_rfpll RX freq %lldHz ok!\r\n", new_freq);

}
