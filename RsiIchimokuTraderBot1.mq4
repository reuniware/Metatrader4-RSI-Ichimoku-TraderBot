//+------------------------------------------------------------------+
//|                                                 RsiIchimokuTraderBot1.mq4 |
//|                     Copyright 2017, ichimokuscanner.000webhostapp.com |
//|                             https://ichimoku-expert.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, investdata.000webhostapp.com"
#property link      "https://ichimoku-expert.blogspot.com"
#property version   "1.00"
#property strict

bool enableFileLog=true;
int file_handle=INVALID_HANDLE; // File handle
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//string exportPath = "C:\\Users\\InvesdataSystems\\Documents\\NetBeansProjects\\investdata\\public_html\\alerts\\data_history";

int OnInit()
  {
   EventSetTimer(10);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
  }

double open_arrayM1[];
double high_arrayM1[];
double low_arrayM1[];
double close_arrayM1[];

bool first_run_done=false;
static datetime LastBarTime[];//=-1;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(first_run_done==false)
     {
      int stotal=SymbolsTotal(true); // seulement les symboles dans le marketwatch (false)

      ArrayResize(LastBarTime,stotal);

      //initialisation de tout le tableau à false car sinon la première valeur vaut true par défaut (bug mt5?).
      for(int sindex=0; sindex<stotal; sindex++)
        {
         LastBarTime[sindex]=-1;
        }

      first_run_done=true;
     }

   int stotal=SymbolsTotal(true); // seulement les symboles dans le marketwatch (false)

   for(int sindex=0; sindex<stotal; sindex++)
     {
      string sname=SymbolName(sindex,true);
      //printf("processing "+sname);

      datetime ThisBarTime=(datetime)SeriesInfoInteger(sname,PERIOD_M1,SERIES_LASTBAR_DATE);
      if(ThisBarTime==LastBarTime[sindex])
        {
         //printf("Same bar time ("+sname+")");
        }
      else
        {
         if(LastBarTime[sindex]==-1)
           {
            //printf("First bar ("+sname+")");
            LastBarTime[sindex]=ThisBarTime;
           }
         else
           {
            //printf("Processing because New bar time ("+sname+")");
            LastBarTime[sindex]=ThisBarTime;

            //recherche si une position existe pour le symbole en cours
            int total=OrdersTotal();
            bool positionFound=false;
            for(int pos=0;pos<total;pos++)
              {
               if(OrderSelect(pos,SELECT_BY_POS)==false) continue;
               //printf(OrderTicket()+" "+OrderOpenPrice()+" "+OrderOpenTime()+" "+OrderSymbol()+" "+OrderLots());

               if(OrderSymbol()==sname)
                 {
                  positionFound=true;
                 }
              }

            MqlTick last_tick;
            double prix_achat;
            double prix_vente;
            double spread;
            SymbolInfoTick(sname,last_tick);
            prix_achat = last_tick.ask;
            prix_vente = last_tick.bid;
            spread=prix_achat-prix_vente;

            const int NUMBER_OF_JCS=4;
            // Obtention des données bougies japonaises
            double open_array[];
            double high_array[];
            double low_array[];
            double close_array[];
            ArraySetAsSeries(open_array,true);
            int numO=CopyOpen(sname,Period(),0,NUMBER_OF_JCS,open_array);
            ArraySetAsSeries(high_array,true);
            int numH=CopyHigh(sname,Period(),0,NUMBER_OF_JCS,high_array);
            ArraySetAsSeries(low_array,true);
            int numL=CopyLow(sname,Period(),0,NUMBER_OF_JCS,low_array);
            ArraySetAsSeries(close_array,true);
            int numC=CopyClose(sname,Period(),0,NUMBER_OF_JCS,close_array);

            // Obtention des données de l'indicateur Ichimoku
            double cs26=iIchimoku(sname,Period(),9,26,52,MODE_CHIKOUSPAN,26);
            double cs27=iIchimoku(sname,Period(),9,26,52,MODE_CHIKOUSPAN,27);
            double tenkan_sen=iIchimoku(sname,Period(),9,26,52,MODE_TENKANSEN,1);
            double kijun_sen=iIchimoku(sname,Period(),9,26,52,MODE_KIJUNSEN,1);
            double ssa=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANA,1); // ssa bougie precedente
            double ssb=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANB,1); // ssb bougie precedente
            double ssa26=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANA,26); // ssa bougie precedente
            double ssb26=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANB,26); // ssb bougie precedente
            double ssa27=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANA,27); // ssa bougie precedente
            double ssb27=iIchimoku(sname,Period(),9,26,52,MODE_SENKOUSPANB,27); // ssb bougie precedente

            double rsi14=iRSI(sname,Period(),14,PRICE_CLOSE,0);
            double rsi14prev=iRSI(sname,Period(),14,PRICE_CLOSE,1);
            double m=iMomentum(sname,Period(),14,PRICE_CLOSE,0);
            double mprev=iMomentum(sname,Period(),14,PRICE_CLOSE,1);

            if(
               open_array[1]<ssa26
               && open_array[1]<ssb26
               && close_array[1]>ssa26
               && close_array[1]>ssb26
               )
              {
               printf(sname+": JCS(-1) is crossing over KUMO");
               printf("rsi14="+DoubleToString(rsi14)+" momentum="+DoubleToString(m));
               if(rsi14>=65)
                 {
                  if(!positionFound)
                    {
                     if(spread<=0.00015)
                       {
                        SendNotification("RSIBT2:"+sname+" Buying.");
                        Buy(sname, 0.05);
                       }
                    }
                 }
              }

            if(
               (rsi14>=60) && (rsi14prev<60)
               && (m>=100.12)
               )
              {
               //printf("Will buy now");
               //Buy(sname,last_tick);

              }

           }
        }

     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Buy(string sname, double lots)
  {
   MqlTick last_tick;
   SymbolInfoTick(sname,last_tick);
   double prix_achat = last_tick.ask;
   double prix_vente = last_tick.bid;
   double spread = prix_achat - prix_vente;

   double stoploss = 0;//prix_achat - 0.00025*2;//prix_achat-0.00100;
                     //double takeprofit=prix_achat+spread+0.00025;
   double takeprofit = prix_achat + spread + prix_achat/100*0.1;  // 0.1% seems optimal

   bool enableTrading=true;
   if(enableTrading)
     {
      int ticket=OrderSend(sname, OP_BUY, lots, prix_achat, 3, stoploss, takeprofit, "My Buy Order", 16384, 0, clrGreen);
      if(ticket<0)
        {
         Print(sname+" : OrderSend failed with error #",GetLastError());
         printf("pa="+DoubleToString(prix_achat));
        }
      else
         Print(sname+" : OrderSend placed successfully");
     }
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
