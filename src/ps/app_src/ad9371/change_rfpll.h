/*
 * change_rfpll.h
 *
 *  Created on: 2017年11月16日
 *      Author: lichen
 */

#ifndef SRC_CHANGE_RFPLL_H_
#define SRC_CHANGE_RFPLL_H_
void change_rfpll(mykonosDevice_t mykDevice, mykonosRfPllName_t pllName,
		uint64_t new_freq);

#endif /* SRC_CHANGE_RFPLL_H_ */
