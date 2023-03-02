unit Unn;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$Define AVX2}   // Удалить или заккоментировать если компилируем для AVX512
{$Define pext}

interface
uses SysUtils,Classes,types,uBitBoards,uBoard,DateUtils;

Const
  current_version=10;  // что проверяем при загрузке сети
  AVX_8=32;            // 8*32=256
  AVX_16=16;           // 16*16=256
  AVX512_8=64;
  AVX512_16=32;
  hidden1=512;  // число нейронов в первом слое
  hidden2=8;
  hidden3=8;
  half=hidden1 div 2;

  cycle1=half div (2*AVX_16);
  cycle2=hidden2 div 8;
  cycle3=hidden1 div AVX_8;
  cycle4=hidden1*8;
  cycle5=hidden3 div 4;
  cycle6=half div AVX_16;

  cycle7=half div AVX512_16;
  cycle8=half div(AVX_16*8);
  cycle9=hidden2 div 4;

  step2=8;
  step3=10;
  // Макс предел 8 битового числа
  limit8=255;
  ones512 : array[0..63] of int16=(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
  RELUlimit : array[0..15] of integer=(limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8,limit8);
  Permut1 : array[0..7] of integer=(0,1,4,5,2,3,6,7);
  ModelBlockSize=64*12+2+2; // С признаками рокировок в блоке

  PieseBlock:array[-King..King] of integer=(704,640,576,512,448,384,0,0,64,128,192,256,320);

  WShortCastle=768;
  WLongCastle =769;
  BShortCastle=770;
  BLongCastle =771;
  MaxFrameSize=ModelBlockSize*10; // Модель К10
  K10Block : array[0..63] of integer =(
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      0*ModelBlockSize,1*ModelBlockSize,2*ModelBlockSize,3*ModelBlockSize,3*ModelBlockSize,2*ModelBlockSize,1*ModelBlockSize,0*ModelBlockSize,
      4*ModelBlockSize,4*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,4*ModelBlockSize,4*ModelBlockSize,
      4*ModelBlockSize,4*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,5*ModelBlockSize,4*ModelBlockSize,4*ModelBlockSize,
      6*ModelBlockSize,6*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,6*ModelBlockSize,6*ModelBlockSize,
      6*ModelBlockSize,6*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,7*ModelBlockSize,6*ModelBlockSize,6*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize,
      8*ModelBlockSize,8*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,9*ModelBlockSize,8*ModelBlockSize,8*ModelBlockSize);
Type
  Tbuf=array[1..64] of Pbyte;
  TF = array[white..black,0..Half-1] of int16;
  TNeuralNetWeights =packed record
     model       : integer; //Модель нейросети
     scale_act   : real;
     scale_out   : integer;
     w1          : integer;
     w2          : integer;
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

TForwardPass = packed record
     Acc16     : TF;                                     // Структура для акумулятора 16 бит  с точки зрения хода белых и хода черных отдельно
     Inputs8   : array[0..hidden1-1] of byte;            // То что поступает на вход нейросети после RELU аккумуляторов
     TempFirst : array[0..hidden2+3] of integer;         // результат после прохода первого слоя до RELU - hidden2(+4) int32 элементов
     RELUFirst : array[0..hidden2-1] of integer;         // результат первого слоя после RELU
     TempSecond: array[0..hidden3+3] of integer;         // результат после прохода второго слоя до RELU hidden2(+4) int32 элементов
     RELUSecond: array[0..hidden3-1] of integer;         // результат второго слоя после RELU
     store     : array[0..16*32-1] of byte                // хранилище для 16 регистров AVX2 (256 бит каждый)
end;

var
   Net : TNeuralNetWeights;
   // Для тестирования
   acc      : array[0..hidden1-1] of int16;
   inputrow : array[0..hidden1-1] of byte;
   inputmatrix : array[0..hidden1*hidden2-1] of int8;
   outputdata,outputdata2,outputdata3: array[0..hidden1+3] of integer;
   store     : array[0..5*32-1] of byte;
   arr : array of integer;

function GetFullVersionName(modelnum:integer) :ansistring;
Function loadnet(filename:string):boolean;
Function NetReSigma(y:integer):integer;
Function ForwardPass(SideToMove:integer;var Pass:TForwardPass):integer;
Procedure UpdAcc16(move:integer;var Board:Tboard;var Undo:Tundo;var OldPass:TForwardPass;var NewPass:TForwardPass);
Procedure CopyAcc16(var OldPass:TForwardPass;var NewPass:TForwardPass);
Function GetWhiteFrameIndex(model:integer;var Board:TBoard):integer;
Function GetBlackFrameIndex(model:integer;var Board:TBoard):integer;
Procedure FillWhiteAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
Procedure FillBlackAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
Procedure AVX2_CopyAcc(Source,Dest : Pbyte); //7.59 for AVX2, 6.4 for AVX512
Procedure speedtest;
Procedure CheckBatch(filename : ansistring; batchsize : integer);
implementation
uses uThread;

function GetFullVersionName(modelnum:integer) :ansistring;
   begin
     if modelnum=0
      then Result:=VersionName+'_zeroblock'
      else Result:=VersionName;
     {$IFDEF AVX2}
       Result:=Result+'_AVX2';
       {$IFDEF pext}
         Result:=Result+'_PEXT';
       {$ENDIF pext}
     {$ELSE AVX2}
       Result:=Result+'_AVX512';
     {$ENDIF AVX2}
   end;
Function ReSigma(y:real):integer;
// По значению вероятности [0..1] восстанавливает оценку позиции
begin
  If y<0.001 then y:=0.001;
  if y>0.999 then y:=0.999;
  result:=round(-400*ln((1/y)-1));
end;
Function NetReSigma(y:integer):integer;
// Быстрый поиск значения оценки по сырому выходу из нейросети
begin
  If y<0 then y:=0;
  if y>Net.MaxSigma then y:=Net.MaxSigma;
  result:=Net.Sigma[y];
end;
Function ModelFrameSize(model:integer):integer;
var
   res : integer;
begin
  res:=0;
  if model=0 then res:=ModelBlockSize else       // zero model
  if model=5 then res:=10*ModelBlockSize;        // K10-model
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
  mov r10,cycle1                         // счетчик числа проходов по акк  8*(16+16)=256
@@1:
  // Берем первые 16 значений аккумулятора int16
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // Берем вторые 16 значений аккумулятора int16
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // Теперь пакуем  2 по 16 int16 в  int8 (с сатурацией без знака ) + RELU
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
procedure slowFirstLayer(var Pass:TforwardPass);
var
   i,j:integer;
   sums : integer;
begin
  for j:=0 to hidden2-1 do
  begin
   sums:=0;
   for i:=0 to hidden1-1 do
    begin
      sums:=sums+Net.FirstLayer[j*hidden1+i]*Pass.Inputs8[i];
    end;
    Pass.TempFirst[j]:=sums;
  end;

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

    {$IFDEF AVX2}
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
     mov r10,cycle2                  // счетчик  стобцов (обрабатываем по 8 столбцов за 1 проход цикла) 8*1=8
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
   {$ELSE AVX2}
     // Единичный столбец
    lea r10,[rip+ones512]
    db 62h,041h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm24,[r10]
    // Кешируем аккумулятор в 8 регистрах
    db 62h,0e1h,7eh,48h,6fh,01h                   // AVX512 vmovdqu32 zmm16,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,09h                   // AVX512 vmovdqu32 zmm17,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,11h                   // AVX512 vmovdqu32 zmm18,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,19h                   // AVX512 vmovdqu32 zmm19,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,21h                   // AVX512 vmovdqu32 zmm20,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,29h                   // AVX512 vmovdqu32 zmm21,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,31h                   // AVX512 vmovdqu32 zmm22,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,39h                   // AVX512 vmovdqu32 zmm23,[rcx]
    mov r10, cycle9
@@3:
    // Обнуляем накопители столбцов
    db 62h,0f1h,0f5h,48h,0efh,0c9h                 // AVX512 vpxorq zmm1,zmm1,zmm1
    db 62h,0f1h,0edh,48h,0efh,0d2h                 // AVX512 vpxorq zmm2,zmm2,zmm2
    db 62h,0f1h,0e5h,48h,0efh,0dbh                 // AVX512 vpxorq zmm3,zmm3,zmm3
    db 62h,0f1h,0ddh,48h,0efh,0e4h                 // AVX512 vpxorq zmm4,zmm4,zmm4
    // По кусочкам проходим по всей строке
    // 1 столбец
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,7dh,40h,04h,0c0h                  // AVX512 vpmaddubsw zmm0,zmm16,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0c9h                 // AVX512 vpaddd zmm1,zmm0,zmm1
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,75h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm17,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0c9h                   // AVX512 vpaddd zmm1,zmm0,zmm1
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,6dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm18,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0c9h                   // AVX512 vpaddd zmm1,zmm0,zmm1
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,65h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm19,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0c9h                   // AVX512 vpaddd zmm1,zmm0,zmm1
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,5dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm20,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0c9h                   // AVX512 vpaddd zmm1,zmm0,zmm1
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,55h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm21,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0c9h                   // AVX512 vpaddd zmm1,zmm0,zmm1
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,4dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm22,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0c9h                   // AVX512 vpaddd zmm1,zmm0,zmm1
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,45h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm23,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0c9h                   // AVX512 vpaddd zmm1,zmm0,zmm1
    add rdx,64
    // 2 столбец
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,7dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm16,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0d2h                   // AVX512 vpaddd zmm2,zmm0,zmm2
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,75h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm17,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0d2h                   // AVX512 vpaddd zmm2,zmm0,zmm2
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,6dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm18,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0d2h                   // AVX512 vpaddd zmm2,zmm0,zmm2
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,65h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm19,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0d2h                   // AVX512 vpaddd zmm2,zmm0,zmm2
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,5dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm20,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0d2h                   // AVX512 vpaddd zmm2,zmm0,zmm2
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,55h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm21,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0d2h                   // AVX512 vpaddd zmm2,zmm0,zmm2
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,4dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm22,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0d2h                   // AVX512 vpaddd zmm2,zmm0,zmm2
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,45h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm23,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0d2h                   // AVX512 vpaddd zmm2,zmm0,zmm2
    add rdx,64
    // 3 столбец
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,7dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm16,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0dbh                   // AVX512 vpaddd zmm3,zmm0,zmm3
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,75h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm17,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0dbh                   // AVX512 vpaddd zmm3,zmm0,zmm3
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,6dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm18,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0dbh                   // AVX512 vpaddd zmm3,zmm0,zmm3
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,65h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm19,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0dbh                   // AVX512 vpaddd zmm3,zmm0,zmm3
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,5dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm20,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0dbh                   // AVX512 vpaddd zmm3,zmm0,zmm3
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,55h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm21,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0dbh                   // AVX512 vpaddd zmm3,zmm0,zmm3
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,4dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm22,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0dbh                   // AVX512 vpaddd zmm3,zmm0,zmm3
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,45h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm23,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0dbh                   // AVX512 vpaddd zmm3,zmm0,zmm3
    add rdx,64
    // 4 столбец
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,7dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm16,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0e4h                   // AVX512 vpaddd zmm4,zmm0,zmm4
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,75h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm17,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0e4h                   // AVX512 vpaddd zmm4,zmm0,zmm4
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,6dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm18,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0e4h                   // AVX512 vpaddd zmm4,zmm0,zmm4
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,65h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm19,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0e4h                   // AVX512 vpaddd zmm4,zmm0,zmm4
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,5dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm20,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0e4h                   // AVX512 vpaddd zmm4,zmm0,zmm4
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,55h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm21,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0e4h                   // AVX512 vpaddd zmm4,zmm0,zmm4
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,4dh,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm22,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0e4h                   // AVX512 vpaddd zmm4,zmm0,zmm4
    add rdx,64
    db 62h,0f1h,7eh,48h,6fh,02h                   // AVX512 vmovdqu32 zmm0,[rdx]
    db 62h,0f2h,45h,40h,04h,0c0h                   // AVX512 vpmaddubsw zmm0,zmm23,zmm0
    //умножаем полученные столбцы на единичный и приводим к int32
    db 62h,091h,7dh,48h,0f5h,0c0h                 // AVX512 vpmaddwd zmm0,zmm0,zmm24
    db 62h,0f1h,7dh,48h,0feh,0e4h                   // AVX512 vpaddd zmm4,zmm0,zmm4
    add rdx,64
    // Складываем пополам и приводим к 256 бит
    db 62h,0f3h,7dh,48h,3bh,0c8h,01h               // AVX512 vextracti32x8 ymm0,zmm1,1
    db 0c5h,0fdh,0feh,0c9h                          // AVX5 vpaddd ymm1,ymm0,ymm1
    db 62h,0f3h,7dh,48h,3bh,0d0h,01h               // AVX512 vextracti32x8 ymm0,zmm2,1
    db 0c5h,0fdh,0feh,0d2h                          // AVX5 vpaddd ymm2,ymm0,ymm2
    db 62h,0f3h,7dh,48h,3bh,0d8h,01h               // AVX512 vextracti32x8 ymm0,zmm3,1
    db 0c5h,0fdh,0feh,0dbh                          // AVX5 vpaddd ymm3,ymm0,ymm3
    db 62h,0f3h,7dh,48h,3bh,0e0h,01h               // AVX512 vextracti32x8 ymm0,zmm4,1
    db 0c5h,0fdh,0feh,0e4h                          // AVX5 vpaddd ymm4,ymm0,ymm4
    // Мы получили векторы для 4-х столбцов. Теперь горизонтально суммируем их, чтобы в итоге получить 4 32-разрядных результата
    db 0c4h,0e2h,75h,02h,0cah          // AVX2 vphaddd ymm1,ymm1,ymm2
    db 0c4h,0e2h,65h,02h,0dch          // AVX2 vphaddd ymm3,ymm3,ymm4
    db 0c4h,0e2h,75h,02h,0cbh          // AVX2 vphaddd ymm1,ymm1,ymm3
    // Полученный вектор складываем пополам
    db 0c4h,0e3h,7dh,39h,0cah,01       // AVX2 vextracti128 xmm2,ymm1,0x1
    db 0c5h,0f5h,0feh,0cah             // AVX2 vpaddd ymm1,ymm1,ymm2
     // сохраняем результат для очередных четырех обработанных столбцов (младшая часть)
    db 0c4h,0c1h,7eh,7fh,08h           // AVX vmovdqu [r8],ymm1
    add r8,16
    // крутим цикл
    sub r10,1
    jnz @@3
  {$ENDIF AVX2}
     // очищаем "верхний флаг"
     db 0c5h,0f8h,77h                 // AVX vzeroupper
end;

Procedure AVX2_RELU_2(Summs,Biases,limits,Res : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 1.34 for 8;
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
    // Строка нулей
    db 0c5h,0edh,0efh,0d2h                   // AVX2  vpxor ymm2,ymm2,ymm2
    // Строка лимитов для RELU
    db 0c4h,0c1h,07eh,06fh,18h              // AVX  vmovdqu ymm3,[r8]
    //  8 int32 элементов
    db 0c5h,0feh,6fh,01h                    // AVX vmovdqu ymm0,[rcx]
    // суммируем с первыми 8 биасами
    db 0c5h,0feh,6fh,0Ah                    // AVX vmovdqu ymm1,[rdx]
    db 0c5h,0f5h,0feh,0c0h                  // AVX2 vpaddd ymm0,ymm1,ymm0
    // множитель квантования
    db 0c5h,0fdh,72h,0e0h,step2             // AVX2 vpsraw ymm0,ymm0,step2
     // Делаем RELU c 0
    db 0c4h,0e2h,7dh,3dh,0c2h               // AVX2 vpmaxsd ymm0,ymm0,ymm2
    // Делаем Clipped_RELU
    db 0c4h,0e2h,7dh,39h,0c3h              // AVX2 vpminsd ymm0,ymm0,ymm3
    // Сохраняем результат
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
end;

Procedure AVX2_SecondLayer_Mul(inprow,Matrix,dest : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  //6.3 for 8x8
//                              rcx(rdi),rdx(rsi),r8(rdx)
// Перемножает матрицу [1xhidden2] элемента  int32 на матрицу [hidden2xhidden3] элемента int32 используя SIMD AVX2
// на выходе матрица [1xhidden3] int32
asm
  {$IFNDEF FPC}
  .noframe
  {$ENDIF}

  {$ifdef UNIX}
     mov r8,rdx
     mov rdx,rsi
     mov rcx,rdi
  {$endif}

     mov r11,cycle5                     // цикл столбцов
     // читаем строку improw [1,8]
     db 0c5h,0feh,6fh,01h               // AVX vmovdqu ymm0,[rcx]
   // В цикле обрабатываем сразу по 4 стлобца
@@1:
     //1 столбец
     db 0c5h,0feh,6fh,0ah               // AVX vmovdqu ymm1,[rdx]
     db 0c4h,0e2h,7dh,40h,0c9h          // AVX2 vpmulld ymm1,ymm0,ymm1
     //2 столбец
     add rdx,32
     db 0c5h,0feh,6fh,12h               // AVX vmovdqu ymm2,[rdx]
     db 0c4h,0e2h,7dh,40h,0d2h          // AVX2 vpmulld ymm2,ymm0,ymm2
     //3 столбец
     add rdx,32
     db 0c5h,0feh,6fh,1ah               // AVX vmovdqu ymm3,[rdx]
     db 0c4h,0e2h,7dh,40h,0dbh          // AVX2 vpmulld ymm3,ymm0,ymm3
     //4 столбец
     add rdx,32
     db 0c5h,0feh,6fh,22h               // AVX vmovdqu ymm4,[rdx]
     db 0c4h,0e2h,7dh,40h,0e4h          // AVX2 vpmulld ymm4,ymm0,ymm4
  // Мы получили векторы для 4-х столбцов. Теперь горизонтально суммируем их, чтобы в итоге получить 4 32-разрядных результата
     db 0c4h,0e2h,75h,02h,0cah          // AVX2 vphaddd ymm1,ymm1,ymm2
     db 0c4h,0e2h,65h,02h,0dch          // AVX2 vphaddd ymm3,ymm3,ymm4
     db 0c4h,0e2h,75h,02h,0cbh          // AVX2 vphaddd ymm1,ymm1,ymm3
    // Полученный вектор складываем пополам
     db 0c4h,0e3h,7dh,39h,0cah,01       // AVX2 vextracti128 xmm2,ymm1,0x1
     db 0c5h,0f5h,0feh,0cah             // AVX2 vpaddd ymm1,ymm1,ymm2
     // сохраняем результат для очередных четырех обработанных столбцов (младшая часть)
     db 0c4h,0c1h,7eh,7fh,08h           // AVX vmovdqu [r8],ymm1
     add r8,16
     // крутим цикл
     add rdx,32
     sub r11,1
     jnz @@1
     // очищаем "верхний флаг"
     db 0c5h,0f8h,77h                       // AVX vzeroupper
end;
Procedure AVX2_RELU_3(Summs,Biases,limits,Res : Pbyte);{$IFDEF FPC} nostackframe assembler;{$ENDIF}  // 1.34 for 8;
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

    // Строка нулей
    db 0c5h,0edh,0efh,0d2h                 // AVX2  vpxor ymm2,ymm2,ymm2
    // Строка лимитов для RELU
    db 0c4h,0c1h,07eh,06fh,18h             // AVX  vmovdqu ymm3,[r8]
    //  8 int32 элементов
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
    // суммируем с первыми 8 биасами
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0
    // множитель квантования
    db 0c5h,0fdh,72h,0e0h,step3            // AVX2 vpsraw ymm0,ymm0,step3
     // Делаем RELU c 0
    db 0c4h,0e2h,7dh,3dh,0c2h              // AVX2 vpmaxsd ymm0,ymm0,ymm2
    // Делаем Clipped_RELU
    db 0c4h,0e2h,7dh,39h,0c3h              // AVX2 vpminsd ymm0,ymm0,ymm3
    // Сохраняем результат
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
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

     db 0c5h,0edh,0efh,0d2h              // AVX2  vpxor ymm2,ymm2,ymm2
     db 0c5h,0e5h,0efh,0dbh              // AVX2  vpxor ymm3,ymm3,ymm3
     db 0c5h,0ddh,0efh,0e4h              // AVX2  vpxor ymm4,ymm4,ymm4
  // читаем строку improw [1,8]
     db 0c5h,0feh,6fh,01h                // AVX vmovdqu ymm0,[rcx]
  // читаем строку матрицы [8,1]
     db 0c5h,0feh,6fh,0Ah                // AVX vmovdqu ymm1,[rdx]
  //  перемножаем  int32
     db 0c4h,0e2h,7dh,40h,0c9h           // AVX2 vpmulld ymm1,ymm0,ymm1
  // Мы получили векторы для 4-х столбцов. Теперь горизонтально суммируем их, чтобы в итоге получить 4 32-разрядных результата
     db 0c4h,0e2h,75h,02h,0cah           // AVX2 vphaddd ymm1,ymm1,ymm2
     db 0c4h,0e2h,65h,02h,0dch           // AVX2 vphaddd ymm3,ymm3,ymm4
     db 0c4h,0e2h,75h,02h,0cbh           // AVX2 vphaddd ymm1,ymm1,ymm3
    // Полученный вектор складываем пополам
     db 0c4h,0e3h,7dh,39h,0cah,01       // AVX2 vextracti128 xmm2,ymm1,0x1
     db 0c5h,0f5h,0feh,0cah             // AVX2 vpaddd ymm1,ymm1,ymm2
  // очищаем "верхний флаг"
     db 0c5h,0f8h,77h                   // AVX vzeroupper
  // Результат перемножения
     movd eax,xmm1
  // Добавляем биас
     add eax,DWORD ptr [r9]
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

  {$IFDEF AVX2}
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
  {$ELSE AVX2}
    mov r10,cycle7                        // счетчик   AVX512_16*cycle7=half
@@2:
    // читаем строку источника (32 элементов int16)
    db 62h,0e1h,7eh,48h,6fh,01h           // AVX512 vmovdqu32 zmm16,[rcx]
    // Сохраняем обновленные данные
    db 62h,0e1h,7eh,48h,7fh,02h           // AVX512 vmovdqu32 [rdx],zmm16
    // Следующие 32 int16 элементов
    add rcx,64
    add rdx,64
    // Крутим цикл
    sub r10,1
    jnz @@2
  {$ENDIF AVX2}

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

  {$IFDEF AVX2}
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
  {$ELSE AVX2}
    mov r10,cycle7                        // счетчик   AVX512_16*cycle7=half
@@2:
    // читаем строку источника (32 элементов int16)
    db 62h,0e1h,7eh,48h,6fh,01h           // AVX512 vmovdqu32 zmm16,[rcx]
    // читаем строку весов (32 элементов int16)
    db 62h,0e1h,7eh,48h,6fh,0ah           // AVX512 vmovdqu32 zmm17,[rdx]
    // Устанавливаем (складываем)
    db 62h,0a1h,7dh,40h,0fdh,0c1h         // AVX512 vpaddw zmm16,zmm16,zmm17
    // Сохраняем обновленные данные
    db 62h,0c1h,7eh,48h,7fh,00h           // AVX512 vmovdqu32 [r8],zmm16
    // Следующие 32 int16 элементов
    add rcx,64
    add rdx,64
    add r8, 64
    // Крутим цикл
    sub r10,1
    jnz @@2
  {$ENDIF AVX2}

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

  {$IFDEF AVX2}
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
  {$ELSE AVX2}
    mov r10,cycle7                        // счетчик   AVX512_16*cycle7=half
@@2:
    // читаем строку источника (32 элементов int16)
    db 62h,0e1h,7eh,48h,6fh,01h           // AVX512 vmovdqu32 zmm16,[rcx]
    // читаем строку весов (32 элементов int16)
    db 62h,0e1h,7eh,48h,6fh,0ah           // AVX512 vmovdqu32 zmm17,[rdx]
    // Устанавливаем (вычитаем)
    db 62h,0a1h,7dh,40h,0f9h,0c1h         // AVX512 vpsubw zmm16,zmm16,zmm17
    // Сохраняем обновленные данные
    db 62h,0c1h,7eh,48h,7fh,00h           // AVX512 vmovdqu32 [r8],zmm16
    // Следующие 32 int16 элементов
    add rcx,64
    add rdx,64
    add r8, 64
    // Крутим цикл
    sub r10,1
    jnz @@2
  {$ENDIF AVX2}
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

  {$IFDEF AVX2}
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
  {$ELSE AVX2}
    mov r10,cycle7                        // счетчик   AVX512_16*cycle7=half
@@2:
    // читаем строку источника (32 элементов int16)
    db 62h,0e1h,7eh,48h,6fh,01h           // AVX512 vmovdqu32 zmm16,[rcx]
    // читаем строку весов1 (32 элементов int16)
    db 62h,0e1h,7eh,48h,6fh,0ah           // AVX512 vmovdqu32 zmm17,[rdx]
    // читаем строку весов2 (32 элементов int16)
    db 62h,0c1h,7eh,48h,6fh,10h           // AVX512 vmovdqu32 zmm18,[r8]
    // Устанавливаем1 (складываем)
    db 62h,0a1h,7dh,40h,0fdh,0c1h         // AVX512 vpaddw zmm16,zmm16,zmm17
    // Устанавливаем2 (вычитаем)
    db 62h,0a1h,7dh,40h,0f9h,0c2h         // AVX512 vpsubw zmm16,zmm16,zmm18
    // Сохраняем обновленные данные
    db 62h,0c1h,7eh,48h,7fh,01h           // AVX512 vmovdqu32 [r9],zmm16
    // Следующие 32 int16 элементов
    add rcx,64
    add rdx,64
    add r8, 64
    add r9, 64
    // Крутим цикл
    sub r10,1
    jnz @@2
  {$ENDIF AVX2}
end;
Procedure AVX2_UpdBufFeauture(acc,cnt,Buf,store : Pbyte); {$IFDEF FPC} nostackframe assembler;{$ENDIF}
//                             rcx(rdi),rdx(rsi),r8(rdx),r9(rcx)
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

    {$IFDEF AVX2}
    // сохраняем все регистры, необходимые для корректной работы Windows
    mov r10,r9
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
    lea rcx,[rip+net.Fbias];
@@1:
    // Кешируем часть аккумулятора в 8 регистрах
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
    add r12,256                            // смещение для следующего кусочка
    sub r10,1
    jnz @@1
    // Восстанавливаем регистры
    pop r14
    pop r13
    pop r12
    mov r10,r9
    db 0c4h,0c1h,07eh,06fh,2ah             // AVX  ymm5,vmovdqu [r10]
    add r10,32
    db 0c4h,0c1h,07eh,06fh,32h             // AVX  ymm6,vmovdqu [r10]
    add r10,32
    db 0c4h,0c1h,07eh,06fh,3ah             // AVX  ymm7,vmovdqu [r10]
    add r10,32
    db 0c4h,041h,07eh,06fh,02h             // AVX  ymm8,vmovdqu [r10]
    // очищаем "верхний флаг"
    db 0c5h,0f8h,77h                       // AVX vzeroupper
    {$ELSE AVX2}
    mov r11,rcx
    lea rcx,[rip+net.Fbias]
    // Кешируем аккумулятор в 8 регистрах
    db 62h,0e1h,7eh,48h,6fh,01h                   // AVX vmovdqu32 zmm16,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,09h                   // AVX vmovdqu32 zmm17,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,11h                   // AVX vmovdqu32 zmm18,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,19h                   // AVX vmovdqu32 zmm19,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,21h                   // AVX vmovdqu32 zmm20,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,29h                   // AVX vmovdqu32 zmm21,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,31h                   // AVX vmovdqu32 zmm22,[rcx]
    add rcx,64
    db 62h,0e1h,7eh,48h,6fh,39h                   // AVX vmovdqu32 zmm23,[rcx]
    // Прогоняем все фичи из буфера
    mov r10,[rdx]
@@3:
    mov rax,[r8]
    // 1 регистр
    db 62h,61h,7eh,48h,6fh,00h                    // AVX vmovdqu32 ymm24,[rax]
    db 62h,0a1h,3dh,40h,0fdh,0c0h                 // AVX2 vpaddw zmm16,zmm24,zmm16
    add rax,64
    // 2 регистр
    db 62h,61h,7eh,48h,6fh,00h                    // AVX vmovdqu32 ymm24,[rax]
    db 62h,0a1h,3dh,40h,0fdh,0c9h                 // AVX2 vpaddw zmm17,zmm24,zmm17
    add rax,64
    // 3 регистр
    db 62h,61h,7eh,48h,6fh,00h                    // AVX vmovdqu32 ymm24,[rax]
    db 62h,0a1h,3dh,40h,0fdh,0d2h                 // AVX2 vpaddw zmm18,zmm24,zmm18
    add rax,64
    // 4 регистр
    db 62h,61h,7eh,48h,6fh,00h                    // AVX vmovdqu32 ymm24,[rax]
    db 62h,0a1h,3dh,40h,0fdh,0dbh                 // AVX2 vpaddw zmm19,zmm24,zmm19
    add rax,64
    // 5 регистр
    db 62h,61h,7eh,48h,6fh,00h                    // AVX vmovdqu32 ymm24,[rax]
    db 62h,0a1h,3dh,40h,0fdh,0e4h                 // AVX2 vpaddw zmm20,zmm24,zmm20
    add rax,64
    // 6 регистр
    db 62h,61h,7eh,48h,6fh,00h                    // AVX vmovdqu32 ymm24,[rax]
    db 62h,0a1h,3dh,40h,0fdh,0edh                 // AVX2 vpaddw zmm21,zmm24,zmm21
    add rax,64
    // 7 регистр
    db 62h,61h,7eh,48h,6fh,00h                    // AVX vmovdqu32 ymm24,[rax]
    db 62h,0a1h,3dh,40h,0fdh,0f6h                 // AVX2 vpaddw zmm22,zmm24,zmm22
    add rax,64
    // 8 регистр
    db 62h,61h,7eh,48h,6fh,00h                    // AVX vmovdqu32 ymm24,[rax]
    db 62h,0a1h,3dh,40h,0fdh,0ffh                 // AVX2 vpaddw zmm23,zmm24,zmm23
    add r8,8                                      // следующая фича
    sub r10,1
    jnz @@3
    // сохраняем обработанный  аккумулятор
    db 62h,0c1h,7eh,48h,7fh,03h                   // AVX vmovdqu32 [r11],zmm16
    add r11,64
    db 62h,0c1h,7eh,48h,7fh,0bh                   // AVX vmovdqu32 [r11],zmm17
    add r11,64
    db 62h,0c1h,7eh,48h,7fh,13h                   // AVX vmovdqu32 [r11],zmm18
    add r11,64
    db 62h,0c1h,7eh,48h,7fh,1bh                   // AVX vmovdqu32 [r11],zmm19
    add r11,64
    db 62h,0c1h,7eh,48h,7fh,23h                   // AVX vmovdqu32 [r11],zmm20
    add r11,64
    db 62h,0c1h,7eh,48h,7fh,2bh                   // AVX vmovdqu32 [r11],zmm21
    add r11,64
    db 62h,0c1h,7eh,48h,7fh,33h                   // AVX vmovdqu32 [r11],zmm22
    add r11,64
    db 62h,0c1h,7eh,48h,7fh,3bh                   // AVX vmovdqu32 [r11],zmm23
    {$ENDIF AVX2}
end;
 

Function ForwardPass(SideToMove:integer;var Pass:TForwardPass):integer;
// Проход по нейросети. На входе загруженная сеть, очередь хода и структура аккумулятора, на выходе - Оценка позции
begin
  //в зависимости от очереди хода расставляем аккумуляторы в нужном порядке
  AVX2_RELU_ACC(@Pass.Acc16[SideToMove],@permut1,@Pass.Inputs8);
  AVX2_RELU_ACC(@Pass.Acc16[SideToMove xor 1],@permut1,@Pass.Inputs8[half]);
  //1
  AVX2_FirstLayer_Mul(@Pass.Inputs8,@Net.FirstLayer,@Pass.TempFirst,@Pass.store);
  AVX2_RELU_2(@Pass.TempFirst,@Net.biasFirst,@RELUlimit,@Pass.RELUFirst);
  //2
  AVX2_SecondLayer_Mul(@Pass.RELUFirst,@Net.SecondLayer,@Pass.TempSecond);
  AVX2_RELU_3(@Pass.TempSecond,@Net.biasSecond,@RELUlimit,@Pass.RELUSecond);
  // output
  Result:=AVX2_NNOut(@Pass.RELUSecond,@Net.outlayer,@Ones512,@Net.outbias);
end;

Function loadnet(filename:string):boolean;
var
  res,size,i,j : integer;
  ver,w   : int16;
  f: TResourceStream;
 // f   :TFileStream;
begin
  // Открываем файл и проверяем верисю нейросети
  f := TResourceStream.Create(HInstance, 'MYDATA', RT_RCDATA);
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
     exit;
    end;
  // Считываем константу scale_act - она зависит от процесса обучения и может от версии к версии меняться.
  Net.scale_act:=0;
  res:=f.Read(w,2);  // 16 бит целочисленное  = scale_act*100
  if res<>2 then
    begin
      Writeln('Cant read a scale_act byte!');
      exit;
    end;
  Net.scale_act:=w/100; // может быть и дробным
  // Считываем константу scale_out - она зависит от процесса обучения и может от версии к версии меняться.
  Net.scale_out:=0;
  res:=f.Read(w,2);  // 16 бит целочисленное
  if res<>2 then
    begin
      Writeln('Cant read a scale_out byte!');
      exit;
    end;
  Net.scale_out:=w;
  // Считываем номер модели нейросети
   res:=f.Read(Net.model,2);
   if res<>2 then
    begin
     Writeln('Cant read a model number!');
     exit;
    end;
  Net.ModelSize:=ModelFrameSize(Net.model);
  // Считываем константу w1 - она зависит от процесса обучения и может от версии к версии меняться.
  res:=f.Read(w,2);  // 16 бит целочисленное
  if res<>2 then
    begin
      Writeln('Cant read a w1 byte!');
      exit;
    end;
  Net.w1:=w;
   // Считываем константу w2 - она зависит от процесса обучения и может от версии к версии меняться.
  res:=f.Read(w,2);  // 16 бит целочисленное
  if res<>2 then
    begin
      Writeln('Cant read a w2 byte!');
      exit;
    end;
  Net.w2:=w;
  // Вычисляем размер модели и считываем сеть в память
  size:=ModelFrameSize(Net.model);
  if size=0 then
    begin
      Writeln('Unknown model!');
      exit;
    end;
  size:=size*half*2; // Размер считываемых байтов весов Flayer (int16=2 байта)
  // Считываем Flayer weights int16
  res:=f.Read(Net.Flayer,size);
  if res<>size then
    begin
     Writeln('Cant read Flayer weights!');
     exit;
    end;

  // Считываем FirstLayer weights int8
  res:=f.Read(Net.FirstLayer,hidden1*hidden2);
  if res<>hidden1*hidden2 then
    begin
     Writeln('Cant read a FirstLayer weights!');
     exit;
    end;
  // Считываем SecondLayer weights integer
  res:=f.Read(Net.SecondLayer,hidden2*hidden3*4); // int32=4 байта
  if res<>hidden2*hidden3*4 then
    begin
     Writeln('Cant read a SecondLayer weights!');
     exit;
    end;
  // Считываем OutLayer weights integer
  res:=f.Read(Net.outlayer,hidden3*4); // int32=4 байта
  if res<>hidden3*4 then
    begin
     Writeln('Cant read a OutLayer weights!');
     exit;
    end;
  // Считываем Flayer biases int16
  res:=f.Read(Net.Fbias,half*2); // (int16=2 байта)
  if res<>half*2 then
    begin
     Writeln('Cant read a Flayer biases!');
     exit;
    end;
  // Считываем FirstLayer biases int32
  res:=f.Read(Net.biasFirst,4*hidden2);
  if res<>4*hidden2 then
    begin
     Writeln('Cant read a FirstLayer biases!');
     exit;
    end;
  // Считываем SecondLayer biases int32
  res:=f.Read(Net.biasSecond,4*hidden3);
  if res<>4*hidden3 then
    begin
     Writeln('Cant read a SecondLayer biases!');
     exit;
    end;
  // Считываем OutLayer biases int32
  res:=f.Read(Net.outbias,4);
  if res<>4 then
    begin
     Writeln('Cant read a OutLayer biases!');
     exit;
    end;
  // Заполняем таблицу сигм для быстрого их потом вычисления
  j:=round(Net.scale_act*Net.scale_out);
  Setlength(Net.Sigma,0);
  Setlength(Net.Sigma,j+1);
  Net.MaxSigma:=j;
  for i:=0 to j do
      Net.Sigma[i]:=ReSigma((i/Net.scale_out)/Net.scale_act);
  f.Free;
  writeln('NET Version : ',ver);
  //writeln('Scale_act = ',Net.scale_act:6:2);
  //writeln('w1 = ',Net.w1);
  //writeln('w2 = ',Net.w2);
  //writeln('Scale_out = ',Net.scale_out);
  //writeln('Model : ',Net.model);
  Result:=True;
end;

Function GetBlockIndex(Piese:integer;sq:integer):integer;
// Вычисляет индекс положения фигуры на доске. На входе - фигура любого цвета и поле, которое она занимает, на выходе - индекс внутри блока
begin
  Result:=PieseBlock[Piese]+sq;
end;

Procedure SetPiesesWhiteAcc(WhiteFrameStartIndex:integer;Piese:integer;var Board:TBoard;var buf:TBuf;var cnt:int64);
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
      Whiteindex:=(WhiteFrameStartIndex+GetBlockIndex(P,sq))*half;
      inc(cnt);
      buf[cnt]:=@Net.Flayer[WhiteIndex];
    end;
end;
Procedure SetPiesesBlackAcc(BlackFrameStartIndex:integer;Piese:integer;var Board:TBoard;var buf:TBuf;var cnt:int64);
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
      Blackindex:=(BlackFrameStartIndex+GetBlockIndex(-P,sq xor 56))*half;
      inc(cnt);
      buf[cnt]:=@Net.Flayer[BlackIndex];
    end;
end;
Function GetWhiteFrameIndex(model:integer;var Board:TBoard):integer;
// В зависимости от выбранной модели нейросети и положения на доске возвращает начальный индекс белого фрейма.
var
  res:integer;
begin
  res:=0;
  if model=5 then res:=K10Block[Board.KingSq[white]]; // K10 Model
  Result:=res;
end;
Function GetBlackFrameIndex(model:integer;var Board:TBoard):integer;
// В зависимости от выбранной модели нейросети и положения на доске возвращает начальный индекс черного фрейма.
var
  res:integer;
begin
  res:=0;
  if model=5 then res:=K10Block[Board.KingSq[black] xor 56]; // K10 Model
  Result:=res;
end;
Procedure FillWhiteAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
// Заполняет структуру белого аккумулятора  по позиции на доске
var
  WhiteFrameStartIndex : integer;
  cnt : int64;
  cr : Tbuf;
begin
  WhiteFrameStartIndex:=GetWhiteFrameIndex(model,Board);
  // Устанавливаем королей
  cr[1]:=@Net.Flayer[(WhiteFrameStartIndex+GetBlockIndex(King,Board.KingSq[white]))*half];
  cr[2]:=@Net.Flayer[(WhiteFrameStartIndex+GetBlockIndex(-King,Board.KingSq[black]))*half];
  cnt:=2;
  //  Теперь устанавливаем фигуры
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Queen,Board,cr,cnt);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Rook,Board,cr,cnt);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Bishop,Board,cr,cnt);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Knight,Board,cr,cnt);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Pawn,Board,cr,cnt);
  // Устанавливаем рокировки
  If (Board.CastleRights and 1)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@Net.Flayer[(WhiteFrameStartIndex+WShortCastle)*half];
    end;
  If (Board.CastleRights and 2)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@Net.Flayer[(WhiteFrameStartIndex+WLongCastle)*half];
    end;
  If (Board.CastleRights and 4)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@Net.Flayer[(WhiteFrameStartIndex+BShortCastle)*half];
    end;
  If (Board.CastleRights and 8)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@Net.Flayer[(WhiteFrameStartIndex+BlongCastle)*half];
    end;
  AVX2_UpdBufFeauture(@Pass.Acc16[white],@cnt,@cr,@Pass.store);
