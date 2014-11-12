//+------------------------------------------------------------------+
//|                                                      Testing.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---

   int ma_period = 12;
   int start = 0;
   int count = 100;
   ENUM_TIMEFRAMES period = PERIOD_H1;
   
   // Fill in buffer with MA indexes
   double buffer[];
   ExportMA(buffer, start, count, Symbol(), period, ma_period, MODE_EMA, PRICE_CLOSE);

      
   MqlRates  rates_array[];
   ArraySetAsSeries(rates_array,true);
   string symbol = Symbol();
   int all_current_rates=CopyRates(symbol,period,0,count,rates_array);

   int file_handle=FileOpen("test.csv",FILE_WRITE|FILE_CSV);
   for(int i=count-1; i>=0; i--)
     {
      string output_data=StringFormat("%s",TimeToString(rates_array[i].time,TIME_DATE));
      output_data+=","+TimeToString(rates_array[i].time,TIME_MINUTES);
      output_data+=","+ DoubleToString(buffer[i],10);
      output_data+="\n";

      FileWriteString(file_handle,output_data);
     }

   FileClose(file_handle);
   Comment("Exported Successfully");
   
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
//+------------------------------------------------------------------+
