//+------------------------------------------------------------------+
//|                                                 MatlabEngineLib  |
//|                                                 MatlabEngine.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                           http://www.mql5.com/ru |
//+------------------------------------------------------------------+
#property library
#property copyright "2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com/ru"
#property version   "1.00"
//+------------------------------------------------------------------+
//| DECLARATION OF IMPORTED FUNCTIONS                                |
//+------------------------------------------------------------------+
#import "LibMlEngine.dll"
void   mlxClose(void);
bool   mlxOpen(void);
bool   mlxInputChar(char &CharArray[]);
bool   mlxInputDouble(double &dArray[],
                      int sizeArray,
                      char &CharNameArray[]);
bool   mlxInputInt(double &dArray[],
                   int sizeArray,
                   char &CharNameArray[]);
bool   mlxInputLogical(double &dArray[],
                       int sizeArray,
                       char &CharNameArray[]);
int    mlxGetDouble(double &dArray[],
                    int sizeArray,
                    char &CharNameArray[]);
int    mlxGetInt(double &dArray[],
                 int sizeArray,
                 char &CharNameArray[]);
int    mlxGetLogical(double &dArray[],
                     int sizeArray,
                     char &CharNameArray[]);
int    mlxGetSizeOfName(char &CharNameArray[]);
#import
//+------------------------------------------------------------------+
//| Function for MATLAB Engine, MATLAB ver 7.4                       |
//+------------------------------------------------------------------+
bool mlOpen(void)export
  {//100% ready. Test: OK.
//+------------------------------------------------------------------+
//| Start MATLAB virtual machine                                     |
//|                                                                  |
//| Function output: true - everything OK! false - start error       |
//+------------------------------------------------------------------+
   return(mlxOpen());
  }
//+------------------------------------------------------------------+
void mlClose(void)export
  {//100% ready. Test: OK.
//+------------------------------------------------------------------+
//| Close MATLAB virtual machine                                     |
//|                                                                  |
//| Function input/output: none!                                     |
//+------------------------------------------------------------------+
   mlxClose();
   return;
  }
//+------------------------------------------------------------------+
bool mlInputChar(string array)export
  {//100% ready. Test: OK.
//+-----------------------------------------------------------------------------------+
//| Passing variable of the string type to MATLAB virtual machine                     |
//|                                                                                   |
//| Input variables:                                                                  |
//+------------+----------------------------------------------------------------------+
//| array[]    | variable of the string type to be passed into MATLAB  virtual machine|
//+------------+----------------------------------------------------------------------+
//| Function output: true - everything OK! false - error in passing of data           |
//+-----------------------------------------------------------------------------------+
// Function variables
   char CharArray[];      // dynamic array for string of characters
   int sizeCharArray = 0; // size of dynamic array for string of characters
                          // Function code
// Convert string into array of characters
   sizeCharArray=StringToCharArray(array,CharArray,0,-1);
   if(sizeCharArray>0)
     {// Passing data to MATLAB desktop: if false - MATLAB error
      return(mlxInputChar(CharArray));
     }
   else
      return false;       // Internal error of MT 5!
  }
//+------------------------------------------------------------------+
bool mlInputDouble(double &array[],int sizeArray,string NameArray)export
  {//100% ready. Test: OK.
//+-----------------------------------------------------------------------------+
//| Passing variable of the double type to MATLAB virtual machine               |
//|                                                                             |
//| Input variables:                                                            |
//+------------+----------------------------------------------------------------+
//| array[]    | array of the double type to be passed                          |
//+------------+----------------------------------------------------------------+
//| sizeArray  | size of array[], i.e. number of elements! not in bytes!        |
//+------------+----------------------------------------------------------------+
//| NameArray  | string of variable name in MATLAB                              |
//+------------+----------------------------------------------------------------+
//| Function output: true - everything OK! false - error in passing of data     |
//+-----------------------------------------------------------------------------+
// Function variables
   double    TempArray[]; // dynamic array for data
   char  CharNameArray[]; // dynamic array for string of characters
   int sizeCharArray = 0; // size of dynamic array for string of characters
                          // Function code
// Convert string into array of characters
   sizeCharArray=StringToCharArray(NameArray,CharNameArray,0,-1);
   if(ArrayIsSeries(array)==true)
     { // Timeseries array
      // Override the size of dynamic array
      if(ArrayResize(TempArray,sizeArray,0)==sizeArray)
        {
         int ind=0;       // main index of loop
         while(ind<sizeArray)
           {// Reverse array
            TempArray[sizeArray-ind-1]=array[ind];
            ind++;// increment index
           }
        }
      else
         return false;    // Internal error of MT 5!
      // Passing data to MATLAB desktop: if false - MATLAB error
      return(mlxInputDouble(TempArray,sizeArray,CharNameArray));
     }
// Passing data to MATLAB desktop: if false - MATLAB error
   return(mlxInputDouble(array,sizeArray,CharNameArray));
  }
