//+------------------------------------------------------------------+
//|                                                         VPEA.mq5 |
//|                                                  Matteo D'Addato |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Matteo D'Addato"
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
//| Libraries                                                        |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <Tools/DateTime.mqh>
enum ENUM_PAIR_TYPE{

   JBP_TYPE = 1,
   STANDARD_TYPE = 2

};
//+------------------------------------------------------------------+
//| Inputs variable                                                  |
//+------------------------------------------------------------------+
input group "---------- Trades parameters ----------";
static input long magicNumber = 765090;            // magic Number
input double lotSize = 1;                          // lot size
input int stopLoss = 30;                           // stoploss in pips (0 = not setted)
input int takeProfit = 90;                         // takeprofit in pips (0 = not setted)
input ENUM_PAIR_TYPE PAIR_TYPE = STANDARD_TYPE;    // select the curre4ncy type for the pips calculation
input group "---------- POC finding parameters ----------";
input double valueAreaOffset = 0.0005;             // valueAreaOffset
input int pocDays = 7;                             // Poc to be considered for the strategy (max 14)
input group "---------- Linear Regression parameters ----------";
input double angularCoefLr = 1.9;                  // angular coefficent for the linar regression
input int linearRegNBars = 50;                     // bars in wich Lienar regression is going to be claculated
input group "---------- Others ----------";
input int closeHourMax = 19;                       // max hour that trade can be running
input bool closeAtCertainHour = true;              // allows the previous input to work
//input int   MAPeriod = 200;                      // MA period to calculate trendline

//+------------------------------------------------------------------+
//| Variavbles                                                       |
//+------------------------------------------------------------------+
CTrade trade;

int buyPos;
int sellPos;
double bufferPOC[];
double bufferTrend[];
double pocIndicatorVal[14];
int actualTrnd;
int trndValues ;
int POChandle;
int trendHandle;
datetime now = TimeCurrent();
MqlDateTime str1; 
//int cont = 14;
int prvTrend;
struct SPoc
{
    double price; // The price level of the POC
    string day; // day of the calculation
};
SPoc pocHistory[14];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+



  
int OnInit()
  {

      if(magicNumber <= 0){
      
         Alert("magic number < 0");
         return INIT_PARAMETERS_INCORRECT;
      
      }
       if(lotSize <= 0 || lotSize > 10){
      
         Alert("lotSize <= 0 or > 10");
         return INIT_PARAMETERS_INCORRECT;
      
      }
       if(stopLoss < 0){
      
         Alert("stopLoss < 0");
         return INIT_PARAMETERS_INCORRECT;
      
      }
      if(stopLoss < 0){
      
         Alert("stopLoss < 0");
         return INIT_PARAMETERS_INCORRECT;
      
      }
      
      trendHandle = iCustom(_Symbol,PERIOD_CURRENT,"Examples/linearregression","Linear_Regression_",PERIOD_CURRENT,linearRegNBars,true,Red,STYLE_SOLID,3,0.618,Black,STYLE_DASH,1,1.618,Black,STYLE_DOT,1,2.618,Black,STYLE_SOLID,3);
      POChandle = iCustom(_Symbol,PERIOD_CURRENT,"vphistogram",10,14,70,Indigo,Magenta,Orange,true);
      ArraySetAsSeries(bufferPOC,true);
      ArraySetAsSeries(bufferTrend,true);
      
      //set expert magic number
      trade.SetExpertMagicNumber(magicNumber);
      
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(trendHandle != INVALID_HANDLE){
   
      IndicatorRelease(trendHandle);
   
   }
   if(POChandle != INVALID_HANDLE){
   
      IndicatorRelease(POChandle);
   
   }
  }
  