end;
Procedure FillBlackAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
// Заполняет структуру черного аккумулятора  по позиции на доске
var
  BlackFrameStartIndex : integer;
  cnt : int64;
  cr : Tbuf;
begin
  BlackFrameStartIndex:=GetBlackFrameIndex(model,Board);
  // Устанавливаем королей
  cr[1]:=@Net.Flayer[(BlackFrameStartIndex+GetBlockIndex(-King,(Board.KingSq[white] xor 56)))*half];
  cr[2]:=@Net.Flayer[(BlackFrameStartIndex+GetBlockIndex(King,(Board.KingSq[black] xor 56)))*half];
  cnt:=2;
  //  Теперь устанавливаем фигуры
  SetPiesesBlackAcc(BlackFrameStartIndex,Queen,Board,cr,cnt);
  SetPiesesBlackAcc(BlackFrameStartIndex,Rook,Board,cr,cnt);
  SetPiesesBlackAcc(BlackFrameStartIndex,Bishop,Board,cr,cnt);
  SetPiesesBlackAcc(BlackFrameStartIndex,Knight,Board,cr,cnt);
  SetPiesesBlackAcc(BlackFrameStartIndex,Pawn,Board,cr,cnt);
   //Устанавливаем рокировки
  If (Board.CastleRights and 1)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@Net.Flayer[(BlackFrameStartIndex+BShortCastle)*half];
    end;
  If (Board.CastleRights and 2)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@Net.Flayer[(BlackFrameStartIndex+BLongCastle)*half];
    end;
  If (Board.CastleRights and 4)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@Net.Flayer[(BlackFrameStartIndex+WShortCastle)*half];
    end;
  If (Board.CastleRights and 8)<>0 then
    begin
      inc(cnt);
      cr[cnt]:=@Net.Flayer[(BlackFrameStartIndex+WlongCastle)*half];
    end;
  AVX2_UpdBufFeauture(@Pass.Acc16[black],@cnt,@cr,@Pass.store);
