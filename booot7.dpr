program booot7;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$APPTYPE CONSOLE}

{$R resource.res}

uses
  {$ifdef UNIX}
  cthreads,
  {$endif }
  uBitBoards in 'uBitBoards.pas',
  uMagic in 'uMagic.pas',
  uAttacks in 'uAttacks.pas',
  uBoard in 'uBoard.pas',
  uHash in 'uHash.pas',
  uEndgame in 'uEndgame.pas',
  uEval in 'uEval.pas',
  uSearch in 'uSearch.pas',
  uThread in 'uThread.pas',
  uSort in 'uSort.pas',
  uUci in 'uUci.pas',
  uKPK in 'uKPK.pas',
  Unn in 'Unn.pas',
  Ubenchmark in 'Ubenchmark.pas';

Procedure EngineInit;
// Инициализация движка сразу после старта
var
  i : integer;
begin
  // грузим нейросеть
  LoadNet('booot71.nn');
  writeln(GetFullVersionName(Net.model));
  // Инициализация структуры данных потоков перед запуском
  for i:=1 to MaxThreads do
    begin
      Threads[i].idle:=true;
      Threads[i].isRun:=false;
    end;
  // По умолчанию работает один поток для перебора - создаем его
  game.Threads:=1;
  InitThreads(game.Threads);
  // Устанавливаем размер глобального хеша по умолчанию
  game.hashsize:=128;
  SetHash(TTGlobal,game.hashsize);
  // Глобальные параметры по умолчанию
  game.showtext:=true;
  game.uciPonder:=false;
  game.doIIR:=True;
  game.doLMP:=True;
  // Устанавливаем стартовую позицию на доске и готовимся к перебору
  NewGame;
end;

begin
  EngineInit;
  if (paramcount>0) then
    begin
      if (Paramstr(1)='bench') then bench;
      exit;
    end;
  //bench;
 // writeln(False xor False);
  //writeln(SizeOf(TThread));
  //FenGenerator(10,700,32,'book.fen','10d_',128,1024);
  //newgame;
  //speedtest;
  //CheckBatch('array2',10000);
  MainLoop;
end.
