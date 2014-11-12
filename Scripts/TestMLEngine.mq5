//+------------------------------------------------------------------+
//|                                                 MatlabEngineLib  |
//|                                                 TestMLEngine.mq5 |
//|                        Copyright 2010, MetaQuotes Software Corp. |
//|                                           http://www.mql5.com/ru |
//+------------------------------------------------------------------+
#property copyright "2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com/ru"
#property version   "1.00"
#import "MatlabEngine.ex5"
bool mlOpen(void);
void mlClose(void);
bool mlInputChar(string array);
bool mlInputDouble(double &array[],
                   int sizeArray,
                   string NameArray);
bool mlInputInt(int &array[],
                int sizeArray,
                string NameArray);
int mlGetDouble(double &array[],
                string NameArray);
int mlGetInt(int &array[],
             string NameArray);
bool mlInputLogical(bool &array[],
                    int sizeArray,
                    string NameArray);
int mlGetLogical(bool &array[],
                 string NameArray);
int mlGetSizeOfName(string strName);
#import
void OnStart()
  {
// Dynamic buffers for MATLAB output
   double dTestOut[];
   int    nTestOut[];
   bool   bTestOut[];
// Variables for MATLAB input
   double dTestIn[] = {   1,     2,    3,     4};
   int    nTestIn[] = {   9,    10,   11,    12};
   bool   bTestIn[] = {true, false, true, false};
   int nSize=0;
// Variables names and command line
   string strComm="clc; clear all;"; // command line - clear screen and variables
   string strA     = "A";            // variable A
   string strB     = "B";            // variable B
   string strC     = "C";            // variable C
/*
   ** 1. RUNNING DLL
   */
   if(mlOpen()==true)
     {
      printf("MATLAB has been loaded");
     }
   else
     {
      printf("Matlab ERROR! Load error.");
      mlClose();
      return;
     }
/*
   ** 2. PASSING THE COMMAND LINE
   */
   if(mlInputChar(strComm)==true)
     {
      printf("Command line has been passed into MATLAB");
     }
   else printf("ERROR! Passing the command line error");
/*
   ** 3. PASSING VARIABLE OF THE DOUBLE TYPE
   */
   if(mlInputDouble(dTestIn,ArraySize(dTestIn),strA)==true)
     {
      printf("Variable of the double type has been passed into MATLAB");
     }
   else printf("ERROR! Error when passing string of the double type");
/*
   ** 4. GETTING VARIABLE OF THE DOUBLE TYPE
   */
   if((nSize=mlGetDouble(dTestOut,strA))>0)
     {
      int ind=0;
      printf("Variable A of the double type has been got into MATLAB, with size = %i",nSize);
      for(ind=0; ind<nSize; ind++)
        {
         printf("A = %g",dTestOut[ind]);
        }
     }
   else printf("ERROR! Variable of the double type double hasn't ben got");
/*
   ** 5. PASSING VARIABLE OF THE INT TYPE
   */
   if(mlInputInt(nTestIn,ArraySize(nTestIn),strB)==true)
     {
      printf("Variable of the int type has been passed into MATLAB");
     }
   else printf("ERROR! Error when passing string of the int type");
/*
   ** 6. GETTING VARIABLE OF THE INT TYPE
   */
   if((nSize=mlGetInt(nTestOut,strB))>0)
     {
      int ind=0;
      printf("Variable B of the int type has been got into MATLAB, with size = %i",nSize);
      for(ind=0; ind<nSize; ind++)
        {
         printf("B = %i",nTestOut[ind]);
        }
     }
   else printf("ERROR! Variable of the int type double hasn't ben got");
/*
   ** 7. PASSING VARIABLE OF THE BOOL TYPE
   */
   if(mlInputLogical(bTestIn,ArraySize(bTestIn),strC)==true)
     {
      printf("Variable of the bool type has been passed into MATLAB");
     }
   else printf("ERROR! Error when passing string of the bool type");
/*
   ** 8. GETTING VARIABLE OF THE BOOL TYPE
   */
   if((nSize=mlGetLogical(bTestOut,strC))>0)
     {
      int ind=0;
      printf("Variable C of the bool type has been got into MATLAB, with size = %i",nSize);
      for(ind=0; ind<nSize; ind++)
        {
         printf("C = %i",bTestOut[ind]);
        }
     }
   else printf("ERROR! Variable of the bool type double hasn't ben got");
/*
   ** 9. ENDING WORK
   */
   mlClose();
  }
