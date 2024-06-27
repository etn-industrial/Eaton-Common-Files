/*  DiagDebounceLite.c
*
* Implements lite debounce counter diagnostics blocks
* Author: Eaton
* Version: 1.0 - 8/31/2023
*
*/

#include "DiagDebounceLite.h"
#include <stdbool.h>
#include "rtwtypes.h"

/* Lv1 event status type */
typedef enum {
    DEM_EVENT_STATUS_INIT       = 0,  //TODO: we shoudl align to the autosar def if possible
    DEM_EVENT_STATUS_FAILED     = 1,
    DEM_EVENT_STATUS_PASSED     = 2
} DemEventStatusType;

/* constants */
const int16_T INIT_COUNTER_L = 0;
const int16_T SINT16_MAX = 32767;
const int16_T SINT16_MIN = -32768;

/*declare sub function prototypes*/
void incrementCounter(int16_T* diagFaultCounter, int16_T diagUpCnt);
void decrementCounter(int16_T* diagFaultCounter, int16_T diagDnCnt);

/* function to debounce event status */
void DiagDebounceLite(int16_T* diagFaultCounter,unsigned char* diagCurrState,
                  bool diagFaultActive, bool diagReset,
                  int16_T diagFaultCntThresh, int16_T diagPassCntThresh,
                  int16_T diagUpCnt, int16_T diagDnCnt, bool diagHealEn)
{
   /* init currState */
   DemEventStatusType currState = (DemEventStatusType)(*diagCurrState);   

   /* Switch based on diagnostic current state */
   switch (currState)
   {
   case DEM_EVENT_STATUS_INIT:
      if (diagReset == true)
      {
         /* reset counter */
         *diagFaultCounter = INIT_COUNTER_L;
      }

      else if (diagFaultActive == false)
      {
         /* decrement fault counter */
         decrementCounter(diagFaultCounter, diagDnCnt);
         if (*diagFaultCounter <= diagPassCntThresh)
         {
            /* update to passed if threshold is met*/
            currState = DEM_EVENT_STATUS_PASSED;
         }
      }
      else /* diagFaultActive == true */
      {
         /* increment fault counter */
         incrementCounter(diagFaultCounter, diagUpCnt);
         if (*diagFaultCounter >= diagFaultCntThresh)
         {
            /* update to failed if threshold is met*/
            currState = DEM_EVENT_STATUS_FAILED;
         }
      }
      break;

   case DEM_EVENT_STATUS_FAILED:
      if (diagReset == true)
      {
         /* update to init */
         currState = DEM_EVENT_STATUS_INIT;

         /* reset counter */
         *diagFaultCounter = INIT_COUNTER_L;
      }
      /* check if fault is absent and healing is enabled */
      else if ((diagFaultActive == false) && (diagHealEn == true))
      {
         if (*diagFaultCounter > INIT_COUNTER_L)
         {
            /* reset counter to zero since false state has changed from last itteration */
            *diagFaultCounter = INIT_COUNTER_L;
         }
         /* decrement fault counter */
         decrementCounter(diagFaultCounter, diagDnCnt);
         /*check for value below thresh*/
         if (*diagFaultCounter <= diagPassCntThresh)
         {
            /* update to passed */
            currState = DEM_EVENT_STATUS_PASSED;
         }
      }
      else /* diagFaultActive == true */
      {
         if (*diagFaultCounter < INIT_COUNTER_L)
         {
            /* increment the counter by diagUpCnt, already in failed state so no need to check threshold */
            incrementCounter(diagFaultCounter, diagUpCnt);
         }
      }

      break;

   case DEM_EVENT_STATUS_PASSED:
      if (diagReset == true)
      {
         /* update to init */
         currState = DEM_EVENT_STATUS_INIT;

         /* reset counter */
         *diagFaultCounter = INIT_COUNTER_L;
      }
      else if (diagFaultActive == false)
      {
        /*only decrement the counter when the value is greater than INIT_COUNTER_L*/
         if (*diagFaultCounter > INIT_COUNTER_L)
         {
            /* decrement the counter by diagDnCnt, already in passed state so no need to check threshold */
            decrementCounter(diagFaultCounter, diagDnCnt);
         }
      }
      else /* diagFaultActive == true */
      {
         if (*diagFaultCounter < INIT_COUNTER_L)
         {
            /* reset counter to zero since false state has changed from last itteration */
            *diagFaultCounter = INIT_COUNTER_L;
         }
         /* increment fault counter */
         incrementCounter(diagFaultCounter, diagUpCnt);
         /*check for value above thresh*/
         if (*diagFaultCounter >= diagFaultCntThresh)
         {
            /* update to failed */
            currState = DEM_EVENT_STATUS_FAILED;
         }
      }
      break;

   default:
      /* should not be possible to get here, if you get to this state a fault
         should be thrown */
      currState = DEM_EVENT_STATUS_FAILED;
      break;
   }

   /* update diagCurrState to match local state */
   *diagCurrState = (unsigned char)currState;
  
}

//Overflow protected addition
void incrementCounter(int16_T* diagFaultCounter, int16_T diagUpCnt)
{
   // check for overflow
   if (*diagFaultCounter < (SINT16_MAX - diagUpCnt))
   {
      *diagFaultCounter = *diagFaultCounter + diagUpCnt;  // update counter
   }
   else
   {
      *diagFaultCounter = SINT16_MAX; //saturate at max
   } 
}

//Underflow protected subtraction
void decrementCounter(int16_T* diagFaultCounter, int16_T diagDnCnt)
{
   // check for underflow
   if (*diagFaultCounter > (SINT16_MIN + diagDnCnt))
   {
      *diagFaultCounter = *diagFaultCounter - diagDnCnt;  // update counter
   }
   else
   {
      *diagFaultCounter = SINT16_MIN; //saturate at min
   } 
}