end;

Procedure CopyAcc16(var OldPass:TForwardPass;var NewPass:TForwardPass);
begin
  AVX2_CopyAcc(@OldPass.Acc16[white],@NewPass.Acc16[white]);
  AVX2_CopyAcc(@OldPass.Acc16[black],@NewPass.Acc16[black]);
end;

Procedure UpdAcc16(move:integer;var Board:Tboard;var Undo:Tundo;var OldPass:TForwardPass;var NewPass:TForwardPass);
// Обновляем аккумуляторы. Единая процедура для обновления обоих аккумуляторов.
var
   Piese,FromPiese,from,dest,capsq,rookfrom,rookdest,myrook,stm,WhiteFrameStartIndex,BlackFrameStartIndex : integer;
   AddwhiteIndex,RemwhiteIndex,AddblackIndex,RemblackIndex : integer;
begin
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
  WhiteFrameStartIndex:=GetWhiteFrameIndex(Net.model,Board);
  If WhiteFrameStartIndex<>Undo.WFrame  then FillWhiteAcc16(Net.model,Board,NewPass) else     // Пересчитываем весь аккумулятор с нуля если изменился индекс фрейма
    begin
      // Переставляем ходившую фигуру
      AddWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Piese,dest))*half;
      RemWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Frompiese,from))*half;
      // Для первого апдейта в виде источника  берем предыдущий аккумулятор
      AVX2_UPdFeauture(@OldPass.Acc16[white],@Net.Flayer[AddWhiteindex],@Net.Flayer[REMWhiteindex],@NewPass.Acc16[white]);
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
          AddWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(MyRook,rookdest))*half;
          RemWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(MyRook,rookfrom))*half;
          AVX2_UPdFeauture(@NewPass.Acc16[white],@Net.Flayer[AddWhiteindex],@Net.Flayer[REMWhiteindex],@NewPass.Acc16[white]);
        end else
      // Если было взятие (в том числе на проходе) - убираем побитую фигуру
      if ((move and CaptureFlag)<>0) then
        begin
          capsq:=dest;
          If Undo.isEnnPass then capsq:=capsq-PawnPush[stm];
          RemWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Board.CapturedPiese,capsq))*half;
          AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[RemWhiteIndex],@NewPass.Acc16[white]);
        end;
      // Если в результате хода поменялись права на рокировку (какая-то из сторон потеряла их) - обновляем
      if Undo.CastleRights<>Board.CastleRights then
        begin
          if (Undo.CastleRights and 1)<>(Board.CastleRights and 1) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[(WhiteFrameStartIndex+WShortCastle)*half],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 2)<>(Board.CastleRights and 2) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[(WhiteFrameStartIndex+WLongCastle)*half],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 4)<>(Board.CastleRights and 4) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[(WhiteFrameStartIndex+BShortCastle)*half],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 8)<>(Board.CastleRights and 8) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[(WhiteFrameStartIndex+BLongCastle)*half] ,@NewPass.Acc16[white]);
        end;
    end;
