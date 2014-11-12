//+------------------------------------------------------------------+
//|                                                TestIndicator.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property description "This indicator calculates TakeProfit levels"
#property description "using the average market volatility. It uses the values"
#property description "of Average True Range (ATR) indicator, calculated"
#property description "on daily price data. Indicator values are calculated"
#property description "using maximal and minimal price values per day."
#property version     "1.00"
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots   2

#property indicator_type1   DRAW_LINE
#property indicator_color1  C'127,191,127'
#property indicator_style1  STYLE_SOLID
#property indicator_label1  "Buy TP"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'191,127,127'
#property indicator_style2  STYLE_SOLID
#property indicator_label2  "Sell TP"

//--- input parameters
input int             ATRper       = 5;         //ATR Period
input ENUM_TIMEFRAMES ATRtimeframe = PERIOD_D1; //Indicator timeframe
double bu[],bd[];
int hATR;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,bu,INDICATOR_DATA);
   SetIndexBuffer(1,bd,INDICATOR_DATA);
   hATR=iATR(NULL,ATRtimeframe,ATRper);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
