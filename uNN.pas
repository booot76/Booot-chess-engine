unit Unn;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$Define pext}
//{$Define AddLayer}
interface
uses SysUtils,Classes,types,uBitBoards,uBoard,DateUtils;

Const

  isHmirror : array[0..8] of boolean = (False,False,True,False   ,False,True,True,True,True);
                                      //Zero  flank Edge flankext  file, K10  K12  K14  K16
  MaxNets=3;
  current_version=35;  // что проверяем при загрузке сети
  AVX_8=32;            // 8*32=256 bit
  AVX_16=16;           // 16*16=256  bit

  hidden1=1024;  // число нейронов в первом слое
  hidden2=8;
  hidden3=32;
  {$IFNDEF AddLayer}
    half=hidden1 div 2;  // размер половинки аккумулятора (за одну сторону)
  {$ENDIF}
  {$IFDEF AddLayer}
    half=hidden1;       // размер половинки аккумулятора (за одну сторону)
  {$ENDIF}
  quarter=half div 2;   // половинка половинки аккумулятора
  // ACC_RELU
  cycle1=half div (2*AVX_16);  // Relu аккумулятора обрабатывает сразу по 2 за AVX2 регистра 16-разрядных элементов раз
  // First_Layer_mul
  cycle2=hidden2 div 8;        // зависит от количество нейронов во втором слое. Должно быть кратно 8 - обрабатываем по 8 сразу
  cycle3=hidden1 div AVX_8;    // Количество кусочков вектора hidden1 обрабатывая их как 8 битные числа
  cycle4=hidden1*8;            // обрабатываем сразу по 8 векторов (столбцов)
  // Second_Layer_mul
  cycle5=hidden3 div 4;        // Счетчик столбцов hidden3 по 4
  cycle6=half div AVX_16;      // Счетчик кусочков для апдейта аккумуляторов
  cycle7=quarter div AVX_8;    // для слоя ADD
  cycle10=hidden2*4*4;         // длина 4 столбцов hidden2 в байтах
  // upd_buffer
  cycle8=half div(AVX_16*8);  // Счетчик кусочков для апдейта аккумуляторов для 8 регистров сразу
  // Second_RELU,out
  cycle9=hidden3 div 8;       // Счетчик столбцов hidden3 по 8



  limit8=255;  // Макс предел 8 битового числа
  ones512 : array[0..63] of int16=(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
  RELUlimit : array[0..15] of integer=(limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8);
  Permut1 : array[0..7] of integer=(0,1,4,5,2,3,6,7);
  ModelBlockSize=64*12+2+2; // С признаками рокировок в блоке

  PieseBlock:array[-King..King] of integer=(704,640,576,512,448,384,0,0,64,128,192,256,320);

  WShortCastle=768;
  WLongCastle =769;
  BShortCastle=770;
  BLongCastle =771;
  MaxFrameSize=ModelBlockSize*16; // Модель К16 максимальная с точки зрения количества признаков

  KingMirror : array[0..63] of integer =(
   0,0,0,0,1,1,1,1,
   0,0,0,0,1,1,1,1,
   0,0,0,0,1,1,1,1,
   0,0,0,0,1,1,1,1,
   0,0,0,0,1,1,1,1,
   0,0,0,0,1,1,1,1,
   0,0,0,0,1,1,1,1,
   0,0,0,0,1,1,1,1);

  HMirror :  array[0..63] of integer =(
    7, 6, 5, 4, 3, 2, 1, 0,
   15,14,13,12,11,10, 9, 8,
   23,22,21,20,19,18,17,16,
   31,30,29,28,27,26,25,24,
   39,38,37,36,35,34,33,32,
   47,46,45,44,43,42,41,40,
   55,54,53,52,51,50,49,48,
   63,62,61,60,59,58,57,56);

  EdgeBlock : array[0..63] of integer =(        // Для модели Edge
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize);
  K10Block : array[0..63] of integer =(        // Для модели К10
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      4*ModelBlockSize,4*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,4*ModelBlockSize,4*ModelBlockSize,
      4*ModelBlockSize,4*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,4*ModelBlockSize,4*ModelBlockSize,
      6*ModelBlockSize,6*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,6*ModelBlockSize,6*ModelBlockSize,
      6*ModelBlockSize,6*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,6*ModelBlockSize,6*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize);
  K12Block : array[0..63] of integer =(        // Для модели К12
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      4*ModelBlockSize,4*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,4*ModelBlockSize,4*ModelBlockSize,
      6*ModelBlockSize,6*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,6*ModelBlockSize,6*ModelBlockSize,
      6*ModelBlockSize,6*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,6*ModelBlockSize,6*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize,
      10*ModelBlockSize,10*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,10*ModelBlockSize,10*ModelBlockSize,
      10*ModelBlockSize,10*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,10*ModelBlockSize,10*ModelBlockSize);
  K14Block : array[0..63] of integer =(        // Для модели К14
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      4*ModelBlockSize,5*ModelBlockSize,6*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,6*ModelBlockSize,5*ModelBlockSize,4*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize,
      10*ModelBlockSize,10*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,10*ModelBlockSize,10*ModelBlockSize,
      10*ModelBlockSize,10*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,10*ModelBlockSize,10*ModelBlockSize,
      12*ModelBlockSize,12*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,12*ModelBlockSize,12*ModelBlockSize,
      12*ModelBlockSize,12*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,12*ModelBlockSize,12*ModelBlockSize);
  K16Block : array[0..63] of integer =(        // Для модели К16
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      4*ModelBlockSize,5*ModelBlockSize,6*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,6*ModelBlockSize,5*ModelBlockSize,4*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize,
      10*ModelBlockSize,10*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,11*ModelBlockSize,10*ModelBlockSize,10*ModelBlockSize,
      12*ModelBlockSize,12*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,12*ModelBlockSize,12*ModelBlockSize,
      12*ModelBlockSize,12*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,13*ModelBlockSize,12*ModelBlockSize,12*ModelBlockSize,
      14*ModelBlockSize,14*ModelBlockSize,15*ModelBlockSize,15*ModelBlockSize,15*ModelBlockSize,15*ModelBlockSize,14*ModelBlockSize,14*ModelBlockSize,
      14*ModelBlockSize,14*ModelBlockSize,15*ModelBlockSize,15*ModelBlockSize,15*ModelBlockSize,15*ModelBlockSize,14*ModelBlockSize,14*ModelBlockSize);
Type
  Tbuf=array[0..64] of Pbyte;    // Буфер устанавливаемых фич при полном пересчете аккумулятора
  Tbuf4=array[0..3] of Pbyte;
  Tacc16 = array[white..black,0..Half-1] of int16;
  Thalf = array[0..half-1] of int16;
  TNeuralNetWeights =packed record
     model       : integer; //Модель нейросети
     scale_act   : real;    // множитель квантования выходов модели [0..2] при обучении соответствует [0..255] после квантования
     scale_out   : integer; // множитель квантования выходного слоя. Может отличаться от степени двойки
     w1          : integer;  // справочная информация по множителю квантования 1 слоя. Проверяется с соответствующей константой
     w2          : integer;  // справочная информация по множителю квантования 2 слоя. Проверяется с соответствующей константой
     ModelSize   : integer;
     FLayer      : array[0..Half*MaxFrameSize-1] of int16;  //[ModelFrameSize,half]
     Fbias       : array[0..Half-1] of int16;
     FirstLayer  : array[0..Hidden1*hidden2-1] of int8;  //[hidden1,hidden2]
     biasFirst   : array[0..hidden2-1] of integer;
     SecondLayer : array[0..hidden2*hidden3-1] of integer; //[hidden2,hidden3]
     biasSecond  : array[0..hidden3-1] of integer;
     outlayer    : array[0..hidden3-1] of integer;      //[hidden3,1]
     outbias     : integer;
     Sigma       : array of integer;
     MaxSigma    : integer;
  end;
   PNeuralNet = ^TNeuralNetWeights;
   TForwardPass =packed record
     Acc16     : Tacc16;                                 // Структура для акумулятора 16 бит  с точки зрения хода белых и хода черных отдельно
     Inputsadd8: array[0..2*half-1]  of byte;            // Что поступает на вход ADD слоев
     Inputs8   : array[0..hidden1-1] of byte;            // То что поступает на вход нейросети после RELU аккумуляторов
     TempFirst : array[0..hidden2+3] of integer;         // результат после прохода первого слоя до RELU - hidden2(+4) int32 элементов
     RELUFirst : array[0..hidden2-1] of integer;         // результат первого слоя после RELU
     TempSecond: array[0..hidden3+3] of integer;         // результат после прохода второго слоя до RELU hidden2(+4) int32 элементов
     RELUSecond: array[0..hidden3-1] of integer;         // результат второго слоя после RELU
     store     : array[0..16*32-1] of byte;              // хранилище для 16 регистров AVX2 (256 бит каждый)
     Net       : PNeuralNet;                             //  Указатель на текущую сетку
   end;

var
   Nets : array[0..MaxNets-1] of  TNeuralNetWeights;
   gg,bb :integer;
  
function GetFullVersionName:ansistring;
Function loadnet(name:shortstring;var CurrNet:TNeuralNetWeights):boolean;
Function NetReSigma(CurrNet:PNeuralNet;y:integer):integer;
Function ForwardPass(SideToMove:integer;var Pass:TForwardPass):integer;
Procedure UpdAcc16(move:integer;var Board:Tboard;var Undo:Tundo;var OldPass:TForwardPass;var NewPass:TForwardPass);
Procedure CopyAcc16(var OldPass:TForwardPass;var NewPass:TForwardPass);
Function GetWhiteFrameIndex(model:integer;var Board:TBoard):integer;
Function GetBlackFrameIndex(model:integer;var Board:TBoard):integer;
Function GetWhiteKingMirror(model:integer;var Board:TBoard):integer;
Function GetBlackKingMirror(model:integer;var Board:TBoard):integer;
Procedure FillWhiteAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
Procedure FillBlackAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
Function ChooseNNIndex(var Board:Tboard):integer;
Procedure checkbinary(netindex:integer;filename:string;n:integer);

implementation
uses uThread;

function GetFullVersionName:ansistring;
   begin
    Result:=VersionName;
    Result:=Result+'_AVX2';
    {$IFDEF pext}
      Result:=Result+'_PEXT';
    {$ENDIF pext}
   end;
Function ReSigma(y:real):integer;
// По значению вероятности [0..1] восстанавливает оценку позиции
begin
  If y<0.000001 then y:=0.000001;
  if y>0.999999 then y:=0.999999;
  result:=round(-410*ln((1/y)-1));
end;
Function NetReSigma(CurrNet:PNeuralNet;y:integer):integer;
// Быстрый поиск значения оценки по сырому выходу из нейросети
var
  score:integer;
begin
  If y<0 then y:=0;
  if y>CurrNet.MaxSigma then y:=CurrNet.MaxSigma;
  score:=CurrNet.Sigma[y];
  Result:=score;
end;
Function ModelFrameSize(model:integer):integer;
var
   res : integer;
begin
  res:=0;
  if model=0 then res:=ModelBlockSize else       // zero model
  if model=1 then res:=3*ModelBlockSize else     // Flank model
  if model=2 then res:=4*ModelBlockSize else     // Edge model
  if model=3 then res:=6*ModelBlockSize else     // FlankExt model
  if model=4 then res:=8*ModelBlockSize else     // File  model
  if model=5 then res:=10*ModelBlockSize else    // K10-model
  if model=6 then res:=12*ModelBlockSize else    // K12-model
  if model=7 then res:=14*ModelBlockSize else    // K14-model
  if model=8 then res:=16*ModelBlockSize;        // K16-model
  Result:=res;
end;
Function SelectFlank(kingsq:integer;ext:boolean):integer;
var
  x,res:integer;
begin
  x:=posx[kingsq];
  if x<4 then res:=0 else
    if x>5 then res:=2
           else res:=1;
  if ext  and (posy[kingsq] >3) then inc(res,3);
  Result:=res;
end;
Function ChooseNNIndex(var Board:Tboard):integer;
var
   AllPiesesBB: TBitBoard;
   wpieses,bpieses,res:integer;
begin
  AllPiesesBB:=Board.Pieses[knight] or Board.Pieses[bishop] or Board.Pieses[rook] or Board.Pieses[queen];
  wpieses:=BitCount(AllPiesesBB and Board.Occupancy[white]);
  bpieses:=BitCount(AllPiesesBB and Board.Occupancy[black]);
  if (wpieses<=2) and (bpieses<=2) then res:=0 else
    if (wpieses<=4) and (bpieses<=4) then res:=1
                                     else res:=2;
  Result:=res;
end;
Procedure AVX2_RELU_ACC(Acc16,Permut,Dest : Pbyte); {$IFDEF FPC} nostackframe assembler;{$ENDIF} // 5,94c  на hidden1=512 (half=256), 11.97 for both
//                      rcx(rdi),rdx(rsi),r8(rdx)
// Получая на вход   аккумулятор за выбранный цвет (256 элементов int16) реализует RELU и  сжимает выход  до int8.Использует SIMD AVX2
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}
  {$ifdef UNIX}
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
  // Карта перемешивания элементов
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  mov r10,cycle1                         // счетчик числа проходов по акк  сycle1*(AVX_16+AVX_16)=half
@@1:
  // Берем первые 16 значений аккумулятора int16
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // Берем вторые 16 значений аккумулятора int16
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // Теперь пакуем  2 по 16 int16 в  int8 (с сатурацией без знака ) = RELU [0..255]
  db 0c5h,0fdh,67h,0c1h                  // AVX2 vpackuswb ymm0,ymm0,ymm1
  // Перемешиваем  для правильного порядка
  db 0c4h,0e2h,6dh,36h,0c0h              // AVX2 vpermd ymm0,ymm2,ymm0
  // Сохраняем 32 int8 элемента
  db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
  // Следующие 16 int16 элементов
  add rcx,32
  add r8, 32
  // Крутим цикл
  sub r10,1
  jnz @@1
  // очищаем "верхний флаг"
  db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_ADDLayer(Source1,Source2,Dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}
