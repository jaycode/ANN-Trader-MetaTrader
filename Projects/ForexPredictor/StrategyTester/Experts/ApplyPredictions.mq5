//+------------------------------------------------------------------+
//|                                            ForexPredictor_nn.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"

input double swap = 0.2;
input double upper_threshold = 0.2;
input double lower_threshold = 10;

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include "..\Includes\ForexPredictorBenchmarkY.mqh"

ForexPredictorBenchmarkY fp_ea();

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   fp_ea.Init(swap, upper_threshold, lower_threshold);
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