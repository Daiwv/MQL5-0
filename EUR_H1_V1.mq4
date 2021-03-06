//+--------------------------------------------------------------------+
//|                                            EURUSD H1.mq4           |
//|                                Copyright ?2017, Ncc Software Corp. |
//|                                                 http://www.ncc.com |
//|EURUSD H1  Chart [MaxProfit=15, risk=0.1 , ma1=8,  ma2=34, ma3=55 ] |
//|XAUUSD M30 Chart [MaxProfit=30, risk=0.15, ma1=15, ma2=50, ma3=144] |
//+--------------------------------------------------------------------+
#property copyright "EURUSD H1 Chart | XAUUSD 30M Chart  || Email: 3402066991@qq.com"
#property link      "http://www.quant123.xin"
#property strict

extern double Lot = 0;//设置头寸(0-自动计算)

extern int LotsPersent=12;//启用资金百分比(<30)
 int Slippage=3;//滑点
 double DecreaseFactor=3;//头寸衰减因子

extern int MaxProfit=21;//盈利百分比
extern int sl=54;//止损点数(0-无止损)
//extern int MaxLoss=10;//最大损失百分比

extern int MagicNumber=1597;//魔术数字
extern int MA1=8;// 快线
extern int MA2 = 34;// 中线
extern int MA3 = 55;// 慢线
extern int ma_shift=0;// 偏移
//+------------------------------------------------------------------+
extern bool isTrendTrade=true;//开户趋势加仓
extern int CountBars=6;//计算K线数
extern int Delta=48;//偏离点数

extern bool isEmail=false;//启用发送邮件

//double pt=0.0;

string LastOrder="";
bool isTrade=false;
bool isMaUnderMa3 = false;
bool isBarUderMA3 = false;
bool isNear = false;
bool isMa1V = false;


int Ticket;
datetime OrderTime;
bool OrderOpen=false;

double Equity=0;
double total_lot=0;

double HistoryBuyProfit;
double HistorySellProfit;
double NewHistoryBuyProfit;
double NewHistorySellProfit;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
  {
   //if(true==TimeLimit(2017,11,1))
   //  {
   //   Print("Time out! Please connect the author ：3402066991@qq.com .");
   //   MessageBox("Time out! \n\nPlease connect the author ：3402066991@qq.com .","Action",MB_OK);      
   //   PlaySound("timeout.wav");
   //   ExpertRemove();
   //   return(-1);
   //  }

   //if(Digits==3 || Digits==5) pt=10*Point;
   //else                          pt=Point;
   
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   ExpertRemove();
   return(0);
  }
//+------------------------------------------------------------------+

int start()
  {
   DisplayComment();

//----
   double MA10=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,0);
   double MA11=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,1);
   double MA20=iMA(NULL,0,MA2,ma_shift,MODE_EMA,PRICE_CLOSE,0);
   double MA21=iMA(NULL,0,MA2,ma_shift,MODE_EMA,PRICE_CLOSE,1);
   double MA30=iMA(NULL,0,MA3,ma_shift,MODE_EMA,PRICE_CLOSE,0);
   double MA31=iMA(NULL,0,MA3,ma_shift,MODE_EMA,PRICE_CLOSE,1);

   if(Time[0]!=OrderTime && Time[1]!=OrderTime) OrderOpen=false;

   double vtotal_lot=total_lot;
   
   double Lots=LotsOptimized();

   int HoldingOrders= 0;
   if(OrdersTotal()!=0)
     {
      for(int i=0; i<OrdersTotal(); i++)
        {
         OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber)
           {
            HoldingOrders++;
           }
        }
     }

   if(HoldingOrders==0) Equity=AccountEquity();
