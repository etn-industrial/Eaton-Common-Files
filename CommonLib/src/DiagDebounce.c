/*  DiagDebounce.c
*
* Implements debounce counter for Lv1 and Lv2 diagnostics blocks
* Author:  Eaton
* Version: 0.7 - 7/15/2020
*
*/

#include "DiagDebounce.h"

/* Lv1 event status type */
typedef enum {
	DEM_EVENT_STATUS_PASSED     = 0U,
    DEM_EVENT_STATUS_FAILED     = 1U,
    DEM_EVENT_STATUS_PREPASSED  = 2U,
    DEM_EVENT_STATUS_PREFAILED  = 3U,
    DEM_EVENT_STATUS_INIT       = 32U	
	
} DemEventStatusType;

/* Lv2 status type */
typedef enum {
    INITSTATE   = 0U, 
    FAULTSTATE  = 1U, 
    PASSSTATE   = 2U
    
} Lv2StatusType;

#define DIAGDEBOUNCE_START_SEC_VAR_Core0ASILA
#pragma ghs section rosdata=".CONST_CFG_UNSPECIFIED_COMMON_EATON_CORE0"
/* constants */
const boolean TEST_PASS   = false;
const boolean TEST_FAILED = true; 
const sint16 INIT_COUNTER = 0; 
#define DIAGDEBOUNCE_STOP_SEC_VAR_Core0ASILA
#pragma ghs section rosdata=default

#define DIAGDEBOUNCE_START_SEC_VAR_Core0ASILB
#pragma ghs section rosdata=".CONST_CFG_UNSPECIFIED_COMMON_EATON_CORE0"
const sint16 INIT_COUNTER_LV2 = 0; 
#define DIAGDEBOUNCE_STOP_SEC_VAR_Core0ASILB
#pragma ghs section rosdata=default

#define DIAGDEBOUNCE_START_SEC_CODE_Core0ASILA
#pragma ghs section text=".CODE_COMMON_EATON_CORE0"
/* function protype */
static DemEventStatusType diagDbncDisabled( boolean diagPrevDbEnable, 
                                            boolean *diagDbncDisActive, boolean diagFaultActive,  
                                            boolean diagStartUpComp, boolean diagReset, 
                                            boolean diagEnable );
#define DIAGDEBOUNCE_STOP_SEC_CODE_Core0ASILA
#pragma ghs section text=default