//                      rcx(rdi),rdx(rsi),r8(rdx)
// Складывает с сатурацией 2 источника int8 (relu [0..255])  Сохраняет по адресу  DEST ( может совпадать с SOURCE)
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
    mov r10,cycle7                          // счетчик   AVX_8*cycle7=quarter
@@1:
   // читаем строку источника1 (32 элементов int8)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // читаем строку источника2 (32 элементов int8)
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    // Складываем с сатурацией
    db 0c5h,0fdh,0dch,0c1h                 // AVX2 vpaddusb ymm0,ymm0,ymm1
    // Сохраняем обновленные данные
    db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
    // Следующие 32 int8 элементов
    add rcx,32
    add rdx,32
    add r8, 32
    // Крутим цикл
    sub r10,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_FirstLayer_mul(inputs8,weights,Dest,store : Pbyte); {$IFDEF FPC} nostackframe assembler;{$ENDIF}  //AVX2 - 56.74 for 512x8 ;AVX512 - 40.65 for 512x8
//                             rcx(rdi), rdx(rsi), r8(rdx),r9(rcx)
// Перемножаем матрицу [1xhidden1] элементов  int8 на матрицу [hidden1xhidden2] елементов int8 используя SIMD AVX2
// На выходе матрица [1xhidden2] int32 элементов
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}

 // сохраняем все регистры, необходимые для корректной работы
     mov r10,r9
     db 0c4h,0c1h,07eh,07fh,2ah       // AVX  vmovdqu [r10],ymm5
     add r10,32
     db 0c4h,0c1h,07eh,07fh,32h       // AVX  vmovdqu [r10],ymm6
     add r10,32
     db 0c4h,0c1h,07eh,07fh,3ah       // AVX  vmovdqu [r10],ymm7
     add r10,32
     db 0c4h,041h,07eh,07fh,2ah       // AVX  vmovdqu [r10],ymm8
     add r10,32
     db 0c4h,041h,07eh,07fh,0ah       // AVX  vmovdqu [r10],ymm9
     add r10,32
     db 0c4h,041h,07eh,07fh,12h       // AVX  vmovdqu [r10],ymm10
     push r12
     push r13
     push r14
     push r15
    // Вектор единиц
     lea r10,[rip+Ones512];
     db 0c4h,41h,07eh,06fh,12h       // AVX vmovdqu ymm10,[r10]
     mov r10,cycle2                  // счетчик  стобцов (обрабатываем по 8 столбцов за 1 проход цикла) 8*cycle2=hidden2
     // Сохраняем некоторые константы
     mov r11,rcx
     mov r14,hidden1                 // длина вектора (расстояние между столбцами)
 @@1:
     // обнуляем накопители для всех 8 обрабатываемых столбцов
     db 0c5h,0f5h,0efh,0c9h          // AVX2  vpxor ymm1,ymm1,ymm1
     db 0c5h,0edh,0efh,0d2h          // AVX2  vpxor ymm2,ymm2,ymm2
     db 0c5h,0e5h,0efh,0dbh          // AVX2  vpxor ymm3,ymm3,ymm3
     db 0c5h,0ddh,0efh,0e4h          // AVX2  vpxor ymm4,ymm4,ymm4
     db 0c5h,0d5h,0efh,0edh          // AVX2  vpxor ymm5,ymm5,ymm5
     db 0c5h,0cdh,0efh,0f6h          // AVX2  vpxor ymm6,ymm6,ymm6
     db 0c5h,0c5h,0efh,0ffh          // AVX2  vpxor ymm7,ymm7,ymm7
     db 0c4h,041h,03dh,0efh,0c0h     // AVX2  vpxor ymm8,ymm8,ymm8
     mov r13,cycle3                  //  cycle3*AVX_8=hidden1
     mov r12,rdx
     mov r15,rdx
 @@2:
     // Читаем очередной кусочек вектора
     db 0c5h,0feh,06fh,01h           // AVX   vmovdqu ymm0,[rcx]
     // Последовательно перемножаем его на соответствующий кусочек каждого из 8 обрабатываемых столбцов и суммируем с накопителем каждого столбца
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 1 столбца
     db 0c4h,041h,35h,0f5h,0cah       // AVX2 vpmaddwd ymm9,ymm9,ymm10 - умножаем на единичный столбец и приводим к int32
     db 0c4h,0c1h,75h,0feh,0c9h      // AVX2  vpaddd ymm1,ymm1,ymm9  - cуммируем с накопителем 1 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 2 столбца
     db 0c4h,041h,35h,0f5h,0cah       // AVX2 vpmaddwd ymm9,ymm9,ymm10 - умножаем на единичный столбец и приводим к int32
     db 0c4h,0c1h,6dh,0feh,0d1h      // AVX2  vpaddd ymm2,ymm2,ymm9  - cуммируем с накопителем 2 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 3 столбца
     db 0c4h,041h,35h,0f5h,0cah       // AVX2 vpmaddwd ymm9,ymm9,ymm10 - умножаем на единичный столбец и приводим к int32
     db 0c4h,0c1h,65h,0feh,0d9h      // AVX2  vpaddd ymm3,ymm3,ymm9  - cуммируем с накопителем 3 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 4 столбца
     db 0c4h,041h,35h,0f5h,0cah       // AVX2 vpmaddwd ymm9,ymm9,ymm10 - умножаем на единичный столбец и приводим к int32
     db 0c4h,0c1h,5dh,0feh,0e1h      // AVX2  vpaddd ymm4,ymm4,ymm9  - cуммируем с накопителем 4 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 5 столбца
     db 0c4h,041h,35h,0f5h,0cah       // AVX2 vpmaddwd ymm9,ymm9,ymm10 - умножаем на единичный столбец и приводим к int32
     db 0c4h,0c1h,55h,0feh,0e9h      // AVX2  vpaddd ymm5,ymm5,ymm9  - cуммируем с накопителем 5 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 6 столбца
     db 0c4h,041h,35h,0f5h,0cah       // AVX2 vpmaddwd ymm9,ymm9,ymm10 - умножаем на единичный столбец и приводим к int32
     db 0c4h,0c1h,4dh,0feh,0f1h      // AVX2  vpaddd ymm6,ymm6,ymm9  - cуммируем с накопителем 6 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 7 столбца
     db 0c4h,041h,35h,0f5h,0cah       // AVX2 vpmaddwd ymm9,ymm9,ymm10 - умножаем на единичный столбец и приводим к int32
     db 0c4h,0c1h,45h,0feh,0f9h      // AVX2  vpaddd ymm7,ymm7,ymm9  - cуммируем с накопителем 7 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 8 столбца
     db 0c4h,041h,35h,0f5h,0cah       // AVX2 vpmaddwd ymm9,ymm9,ymm10 - умножаем на единичный столбец и приводим к int32
     db 0c4h,041h,3dh,0feh,0c1h      // AVX2  vpaddd ymm8,ymm8,ymm9  - cуммируем с накопителем 8 столбца
     // Крутим в цикле для всех   кусочков вектора и столбцов
     add rcx,32                      // Адрес следующего кусочка вектора
     mov rdx,r15
     add rdx,32                      // Адрес следующего кусочка 1 столбца
     mov r15,rdx
     // Крутим цикл кусочков
     sub r13,1
     jnz @@2
    // Теперь горизонтально суммируем по 4 столбца и сохраняем результаты
     db 0c4h,0e2h,75h,02h,0c2h        // AVX2 vphaddd ymm0,ymm1,ymm2
     db 0c4h,062h,65h,02h,0cch        // AVX2 vphaddd ymm9,ymm3,ymm4
     db 0c4h,0c2h,7dh,02h,0c1h        // AVX2 vphaddd ymm0,ymm0,ymm9
    // Полученный вектор складываем пополам
     db 0c4h,0c3h,7dh,39h,0c1h,01     // AVX2 vextracti128 xmm9,ymm0,0x1
     db 0c4h,0c1h,7dh,0feh,0c1h       // AVX2 vpaddd ymm0,ymm0,ymm9
     // сохраняем результат для первых четырех обработанных столбцов (младшая часть регистра)
     db 0c4h,0c1h,07eh,07fh,00h       // AVX  vmovdqu [r8],ymm0
     add r8,16
     db 0c4h,0e2h,55h,02h,0c6h        // AVX2 vphaddd ymm0,ymm5,ymm6
     db 0c4h,042h,45h,02h,0c8h        // AVX2 vphaddd ymm9,ymm7,ymm8
     db 0c4h,0c2h,7dh,02h,0c1h        // AVX2 vphaddd ymm0,ymm0,ymm9
    // Полученный вектор складываем пополам
     db 0c4h,0c3h,7dh,39h,0c1h,01     // AVX2 vextracti128 xmm9,ymm0,0x1
     db 0c4h,0c1h,7dh,0feh,0c1h       // AVX2 vpaddd ymm0,ymm0,ymm9
     // сохраняем результат для вторых четырех обработанных столбцов (младшая часть регистра)
     db 0c4h,0c1h,07eh,07fh,00h       // AVX  vmovdqu [r8],ymm0
     add r8,16
     // Перемещаемся для обработки следущих восьми столбцов
     mov rcx,r11
     mov rdx,r12
     add rdx,cycle4  // 8xhiddden1
     sub r10,1
     jnz @@1
     // восстанавливаем регистры
     pop r15
     pop r14
     pop r13
     pop r12
     mov r10,r9
     db 0c4h,0c1h,07eh,06fh,2ah       // AVX  ymm5,vmovdqu [r10]
     add r10,32
     db 0c4h,0c1h,07eh,06fh,32h       // AVX  ymm6,vmovdqu [r10]
     add r10,32
     db 0c4h,0c1h,07eh,06fh,3ah       // AVX  ymm7,vmovdqu [r10]
     add r10,32
     db 0c4h,041h,07eh,06fh,02h       // AVX  ymm8,vmovdqu [r10]
     add r10,32
     db 0c4h,041h,07eh,06fh,0ah       // AVX  ymm9,vmovdqu [r10]
     add r10,32
     db 0c4h,041h,07eh,06fh,12h       // AVX  ymm9,vmovdqu [r10]
     // очищаем "верхний флаг"
     db 0c5h,0f8h,77h                 // AVX vzeroupper