////////////////////////////
   if(MA11<MA21 && MA10>=MA20 && MA10>MA30 && OrderOpen==false)
     {
      if(NewLotsCount(OP_SELL)>0){NewHistorySellProfit+=NewHoldingSellProfit(); NewCloseAllSell();}

      if(LotsCount(OP_SELL)>0 && NewLotsCount(OP_BUY)==0)
        {
         Ticket=OrderSend(Symbol(),OP_BUY,LotsCount(OP_SELL),NormalizeDouble(Ask,Digits),Slippage,0,0,"dummy-buy",MagicNumber+1,0,Yellow); 
         if(Ticket>0) total_lot+=LotsCount(OP_SELL);
        }

      Ticket=OrderSend(Symbol(),OP_BUY,Lots,NormalizeDouble(Ask,Digits),Slippage,0,0,"new-buy",MagicNumber,0,Red);
      LastOrder="buy";  isTrade=true;

      if(Ticket>0)
        {
         if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES))
           {
            OrderOpen=true;
            OrderTime=Time[0];
            mSendMail();
            total_lot+=Lots;
            //PlaySound("email.wav");
           }
         else
           {
            Print("Error opening buy order : ",GetLastError());
            return(0);
           }
        }
     }
   else
   if(MA11>MA21 && MA10<=MA20 && MA10<MA30 && OrderOpen==false)
     {
      if(NewLotsCount(OP_BUY)>0){NewHistoryBuyProfit+=NewHoldingBuyProfit(); NewCloseAllBuy();}

      if(LotsCount(OP_BUY)>0 && NewLotsCount(OP_SELL)==0)
        {
         Ticket=OrderSend(Symbol(),OP_SELL,LotsCount(OP_BUY),NormalizeDouble(Bid,Digits),Slippage,0,0,"dummy-sell",MagicNumber+1,0,Green); 
         if(Ticket>0) total_lot+=LotsCount(OP_BUY);
        }

      Ticket=OrderSend(Symbol(),OP_SELL,Lots,NormalizeDouble(Bid,Digits),Slippage,0,0,"new-sell",MagicNumber,0,Blue);
      LastOrder="sell";  isTrade=true;

      if(Ticket>0)
        {
         if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES))
           {
            OrderOpen=true;
            OrderTime=Time[0];
            mSendMail();
            total_lot+=Lots;
            // PlaySound("email.wav");
           }
         else
           {
            Print("Error opening sell order : ",GetLastError());
            return(0);
           }
        }
     }
////////////////////
   if(isTrendTrade && isTrendSell())
     {
      Ticket=OrderSend(Symbol(),OP_SELL,Lots,NormalizeDouble(Bid,Digits),Slippage,0,0,"trend-sell",MagicNumber,0,Lime); 

      if(Ticket>0)
        {
         if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES))
           {
            isTrade=false;
            mSendMail();
            total_lot+=Lots;
            // PlaySound("email.wav");
           }
         else
           {
            Print("Error opening sell order : ",GetLastError());
            return(0);
           }
        }
     }
   else
   if(isTrendTrade && isTrendBuy())
     {
      Ticket=OrderSend(Symbol(),OP_BUY,Lots,NormalizeDouble(Ask,Digits),Slippage,0,0,"trend-buy",MagicNumber,0,Magenta); 

      if(Ticket>0)
        {
         if(OrderSelect(Ticket,SELECT_BY_TICKET,MODE_TRADES))
           {
            isTrade=false;
            mSendMail();
            total_lot+=Lots;
            // PlaySound("email.wav");
           }
         else
           {
            Print("Error opening buy order : ",GetLastError());
            return(0);
           }
        }
     }

//---------------------------
   if(AccountEquity()-Equity>=AccountEquity()*MaxProfit/100)
     {
      CloseAllSell();CloseAllBuy(); NewCloseAllSell();NewCloseAllBuy();
      NewHistorySellProfit=0; HistoryBuyProfit=0; NewHistoryBuyProfit=0; HistorySellProfit=0;
     }
//        if(Equity-AccountEquity()>=AccountEquity()*MaxLoss/100){CloseAllSell();CloseAllBuy();}
//         CloseAllLossBuy(); CloseAllLossSell();


   if(MA11<MA21 && MA10>=MA20)CloseAllWinSell();
   if(MA11>MA21 && MA10<=MA20)CloseAllWinBuy();

   if(iMA(NULL,0,3,0,MODE_EMA,PRICE_CLOSE,0)<MA11 && iMA(NULL,0,3,0,MODE_EMA,PRICE_CLOSE,0)>MA10)CloseAllWinSell();
   if(iMA(NULL,0,3,0,MODE_EMA,PRICE_CLOSE,0)>MA11 && iMA(NULL,0,3,0,MODE_EMA,PRICE_CLOSE,0)<MA10)CloseAllWinBuy();