#define DIAGDEBOUNCE_START_SEC_CODE_Core0ASILA
#pragma ghs section text=".CODE_COMMON_EATON_CORE0"
/* function to debounce Lv1 event status */
void DiagDebounceLv1( sint16 *diagFaultCounter, uint8 *diagCurrState, 
                      boolean *diagPrevDbncEnable, boolean *diagDbncDisActive,  
                      boolean *diagPrestorageTrigger, boolean diagFaultActive, 
                      boolean diagStartUpComp, boolean diagReset, boolean diagEnable, 
                      boolean diagDbncEnable, sint16 diagFaultCntThresh, 
                      sint16 diagPassCntThresh, sint16 diagUpCnt, sint16 diagDnCnt, 
                      boolean diagHealEn, boolean diagPrestorageEn, boolean diagJumpDownEn )
{  
    /* init currState */    
    DemEventStatusType currState = (DemEventStatusType)( *diagCurrState );
    
    /* comment out below for timing purpose */
    /* if( diagFaultCounter == NULL || diagCurrState == NULL || 
           diagPrevDbncEnable == NULL || diagPrestorageTrigger == NULL )
    {        
        return (uint8)(DEM_EVENT_STATUS_FAILED); 
    } */
    
    
	if( diagDbncEnable == false )
	{
        /* process fault status when debounce is disabled */
		currState = diagDbncDisabled( *diagPrevDbncEnable, diagDbncDisActive,  
                                      diagFaultActive, diagStartUpComp, diagReset, diagEnable );        
	}
	else 
    {
        if( diagDbncEnable != *diagPrevDbncEnable )
        {
            /* if debounce is just enabled, set event status to init */ 
            currState = DEM_EVENT_STATUS_INIT;   

            /* reset counter */
            *diagFaultCounter = INIT_COUNTER; 
        }
     
        /* diagCurrState is the global state that is retained across loops */
        switch( currState )
        {
            case DEM_EVENT_STATUS_INIT:    
                
                if( diagPrestorageEn == true )
                {
                    /* init diagPrestorageTrigger to false */
                    *diagPrestorageTrigger = false;
                }
                               
                if( ( diagStartUpComp == false ) || 
                    ( diagReset == true ) || ( diagEnable == false ) )
                {
                    /* reset counter */
                    *diagFaultCounter = INIT_COUNTER;                   
                }
                else if( diagFaultActive == false )
                {
                    /* decrement fault counter */
                    *diagFaultCounter = *diagFaultCounter - diagDnCnt;
                    if( *diagFaultCounter <= diagPassCntThresh ) 
                    {
                        /* update to passed */
                        currState = DEM_EVENT_STATUS_PASSED; 
                        
                        /* set count to diagPassCntThresh */
                        *diagFaultCounter = diagPassCntThresh; 
                    }
                }
                else /* diagFaultActive == true */ 
                {
                    /* increment fault counter */
                    *diagFaultCounter = *diagFaultCounter + diagUpCnt;
                    if( *diagFaultCounter >= diagFaultCntThresh ) 
                    {
                        /* update to failed */
                        currState = DEM_EVENT_STATUS_FAILED; 
                        
                        /* set count to diagFaultCntThresh */
                        *diagFaultCounter = diagFaultCntThresh; 
                    }                    
                }
                break;

            case DEM_EVENT_STATUS_FAILED:
                
                if( diagPrestorageEn == true && *diagPrestorageTrigger == true )
                {
                    /* set diagPrestorageTrigger to false */
                    *diagPrestorageTrigger = false;
                }

                if( ( diagReset == true ) || ( diagEnable == false ) )
                {                     
                    /* update to init */
                    currState = DEM_EVENT_STATUS_INIT;
                    
                    /* reset counter */
                    *diagFaultCounter = INIT_COUNTER; 
                }
                else if( diagFaultActive == false )
                {
                    /* check if healing is enabled */
                    if( diagHealEn == true )
                    {
                        if( ( *diagFaultCounter > INIT_COUNTER ) && ( diagJumpDownEn == true ) )
                        {                            
                            /* set to jump down counter */
                            *diagFaultCounter = INIT_COUNTER;                             
                        }
                        /* decrement fault counter */
                        *diagFaultCounter = *diagFaultCounter - diagDnCnt;
                        if( *diagFaultCounter <= diagPassCntThresh ) 
                        {
                            /* update to passed */
                            currState = DEM_EVENT_STATUS_PASSED; 
                            
                            /* set to diagPassCntThresh */
                            *diagFaultCounter = diagPassCntThresh;                                                      
                        }
                    }                    
                } 
                else /* diagFaultActive == true */ 
                {
					if(*diagFaultCounter < INIT_COUNTER)
                    {                            
                            /* reset counter when PASSTHD < Counter < INIT and fault becomes active*/
                            *diagFaultCounter = INIT_COUNTER;                             
                    }      
                    /* only increment the counter when it is below the failed threshold 
                       due to oscillation */
                    if (*diagFaultCounter <= diagFaultCntThresh)
                    {
                        /* increment the counter by diagUpCnt */
                        *diagFaultCounter = *diagFaultCounter + diagUpCnt; 
                        
                        /* check if the counter has been incremented beyond the fault threshold, 
                           if so saturate at the fault threshold */
                        if (*diagFaultCounter > diagFaultCntThresh)
                        {
                            *diagFaultCounter = diagFaultCntThresh;
                        }
					}             
                }

                break;

            case DEM_EVENT_STATUS_PASSED:
                
                if( diagPrestorageEn == true && *diagPrestorageTrigger == true )
                {
                    /* set diagPrestorageTrigger to false */
                    *diagPrestorageTrigger = false;
                }

                if( ( diagReset == true ) || ( diagEnable == false ) )
                {                     
                    /* update to init */
                    currState = DEM_EVENT_STATUS_INIT;
                    
                    /* reset counter */
                    *diagFaultCounter = INIT_COUNTER; 
                }
                else if( diagFaultActive == false )
                {
                    /* only decrement the counter when it is above the pass threshold 
                       due to oscillation */
                    if (*diagFaultCounter >= diagPassCntThresh)
                    {
                        /* decrement the counter by diagDnCnt */
                        *diagFaultCounter = *diagFaultCounter - diagDnCnt; 

                        /* check if the counter has been decremented beyond the passed threshold, 
                           if so saturate at the passed threshold */
                        if (*diagFaultCounter < diagPassCntThresh)
                        {
                            *diagFaultCounter = diagPassCntThresh;
                        }
                    }
                }
                else /* diagFaultActive == true */
                {
                    if( diagPrestorageEn == true && *diagFaultCounter == diagPassCntThresh )
                    {                        
                        /* enable prestorage trigger */
                        *diagPrestorageTrigger = true;
                    }
                    
                    if( *diagFaultCounter < INIT_COUNTER )
                    {
                        /* set fault counter to jump up value */
                        *diagFaultCounter = INIT_COUNTER;
                    }
                    
                    /* increment fault counter */
                    *diagFaultCounter = *diagFaultCounter + diagUpCnt;
                    if( *diagFaultCounter >= diagFaultCntThresh ) 
                    {
                        /* update to failed */
                        currState = DEM_EVENT_STATUS_FAILED; 
                        
                        /* set to fault threshold counter */
                        *diagFaultCounter = diagFaultCntThresh;                        
                    }                    
                }                                   
                break;

            default:
                /* should not be possible to get here, if you get to this state a fault 
                   should be thrown */
                currState = DEM_EVENT_STATUS_FAILED;               
                break;
        }
	}
    
    /* remember the debounce enable state */
    *diagPrevDbncEnable = diagDbncEnable;
    
    /* update diagCurrState */
    *diagCurrState = (uint8)currState;
    
}
#define DIAGDEBOUNCE_STOP_SEC_CODE_Core0ASILA
#pragma ghs section text=default

