//+------------------------------------------------------------------+
//|                                             ForexPredictorEA.mqh |
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

class ForexPredictorEA
{
   protected:
   public:
      ForexPredictorEA();
      ~ForexPredictorEA();
      void Init();
      void Processing();
      bool ProcessOrder();
}

ForexPredictorEA::ForexPredictorEA()
{
}

ForexPredictorEA::~ForexPredictorEA()
{
}

ForexPredictorEA::Init()
{
   
}

ForexPredictorEA::Processing()
{
}

ForexPredictorEA::ProcessOrder()
{
}