
//+------------------------------------------------------------------+
//|                                          Export Indicator Values |
//+------------------------------------------------------------------+
#property description "This Script Export Indicators Values to CSV File."
#property description "(You can change the iCustom function parameters to change what indicator to export)"
#property copyright "NFTrader"
#property version   "2.00"
#property script_show_inputs

input int    IndicatorPeriod=14;
input string Indicator_Directory_And_Name="Examples\\RSI";
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   MqlRates  rates_array[];
   string sSymbol=Symbol();

// Convert Period to string to use it in the file name
   string  sPeriod=EnumToString(Period());
// Comment to appear in the up left screen
   Comment("Exporting ... Please wait... ");

// Prepare file name, e.g: EURUSD_PERIOD_H1(RSI,14)
   string       ExtFileName; // ="XXXXXX_PERIOD_H1(RSI,14).CSV";
   ExtFileName=sSymbol;
   int pos=StringFind(Indicator_Directory_And_Name,"\\",0);
   string indicatorName=StringSubstr(Indicator_Directory_And_Name,pos+1,-1);
   string indicatorPeriod=IntegerToString(IndicatorPeriod);
   StringConcatenate(ExtFileName,sSymbol,"_",sPeriod,"(",indicatorName,",",indicatorPeriod,")",".CSV");

   ArraySetAsSeries(rates_array,true);
   int MaxBar=TerminalInfoInteger(TERMINAL_MAXBARS);
   int iCurrent=CopyRates(sSymbol,Period(),0,MaxBar,rates_array);

   double IndicatorBuffer[];
   SetIndexBuffer(0,IndicatorBuffer,INDICATOR_DATA);

   int bars=Bars(sSymbol,PERIOD_CURRENT);
   int to_copy=bars;

   int rsiHandle=iCustom(sSymbol,PERIOD_CURRENT,Indicator_Directory_And_Name,IndicatorPeriod);       // Change here.

   CopyBuffer(rsiHandle,0,0,to_copy,IndicatorBuffer);
   ArraySetAsSeries(IndicatorBuffer,true);

   int fileHandle=FileOpen(ExtFileName,FILE_WRITE|FILE_CSV);

   for(int i=iCurrent-IndicatorPeriod-1; i>0; i--)
     {
      string outputData=StringFormat("%s",TimeToString(rates_array[i].time,TIME_DATE));
      outputData+=","+TimeToString(rates_array[i].time,TIME_MINUTES);
      outputData+=","+ DoubleToString(IndicatorBuffer[i],2);
      outputData+="\n";

      FileWriteString(fileHandle,outputData);
     }

   FileClose(fileHandle);
   Comment("Exported Successfully");
  }
//+------------------------------------------------------------------+