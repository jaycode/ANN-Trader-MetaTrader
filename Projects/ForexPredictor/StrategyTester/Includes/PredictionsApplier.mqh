//+------------------------------------------------------------------+
//|                                             ForexPredictorNn.mqh |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property description "Test if exported Y is profitable by using it in Expert Advisor"
#property version   "1.00"

#property tester_file "ForexPredictor\\predictions.csv"
#property tester_file "ForexPredictor\\settings.csv"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PredictionsApplier
  {
protected:
      struct output
      {
         long    time; // unix timestamp
         int     signal; // 0 - hold, 1 - buy, 2 - sell
         double  confidence;
      };
      output outputs[];
      long times[];
      double upper_threshold; // Percent of upper threshold
      double lower_threshold; // Percent of lower threshold
      CTrade         m_trade;

      MqlTradeRequest request;
      MqlTradeResult result;
      MqlDateTime dt;

      void UpdateTrailingStops();
public:
      PredictionsApplier();
      ~PredictionsApplier();
      void Init();
      void Processing();
      bool ProcessOrder();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PredictionsApplier::PredictionsApplier()
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PredictionsApplier::~PredictionsApplier()
  {
  }
//+------------------------------------------------------------------+

void PredictionsApplier::Init()
{
   int filehandle=FileOpen("ForexPredictor\\settings.csv",FILE_READ|FILE_CSV|FILE_ANSI, ",");
   if(filehandle!=INVALID_HANDLE)
   {
      while (FileIsEnding(filehandle) == false)
      {
         string name = FileReadString(filehandle);
         if (name == "upper_threshold") {
            upper_threshold = (double)FileReadString(filehandle);
         }
         else if(name == "lower_threshold") {
            lower_threshold = (double)FileReadString(filehandle);
         }
      }
   }
// get y of training
   ResetLastError();
   filehandle=FileOpen("ForexPredictor\\predictions.csv",FILE_READ|FILE_CSV|FILE_ANSI, ",");
   if(filehandle!=INVALID_HANDLE)
   {
      int size = 0;
      while (FileIsEnding(filehandle) == false)
      {
         if (size > 0) {
            ArrayResize(outputs,size);
            ArrayResize(times, size);
            int count = size-1;
            outputs[count].time = long(FileReadString(filehandle));
            outputs[count].signal = int(FileReadString(filehandle));
            outputs[count].confidence = double(FileReadString(filehandle));
            times[count] = outputs[count].time;
         }
         else {
            // first line removal
            string buf = FileReadString(filehandle);
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
void PredictionsApplier::Processing()
{
   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);    // Ask price
   double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);    // Bid price
   ZeroMemory(request);
   ZeroMemory(result);
   
   
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double price_per_lot = ask * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
   double budget = (balance * 1 / 100) * (double)AccountInfoInteger(ACCOUNT_LEVERAGE);
   double volume_budget = NormalizeDouble(budget / price_per_lot,2);
   // Print("account balance is ",balance);
   // Print("price per lot: ", price_per_lot);
   // Print("budget is: ", budget);
   // Print("max volume to buy is ",volume_budget);
      
   request.symbol      =Symbol();
   request.tp          =0;
   request.deviation   =0;
   request.type_filling=ORDER_FILLING_FOK;
   request.magic = 0;
   ulong ticket = 1;
   
   datetime time_current = TimeCurrent(dt);
   long time_current_long = long(time_current);
   int prediction_id = ArrayBsearch(times, time_current_long);
   if (prediction_id != -1 && times[prediction_id] != time_current_long) {
      prediction_id = -1;
   }
   else {
      // Since our data was sorted descendingly, need to convert pos to found_pos as follows:
      prediction_id = ArraySize(times) - prediction_id - 1;
   }
   
   
   
   /* Trading System:
   *  A. If current history has a prediction:
   *  1. If prediction is buy (signal = 1)
   *     Create a new or add to existing position.
   *     If position exists AND current price is higher than that position, buy more (pyramiding) then do the following:
   *     - Update take profit value to current threshold if it is higher.
   *     - Change stop lost value to current threshold only if it is higher.
   *  2. If prediction is sell(signal = 0)
   *     If position exists and not profitable, do the following:
   *     - Do not change take profit value.
   *     - Change stop lost value to current threshold only if it is higher.
   *     If position exists and profitable, sell position.
   *  B. If current history does not have a prediction (i.e. a small tick):
   *     If position exists, do the following:
   *     - Do not change take profit value.
   *     - Change stop lost value to current threshold only if it is higher.
   */
   
   
   // Print("find time: ",time_current_long);
   // Print("prediction_id: ",prediction_id);
   if (prediction_id > -1) {
      Print("prediction_id: "+prediction_id+" - Found signal " + outputs[prediction_id].signal + " with confidence: " + outputs[prediction_id].confidence + " at time " + outputs[prediction_id].time + " (current time is "+time_current+")");
   
      if (outputs[prediction_id].signal == 1 && outputs[prediction_id].confidence > 0) {
         if ((PositionSelect(Symbol()) && PositionGetDouble(POSITION_PROFIT)>0) || !PositionSelect(Symbol())) {
            Print("try to buy");
            // If no position found and signal is buy, buy position with budget% of available capital
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            request.action=TRADE_ACTION_DEAL;
            request.type = ORDER_TYPE_BUY;
            request.volume = volume_budget;
            request.order = ticket;
            request.price = NormalizeDouble(ask, _Digits);
            // We won't really know our exact stop loss and take profit values in real world
            // situation, so lets use the same threshold used in exporter script.
            request.sl=NormalizeDouble(bid + (bid * lower_threshold/100), _Digits);
            request.tp=NormalizeDouble(bid + (bid * upper_threshold/100), _Digits);
            
            // If we do know max close, it may maximise our profits:
            // request.sl=NormalizeDouble(outputs[found_pos].bid - (outputs[found_pos].bid*10/100),_Digits);
            // request.tp=NormalizeDouble(outputs[found_pos].max_close,_Digits);
            
            // sending request to trade server
            Print("freemargin before buying: ", AccountInfoString(ACCOUNT_CURRENCY), " ", AccountInfoDouble(ACCOUNT_FREEMARGIN));
            Print("buy with volume = "+request.volume+" price = "+request.price+" sl = "+request.sl+" and tp = "+request.tp);
            bool process_order = ProcessOrder(request,result);
            Print("freemargin after buying: ", AccountInfoString(ACCOUNT_CURRENCY), " ", AccountInfoDouble(ACCOUNT_FREEMARGIN));

         }
      }
      else {
         // hold
         UpdateTrailingStops();
         // If position is open, profitable, and signal is sell, sell entire position
         if (PositionSelect(Symbol()) && PositionGetDouble(POSITION_PROFIT) > 0) {
            m_trade.PositionClose(Symbol());
         }
      }

   }
   else {
      // No prediction found for this tick.
      UpdateTrailingStops();
   }
}

// This method updates ALL trailing stops, even outside of current symbol, as this is meant to be generic.
void PredictionsApplier::UpdateTrailingStops()
{
   for(int i=0;i<PositionsTotal();i++)
   {
      PositionSelect(PositionGetSymbol(i));
      double pos_sl = PositionGetDouble(POSITION_SL);
      double pos_tp = PositionGetDouble(POSITION_TP);
      double psymbol_bid = SymbolInfoDouble(PositionGetSymbol(i),SYMBOL_BID);
      double psymbol_bid_sl = NormalizeDouble(psymbol_bid + (psymbol_bid * lower_threshold/100), _Digits);
      // If stop loss of current bid of position's symbol is larger than the position's stop loss, update position's stop loss.
      if (psymbol_bid_sl > pos_sl) {
         if (m_trade.PositionModify(PositionGetSymbol(i), psymbol_bid_sl, pos_tp)) {
            ProcessRetcode(m_trade.ResultRetcode(), request, result);
         }
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
      ProcessRetcode(answer, request, result);
      //--- notify about the unsuccessful result of the trade request by returning false
      return(false);
   }
//--- OrderSend() returns true - repeat the answer
   return(true);
}
void ProcessRetcode(uint retcode, MqlTradeRequest &request,MqlTradeResult &result)
{
   switch(retcode)
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
      //--- request completed
      case 10009:
         Print("TRADE_RETCODE_DONE");
      //--- some other reason, output the server response code 
      default:
      {
         Print("Other answer = ",retcode);
      }
   }
}  