//        if(High[1]<MA11 && High[0]>MA10)CloseAllWinSell();
//        if(Low[1]>MA11 && Low[0]<=MA10)CloseAllWinBuy();

   if(HoldingBuyProfit()+HistoryBuyProfit+NewHoldingSellProfit()+NewHistorySellProfit>AccountEquity()*MaxProfit/100/2)
     {
      CloseAllBuy(); NewCloseAllSell(); NewHistorySellProfit=0; HistoryBuyProfit=0;
     }
   if(HoldingSellProfit()+HistorySellProfit+NewHoldingBuyProfit()+NewHistoryBuyProfit>AccountEquity()*MaxProfit/100/2)
     {
      CloseAllSell(); NewCloseAllBuy(); NewHistoryBuyProfit=0; HistorySellProfit=0;
     }

   if(isTrailStop) TrailingStop();
/*

*/
   if(vtotal_lot!=total_lot)
      Print(StringSubstr(Symbol(),0,6)+" Total Lots: "+DoubleToStr(total_lot,2));
//----
   return(0);
  }
// -------------------------------------------------

//////////////////////////////////////////////////////////////////// 
double CalDrawDown(int type=2)
  {
   double ddv=0.0;
   if(type==2) 
     {
      ddv =(AccountEquity()/AccountBalance()-1.0)/(-0.01);
      if(ddv <= 0.0) return (0);
      return (ddv);
     }
   if(type==1) 
     {
      ddv = 100.0 *(AccountEquity()/AccountBalance()-1.0);
      if(ddv <= 0.0) return (0);
      return (ddv);
     }
   return (0.0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DisplayComment()
  {
   string ddv=DoubleToString(CalDrawDown(2),2);
   double prov=0.0;
   
   for (int i = 0; i < OrdersHistoryTotal(); i++)
      if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol() && OrderType() <= OP_SELL)
         prov += OrderProfit();    
   
   Comment(
           "\nSanXianZhiLu V1.0",
           "\nAccount Leverage  :  "+"1 : "+AccountLeverage(),
           "\nAccount Type  :  "+AccountServer(),
           "\nServer Time  :  "+TimeToStr(TimeCurrent(),TIME_SECONDS),
           "\nAccount Equity  = ",AccountEquity(),
           "\nFree Margin     = ",AccountFreeMargin(),
           "\nTotal Profit    = "+DoubleToString(AccountProfit(),2),
           "\nHolding Lots     = "+DoubleToString(LotsCount(OP_BUY)+LotsCount(OP_SELL),2),
           "\n    OP_BUY      = "+DoubleToString(LotsCount(OP_BUY),2),
           "\n    OP_SELL     = "+DoubleToString(LotsCount(OP_SELL),2),
           "\nLot size     =  "+DoubleToString(LotsOptimized(),2),
           "\nDrawdown  :  ",ddv,
           " \n"+Symbol()," Earnings  :  "+DoubleToString(prov,2)
           );
  }
///////////////////////////////////////

//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double LotsOptimized()
  {
   double lv;
   int    orders=OrdersHistoryTotal();     // history orders total
   int    losses=0;                  // number of losses orders without a break

   if(AccountEquity()<=50) {Comment("\nNo enough money to open new order!"); return(0.0);}
   
   if(Lot>0)
      lv=Lot;
   else
      lv=(AccountFreeMargin() * 0.001 * LotsPersent * 0.01);   //lv=(AccountFreeMargin() / 1000.0 * LotsPersent /100.0);
//--- calcuulate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      for(int i=orders-1;i>=0;i--)
        {
         if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
           {
            Print("Error in history!");
            break;
           }
         if(OrderSymbol()!=Symbol() || OrderType()>OP_SELL)
            continue;
         //---
         if(OrderProfit()>0) break;
         if(OrderProfit()<0) losses++;
        }
      if(losses>1)
         lv=NormalizeDouble(lv-lv*losses/DecreaseFactor,1);
     }
//--- 
// make sure trader has set Lots to at least the minimum lot size of the broker and 
// we will normalize the Lots variable so we can properly open an order
   if(MarketInfo(Symbol(),MODE_MINLOT)==0.01)
     {
      if(lv<0.01)    lv=0.01;
      lv=NormalizeDouble(lv,2);
     }
   if(MarketInfo(Symbol(),MODE_MINLOT)==0.1)
     {
      lv=NormalizeDouble(lv,1);
      if(lv<0.1)
         lv=0.1;
     }
   if(MarketInfo(Symbol(),MODE_MINLOT)==1)
     {
      lv=NormalizeDouble(lv,0);
      if(lv<1)
         lv=1;
     }
//---
   double minl = MarketInfo(Symbol(),MODE_MINLOT);
   double maxl = MarketInfo(Symbol(),MODE_MAXLOT);

   if(lv<=minl) lv=minl;
   if(lv>=maxl) lv=maxl;

   return(lv);
  }

