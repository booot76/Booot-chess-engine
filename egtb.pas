unit egtb;
// Юнит отвечает за использование эндшпильных таблиц. Программа использует собственные
// эндшпильные таблицы.
interface
uses params,bitboards,SysUtils;

const

EGTBSymmetry : ByteArray=
 (
  0,0,0,0,7,7,7,6,
  1,0,0,0,7,7,6,6,
  1,1,0,0,7,6,6,6,
  1,1,1,0,6,6,6,6,
  2,2,2,2,4,5,5,5,
  2,2,2,3,4,4,5,5,
  2,2,3,3,4,4,4,5,
  2,3,3,3,4,4,4,4
 );
PawnPosition : ByteArray=
 (
  -1,-1,-1,-1,-1,-1,-1,-1,
   0, 6,12,18,-2,-2,-2,-2,
   1, 7,13,19,-2,-2,-2,-2,
   2, 8,14,20,-2,-2,-2,-2,
   3, 9,15,21,-2,-2,-2,-2,
   4,10,16,22,-2,-2,-2,-2,
   5,11,17,23,-2,-2,-2,-2,
  -1,-1,-1,-1,-1,-1,-1,-1
 );
   Illegal=127;
   EGTBMate=126;
   StaleMate=125;
   Draw=0;
   DeadDraw=123;
   BitBaseWin=1000;
   BitBaseDraw=2000;
   BitBaseFault=3000;
var
   f11,f22:boolean;
Function RotatePieses(Piese:integer;symmetry:integer):integer;
Function ProduceEGTBTitle(WList:EGTBPieses;BList:EGTBPieses):string;
Procedure AddToEGTBTitle(List:EGTBPieses;var res:string);
Function IsEGTBExist(Title:string):boolean;
Procedure FillLists(var WList:EGTBPieses;var BList:EGTBPieses);
Function PawnlessIndex(wlist:egtbpieses;blist:egtbpieses):integer;
Function PawnIndex(wlist:egtbpieses;blist:egtbpieses;invert : boolean):integer;
Function EGTBProbe(color:integer) : integer;
Function CanuseEGTB : boolean;
Function LoadBB(title:string):boolean;
Function EGTBBitbaseProbe(color:integer;ply:integer):integer;
Procedure ClearMemory;
implementation
uses eval;

Function RotatePieses(Piese:integer;symmetry:integer):integer;
// Функция "вращает" фигуру по доске в зависимости от положения белого короля (ось симметрии).
var
   res,x,y:integer;
   FPiese:integer;
begin
  FPiese:=Deboard[Piese];
  x:=FPiese div 10;
  y:=FPiese mod 10;
  res:=0;
  case symmetry of
    0: Res:=Piese;
    1: Res:=Board[y*10+x,2];
    2: Res:=Board[(9-y)*10+x,2];
    3: Res:=Board[x*10+(9-y),2];
    4: Res:=Board[(9-x)*10+(9-y),2];
    5: Res:=Board[(9-y)*10+(9-x),2];
    6: Res:=Board[y*10+(9-x),2];
    7: Res:=Board[(9-x)*10+y,2];
  end;
 Result:=res;
end;

Procedure AddToEGTBTitle(List:EGTBPieses;var res:string);
// Процедура формирует имя файла в зависимости от положения фигур в списке.
var
   i: integer;
begin
  For i:=1 to 5 do
    case List[i,1] of
     Empty : exit;
     Pawn  : res:=res+'P';
     Knight: res:=res+'N';
     Bishop: res:=res+'B';
     Rook  : res:=res+'R';
     Queen : res:=res+'Q';
     King  : res:=res+'K';
    end;
end;


Function ProduceEGTBTitle(WList:EGTBPieses;BList:EGTBPieses):string;
// Формирует заголовок файла эндшпильных таблиц в зависимости от эндшпиля.
var
   res : string;
begin
  res:='';
  AddToEGTBTitle(Wlist,res);
  AddToEGTBTitle(Blist,res);
  Result:=res;
end;

Function IsEGTBExist(Title:string):boolean;
// Функция проверяет: есть ли файлы нужного эндшпиля на диске.
var
  filename1,filename2 : string;
  res:boolean;
  path:string;
begin
  if egtbpath='\' then path:=''
                  else path:=egtbpath;
  filename1:=path+Title+'.FTW';
  filename2:=path+Title+'.FTB';
  f11:=fileexists(filename1);
  f22:=fileexists(filename2);
  res:=f11 and f22;
 Result:=res;
end;

Procedure FillLists(var WList:EGTBPieses; var BList:EGTBPieses);
// Процедура заполняет списки фигур из стандартного bitboard представления.
var
   i,sq:integer;
   temp:bitboard;
begin
  i:=1;
  Wlist[1,1]:=king;
  Wlist[1,2]:=BitScanForward(WhiteKing);
  temp:=WhiteQueens;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     WList[i,1]:=queen;
     WList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;

 temp:=WhiteRooks;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     WList[i,1]:=rook;
     WList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;
 temp:=WhiteBishops;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     WList[i,1]:=bishop;
     WList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;
 temp:=WhiteKnights;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     WList[i,1]:=knight;
     WList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;
  temp:=WhitePawns;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     WList[i,1]:=pawn;
     WList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;
   inc(i);
   Wlist[i,1]:=empty;

  i:=1;
  Blist[1,1]:=king;
  Blist[1,2]:=BitScanForward(BlackKing);
  temp:=BlackQueens;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     bList[i,1]:=queen;
     bList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;

 temp:=BlackRooks;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     BList[i,1]:=rook;
     BList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;
 temp:=BlackBishops;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     BList[i,1]:=bishop;
     BList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;
 temp:=BlackKnights;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     BList[i,1]:=knight;
     BList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;
  temp:=BlackPawns;
  While temp<>0 do
   begin
     sq:=BitScanForward(temp);
     inc(i);
     BList[i,1]:=pawn;
     BList[i,2]:=sq;
     temp:=temp and NotOnly[sq];
   end;
   inc(i);
   Blist[i,1]:=empty;
end;

Function PawnlessIndex(wlist:egtbpieses;blist:egtbpieses):integer;
// Функция вычисляет индекс нужной позиции для эндшпилей без пешек.
var
  symmetry,wking,bking,wpiese1,wpiese2,bpiese,index : integer;
  useone:boolean;
