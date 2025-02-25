﻿program booot7;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$APPTYPE CONSOLE}

{$R 'resource.res'}
//{$R 'resource.res' 'resource.rc'}


uses
  {$ifdef UNIX}
  cthreads,
  {$endif }
  SysUtils,
  {$ifdef WIN64}
  windows,
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
  uNN in 'uNN.pas',
  uBenchmark in 'uBenchmark.pas';

Procedure EngineInit;
// Инициализация движка сразу после старта
var
  i : integer;
begin
  // грузим нейросеть
  for i := 1 to MaxNets do
    LoadNet('MYNN'+inttostr(i),Nets[i-1]);
  writeln(GetFullVersionName);
  game.syzygyman:=0;
  game.syzygydepth:=1;
  {$ifdef WIN64}
    handle := LoadLibrary('syzygy.dll');
    if handle<>0 then
      begin
       @egtbinit := GetProcAddress(handle, 'boootInit');
       @egtbprobe := GetProcAddress(handle, 'boootProbe');
       if (@egtbinit<>nil) and (@egtbprobe<>nil) then writeln('Syzygy DLL is loaded');
       if egtbinit('D:/syzygy3456/') then
         begin
          writeln('Syzygy found');
          game.syzygyman:=6;
         end;
      end;
 {$endif}

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
  //bb:=0;
 // gg:=0;
 // bench;
 // writeln(gg);
 // writeln(bb);
 // writeln(False xor False);
  //writeln(SizeOf(TThread));
  //FenGenerator(12,510,30,'book.fen','12d_',128,1024,'d:/syzygy3456/');
  //newgame;
  //speedtest;

  //checkbinary(0,'1data.bin',100000);
  //checkbinary(0,'2data.bin',100000);
  //checkbinary(0,'3data.bin',100000);

  MainLoop;
end.