end;
Procedure AVX2_RELU_2_64(Summs,Biases,limits,Res : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 1.34 for 8;
//                     rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Получая на вход строку из hidden2 выходов нейронов (int32)  + hidden2 биаса (int32) реализует RELU. Использует SIMD AVX2
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
    mov r11,cycle2                           // обрабатываем по 8 значений за раз
    // Строка нулей
    db 0c5h,0edh,0efh,0d2h                   // AVX2  vpxor ymm2,ymm2,ymm2
    // Строка лимитов для RELU
    db 0c4h,0c1h,07eh,06fh,18h              // AVX  vmovdqu ymm3,[r8]
@@1:
    //  8 int32 элементов
    db 0c5h,0feh,6fh,01h                    // AVX vmovdqu ymm0,[rcx]
    // суммируем с первыми 8 биасами
    db 0c5h,0feh,6fh,0Ah                    // AVX vmovdqu ymm1,[rdx]
    db 0c5h,0f5h,0feh,0c0h                  // AVX2 vpaddd ymm0,ymm1,ymm0
    // множитель квантования
    db 0c5h,0fdh,72h,0e0h,6                 // AVX2 vpsraw ymm0,ymm0,6      для 64
     // Делаем RELU c 0
    db 0c4h,0e2h,7dh,3dh,0c2h               // AVX2 vpmaxsd ymm0,ymm0,ymm2
    // Делаем Clipped_RELU
    db 0c4h,0e2h,7dh,39h,0c3h              // AVX2 vpminsd ymm0,ymm0,ymm3
    // Сохраняем результат
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    add rcx,32
    add rdx,32
    add r9,32
    sub r11,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_RELU_2_128(Summs,Biases,limits,Res : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 1.34 for 8;
//                     rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Получая на вход строку из hidden2 выходов нейронов (int32)  + hidden2 биаса (int32) реализует RELU. Использует SIMD AVX2
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
    mov r11,cycle2                           // обрабатываем по 8 значений за раз
    // Строка нулей
    db 0c5h,0edh,0efh,0d2h                   // AVX2  vpxor ymm2,ymm2,ymm2
    // Строка лимитов для RELU
    db 0c4h,0c1h,07eh,06fh,18h              // AVX  vmovdqu ymm3,[r8]
@@1:
    //  8 int32 элементов
    db 0c5h,0feh,6fh,01h                    // AVX vmovdqu ymm0,[rcx]
    // суммируем с первыми 8 биасами
    db 0c5h,0feh,6fh,0Ah                    // AVX vmovdqu ymm1,[rdx]
    db 0c5h,0f5h,0feh,0c0h                  // AVX2 vpaddd ymm0,ymm1,ymm0
    // множитель квантования
    db 0c5h,0fdh,72h,0e0h,7                 // AVX2 vpsraw ymm0,ymm0,7      для 128
     // Делаем RELU c 0
    db 0c4h,0e2h,7dh,3dh,0c2h               // AVX2 vpmaxsd ymm0,ymm0,ymm2
    // Делаем Clipped_RELU
    db 0c4h,0e2h,7dh,39h,0c3h              // AVX2 vpminsd ymm0,ymm0,ymm3
    // Сохраняем результат
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    add rcx,32
    add rdx,32
    add r9,32
    sub r11,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_RELU_2_256(Summs,Biases,limits,Res : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 1.34 for 8;
//                     rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Получая на вход строку из hidden2 выходов нейронов (int32)  + hidden2 биаса (int32) реализует RELU. Использует SIMD AVX2
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
    mov r11,cycle2                           // обрабатываем по 8 значений за раз
    // Строка нулей
    db 0c5h,0edh,0efh,0d2h                   // AVX2  vpxor ymm2,ymm2,ymm2
    // Строка лимитов для RELU
    db 0c4h,0c1h,07eh,06fh,18h              // AVX  vmovdqu ymm3,[r8]
@@1:
    //  8 int32 элементов
    db 0c5h,0feh,6fh,01h                    // AVX vmovdqu ymm0,[rcx]
    // суммируем с первыми 8 биасами
    db 0c5h,0feh,6fh,0Ah                    // AVX vmovdqu ymm1,[rdx]
    db 0c5h,0f5h,0feh,0c0h                  // AVX2 vpaddd ymm0,ymm1,ymm0
    // множитель квантования
    db 0c5h,0fdh,72h,0e0h,8                 // AVX2 vpsraw ymm0,ymm0,8      для 256
     // Делаем RELU c 0
    db 0c4h,0e2h,7dh,3dh,0c2h               // AVX2 vpmaxsd ymm0,ymm0,ymm2
    // Делаем Clipped_RELU
    db 0c4h,0e2h,7dh,39h,0c3h              // AVX2 vpminsd ymm0,ymm0,ymm3
    // Сохраняем результат
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    add rcx,32
    add rdx,32
    add r9,32
    sub r11,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_RELU_2_512(Summs,Biases,limits,Res : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 1.34 for 8;
//                     rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Получая на вход строку из hidden2 выходов нейронов (int32)  + hidden2 биаса (int32) реализует RELU. Использует SIMD AVX2
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
    mov r11,cycle2                           // обрабатываем по 8 значений за раз
    // Строка нулей
    db 0c5h,0edh,0efh,0d2h                   // AVX2  vpxor ymm2,ymm2,ymm2
    // Строка лимитов для RELU
    db 0c4h,0c1h,07eh,06fh,18h              // AVX  vmovdqu ymm3,[r8]
@@1:
    //  8 int32 элементов
    db 0c5h,0feh,6fh,01h                    // AVX vmovdqu ymm0,[rcx]
    // суммируем с первыми 8 биасами
    db 0c5h,0feh,6fh,0Ah                    // AVX vmovdqu ymm1,[rdx]
    db 0c5h,0f5h,0feh,0c0h                  // AVX2 vpaddd ymm0,ymm1,ymm0
    // множитель квантования
    db 0c5h,0fdh,72h,0e0h,9                 // AVX2 vpsraw ymm0,ymm0,9      для 256
     // Делаем RELU c 0
    db 0c4h,0e2h,7dh,3dh,0c2h               // AVX2 vpmaxsd ymm0,ymm0,ymm2
    // Делаем Clipped_RELU
    db 0c4h,0e2h,7dh,39h,0c3h              // AVX2 vpminsd ymm0,ymm0,ymm3
    // Сохраняем результат
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    add rcx,32
    add rdx,32
    add r9,32
    sub r11,1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_SecondLayer_Mul(inprow,Matrix,dest,store : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  //6.3 for 8x8
//                              rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Перемножает матрицу [1xhidden2] элемента  int32 на матрицу [hidden2xhidden3] элемента int32 используя SIMD AVX2
// на выходе матрица [1xhidden3] int32

asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
  // сохраняем все регистры, необходимые для корректной работы
     mov r10,r9
     db 0c4h,0c1h,07eh,07fh,2ah       // AVX  vmovdqu [r10],ymm5
     add r10,32
     db 0c4h,0c1h,07eh,07fh,32h       // AVX  vmovdqu [r10],ymm6
     add r10,32
     db 0c4h,0c1h,07eh,07fh,3ah       // AVX  vmovdqu [r10],ymm7
     add r10,32
     db 0c4h,041h,07eh,07fh,2ah       // AVX  vmovdqu [r10],ymm8

     push r12
     push r13
     push r14
     push r15

     mov r12,rcx
     mov r14,hidden2*4                  // длина вектора (расстояние между столбцами в байтах)
     mov r11,cycle5                     // цикл столбцов hidden3 по 4
@@1:
     mov rcx,r12
     // обнуляем накопители
     db 0c5h,0f5h,0efh,0c9h          // AVX2  vpxor ymm1,ymm1,ymm1
     db 0c5h,0edh,0efh,0d2h          // AVX2  vpxor ymm2,ymm2,ymm2
     db 0c5h,0e5h,0efh,0dbh          // AVX2  vpxor ymm3,ymm3,ymm3
     db 0c5h,0ddh,0efh,0e4h          // AVX2  vpxor ymm4,ymm4,ymm4
     mov r10,cycle2                  // цикл  строки hidden2 по 8
     mov r13,rdx
     mov r15,rdx

@@2:
     // читаем строку improw [1,hidden2]  8 int 32
     db 0c5h,0feh,6fh,01h               // AVX vmovdqu ymm0,[rcx]
   // В цикле обрабатываем сразу по 4 столбца

     //1 столбец
     db 0c5h,0feh,6fh,2ah               // AVX vmovdqu ymm5,[rdx]
     db 0c4h,0e2h,7dh,40h,0edh          // AVX2 vpmulld ymm5,ymm0,ymm5
     db 0c5h,0f5h,0feh,0cdh             // AVX2  vpaddd ymm1,ymm1,ymm5  - cуммируем с накопителем 1 столбца

     //2 столбец
     add rdx,r14
     db 0c5h,0feh,6fh,32h               // AVX vmovdqu ymm6,[rdx]
     db 0c4h,0e2h,7dh,40h,0f6h          // AVX2 vpmulld ymm6,ymm0,ymm6
     db 0c5h,0edh,0feh,0d6h             // AVX2  vpaddd ymm2,ymm2,ymm6  - cуммируем с накопителем 2 столбца
     //3 столбец
     add rdx,r14
     db 0c5h,0feh,6fh,3ah               // AVX vmovdqu ymm7,[rdx]
     db 0c4h,0e2h,7dh,40h,0ffh          // AVX2 vpmulld ymm7,ymm0,ymm7
     db 0c5h,0e5h,0feh,0dfh             // AVX2  vpaddd ymm3,ymm3,ymm7  - cуммируем с накопителем 3 столбца
     //4 столбец
     add rdx,r14
     db 0c5h,07eh,6fh,02h               // AVX vmovdqu ymm8,[rdx]
     db 0c4h,042h,7dh,40h,0c0h          // AVX2 vpmulld ymm8,ymm0,ymm8
     db 0c4h,0c1h,05dh,0feh,0e0h        // AVX2  vpaddd ymm4,ymm4,ymm8  - cуммируем с накопителем 4 столбца
     // крутим цикл по строке hidden 2
     add rcx,32                         // следующий кусочек строки
     mov rdx,r13
     add rdx,32                         // следующий кусочек столбцов
     mov r13,rdx
     sub r10,1
     jnz @@2
  // Мы получили векторы для 4-х столбцов. Теперь горизонтально суммируем их, чтобы в итоге получить 4 32-разрядных результата
     db 0c4h,0e2h,75h,02h,0cah          // AVX2 vphaddd ymm1,ymm1,ymm2
     db 0c4h,0e2h,65h,02h,0dch          // AVX2 vphaddd ymm3,ymm3,ymm4
     db 0c4h,0e2h,75h,02h,0cbh          // AVX2 vphaddd ymm1,ymm1,ymm3
    // Полученный вектор складываем пополам
     db 0c4h,0e3h,7dh,39h,0cah,01       // AVX2 vextracti128 xmm2,ymm1,0x1
     db 0c5h,0f5h,0feh,0cah             // AVX2 vpaddd ymm1,ymm1,ymm2
     // сохраняем результат для очередных четырех обработанных столбцов (половинку)
     db 0c4h,0c1h,7eh,7fh,08h           // AVX vmovdqu [r8],ymm1
     add r8,16
     // Перемещаемся для обработки следущих четырех столбцов
     mov rdx,r15
     add rdx,cycle10
     sub r11,1
     jnz @@1
     // восстанавливаем регистры
     pop r15
     pop r14
     pop r13
     pop r12
     mov r10,r9
     db 0c4h,0c1h,07eh,06fh,2ah       // AVX  ymm5,vmovdqu [r10]
     add r10,32
     db 0c4h,0c1h,07eh,06fh,32h       // AVX  ymm6,vmovdqu [r10]
     add r10,32
     db 0c4h,0c1h,07eh,06fh,3ah       // AVX  ymm7,vmovdqu [r10]
     add r10,32
     db 0c4h,041h,07eh,06fh,02h       // AVX  ymm8,vmovdqu [r10]
     // очищаем "верхний флаг"
     db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_RELU_3_4096(Summs,Biases,limits,Res : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 1.34 for 8;
//                     rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Получая на вход строку из hidden3 выходов нейронов (int32)  + hidden3 биаса (int32) реализует RELU. Использует SIMD AVX2
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
     mov r11,cycle9                       // счетчик длины hidden3  по 8
    // Строка нулей
    db 0c5h,0edh,0efh,0d2h                 // AVX2  vpxor ymm2,ymm2,ymm2
    // Строка лимитов для RELU
    db 0c4h,0c1h,07eh,06fh,18h             // AVX  vmovdqu ymm3,[r8]
@@1:
    //  8 int32 элементов
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
    // суммируем с первыми 8 биасами
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0
    // множитель квантования
    db 0c5h,0fdh,72h,0e0h,12               // AVX2 vpsraw ymm0,ymm0,12  - для 4096
     // Делаем RELU c 0
    db 0c4h,0e2h,7dh,3dh,0c2h              // AVX2 vpmaxsd ymm0,ymm0,ymm2
    // Делаем Clipped_RELU
    db 0c4h,0e2h,7dh,39h,0c3h              // AVX2 vpminsd ymm0,ymm0,ymm3
    // Сохраняем результат
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    // крутим цикл
    add rcx,32
    add rdx,32
    add r9,32
    sub r11,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_RELU_3_8192(Summs,Biases,limits,Res : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 1.34 for 8;
//                     rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Получая на вход строку из hidden3 выходов нейронов (int32)  + hidden3 биаса (int32) реализует RELU. Использует SIMD AVX2
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
    mov r11,cycle9                        // счетчик длины hidden3 по 8
    // Строка нулей
    db 0c5h,0edh,0efh,0d2h                 // AVX2  vpxor ymm2,ymm2,ymm2
    // Строка лимитов для RELU
    db 0c4h,0c1h,07eh,06fh,18h             // AVX  vmovdqu ymm3,[r8]
@@1:
    //  8 int32 элементов
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
    // суммируем с первыми 8 биасами
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0
    // множитель квантования
    db 0c5h,0fdh,72h,0e0h,13               // AVX2 vpsraw ymm0,ymm0,13  - для 8192
     // Делаем RELU c 0
    db 0c4h,0e2h,7dh,3dh,0c2h              // AVX2 vpmaxsd ymm0,ymm0,ymm2
    // Делаем Clipped_RELU
    db 0c4h,0e2h,7dh,39h,0c3h              // AVX2 vpminsd ymm0,ymm0,ymm3
    // Сохраняем результат
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    // крутим цикл
    add rcx,32
    add rdx,32
    add r9,32
    sub r11,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Function AVX2_NNOut(Inprow,Matrix,Ones,Bias : Pbyte):integer;{$IFDEF FPC} nostackframe assembler;{$ENDIF} //1.84 c
//                   rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Перемножает матрицу [1xhidden3] элемента  int32 на матрицу [hidden3x1] элемента int32 используя SIMD AVX2
// Дает int32 выход всей нейросети , используя bias последнего слоя.
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}
  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
     mov r11,cycle9                     // счетчик длины hidden3  по 8
     // нули для горизонтального сложения
     db 0c5h,0e5h,0efh,0dbh              // AVX2  vpxor ymm3,ymm3,ymm3
     // тут накапливаем результат
     db 0c5h,0ddh,0efh,0e4h              // AVX2  vpxor ymm4,ymm4,ymm4
@@1:

  // читаем строку improw [1,hidden3] 8 элементов
     db 0c5h,0feh,6fh,01h                // AVX vmovdqu ymm0,[rcx]
  // читаем строку матрицы [hidden3,1] 8 элементов
     db 0c5h,0feh,6fh,0Ah                // AVX vmovdqu ymm1,[rdx]
  //  перемножаем  int32
     db 0c4h,0e2h,7dh,40h,0c9h           // AVX2 vpmulld ymm1,ymm0,ymm1
     //  складываем  int32
     db 0c5h,0ddh,0feh,0e1h              // AVX2 vpaddd ymm4,ymm4,ymm1
   // крутим цикл
     add rcx,32
     add rdx,32
     sub r11,1
     jnz @@1
  // Теперь горизонтально суммируем 2 раза чтобы результат оставался в 64 младших битах 256->128->64
     db 0c4h,0e2h,5dh,02h,0e3h           // AVX2 vphaddd ymm4,ymm4,ymm3
     db 0c4h,0e2h,5dh,02h,0e3h           // AVX2 vphaddd ymm4,ymm4,ymm3
    // Полученный вектор складываем пополам
     db 0c4h,0e3h,7dh,39h,0e2h,01        // AVX2 vextracti128 xmm2,ymm4,0x1
     db 0c5h,0ddh,0feh,0cah              // AVX2 vpaddd ymm1,ymm4,ymm2
    // Результат
     movd eax,xmm1
    // Добавляем биас
     add eax,DWORD ptr [r9]
  // очищаем "верхний флаг"
     db 0c5h,0f8h,77h                   // AVX vzeroupper
end;

Procedure AVX2_CopyAcc(Source,Dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF} //7.59 for AVX2, 6.4 for AVX512
//                       rcx(rdi),  rdx(rsi)
// Копирует int16 аккумулятор за 1 цвет.  Сохраняет по адресу  DEST ( может совпадать с SOURCE)
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov rdx,rsi
     mov rcx,rdi
  {$endif}
    mov r10,cycle6                          // счетчик   AVX_16*cycle6=half
@@1:
   // читаем строку источника (16 элементов int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
    // Сохраняем обновленные данные
    db 0c5h,0feh,7fh,02h                    // AVX vmovdqu [rdx],ymm0
    // Следующие 16 int16 элементов
    add rcx,32
    add rdx,32
    // Крутим цикл
    sub r10,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_SetFeauture(Source,NetIndex,Dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 8.64 for AVX2, 8.98 for AVX512
//                          rcx(rdi),rdx(rsi),r8(rdx)
// Обновляет (устанавливает фичу) int16 аккумулятора за 1 цвет.  Сохраняет по адресу  DEST ( может совпадать с SOURCE)
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}

    mov r10,cycle6                          // счетчик   AVX_16*cycle6=half
@@1:
   // читаем строку источника (16 элементов int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // читаем строку весов (16 элементов int16)
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    // Устанавливаем (складываем)
    db 0c5h,0fdh,0fdh,0c1h                 // AVX2 vpaddw ymm0,ymm0,ymm1
    // Сохраняем обновленные данные
    db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
    // Следующие 16 int16 элементов
    add rcx,32
    add rdx,32
    add r8, 32
    // Крутим цикл
    sub r10,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;

Procedure AVX2_ReSetFeauture(Source,NetIndex,Dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF} // 8.64 for AVX2, 7.25 for AVX512
//                          rcx(rdi),rdx(rsi),r8(rdx)
// Обновляет (убирает фичу)  int16 аккумулятора за 1 цвет. Сохраняет по адресу  DEST ( может совпадать с SOURCE)
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}

    mov r10,cycle6                          // счетчик   AVX_16*cycle6=half
@@1:
   // читаем строку источника (16 элементов int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // читаем строку весов (16 элементов int16)
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    // Устанавливаем (вычитаем)
    db 0c5h,0fdh,0f9h,0c1h                 // AVX2 vpsubw ymm0,ymm0,ymm1
    // Сохраняем обновленные данные
    db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
    // Следующие 16 int16 элементов
    add rcx,32
    add rdx,32
    add r8, 32
    // Крутим цикл
    sub r10,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_DBlReSetFeauture(Source,NetIndex1,NetIndex2,Dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF} // 8.64 for AVX2, 7.25 for AVX512
//                               rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Обновляет (убирает 2 фичи)  int16 аккумулятора за 1 цвет. Сохраняет по адресу  DEST ( может совпадать с SOURCE)
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}

    mov r10,cycle6                          // счетчик   AVX_16*cycle6=half
@@1:
   // читаем строку источника (16 элементов int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // читаем строку весов1 (16 элементов int16)
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    // читаем строку весов2 (16 элементов int16)
    db 0c4h,0c1h,7eh,6fh,10h               // AVX vmovdqu ymm2,[r8]
    // Устанавливаем (вычитаем)1
    db 0c5h,0fdh,0f9h,0c1h                 // AVX2 vpsubw ymm0,ymm0,ymm1
    // Устанавливаем (вычитаем)2
    db 0c5h,0fdh,0f9h,0c2h                 // AVX2 vpsubw ymm0,ymm0,ymm2
    // Сохраняем обновленные данные
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    // Следующие 16 int16 элементов
    add rcx,32
    add rdx,32
    add r8, 32
    add r9, 32
    // Крутим цикл
    sub r10,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_UpdFeauture(Source,NetIndexAdd,NetIndexSUB,Dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}   // 10.26 for AVX2, 8.76 for AVX512
//                          rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Обновляет (добавляет + убирает фичи) половину int16 аккумулятора (за 1 цвет). На входе адрес источника половинки аккумулятора int16 и начальный адрес нужной фичи в сетке int16. Сохраняет половинку аккумулятора по адресу  DEST ( может совпадать с SOURCE)
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}

    mov r10,cycle6                          // счетчик   AVX_16*cycle6=half
@@1:
   // читаем строку источника (16 элементов int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // читаем строку весов1 (16 элементов int16)
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    // читаем строку весов2 (16 элементов int16)
    db 0c4h,0c1h,7eh,6fh,10h               // AVX vmovdqu ymm2,[r8]
    // Устанавливаем1  (складываем)
    db 0c5h,0fdh,0fdh,0c1h                 // AVX2 vpaddw ymm0,ymm0,ymm1
    // Устанавливаем2 (вычитаем)
    db 0c5h,0fdh,0f9h,0c2h                 // AVX2 vpsubw ymm0,ymm0,ymm2
    // Сохраняем обновленные данные
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    // Следующие 16 int16 элементов
    add rcx,32
    add rdx,32
    add r8, 32
    add r9, 32
    // Крутим цикл
    sub r10,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_UpdCaptureFeauture(Source,Buf,Dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}
//                               rcx(rdi),rdx(rsi),r8(rdx)
// Обновляет при взятии (добавляет + убирает фичи) половину int16 аккумулятора (за 1 цвет). Фичи хранятся в буфере. Сохраняет половинку аккумулятора по адресу  DEST ( может совпадать с SOURCE)
asm
   {$IFNDEF FPC}
    .noframe
    {$ENDIF}

    {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
   {$endif}

    // Выбираем фичи из буфера
    mov rax,[rdx]                           // адрес фичи add
    add rdx,8
    mov r9,[rdx]                            // адрес фичи sub1
    add rdx,8
    mov r10,[rdx]                           // адрес фичи sub2
    mov rdx,cycle6                          // счетчик   AVX_16*cycle6=half
@@1:
    // читаем строку источника (16 элементов int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // читаем строку весов1 (16 элементов int16)
    db 0c5h,0feh,6fh,08h                   // AVX vmovdqu ymm1,[rax]
    // читаем строку весов2 (16 элементов int16)
    db 0c4h,0c1h,7eh,6fh,11h               // AVX vmovdqu ymm2,[r9]
    // читаем строку весов3 (16 элементов int16)
    db 0c4h,0c1h,7eh,6fh,1Ah               // AVX vmovdqu ymm3,[r10]
    // Устанавливаем1  (складываем)
    db 0c5h,0fdh,0fdh,0c1h                 // AVX2 vpaddw ymm0,ymm0,ymm1
    // Устанавливаем2 (вычитаем)
    db 0c5h,0fdh,0f9h,0c2h                 // AVX2 vpsubw ymm0,ymm0,ymm2
    // Устанавливаем3 (вычитаем)
    db 0c5h,0fdh,0f9h,0c3h                 // AVX2 vpsubw ymm0,ymm0,ymm3
    // Сохраняем обновленные данные
    db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
    // Следующие 16 int16 элементов
    add rcx,32
    add rax,32
    add r8, 32
    add r9, 32
    add r10,32
    // Крутим цикл
    sub rdx,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;

Procedure AVX2_UpdCastleFeauture(Source,Buf,Dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}
//                               rcx(rdi),rdx(rsi),r8(rdx)
// Обновляет при взятии (добавляет + убирает фичи) половину int16 аккумулятора (за 1 цвет). Фичи хранятся в буфере. Сохраняет половинку аккумулятора по адресу  DEST ( может совпадать с SOURCE)
asm
   {$IFNDEF FPC}
    .noframe
    {$ENDIF}

    {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
   {$endif}

    // Выбираем фичи из буфера
    mov rax,[rdx]                           // адрес фичи add
    add rdx,8
    mov r9,[rdx]                            // адрес фичи sub1
    add rdx,8
    mov r10,[rdx]                           // адрес фичи sub2
    add rdx,8
    mov r11,[rdx]                           // адрес фичи add2
    mov rdx,cycle6                          // счетчик   AVX_16*cycle6=half
@@1:
    // читаем строку источника (16 элементов int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // читаем строку весов1 (16 элементов int16)
    db 0c5h,0feh,6fh,08h                   // AVX vmovdqu ymm1,[rax]
    // читаем строку весов2 (16 элементов int16)
    db 0c4h,0c1h,7eh,6fh,11h               // AVX vmovdqu ymm2,[r9]
    // читаем строку весов3 (16 элементов int16)
    db 0c4h,0c1h,7eh,6fh,1Ah               // AVX vmovdqu ymm3,[r10]
    // читаем строку весов4 (16 элементов int16)
    db 0c4h,0c1h,7eh,6fh,23h               // AVX vmovdqu ymm4,[r11]
    // Устанавливаем1  (складываем)
    db 0c5h,0fdh,0fdh,0c1h                 // AVX2 vpaddw ymm0,ymm0,ymm1
    // Устанавливаем2 (вычитаем)
    db 0c5h,0fdh,0f9h,0c2h                 // AVX2 vpsubw ymm0,ymm0,ymm2
    // Устанавливаем3 (вычитаем)
    db 0c5h,0fdh,0f9h,0c3h                 // AVX2 vpsubw ymm0,ymm0,ymm3
    // Устанавливаем4  (складываем)
    db 0c5h,0fdh,0fdh,0c4h                 // AVX2 vpaddw ymm0,ymm0,ymm4
    // Сохраняем обновленные данные
    db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
    // Следующие 16 int16 элементов
    add rcx,32
    add rax,32
    add r8, 32
    add r9, 32
    add r10,32
    add r11,32
    // Крутим цикл
    sub rdx,1
    jnz @@1
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_UpdBufFeauture(acc,cnt,Buf,Flayer_Bias : Pbyte); {$IFDEF FPC} nostackframe assembler;{$ENDIF}
//                           rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
// Добавялет фичи в аккумулятор из списка
asm
    {$IFNDEF FPC}
    .noframe
    {$ENDIF}

    {$ifdef UNIX}
     mov r9,rcx
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
   {$endif}

    push r8
    // сохраняем все регистры, необходимые для корректной работы Windows
    mov r10,[r8]                           //  В нулевой ячейке - store adress
    add r8,8                               //  1-я фича
    db 0c4h,0c1h,07eh,07fh,2ah             // AVX  vmovdqu [r10],ymm5
    add r10,32
    db 0c4h,0c1h,07eh,07fh,32h             // AVX  vmovdqu [r10],ymm6
    add r10,32
    db 0c4h,0c1h,07eh,07fh,3ah             // AVX  vmovdqu [r10],ymm7
    add r10,32
    db 0c4h,041h,07eh,07fh,2ah             // AVX  vmovdqu [r10],ymm8
    push r12
    push r13
    push r14
    mov r10,cycle8                         // счетчик   AVX_16*8*cycle8=half
    mov r12,0                              // первый кусочек имеет смещение 0
    mov r13,rcx
    mov r14,r8
    mov rcx,r9;
@@1:
    // Кешируем bias Flayer в 8 регистрах  (128 16-битных ячеек )
    db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
    add rcx,32
    db 0c5h,0feh,6fh,11h                   // AVX vmovdqu ymm2,[rcx]
    add rcx,32
    db 0c5h,0feh,6fh,19h                   // AVX vmovdqu ymm3,[rcx]
    add rcx,32
    db 0c5h,0feh,6fh,21h                   // AVX vmovdqu ymm4,[rcx]
    add rcx,32
    db 0c5h,0feh,6fh,29h                   // AVX vmovdqu ymm5,[rcx]
    add rcx,32
    db 0c5h,0feh,6fh,31h                   // AVX vmovdqu ymm6,[rcx]
    add rcx,32
    db 0c5h,0feh,6fh,39h                   // AVX vmovdqu ymm7,[rcx]
    add rcx,32
    db 0c5h,07eh,6fh,01h                   // AVX vmovdqu ymm8,[rcx]
    add rcx,32
    // Прогоняем все фичи из буфера по кусочку аккумулятора
    mov r11,[rdx]                          // количество фич в буфере
@@2:
    mov rax,[r8]
    add rax,r12
    // 1 регистр
    db 0c5h,0feh,6fh,00h                   // AVX vmovdqu ymm0,[rax]
    db 0c5h,0fdh,0fdh,0c9h                 // AVX2 vpaddw ymm1,ymm0,ymm1
    add rax,32
    // 2 регистр
    db 0c5h,0feh,6fh,00h                   // AVX vmovdqu ymm0,[rax]
    db 0c5h,0fdh,0fdh,0d2h                 // AVX2 vpaddw ymm2,ymm0,ymm2
    add rax,32
    // 3 регистр
    db 0c5h,0feh,6fh,00h                   // AVX vmovdqu ymm0,[rax]
    db 0c5h,0fdh,0fdh,0dbh                 // AVX2 vpaddw ymm3,ymm0,ymm3
    add rax,32
    // 4 регистр
    db 0c5h,0feh,6fh,00h                   // AVX vmovdqu ymm0,[rax]
    db 0c5h,0fdh,0fdh,0e4h                 // AVX2 vpaddw ymm4,ymm0,ymm4
    add rax,32
    // 5 регистр
    db 0c5h,0feh,6fh,00h                   // AVX vmovdqu ymm0,[rax]
    db 0c5h,0fdh,0fdh,0edh                 // AVX2 vpaddw ymm5,ymm0,ymm5
    add rax,32
    // 6 регистр
    db 0c5h,0feh,6fh,00h                   // AVX vmovdqu ymm0,[rax]
    db 0c5h,0fdh,0fdh,0f6h                 // AVX2 vpaddw ymm6,ymm0,ymm6
    add rax,32
    // 7 регистр
    db 0c5h,0feh,6fh,00h                   // AVX vmovdqu ymm0,[rax]
    db 0c5h,0fdh,0fdh,0ffh                 // AVX2 vpaddw ymm7,ymm0,ymm7
    add rax,32
    // 8 регистр
    db 0c5h,0feh,6fh,00h                   // AVX vmovdqu ymm0,[rax]
    db 0c4h,41h,07dh,0fdh,0c0h             // AVX2 vpaddw ymm8,ymm0,ymm8
    add r8,8                               // следующая фича
    sub r11,1
    jnz @@2
    // сохраняем обработанный кусочек аккумулятора
    db 0c4h,0c1h,07eh,7fh,4dh,00h          // AVX [r13],vmovdqu ymm1
    add r13,32
    db 0c4h,0c1h,07eh,7fh,55h,00h          // AVX [r13],vmovdqu ymm2
    add r13,32
    db 0c4h,0c1h,07eh,7fh,5dh,00h          // AVX [r13],vmovdqu ymm3
    add r13,32
    db 0c4h,0c1h,07eh,7fh,65h,00h          // AVX [r13],vmovdqu ymm4
    add r13,32
    db 0c4h,0c1h,07eh,7fh,6dh,00h          // AVX [r13],vmovdqu ymm5
    add r13,32
    db 0c4h,0c1h,07eh,7fh,75h,00h          // AVX [r13],vmovdqu ymm6
    add r13,32
    db 0c4h,0c1h,07eh,7fh,7dh,00h          // AVX [r13],vmovdqu ymm7
    add r13,32
    db 0c4h,041h,07eh,7fh,45h,00h          // AVX [r13],vmovdqu ymm8
    add r13,32
    mov r8,r14
    add r12,256                            // смещение для следующего кусочка фичи
    sub r10,1
    jnz @@1
    // Восстанавливаем регистры
    pop r14
    pop r13
    pop r12
    pop r8
    mov r10,[r8]
    db 0c4h,0c1h,07eh,06fh,2ah             // AVX  ymm5,vmovdqu [r10]
    add r10,32
    db 0c4h,0c1h,07eh,06fh,32h             // AVX  ymm6,vmovdqu [r10]
    add r10,32
    db 0c4h,0c1h,07eh,06fh,3ah             // AVX  ymm7,vmovdqu [r10]
    add r10,32
    db 0c4h,041h,07eh,06fh,02h             // AVX  ymm8,vmovdqu [r10]
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;


Function ForwardPass(SideToMove:integer;var Pass:TForwardPass):integer;
// Проход по нейросети. На входе загруженная сеть, очередь хода и структура аккумулятора, на выходе - Оценка позции

begin

  //в зависимости от очереди хода расставляем аккумуляторы в нужном порядке

  {$IFDEF AddLayer}
    AVX2_RELU_ACC(@Pass.Acc16[SideToMove],@permut1,@Pass.Inputsadd8);
    AVX2_RELU_ACC(@Pass.Acc16[SideToMove xor 1],@permut1,@Pass.Inputsadd8[half]);
    // ADD stm
    AVX2_ADDLayer(@Pass.Inputsadd8,@Pass.Inputsadd8[quarter],@Pass.Inputs8);
    // ADD nonstm
    AVX2_ADDLayer(@Pass.Inputsadd8[half],@Pass.Inputsadd8[half+quarter],@Pass.Inputs8[quarter]);
  {$ENDIF}
  {$IFNDEF AddLayer}
    AVX2_RELU_ACC(@Pass.Acc16[SideToMove],@permut1,@Pass.Inputs8);
    AVX2_RELU_ACC(@Pass.Acc16[SideToMove xor 1],@permut1,@Pass.Inputs8[half]);
  {$ENDIF}
  //1
  AVX2_FirstLayer_Mul(@Pass.Inputs8,@Pass.Net.FirstLayer,@Pass.TempFirst,@Pass.store);

  case Pass.Net.w1 of
    64 : AVX2_RELU_2_64 (@Pass.TempFirst,@Pass.Net.biasFirst,@RELUlimit,@Pass.RELUFirst);
   128 : AVX2_RELU_2_128(@Pass.TempFirst,@Pass.Net.biasFirst,@RELUlimit,@Pass.RELUFirst);
   256 : AVX2_RELU_2_256(@Pass.TempFirst,@Pass.Net.biasFirst,@RELUlimit,@Pass.RELUFirst);
   512 : AVX2_RELU_2_512(@Pass.TempFirst,@Pass.Net.biasFirst,@RELUlimit,@Pass.RELUFirst);
  end;

  //2
  AVX2_SecondLayer_Mul(@Pass.RELUFirst,@Pass.Net.SecondLayer,@Pass.TempSecond,@Pass.store);

  if Pass.Net.w2=4096
    then AVX2_RELU_3_4096(@Pass.TempSecond,@Pass.Net.biasSecond,@RELUlimit,@Pass.RELUSecond)
    else AVX2_RELU_3_8192(@Pass.TempSecond,@Pass.Net.biasSecond,@RELUlimit,@Pass.RELUSecond);

  // output
  Result:=AVX2_NNOut(@Pass.RELUSecond,@Pass.Net.outlayer,@Ones512,@Pass.Net.outbias);
end;

Function loadnet(name:shortstring;var CurrNet:TNeuralNetWeights):boolean;
var
  res,size,i,j : integer;
  ver,w   : int16;
  f: TResourceStream;
begin
  // Открываем файл и проверяем верисю нейросети
  f := TResourceStream.Create(HInstance,name,RT_RCDATA);
  w:=0;ver:=0;
  Result:=false;
  res:=f.Read(ver,2); // 16-бит целочисленное
  if res<>2 then
    begin
      Writeln('Cant read a version byte!');
      exit;
    end;
  if ver<>current_version then
    begin
     writeln('Wrong version of NeuralNet or incorrect file!');
     writeln(ver,'-',current_version);
     exit;
    end;
  // Считываем константу scale_act - она зависит от процесса обучения и может от версии к версии меняться.
  CurrNet.scale_act:=0;
  res:=f.Read(w,2);  // 16 бит целочисленное  = scale_act*100
  if res<>2 then
    begin
      Writeln('Cant read a scale_act byte!');
      exit;
    end;
  CurrNet.scale_act:=w/100; // может быть и дробным
  // Считываем константу scale_out - она зависит от процесса обучения и может от версии к версии меняться.
  CurrNet.scale_out:=0;
  res:=f.Read(w,2);  // 16 бит целочисленное
  if res<>2 then
    begin
      Writeln('Cant read a scale_out byte!');
      exit;
    end;
  CurrNet.scale_out:=w;
  // Считываем номер модели нейросети
   res:=f.Read(CurrNet.model,2);
   if res<>2 then
    begin
     Writeln('Cant read a model number!');
     exit;
    end;
  CurrNet.ModelSize:=ModelFrameSize(CurrNet.model);
  // Считываем константу w1 - она зависит от процесса обучения и может от версии к версии меняться.
  res:=f.Read(w,2);  // 16 бит целочисленное
  if res<>2 then
    begin
      Writeln('Cant read a w1 byte!');
      exit;
    end;
  CurrNet.w1:=w;
   // Считываем константу w2 - она зависит от процесса обучения и может от версии к версии меняться.
  res:=f.Read(w,2);  // 16 бит целочисленное
  if res<>2 then
    begin
      Writeln('Cant read a w2 byte!');
      exit;
    end;
  CurrNet.w2:=w;
  // считываем сеть в память
  size:=CurrNet.ModelSize;
  if size=0 then
    begin
      Writeln('Unknown model!');
      exit;
    end;
  size:=size*half*2; // Размер считываемых байтов весов Flayer (int16=2 байта)
  // Считываем Flayer weights int16
  res:=f.Read(CurrNet.Flayer,size);
  if res<>size then
    begin
     Writeln('Cant read Flayer weights!');
     exit;
    end;

  // Считываем FirstLayer weights int8
  res:=f.Read(CurrNet.FirstLayer,hidden1*hidden2);
  if res<>hidden1*hidden2 then
    begin
     Writeln('Cant read a FirstLayer weights!');
     exit;
    end;
  // Считываем SecondLayer weights integer
  res:=f.Read(CurrNet.SecondLayer,hidden2*hidden3*4); // int32=4 байта
  if res<>hidden2*hidden3*4 then
    begin
     Writeln('Cant read a SecondLayer weights!');
     exit;
    end;
  // Считываем OutLayer weights integer
  res:=f.Read(CurrNet.outlayer,hidden3*4); // int32=4 байта
  if res<>hidden3*4 then
    begin
     Writeln('Cant read a OutLayer weights!');
     exit;
    end;
  // Считываем Flayer biases int16
  res:=f.Read(CurrNet.Fbias,half*2); // (int16=2 байта)
  if res<>half*2 then
    begin
     Writeln('Cant read a Flayer biases!');
     exit;
    end;
  // Считываем FirstLayer biases int32
  res:=f.Read(CurrNet.biasFirst,4*hidden2);
  if res<>4*hidden2 then
    begin
     Writeln('Cant read a FirstLayer biases!');
     exit;
    end;
  // Считываем SecondLayer biases int32
  res:=f.Read(CurrNet.biasSecond,4*hidden3);
  if res<>4*hidden3 then
    begin
     Writeln('Cant read a SecondLayer biases!');
     exit;
    end;
  // Считываем OutLayer biases int32
  res:=f.Read(CurrNet.outbias,4);
  if res<>4 then
    begin
     Writeln('Cant read a OutLayer biases!');
     exit;
    end;
  // Заполняем таблицу сигм для быстрого их потом вычисления
  j:=round(CurrNet.scale_act*CurrNet.scale_out);
  Setlength(CurrNet.Sigma,0);
  Setlength(CurrNet.Sigma,j+1);
  CurrNet.MaxSigma:=j;
  for i:=0 to j do
      CurrNet.Sigma[i]:=ReSigma((i/CurrNet.scale_out)/CurrNet.scale_act);
  f.Free;
  {writeln('NET Version : ',ver);
  writeln('Scale_act = ',CurrNet.scale_act:6:2);
  writeln('w1 = ',CurrNet.w1);
  writeln('w2 = ',CurrNet.w2);
  writeln('Scale_out = ',CurrNet.scale_out);
  writeln('Model : ',CurrNet.model); }

  Result:=True
end;

Function GetBlockIndex(Piese:integer;sq:integer;mirror:integer):integer;
// Вычисляет индекс положения фигуры на доске. На входе - фигура любого цвета и поле, которое она занимает, на выходе - индекс внутри блока
var
   res:integer;
begin
  if mirror=1
    then Res:=PieseBlock[Piese]+sq
    else res:=PieseBlock[piese]+HMirror[sq];
  Result:=res;
end;

Procedure SetPiesesWhiteAcc(WhiteFrameStartIndex:integer;Piese:integer;var Board:TBoard;var buf:TBuf;var cnt:int64;CurrNet:PNeuralNet;Whitemirror:integer);
// Устанавливает фичи фигур выбранного типа (любого  цвета) в белый акумулятор. На входе - начальный адрес белого фрейма в который устанавливаются фигуры
var
  Temp : int64;
  Whiteindex,sq,p : integer;
begin
  Temp:=Board.Pieses[Piese];
  While Temp<>0 do
    begin
      sq:=BitScanForward(Temp);
      Temp:=Temp and (Temp-1);
      If (Board.Occupancy[white] and Only[sq])<>0
        then p:=Piese
        else p:=-Piese;
      Whiteindex:=(WhiteFrameStartIndex+GetBlockIndex(P,sq,Whitemirror))*half;
      inc(cnt);
      buf[cnt]:=@CurrNet.Flayer[WhiteIndex];
    end;
end;
Procedure SetPiesesBlackAcc(BlackFrameStartIndex:integer;Piese:integer;var Board:TBoard;var buf:TBuf;var cnt:int64;CurrNet:PNeuralNet;Blackmirror:integer);
// Устанавливает фичи фигур выбранного типа (любого  цвета) в черный акумулятор. На входе - начальный адрес черного фрейма в который устанавливаются фигуры
var
  Temp : int64;
  Blackindex,sq,p : integer;
begin
  Temp:=Board.Pieses[Piese];
  While Temp<>0 do
    begin
      sq:=BitScanForward(Temp);
      Temp:=Temp and (Temp-1);
      If (Board.Occupancy[white] and Only[sq])<>0
        then p:=Piese
        else p:=-Piese;
      Blackindex:=(BlackFrameStartIndex+GetBlockIndex(-P,sq xor 56,Blackmirror))*half;
      inc(cnt);
      buf[cnt]:=@CurrNet.Flayer[BlackIndex];
    end;
end;
Function GetWhiteFrameIndex(model:integer;var Board:TBoard):integer;
// В зависимости от выбранной модели нейросети и положения на доске возвращает начальный индекс белого фрейма.
var
  res:integer;
begin
  res:=0;                                                                          // Zero
  if model=1 then res:=SelectFlank(Board.KingSq[white],false)*ModelBlockSize else  // Flank
  if model=2 then res:=EdgeBlock[Board.KingSq[white]] else                         // Edge
  if model=3 then res:=SelectFlank(Board.KingSq[white],true)*ModelBlockSize else   // FlankExt
  if model=4 then res:=Posx[Board.KingSq[white]]*ModelBlockSize else               // File
  if model=5 then res:=K10Block[Board.KingSq[white]] else                          // K10 Model
  if model=6 then res:=K12Block[Board.KingSq[white]] else                          // K12 Model
  if model=7 then res:=K14Block[Board.KingSq[white]] else                          // K14 Model
  if model=8 then res:=K16Block[Board.KingSq[white]];                              // K16 Model
  Result:=res;
end;
Function GetWhiteKingMirror(model:integer;var Board:TBoard):integer;
var
  res : integer;
begin
  res:=1;
  if isHmirror[model] then res:=KingMirror[Board.KingSq[white]];
  Result:=res;
end;
Function GetBlackKingMirror(model:integer;var Board:TBoard):integer;
var
  res : integer;
begin
  res:=1;
  if isHmirror[model] then res:=KingMirror[Board.KingSq[black] xor 56];
  Result:=res;
end;
Function GetBlackFrameIndex(model:integer;var Board:TBoard):integer;
// В зависимости от выбранной модели нейросети и положения на доске возвращает начальный индекс черного фрейма.
var
  res:integer;
begin
  res:=0;                                                                                  // Zero
  if model=1 then res:=SelectFlank(Board.KingSq[black] xor 56,false)*ModelBlockSize else   // Flank
  if model=2 then res:=EdgeBlock[Board.KingSq[black] xor 56] else                          // Edge
  if model=3 then res:=SelectFlank(Board.KingSq[black] xor 56,true)*ModelBlockSize else    // FlankExt
  if model=4 then res:=Posx[Board.KingSq[black] xor 56]*ModelBlockSize else                // File
  if model=5 then res:=K10Block[Board.KingSq[black] xor 56] else                           // K10 Model
  if model=6 then res:=K12Block[Board.KingSq[black] xor 56] else                           // K12 Model
  if model=7 then res:=K14Block[Board.KingSq[black] xor 56] else                           // K14 Model
  if model=8 then res:=K16Block[Board.KingSq[black] xor 56];                               // K16 Model
  Result:=res;
end;
Procedure FillWhiteAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
// Заполняет структуру белого аккумулятора  по позиции на доске
var
  WhiteFrameStartIndex,WhiteMirror,NetIndex : integer;
  cnt : int64;   // Чтобы поместиться полностью в регистр
  cr : Tbuf;
  CurrNet:PNeuralNet;
begin
  // Блок выбора нужной нейросети
  NetIndex:=ChooseNNIndex(Board);
  CurrNet:=@Nets[NetIndex];
  Pass.Net:=CurrNet;
  WhiteFrameStartIndex:=GetWhiteFrameIndex(model,Board);
  WhiteMirror:=GetWhiteKingMirror(model,Board);
  cr[0]:=@Pass.store;
  // Устанавливаем королей
  cr[1]:=@CurrNet.Flayer[(WhiteFrameStartIndex+GetBlockIndex(King,Board.KingSq[white],WhiteMirror))*half];
  cr[2]:=@CurrNet.Flayer[(WhiteFrameStartIndex+GetBlockIndex(-King,Board.KingSq[black],WhiteMirror))*half];
  cnt:=2;
  //  Теперь устанавливаем фигуры
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Queen,Board,cr,cnt,CurrNet,WhiteMirror);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Rook,Board,cr,cnt,CurrNet,WhiteMirror);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Bishop,Board,cr,cnt,CurrNet,WhiteMirror);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Knight,Board,cr,cnt,CurrNet,WhiteMirror);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Pawn,Board,cr,cnt,CurrNet,WhiteMirror);
  // Устанавливаем рокировки
  If (Board.CastleRights and 1)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@CurrNet.Flayer[(WhiteFrameStartIndex+WShortCastle)*half];
    end;
  If (Board.CastleRights and 2)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@CurrNet.Flayer[(WhiteFrameStartIndex+WLongCastle)*half];
    end;
  If (Board.CastleRights and 4)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@CurrNet.Flayer[(WhiteFrameStartIndex+BShortCastle)*half];
    end;
  If (Board.CastleRights and 8)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@CurrNet.Flayer[(WhiteFrameStartIndex+BlongCastle)*half];
    end;
  AVX2_UpdBufFeauture(@Pass.Acc16[white],@cnt,@cr,@CurrNet.Fbias);
