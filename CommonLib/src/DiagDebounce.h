/* DiagDebounce.h
*
* Author: Eaton
* Version: 0.7 - 7/15/2020
*
*/

#ifndef DiagDebounce_h_
#define DiagDebounce_h_

#include "rtwtypes.h"
#include "Platform_Types.h"

#define DIAGDEBOUNCE_START_SEC_CODE_Core0ASILA
#pragma ghs section text=".CODE_COMMON_EATON_CORE0"

/* function to debounce Lv1 event status */
extern void DiagDebounceLv1( sint16 *diagFaultCounter, uint8 *diagCurrState, 
                             boolean *diagPrevDbncEnable, boolean *diagDbncDisActive,  
                             boolean *diagPrestorageTrigger, boolean diagFaultActive, 
                             boolean diagStartUpComp, boolean diagReset, boolean diagEnable, 
                             boolean diagDbncEnable, sint16 diagFaultCntThresh, 
                             sint16 diagPassCntThresh, sint16 diagUpCnt, sint16 diagDnCnt, 
                             boolean diagHealEn, boolean diagPrestorageEn, boolean diagJumpDownEn );

#define DIAGDEBOUNCE_STOP_SEC_CODE_Core0ASILA
#pragma ghs section text=default

#define DIAGDEBOUNCE_START_SEC_CODE_Core0ASILB
#pragma ghs section text=".CODE_COMMON_EATON_CORE0"

/* function to debounce Lv2 fault status */
extern boolean DiagDebounceLv2( sint16 *diagFaultCounter, uint8 *diagCurrState, 
                                boolean *diagPassCntThresh, boolean diagFaultActive, 
                                boolean diagStartUpComp, boolean diagReset, 
                                sint16 diagFaultCntThresh, sint16 diagUpCnt, sint16 diagDnCnt, 
                                boolean diagHealEn );
                                
#define DIAGDEBOUNCE_STOP_SEC_CODE_Core0ASILB
#pragma ghs section text=default

#endif
