//+------------------------------------------------------------------+
//|                                            ForexPredictor_nn.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"
#property description "Applying predictions set up by Matlab."

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include "..\Includes\PredictionsApplier3Labels.mqh"

PredictionsApplier3Labels fp_ea();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("Init");
   fp_ea.Init();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   fp_ea.Processing();
  }
//+------------------------------------------------------------------+

void OnTimer()
{
   // fp_ea.Processing();
}