// Обновляем черный аккумулятор
  BlackFrameStartIndex:=GetBlackFrameIndex(Net.model,Board);
  If BlackFrameStartIndex<>Undo.BFrame then FillBlackAcc16(Net.model,Board,NewPass) else     // Пересчитываем весь аккумулятор с нуля если изменился индекс фрейма
    begin
      // Переставляем ходившую фигуру
      AddBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Piese,dest xor 56))*half;
      RemBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Frompiese,from xor 56))*half;
      // Для первого апдейта  в виже источника  берем предыдущий аккумулятор
      AVX2_UPdFeauture(@OldPass.Acc16[black],@Net.Flayer[AddBlackindex],@Net.Flayer[REMBlackindex],@NewPass.Acc16[black]);
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
          AddBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-MyRook,rookdest xor 56))*half;
          RemBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-MyRook,rookfrom xor 56))*half;
          AVX2_UPdFeauture(@NewPass.Acc16[black],@Net.Flayer[AddBlackindex],@Net.Flayer[REMBlackindex],@NewPass.Acc16[black]);
        end else
      // Если было взятие (в том числе на проходе) - убираем побитую фигуру
      if ((move and CaptureFlag)<>0) then
        begin
          capsq:=dest;
          If Undo.isEnnPass then capsq:=capsq-PawnPush[stm];
          RemBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Board.CapturedPiese,capsq xor 56))*half;
          AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[RemBlackIndex],@NewPass.Acc16[black]);
        end;
      // Если в результате хода поменялись права на рокировку (какая-то из сторон потеряла их) - обновляем
      if Undo.CastleRights<>Board.CastleRights then
        begin
          if (Undo.CastleRights and 1)<>(Board.CastleRights and 1) then AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[(BlackFrameStartIndex+BShortCastle)*half],@NewPass.Acc16[black]);
          if (Undo.CastleRights and 2)<>(Board.CastleRights and 2) then AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[(BlackFrameStartIndex+BLongCastle)*half],@NewPass.Acc16[black]);
          if (Undo.CastleRights and 4)<>(Board.CastleRights and 4) then AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[(BlackFrameStartIndex+WShortCastle)*half],@NewPass.Acc16[black]);
          if (Undo.CastleRights and 8)<>(Board.CastleRights and 8) then AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[(BlackFrameStartIndex+WLongCastle)*half] ,@NewPass.Acc16[black]);
        end;

    end;
