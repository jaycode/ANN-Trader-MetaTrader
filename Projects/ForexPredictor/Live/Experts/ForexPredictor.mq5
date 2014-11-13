//+------------------------------------------------------------------+
//|                                            ForexPredictor_nn.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"
// #property library "FPDLL.dll";
#property tester_library "FPDLL.dll";

#include "../../Includes/Exporters.mqh"

#import "FPDLL.dll"
   bool Memorize(int size, double &X[][], datetime &time[]);
   bool Predict(datetime time, double ask, double &positions[], double budget, bool& signal, double& take_profit, double& stop_loss, double& volume);
   void GetLog(string &logStr);
#import

input int       Export_Bars = 5; // Number of bars exported for learning.
input ENUM_TIMEFRAMES Export_Period  = PERIOD_D1; // Period between each two learning bars.
input int       Export_NextTickToGuess = 5; // Tick at this position after the last sample will be guessed by our robot.

// Use this to make sure prediction is done once daily. Stored in:
// C:\Users\Username\AppData\Roaming\MetaQuotes\Terminal\Common\Files\ dir
input string lastTickFile = "ForexPredictor\\lastTickTime.txt";

input string logFile = "ForexPredictor\\app.log";

int loghandle;
int tickhandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   loghandle=FileOpen(logFile,FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   FileWrite(loghandle, "log starts - ", (string)TimeCurrent());
   FileFlush(loghandle);
   tickhandle=FileOpen(lastTickFile,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   FileClose(loghandle);
   FileClose(tickhandle);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if (!HavePredicted()) {
      FileSeek(loghandle,0,SEEK_END);
      Log("tick processing...");
      
      // File delete is not allowed because file is not located in MQL5/Files.
      // File cannot be put inside MQL5/Files because of reason.
      // When flag is set to FILE_COMMON delete supposed to work but it doesn't.
      /*
      bool delStatus = FileDelete(tickhandle, FILE_COMMON);
      if (delStatus == false) {
         Log("Delete failed");
      }*/
      FileSeek(tickhandle,0,SEEK_SET);
      FileWrite(tickhandle, (long)TimeCurrent());
      
      MqlTradeRequest request;
      MqlTradeResult result;
      double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);    // Ask price
      double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);    // Bid price
      ZeroMemory(request);
      ZeroMemory(result);
      
      // Our buffers
      double ema3[];
      double ema30[];
      double ema15[];
      double ema60[];
      double sma3[];
      double sma15[];
      double atr3[];
      double atr15[];
      double adx3[];
      double adx15[];
      double stoch3[];
      double stoch15[];
      double rsi3[];
      double rsi15[];
      double macd[];
      MqlRates rates[];
      CopyRates(Symbol(), Export_Period, 1, Export_Bars, rates);
      // True because we want newest data first
      ArraySetAsSeries(rates, true);
      
      ExportMA(ema3, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), MODE_EMA, PRICE_CLOSE);
      ExportMA(ema30, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period), MODE_EMA, PRICE_CLOSE);
      ExportMA(ema15, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), MODE_EMA, PRICE_CLOSE);
      ExportMA(ema60, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period), MODE_EMA, PRICE_CLOSE);
      ExportMA(sma3, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), MODE_SMA, PRICE_CLOSE);
      ExportMA(sma15, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period), MODE_SMA, PRICE_CLOSE);
      ExportATR(atr3, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period));
      ExportATR(atr15, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period));
      ExportADX(adx3, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period));
      ExportADX(adx15, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period));
      ExportStoch(stoch3, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), MODE_SMA, STO_LOWHIGH);
      ExportStoch(stoch15, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period), MODE_SMA, STO_LOWHIGH);
      ExportRSI(rsi3, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), PRICE_CLOSE);
      ExportRSI(rsi15, 0, Export_Bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), PRICE_CLOSE);
      ExportMACD(macd,0, Export_Bars, Symbol(), Export_Period, NormalizeDays(12, Export_Period), NormalizeDays(26, Export_Period), NormalizeDays(9, Export_Period), PRICE_CLOSE);
      
      double X[][];
      ArrayResize(X, Export_Bars);
      double Y[][];
      ArrayResize(Y, Export_Bars);
      
      // Learn using all data above.
      string x_fields[] = [
         'time',
         'ema3ema30',
         'ema15ema60',
         'hpr200',
         'lpr200',
         'sma3sma15',
         'atr3atr15',
         'adx3',
         'adx15',
         'stochk3',
         'stochk15',
         'rsi3',
         'rsi15',
         'macd'
      ];
      string row_y = "signal, bids, asks, " +
      "maxclose"+(Export_NextTickToGuess* PeriodSeconds(Export_Period)/3600)+"h, target, time";
      string y_fields[] = [
         'signal',
         'bids',
         'asks',
         'maxclose' + (Export_NextTickToGuess* PeriodSeconds(Export_Period)/3600)+'h',
         'target',
         'time'
      ]
      
      for(int i=0; i<Export_Bars; i++){
      
         double highest_close = 0;
         double lowest_close = 99999;
         for (int j = i; j < i+200; j++) {
            if (rates[j].close > highest_close) highest_close = rates[j].close;
            if (rates[j].close < lowest_close) lowest_close = rates[j].close;
         }
         X[i][0] = rates[i].time;
         X[i][1] = ema3[i]/ema30[i];
         X[i][2] = ema15[i]/ema60[i];
         X[i][3] = rates[i].close/highest_close;
         X[i][4] = lowest_close/rates[i].close;
         X[i][5] = sma3[i]/sma15[i];
         X[i][6] = atr3[i]/atr15[i];
         X[i][7] = adx3[i];
         X[i][8] = adx15[i];
         X[i][9] = stoch3[i];
         X[i][10] = stoch15[i];
         X[i][11] = rsi3[i];
         X[i][12] = rsi15[i];
         X[i][13] = macd[i];
         Y[i][1] = 
      }
      
      double bids[];
      ArrayResize(bids, Export_Bars);
      double asks[];
      ArrayResize(asks, Export_Bars);
      datetime times[];
      ArrayResize(times, Export_Bars);
      
      for (int i = 0; i < Export_Bars; i++) {
         bids[i] = rates[i].close;
         asks[i] = rates[i].close + rates[i].spread*0.00001;
         times[i] = rates[i].time;
      }
      
      
      // Learn(Export_Bars, X, bids, asks, times);
      Memorize('x_'+Export_Period, x_fields, Export_Bars, X, times);
      string logStr = "";
      GetLog(logStr);
      Log(logStr);
      
      Memorize('y_'+Export_Period, y_fields, Export_Bars, Y, times);
      logStr = "";
      GetLog(logStr);
      Log(logStr);
      
      Learn(Export_Period);
   }
   LogFlush();
}

bool HavePredicted() {
   MqlDateTime time_current_mdt;
   TimeToStruct(TimeCurrent(), time_current_mdt);

   FileSeek(tickhandle,0,SEEK_SET);
   long last_time = long(FileReadString(tickhandle));
   // Log("last_time long is " +last_time);
   // Log("datetime of last_time is " + (string)(datetime)last_time);
   MqlDateTime last_time_mdt;
   TimeToStruct((datetime)last_time,last_time_mdt);
   
   // Log((string)time_current_mdt.day + " vs " + (string)last_time_mdt.day);
   if (time_current_mdt.day == last_time_mdt.day && time_current_mdt.mon == last_time_mdt.mon && 
       time_current_mdt.year == last_time_mdt.year) {
      // Log("return true");
      return true;
   }
   // Log("return false");
   return false;
}

void Log(string text) {
   FileWrite(loghandle,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS)+ " - " + text);
}

void LogFlush()
{
   FileFlush(loghandle);
}