end;
Procedure FillBlackAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
// Заполняет структуру черного аккумулятора  по позиции на доске
var
  BlackFrameStartIndex,BlackMirror,NetIndex : integer;
  cnt : int64;
  cr : Tbuf;
  CurrNet:PNeuralNet;
begin
  // Блок выбора нужной нейросети
  NetIndex:=ChooseNNIndex(Board);
  CurrNet:=@Nets[NetIndex];
  Pass.Net:=CurrNet;
  BlackFrameStartIndex:=GetBlackFrameIndex(model,Board);
  BlackMirror:=GetBlackKingMirror(model,Board);
  cr[0]:=@Pass.store;
  // Устанавливаем королей
  cr[1]:=@CurrNet.Flayer[(BlackFrameStartIndex+GetBlockIndex(-King,(Board.KingSq[white] xor 56),BlackMirror))*half];
  cr[2]:=@CurrNet.Flayer[(BlackFrameStartIndex+GetBlockIndex(King,(Board.KingSq[black] xor 56),BlackMirror))*half];
  cnt:=2;
  //  Теперь устанавливаем фигуры
  SetPiesesBlackAcc(BlackFrameStartIndex,Queen,Board,cr,cnt,CurrNet,BlackMirror);
  SetPiesesBlackAcc(BlackFrameStartIndex,Rook,Board,cr,cnt,CurrNet,BlackMirror);
  SetPiesesBlackAcc(BlackFrameStartIndex,Bishop,Board,cr,cnt,CurrNet,BlackMirror);
  SetPiesesBlackAcc(BlackFrameStartIndex,Knight,Board,cr,cnt,CurrNet,BlackMirror);
  SetPiesesBlackAcc(BlackFrameStartIndex,Pawn,Board,cr,cnt,CurrNet,BlackMirror);
   //Устанавливаем рокировки
  If (Board.CastleRights and 1)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@CurrNet.Flayer[(BlackFrameStartIndex+BShortCastle)*half];
    end;
  If (Board.CastleRights and 2)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@CurrNet.Flayer[(BlackFrameStartIndex+BLongCastle)*half];
    end;
  If (Board.CastleRights and 4)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@CurrNet.Flayer[(BlackFrameStartIndex+WShortCastle)*half];
    end;
  If (Board.CastleRights and 8)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@CurrNet.Flayer[(BlackFrameStartIndex+WlongCastle)*half];
    end;
  AVX2_UpdBufFeauture(@Pass.Acc16[black],@cnt,@cr,@CurrNet.Fbias);
