unit root;

interface
uses params,captures,genmoves,make,fors,attacks,sysutils,bitboards;

Procedure GenerateRoot(color :integer);
Procedure PutOnTop(move:integer);
implementation
uses search;
Procedure GenerateRoot(color :integer);
var
   i,temp,point,p,opking: integer;
   fl : boolean;
   t1:int64;
begin
  GetCaptures(color,1,WhitePieses,BlackPieses);
  GetMoves(color,1);
  point:=128;
  p:=point+Moves[point];
  For i:=point+1 to point+takes[point] do
       Moves[i-point+p]:=Takes[i];
  Moves[point]:=Moves[point]+Takes[point];
  if color=white then
      begin
        opking:=tree[1].Bking;
      end
          else
      begin
        opking:=tree[1].wking;
      end;
      t1:=allpieses;
  rep:=rule50[1];    
  For i:=point+1 to point+Moves[point] do
      begin
      if MakeMove(color,Moves[i],1) then
         begin
           tree[2].onCheck:=isAttack(color,opking);
           MTakes[i]:=-FV(color xor 1,-Mate,Mate,2,true,-mate);
           UnMakeMove(color,Moves[i],1);
         end
            else
                begin
                UnMakeMove(color,Moves[i],1);
                MTakes[i]:=-Mate-1;
                end;
      if t1<>allpieses then
         writeln;
      end;
   repeat
   fl:=true ;
   for i:=point+1 to point+Moves[point]-1 do
     begin
      if Mtakes[i+1]>MTakes[i] then
        begin
          fl:=false;
          temp:=Mtakes[i];
          Mtakes[i]:=Mtakes[i+1];
          Mtakes[i+1]:=temp;
          temp:=Moves[i];
          Moves[i]:=Moves[i+1];
          Moves[i+1]:=temp;
        end;

     end;
   until fl;
   p:=0;
   for i:=point+1 to point+Moves[point] do
     if Mtakes[i]>-Mate then inc(p);
   Moves[point]:=p;
// Устанавливаем флажок раннего выхода
EasyExit:=false;
if Mtakes[point+1]>Mtakes[point+2]+150 then EasyExit:=true;
//  for i:=point+1 to point+Moves[point] do
//  LPrint(decode[Moves[i] and 255]+Decode[(Moves[i] shr 8) and 255]+' '+inttostr(Mtakes[i]));
end;

Procedure PutOnTop(move:integer);
var
   i,point,temp,j: integer;
begin
  point:=128;
  for i:=point+1 to point+Moves[point] do
    if Moves[i]=move then
       begin
         temp:=moves[i];
         for j:=i-1 downto point+1 do
           Moves[j+1]:=Moves[j];
         moves[point+1]:=temp;
       end;
   
end;
end.

