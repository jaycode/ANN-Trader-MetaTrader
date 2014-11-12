#property script_show_inputs
//+------------------------------------------------------------------+
input string    Export_FileName = "NeuroSolutions\\data.csv"; // File for exporting (in the folder "MQL5\Files")
input int       Export_Bars     = 260; // Number of lines to be exported
//+------------------------------------------------------------------+
void OnStart() 
  {
  
   // Create the file
   int file = FileOpen(Export_FileName, FILE_WRITE|FILE_CSV|FILE_ANSI, ',');
   
   if (file != INVALID_HANDLE)
     {
      // Write the heading of data
      
      string row="";
      for (int i=0; i<=5; i++)
        {
         if (StringLen(row)) row += ",";
         row += "Open"+i+",High"+i+",Low"+i+",Close"+i;
        }
      FileWrite(file, row);
      
      // Copy all required information from the history
      
      MqlRates rates[], rate;
      int count = Export_Bars + 5;
      if (CopyRates(Symbol(), Period(), 1, count, rates) < count)
        {
         Print("Error! Not enough history for exporting of data.");
         return;
        }
      ArraySetAsSeries(rates, true);
      
      // Write data      
      
      for (int bar=0; bar<Export_Bars; bar++)
        {
         row="";
         double zlevel=0;
         for (int i=0; i<=5; i++)
           {
            if (StringLen(row)) row += ",";
            rate = rates[bar+i];
            if (i==0) zlevel = rate.open; // level for counting of prices
            row += NormalizeDouble(rate.open -zlevel, Digits()) + ","
                 + NormalizeDouble(rate.high -zlevel, Digits()) + ","
                 + NormalizeDouble(rate.low  -zlevel, Digits()) + ","
                 + NormalizeDouble(rate.close-zlevel, Digits());
           }
         FileWrite(file, row);
        }

      FileClose(file);
      Print("Export of data finished successfully.");
     }
   else Print("Error! Failed to create the file for data export. ", GetLastError());
  }
//+------------------------------------------------------------------+