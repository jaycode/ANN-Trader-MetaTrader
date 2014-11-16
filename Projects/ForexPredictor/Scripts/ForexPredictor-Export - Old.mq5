//+------------------------------------------------------------------+
//|                                     ForexPredictor_nn-Export.mq5 |
//|                                                              Jay |
//|                                       http://www.teguhwijaya.com |
//+------------------------------------------------------------------+
#property copyright "Jay"
#property description "This is an exporter script to prepare our hypothesis."
#property link      "http://www.teguhwijaya.com"
#property version   "1.00"

#property script_show_inputs
#include "../Includes/Exporters.mqh"
//+------------------------------------------------------------------+
// x = input
// y = output
input string    Export_FileDir      = "ForexPredictor\\"; // File for exporting (in the folder "MQL5\Files")
input int       Export_Bars_Training = 300; // Number of lines of each y to be exported for training (number of rows exported are this times y variants).
input int       Export_Bars_CrossValidation = 200; // Number of lines of each y to be exported for cross-validation.
input int       Export_Bars_Testing  = 30; // Number of lines of each y to be exported for testing.
input ENUM_TIMEFRAMES Export_Period  = PERIOD_D1; // Tick Period
input int       Export_NextTickToGuess = 5; // Tick at this position after the last sample will be guessed by our robot.
input double    Export_OutputThreshold = 0.5; // When target is higher than this, generate buy signal (sell otherwise).
input double    swap = 0.2; // Swap is broker's fee for keeping a trade open, calculated daily of all current trades.
//+------------------------------------------------------------------+


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
   
