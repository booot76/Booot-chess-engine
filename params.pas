unit params;
// Юнит хранит все глобальные переменные проекта
interface
uses Windows;
Type

    BitBoard  = int64;
    EgtbPieses = array[1..5,1..2] of integer;
    EgtbResult = array [1..2] of integer;
    ByteArray = array[0..63] of integer;
    charArray = array[0..63] of string[2];
    Move = integer;   {0..7 -From }
                      {8..15 - To }
                      {16..19- PieseFrom}
                      {20..23- PieseTo}
                      {24..27- Promoting Piese}
                      {28 - Capture}
                      {29 - Promote}
                      {30 - Castle}
                      {31 - EnPassant}

   Tarray = array[-6..6] of integer;
   TTree = record
             EnnPass : integer;
             Castle  : integer;
             Wking   : integer;
             Bking   : integer;
             MatEval : integer;
             Wmat    : integer;
             Bmat    : integer;
             HashKey : int64;
             PHash   : cardinal;
             onCheck : boolean;
             Hashmove: integer;
             Hflag   : integer;
             status  : integer;
             curr    : integer;
             bmove   : integer;
             cmove   : integer;
           end;
  Tundo = record
            color:integer;
            WP: int64;
            BP: int64;
            WN:int64;
            BN:int64;
            WB:int64;
            BB:int64;
            WR:int64;
            BR:int64;
            WQ:int64;
            BQ:int64;
            WK:int64;
            BK:int64;
            EnnPass: integer;
            castle:integer;
            r50 : integer;
            rep : integer;
            mtc : integer;
          end;
  Thash = record
               key   : int64;
               move  : integer;
               age   : byte;
               draft : byte;
               minvalue  : integer;
               mindepth  : byte;
               movedepth : byte;
               maxdepth  : byte;
               maxvalue  : integer;
               Matethreat:boolean;
             end;
  Tentry = array[1..4] of thash;        
 TPawn = record
          key : cardinal;
          pscore: smallint;
          pend:smallint;
          wpassvector : byte;
          bpassvector : byte;
          wdef:integer;
          bdef:integer;
         end;
 TTime=record
       TimeMode:integer;
       NumberMoves:integer;
       BaseTime:integer;
       Increment:integer;
     end;

 Tmod=array[0..40960] of byte;
 tsaf=array[0..15,0..15] of integer; 
Const
     MaxPly=50;

     HashNoFound=50000;
     Mate=32700;
     Pawn=1;
     Knight=2;
     Bishop=3;
     Rook=4;
     Queen=5;
     King=6;
     Empty=0;
     white=0;
     black=1;
     BadIndex=1000000000;
     a1=0 ;b1=1 ;c1=2 ;d1=3 ;e1=4 ;f1=5 ;g1=6 ;h1=7 ;
     a2=8 ;b2=9 ;c2=10;d2=11;e2=12;f2=13;g2=14;h2=15;
     a3=16;b3=17;c3=18;d3=19;e3=20;f3=21;g3=22;h3=23;
     a4=24;b4=25;c4=26;d4=27;e4=28;f4=29;g4=30;h4=31;
     a5=32;b5=33;c5=34;d5=35;e5=36;f5=37;g5=38;h5=39;
     a6=40;b6=41;c6=42;d6=43;e6=44;f6=45;g6=46;h6=47;
     a7=48;b7=49;c7=50;d7=51;e7=52;f7=53;g7=54;h7=55;
     a8=56;b8=57;c8=58;d8=59;e8=60;f8=61;g8=62;h8=63;

     PawnValue=100;
     KnightValue=400;
     BishopValue=400;
     RookValue=600;
     QueenValue=1200;
     EGTBWIN=12*PawnValue;
     minorshort=3;
     rookshort=5;
     queenshort=9;
     Exact=0;
     Upper=1;
     Lower=2;
     HashValue=2100000000;
     ForsValue=2000000000;
     KillerValue=1500000000;
     Used=-2100000000;
R90 : ByteArray =
     ( a1,a2,a3,a4,a5,a6,a7,a8,
       b1,b2,b3,b4,b5,b6,b7,b8,
       c1,c2,c3,c4,c5,c6,c7,c8,
       d1,d2,d3,d4,d5,d6,d7,d8,
       e1,e2,e3,e4,e5,e6,e7,e8,
       f1,f2,f3,f4,f5,f6,f7,f8,
       g1,g2,g3,g4,g5,g6,g7,g8,
       h1,h2,h3,h4,h5,h6,h7,h8
    );