begin
  useone:=false;
  symmetry:=EGTBSymmetry[wlist[1,2]];
  // 1. Ставим на доску белого короля
  wking:=RotatePieses(wlist[1,2],symmetry);
  // 2. Ставим на доску черного короля (если белый король на диагонали a1h8  то перемещаем черного короля в треугольник a1h1h8)
  bking:=RotatePieses(blist[1,2],symmetry);
  if (wking in [0,9,18,27]) and ((Only[bking] and a1h1h8)=0) then
    begin
    bking:=RotatePieses(bking,1);
    useone:=true;
    end;
  // Расставляем другие фигуры
  if wlist[2,1]<>empty then
     begin
       wpiese1:=RotatePieses(wlist[2,2],symmetry);
       if useone then wpiese1:=RotatePieses(wpiese1,1);
       if wlist[3,1]<>empty then
          begin
           wpiese2:=RotatePieses(wlist[3,2],symmetry);
           if useone then wpiese2:=RotatePieses(wpiese2,1);
          end
             else wpiese2:=-1;
     end
        else
          begin
           Result:=BadIndex;
           exit;
          end;
  if blist[2,1]<>empty
      then
          begin
          bpiese:=RotatePieses(blist[2,2],symmetry);
          if useone then bpiese:=RotatePieses(bpiese,1);
          end
      else bpiese:=-1;
  // Вычисляем индекс позиции

  index:=k_k_pawnless[wkingconv[wking],bking];
       if index=badindex then
          begin
           Result:=BadIndex;
           exit;
          end;
  dec(index);
  if bpiese>=0 then
     begin
      Result:=index*4096+wpiese1*64+bpiese;
      exit;
     end
        else
     if wpiese2>=0 then
        begin
         Result:=index*4096+wpiese1*64+wpiese2;
         exit;
        end
           else
        begin
          Result:=index*64+wpiese1;
          exit;
        end;
end;

Function PawnIndex(wlist:egtbpieses;blist:egtbpieses;invert : boolean):integer;
// Функция вычисляет индекс нужной позиции для эндшпилей, содержащих пешку(и).
var
  wking,bking,wpiese1,bpiese : integer;
begin
  wking:=wlist[1,2];
  bking:=blist[1,2];
  if (wlist[2,1]=pawn) and (wlist[3,1]=empty) and (blist[2,1]=empty) then
     begin
       wpiese1:=wlist[2,2];
       if invert then
         begin
           wking:=RotatePieses(wking,3);
           bking:=RotatePieses(bking,3);
           wpiese1:=RotatePieses(wpiese1,3);
         end;
      if PawnPosition[wpiese1]=-1 then
        begin
          Result:=BadIndex;
          exit;
        end else
     if PawnPosition[wpiese1]=-2 then
        begin
           wking:=RotatePieses(wking,7);
           bking:=RotatePieses(bking,7);
           wpiese1:=RotatePieses(wpiese1,7);
        end;
       Result:=PawnPosition[wpiese1]*3612+k_k_wpawns[wking,bking]-1;
       exit;
     end
        else
if (wlist[2,1]=pawn) and (wlist[3,1]=empty) and (blist[2,1]<>empty) and (blist[3,1]=empty) then
     begin
       wpiese1:=wlist[2,2];
       bpiese:=blist[2,2];
       if invert then
         begin
           wking:=RotatePieses(wking,3);
           bking:=RotatePieses(bking,3);
           wpiese1:=RotatePieses(wpiese1,3);
           bpiese:=RotatePieses(bpiese,3);
         end;
      if PawnPosition[wpiese1]=-1 then
        begin
          Result:=BadIndex;
          exit;
        end else
     if PawnPosition[wpiese1]=-2 then
        begin
           wking:=RotatePieses(wking,7);
           bking:=RotatePieses(bking,7);
           wpiese1:=RotatePieses(wpiese1,7);
           bpiese:=RotatePieses(bpiese,7);
        end;
       Result:=PawnPosition[wpiese1]*3612*64+(k_k_wpawns[wking,bking]-1)*64+bpiese;
       exit;
     end
        else
     if (wlist[2,1]<>empty) and (wlist[3,1]=empty) and (blist[2,1]=pawn) and (blist[3,1]=empty) then
     begin
       wpiese1:=blist[2,2];
       bpiese:=wlist[2,2];
       if invert then
         begin
           wking:=RotatePieses(wking,3);
           bking:=RotatePieses(bking,3);
           wpiese1:=RotatePieses(wpiese1,3);
           bpiese:=RotatePieses(bpiese,3);
         end;
      if PawnPosition[wpiese1]=-1 then
        begin
          Result:=BadIndex;
          exit;
        end else
     if PawnPosition[wpiese1]=-2 then
        begin
           wking:=RotatePieses(wking,7);
           bking:=RotatePieses(bking,7);
           wpiese1:=RotatePieses(wpiese1,7);
           bpiese:=RotatePieses(bpiese,7);
        end;
       Result:=PawnPosition[wpiese1]*3612*64+(k_k_wpawns[wking,bking]-1)*64+bpiese;
       exit;
     end;
 Result:=BadIndex;

end;


Function EGTBProbe(color:integer) : integer;
// Функция, делающая запрос на DTM оценку нужной позиции
var
   Wlist,Blist,MyList,OpList:EGTBPieses;
   MyTitle,OpTitle : string;
   Index:integer;
   w,b:file of byte;
   wresultmy,bresultop:byte;
   invert:boolean;
   path:string;
begin
  wresultmy:=Illegal;
  bresultop:=Illegal;
  //1. Заполняем список фигур, принимая себя как сильнейшую сторону:
  FillLists(Wlist,Blist);
  if color=black then
     begin
       MyList:=Blist;
       OpList:=Wlist;
     end
        else
     begin
      MyList:=Wlist;
      OpList:=Blist;
     end;
 //2. Формируем заголовок эндшпиля для случая, когда мы - сильнейшая сторона:
    MyTitle:=ProduceEGTBTitle(MyList,Oplist);
    if MyList[1,2]=Blist[1,2]  then invert:=true
                               else invert:=false;
 // 3. Проверяем : есть ли искомый эндшпиль у нас?
 if isEGTBExist(MyTitle) then
    begin

      // Если есть, то вычисляем индекс нашей позиции (вращая и отражая ее):
      if pos('P',MyTitle)=0 then
                                index:=PawnlessIndex(MyList,Oplist)
                             else
                                index:=PawnIndex(MyList,Oplist,invert);
      if index<>BadIndex then
       begin
        if egtbpath='\' then path:=MyTitle
                        else path:=egtbpath+MyTitle;
        // Ищем в файле нашу позицию:
        assign(w,path+'.FTW');
        reset(w);
        seek(w,index);
        read(w,wresultmy);
        close(w);
        if wresultmy=DeadDraw then wresultmy:=Draw;
        // Если оценка позиции "выиграно" или "нелегальная позиция" - то возвращаем ее
        if (wresultmy<>Draw) then
           begin
             Result:=Wresultmy;
             exit;
           end;
      end;
    end;
 //Если искомого эндшпиля нет, или есть, но оценка:ничья, то нужна проверка за противника
 //4. Формируем заголовок эндшпиля для случая, когда мы - слабейшая сторона:
   OpTitle:=ProduceEGTBTitle(OpList,MyList);
   if OpList[1,2]=Blist[1,2]  then invert:=true
                    else invert:=false;
  // 5. Проверяем : есть ли искомый эндшпиль у нас?
 if isEGTBExist(OpTitle) then
    begin
      // Если есть, то вычисляем индекс нашей позиции (вращая и отражая ее):
      if pos('P',OPTitle)=0 then
                                index:=PawnlessIndex(OpList,Mylist)
                             else
                                index:=PawnIndex(OpList,Mylist,invert);
      if index<>BadIndex then
        begin
        // Ищем в файле нашу позицию:
        if egtbpath='\' then path:=OpTitle
                        else path:=egtbpath+OpTitle;
        assign(b,path+'.FTB');
        reset(b);
        seek(b,index);
        read(b,bresultop);
        close(b);
        // Если ничья, то возвращаем ничью
        if bresultop in [Draw,DeadDraw,StaleMate] then
          begin
           Result:=Draw;
           Exit;
          end;
        // Если оценка позиции "выиграно" то возвращаем оценку позиции с отр знаком (оппонент выигрывает)
        if ((bresultop>Draw) and (bresultop<DeadDraw)) or (bresultop=EGTBMate) then
           begin
             Result:=-BresultOp;
             exit;
           end;
       end;    
    end;
  // Если за оппонента выигрыша нет, то возвращаем нашу исходную оценку (или "невозможная позиция")
 Result:=WresultMy;
