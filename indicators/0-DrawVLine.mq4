//+------------------------------------------------------------------+
//|                                                  0-DrawVLine.mq4 |
//|                                                   Copyright 2018 |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

//+------------------------------------------------------------------+
input bool show_pivots=True;
input bool show_dvline=True;
input bool obj_back=True;
input bool CandleTime_Enabled=True;
input ENUM_LINE_STYLE line_style;
input int line_width=0;
int offDay=10;

string stime,stime2;
string sv1,sv2,sv3,sv4;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(offDay>=23 || offDay<=0) offDay=10;
   if(StringSubstr(Symbol(),0,6)=="XAUUSD")
     {
      sv1=" 01:00"; sv2=" 06:45"; sv3=" 12:30"; sv4=" 18:15";
     }
   else
     {
      sv1=" 00:00"; sv2=" 06:00"; sv3=" 12:00"; sv4=" 18:00";
     }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   ObjectsDeleteAll(0,OBJ_VLINE);
   ObjectDelete("num");
   ObjectDelete("WeekOpenLine");
   ObjectDelete("valTime");

   ObjectDelete("Pivot");
   ObjectDelete("FibS1");
   ObjectDelete("FibR1");
   ObjectDelete("FibS2");
   ObjectDelete("FibR2");
   ObjectDelete("FibS3");
   ObjectDelete("FibR3");

   ObjectDelete("pp");
   ObjectDelete("ps1");
   ObjectDelete("ps2");
   ObjectDelete("ps3");
   ObjectDelete("pr1");
   ObjectDelete("pr2");
   ObjectDelete("pr3");
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
//---
   if(show_dvline) 
      ShowDeltaLine();
   ShowDeltaNum();
   DrawHLine("WeekOpenLine",iOpen(NULL,PERIOD_W1,0));
   if(show_pivots) 
      Fib_Pivots();
   if(Period()<=240)
      CandleTime();
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+ //④⑤ ⑧⑨ ⑪
void ShowDeltaNum()
  {
   string name="num";
   if(Period()>PERIOD_M15) {ObjectDelete(name);return;}
   string dnum="";
   if(StringSubstr(Symbol(),0,6)=="GBPUSD") dnum="|1--2-3-4-|5-6--7--8|9--10---11|-12---13-|";
   if(StringSubstr(Symbol(),0,6)=="EURUSD") dnum="|1--2-3-|-4-5-|6-7-8-|9-10-11-|";
   if(ObjectFind(name)==-1)
     {
      ObjectCreate(name,OBJ_LABEL,0,0,0);
      ObjectSetText(name,dnum,16);
      ObjectSet(name,OBJPROP_SELECTABLE,false);
      ObjectSet(name,OBJPROP_XDISTANCE,700);
      ObjectSet(name,OBJPROP_YDISTANCE,5);
     }
  }