end;

Procedure CopyAcc16(var OldPass:TForwardPass;var NewPass:TForwardPass);
begin
  AVX2_CopyAcc(@OldPass.Acc16[white],@NewPass.Acc16[white]);
  AVX2_CopyAcc(@OldPass.Acc16[black],@NewPass.Acc16[black]);
  NewPass.Net:=OldPass.Net;
end;

Procedure UpdAcc16(move:integer;var Board:Tboard;var Undo:Tundo;var OldPass:TForwardPass;var NewPass:TForwardPass);
// Обновляем аккумуляторы. Единая процедура для обновления обоих аккумуляторов.
var
   Piese,FromPiese,from,dest,capsq,rookfrom,rookdest,myrook,stm,WhiteFrameStartIndex,BlackFrameStartIndex,WhiteMirror,BlackMirror,NetIndex,cnt : integer;
   cr:Tbuf4;
begin
  //inc(bb);
  NetIndex:=ChooseNNIndex(Board);
  if (NetIndex<>Undo.NetIndex) then
    begin
      FillWhiteAcc16(Nets[NetIndex].model,Board,NewPass);
      FillBlackAcc16(Nets[NetIndex].model,Board,NewPass);
      exit;
    end;
  NewPass.Net:=@Nets[NetIndex];
  from:=move and 63;
  dest:=(move shr 6) and 63;
  Piese:=Board.Pos[dest];       // Процедура должна вызывать ПОСЛЕ MakeMove
  stm:=Board.SideToMove xor 1;  // Процедура должна вызывать ПОСЛЕ MakeMove
  // Если Ход - превращение пешки (как вараинт - со взятием, взятие отрабатывается позже)
  if (move and PromoteFlag)<>0 then
    begin
      if stm=white
        then FromPiese:=Pawn
        else FromPiese:=-Pawn;
    end else FromPiese:=Piese;
  
  // Обновляем белый аккумулятор
  WhiteFrameStartIndex:=GetWhiteFrameIndex(Nets[NetIndex].model,Board);
  WhiteMirror:=GetWhiteKingMirror(Nets[NetIndex].model,Board);
  If (WhiteFrameStartIndex<>Undo.WFrame) or (WhiteMirror<>undo.Wmirror) then FillWhiteAcc16(Nets[NetIndex].model,Board,NewPass)  else     // Пересчитываем весь аккумулятор с нуля если изменился индекс фрейма
    begin
      // Переставляем ходившую фигуру
      cr[0]:=@OldPass.Net.Flayer[(WhiteFrameStartIndex+GetBlockIndex(Piese,dest,WhiteMirror))*half];
      cr[1]:=@OldPass.Net.Flayer[(WhiteFrameStartIndex+GetBlockIndex(Frompiese,from,WhiteMirror))*half];
      // Если была рокировка, то делаем второй виртуальных ход - перемещаем ладью
      if Undo.isCastle then
        begin
          If dest-from=2 then
            begin
             rookdest:=dest-1;
             rookfrom:=rookdest+2;
            end else
            begin
             rookdest:=dest+1;
             rookfrom:=rookdest-3;
            end;
          Myrook:=Board.Pos[rookdest];
          cr[3]:=@OldPass.Net.Flayer[(WhiteFrameStartIndex+GetBlockIndex(MyRook,rookdest,WhiteMirror))*half];
          cr[2]:=@OldPass.Net.Flayer[(WhiteFrameStartIndex+GetBlockIndex(MyRook,rookfrom,WhiteMirror))*half];
          AVX2_UPdCastleFeauture(@OldPass.Acc16[white],@cr,@NewPass.Acc16[white]);
        end else
      // Если было взятие (в том числе на проходе) - убираем побитую фигуру
      if ((move and CaptureFlag)<>0) then
        begin
          capsq:=dest;
          If Undo.isEnnPass then capsq:=capsq-PawnPush[stm];
          cr[2]:=@OldPass.Net.Flayer[(WhiteFrameStartIndex+GetBlockIndex(Board.CapturedPiese,capsq,WhiteMirror))*half];
          AVX2_UpdCaptureFeauture(@OldPass.Acc16[white],@cr,@NewPass.Acc16[white]);
        end else AVX2_UPdFeauture(@OldPass.Acc16[white],cr[0],cr[1],@NewPass.Acc16[white]);
      // Если в результате хода поменялись права на рокировку (какая-то из сторон потеряла их) - обновляем
      if Undo.CastleRights<>Board.CastleRights then
        begin
          cnt:=0;
          if (Undo.CastleRights and 1)<>(Board.CastleRights and 1) then
            begin
              cr[cnt]:=@NewPass.Net.Flayer[(WhiteFrameStartIndex+WShortCastle)*half];
              inc(cnt);
            end;
          if (Undo.CastleRights and 2)<>(Board.CastleRights and 2) then
            begin
              cr[cnt]:=@NewPass.Net.Flayer[(WhiteFrameStartIndex+WLongCastle)*half];
              inc(cnt);
            end;
          if (Undo.CastleRights and 4)<>(Board.CastleRights and 4) then
            begin
             cr[cnt]:=@NewPass.Net.Flayer[(WhiteFrameStartIndex+BShortCastle)*half];
             inc(cnt);
            end;
          if (Undo.CastleRights and 8)<>(Board.CastleRights and 8) then
            begin
             cr[cnt]:=@NewPass.Net.Flayer[(WhiteFrameStartIndex+BLongCastle)*half];
             inc(cnt);
            end;
          if cnt=1 then AVX2_ReSetFeauture(@NewPass.Acc16[white],cr[0],@NewPass.Acc16[white]) else
          if cnt=2 then AVX2_DBLReSetFeauture(@NewPass.Acc16[white],cr[0],cr[1],@NewPass.Acc16[white]) else
          if cnt=3 then begin
                          AVX2_DBLReSetFeauture(@NewPass.Acc16[white],cr[0],cr[1],@NewPass.Acc16[white]);
                          AVX2_ReSetFeauture(@NewPass.Acc16[white],cr[2],@NewPass.Acc16[white])
                        end
                   else begin
                          AVX2_DBLReSetFeauture(@NewPass.Acc16[white],cr[0],cr[1],@NewPass.Acc16[white]);
                          AVX2_DBLReSetFeauture(@NewPass.Acc16[white],cr[2],cr[3],@NewPass.Acc16[white]);
                        end;

        end;
    end;