//+------------------------------------------------------------------+
int mlGetSizeOfName(string strName)export
  {//100% ready. Test: OK.
//+------------------------------------------------------------------+
//| Function returns the size of variable/array                      |
//|                                                                  |
//| Function output: 0 - error, >0 no error                          |
//+------------------------------------------------------------------+
   char CharArray[];      // dynamic array for string of characters
                          // Convert string into array of characters
   StringToCharArray(strName,CharArray,0,-1);
   return(mlxGetSizeOfName(CharArray));
  }
//+-------------------------------------------------------------------+
int mlGetDouble(double &array[],string NameArray)export
  {//100% ready. Тест: нет.
//+----------------------------------------------------------------------+
//| Get variable of the double type from MATLAB virtual machine          |
//|                                                                      |
//| WARNING!                                                             |
//| This function returns arrays with orientation, used in MATLAB,       |
//| i.e. arrays are not timeseries.                                      |
//|                                                                      |
//| Input variables:                                                     |
//+------------+---------------------------------------------------------+
//| array[]    | variable/array of the double type to get data           |
//+------------+---------------------------------------------------------+
//| NameArray  | string of variable name in MATLAB                       |
//+------------+---------------------------------------------------------+
//| Function output: new size of array[] - everything OK, else 0 - error!|
//+----------------------------------------------------------------------+
// Function variables
   char CharNameArray[];  // dynamic array for string of characters
   int  sizeArray = 0;    // size of output array
                          // Function code
// Convert string into array of characters
   StringToCharArray(NameArray,CharNameArray,0,-1);
// Check size for error
   if((sizeArray=mlxGetSizeOfName(CharNameArray))<1)
     {
      return(0);          // size error!
     }
   else
     {
      ArrayResize(array,sizeArray,0);
      return(mlxGetDouble(array,sizeArray,CharNameArray));
     }
  }
//+------------------------------------------------------------------+
bool mlInputInt(int &array[],int sizeArray,string NameArray)export
  {//100% ready. Test: OK.
//+------------------------------------------------------------------------+
//| Passing variable of the int type to MATLAB virtual machine             |
//|                                                                        |
//| Input variables:                                                       |
//+------------+-----------------------------------------------------------+
//| array[]    | array of the int type to be passed                        |
//+------------+-----------------------------------------------------------+
//| sizeArray  | size of array[], i.e. number of elements! not in bytes!   |
//+------------+-----------------------------------------------------------+
//| NameArray  | string of variable name in MATLAB                         |
//+------------+-----------------------------------------------------------+
//| Function output: true - everything OK! false - error in passing of data|
//+------------------------------------------------------------------------+
// Function variables
   double TempArray[];    // dynamic array for data
   char CharNameArray[];  // dynamic array for string of characters
                          // Convert string into array of characters
   StringToCharArray(NameArray,CharNameArray,0,-1);
   if(ArrayResize(TempArray,sizeArray,0)!=sizeArray) return false;
// If array is passed, check its orientation
   if(ArrayIsSeries(array)==true)
     {// Timeseries array
      int ind=0;          // main index of loop
      while(ind<sizeArray)
        {// Array conversion + reversing
         TempArray[sizeArray-ind-1]=array[ind];
         ind++;           // index increment
        }
      // Passing data to MATLAB desktop: if false - MATLAB error
      return(mlxInputInt(TempArray,sizeArray,CharNameArray));
     }
   else
     {
      int ind=0;          // main index of loop      
      while(ind<sizeArray)
        {// Array conversion 
         TempArray[ind]=array[ind];
         ind++;           // index increment
        }
      // Passing data to MATLAB desktop: if false - MATLAB error
      return(mlxInputInt(TempArray,sizeArray,CharNameArray));
     }
  }
