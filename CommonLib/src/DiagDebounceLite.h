/* DiagDebounceLite.h
*
* Implements lite debounce counter diagnostics blocks
* Author: Eaton
* Version: 1.0 - 8/31/2023
*
*/

#ifndef DiagDebounceLite_h_
#define DiagDebounceLite_h_

#include <stdbool.h>
#include "rtwtypes.h"

/* function to debounce Lv1 event status */
extern void DiagDebounceLite(int16_T* diagFaultCounter,unsigned char* diagCurrState,
                  bool diagFaultActive, bool diagReset,
                  int16_T diagFaultCntThresh, int16_T diagPassCntThresh,
                  int16_T diagUpCnt, int16_T diagDnCnt, bool diagHealEn);
#endif