// Обновляем черный аккумулятор
  BlackFrameStartIndex:=GetBlackFrameIndex(Nets[NetIndex].model,Board);
  BlackMirror:=GetBlackKingMirror(Nets[NetIndex].model,Board);
  If (BlackFrameStartIndex<>Undo.BFrame) or (BlackMirror<>undo.Bmirror) then FillBlackAcc16(Nets[NetIndex].model,Board,NewPass) else     // Пересчитываем весь аккумулятор с нуля если изменился индекс фрейма
    begin
      // Переставляем ходившую фигуру
      cr[0]:=@OldPass.Net.Flayer[(BlackFrameStartIndex+GetBlockIndex(-Piese,dest xor 56,Blackmirror))*half];
      cr[1]:=@OldPass.Net.Flayer[(BlackFrameStartIndex+GetBlockIndex(-Frompiese,from xor 56,Blackmirror))*half];
      // Если была рокировка, то делаем второй виртуальных ход - перемещаем ладью
      if Undo.isCastle then
        begin
          If dest-from=2 then
            begin
             rookdest:=dest-1;
             rookfrom:=rookdest+2;
            end else
            begin
             rookdest:=dest+1;
             rookfrom:=rookdest-3;
            end;
          MyRook:=Board.Pos[rookdest];
          cr[3]:=@OldPass.Net.Flayer[(BlackFrameStartIndex+GetBlockIndex(-MyRook,rookdest xor 56,Blackmirror))*half];
          cr[2]:=@OldPass.Net.Flayer[(BlackFrameStartIndex+GetBlockIndex(-MyRook,rookfrom xor 56,Blackmirror))*half];
          AVX2_UPdCastleFeauture(@OldPass.Acc16[black],@cr,@NewPass.Acc16[black]);
        end else
      // Если было взятие (в том числе на проходе) - убираем побитую фигуру
      if ((move and CaptureFlag)<>0) then
        begin
          capsq:=dest;
          If Undo.isEnnPass then capsq:=capsq-PawnPush[stm];
          cr[2]:=@OldPass.Net.Flayer[(BlackFrameStartIndex+GetBlockIndex(-Board.CapturedPiese,capsq xor 56,Blackmirror))*half];
          AVX2_UPdCaptureFeauture(@OldPass.Acc16[black],@cr,@NewPass.Acc16[black]);
        end else AVX2_UPdFeauture(@OldPass.Acc16[black],cr[0],cr[1],@NewPass.Acc16[black]);
      // Если в результате хода поменялись права на рокировку (какая-то из сторон потеряла их) - обновляем
      if Undo.CastleRights<>Board.CastleRights then
        begin
          cnt:=0;
          if (Undo.CastleRights and 1)<>(Board.CastleRights and 1) then
            begin
              cr[cnt]:=@NewPass.Net.Flayer[(BlackFrameStartIndex+BShortCastle)*half];
              inc(cnt);
            end;
          if (Undo.CastleRights and 2)<>(Board.CastleRights and 2) then
            begin
              cr[cnt]:=@NewPass.Net.Flayer[(BlackFrameStartIndex+BLongCastle)*half];
              inc(cnt);
            end;
          if (Undo.CastleRights and 4)<>(Board.CastleRights and 4) then
            begin
             cr[cnt]:=@NewPass.Net.Flayer[(BlackFrameStartIndex+WShortCastle)*half];
             inc(cnt);
            end;
          if (Undo.CastleRights and 8)<>(Board.CastleRights and 8) then
            begin
             cr[cnt]:=@NewPass.Net.Flayer[(BlackFrameStartIndex+WLongCastle)*half];
             inc(cnt);
            end;
          if cnt=1 then AVX2_ReSetFeauture(@NewPass.Acc16[black],cr[0],@NewPass.Acc16[black]) else
          if cnt=2 then AVX2_DBLReSetFeauture(@NewPass.Acc16[black],cr[0],cr[1],@NewPass.Acc16[black]) else
          if cnt=3 then begin
                          AVX2_DBLReSetFeauture(@NewPass.Acc16[black],cr[0],cr[1],@NewPass.Acc16[black]);
                          AVX2_ReSetFeauture(@NewPass.Acc16[black],cr[2],@NewPass.Acc16[black])
                        end
                   else begin
                          AVX2_DBLReSetFeauture(@NewPass.Acc16[black],cr[0],cr[1],@NewPass.Acc16[black]);
                          AVX2_DBLReSetFeauture(@NewPass.Acc16[black],cr[2],cr[3],@NewPass.Acc16[black]);
                        end;
        end;
    end;