end;
Procedure SlowCalcAcc(var Pass:TForwardPass;row:integer;framesize:integer);
var
   i,j,sumstm,sumsnon,cell : integer;
begin
 for j:=0 to half-1 do
  begin
   sumstm:=Net.Fbias[j];
   sumsnon:=Net.Fbias[j];
   for i:=0 to framesize-1 do
    begin
      cell:=row*(2*framesize+1)+i;
      sumstm:=sumstm+Net.FLayer[i*half+j]*Arr[cell];
      cell:=row*(2*framesize+1)+i+framesize;
      sumsnon:=sumsnon+Net.FLayer[i*half+j]*Arr[cell];
    end;
    Pass.Acc16[white,j]:=sumstm;
    Pass.Acc16[black,j]:=sumsnon;
  end;

end;
Procedure CheckBatch(filename : ansistring; batchsize : integer);
var
  i,res : integer;
  framesize,total,rowsize,evalrow : integer;
  proc,ss,dd : extended;
  f : TFileStream;
  Pass : TForwardPass;
begin
  writeln('Выделяем память под массив');
  framesize:=ModelFrameSize(Net.model);
  rowsize:=2*framesize+1;
  total:=rowsize*batchsize;
  writeln('Size of array - ',total,' integer');
  Setlength(arr,total);
  writeln('Array ready');
  f:=TFileStream.Create(filename+'.dat',fmOpenRead);
  res:=f.Read(arr[0],total*4);
  writeln('Array Loaded - ',res,' bytes');
  f.free;

  proc:=0;
  for i:=0 to batchsize-1 do
    begin
      SlowCalcAcc(Pass,i,framesize);
      evalrow:=ForwardPass(white,Pass);
      ss:=(evalrow/Net.scale_out)/Net.scale_act;
      dd:=arr[i*rowsize+rowsize-1]/1E9;
      //dd:=round(dd*1e8)/1e8;
      proc:=proc+abs(dd-ss);
      //writeln(i,' ',proc,' ',ss,' ',dd);
      //readln;
    end;
  writeln(proc);
  writeln(proc/batchsize);
