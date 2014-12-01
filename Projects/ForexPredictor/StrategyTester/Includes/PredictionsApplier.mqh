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
#include "PredictionsApplier.mqh"

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
      int Export_NextTickToGuess;
      ENUM_TIMEFRAMES Export_Period;
      CTrade         m_trade;

      // variables needed for processing, set at PreProcessing method
      // ----------------------------- //
      MqlTradeRequest request;
      MqlTradeResult result;
      MqlDateTime dt;
      
      double ask;
      double bid;
      double budget_percentage; // Percent of budget to be used per trade
      double balance; // Current account balance.
      double price_per_lot;
      double budget; // Current money to be budgeted per trade.
      double volume_budget; // Volume to buy per trade.

      ulong ticket;
      datetime time_current;
      long time_current_long;
      int prediction_id;
      // ----------------------------- //

      double bb_buffer_upper[]; // Upper buffer for Bollinger Band
      double bb_buffer_lower[]; // Upper buffer for Bollinger Band
      void UpdateTrailingStops();
public:
      PredictionsApplier();
      ~PredictionsApplier();
      void Init();
      void PreProcessing();
      virtual void Processing();
      bool ProcessOrder();
      static bool PredictionsApplier::ProcessOrder(MqlTradeRequest &request,MqlTradeResult &result);
      static void PredictionsApplier::ProcessRetcode(uint retcode, MqlTradeRequest &request,MqlTradeResult &result);
      
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
   budget_percentage = 1;
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
         else if(name == "Export_NextTickToGuess") {
            Export_NextTickToGuess = (int)FileReadString(filehandle);
         }
         else if(name == "Export_Period") {
            Export_Period = (ENUM_TIMEFRAMES)FileReadString(filehandle);
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

void PredictionsApplier::PreProcessing() {
   ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);    // Ask price
   bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);    // Bid price
   ZeroMemory(request);
   ZeroMemory(result);
   
   
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
   price_per_lot = ask * SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE);
   budget = (balance * budget_percentage / 100) * (double)AccountInfoInteger(ACCOUNT_LEVERAGE);
   volume_budget = NormalizeDouble(budget / price_per_lot,2);
   // Print("account balance is ",balance);
   // Print("price per lot: ", price_per_lot);
   // Print("budget is: ", budget);
   // Print("max volume to buy is ",volume_budget);
      
   request.symbol      =Symbol();
   request.tp          =0;
   request.deviation   =0;
   request.type_filling=ORDER_FILLING_FOK;
   request.magic = 0;
   ticket = 1;
   
   time_current = TimeCurrent(dt);
   time_current_long = long(time_current);
   prediction_id = ArrayBsearch(times, time_current_long);
   if (prediction_id != -1 && times[prediction_id] != time_current_long) {
      prediction_id = -1;
   }
   else {
      // Since our data was sorted descendingly, need to convert pos to found_pos as follows:
      prediction_id = ArraySize(times) - prediction_id - 1;
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
      
      /* BOLLINGER BAND - TOO SLOW and unprofitable
      if (PositionGetDouble(POSITION_PROFIT) < 0) {
         int bb_handle = iCustom(PositionGetSymbol(i), PERIOD_D1, "Examples\\BB");
         int copy1=CopyBuffer(bb_handle,1,0,1,bb_buffer_upper);
         int copy2=CopyBuffer(bb_handle,2,0,1,bb_buffer_lower);
         double bb_tp = NormalizeDouble(bb_buffer_upper[0], _Digits);
         double bb_sl = NormalizeDouble(bb_buffer_lower[0], _Digits);
   
         
         if (bb_sl < pos_tp && (bb_sl != pos_sl || bb_tp != pos_tp)) {
            if (m_trade.PositionModify(PositionGetSymbol(i), bb_sl, bb_tp)) {
               ProcessRetcode(m_trade.ResultRetcode(), request, result);
            }      
         }
      }
      */
      
      double psymbol_bid = SymbolInfoDouble(PositionGetSymbol(i),SYMBOL_BID);
      double psymbol_bid_sl = NormalizeDouble(psymbol_bid + (psymbol_bid * lower_threshold/100), _Digits);
      // If stop loss of current bid of position's symbol is larger than the position's stop loss, update position's stop loss.
      if (psymbol_bid_sl > pos_sl) {
         if (m_trade.PositionModify(PositionGetSymbol(i), psymbol_bid_sl, pos_tp)) {
            ProcessRetcode(m_trade.ResultRetcode(), request, result);
         }
      }
      
      long pos_open_time = PositionGetInteger(POSITION_TIME);
      long timenow = long(TimeCurrent(dt));
      long max_age = Export_NextTickToGuess * PeriodSeconds(Export_Period);
      long age = timenow - pos_open_time;
      if (age > max_age && PositionGetDouble(POSITION_PROFIT) < 0) {
         m_trade.PositionClose(PositionGetSymbol(i));
      }
   }
}

//+------------------------------------------------------------------+
//| Sending a trade request with the result processing               |
//+------------------------------------------------------------------+
static bool PredictionsApplier::ProcessOrder(MqlTradeRequest &request,MqlTradeResult &result)
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

static void PredictionsApplier::ProcessRetcode(uint retcode, MqlTradeRequest &request,MqlTradeResult &result)
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