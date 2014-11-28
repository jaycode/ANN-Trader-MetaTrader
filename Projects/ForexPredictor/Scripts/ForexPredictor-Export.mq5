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
input datetime  Training_Date_Start = D'2000.01.01'; // Start of training date minus 200 trading days.
input datetime  Training_Date_End = D'2013.12.31'; // End of training date.
input datetime  Testing_Date_Start = D'2014.01.01'; // Start of testing date.
input ENUM_TIMEFRAMES Export_Period  = PERIOD_D1; // Tick Period
input int       Export_NextTickToGuess = 5; // Export targets after this * export period (e.g. 5 days forward).
//+------------------------------------------------------------------+

// Add this number of ticks/days to training date start, so if training date starts
// at 2000 jan 1, use data from 2000 jan 1 + 200 trading days. This is needed for
// hpr and lpr calculation.
int hpr_lpr_ticks = 200; 

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
   
   string training_path_inputs;
   string testing_path_inputs;
   
   string training_path_targets;
   string testing_path_targets;
   
   StringConcatenate(training_path_inputs, Export_FileDir, "training_inputs.csv");
   StringConcatenate(testing_path_inputs, Export_FileDir, "testing_inputs.csv");

   StringConcatenate(training_path_targets, Export_FileDir, "training_targets.csv");
   StringConcatenate(testing_path_targets, Export_FileDir, "testing_targets.csv");

   // Create the files
   int file_training_inputs = FileOpen(training_path_inputs, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   int file_testing_inputs = FileOpen(testing_path_inputs, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   
   int file_training_targets = FileOpen(training_path_targets, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   int file_testing_targets = FileOpen(testing_path_targets, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   
   if (file_training_inputs != INVALID_HANDLE && file_testing_inputs != INVALID_HANDLE &&
       file_training_targets != INVALID_HANDLE && file_testing_targets != INVALID_HANDLE)
     {
      // Write the heading of data
      
      // Highest Price Ratio
      // hpr200 = Close/Highest Close 200
      // Lowest Price Ratio
      // lpr200 = Lowest Close 200 / Close
      // mom = Momentum indicator
      string row="time, ema3ema30, ema15ema60, " +
      "hpr200, lpr200, " + 
      "sma3sma15, volsma3sma15, atr3atr15, " + 
      "adx3, adx15, stochk3, stochk15, stochk3stochk15, " + 
      "mom3, mom15, mom3mom15, " +
      "rsi3, rsi15, rsi3rsi15, macd";
      FileWrite(file_training_inputs, row);
      FileWrite(file_testing_inputs, row);
      
      // Bid - dealer bid, we sell price
      // Ask - dealer ask, we buy price
      // Upper target - Highest strength in predicted days.
      // Lower target - Lowest strength in predicted days.
      string row_targets = "time, bids, asks, " +
      "maxclose, " +
      "minclose, uppertarget, lowertarget";
      FileWrite(file_training_targets, row_targets);
      FileWrite(file_testing_targets, row_targets);

      CopyRates(Symbol(), Export_Period, TimeCurrent(), Training_Date_Start, rates);
      int all_bars = ArraySize(rates);
      // False because we want oldest data first
      ArraySetAsSeries(rates, false);
      
      
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
      
      int bar = hpr_lpr_ticks+1;
      while (bar < all_bars - Export_NextTickToGuess)
      {
         double max_close, min_close;
         double upper_target, lower_target;
         CalculateTarget(rates, bar, Export_NextTickToGuess, max_close, min_close, upper_target, lower_target);
         row_targets = (long)rates[bar].time + ", "+(rates[bar].close)+", "+(rates[bar].close+rates[bar].spread*0.00001)+", "+max_close+", "+min_close+", "+upper_target+", "+lower_target;
         row = SetupX(bar);
         if (rates[bar].time <= Training_Date_End) {
            FileWrite(file_training_inputs, row);
            FileWrite(file_training_targets, row_targets);
         }
         else {
            FileWrite(file_testing_inputs, row);
            FileWrite(file_testing_targets, row_targets);
         }
         bar++;
      }
      Print("Exported ", all_bars, " rates");
      Print("Export_NextTickToGuess: ", Export_NextTickToGuess);
      FileClose(file_training_inputs);
      FileClose(file_testing_inputs);
      FileClose(file_training_targets);
      FileClose(file_testing_targets);
      Print("Export of data finished successfully.");
     }
   else Print("Error! Failed to create the file for data export. ", GetLastError());
  }

string SetupX(int current_pos)
{
   double highest_close = 0;
   double lowest_close = 99999;
   /*
   for (int i = current_pos; i < current_pos+Export_NextTickToGuess-1; i++) {
      if (rates[i].close > highest_close) highest_close = rates[i].close;
      if (rates[i].close < lowest_close) lowest_close = rates[i].close;
   }
   */
   for (int i = current_pos - hpr_lpr_ticks; i < current_pos; i++) {
      if (rates[i].close > highest_close) highest_close = rates[i].close;
      if (rates[i].close < lowest_close) lowest_close = rates[i].close;
   }

   
   return (long)rates[current_pos].time + ", " + (ema3[current_pos]/ema30[current_pos])+", "
         +(ema15[current_pos]/ema60[current_pos])+", "
         +(rates[current_pos].close/highest_close)+", "
         +(lowest_close/rates[current_pos].close)+", "
         +(sma3[current_pos]/sma15[current_pos])+", "
         +(atr3[current_pos]/atr15[current_pos])+", "
         +(adx3[current_pos])+", "
         +(adx15[current_pos])+", "
         +(stoch3[current_pos])+", "
         +(stoch15[current_pos])+", "
         +(stoch3[current_pos]/stoch15[current_pos])+", "
         +(rsi3[current_pos])+", "
         +(rsi15[current_pos])+", "
         +(macd[current_pos])
         ;
}
//+------------------------------------------------------------------+