end;

Procedure speedtest;
var
  t1,t2 : TDateTime;
  i : integer;
  f : file of TF;
begin
  for i:=0 to hidden1-1 do
    begin
     acc[i]:=3;
     inputrow[i]:=2;
    end;
 for i:=0 to hidden1*hidden2-1 do
    inputmatrix[i]:=2;
 for i:=0 to 63 do
    outputdata3[i]:=1;

 assign(f,'testacc.dat');
 reset(f);
 read(f,Threads[1].pass[1].acc16);
 close(f);


 //FillWhiteAcc16(net.model,Threads[1].Board,Threads[1].Pass[1]);
 //FillBlackAcc16(net.model,Threads[1].Board,Threads[1].Pass[1]);
 AVX2_RELU_ACC(@Threads[1].Pass[1].Acc16[white],@permut1,@Threads[1].Pass[1].Inputs8);
 AVX2_RELU_ACC(@Threads[1].Pass[1].Acc16[black],@permut1,@Threads[1].Pass[1].Inputs8[half]);
 AVX2_FirstLayer_Mul(@Threads[1].Pass[1].Inputs8,@Net.FirstLayer,@outputdata,@Threads[1].Pass[1].store);
 for i:=0 to 7 do
   writeln(outputdata[i]);
 writeln('------------------------------------');
 SlowFirstLayer(Threads[1].pass[1]);
 //AVX2_RELU_3(@outputdata,@outputdata,@RELUlimit,@outputdata2);
 //AVX2_SecondLayer_Mul(@outputdata2,@outputdata3,@outputdata);

 //PrintBoard(Threads[1].board);