Dh1 : ByteArray =
{0}     (  h8,
{1}        g8,h7,
{3}        f8,g7,h6,
{6}        e8,f7,g6,h5,
{10}       d8,e7,f6,g5,h4,
{15}       c8,d7,e6,f5,g4,h3,
{21}       b8,c7,d6,e5,f4,g3,h2,
{28}       a8,b7,c6,d5,e4,f3,g2,h1,
{36}       a7,b6,c5,d4,e3,f2,g1,
{43}       a6,b5,c4,d3,e2,f1,
{49}       a5,b4,c3,d2,e1,
{54}       a4,b3,c2,d1,
{58}       a3,b2,c1,
{61}       a2,b1,
{63}       a1
         );
DSh1 : ByteArray =
     (
       63,61,58,54,49,43,36,28,
       61,58,54,49,43,36,28,21,
       58,54,49,43,36,28,21,15,
       54,49,43,36,28,21,15,10,
       49,43,36,28,21,15,10,6 ,
       43,36,28,21,15,10,6 ,3 ,
       36,28,21,15,10,6 ,3 ,1 ,
       28,21,15,10,6 ,3 ,1 ,0
     );

Da1 : ByteArray =
{0}     (  a8,
{1}        a7,b8,
{3}        a6,b7,c8,
{6}        a5,b6,c7,d8,
{10}       a4,b5,c6,d7,e8,
{15}       a3,b4,c5,d6,e7,f8,
{21}       a2,b3,c4,d5,e6,f7,g8,
{28}       a1,b2,c3,d4,e5,f6,g7,h8,
{36}       b1,c2,d3,e4,f5,g6,h7,
{43}       c1,d2,e3,f4,g5,h6,
{49}       d1,e2,f3,g4,h5,
{54}       e1,f2,g3,h4,
{58}       f1,g2,h3,
{61}       g1,h2,
{63}       h1
         );
DSa1 : ByteArray =
     (
       28,36,43,49,54,58,61,63,
       21,28,36,43,49,54,58,61,
       15,21,28,36,43,49,54,58,
       10,15,21,28,36,43,49,54,
       6 ,10,15,21,28,36,43,49,
       3 ,6 ,10,15,21,28,36,43,
       1 ,3 ,6 ,10,15,21,28,36,
       0 ,1 ,3 ,6 ,10,15,21,28
     );
DiagLenh1 : ByteArray =
     (
       1,2,3,4,5,6,7,8,
       2,3,4,5,6,7,8,7,
       3,4,5,6,7,8,7,6,
       4,5,6,7,8,7,6,5,
       5,6,7,8,7,6,5,4,
       6,7,8,7,6,5,4,3,
       7,8,7,6,5,4,3,2,
       8,7,6,5,4,3,2,1
     );
sqh1 : ByteArray =
     (
       1,1,1,1,1,1,1,1,
       2,2,2,2,2,2,2,1,
       3,3,3,3,3,3,2,1,
       4,4,4,4,4,3,2,1,
       5,5,5,5,4,3,2,1,
       6,6,6,5,4,3,2,1,
       7,7,6,5,4,3,2,1,
       8,7,6,5,4,3,2,1
     );
sqa1 : ByteArray =
     (
       8,7,6,5,4,3,2,1,
       7,7,6,5,4,3,2,1,
       6,6,6,5,4,3,2,1,
       5,5,5,5,4,3,2,1,
       4,4,4,4,4,3,2,1,
       3,3,3,3,3,3,2,1,
       2,2,2,2,2,2,2,1,
       1,1,1,1,1,1,1,1
     );

DiagLena1 : ByteArray =
     (
       8,7,6,5,4,3,2,1,
       7,8,7,6,5,4,3,2,
       6,7,8,7,6,5,4,3,
       5,6,7,8,7,6,5,4,
       4,5,6,7,8,7,6,5,
       3,4,5,6,7,8,7,6,
       2,3,4,5,6,7,8,7,
       1,2,3,4,5,6,7,8
     );
Castlemask : ByteArray=
     (
      253,255,255,255,252,255,255,254,
      255,255,255,255,255,255,255,255,
      255,255,255,255,255,255,255,255,
      255,255,255,255,255,255,255,255,
      255,255,255,255,255,255,255,255,
      255,255,255,255,255,255,255,255,
      255,255,255,255,255,255,255,255,
      247,255,255,255,243,255,255,251
     );
decode : chararray =
     ( 'a1','b1','c1','d1','e1','f1','g1','h1',
       'a2','b2','c2','d2','e2','f2','g2','h2',
       'a3','b3','c3','d3','e3','f3','g3','h3',
       'a4','b4','c4','d4','e4','f4','g4','h4',
       'a5','b5','c5','d5','e5','f5','g5','h5',
       'a6','b6','c6','d6','e6','f6','g6','h6',
       'a7','b7','c7','d7','e7','f7','g7','h7',
       'a8','b8','c8','d8','e8','f8','g8','h8'
     );