//+------------------------------------------------------------------+
extern bool isTrailStop=true; //开启移动止损
extern int TrailStop=36;   //移动止损距离
extern int TrailShag=6; //止损保护距离
//+------------------------------------------------------------------+
//|                      移动止损                                    |
//+------------------------------------------------------------------+
void  TrailingStop()
  {
   bool err;
   double newSL=0.0;

   for(int i=0; i<OrdersTotal(); i++)
     {
      err=OrderSelect(i,SELECT_BY_POS,MODE_TRADES);
      
      if(OrderSymbol()!= Symbol()) continue;
      if(MagicNumber != OrderMagicNumber()) continue;
      
      if(sl>30 && OrderStopLoss()==0)
        {
         if(OrderType()==OP_BUY )  newSL=OrderOpenPrice()-Point*10*sl;
         if(OrderType()==OP_SELL )  newSL=OrderOpenPrice()+Point*10*sl;
         
         err=OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,Yellow);
        }
        
      if(TrailStop>0 && OrderType()==OP_BUY && OrderSymbol()==Symbol())
        {
         newSL=Bid-Point*10*TrailStop;
         if(newSL>=OrderOpenPrice() && newSL>OrderStopLoss())
           {
            if((newSL-OrderStopLoss())>=TrailShag*Point*10)
              {
               err=OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,Yellow);
               if(err==false){Print("修改订单错误: ",GetLastError());}
              }
           }
        }////

      if(TrailStop>0 && OrderType()==OP_SELL && OrderSymbol()==Symbol())
        {
         newSL=Ask+TrailStop*Point*10;
         if(OrderOpenPrice()>=newSL && OrderStopLoss()>newSL)
           {
            if((OrderStopLoss()-newSL)>TrailShag*Point*10)
              {
               err=OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,Yellow);
               if(err==false){Print("修改订单错误: ",GetLastError());}
              }
           }

         if(OrderOpenPrice()>=newSL && OrderStopLoss()==0)
           {
            if(OrderProfit()>0)
              {
               err=OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,Green);
               if(err==false){Print("修改订单错误: ",GetLastError());}
              }
           }
        }
     }////
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllSell()
  {
   bool CAS = FALSE;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber)
         CAS=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Yellow);  
      // PlaySound("news.wav");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllBuy()
  {
   bool CAB = FALSE;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber)
         CAB=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Yellow);  
      // PlaySound("news.wav");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllWinSell()
  {
   bool CAWS= FALSE;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber && OrderProfit()>0.0)
        {
         HistorySellProfit+=OrderProfit();
         CAWS=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Yellow);  
         // PlaySound("news.wav");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllLossSell()
  {
   bool CAWS= FALSE;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber && OrderProfit()<0.0)
        {
         HistorySellProfit+=OrderProfit();
         CAWS=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Yellow);  
         //  PlaySound("news.wav");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllWinBuy()
  {
   bool CAWB= FALSE;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber && OrderProfit()>0.0)
        {
         HistoryBuyProfit+=OrderProfit();
         CAWB=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Yellow);  
         //  PlaySound("news.wav");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllLossBuy()
  {
   bool CAWB= FALSE;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber && OrderProfit()<0.0)
        {
         HistoryBuyProfit+=OrderProfit();
         CAWB=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Yellow);  
         //  PlaySound("news.wav");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double HoldingBuyProfit()
  {
   double BuyProfit=0;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber)
         BuyProfit+=OrderProfit();
     }
   return (BuyProfit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double HoldingSellProfit()
  {
   double SellProfit=0;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber)
         SellProfit+=OrderProfit();
     }
   return (SellProfit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NewHoldingBuyProfit()
  {
   double NewBuyProfit=0;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber+1)
         NewBuyProfit+=OrderProfit();
     }
   return (NewBuyProfit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NewHoldingSellProfit()
  {
   double NewSellProfit=0;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber+1)
         NewSellProfit+=OrderProfit();
     }
   return (NewSellProfit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LotsCount(int type)
  {
   double BuyLots=0;
   double SellLots=0;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber )BuyLots+=OrderLots();
      if(OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber )SellLots+=OrderLots();
     }
   switch(type)
     {
      case OP_BUY:   return (BuyLots); break;
      case OP_SELL:  return (SellLots); break;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NewLotsCount(int type)
  {
   double BuyLots=0;
   double SellLots=0;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType() == OP_BUY && OrderMagicNumber() == MagicNumber+1 )BuyLots+=OrderLots();
      if(OrderType() == OP_SELL && OrderMagicNumber() == MagicNumber+1 )SellLots+=OrderLots();
     }
   switch(type)
     {
      case OP_BUY: return (BuyLots); break;
      case OP_SELL: return (SellLots); break;
     }
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void NewCloseAllSell()
  {
   bool CAS = FALSE;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_SELL && OrderMagicNumber()==MagicNumber+1)
         CAS=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Yellow);
      // PlaySound("news.wav");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void NewCloseAllBuy()
  {
   bool CAB = FALSE;
   for(int t=0; t<OrdersTotal(); t++)
     {
      OrderSelect(t,SELECT_BY_POS,MODE_TRADES);
      if(OrderType()==OP_BUY && OrderMagicNumber()==MagicNumber+1)
         CAB=OrderClose(OrderTicket(),OrderLots(),NormalizeDouble(OrderClosePrice(),Digits),Slippage,Yellow);
      //  PlaySound("news.wav");
     }
  }
