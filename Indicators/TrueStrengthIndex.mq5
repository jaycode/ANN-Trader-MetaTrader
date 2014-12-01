//+------------------------------------------------------------------+
//|                                            TrueStrengthIndex.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 7
#property indicator_plots   1
//--- plot TSI
#property indicator_label1  "TSI"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_applied_price PRICE_TYPICAL

//--- input parameters
input int      r=25;
input int      s=13;
//--- indicator buffers
double         TSIBuffer[];
double         MTMBuffer[];
double         AbsMTMBuffer[];
double         EMA_MTMBuffer[];
double         EMA2_MTMBuffer[];
double         EMA_AbsMTMBuffer[];
double         EMA2_AbsMTMBuffer[];

#include <MovingAverages.mqh>

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,TSIBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,MTMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(2,AbsMTMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,EMA_MTMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,EMA2_MTMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,EMA_AbsMTMBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,EMA2_AbsMTMBuffer,INDICATOR_CALCULATIONS);
//--- bar, starting from which the indicator is drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,r+s-1);
   string shortname;
   StringConcatenate(shortname,"TSI(",r,",",s,")");
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
int OnCalculate (const int rates_total,      // size of the price[] array
                 const int prev_calculated,  // number of available bars at the previous call
                 const int begin,            // from what index in price[] authentic data start
                 const double& price[])      // array, on which the indicator will be calculated
  {
//---

//--- if the size of price[] is too small
  if(rates_total<r+s) return(0); // do not calculate or draw anything

//--- if it is the first call 
   if(prev_calculated==0)
   {
      //--- set zero values to zero indexes
      MTMBuffer[0]=0.0;
      AbsMTMBuffer[0]=0.0;
   }
//--- calculate values of mtm and |mtm|
   int start;
   if(prev_calculated==0) start=1;  // start filling out MTMBuffer[] and AbsMTMBuffer[] from the 1st index 
   else start=prev_calculated-1;    // set start equal to the last index in the arrays 
   for(int i=start;i<rates_total;i++)
   {
      MTMBuffer[i]=price[i]-price[i-1];
      AbsMTMBuffer[i]=fabs(MTMBuffer[i]);
   }
   
   //--- calculate the first moving
   ExponentialMAOnBuffer(rates_total,prev_calculated,
                         1,  // index, starting from which data for smoothing are available 
                         r,  // period of the exponential average
                         MTMBuffer,       // buffer to calculate average
                         EMA_MTMBuffer);  // into this buffer locate value of the average
   ExponentialMAOnBuffer(rates_total,prev_calculated,
                         1,r,AbsMTMBuffer,EMA_AbsMTMBuffer);

//--- calculate the second moving average on arrays
   ExponentialMAOnBuffer(rates_total,prev_calculated,
                         r,s,EMA_MTMBuffer,EMA2_MTMBuffer);
   ExponentialMAOnBuffer(rates_total,prev_calculated,
                         r,s,EMA_AbsMTMBuffer,EMA2_AbsMTMBuffer);

//--- now calculate values of the indicator
   if(prev_calculated==0) start=r+s-1; // set the starting index for input arrays
   for(int i=start;i<rates_total;i++)
   {
      TSIBuffer[i]=100*EMA2_MTMBuffer[i]/EMA2_AbsMTMBuffer[i];
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
