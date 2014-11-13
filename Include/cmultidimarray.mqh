//+------------------------------------------------------------------+
//|                                               CMultiDimArray.mqh |
//|                                                          Integer |
//|                          https://login.mql5.com/ru/users/Integer |
//+------------------------------------------------------------------+
#property copyright "Integer"
#property link "https://login.mql5.com/ru/users/Integer"
//+------------------------------------------------------------------+
//|   Base class                                                     |
//+------------------------------------------------------------------+
class CArrayBase
  {
public:
   CArrayBase       *D[];
   double            V[];

   void ~CArrayBase()
     {
      for(int i=ArraySize(D)-1; i>=0; i--)
        {
         if(CheckPointer(D[i])==POINTER_DYNAMIC)
           {
            delete D[i];
           }
        }
     }
  };
//+------------------------------------------------------------------+
//|   Child class 1                                                  |
//+------------------------------------------------------------------+
class CDim : public CArrayBase
  {
public:
   void CDim(int Size)
     {
      ArrayResize(D,Size);
     }
  };
//+------------------------------------------------------------------+
//|   Child class 1                                                  |
//+------------------------------------------------------------------+
class CArr : public CArrayBase
  {
public:
   void CArr(int Size)
     {
      ArrayResize(V,Size);
     }
  };
//+------------------------------------------------------------------+