//+------------------------------------------------------------------+
//|                     time limit function                          |
//+------------------------------------------------------------------+
bool TimeLimit(int myyear,int mymonth,int myday)
  {
   if(Year()<=myyear)
     {
      if(Month()<=mymonth)
        {
         if(Day()<=myday)
           {
            return(true);
           }
        }
     }
   return(false);
  }
//+------------------------------------------------------------------+
bool isTrendSell()
  {
   int iNear=999;
   int val_index=0;
   double MA100,MA200,MA300,BarVal=0,MA1N2,MA1P2,MA1A2;
   if(LastOrder=="sell" && isTrade)
     {
      val_index=iLowest(NULL,0,MODE_HIGH,CountBars,1);
      if(val_index!=-1) BarVal=Low[val_index];
      //find 
      for(int i=0;i<=CountBars;i++)
        {
         MA300=iMA(NULL,0,MA3,ma_shift,MODE_EMA,PRICE_CLOSE,i);//now
         MA200=iMA(NULL,0,MA2,ma_shift,MODE_EMA,PRICE_CLOSE,i);//now  
         MA100=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,i);//now

         if(MA100<=MA300 && MA200<=MA300) // ma15 and  ma50 both under ma144
           { isMaUnderMa3=true;}
         else//if ma15 or ma50 up ma144 ,exit and do nothing
           {
            isMaUnderMa3=false;
            return false;
            break;
           }
         // the highest bar of near CountBars is under ma144
         //if(MathAbs(BarVal-MA300)<=Beta*Point*10)
         if(MA300>=BarVal)
           {
            isBarUderMA3=true; //Print("MA300-BarVal = ",MA300-BarVal," Delta*Point = ",Delta*Point );
           }
         else
           {isBarUderMA3=false; return false; break;}
         // is MA1 up to near MA2?
         if((MA200-MA100)<=Delta*Point*10)//Delta=13
           {
            isNear=true;
            iNear=i;//Print("near  MA200-MA100= ",MA200-MA100,"  iNear= ",i);
           }
         else
           {
            isNear= false;
            iNear = 999;
           }
        }
      // is MA1 is like '^' at iNear?
      if(iNear!=999 && iNear!=0)
        {
         MA1N2=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,iNear);//now i 
         MA1P2=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,iNear+1);//pre  
         MA1A2=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,iNear-1);//after

         if(MA1P2<MA1N2 && MA1A2<MA1N2)//
           {
            //Print("MA1N2= ",MA1N2," > MA1A2= ",MA1A2," ^ iNear= ",iNear);
            isMa1V=true;
           }
         else
           {isMa1V=false;}
        }

      if(isMaUnderMa3 && isBarUderMA3 && isNear && isMa1V)
        {
         return true;
        }
      else
         return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isTrendBuy()
  {
   int iNear=999;
   int val_index=0;
   double MA100,MA200,MA300,BarVal,MA1N2,MA1P2,MA1A2;
   if(LastOrder=="buy" && isTrade)
     {
      val_index=iHighest(NULL,0,MODE_HIGH,CountBars,1);
      BarVal=High[val_index];

      //find 
      for(int i=0;i<=CountBars;i++)
        {
         MA300=iMA(NULL,0,MA3,ma_shift,MODE_EMA,PRICE_CLOSE,i);//now
         MA200=iMA(NULL,0,MA2,ma_shift,MODE_EMA,PRICE_CLOSE,i);//now  
         MA100=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,i);//now
                                                               // ma15 and  ma50 both under ma144
         if(MA100>MA300 && MA200>MA300)
           { isMaUnderMa3=true;}
         else//if ma15 or ma50 up ma144 ,exit and do nothing
           {
            isMaUnderMa3=false;
            return false;
            break;
           }
         // the highest bar of near CountBars is under ma144
         //if(MathAbs(BarVal-MA300)<=Beta*Point*10)
         if(BarVal>=MA300)
           {
            isBarUderMA3=true;
           }
         else
           {isBarUderMA3=false; return false; break;}
         // is MA1 up to near MA2?
         if((MA100-MA200)<=Delta*Point*10)//Delta=13
           {
            isNear= true;
            iNear = i;
           }
         else
           {
            isNear= false;
            iNear = 999;
            return false;
           }
        }
      // is MA1 is like 'V' at iNear?
      if(iNear!=999 && iNear!=0)
        {
         MA1N2=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,iNear);//now i 
         MA1P2=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,iNear+1);//pre  
         MA1A2=iMA(NULL,0,MA1,ma_shift,MODE_EMA,PRICE_CLOSE,iNear-1);//after
         if(MA1P2>MA1N2 && MA1A2>MA1N2)
           {
            isMa1V=true;
           }
         else
           {isMa1V=false; return false;}
        }

      if(isMaUnderMa3 && isBarUderMA3 && isNear && isMa1V)
        {
         return true;
        }
      else
         return false;
     }
   return false;
  }
//+------------------------------------------------------------------+
void mSendMail()
  {
   string  mes;
   if(isEmail)
     {
      mes=StringSubstr(Symbol(),0,6)+" "
          +OrderComment()+" "
          +DoubleToString(OrderLots(), 2)+" @ "
          +DoubleToString(OrderOpenPrice(),Digits)
          +"\n\t帐户余额: "+DoubleToString(AccountBalance(), 2)
          +"\n\t帐户净值: "+DoubleToString(AccountEquity(), 2)
          +"\n\t浮动盈亏: "+DoubleToString(AccountProfit(), 2)
          +"\n\t持仓头寸："
          +"\n\t\t总计："+DoubleToString(LotsCount(OP_BUY)+LotsCount(OP_SELL), 2)
          +"\n\t\t\t多单："+DoubleToString(LotsCount(OP_BUY), 2)
          +"\n\t\t\t空单："+DoubleToString(LotsCount(OP_SELL), 2)
          ;
      SendMail(OrderComment(),mes);
     }
  }
//+------------------------------------------------------------------+