PiesePrice : Tarray = (Mate,QueenValue,RookValue,BishopValue,KnightValue,PawnValue,Empty,PawnValue,KnightValue,BishopValue,RookValue,QueenValue,Mate);
PieseShort : Tarray=(0,9,5,3,3,0,0,0,3,3,5,9,0);
     init=0;
     TryHashMove=1;
     GenerCaptures=2;
     TryGoodCaptures=3;
     TryKiller1=4;
     TryKiller2=5;
     TryKiller3=11;
     TryKiller4=12;
     GenerMoves=6;
     TryHistory1=7;
     tryHistory2=8;
     TryOther=9;
     TryBadCaptures=10;

     Convection=0;
     increment=1;
     exacttime=3;
     LazyExit=200;
     DoublePawn=2*PawnValue;
     Futility = 100;
     ExFutility=300;
     Razor2=350;
     Razor1=150;
     aspiration=40;
     NullR=3;
     Delta=100;
     OpenCheck=-100;
Var
    Tree : array [0..MaxPly+1] of Ttree;
    Only,NotOnly,OnlyR90,NotOnlyR90,OnlyDa1,NotOnlyDa1,OnlyDh1,NotOnlyDh1 : array[0..63] of bitboard;
    Posx,Posy,Posxx,Posyy,deboard : array[0..63] of integer;
    Board : array[-10..109,1..2] of integer;
    Hist,mgood,mtotal : array [1..6,0..63] of integer;
    RB,RBR90,RBDh1,RBDa1 : array [0..63,0..255] of bitboard;
    MobRb,MobRBR90,MobRBDh1,MobRBDa1 : array[0..63,0..255] of byte;
    KingsMove,KnightsMove,NHalfW,NhalfB,WPattacks,BPattacks,RookFull,BishopFull,zoneslide : array [0..63] of bitboard;
    LDir,RDir,UDir,DDir,ULDir,URDIr,DLDir,DRDir : array [0..63] of bitboard;
    direction : array [0..63,0..63] of integer;
    WhitePawns,BlackPawns,WhiteKnights,BlackKnights,WhiteBishops,BlackBishops,WhitePieses,BlackPieses,WQR,WQB,BQR,BQB,
    WhiteRooks,BlackRooks,WhiteQueens,BlackQueens,WhiteKing,BlackKing,Target,AllPieses,AllR90,AllDa1,AllDh1 : Bitboard;
    Noafile,Nohfile,wshortmask,wlongmask,bshortmask,blongmask,wshort,wlong,bshort,blong,a1h1h8,a1d1d4,a1h8 : BitBoard;
    Rank27,abc,fgh : bitboard;
    InterSect : array[0..63,0..63] of bitboard;
    Moves,Takes,MTakes,Mvalues,oldmoves : array[0..128*(MaxPly+1)] of integer;
    Captureflag,Castleflag,EnPassantflag,Promoteflag,CapPromoflag : integer;
    HMateThreatflag,znakflag,znakmask : integer;
    MaskDh1,MaskDa1 : array[0..63] of integer;
    Files,Ranks : array[1..8] of bitboard;
    SideToMove : integer;
    WPZobr,BPZobr,WNZobr,BNZobr,WBZobr,BBZobr,WRZobr,BRZobr,WQZobr,BQZobr,WKZobr,BKZobr,EnPassZobr : array[0..63] of bitboard;
    WPZobr32,BPZobr32 : array[0..63] of cardinal;
    Zcolor:bitboard;
    Killer : array[0..MaxPly,1..2] of integer;
    WhiteTable,BlackTable : array of Tentry;
    PTable : array  of TPawn;
    Age : integer;
    Nodes,TBHITS : cardinal;
    Remain : integer;
    PV : array[0..MaxPly+1,0..MaxPly+1] of Integer;
    PVlen : array[0..MaxPly+1] of integer;
    MoveNow,PostMode,XboardMode,UCImode,EditMode,ForceMode,ExitNow,DepthLimit : boolean;
    gHandleout:Cardinal;
    EngineTime,EditColor,MaxDepth : integer;
    usebook,AbortSearch,MateInOne:boolean;
    timer:Ttime;
    EngineClock,RemainNodes,MovesToControl : integer;
    StartTime,CurrTime:TDateTime;
    hmovemask,f2g3h3,f7g6h6,a3b3c2,a6b6c7,f3g2h3,a3b2c3,a6b7c6,f6g7h6,pawnext,centerw,centerb,g1h1,a1b1,a8b8,g8h8,a2a3,a7a6,h2h3,h7h6,
    wqflang,wkflang,bqflang,bkflang,light,dark,wfianq,bfianq,wfiank,bfiank,a2b3c2,a7b6c7,f2g3h2,f7g6h7 : bitboard;
    wbishtrap,bbishtrap:bitboard;
    wrooktrap,brooktrap : array[-4..3] of bitboard;
    RootDepth : integer;
    Rule50: array [1..MaxPly] of integer;
    HashGame:array [0..100+MaxPly+1] of int64;
    rep : integer;
    WPassMask,BPassMask,IsoMask,Wstopper,BStopper,Wback,BBack : array[0..63] of bitboard;
    Filedist,RankDist,Dist : array[0..63,0..63] of integer;
    WCastleDid,BCastleDid : boolean;
    recod : array[0..88] of integer;
    isResign:boolean;
    TotalHash,Resign:integer;
    HashSize,HashMask,PHashSize,PHashMask : integer;
    RootEval,resCount,fdepth:integer;
    k_k_pawnless : array[0..9,0..63] of integer;
    k_k_wpawns : array[0..63,0..63] of integer;
    wkingconv : array[0..63] of integer;
    useegtb,canuseeg:boolean;
    fkqk,fkrk,fkqkq,fkqkr,fkqkb,fkqkn,fkrkq,fkrkr,fkrkb,fkrkn,fkbbk,fkbnk,fkpk,fkpknab,fkpkncd,
    fkpkbab,fkpkbcd,fkpkrab,fkpkrcd,fkpkqab,fkpkqcd,fkrkpab,fkrkpcd,fkqkpab,fkqkpcd,fkpkp:boolean;
    bkqkw,bkrkw,bkqkqw,bkqkrw,bkqkbw,bkqknw,bkrkqw,bkrkrw,bkrkbw,bkrknw,bkbbkw,bkbnkw,bkpkw,bkpkb,
    bkqkb,bkrkb,bkqkqb,bkqkrb,bkqkbb,bkqknb,bkrkqb,bkrkrb,bkrkbb,bkrknb,bkbbkb,bkbnkb,
    bkpknabw,bkpknabb,bkpkbabw,bkpkbabb,bkpkrabw,bkpkrabb,bkpkqabw,bkpkqabb,bkrkpabw,bkrkpabb,bkqkpabw,bkqkpabb,
    bkpkpw,bkpkpb,bkpkncdw,bkpkncdb,bkpkbcdw,bkpkbcdb,bkpkrcdw,bkpkrcdb,bkpkqcdw,bkpkqcdb,bkrkpcdw,bkrkpcdb,bkqkpcdw,bkqkpcdb : array of byte;
    egtbfile : file;
    egtbpath :string;
    NullThreat : array[0..MaxPly] of integer;
    Undo : array[0..512] of tundo;
    Undocount:integer;
    OldRootDepth,PredictedMove,Rezerv,oldenginetime :integer;
    canadd,added:boolean;
    pkikw,pkikb:int64;
    pvmove :integer;
    rootegtb : boolean;
    RootChanged,FailLowNow,FailLowPrev,EasyExit :boolean;
    wforce,bforce:integer;