t1:=now;
 for i:=1 to 1000000000 do
   begin
     //AVX2_RELU_ACC(@acc,@permut1,@inputrow); //5.94 for hidden1=512 (Half=256)
     //AVX2_RELU_ACC(@acc[half],@permut1,@inputrow[half]); //5.94 for hidden1=512 (Half=256)
       AVX2_FirstLayer_Mul(@Threads[1].Pass[1].Inputs8,@Net.FirstLayer,@outputdata,@Threads[1].Pass[1].store); //AVX2 - 56.74 for 512x8 ;AVX512 - 40.65 for 512x8
     //AVX2_RELU_2(@outputdata,@outputdata,@RELUlimit,@outputdata2); // 1.56 for 8; 3.56 for 32
     //AVX2_SecondLayer_Mul(@outputdata2,@outputdata3,@outputdata); // 6.3 for 8x8
     //AVX2_NNOut(@inputrow,@inputmatrix,@Ones512,@Net.outbias) // 1.84
     //AVX2_CopyAcc(@inputrow,@inputmatrix); //7.59 for AVX2, 6.4 for AVX512
     //AVX2_SetFeauture(@inputrow,@inputmatrix,@outputdata); // 8.64 for AVX2, 8.98 for AVX512
     //AVX2_DoubleSetFeauture(@inputrow,@inputmatrix,@inputmatrix,@outputdata); // 10.64 for AVX2, 8.25 for AVX512
     //AVX2_TripleSetFeauture(@inputrow,@inputmatrix,@outputdata,@outputdata2); // 12.54 for AVX2, 9.98 for AVX512
     //AVX2_ReSetFeauture(@inputrow,@inputmatrix,@outputdata); // 8.64 for AVX2, 7.25 for AVX512
     //AVX2_UpdFeauture(@inputrow,@inputmatrix,@inputmatrix,@outputdata); // 10.26 for AVX2, 8.76 for AVX512
     //FillWhiteAcc16(net.model,Threads[1].Board,Threads[1].Pass[1]); // AVX2-231  AVX512-222
   end;
t2:=now;
writeln((t2-t1)*86400:6:2);
end;

end.