end;
Function CanuseEGTB : boolean;
// Функция возвращает true, если движок нашел трехфигурные эндшпиля по нужному пути.
var
   path : string;
begin
  if egtbpath='\' then path:=''
                  else path:=egtbpath;
  Result:=fileexists(path+'kqk.ftw') and fileexists(path+'kqk.ftb') and fileexists(path+'krk.ftw') and fileexists(path+'krk.ftb');
end;

Function LoadBB(title:string):boolean;
//Функция, подгружающая в память нужный битборд (в качестве параметра - имя нужного битборда)
// Возвращает true если все произошло нормально без ошибок.
var
  realread,i:integer;
  buf : array[1..24*3612*8] of byte;
  path:string;
begin
  if egtbpath='\' then   path:=''
                  else path:=egtbpath;

  if (title='KQK') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkqkw,462*64);
       SetLength(bkqkb,462*64);
       assign(egtbfile,path+'KQK.ftw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64,realread);
       close(egtbfile);
       if realread<>462*64 then
          begin
            SetLength(bkqkw,0);
            SetLength(bkqkb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64 do
         bkqkw[i-1]:=buf[i];
       assign(egtbfile,path+'KQK.ftb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64,realread);
       close(egtbfile);
       if realread<>462*64 then
          begin
            SetLength(bkqkw,0);
            SetLength(bkqkb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64 do
         bkqkb[i-1]:=buf[i];
       fkqk:=true;  
     end
        else
if (title='KRK') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkrkw,462*64);
       SetLength(bkrkb,462*64);
       assign(egtbfile,path+'KRK.ftw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64,realread);
       close(egtbfile);
       if realread<>462*64 then
          begin
            SetLength(bkrkw,0);
            SetLength(bkrkb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64 do
         bkrkw[i-1]:=buf[i];
       assign(egtbfile,path+'KRK.ftb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64,realread);
       close(egtbfile);
       if realread<>462*64 then
          begin
            SetLength(bkrkw,0);
            SetLength(bkrkb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64 do
         bkrkb[i-1]:=buf[i];
       fkrk:=true;
     end
     else
     if (title='KPK') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkw,3612*24);
       SetLength(bkpkb,3612*24);
       assign(egtbfile,path+'KPK.ftw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,3612*24,realread);
       close(egtbfile);
       if realread<>3612*24 then
          begin
            SetLength(bkpkw,0);
            SetLength(bkpkb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 3612*24 do
         bkpkw[i-1]:=buf[i];
       assign(egtbfile,path+'KPK.ftb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,3612*24,realread);
       close(egtbfile);
       if realread<>3612*24 then
          begin
            SetLength(bkpkw,0);
            SetLength(bkpkb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 3612*24 do
         bkpkb[i-1]:=buf[i];
       fkpk:=true;
     end
        else
if (title='KQKQ') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkqkqw,462*64*8);
       SetLength(bkqkqb,462*64*8);
       assign(egtbfile,path+'KQKQ.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqkqw,0);
            SetLength(bkqkqb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkqkqw[i-1]:=buf[i];
       assign(egtbfile,path+'KQKQ.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqkqw,0);
            SetLength(bkqkqb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkqkqb[i-1]:=buf[i];
       fkqkq:=true;
     end else
if (title='KRKR') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkrkrw,462*64*8);
       SetLength(bkrkrb,462*64*8);
       assign(egtbfile,path+'KRKR.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkrkrw,0);
            SetLength(bkrkrb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkrkrw[i-1]:=buf[i];
       assign(egtbfile,path+'KRKR.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkrkrw,0);
            SetLength(bkrkrb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkrkrb[i-1]:=buf[i];
       fkrkr:=true;
     end else
if (title='KRKN') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkrknw,462*64*8);
       SetLength(bkrknb,462*64*8);
       assign(egtbfile,path+'KRKN.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkrknw,0);
            SetLength(bkrknb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkrknw[i-1]:=buf[i];
       assign(egtbfile,path+'KRKN.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkrknw,0);
            SetLength(bkrknb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkrknb[i-1]:=buf[i];
       fkrkn:=true;
     end else
if (title='KRKB') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkrkbw,462*64*8);
       SetLength(bkrkbb,462*64*8);
       assign(egtbfile,path+'KRKB.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkrkbw,0);
            SetLength(bkrkbb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkrkbw[i-1]:=buf[i];
       assign(egtbfile,path+'KRKB.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkrkbw,0);
            SetLength(bkrkbb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkrkbb[i-1]:=buf[i];
       fkrkb:=true;
     end else
if (title='KQKN') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkqknw,462*64*8);
       SetLength(bkqknb,462*64*8);
       assign(egtbfile,path+'KQKN.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqknw,0);
            SetLength(bkqknb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkqknw[i-1]:=buf[i];
       assign(egtbfile,path+'KQKN.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqknw,0);
            SetLength(bkqknb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkqknb[i-1]:=buf[i];
       fkqkn:=true;
     end else
if (title='KQKB') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkqkbw,462*64*8);
       SetLength(bkqkbb,462*64*8);
       assign(egtbfile,path+'KQKB.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqkbw,0);
            SetLength(bkqkbb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkqkbw[i-1]:=buf[i];
       assign(egtbfile,path+'KQKB.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqkbw,0);
            SetLength(bkqkbb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkqkbb[i-1]:=buf[i];
       fkqkb:=true;
     end else
if (title='KQKR') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkqkrw,462*64*8);
       SetLength(bkqkrb,462*64*8);
       SetLength(bkrkqw,462*64*8);
       SetLength(bkrkqb,462*64*8);

       assign(egtbfile,path+'KQKR.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqkrw,0);
            SetLength(bkqkrb,0);
            SetLength(bkrkqw,0);
            SetLength(bkrkqb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkqkrw[i-1]:=buf[i];
       assign(egtbfile,path+'KRKQ.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqkrw,0);
            SetLength(bkqkrb,0);
            SetLength(bkrkqw,0);
            SetLength(bkrkqb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkrkqw[i-1]:=buf[i];

       assign(egtbfile,path+'KQKR.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqkrw,0);
            SetLength(bkqkrb,0);
            SetLength(bkrkqw,0);
            SetLength(bkrkqb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkqkrb[i-1]:=buf[i];
       assign(egtbfile,path+'KRKQ.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkqkrw,0);
            SetLength(bkqkrb,0);
            SetLength(bkrkqw,0);
            SetLength(bkrkqb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkrkqb[i-1]:=buf[i];

       fkqkr:=true;
     end else
if (title='KBNK') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkbnkw,462*64*8);
       SetLength(bkbnkb,462*64*8);
       assign(egtbfile,path+'KBNK.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkbnkw,0);
            SetLength(bkbnkb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkbnkw[i-1]:=buf[i];
       assign(egtbfile,path+'KBNK.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkbnkw,0);
            SetLength(bkbnkb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkbnkb[i-1]:=buf[i];
       fkbnk:=true;
     end else
if (title='KBBK') then
     begin
       if ((fileexists(path+title+'.ftw')) and (fileexists(path+title+'.ftb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkbbkw,462*64*8);
       SetLength(bkbbkb,462*64*8);
       assign(egtbfile,path+'KBBK.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkbbkw,0);
            SetLength(bkbbkb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 462*64*8 do
         bkbbkw[i-1]:=buf[i];
       assign(egtbfile,path+'KBBK.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,462*64*8,realread);
       close(egtbfile);
       if realread<>462*64*8 then
          begin
            SetLength(bkbbkw,0);
            SetLength(bkbbkb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 462*64*8 do
         bkbbkb[i-1]:=buf[i];
       fkbbk:=true;
     end
        else
if (title='KPKNAB') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpknabw,12*3612*8);
       SetLength(bkpknabb,12*3612*8);
       assign(egtbfile,path+'KPKNAB.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpknabw,0);
            SetLength(bkpknabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpknabw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKNAB.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpknabw,0);
            SetLength(bkpknabb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 12*3612*8 do
         bkpknabb[i-1]:=buf[i];
       fkpknab:=true;
     end
       else
if (title='KPKNCD') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkncdw,12*3612*8);
       SetLength(bkpkncdb,12*3612*8);
       assign(egtbfile,path+'KPKNCD.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkncdw,0);
            SetLength(bkpkncdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkncdw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKNCD.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkncdw,0);
            SetLength(bkpkncdb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 12*3612*8 do
         bkpkncdb[i-1]:=buf[i];
       fkpkncd:=true;
     end
       else
if (title='KPKBAB') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkbabw,12*3612*8);
       SetLength(bkpkbabb,12*3612*8);
       assign(egtbfile,path+'KPKBAB.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkbabw,0);
            SetLength(bkpkbabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkbabw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKBAB.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkbabw,0);
            SetLength(bkpkbabb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 12*3612*8 do
         bkpkbabb[i-1]:=buf[i];
       fkpkbab:=true;
     end
       else
if (title='KPKBCD') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkbcdw,12*3612*8);
       SetLength(bkpkbcdb,12*3612*8);
       assign(egtbfile,path+'KPKBCD.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkbcdw,0);
            SetLength(bkpkbcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkbcdw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKBCD.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkbcdw,0);
            SetLength(bkpkbcdb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 12*3612*8 do
         bkpkbcdb[i-1]:=buf[i];
       fkpkbcd:=true;
     end
       else
if (title='KPKRAB') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkrabw,12*3612*8);
       SetLength(bkpkrabb,12*3612*8);
       SetLength(bkrkpabw,12*3612*8);
       SetLength(bkrkpabb,12*3612*8);

       assign(egtbfile,path+'KPKRAB.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkrabw,0);
            SetLength(bkpkrabb,0);
            SetLength(bkrkpabw,0);
            SetLength(bkrkpabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkrabw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKRAB.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkrabw,0);
            SetLength(bkpkrabb,0);
            SetLength(bkrkpabw,0);
            SetLength(bkrkpabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkrabb[i-1]:=buf[i];
       assign(egtbfile,path+'KRKPAB.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkrabw,0);
            SetLength(bkpkrabb,0);
            SetLength(bkrkpabw,0);
            SetLength(bkrkpabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkrkpabw[i-1]:=buf[i];
       assign(egtbfile,path+'KRKPAB.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkrabw,0);
            SetLength(bkpkrabb,0);
            SetLength(bkrkpabw,0);
            SetLength(bkrkpabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkrkpabb[i-1]:=buf[i];
       fkpkrab:=true;
     end
       else
if (title='KPKRCD') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkrcdw,12*3612*8);
       SetLength(bkpkrcdb,12*3612*8);
       SetLength(bkrkpcdw,12*3612*8);
       SetLength(bkrkpcdb,12*3612*8);

       assign(egtbfile,path+'KPKRCD.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkrcdw,0);
            SetLength(bkpkrcdb,0);
            SetLength(bkrkpcdw,0);
            SetLength(bkrkpcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkrcdw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKRCD.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkrcdw,0);
            SetLength(bkpkrcdb,0);
            SetLength(bkrkpcdw,0);
            SetLength(bkrkpcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkrcdb[i-1]:=buf[i];
       assign(egtbfile,path+'KRKPCD.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkrcdw,0);
            SetLength(bkpkrcdb,0);
            SetLength(bkrkpcdw,0);
            SetLength(bkrkpcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkrkpcdw[i-1]:=buf[i];
       assign(egtbfile,path+'KRKPCD.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkrcdw,0);
            SetLength(bkpkrcdb,0);
            SetLength(bkrkpcdw,0);
            SetLength(bkrkpcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkrkpcdb[i-1]:=buf[i];
       fkpkrcd:=true;
     end
         else
if (title='KPKQAB') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkqabw,12*3612*8);
       SetLength(bkpkqabb,12*3612*8);
       SetLength(bkqkpabw,12*3612*8);
       SetLength(bkqkpabb,12*3612*8);

       assign(egtbfile,path+'KPKQAB.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkqabw,0);
            SetLength(bkpkqabb,0);
            SetLength(bkqkpabw,0);
            SetLength(bkqkpabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkqabw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKQAB.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkqabw,0);
            SetLength(bkpkqabb,0);
            SetLength(bkqkpabw,0);
            SetLength(bkqkpabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkqabb[i-1]:=buf[i];
       assign(egtbfile,path+'KQKPAB.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkqabw,0);
            SetLength(bkpkqabb,0);
            SetLength(bkqkpabw,0);
            SetLength(bkqkpabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkqkpabw[i-1]:=buf[i];
       assign(egtbfile,path+'KQKPAB.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkqabw,0);
            SetLength(bkpkqabb,0);
            SetLength(bkqkpabw,0);
            SetLength(bkqkpabb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkqkpabb[i-1]:=buf[i];
       fkpkqab:=true;
     end
       else
if (title='KPKQCD') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkqcdw,12*3612*8);
       SetLength(bkpkqcdb,12*3612*8);
       SetLength(bkqkpcdw,12*3612*8);
       SetLength(bkqkpcdb,12*3612*8);

       assign(egtbfile,path+'KPKQCD.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkqcdw,0);
            SetLength(bkpkqcdb,0);
            SetLength(bkqkpcdw,0);
            SetLength(bkqkpcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkqcdw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKQCD.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkqcdw,0);
            SetLength(bkpkqcdb,0);
            SetLength(bkqkpcdw,0);
            SetLength(bkqkpcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkpkqcdb[i-1]:=buf[i];
       assign(egtbfile,path+'KQKPCD.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkqcdw,0);
            SetLength(bkpkqcdb,0);
            SetLength(bkqkpcdw,0);
            SetLength(bkqkpcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkqkpcdw[i-1]:=buf[i];
       assign(egtbfile,path+'KQKPCD.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,12*3612*8,realread);
       close(egtbfile);
       if realread<>12*3612*8 then
          begin
            SetLength(bkpkqcdw,0);
            SetLength(bkpkqcdb,0);
            SetLength(bkqkpcdw,0);
            SetLength(bkqkpcdb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 12*3612*8 do
         bkqkpcdb[i-1]:=buf[i];
       fkpkqcd:=true;
     end
        else
if (title='KPKP') then
     begin
       if ((fileexists(path+title+'.bbw')) and (fileexists(path+title+'.bbb')))=false
           then begin
                 Result:=false;
                 exit;
                end;
       SetLength(bkpkpw,24*3612*8);
       SetLength(bkpkpb,24*3612*8);
       assign(egtbfile,path+'KPKP.bbw');
       reset(egtbfile,1);
       blockread(egtbfile,buf,24*3612*8,realread);
       close(egtbfile);
       if realread<>24*3612*8 then
          begin
            SetLength(bkpkpw,0);
            SetLength(bkpkpb,0);
            Result:=false;
            exit;
          end;
       for i:=1 to 24*3612*8 do
         bkpkpw[i-1]:=buf[i];
       assign(egtbfile,path+'KPKP.bbb');
       reset(egtbfile,1);
       blockread(egtbfile,buf,24*3612*8,realread);
       close(egtbfile);
       if realread<>24*3612*8 then
          begin
            SetLength(bkpkpw,0);
            SetLength(bkpkpb,0);
            Result:=false;
            exit;
          end;
        for i:=1 to 24*3612*8 do
         bkpkpb[i-1]:=buf[i];
       fkpkp:=true;
     end
        else
            begin
              Result:=false;
              exit;
            end;
Result:=true;
end;

Function EGTBBitbaseProbe(color:integer;ply:integer):integer;
// Функция, делающая запрос в битовые базы. Возвращает оценку позиции.
label l1;
var
   rang,wminor,bminor,bmajor,wmajor,wqueens,bqueens,index,ind,byt,wking,bking:integer;
   wpawns,bpawns,pawn:integer;
   wlist,blist:EGTBPieses;
begin
  wmajor:=BitCount(WhiteRooks);
  bmajor:=BitCount(BlackRooks);
  wminor:=BitCount(WhiteKnights or WhiteBishops);
  bminor:=BitCount(BlackKnights or BlackBishops);
  wqueens:=BitCount(WhiteQueens);
  bqueens:=BitCount(BlackQueens);
  wking:=BitScanForward(WhiteKing);
  bking:=BitScanForward(BlackKing);
  wpawns:=BitCount(WhitePawns);
  bpawns:=BitCount(BlackPawns);
 //1. KQK; KRK
    if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=1) and (bqueens=0)
     and (wpawns=0) and (bpawns=0) then
       begin
              // Если база не подгружена, то подгружаем ее
              if (not fkqk) then
                if (not LoadBB('KQK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(WList,Blist);
              if index=BadIndex then goto l1;
              if color=white
                then rang:=bkqkw[index]
                else rang:=bkqkb[index];
                if rang=Illegal then goto l1;
              if rang in [Draw,DeadDraw,Stalemate] then
                 begin
                 Result:=0;
                 exit;
                 end
                else
                if rang=EGTBMate
                 then
                   begin
                   Result:=Mate-ply+1;
                   exit;
                   end
                else
                  if (rang>0) and (rang<100) then
                   begin
                   Result:=Mate-ply-(rang*2+1)+1;
                   if color=white then inc(Result);
                   exit;
                   end;
       end;
    if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=1)
    and (wpawns=0) and (bpawns=0) then
       begin
              // Если база не подгружена, то подгружаем ее
              if (not fkqk) then
                if (not LoadBB('KQK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(BList,Wlist);
              if index=BadIndex then goto l1;
              if color=black
                then rang:=bkqkw[index]
                else rang:=bkqkb[index];
                if rang=Illegal then goto l1;
              if rang in [Draw,DeadDraw,Stalemate] then
                 begin
                 Result:=0;
                 exit;
                 end
                else
                if rang=EGTBMate then Result:=-(Mate-ply+1)
                else
                   begin
                   Result:=-(Mate-ply-(rang*2+1)+1);
                   if color=black then dec(Result);
                   end;
              exit;
       end;
     if (wmajor=1) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=0)
     and (wpawns=0) and (bpawns=0)then
       begin
              // Если база не подгружена, то подгружаем ее
              if (not fkrk) then
                if (not LoadBB('KRK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(WList,Blist);
               if index=BadIndex then goto l1;
              if color=white
                then rang:=bkrkw[index]
                else rang:=bkrkb[index];
                if rang=Illegal then goto l1;
              if rang in [Draw,DeadDraw,Stalemate] then
                 begin
                 Result:=0;
                 exit;
                 end
                else
                if rang=EGTBMate then Result:=Mate-ply+1
                else
                   begin
                   Result:=Mate-ply-(rang*2+1)+1;
                   if color=white then inc(Result);
                   end;
              exit;
       end;
    if (wmajor=0) and (wminor=0) and (bmajor=1) and (bminor=0) and (wqueens=0) and (bqueens=0)
    and (wpawns=0) and (bpawns=0) then
       begin
              // Если база не подгружена, то подгружаем ее
              if (not fkrk) then
                if (not LoadBB('KRK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(BList,Wlist);
               if index=BadIndex then goto l1;
              if color=black
                then rang:=bkrkw[index]
                else rang:=bkrkb[index];
                if rang=Illegal then goto l1;
              if rang in [Draw,DeadDraw,Stalemate] then
                 begin
                 Result:=0;
                 exit;
                 end
                else
                if rang=EGTBMate then Result:=-(Mate-ply+1)
                else
                   begin
                   Result:=-(Mate-ply-(rang*2+1)+1);
                   if color=black then dec(Result);
                   end;
              exit;
       end;
   //Пошли четырехфигурные
   // KQKQ
   if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=1) and (bqueens=1)
   and (wpawns=0) and (bpawns=0)then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkqkq) then
                if (not LoadBB('KQKQ')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              if color=white then
                begin
                  index:=PawnlessIndex(WList,Blist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkqw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                   exit;
                                  end;
                  index:=PawnlessIndex(BList,Wlist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkqb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnlessIndex(BList,Wlist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkqw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                   exit;
                                  end;
                  index:=PawnlessIndex(WList,Blist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkqb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end

       end;
    // KQKR
   if (wmajor=0) and (wminor=0) and (bmajor=1) and (bminor=0) and (wqueens=1) and (bqueens=0)
   and (wpawns=0) and (bpawns=0)then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkqkr) then
                if (not LoadBB('KQKR')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              if color=white then
                begin
                  index:=PawnlessIndex(WList,Blist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkrw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                   exit;
                                  end;
                  index:=PawnlessIndex(BList,Wlist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkqb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnlessIndex(BList,Wlist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkqw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                   exit;
                                  end;
                  index:=PawnlessIndex(WList,Blist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkrb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
       end;
    
   if (wmajor=1) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=1)
   and (wpawns=0) and (bpawns=0)then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkqkr) then
                if (not LoadBB('KQKR')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              if color=white then
                begin
                  index:=PawnlessIndex(WList,Blist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkqw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                   exit;
                                  end;
                  index:=PawnlessIndex(BList,Wlist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkrb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnlessIndex(BList,Wlist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkrw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                   exit;
                                  end;
                  index:=PawnlessIndex(WList,Blist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkqb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
       end;
   // KRKR
   if (wmajor=1) and (wminor=0) and (bmajor=1) and (bminor=0) and (wqueens=0) and (bqueens=0)
   and (wpawns=0) and (bpawns=0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkrkr) then
                if (not LoadBB('KRKR')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              if color=white then
                begin
                  index:=PawnlessIndex(WList,Blist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkrw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                   exit;
                                  end;
                  index:=PawnlessIndex(BList,Wlist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkrb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnlessIndex(BList,Wlist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkrw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                   exit;
                                  end;
                  index:=PawnlessIndex(WList,Blist);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkrb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
       end;
    // KRKN
   if (wmajor=1) and (wminor=0) and (bmajor=0) and (bminor=1) and (wqueens=0) and (bqueens=0) and (wpawns=0) and (bpawns=0)
      and (BlackKnights<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkrkn) then
                if (not LoadBB('KRKN')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(WList,Blist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkrknw[ind] and (1 shl byt)
                  else rang:=bkrknb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking]+Dist[bking,BitCount(BlackKnights)]*5;
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
   if (wmajor=0) and (wminor=1) and (bmajor=1) and (bminor=0) and (wqueens=0) and (bqueens=0) and (wpawns=0) and (bpawns=0)
      and (WhiteKnights<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkrkn) then
                if (not LoadBB('KRKN')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(BList,Wlist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkrknw[ind] and (1 shl byt)
                  else rang:=bkrknb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking]-Dist[wking,BitCount(WhiteKnights)]*5;
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
  // KRKB
   if (wmajor=1) and (wminor=0) and (bmajor=0) and (bminor=1) and (wqueens=0) and (bqueens=0)and (wpawns=0) and (bpawns=0)
      and (BlackBishops<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkrkb) then
                if (not LoadBB('KRKB')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(WList,Blist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkrkbw[ind] and (1 shl byt)
                  else rang:=bkrkbb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
   if (wmajor=0) and (wminor=1) and (bmajor=1) and (bminor=0) and (wqueens=0) and (bqueens=0)and (wpawns=0) and (bpawns=0)
      and (WhiteBishops<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkrkb) then
                if (not LoadBB('KRKB')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(BList,Wlist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkrkbw[ind] and (1 shl byt)
                  else rang:=bkrkbb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
    // KQKB
   if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=1) and (wqueens=1) and (bqueens=0) and (wpawns=0) and (bpawns=0)
      and (BlackBishops<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkqkb) then
                if (not LoadBB('KQKB')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(WList,Blist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkqkbw[ind] and (1 shl byt)
                  else rang:=bkqkbb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
   if (wmajor=0) and (wminor=1) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=1) and (wpawns=0) and (bpawns=0)
      and (WhiteBishops<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkqkb) then
                if (not LoadBB('KQKB')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(BList,Wlist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkqkbw[ind] and (1 shl byt)
                  else rang:=bkqkbb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
   // KQKN
   if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=1) and (wqueens=1) and (bqueens=0)and (wpawns=0) and (bpawns=0)
      and (BlackKnights<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkqkn) then
                if (not LoadBB('KQKN')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(WList,Blist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkqknw[ind] and (1 shl byt)
                  else rang:=bkqknb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
   if (wmajor=0) and (wminor=1) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=1)and (wpawns=0) and (bpawns=0)
      and (WhiteKnights<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkqkn) then
                if (not LoadBB('KQKN')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(BList,Wlist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkqknw[ind] and (1 shl byt)
                  else rang:=bkqknb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
    // KBNK
   if (wmajor=0) and (wminor=2) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=0) and (wpawns=0) and (bpawns=0)
      and (WhiteKnights<>0) and (WhiteBishops<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkbnk) then
                if (not LoadBB('KBNK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(WList,Blist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkbnkw[ind] and (1 shl byt)
                  else rang:=bkbnkb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
   if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=2) and (wqueens=0) and (bqueens=0) and (wpawns=0) and (bpawns=0)
      and (BlackKnights<>0) and (BlackBishops<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkbnk) then
                if (not LoadBB('KBNK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(BList,Wlist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkbnkw[ind] and (1 shl byt)
                  else rang:=bkbnkb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
   // KBBK
   if (wmajor=0) and (wminor=2) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=0) and (wpawns=0) and (bpawns=0)
      and (WhiteKnights=0) and (WhiteBishops<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkbbk) then
                if (not LoadBB('KBBK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(WList,Blist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkbbkw[ind] and (1 shl byt)
                  else rang:=bkbbkb[ind] and (1 shl byt);

              if rang<>0 then begin
                                Result:=EGTBWIN-Dist[wking,bking]*2-KMATE[bking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
   if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=2) and (wqueens=0) and (bqueens=0) and (wpawns=0) and (bpawns=0)
      and (BlackKnights=0) and (BlackBishops<>0) then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkbbk) then
                if (not LoadBB('KBBK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnlessIndex(BList,Wlist);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkbbkw[ind] and (1 shl byt)
                  else rang:=bkbbkb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=-EGTBWIN+Dist[wking,bking]*2+KMATE[wking];
                                exit;
                              end;
                  Result:=0;
                  exit;
       end;
       //KPK
   if (wmajor=0) and (wminor=0) and (wqueens=0) and (bmajor=0) and (bminor=0) and (bqueens=0)
      and (wpawns=1) and (bpawns=0) then
        begin
         if (not fkpk) then
             if (not LoadBB('KPK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnIndex(WList,Blist,false);
              if index=BadIndex then goto l1;
              if color=white
                then rang:=bkpkw[index]
                else rang:=bkpkb[index];
                if rang=Illegal then goto l1;
              if rang in [Draw,DeadDraw,Stalemate] then
                 begin
                 result:=0;
                 exit;
                 end
                else
                if rang=EGTBMate
                then
                    begin
                    result:=Mate-ply+1;
                    exit;
                    end
                else
                  if (rang>0) and (rang<100) then
                   begin
                    result:=Mate-ply-(rang*2+1)+1;
                    if color=white then inc(result);
                    exit;
                   end;

        end;
  if (wmajor=0) and (wminor=0) and (wqueens=0) and (bmajor=0) and (bminor=0) and (bqueens=0)
      and (wpawns=0) and (bpawns=1) then
      begin
       if (not fkpk) then
       if (not LoadBB('KPK')) then goto l1;
              // Делаем пробинг
              FillLists(Wlist,Blist);
              index:=PawnIndex(BList,Wlist,true);
              if index=BadIndex then goto l1;
              if color=black
                then rang:=bkpkw[index]
                else rang:=bkpkb[index];
                if rang=Illegal then goto l1;
              if rang in [Draw,DeadDraw,Stalemate] then
                 begin
                 result:=0;
                 exit;
                 end
                else
                if rang=EGTBMate then
                   begin
                   result:=-(Mate-ply+1);
                   exit;
                   end
                else
                  if (rang>0) and (rang<100) then
                   begin
                   result:=-(Mate-ply-(rang*2+1)+1);
                   if color=black then dec(result);
                   exit;
                   end;
              
      end;
// KPKN
    if (wmajor=0) and (wminor=0) and (wqueens=0) and (bmajor=0) and (bminor=1) and (bqueens=0)
      and (wpawns=1) and (bpawns=0) and (BlackKnights<>0) then
        begin
         FillLists(Wlist,Blist);
         if Posx[wlist[2,2]] in [1,2,7,8] then
            begin
              if (not fkpknab) then
              if (not LoadBB('KPKNAB')) then goto l1;
              // Делаем пробинг
              index:=PawnIndex(WList,Blist,false);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkpknabw[ind] and (1 shl byt)
                  else rang:=bkpknabb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[1,2]];
                                exit;
                              end;
                  Result:=0;
                  exit;
            end
                else
            begin
             if (not fkpkncd) then
              if (not LoadBB('KPKNCD')) then goto l1;
              // Делаем пробинг
              index:=PawnIndex(WList,Blist,false);
              if index=BadIndex then goto l1;
              index:=index-12*3612*64;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkpkncdw[ind] and (1 shl byt)
                  else rang:=bkpkncdb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[1,2]];
                                exit;
                              end;
                  Result:=0;
                  exit;
            end;

        end;
if (wmajor=0) and (wminor=1) and (wqueens=0) and (bmajor=0) and (bminor=0) and (bqueens=0)
      and (wpawns=0) and (bpawns=1) and (WhiteKnights<>0) then
        begin
         FillLists(Wlist,Blist);
         if Posx[blist[2,2]] in [1,2,7,8] then
            begin
              if (not fkpknab) then
              if (not LoadBB('KPKNAB')) then goto l1;
              // Делаем пробинг
              index:=PawnIndex(BList,Wlist,true);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkpknabw[ind] and (1 shl byt)
                  else rang:=bkpknabb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[1,2]]);
                                exit;
                              end;
                  Result:=0;
                  exit;
            end
                else
            begin
             if (not fkpkncd) then
              if (not LoadBB('KPKNCD')) then goto l1;
              // Делаем пробинг
              index:=PawnIndex(BList,Wlist,true);
              if index=BadIndex then goto l1;
              index:=index-12*3612*64;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkpkncdw[ind] and (1 shl byt)
                  else rang:=bkpkncdb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[1,2]]);
                                exit;
                              end;
                  Result:=0;
                  exit;
            end;

        end;

// KPKB
    if (wmajor=0) and (wminor=0) and (wqueens=0) and (bmajor=0) and (bminor=1) and (bqueens=0)
      and (wpawns=1) and (bpawns=0) and (BlackBishops<>0) then
        begin
         FillLists(Wlist,Blist);
         if Posx[wlist[2,2]] in [1,2,7,8] then
            begin
              if (not fkpkbab) then
              if (not LoadBB('KPKBAB')) then goto l1;
              // Делаем пробинг
              index:=PawnIndex(WList,Blist,false);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkpkbabw[ind] and (1 shl byt)
                  else rang:=bkpkbabb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[1,2]];
                                exit;
                              end;
                  Result:=0;
                  exit;
            end
                else
            begin
             if (not fkpkbcd) then
              if (not LoadBB('KPKBCD')) then goto l1;
              // Делаем пробинг
              index:=PawnIndex(WList,Blist,false);
              if index=BadIndex then goto l1;
              index:=index-12*3612*64;
              ind:=index div 8;
              byt:=index mod 8;
              if color=white
                  then rang:=bkpkbcdw[ind] and (1 shl byt)
                  else rang:=bkpkbcdb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[1,2]];
                                exit;
                              end;
                  Result:=0;
                  exit;
            end;

        end;
if (wmajor=0) and (wminor=1) and (wqueens=0) and (bmajor=0) and (bminor=0) and (bqueens=0)
      and (wpawns=0) and (bpawns=1) and (WhiteBishops<>0) then
        begin
         FillLists(Wlist,Blist);
         if Posx[blist[2,2]] in [1,2,7,8] then
            begin
              if (not fkpkbab) then
              if (not LoadBB('KPKBAB')) then goto l1;
              // Делаем пробинг
              index:=PawnIndex(BList,Wlist,true);
              if index=BadIndex then goto l1;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkpkbabw[ind] and (1 shl byt)
                  else rang:=bkpkbabb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[1,2]]);
                                exit;
                              end;
                  Result:=0;
                  exit;
            end
                else
            begin
             if (not fkpkbcd) then
              if (not LoadBB('KPKBCD')) then goto l1;
              // Делаем пробинг
              index:=PawnIndex(BList,Wlist,true);
              if index=BadIndex then goto l1;
              index:=index-12*3612*64;
              ind:=index div 8;
              byt:=index mod 8;
              if color=black
                  then rang:=bkpkbcdw[ind] and (1 shl byt)
                  else rang:=bkpkbcdb[ind] and (1 shl byt);
              if rang<>0 then begin
                                Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[1,2]]);
                                exit;
                              end;
                  Result:=0;
                  exit;
            end;

        end;
   // KPKR
   if (wmajor=0) and (wminor=0) and (bmajor=1) and (bminor=0) and (wqueens=0) and (bqueens=0)
   and (wpawns=1) and (bpawns=0)then
       begin
          FillLists(Wlist,Blist);
         if Posx[wlist[2,2]] in [1,2,7,8] then
            begin
         // Если база не подгружена, то подгружаем ее
              if (not fkpkrab) then
                if (not LoadBB('KPKRAB')) then goto l1;
              // Делаем пробинг
              if color=white then
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkrabw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkpabb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkpabw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkrabb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
            end
               else
            begin
             // Если база не подгружена, то подгружаем ее
              if (not fkpkrcd) then
                if (not LoadBB('KPKRCD')) then goto l1;
              // Делаем пробинг
              if color=white then
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkrcdw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkpcdb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkpcdw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkrcdb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
            end;
       end;
 if (wmajor=1) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=0)
   and (wpawns=0) and (bpawns=1)then
       begin
          FillLists(Wlist,Blist);
         if Posx[blist[2,2]] in [1,2,7,8] then
            begin
         // Если база не подгружена, то подгружаем ее
              if (not fkpkrab) then
                if (not LoadBB('KPKRAB')) then goto l1;
              // Делаем пробинг
              if color=black then
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkrabw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkpabb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkpabw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkrabb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
            end
               else
            begin
             // Если база не подгружена, то подгружаем ее
              if (not fkpkrcd) then
                if (not LoadBB('KPKRCD')) then goto l1;
              // Делаем пробинг
              if color=black then
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkrcdw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkpcdb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkrkpcdw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkrcdb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
            end;
       end;
 // KPKQ
   if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=1)
   and (wpawns=1) and (bpawns=0)then
       begin
          FillLists(Wlist,Blist);
         if Posx[wlist[2,2]] in [1,2,7,8] then
            begin
         // Если база не подгружена, то подгружаем ее
              if (not fkpkqab) then
                if (not LoadBB('KPKQAB')) then goto l1;
              // Делаем пробинг
              if color=white then
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkqabw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkpabb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkpabw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkqabb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
            end
               else
            begin
             // Если база не подгружена, то подгружаем ее
              if (not fkpkqcd) then
                if (not LoadBB('KPKQCD')) then goto l1;
              // Делаем пробинг
              if color=white then
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkqcdw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkpcdb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkpcdw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkqcdb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]];
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
            end;
       end;
 if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=1) and (bqueens=0)
   and (wpawns=0) and (bpawns=1)then
       begin
          FillLists(Wlist,Blist);
         if Posx[blist[2,2]] in [1,2,7,8] then
            begin
         // Если база не подгружена, то подгружаем ее
              if (not fkpkqab) then
                if (not LoadBB('KPKQAB')) then goto l1;
              // Делаем пробинг
              if color=black then
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkqabw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkpabb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkpabw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkqabb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
            end
               else
            begin
             // Если база не подгружена, то подгружаем ее
              if (not fkpkqcd) then
                if (not LoadBB('KPKQCD')) then goto l1;
              // Делаем пробинг
              if color=black then
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkqcdw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkpcdb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkqkpcdw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  index:=index-12*3612*64;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkqcdb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-EGTBWIN-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
            end;
       end;

 // KPKP
   if (wmajor=0) and (wminor=0) and (bmajor=0) and (bminor=0) and (wqueens=0) and (bqueens=0)
   and (wpawns=1) and (bpawns=1)then
       begin
         // Если база не подгружена, то подгружаем ее
              if (not fkpkp) then
                if (not LoadBB('KPKP')) then goto l1;
              // Делаем пробинг
                FillLists(Wlist,Blist);
              if color=white then
                begin
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkpw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]]-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkpb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-(EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]]-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]));
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end
                   else
                begin
                  index:=PawnIndex(BList,Wlist,true);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkpw[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=-(EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]]-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]));
                                   exit;
                                  end;
                  index:=PawnIndex(WList,Blist,false);
                  if index=BadIndex then goto l1;
                  ind:=index div 8;
                  byt:=index mod 8;
                  rang:=bkpkpb[ind] and (1 shl byt);
                  if rang<>0 then begin
                                   Result:=EGTBWIN+Dist[wking,wlist[2,2]]*2+10*Posy[wlist[2,2]]-Dist[bking,blist[2,2]]*2-10*(9-Posy[blist[2,2]]);
                                   exit;
                                  end;
                  Result:=0;
                  exit;
                end

       end;

l1:
  Result:=BadIndex;

end;

Procedure ClearMemory;
// Процедура освобождает память от находящихся там битовых баз.
begin
fkqk:=false;
fkrk:=false;
fkqkq:=false;
fkqkr:=false;
fkqkb:=false;
fkqkn:=false;
fkrkq:=false;
fkrkr:=false;
fkrkb:=false;
fkrkn:=false;
fkbbk:=false;
fkbnk:=false;
fkpk:=false;
fkpknab:=false;
fkpkncd:=false;
fkpkbab:=false;
fkpkbcd:=false;
fkpkrab:=false;
fkpkrcd:=false;
fkpkqab:=false;
fkpkqcd:=false;
fkpkp:=false;
fkrkpab:=false;
fkrkpcd:=false;
fkqkpab:=false;
fkqkpcd:=false;
SetLength(bkqkw,0);
SetLength(bkrkw,0);
SetLength(bkqkqw,0);
SetLength(bkqkrw,0);
SetLength(bkqkbw,0);
SetLength(bkqknw,0);
SetLength(bkrkqw,0);
SetLength(bkrkrw,0);
SetLength(bkrkbw,0);
SetLength(bkrknw,0);
SetLength(bkbbkw,0);
SetLength(bkbnkw,0);
SetLength(bkqkb,0);
SetLength(bkrkb,0);
SetLength(bkqkqb,0);
SetLength(bkqkrb,0);
SetLength(bkqkbb,0);
SetLength(bkqknb,0);
SetLength(bkrkqb,0);
SetLength(bkrkrb,0);
SetLength(bkrkbb,0);
SetLength(bkrknb,0);
SetLength(bkbbkb,0);
SetLength(bkbnkb,0);
SetLength(bkpkw,0);
SetLength(bkpkb,0);
SetLength(bkpknabw,0);
SetLength(bkpknabb,0);
SetLength(bkpkncdw,0);
SetLength(bkpkncdb,0);
SetLength(bkpkbabw,0);
SetLength(bkpkbabb,0);
SetLength(bkpkbcdw,0);
SetLength(bkpkbcdb,0);
SetLength(bkpkrabw,0);
SetLength(bkpkrabb,0);
SetLength(bkpkrcdw,0);
SetLength(bkpkrcdb,0);
SetLength(bkpkqabw,0);
SetLength(bkpkqabb,0);
SetLength(bkpkqcdw,0);
SetLength(bkpkqcdb,0);
SetLength(bkpkpw,0);
SetLength(bkpkpb,0);
SetLength(bkrkpabw,0);
SetLength(bkrkpabb,0);
SetLength(bkrkpcdw,0);
SetLength(bkrkpcdb,0);
SetLength(bkqkpabw,0);
SetLength(bkqkpabb,0);
SetLength(bkqkpcdw,0);
SetLength(bkqkpcdb,0);
end;

end.