//+---------------------------------------------------------------------------+
//| Expert tick function called at every price change (very very very often)  |
//+---------------------------------------------------------------------------+
void OnTick()
  {
      int value = CopyBuffer(POChandle,0,0,14,bufferPOC);
      
      copyArray(bufferPOC,pocIndicatorVal,14);
      
      // get POC indicator values
      now = TimeCurrent();
      TimeToStruct(now,str1);
      
      bool testTrail = trailingStop();
      
      if (str1.hour == 1){     
         
        //saving data for the Storical Pocs every day
            for(int i = 0; i<14; i++){
            
               if(i == 0){
               
                  pocHistory[i].day = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES);
                  pocHistory[i].price = pocIndicatorVal[i];
               
               }else{
               
                   pocHistory[i].day =  TimeToString(TimeCurrent() - (86400*i), TIME_DATE | TIME_MINUTES);
                   pocHistory[i].price = pocIndicatorVal[i];
                   
               }
            }
      }else if (str1.hour == closeHourMax && closeAtCertainHour == true){
      
      for(int i = 0;i<2; i++ ){
      
        
          closePositions(1);
         
         closePositions(2);
      
        
        }
      }
      
      //get current trendline (works)
      
      trndValues = CopyBuffer(trendHandle,0,0,1,bufferTrend);
      
      double currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      
      int trdLine = 0;
      
      //Print("linear regression indicator value : ",bufferTrend[0]);
      
      if(bufferTrend[0] >= angularCoefLr){
      
        currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_BID);
        
        trdLine = 1;
      
      }else if (bufferTrend[0] <= -angularCoefLr) {
      
        trdLine = -1;
      
        currentPrice = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
     
      }
      
      if(pocHistory[0].price>0)
      {
         for(int j = 0; j<pocDays; j++){
              
            if(trdLine == 1 && checkOpen(pocHistory,currentPrice,pocDays,trdLine) && countOpenPositions(buyPos,sellPos,POSITION_TYPE_BUY) && openOneTime(currentPrice) && checkHour(str1) ){
            
               double sl = stopLoss * 0.0001;
               double tp = takeProfit * 0.0001;
               
               if (stopLoss == 0 && takeProfit ==0){
               
                  trade.PositionOpen( _Symbol, ORDER_TYPE_BUY, lotSize, SymbolInfoDouble(_Symbol,SYMBOL_ASK),0,0,"VPEA");
               
               }else{
               
                  trade.PositionOpen( _Symbol, ORDER_TYPE_BUY, lotSize, SymbolInfoDouble(_Symbol,SYMBOL_ASK), currentPrice - sl, currentPrice + tp,"VPEA");
               
               }
               
               
               
            }else if(trdLine == -1 && checkOpen(pocHistory,currentPrice,pocDays,trdLine) && countOpenPositions(buyPos,sellPos,POSITION_TYPE_SELL) && openOneTime(currentPrice) && checkHour(str1)){
            
               double sl = stopLoss * 0.0001;
               double tp = takeProfit * 0.0001;
               
                if (stopLoss == 0 && takeProfit ==0){
               
                  trade.PositionOpen( _Symbol, ORDER_TYPE_SELL, lotSize, SymbolInfoDouble(_Symbol,SYMBOL_BID),0,0,"VPEA");
               
               }else{
               
                  trade.PositionOpen( _Symbol, ORDER_TYPE_SELL, lotSize, SymbolInfoDouble(_Symbol,SYMBOL_BID), currentPrice + sl, currentPrice - tp,"VPEA");
               
               }

            }
         
         }
      }
  }
//+---------------------------------------------------------------------------+
//| Custom functions                                                          |
//+---------------------------------------------------------------------------+

//+---------------------------------------------------------------------------+
//|countOpenPositions                                                         |
//+---------------------------------------------------------------------------+

bool countOpenPositions(int &cntBuy, int &cntSell,ENUM_POSITION_TYPE psType){
   
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0){
         Print("Failed to get position ticket");
         return false;
      }
      if(!PositionSelectByTicket(ticket)){
         Print("Failed to select position");
         return false;
      }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){
         Print("Failed to get position magic");
         return false;
      }
      if(magic==magicNumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){
            Print("Failed to get position type");
            return false;
         }
         if(type == POSITION_TYPE_BUY){
             if(cntBuy + cntSell == 3){return false;}
             cntBuy++;
         }
         if(type == POSITION_TYPE_SELL){
             if(cntBuy + cntSell == 3){return false;}
             cntSell++;
         }
         if(psType ==  POSITION_TYPE_BUY && cntSell > 0){
            
            return false;
         
         }else if(psType ==  POSITION_TYPE_SELL && cntBuy > 0){
         
             return false;
         
         }
         
      }
   
   }
   return true;
}
//+---------------------------------------------------------------------------+
//|checkHour                                                                  |
//+---------------------------------------------------------------------------+

bool checkHour(MqlDateTime &str){

   if(str.hour > 7 && str.hour < 14){
   
      return true;
   
   }
   
   return false;
   
}

//+---------------------------------------------------------------------------+
//|openOneTime                                                                |
//+---------------------------------------------------------------------------+

bool openOneTime(double price){

   double offset =  0.0015;
  
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0){
         Print("Failed to get position ticket");
         return false;
      }
      if(!PositionSelectByTicket(ticket)){
         Print("Failed to select position");
         return false;
      }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){
         Print("Failed to get position magic");
         return false;
      }
      if(magic==magicNumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){
            Print("Failed to get position type");
            return false;
         }
         
         double trdPriceCheck = trade.RequestPrice();
         if(price + offset >  trdPriceCheck && price - offset <  trdPriceCheck){
         
            return false;
         
         }
      }
   
   }
  
   return true;
  
}

//+---------------------------------------------------------------------------+
//|Trailing Stop                                                              |
//+---------------------------------------------------------------------------+

