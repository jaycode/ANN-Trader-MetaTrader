//+------------------------------------------------------------------+
//|                                                    GapFiller.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

input int Input_Trailing_Stop = 20;

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
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   MqlRates rates[];
   CopyRates(Symbol(), PERIOD_D1, 0, 3, rates);
   ArraySetAsSeries(rates, true);
   
   datetime close_hour = D'2014.11.08 15:40';
   datetime now = TimeCurrent();
   MqlDateTime str_current;
   MqlDateTime str_end;
   TimeToStruct(now,str_current);
   TimeToStruct(close_hour,str_end);
   
   // At end of day, sell all current positions
   // Print("current hour: ", str_current.hour, ", end hour: ", str_end.hour);
   if (str_current.hour >= str_end.hour) 
   {
      CTrade trade;
      int i=PositionsTotal()-1;
      while (i>=0)
      {
         if (trade.PositionClose(PositionGetSymbol(i))) i--;
      }
        
   }
   else {
      // Print("PositionsTotal: ", PositionsTotal(), " rates2close: ", rates[2].close, ", rates1close-x%: ", (rates[1].close * 0.98), ", rates0open: ", rates[0].open);
      if (PositionsTotal() == 0 && rates[2].close < rates[1].close && rates[0].open < (rates[1].close * 0.9995)) {
         // Print("BUY!");
         MqlTradeRequest request;
         MqlTradeResult result;
         double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);    // Ask price
         double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);    // Bid price
         ZeroMemory(request);
         ZeroMemory(result);
         
         ulong ticket = 1;
         request.symbol = Symbol();
         request.type_filling = ORDER_FILLING_FOK;
   
         request.action=TRADE_ACTION_DEAL;
         request.type = ORDER_TYPE_BUY;
         request.volume = 0.01;
         request.order = ticket;
         request.price = NormalizeDouble(ask, _Digits);
         request.tp = rates[1].close;
         request.sl = bid - Point() * Input_Trailing_Stop;
         bool process_order = ProcessOrder(request,result);
      }

   }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Sending a trade request with the result processing               |
//+------------------------------------------------------------------+
bool ProcessOrder(MqlTradeRequest &request,MqlTradeResult &result)
  {
//--- reset the last error code to zero
   ResetLastError();
//--- send request
   bool success=OrderSend(request,result);
//--- if the result fails - try to find out why
   if(!success)
     {
      int answer=result.retcode;
      Print("TradeLog: Trade request failed. Error = ",GetLastError());
      switch(answer)
        {
         //--- requote
         case 10004:
           {
            Print("TRADE_RETCODE_REQUOTE");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- order is not accepted by the server
         case 10006:
           {
            Print("TRADE_RETCODE_REJECT");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- invalid price
         case 10015:
           {
            Print("TRADE_RETCODE_INVALID_PRICE");
            Print("request.price = ",request.price,"   result.ask = ",
                  result.ask," result.bid = ",result.bid);
            break;
           }
         //--- invalid SL and/or TP
         case 10016:
           {
            Print("TRADE_RETCODE_INVALID_STOPS");
            Print("Invalid stops. Stop Loss or Take Profit might be too close to current price (for position) or to open price (for pending order).");
            Print("request.price = ",request.price," request.sl = ",request.sl," request.tp = ",request.tp);
            Print("result.ask = ",result.ask," result.bid = ",result.bid);
            break;
           }
         //--- invalid volume
         case 4756:
         case 10014:
           {
            Print("TRADE_RETCODE_INVALID_VOLUME");
            Print("request.volume = ",request.volume,"   result.volume = ",
                  result.volume);
            break;
           }
         //--- not enough money for a trade operation 
         case 10019:
           {
            Print("TRADE_RETCODE_NO_MONEY");
            Print("request.volume = ",request.volume,"   result.volume = ",
                  result.volume,"   result.comment = ",result.comment);
            break;
           }
         //--- some other reason, output the server response code 
         default:
           {
            Print("Other answer = ",answer);
           }
        }
      //--- notify about the unsuccessful result of the trade request by returning false
      return(false);
     }
//--- OrderSend() returns true - repeat the answer
   return(true);
  }