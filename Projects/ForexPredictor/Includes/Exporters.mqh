//+------------------------------------------------------------------+
//|                                                    Exporters.mqh |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

double CalculateTarget(MqlRates& rates[], int current_pos, int pos_to_guess, double& final_max_close)
{
   double max_close = 0;
   double dbl_spread = 0;
   for (int i = current_pos-1; i > current_pos-pos_to_guess; i--) {
      if (rates[i].close > max_close) max_close = rates[i].close;
   }
   final_max_close = max_close;
   
   dbl_spread = rates[current_pos].spread * 0.00001;
   double target = ((max_close - (rates[current_pos].close + dbl_spread)) / rates[current_pos].close) * 100;
   return target;
}

// Convert days to whatever period we are using
int NormalizeDays(int days, ENUM_TIMEFRAMES period)
{
   int answer = (days * 24 * 3600) / PeriodSeconds(period);
   return(answer);
}

void ExportMA(
      double& buffer[],
      int start = 0,
      int end = NULL,
      string symbol = NULL,
      ENUM_TIMEFRAMES period = 0,
      int ma_period = 12,
      ENUM_MA_METHOD ma_method = MODE_EMA,
      ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE
      ) 
{
   int buffer_number = 0;
   SetIndexBuffer(buffer_number,buffer,INDICATOR_DATA);
   int ma_handle=iMA(symbol,period,ma_period,0,ma_method,applied_price);
   if (end == NULL) {
      end=Bars(symbol,period);
   }
   
   CopyBuffer(ma_handle,buffer_number,start,end,buffer);
   
   // This function reverse the buffer array so that newest are displayed first
   ArraySetAsSeries(buffer,true);
   
}
  
void ExportATR(
      double& buffer[],
      int start = 0,
      int end = NULL,
      string symbol = NULL,
      ENUM_TIMEFRAMES period = 0,
      int ma_period = 12
      ) 
{
   int buffer_number = 0;
   SetIndexBuffer(buffer_number,buffer,INDICATOR_DATA);
   int handle=iATR(symbol,period,ma_period);
   if (end == NULL) {
      end=Bars(symbol,period);
   }
   
   CopyBuffer(handle,buffer_number,start,end,buffer);
   
   // This function reverse the buffer array so that newest are displayed first
   ArraySetAsSeries(buffer,true);
   
}
  
void ExportADX(
      double& buffer[],
      int start = 0,
      int end = NULL,
      string symbol = NULL,
      ENUM_TIMEFRAMES period = 0,
      int adx_period = 12
      ) 
{
   int buffer_number = 0;
   SetIndexBuffer(buffer_number,buffer,INDICATOR_DATA);
   int handle=iADX(symbol,period,adx_period);
   if (end == NULL) {
      end=Bars(symbol,period);
   }
   
   CopyBuffer(handle,buffer_number,start,end,buffer);
   
   // This function reverse the buffer array so that newest are displayed first
   ArraySetAsSeries(buffer,true);
   
}

void ExportStoch(
      double& buffer[],
      int start = 0,
      int end = NULL,
      string symbol = NULL,
      ENUM_TIMEFRAMES period = 0,
      int Kperiod = 3,
      ENUM_MA_METHOD ma_method = MODE_EMA,
      ENUM_STO_PRICE applied_price = STO_LOWHIGH
      ) 
{
   int buffer_number = 0;
   SetIndexBuffer(buffer_number,buffer,INDICATOR_DATA);
   int handle=iStochastic(symbol,period,Kperiod, 3,3, ma_method, applied_price);
   if (end == NULL) {
      end=Bars(symbol,period);
   }
   
   CopyBuffer(handle,buffer_number,start,end,buffer);
   
   // This function reverse the buffer array so that newest are displayed first
   ArraySetAsSeries(buffer,true);
   
}

void ExportRSI(
      double& buffer[],
      int start = 0,
      int end = NULL,
      string symbol = NULL,
      ENUM_TIMEFRAMES period = 0,
      int ma_period = 12,
      ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE
      ) 
{
   int buffer_number = 0;
   SetIndexBuffer(buffer_number,buffer,INDICATOR_DATA);
   int handle=iRSI(symbol,period,ma_period,applied_price);
   if (end == NULL) {
      end=Bars(symbol,period);
   }
   
   CopyBuffer(handle,buffer_number,start,end,buffer);
   
   // This function reverse the buffer array so that newest are displayed first
   ArraySetAsSeries(buffer,true);
   
}

void ExportMACD(
      double& buffer[],
      int start = 0,
      int end = NULL,
      string symbol = NULL,
      ENUM_TIMEFRAMES period = 0,
      int fast_ema_period = 12,
      int slow_ema_period = 26,
      int signal_period = 9,
      ENUM_APPLIED_PRICE applied_price = PRICE_CLOSE
      ) 
{
   int buffer_number = 0;
   SetIndexBuffer(buffer_number,buffer,INDICATOR_DATA);
   int handle=iMACD(symbol,period,fast_ema_period, slow_ema_period, signal_period, applied_price);
   if (end == NULL) {
      end=Bars(symbol,period);
   }
   
   CopyBuffer(handle,buffer_number,start,end,buffer);
   
   // This function reverse the buffer array so that newest are displayed first
   ArraySetAsSeries(buffer,true);
   
}