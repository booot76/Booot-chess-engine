unit params;

interface
  uses SysUtils;
CONST
    EngineName='Booot 5.2.0(32)';
    MaxPly=64;
    Mate=32000;
    white = 0;
    black = 1;
    moveislegal=0;
    moveisunlegal=1;
    hardmove=2;
    FullPly=2;
    a1=0 ;b1=1 ;c1=2 ;d1=3 ;e1=4 ;f1=5 ;g1=6 ;h1=7 ;
    a2=8 ;b2=9 ;c2=10;d2=11;e2=12;f2=13;g2=14;h2=15;
    a3=16;b3=17;c3=18;d3=19;e3=20;f3=21;g3=22;h3=23;
    a4=24;b4=25;c4=26;d4=27;e4=28;f4=29;g4=30;h4=31;
    a5=32;b5=33;c5=34;d5=35;e5=36;f5=37;g5=38;h5=39;
    a6=40;b6=41;c6=42;d6=43;
    e6=44;f6=45;g6=46;h6=47;
    a7=48;b7=49;c7=50;d7=51;e7=52;f7=53;g7=54;h7=55;
    a8=56;b8=57;c8=58;d8=59;e8=60;f8=61;g8=62;h8=63;

    HashMatSize=65536;//* 16 = 1  MB
    HashMatMask=HashMatSize-1;
    HashPawnSize=131072;// *40 = 5 Mb
    HashPawnMask=HashMatSize-1;
    HashSize=1048576;//*16*4 =64 Mb
    HashMask=HashSize-1;
    FullRemain=100000;
    FullRemainSudden=50000;
TYPE
   TBitBoard=int64;
   TSquare = integer;
   TColor = integer;
   TPiese = integer;
   Tmove = integer;  //0..5 -from  6..11-dest 12..14-promo 15-captureflag
   TKey = int64;
   TPawnKey=int64;
   TmatKey=integer;
   TBBLine=array[a1..h8] of TBitBoard;
   TFileArray = array[1..8] of integer;
   TRankArray = array[1..8] of integer;
   TStringLine = array[a1..h8] of string;
   TBBColorLine=array[white..black,a1..h8] of TBitBoard;
   Tpositionvalue=array[a1..h8,a1..h8] of integer;
   TBytesArray=array[a1..h8] of TSquare;
   TBBFile = array[1..8] of TBitBoard;
   t8 = array[0..8] of integer;
   t16 = array[0..16] of integer;
   t32 = array[0..32] of integer;
   T256 = array[0..255] of integer;
   TMoveList = record
                  count : integer;
                  pos   : integer;
                  status: integer;
                  Moves : array[0..256] of Tmove;
                  Values: array[0..256] of integer;
               end;
    TPVLine = record
                 count : integer;
                 Moves : array[1..2*MaxPly] of Tmove;
               end;
    Tgame = record
              TimeStart : Cardinal;
              time  : Cardinal;
              rezerv:Cardinal;
              pondertime  : Cardinal;
              ponderrezerv : Cardinal;
              oldtime:cardinal;
              HashAge : integer;
              NodesTotal : cardinal;
              AbortSearch : Boolean;
              remain:integer;
              uciPonder : boolean;
            end;
Var
   BitCountTable : array[0..65535] of integer;
   game : Tgame;
Procedure Init;


implementation
Uses BitBoards,Board,Material,Pawn,history,hash,uci,movegen,safety;

Procedure Init;
 var
   i:integer;
   j,x,y:integer;
   bb :int64;
  begin
    for i:=0 to 65535 do
       BitCounttable[i]:=BitCountInit(i);
     
    for i:=0 to MaxPly*FullPly do
      DepthInc[i]:=i*i;

    for I := a1 to h8 do
   begin
     ConnectedMaskBB[i]:=0;
     x:=posx[i];
     y:=posy[i];
     bb:=RanksBB[y];
     if y<8 then bb:=bb or RanksBB[y+1];
     if y<7 then bb:=bb or RanksBB[y+2];
     if y>1 then bb:=bb or RanksBB[y-1];
     if y>2 then bb:=bb or RanksBB[y-2];
     ConnectedMaskBB[i]:=bb and (not filesbb[x]) and PawnIsoMaskBB[i];
   end;

    for I :=a1 to h8 do
      begin
         bb:=0;
         x:=posx[i];
         for j:=x+1 to 8 do
           bb:=bb or FilesBB[j];
         RightFlangBB[i]:=bb;
         bb:=0;
         for j:=x-1 downto 1 do
           bb:=bb or FilesBB[j];
         LeftFlangBB[i]:=bb;
      end;
    for I :=a1 to h8 do
      begin
        x:=posx[i];
        if x>4
          then bb:=BishopFullAttacksBB[i] and LeftFlangBB[i]
          else bb:=BishopFullAttacksBB[i] and RightFlangBB[i];
        KingShelterDiagBB[i]:=bb;
      end;
    for I :=a1 to h8 do
      begin
        HoleBB[i]:=0;
        x:=posx[i];
        if x>2 then HoleBB[i]:=OnlyR00[i-2];
      end;
    // по умолчанию пондеринг включен
    game.uciPonder:=true;
    // Инициализируем хеши
     SetLength(MatTable,0);
     SetLength(MatTable,HashMatSize);
     SetLength(PawnTable,0);
     SetLength(PawnTable,HashPawnSize);
     SetHash(TT,Hashsize);
     SetupChanels;
  end;


end.
