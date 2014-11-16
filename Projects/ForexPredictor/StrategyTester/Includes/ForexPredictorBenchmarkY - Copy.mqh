//+------------------------------------------------------------------+
//|                                             ForexPredictorNn.mqh |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property description "Test if exported Y is profitable by using it in Expert Advisor"
#property version   "1.00"

#property tester_file "ForexPredictor\\training_y.csv"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ForexPredictorBenchmarkY
  {
protected:
      struct output
      {
         int          signal; // 1 - buy, 0 - sell
         double       bid;
         double       ask;
         double       max_close;
         double       target;
         datetime     time;
      };
      output outputs[];
      long times[];
      double swap;
      double upper_threshold; // Percent of upper threshold
      double lower_threshold; // Percent of lower threshold
public:
                     ForexPredictorBenchmarkY();
                    ~ForexPredictorBenchmarkY();
                     void Init(double swap_input, double upper_threshold_input, double lower_threshold_input);
                     void Processing();
                     bool ProcessOrder();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ForexPredictorBenchmarkY::ForexPredictorBenchmarkY()
  {
      
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ForexPredictorBenchmarkY::~ForexPredictorBenchmarkY()
  {
  }
//+------------------------------------------------------------------+

void ForexPredictorBenchmarkY::Init(double swap_input, double upper_threshold_input, double lower_threshold_input)
{
   swap = swap_input;
   upper_threshold = upper_threshold_input;
   lower_threshold = lower_threshold_input;
// get y of training
   ResetLastError();
   int filehandle=FileOpen("ForexPredictor\\training_y.csv",FILE_READ|FILE_CSV|FILE_ANSI, ",");
   if(filehandle!=INVALID_HANDLE)
   {
      int size = 0;
      while (FileIsEnding(filehandle) == false)
      {
         if (size > 0) {
            ArrayResize(outputs,size);
            ArrayResize(times, size);
            int count = size-1;
            outputs[count].signal = bool(FileReadString(filehandle));
            outputs[count].bid = double(FileReadString(filehandle));
            outputs[count].ask = double(FileReadString(filehandle));
            outputs[count].max_close = double(FileReadString(filehandle));
            outputs[count].target = double(FileReadString(filehandle));
            outputs[count].time = datetime(FileReadString(filehandle));
            times[count] = long(outputs[count].time);
         }
         else {
            // first line removal
            string buf = FileReadString(filehandle);
            buf = FileReadString(filehandle);
            buf = FileReadString(filehandle);
            buf = FileReadString(filehandle);
            buf = FileReadString(filehandle);
            buf = FileReadString(filehandle);
         }
         size ++;
      }
      
      // Binary search needs ascending sorted array, while our time data is descending sorted.
      ArraySort(times);
      Print("Total data = ",size);
      //--- close the file
      FileClose(filehandle);
   }
   else Print("Operation FileOpen failed, error: ",GetLastError());
   
}
void ForexPredictorBenchmarkY::Processing()
{
   MqlTradeRequest request;
   MqlTradeResult result;
   MqlDateTime dt;
   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);    // Ask price
   double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);    // Bid price
   ZeroMemory(request);
   ZeroMemory(result);
          
   request.symbol      =Symbol();
   request.tp          =0;
   request.deviation   =0;
   request.type_filling=ORDER_FILLING_FOK;
   request.magic = 0;
   ulong ticket = 1;
   
   datetime time_current = TimeCurrent(dt);
   long time_current_long = long(time_current);
   int pos = ArrayBsearch(times, time_current_long);
   if (pos != -1 && times[pos] != time_current_long) {
      pos = -1;
   };
   
   // Since our data was sorted descendingly, need to convert pos to found_pos as follows:
   int found_pos = ArraySize(times) - pos - 1;
   
   if (pos > -1) {
      Print("Pos: "+found_pos+" - Found signal " + outputs[found_pos].signal + " with max price: " + outputs[found_pos].max_close + " at time " + outputs[found_pos].time + " (current time is "+time_current+")");
   
      if (outputs[found_pos].signal == 0) {
         // Loop for all positions
         // If position is open and signal is sell, sell entire position
         for(int i=0;i<PositionsTotal();i++)
         {
            // processing orders with "our" symbols only
            if(Symbol()==PositionGetSymbol(i))
            {
           /*    request.action=TRADE_ACTION_DEAL;
               request.type = ORDER_TYPE_SELL;
               request.volume = PositionGetDouble(POSITION_VOLUME);
               request.price = NormalizeDouble(bid, _Digits);
               // We won't really know our exact stop loss and take profit values in real world
               // situation, so lets use the same threshold used in exporter script.
               request.sl=NormalizeDouble(bid - (bid * lower_threshold/100), _Digits);
               request.tp=NormalizeDouble(bid + (bid * upper_threshold/100), _Digits);
               
               // If we do know max close, it may maximise our profits:
               // request.sl=NormalizeDouble(outputs[found_pos].bid,_Digits);
               // request.tp=NormalizeDouble(outputs[found_pos].max_close,_Digits);
               
               // sending request to trade server
               bool process_order = ProcessOrder(request,result);*/
               return;
            }
         }

      }
      else {
         // if (PositionsTotal() == 0) {
            Print("try to buy");
            // If no position found and signal is buy, buy position with budget% of available capital
            request.action=TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_BUY;
            request.volume = 1;
            request.order = ticket;
            request.price = NormalizeDouble(ask, _Digits);
            // We won't really know our exact stop loss and take profit values in real world
            // situation, so lets use the same threshold used in exporter script.
            request.sl=NormalizeDouble(bid - (bid * lower_threshold/100), _Digits);
            request.tp=NormalizeDouble(bid + (bid * upper_threshold/100), _Digits);
            
            // If we do know max close, it may maximise our profits:
            // request.sl=NormalizeDouble(outputs[found_pos].bid - (outputs[found_pos].bid*10/100),_Digits);
            // request.tp=NormalizeDouble(outputs[found_pos].max_close,_Digits);
            
            // sending request to trade server
            Print("buy with price = "+ask+" sl = "+request.sl+" and tp = "+request.tp);
            bool process_order = ProcessOrder(request,result);

         // }
      }

   }
}

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
            Print("request.sl = ",request.sl," request.tp = ",request.tp);
            Print("result.ask = ",result.ask," result.bid = ",result.bid);
            break;
           }
         //--- invalid volume
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