#define DIAGDEBOUNCE_START_SEC_CODE_Core0ASILA
#pragma ghs section text=".CODE_COMMON_EATON_CORE0"
/* function to debounce Lv1 event status when debounce is disabled */
static DemEventStatusType diagDbncDisabled( boolean diagPrevDbEnable, 
                                            boolean *diagDbncDisActive, boolean diagFaultActive,  
                                            boolean diagStartUpComp, boolean diagReset, 
                                            boolean diagEnable )
{
    /* init currState */    
    DemEventStatusType currState = DEM_EVENT_STATUS_INIT;
    
    if( *diagDbncDisActive == false )
    {       
        /* debounce disable is active */
        *diagDbncDisActive = true;
        
    }
    else if( ( diagPrevDbEnable == true ) || (diagStartUpComp == false) || 
        (diagEnable == false) || (diagReset == true)  )
    {
        /* init status */
        currState = DEM_EVENT_STATUS_INIT;
    }    
    else if ( diagFaultActive == false )
    {
        /* fault inactive */
        currState = DEM_EVENT_STATUS_PREPASSED;        
    }
    else
    {
        /* fault active */
        currState = DEM_EVENT_STATUS_PREFAILED;         
    }  
    
    return currState;   
}
#define DIAGDEBOUNCE_STOP_SEC_CODE_Core0ASILA
#pragma ghs section text=default

