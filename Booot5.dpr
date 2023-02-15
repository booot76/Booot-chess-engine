program Booot5;

{$APPTYPE CONSOLE}

uses
  BitBoards in 'BitBoards.pas',
  MoveGen in 'MoveGen.pas',
  Board in 'Board.pas',
  move in 'move.pas',
  params in 'params.pas',
  attacks in 'attacks.pas',
  Perft in 'Perft.pas',
  hash in 'hash.pas',
  Material in 'Material.pas',
  Pawn in 'Pawn.pas',
  Safety in 'Safety.pas',
  Evaluation in 'Evaluation.pas',
  Sort in 'Sort.pas',
  History in 'History.pas',
  Search in 'Search.pas',
  Uci in 'Uci.pas',
  Endgame in 'Endgame.pas';

begin
 Init;
 Main;

end.