//+------------------------------------------------------------------+
void ShowDeltaLine()
  {
   if(Period()>PERIOD_M15) {ObjectsDeleteAll(0,OBJ_VLINE);return;}

   int tday=TimeDay(Time[0]);
   int dday=-1;
   if(dday!=tday)
     {
      if(tday>offDay)
        {
         for(int i=tday-offDay;i<tday+2;i++)
           {
            if(i>31) break;
            stime=TimeYear(Time[0])+"."+TimeMonth(Time[0])+"."+i;
            DrawVLine("vv1_"+i,StrToTime(stime+sv1));
            DrawVLine("vv2_"+i,StrToTime(stime+sv2),Green);
            DrawVLine("vv3_"+i,StrToTime(stime+sv3),Blue);
            DrawVLine("vv4_"+i,StrToTime(stime+sv4),Orange);
           }
         dday=TimeDay(Time[0]);
        }
      else
        {
         for(int i=23+tday-offDay;i<32;i++)
           {
            stime=TimeYear(Time[0])+"."+(TimeMonth(Time[0])-1)+"."+i;
            DrawVLine("vv1_"+i,StrToTime(stime+sv1));
            DrawVLine("vv2_"+i,StrToTime(stime+sv2),Green);
            DrawVLine("vv3_"+i,StrToTime(stime+sv3),Blue);
            DrawVLine("vv4_"+i,StrToTime(stime+sv4),Orange);
           }

         for(int i=1;i<tday+2;i++)
           {
            stime2=TimeYear(Time[0])+"."+TimeMonth(Time[0])+"."+i;
            DrawVLine("vv1_"+i,StrToTime(stime2+sv1));
            DrawVLine("vv2_"+i,StrToTime(stime2+sv2),Green);
            DrawVLine("vv3_"+i,StrToTime(stime2+sv3),Blue);
            DrawVLine("vv4_"+i,StrToTime(stime2+sv4),Orange);
           }
         dday=TimeDay(Time[0]);
        }

     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVLine(string name,datetime time,color clr=clrRed)
  {
   ObjectCreate(name,OBJ_VLINE,0,time,0);
   ObjectSet(name,OBJPROP_COLOR,clr);
   ObjectSet(name,OBJPROP_SELECTABLE,false);
   ObjectSet(name,OBJPROP_STYLE,line_style);
   ObjectSet(name,OBJPROP_WIDTH,line_width);
   ObjectSet(name,OBJPROP_BACK,obj_back);
   WindowRedraw();

  }
//+------------------------------------------------------------------+

void DrawHLine(string name,double price,color clr=Red)
  {
   if(ObjectFind(name)==-1)
     {
      ObjectCreate(name,OBJ_HLINE,0,0,price);
      ObjectSet(name,OBJPROP_COLOR,clr);
      ObjectSet(name,OBJPROP_SELECTABLE,false);
      ObjectSet(name,OBJPROP_STYLE,STYLE_DASH);
      ObjectSet(name,OBJPROP_WIDTH,1);
      WindowRedraw();
     }
   else
     {
      ObjectMove(name,0,0,price);
      WindowRedraw();
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawSLine(string name,datetime t1,double price1,datetime t2,double price2,color clr=Red,ENUM_LINE_STYLE style=STYLE_DOT)
  {
   ObjectDelete(name);
   ObjectCreate(name,OBJ_TREND,0,t1,price1,t2,price2);
   ObjectSet(name,OBJPROP_COLOR,clr);
   ObjectSet(name,OBJPROP_SELECTABLE,false);
   ObjectSet(name,OBJPROP_RAY,false);
   ObjectSet(name,OBJPROP_STYLE,style);
   ObjectSet(name,OBJPROP_WIDTH,1);
   WindowRedraw();
  }
//+------------------------------------------------------------------+

string Pivot="Pivot Point",FibS1="S 1", FibR1="R 1";
string FibS2="S 2", FibR2="R 2", FibS3="S 3", FibR3="R 3";
int fontsize=10;
double P,R,S1,R1,S2,R2,S3,R3;
double LastHigh,LastLow,x;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Fib_Pivots()
  {
   int    counted_bars=IndicatorCounted();
   int limit,i;
//---- indicator calculation
   if(counted_bars==0)
     {
      x=Period();
      if(x>60) return;
      ObjectCreate("Pivot",OBJ_TEXT,0,0,0);
      ObjectSetText("Pivot","Pivot ",fontsize,"Arial",White);
      ObjectCreate("FibS1",OBJ_TEXT,0,0,0);
      ObjectSetText("FibS1"," S1 ",fontsize,"Arial",Lime);
      ObjectCreate("FibR1",OBJ_TEXT,0,0,0);
      ObjectSetText("FibR1"," R1 ",fontsize,"Arial",Lime);
      ObjectCreate("FibS2",OBJ_TEXT,0,0,0);
      ObjectSetText("FibS2"," S2 ",fontsize,"Arial",Yellow);
      ObjectCreate("FibR2",OBJ_TEXT,0,0,0);
      ObjectSetText("FibR2"," R2 ",fontsize,"Arial",Yellow);
      ObjectCreate("FibS3",OBJ_TEXT,0,0,0);
      ObjectSetText("FibS3"," S3 ",fontsize,"Arial",Red);
      ObjectCreate("FibR3",OBJ_TEXT,0,0,0);
      ObjectSetText("FibR3"," R3 ",fontsize,"Arial",Red);
     }
   if(counted_bars<0) return;
//---- last counted bar will be recounted
//   if(counted_bars>0) counted_bars--;
   limit=(Bars-counted_bars)-2;
//----
   for(i=limit; i>=0;i--)
     {
      if(High[i+1]>LastHigh) LastHigh=High[i+1];
      if(Low[i+1]<LastLow) LastLow=Low[i+1];
      if(TimeDay(Time[i])!=TimeDay(Time[i+1]))
        {
         P=(LastHigh+LastLow+Close[i+1])/3;
         R=LastHigh-LastLow;
         R1=P + (R * 0.382);
         S1=P - (R * 0.382);
         R2=P + (R * 0.618);
         S2=P - (R * 0.618);
         R3=P + (R * 0.99);
         S3=P - (R * 0.99);
         LastLow=Open[i]; LastHigh=Open[i];
         ///----
         ObjectMove("Pivot",0,Time[i],P);
         ObjectMove("FibS1",0,Time[i],S1);
         ObjectMove("FibR1",0,Time[i],R1);
         ObjectMove("FibS2",0,Time[i],S2);
         ObjectMove("FibR2",0,Time[i],R2);
         ObjectMove("FibS3",0,Time[i],S3);
         ObjectMove("FibR3",0,Time[i],R3);

         if(Period()<240)
           {
            datetime t1=StringToTime(TimeToStr(Time[0],TIME_DATE)+" 00:00");
            datetime t2=StringToTime(TimeToStr(Time[0],TIME_DATE)+" 23:55");

            DrawSLine("pp",t1,P,t2,P,clrWhite,0);
            DrawSLine("ps1",t1,S1,t2,S1,clrLime,2);
            DrawSLine("pr1",t1,R1,t2,R1,clrLime,2);
            DrawSLine("ps2",t1,S2,t2,S2,clrYellow,2);
            DrawSLine("pr2",t1,R2,t2,R2,clrYellow,2);
            DrawSLine("ps3",t1,R3,t2,R3,clrRed,2);
            DrawSLine("pr3",t1,S3,t2,S3,clrRed,2);
           }
        }
     }
  }
//+------------------------------------------------------------------+
void CandleTime()
  {
   int m,tmp;
   string s,txt="";

   if(CandleTime_Enabled==TRUE)
     {
      m=Time[0]+60*Period()-TimeCurrent();
      tmp=m%60;
      m=(m-tmp)/60;
      if(m>=0)
        {
         s=tmp;
         if(StringLen(s)==1) s="0"+s;
        }
      if(ObjectFind("valTime")==-1)
        {
         ObjectCreate("valTime",OBJ_TEXT,0,0,0);
         ObjectSet("valTime",OBJPROP_SELECTABLE,false);
        }

      txt="                      <--"+m+":"+s+"  "+DoubleToString((Ask-Bid)/Point,0);
      ObjectSetText("valTime",txt,14,"Verdana",clrWhite);
      ObjectMove("valTime",0,Time[0],Ask);

     }
   else
     {
      if(ObjectFind("valTime")!=-1)
         ObjectDelete("valTime");
     }
  }
//+------------------------------------------------------------------+