#define DIAGDEBOUNCE_START_SEC_CODE_Core0ASILB
#pragma ghs section text=".CODE_COMMON_EATON_CORE0"
/* function to debounce Lv2 fault status */
boolean DiagDebounceLv2(sint16 *diagFaultCounter, uint8 *diagCurrState, boolean *diagPassCntThresh, 
                        boolean diagFaultActive, boolean diagStartUpComp, boolean diagReset, 
                        sint16 diagFaultCntThresh, sint16 diagUpCnt, sint16 diagDnCnt, 
                        boolean diagHealEn)
{  
    /* init currState */    
    Lv2StatusType currState = (Lv2StatusType)( *diagCurrState );
    
    /* init return to TEST_FAILED */
    boolean testStatus = TEST_FAILED; 
    
    /* comment out below for timing purpose */
    /* if( diagFaultCounter == NULL || diagCurrState == NULL || diagPassCntThresh == NULL )
    {
        return TEST_FAILED; 
    } */

   /* diagCurrState is retained across loops */
    switch (currState)
    {
        case INITSTATE:

            /* reset counter */
            *diagFaultCounter = INIT_COUNTER_LV2; 

            /* switch to pass state once startup is complete and diag reset is false */
            if ((diagStartUpComp == true) && (diagReset == false))
            {
                currState = PASSSTATE; 
            }

            /* TEST_PASS should always be set at init */
            testStatus = TEST_PASS;
            break;

        case FAULTSTATE:

            /* init test status to failed, will only be changed once pass is confirmed */
            testStatus = TEST_FAILED; 

            /* check if reset has been triggered, if not check if counter should be adjusted */
            if (diagReset == true)
            {
                 currState = INITSTATE; 
            }
            else /* reset is inactive, need to update the counter */
            {
                /* first check if fault is active (most likely in fault state) */
                if (diagFaultActive == true)
                {
                    /* only increment the counter when it is below the failed threshold */
                    if (*diagFaultCounter <= diagFaultCntThresh)
                    {
                        *diagFaultCounter = *diagFaultCounter + diagUpCnt; 

                        /* check if the counter has been incremented beyond the fault threshold, 
                           if so saturate at the fault threshold */
                        if (*diagFaultCounter > diagFaultCntThresh)
                        {
                            *diagFaultCounter = diagFaultCntThresh;
                        }
                    }
                }
                else /* fault is not active, need to decrement the counter */
                {
                    /* only decerement counter if healing is enabled */
                    if (diagHealEn == true)
                    {
                        *diagFaultCounter = *diagFaultCounter - diagDnCnt; 
                        
                        /* check if below threshold */
                        if (*diagFaultCounter <= *diagPassCntThresh) 
                        {
                            currState = PASSSTATE; 
                            testStatus = TEST_PASS;  
                            *diagFaultCounter = *diagPassCntThresh;
                        }
                    }
                }
            }

            break;

        case PASSSTATE:
        
            /* init test status to passed */
            testStatus = TEST_PASS; 

            /* check if reset has been triggered, if not check if counter should be adjusted */
            if (diagReset == true)
            {
                currState = INITSTATE; 
            }
            else /* reset is inactive, need to update the counter */
            {
                /* first check if fault is inactive */
                if (diagFaultActive == false)
                {
                    /* only decrement the counter when it is above the pass threshold */
                    if (*diagFaultCounter >= *diagPassCntThresh)
                    {
                        *diagFaultCounter = *diagFaultCounter - diagDnCnt; 

                        /* check if the counter has been decremented beyond the passed threshold, 
                           if so saturate at the passed threshold */
                        if (*diagFaultCounter < *diagPassCntThresh)
                        {
                            *diagFaultCounter = *diagPassCntThresh;
                        }
                    }
                }

                else /* fault is present, need to increment the counter */
                {
                    *diagFaultCounter = *diagFaultCounter + diagUpCnt; 

                    /* check if above threshold */
                    if (*diagFaultCounter >= diagFaultCntThresh) 
                    {
                        currState = FAULTSTATE; 
                        
                        /* update the test status to failed */
                        testStatus = TEST_FAILED;  
                        *diagFaultCounter = diagFaultCntThresh;
                    }
                }
            }

          break;

        default:
            
          /* should not be possible to get here, if you get to this state 
             a fault should be thrown */
          testStatus = TEST_FAILED;
          break;
   }  
   
   /* update diagCurrState */
   *diagCurrState = (uint8)currState;
   
    /* return the test status */
    return testStatus;
}
#define DIAGDEBOUNCE_STOP_SEC_CODE_Core0ASILB
#pragma ghs section text=default


