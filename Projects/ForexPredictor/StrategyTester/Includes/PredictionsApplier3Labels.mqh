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
class PredictionsApplier3Labels : public PredictionsApplier
  {
protected:
      void Buy(double volume, double sl, double tp, string comment = "");
public:
      PredictionsApplier3Labels();
      ~PredictionsApplier3Labels();
      void Init();
      void Processing();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PredictionsApplier3Labels::PredictionsApplier3Labels()
  {

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PredictionsApplier3Labels::~PredictionsApplier3Labels()
  {
  }
//+------------------------------------------------------------------+

void PredictionsApplier3Labels::Init()
{
   PredictionsApplier::Init();
}

void PredictionsApplier3Labels::Processing()
{
   int     InpBandsPeriod=20;       // Period
   int     InpBandsShift=0;         // Shift
   double  InpBandsDeviations=2.0;  // Deviation
   PreProcessing();   
   /* Trading System:
   *  A. If current history has a prediction:
   *  1. If prediction is buy (signal = 1)
   *     Create a new or add to existing position.
   *     If position exists AND current price is higher than that position, buy more (pyramiding) then do the following:
   *     - Update take profit value to current threshold if it is higher.
   *     - Change stop lost value to current threshold only if it is higher.
   *  2. If prediction is hold (signal = 0)
   *     If position exists, do the following:
   *     - Do not change take profit value.
   *     - Change stop lost value to current threshold only if it is higher.
   *  3. If prediction is sell (signal = 2)
   *     Sell position.
   *  B. If current history does not have a prediction (i.e. a small tick):
   *     If position exists, do the following:
   *     - Do not change take profit value.
   *     - Change stop lost value to current threshold only if it is higher.
   */
   
   
   // Print("find time: ",time_current_long);
   // Print("prediction_id: ",prediction_id);
   if (prediction_id > -1) {
      Print("prediction_id: "+prediction_id+" - Found signal " + outputs[prediction_id].signal + " with confidence: " + outputs[prediction_id].confidence + " at time " + outputs[prediction_id].time + " (current time is "+time_current+")");
   
      if (outputs[prediction_id].signal == 2 && outputs[prediction_id].confidence > 0.52) {
         // If position is open, profitable, and signal is sell, sell entire position
         if (PositionSelect(Symbol())) {
            m_trade.PositionClose(Symbol());
         }
      }
      else if (outputs[prediction_id].signal == 1 && outputs[prediction_id].confidence > 0.52) {
         Print("profit: ", PositionGetDouble(POSITION_PROFIT));
         if (!PositionSelect(Symbol())) {
            int bb_handle = iCustom(Symbol(), 0, "Examples\\BB",
               InpBandsPeriod,
               InpBandsShift,
               InpBandsDeviations
            );
            int copy1=CopyBuffer(bb_handle,1,0,2,bb_buffer_upper);
            int copy2=CopyBuffer(bb_handle,2,0,2,bb_buffer_lower);
            double bb_tp = NormalizeDouble(bb_buffer_upper[1], _Digits);
            double bb_sl = NormalizeDouble(bb_buffer_lower[1], _Digits);

            // If no position found and signal is buy, buy position with budget% of available capital
            Buy(
               volume_budget,
               // NormalizeDouble(bid + (bid * lower_threshold/100), _Digits),
               // NormalizeDouble(bid + (bid * upper_threshold/100), _Digits),
               bb_sl,
               bb_tp,
               // NormalizeDouble(bid + (bid * upper_threshold/100), _Digits),
               "confidence: " + outputs[prediction_id].confidence
            );
         }
         else {
            // If position found and signal is buy and position is profitable,
            // buy more, but put stop loss to current position price
            if (PositionGetDouble(POSITION_PROFIT) > 0) {
               int bb_handle = iCustom(Symbol(), 0, "Examples\\BB",
                  InpBandsPeriod,
                  InpBandsShift,
                  InpBandsDeviations
               );
               int copy1=CopyBuffer(bb_handle,1,0,2,bb_buffer_upper);
               int copy2=CopyBuffer(bb_handle,2,0,2,bb_buffer_lower);
               double bb_tp = NormalizeDouble(bb_buffer_upper[1], _Digits);
               double bb_sl = NormalizeDouble(bb_buffer_lower[1], _Digits);
               
               Buy(
                  volume_budget,
                  PositionGetDouble(POSITION_PRICE_CURRENT)-((PositionGetDouble(POSITION_PRICE_CURRENT)- PositionGetDouble(POSITION_PRICE_OPEN))*30/100),
                  // NormalizeDouble(bid + (bid * upper_threshold/100), _Digits),
                  bb_tp,
                  "top up with confidence: " + outputs[prediction_id].confidence
               );
            }
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

void PredictionsApplier3Labels::Buy(double volume, double sl, double tp, string comment = "")
{
   request.action=TRADE_ACTION_DEAL;
   request.type = ORDER_TYPE_BUY;
   request.volume = volume;
   request.order = ticket;
   request.price = NormalizeDouble(ask, _Digits);
   request.sl=sl;
   request.tp=tp;
   request.comment = comment;
   
   // If we do know max close, it may maximise our profits:
   // request.sl=NormalizeDouble(outputs[found_pos].bid - (outputs[found_pos].bid*10/100),_Digits);
   // request.tp=NormalizeDouble(outputs[found_pos].max_close,_Digits);
   
   // sending request to trade server
   Print("freemargin before buying: ", AccountInfoString(ACCOUNT_CURRENCY), " ", AccountInfoDouble(ACCOUNT_FREEMARGIN));
   Print("buy with volume = "+request.volume+" price = "+request.price+" sl = "+request.sl+" and tp = "+request.tp);
   bool process_order = ProcessOrder(request,result);
   Print("freemargin after buying: ", AccountInfoString(ACCOUNT_CURRENCY), " ", AccountInfoDouble(ACCOUNT_FREEMARGIN));
}