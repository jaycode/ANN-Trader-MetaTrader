//+------------------------------------------------------------------+
//|                                                      TryMyEA.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"

#import "test.dll"
   int CalcNeuralNet(string dllPath, string weightsPath, double& inputs[], double& outputs[]);
#import
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
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
  
TheMachine Machine;
double Prognoze;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() 
  {
   // Get the price prediction from the neuronet
   if (NN.Calc()) Prognoze = Machine.out[0];
   else           Prognoze = 0;

   // Perform necessary trade actions
   Trade();
  }
//+------------------------------------------------------------------+
void Trade() 
  {

   // Close an open position if it is opposite to the prediction

   if(PositionSelect(_Symbol)) 
     {
      long type=PositionGetInteger(POSITION_TYPE);
      bool close=false;
      if((type == POSITION_TYPE_BUY)  && (Prognoze <= 0)) close = true;
      if((type == POSITION_TYPE_SELL) && (Prognoze >= 0)) close = true;
      if(close) 
        {
         CTrade trade;
         trade.PositionClose(_Symbol);
        }
     }

   // If there is no positions, open one according to the prediction

   if((Prognoze!=0) && (!PositionSelect(_Symbol))) 
     {
      CTrade trade;
      if(Prognoze > 0) trade.Buy (Lots);
      if(Prognoze < 0) trade.Sell(Lots);
     }
  }
//+------------------------------------------------------------------+