void OnStart() 
  {
   
   string training_path_x;
   string crossvalidation_path_x;
   string testing_path_x;
   
   string training_path_y;
   string crossvalidation_path_y;
   string testing_path_y;
   
   StringConcatenate(training_path_x, Export_FileDir, "training_x.csv");
   StringConcatenate(crossvalidation_path_x, Export_FileDir, "cross-validation_x.csv");
   StringConcatenate(testing_path_x, Export_FileDir, "testing_x.csv");

   StringConcatenate(training_path_y, Export_FileDir, "training_y.csv");
   StringConcatenate(crossvalidation_path_y, Export_FileDir, "cross-validation_y.csv");
   StringConcatenate(testing_path_y, Export_FileDir, "testing_y.csv");

   // Create the files
   int file_training_x = FileOpen(training_path_x, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   int file_crossvalidation_x = FileOpen(crossvalidation_path_x, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   int file_testing_x = FileOpen(testing_path_x, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   
   int file_training_y = FileOpen(training_path_y, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   int file_crossvalidation_y = FileOpen(crossvalidation_path_y, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   int file_testing_y = FileOpen(testing_path_y, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   
   if (file_training_x != INVALID_HANDLE && file_crossvalidation_x != INVALID_HANDLE && file_testing_x != INVALID_HANDLE &&
       file_training_y != INVALID_HANDLE && file_crossvalidation_y != INVALID_HANDLE && file_testing_y != INVALID_HANDLE)
     {
      // Write the heading of data
      
      // Highest Price Ratio
      // hpr200 = Close/Highest Close 200
      // Lowest Price Ratio
      // lpr200 = Lowest Close 200 / Close
      string row="time, ema3ema30, ema15ema60, " +
      "hpr200, lpr200, " + 
      "sma3sma15, atr3atr15, " + 
      "adx3, adx15, stochk3, stochk15, rsi3, rsi15, macd";
      FileWrite(file_training_x, row);
      FileWrite(file_crossvalidation_x, row);
      FileWrite(file_testing_x, row);
      
      // Bid - we sell price
      // Ask - we buy price
      string row_y = "time, signal, bids, asks, " +
      "maxclose"+(Export_NextTickToGuess* PeriodSeconds(Export_Period)/3600)+"h, target";
      FileWrite(file_training_y, row_y);
      FileWrite(file_crossvalidation_y, row_y);
      FileWrite(file_testing_y, row_y);
      
      // Go through history and get a number of trades used in training, cross validation, and testing.
      int count = Export_Bars_CrossValidation + Export_Bars_Training + Export_Bars_Testing;

      int all_bars = Bars(Symbol(),Export_Period);
      if (CopyRates(Symbol(), Export_Period, 1, all_bars, rates) < count)
        {
         Print("Error! Not enough history for data export.");
         return;
        }
      // True because we want newest data first
      ArraySetAsSeries(rates, true);
      
      
      ExportMA(ema3, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), MODE_EMA, PRICE_CLOSE);
      ExportMA(ema30, 0, all_bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period), MODE_EMA, PRICE_CLOSE);
      ExportMA(ema15, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), MODE_EMA, PRICE_CLOSE);
      ExportMA(ema60, 0, all_bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period), MODE_EMA, PRICE_CLOSE);
      ExportMA(sma3, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), MODE_SMA, PRICE_CLOSE);
      ExportMA(sma15, 0, all_bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period), MODE_SMA, PRICE_CLOSE);
      ExportATR(atr3, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period));
      ExportATR(atr15, 0, all_bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period));
      ExportADX(adx3, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period));
      ExportADX(adx15, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period));
      ExportStoch(stoch3, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), MODE_SMA, STO_LOWHIGH);
      ExportStoch(stoch15, 0, all_bars, Symbol(), Export_Period, NormalizeDays(15, Export_Period), MODE_SMA, STO_LOWHIGH);
      ExportRSI(rsi3, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), PRICE_CLOSE);
      ExportRSI(rsi15, 0, all_bars, Symbol(), Export_Period, NormalizeDays(3, Export_Period), PRICE_CLOSE);
      ExportMACD(macd,0, all_bars, Symbol(), Export_Period, NormalizeDays(12, Export_Period), NormalizeDays(26, Export_Period), NormalizeDays(9, Export_Period), PRICE_CLOSE);
      
      int counter = 0;
      int count_y_buy = 0;
      int count_y_sell = 0;
      
      // for (int bar=0; bar<count-Export_SampleTicks-Export_NextTickToGuess; bar++)
      int bar = Export_NextTickToGuess-1;
      while (counter < count*2 && bar < all_bars)
      {
         bool write = false;
         // Checks if target is larger or within or less than threshold.
         double max_close;
         double target = CalculateTarget(rates, bar, Export_NextTickToGuess, max_close);
         // When there are space left within an x (and y) set, add a new line into it.
         if (target > Export_OutputThreshold && count_y_buy < count) {
            count_y_buy++;
            counter++;
            write = true;
            row_y = (long)rates[bar].time + ", 1, "+(rates[bar].close)+", "+(rates[bar].close+rates[bar].spread*0.00001)+", "+max_close+", "+target;
            row = SetupX(bar);
            if (count_y_buy < Export_Bars_CrossValidation) {
               FileWrite(file_crossvalidation_x, row);
               FileWrite(file_crossvalidation_y, row_y);
            }
            else if (count_y_buy < (Export_Bars_CrossValidation + Export_Bars_Training)) {
               FileWrite(file_training_x, row);
               FileWrite(file_training_y, row_y);
            }
            else if (count_y_buy < (Export_Bars_CrossValidation + Export_Bars_Training + Export_Bars_Testing)) {
               FileWrite(file_testing_x, row);
               FileWrite(file_testing_y, row_y);
            }
         }
         else if (target <= Export_OutputThreshold && count_y_sell < count) {
            count_y_sell++;
            counter++;
            write = true;
            
            row_y = (long)rates[bar].time + ", 0, "+(rates[bar].close)+", "+(rates[bar].close+rates[bar].spread*0.00001)+", "+max_close+", "+target;
            row = SetupX(bar);
            if (count_y_sell < Export_Bars_CrossValidation) {
               FileWrite(file_crossvalidation_x, row);
               FileWrite(file_crossvalidation_y, row_y);
            }
            else if (count_y_sell < (Export_Bars_CrossValidation + Export_Bars_Training)) {
               FileWrite(file_training_x, row);
               FileWrite(file_training_y, row_y);
            }
            else if (count_y_sell < (Export_Bars_CrossValidation + Export_Bars_Training + Export_Bars_Testing)) {
               FileWrite(file_testing_x, row);
               FileWrite(file_testing_y, row_y);
            }
         }
         
         bar++;
      }
      if (bar == all_bars) {
         Print("Export failed. Please use smaller number for Export Threshold.");
      }
      FileClose(file_training_x);
      FileClose(file_crossvalidation_x);
      FileClose(file_testing_x);
      FileClose(file_training_y);
      FileClose(file_crossvalidation_y);
      FileClose(file_testing_y);
      Print("Export of data finished successfully.");
     }
   else Print("Error! Failed to create the file for data export. ", GetLastError());
  }

string SetupX(int bar)
{
   double highest_close = 0;
   double lowest_close = 99999;
   for (int i = bar; i < bar+200; i++) {
      if (rates[i].close > highest_close) highest_close = rates[i].close;
      if (rates[i].close < lowest_close) lowest_close = rates[i].close;
   }
   
   return (long)rates[bar].time + ", " + (ema3[bar]/ema30[bar])+", "
         +(ema15[bar]/ema60[bar])+", "
         +(rates[bar].close/highest_close)+", "
         +(lowest_close/rates[bar].close)+", "
         +(sma3[bar]/sma15[bar])+", "
         +(atr3[bar]/atr15[bar])+", "
         +(adx3[bar])+", "
         +(adx15[bar])+", "
         +(stoch3[bar])+", "
         +(stoch15[bar])+", "
         +(rsi3[bar])+", "
         +(rsi15[bar])+", "
         +(macd[bar])
         ;
}
//+------------------------------------------------------------------+