Procedure GetSTD;
Procedure LPrint(msgs:string);
Procedure SPrint(msgs:string);
Function MoveToStr(move:word):string;
Function StrToField(str:string):byte;
implementation
Procedure GetSTD;
// Процедура однократного подхвата потока для вывода в стандартный OutPut
begin
gHandleout := getstdhandle(std_output_handle);
end;

Procedure LPrint(msgs:string);
// Печать на стандартный output
var
   x1:Pchar;
   len:Cardinal;
begin
     len := length(msgs);
     x1 := pchar(msgs + #10); // just to be safe
    _lwrite(gHandleout, x1, len + 1);
end;


Procedure SPrint(msgs:string);
// Печать на стандартный output без возврата каретки
var
   x1:Pchar;
   len:Cardinal;
begin
     len := length(msgs);
     x1 := pchar(msgs+#10); // just to be safe
    _lwrite(gHandleout, x1, len);
end;

Function MoveToStr(move:word):string;
var
   res:string;
begin
 res:=Decode[trunc(move/256)]+Decode[move-256*trunc(move/256)];
 Result:=res;
end;

Function StrToField(str:string):byte;
var
   i:byte;
begin
For i:=0 to 63 do
 if Decode[i]=str
     then begin
           Result:=i;
           exit;
          end;

Result:=64;// Код ошибки
end;

end.


















































