//+------------------------------------------------------------------+
//|                                               PriceHistogram.mq5 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Matteo D'Addato"
#property version   "1.00"

#property description "The indicator «Price histogram» (Market profile)."
#property description "The indicator shows points where the market will be «most convenient» for a trade. "
#property description "It isn't recommended to use it as a separate tool, use it with the other indicators or oscillators."
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1


#include "../include/classexpert.mqh"
//The block of input parameters
input int         DayTheHistogram   = 10;          // Days for histogram
input int         DaysForCalculation= 14;         // Days for calculation(-1 all
input int        RangePercent      = 70;          // Percent range
input color       InnerRange        =Indigo;       // Inner range color
input color       OuterRange        =Magenta;      // Outer range color
input color       ControlPoint      =Orange;       // Point of Control (POC) color
input bool        ShowValue         =true;         // Show Values

// Class variable
CExpert ExtExpert;
double pocBuffer[];
double array[14];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   //--- indicator buffers mapping
    SetIndexBuffer(0,pocBuffer,INDICATOR_DATA);                   //buffer index
    PlotIndexSetString(0,PLOT_LABEL,"POC");                       //buffer label
    IndicatorSetString(INDICATOR_SHORTNAME,"POCIndicator");       //buffer shortname (used in EA)
    ArraySetAsSeries(pocBuffer,true);
    
// Check for the symbol synchronisation before the beginning of calculations
   int err=0;
   while(!(bool)SeriesInfoInteger(Symbol(),0,SERIES_SYNCHRONIZED) && err<AMOUNT_OF_ATTEMPTS)
     {
      Sleep(500);
      err++;
     }
// Initialization of CExpert class
   ExtExpert.RangePercent=RangePercent;
   ExtExpert.InnerRange=InnerRange;
   ExtExpert.OuterRange=OuterRange;
   ExtExpert.ControlPoint=ControlPoint;
   ExtExpert.ShowValue=ShowValue;
   ExtExpert.DaysForCalculation=DaysForCalculation;
   ExtExpert.DayTheHistogram=DayTheHistogram;
   ExtExpert.Init();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ExtExpert.Deinit(reason);
  }
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
  ExtExpert.OnTick(array);
  sortArray(array);
  copyArray(array,pocBuffer,14);
  return rates_total;
  }
//+------------------------------------------------------------------+
//| Expert Event function                                            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,         // event identifier
                  const long& lparam,   // event parameter of long type
                  const double& dparam, // event parameter of double type
                  const string& sparam) // event parameter of string type
  {
   ExtExpert.OnEvent(id,lparam,dparam,sparam);
  }
//+------------------------------------------------------------------+
//| Expert Timer function                                            |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+

void sortArray(double &Array[]){

   double app = 0;
   
   for(int i = 0; i<(14/2) - 1; i++){
   
      app = Array[i];
      
      Array[i] = Array[13-i];

      Array[ArraySize(Array)-1-i] = app;   
   }

}

void copyArray(double &sourceArray[],double &destArray[],int nElements){
   
   for(int i = 0; i<nElements; i++){
      
      destArray[i] = NormalizeDouble(sourceArray[i],5);
   }

}