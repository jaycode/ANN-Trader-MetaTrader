//+------------------------------------------------------------------+
//|                                                          VMA.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
//--- plot TSI
#property indicator_label1  "VMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#include <MovingAverages.mqh>

input int input_Period = 3; // Period

double         dblvolume[];
double         VMABuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,VMABuffer,INDICATOR_DATA);
   SetIndexBuffer(1,dblvolume,INDICATOR_CALCULATIONS);
//--- bar, starting from which the indicator is drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,input_Period-1);
   string shortname;
   StringConcatenate(shortname,"VMA(",input_Period,")");
//--- set a label do display in DataWindow
   PlotIndexSetString(0,PLOT_LABEL,shortname);   
//--- set a name to show in a separate sub-window or a pop-up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- set accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
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
   ArrayResize(dblvolume, ArraySize(VMABuffer));
   if(rates_total<input_Period) return(0);
   
   //--- if it is the first call 
   if(prev_calculated==0)
   {
      //--- set zero values to zero indexes
      VMABuffer[0]=0.0;
      dblvolume[0]=0.0;
   }
   
   int start;
   if(prev_calculated==0) start=1;  // start filling out MTMBuffer[] and AbsMTMBuffer[] from the 1st index 
   else start=prev_calculated-1;    // set start equal to the last index in the arrays 
   for(int i=start;i<rates_total;i++)
   {
      dblvolume[i] = (double)tick_volume[i];
   }
   
   SimpleMAOnBuffer(rates_total, prev_calculated, 1, input_Period, dblvolume, VMABuffer);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