end;

Procedure checkbinary(netindex:integer;filename:string;n:integer);
var
  f:TFileStream;
  stm,non : array of Thalf;
  Y : array of double;
  i,res : integer;
  x : Thalf;
  xx,fpass : integer;
  Pass : TForwardPass;
  err,fp : double;
begin
  f := TFileStream.Create(filename, fmOpenRead);
  setlength(stm,n);
  setlength(non,n);
  setlength(Y,n);
  Pass.Net:=@Nets[netindex];
  for i:=1 to n do
   begin
    res:=f.Read(x,half*2);
   if res<>half*2 then
    begin
     Writeln('Cant read a stm part  ',res,' ',hidden1*2);
     readln;
     exit;
    end;
    stm[i]:=x
   end;
  writeln('stm loaded');
  for i:=1 to n do
   begin
    res:=f.Read(x,half*2);
   if res<>half*2 then
    begin
     Writeln('Cant read a non',res,' ',hidden1*2);
     readln;
     exit;
    end;
    non[i]:=x
   end;
  writeln('non loaded');
  for i:=1 to n do
   begin
    res:=f.Read(xx,4);
   if res<>4 then
    begin
     Writeln('Cant read a Y',res,' ',4);
     readln;
     exit;
    end;
    Y[i]:=xx/1000000000;
   end;
  writeln('Y loaded');
  err:=0;
  for  i:=1 to n do
    begin
      avx2_copyacc(@stm[i],@Pass.Acc16[white]);
      avx2_copyacc(@non[i],@Pass.Acc16[black]);
      fpass:=forwardpass(white,Pass);
      fp:=(fpass/Nets[netindex].scale_out)/nets[netindex].scale_act;
      err:=err+abs(fp-Y[i]);
    end;
  writeln('Total error is ',err/n:15:12);
  f.free;
  readln;
end;
end.