bool trailingStop(){
   
   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0){
         Print("Failed to get position ticket");
         return false;
      }
      if(!PositionSelectByTicket(ticket)){
         Print("Failed to select position");
         return false;
      }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){
         Print("Failed to get position magic");
         return false;
      }
      if(magic==magicNumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){
            Print("Failed to get position type");
            return false;
         }
         if(type == POSITION_TYPE_BUY){
            
            double sl = trade.RequestSL();
            
            double tp = trade.RequestTP();
            
            double op = tp - (takeProfit * 0.0001);
            
            double secondStep = tp - (takeProfit * 0.0001)/3;
            
            double firstStep = tp - (takeProfit * 0.0001)*2/3;
            
            
            if(SymbolInfoDouble(_Symbol,SYMBOL_ASK) + 0.0002 > firstStep && sl < op){
            
               trade.PositionModify(ticket,op + 0.0005,tp); 
                       
          
            }else if(SymbolInfoDouble(_Symbol,SYMBOL_ASK) + 0.0002 > secondStep && sl < firstStep){
            
               trade.PositionModify(ticket,firstStep + 0.0005,tp);
            
            }
         }
         
         
         if(type == POSITION_TYPE_SELL){
         
            double sl = trade.RequestSL();
            
            double tp = trade.RequestTP();
            
            double op = tp + (takeProfit * 0.0001);
            
            double secondStep = tp + (takeProfit * 0.0001)/3;
            
            double firstStep = tp + (takeProfit * 0.0001)*2/3;
            
            
            if(SymbolInfoDouble(_Symbol,SYMBOL_BID) - 0.0002 < firstStep && sl > op){
            
               trade.PositionModify(ticket,op - 0.0005,tp); 
                       
          
            }else if(SymbolInfoDouble(_Symbol,SYMBOL_BID) + 0.0002 < secondStep && sl > firstStep){
            
               trade.PositionModify(ticket,firstStep - 0.0005,tp);
            
            }
         
         
         
         }
      }
   
   }
   return true;
}

//+---------------------------------------------------------------------------+
//|closePositions                                                             |
//+---------------------------------------------------------------------------+
bool closePositions(int all_buy_sell){

   int total = PositionsTotal();
   for(int i=total-1; i>=0; i--){
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0){
         Print("Failed to get position ticket");
         return false;
      }
      if(!PositionSelectByTicket(ticket)){
         Print("Failed to select position");
         return false;
      }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){
         Print("Failed to get position magic");
         return false;
      }
      if(magic==magicNumber){
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){
            Print("Failed to get position type");
            return false;
         }
         if(all_buy_sell == 1 && type == POSITION_TYPE_SELL){continue;}
         if(all_buy_sell == 2 && type == POSITION_TYPE_BUY){continue;}
         trade.PositionClose(ticket);
         if(trade.ResultRetcode() != TRADE_RETCODE_DONE){
            Print("Failed to cose the position. ticket."+(string)ticket+" result:"+(string)trade.ResultRetcode()+":"+trade.CheckResultRetcodeDescription());

         }
      }
   
   }

   return true;
}
//+---------------------------------------------------------------------------+
//|normalizePrice                                                             |
//+---------------------------------------------------------------------------+

bool normalizePrice(double &price){

   double tickSize = 0;
   
   if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize)){
      Print("Failed to get tick size");
      return false;
   }
   
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
   
   return true;
}

//+---------------------------------------------------------------------------+
//|checkOpen                                                                  |
//+---------------------------------------------------------------------------+


bool checkOpen(SPoc &Pocs[], double currPrx, int Cont,int trd){

   for(int i = 0; i<Cont; i++){

      if((Pocs[i].price + valueAreaOffset) > currPrx && (Pocs[i].price - valueAreaOffset) < currPrx){
      
         if(trd == 1 && iLow(_Symbol,PERIOD_CURRENT,1) > Pocs[i].price){
                     
            return true;
         
         }else if(trd == -1 && iHigh(_Symbol,PERIOD_CURRENT,1) < Pocs[i].price){
         
            return true;
         
         }
      
      }
   }
   
   return false;

}

//+---------------------------------------------------------------------------+
//|copyArray                                                                  |
//+---------------------------------------------------------------------------+

void copyArray(double &sourceArray[],double &destArray[],int nElements){
   
   for(int i = 0; i<nElements; i++){
      
      destArray[i] = sourceArray[i];
   }

}
//+---------------------------------------------------------------------------+
//|sortArray                                                                  |
//+---------------------------------------------------------------------------+

void sortArray(double &array[]){

   double app = 0;
   
   for(int i = 0; i<14/2; i++){
   
      app = array[i];
      
      array[i] = array[14-1-i];

      array[ArraySize(array)-1-i] = app;   
   }

}