//+-------------------------------------------------------------------+
int mlGetInt(int &array[],string NameArray)export
  {//100% ready. Test: OK.
//+----------------------------------------------------------------------+
//| Get variable of the int type from MATLAB virtual machine             |
//|                                                                      |
//| WARNING!                                                             |
//| This function returns arrays with orientation, used in MATLAB,       |
//| i.e. arrays are not timeseries.                                      |
//|                                                                      |
//| Input variables:                                                     |
//+------------+---------------------------------------------------------+
//| array[]    | variable/array of the double type to get data           |
//+------------+---------------------------------------------------------+
//| NameArray  | string of variable name in MATLAB                       |
//+------------+---------------------------------------------------------+
//| Function output: new size of array[] - everything OK, else 0 - error!|
//+----------------------------------------------------------------------+
// Function variables
   double TempArray[];    // dynamic array for data
   char CharNameArray[];  // dynamic array for string of characters
   int sizeArray = 0;     // size of output array
                          // Function code
// Convert string into array of characters
   StringToCharArray(NameArray,CharNameArray,0,-1);
// Get array size
   sizeArray=mlxGetSizeOfName(CharNameArray);
// Check size for error
   if(sizeArray<1)
     {
      return(0);          // MATLAB error!
     }
   else
     {
      // Override sizes of dynamic arrays
      if(ArrayResize(TempArray,sizeArray,0)!=sizeArray)return 0;
      if(ArrayResize(array,sizeArray,0)!=sizeArray)return 0;
      if(mlxGetInt(TempArray,sizeArray,CharNameArray)<1) return 0;
      int ind=0;
      while(ind<sizeArray)
        {
         array[ind]=TempArray[ind];
         ind++;
        }
      return(sizeArray);
     }
  }
//+------------------------------------------------------------------+
bool mlInputLogical(bool &array[],int sizeArray,string NameArray)export
  {//100% ready. Test: OK.
//+-------------------------------------------------------------------------+
//| Passing variable of the bool type to MATLAB virtual machine             |
//|                                                                         |
//| Input variables:                                                        |
//+------------+------------------------------------------------------------+
//| array[]    | array of the bool type to be passed                        |
//+------------+------------------------------------------------------------+
//| sizeArray  | size of array[], i.e. number of elements! not in bytes!    |
//+------------+------------------------------------------------------------+
//| NameArray  | string of variable name in MATLAB                          |
//+------------+------------------------------------------------------------+
//| Function output: true - everything OK! false - error in passing of data |
//+-------------------------------------------------------------------------+
// Function variables
   double TempArray[];    // dynamic array for data
   char CharNameArray[];  // dynamic array for string of characters
                          // Function code
// Convert string into array of characters
   StringToCharArray(NameArray,CharNameArray,0,-1);
   if(ArrayResize(TempArray,sizeArray,0)!=sizeArray) return false;
// If array is passed, check its orientation
   if(ArrayIsSeries(array)==true)
     {// Timeseries array
      int ind=0;          // main index of loop
      while(ind<sizeArray)
        {// Array conversion + reversing
         TempArray[sizeArray-ind-1]=array[ind];
         ind++;           // index increment
        }
      // Passing data to MATLAB desktop: if false - MATLAB error
      return(mlxInputLogical(TempArray,sizeArray,CharNameArray));
     }
   else
     {
      int ind=0;          // main index of loop      
      while(ind<sizeArray)
        {// Array conversion 
         TempArray[ind]=array[ind];
         ind++;           // index increment
        }
      // Passing data to MATLAB desktop: if false - MATLAB error
      return(mlxInputLogical(TempArray,sizeArray,CharNameArray));
     }
  }
//+-------------------------------------------------------------------+
int mlGetLogical(bool &array[],string NameArray)export
  {//100% ready. Test: OK.
//+----------------------------------------------------------------------+
//| Get variable of the bool type from MATLAB virtual machine            |
//|                                                                      |
//| WARNING!                                                             |
//| This function returns arrays with orientation, used in MATLAB,       |
//| i.e. arrays are not timeseries.                                      |
//|                                                                      |
//| Input variables:                                                     |
//+------------+---------------------------------------------------------+
//| array[]    | variable/array of the bool type to get data             |
//+------------+---------------------------------------------------------+
//| NameArray  | string of variable name in MATLAB                       |
//+------------+---------------------------------------------------------+
//| Function output: new size of array[] - everything OK, else 0 - error!|
//+----------------------------------------------------------------------+
// Function variables
   double TempArray[];    // dynamic array for data
   char CharNameArray[];  // dynamic array for string of characters
   int sizeArray = 0;     // size of output array
                          // Function code
// Convert string into array of characters
   StringToCharArray(NameArray,CharNameArray,0,-1);
// Get array size
   sizeArray=mlxGetSizeOfName(CharNameArray);
// Check size for error
   if(sizeArray<1)
     {
      return(0);          // MATLAB error!
     }
   else
     {
      // Override sizes of dynamic arrays
      if(ArrayResize(TempArray,sizeArray,0)!=sizeArray) return(0);
      if(ArrayResize(array,sizeArray,0)!=sizeArray) return(0);
      if(mlxGetLogical(TempArray,sizeArray,CharNameArray)<1) return(0);
      int ind=0;
      while(ind<sizeArray)
        {
         array[ind]=TempArray[ind];
         ind++;
        }
      return(sizeArray);
     }
  }
//+------------------------------------------------------------------+
