//+------------------------------------------------------------------+
//|                                                      TestDLL.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"

#import "FPDLL.dll"
   int GetAnswerOfLife();
   double RunMatlabFunction();
   void GetLog(string &logStr);
#import
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("Answer of life: ");
   Print((string)GetAnswerOfLife());
   Print("Test running matlab function: ");
   Print((string)RunMatlabFunction());
   string logStr = "";
   GetLog(logStr);
   Print("log: " + logStr);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
