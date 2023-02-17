unit Unn;

interface
uses SysUtils,Classes,uBitBoards,uBoard,uAttacks,DateUtils;

Const
  current_version=4;  // что проверяем при загрузке сети
  hidden1=512;  // число нейронов в первом слое
  half=hidden1 div 2;
  // коэффициенты квантования берем из скрипта обучения
  scale_weight16=1;
  scale_weight8=64;
  // Макс предел 8 битового числа
  limit8=255;
  ones512 : array[0..63] of int16=(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
  Permut : array[0..7] of integer=(1,5,0,4,3,7,2,6);
  Permut1 : array[0..7] of integer=(0,1,4,5,2,3,6,7);
  ModelBlockSize=64*12+2+2; // С признаками рокировок в блоке

  PieseBlock:array[-King..King] of integer=(704,640,576,512,448,384,0,0,64,128,192,256,320);

  WShortCastle=768 shl 8;
  WLongCastle =769 shl 8;
  BShortCastle=770 shl 8;
  BLongCastle =771 shl 8;
  MaxFrameSize=ModelBlockSize;

Type
  TNeuralNetWeights =packed record
     model       : integer; //Модель нейросети
     scale_act   : real;
     scale_out   : integer;
     w1          : integer;
     w2          : integer;
     FLayer      : array[0..Half*MaxFrameSize-1] of int16;  //[ModelFrameSize,256]
     Fbias       : array[0..Half-1] of int16;
     FirstLayer  : array[0..Hidden1*32-1] of int8;
     biasFirst   : array[0..31] of integer;
     SecondLayer : array[0..32*32-1] of int8;
     biasSecond  : array[0..31] of integer;
     outlayer    : array[0..31] of int8;
     outbias     : integer;
     Sigma       : array[0..128*512] of integer;
     MaxSigma    : integer;
  end;

TForwardPass = packed record
     Acc16     : array[white..black,0..Half-1] of int16; // Структура для акумулятора 16 бит  с точки зрения хода белых и хода черных отдельно
     Inputs8   : array[0..Hidden1-1] of byte;
     TempFirst : array[0..31] of integer;  // результат после прохода первого слоя до RELU - 32 int32 элементов
     RELUFirst : array[0..31] of byte;     // результат первого слоя после RELU
     TempSecond: array[0..31] of integer;  // результат после прохода второго слоя до RELU 32 int32 элементов
     RELUSecond: array[0..31] of byte;     // результат второго слоя после RELU
     store     : array[0..11*16-1] of byte // хранилище для регистров
end;

var
   Net : TNeuralNetWeights;

Function loadnet(filename:string):boolean;
Function NetReSigma(y:integer):integer;
Function ForwardPass(SideToMove:integer;var Pass:TForwardPass):integer;
Procedure UpdAcc16(move:integer;var Board:Tboard;var Undo:Tundo;var OldPass:TForwardPass;var NewPass:TForwardPass);
Procedure CopyAcc16(var OldPass:TForwardPass;var NewPass:TForwardPass);
Function GetWhiteFrameIndex(model:integer;var Board:TBoard):integer;
Function GetBlackFrameIndex(model:integer;var Board:TBoard):integer;
Procedure FillWhiteAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
Procedure FillBlackAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
implementation
uses UMagic;

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
  if model=1 then res:=2*ModelBlockSize else     // Q-model
  if model=1 then res:=4*ModelBlockSize else     // QR-model
  if model=1 then res:=8*ModelBlockSize;         // QRM-model
  Result:=res;
end;
Procedure AVX2_FirstLayer_mul(inputs8,weights,Dest,store : Pbyte);   // 190
//                        rcx,     rdx,   r8,   r9
// Перемножаем матрицу [1x512] элементов  int8 на матрицу [512x32] елементов int8 используя SIMD AVX2
// На выходе матрица [1x32] int32 элементов
asm
  .noframe
 // сохраняем все регистры, необходимые для корректной работы Windows
     movdqu [r9],xmm5
     movdqu [r9+16],xmm6
     movdqu [r9+32],xmm7
     movdqu [r9+48],xmm8
     movdqu [r9+64],xmm9
     movdqu [r9+80],xmm10
     push r12
     push r13
     push r14
     push r15
    // Вектор единиц
     lea r10,Ones512;
     db 0c4h,41h,07eh,06fh,12h       // AVX vmovdqu ymm10,[r10]
     mov r10,4                       // счетчик  стобцов (обрабатываем по 8 столбцов за 1 проход цикла) 8*4=32
     // Сохраняем некоторые константы
     mov r11,rcx
     mov r14,512 // длина вектора (расстояние между столбцами)
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
     mov r13,16 // avx2 16*32=hidden1
     mov r12,rdx
     mov r15,rdx
 @@2:
     // Читаем очередной кусочек вектора
     db 0c5h,0feh,06fh,01h           // AVX   vmovdqu ymm0,[rcx]
     // Последовательно перемножаем его на соответствующий кусочек каждого из 8 обрабатываемых столбцов и суммируем с накопителем каждого столбца
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 1 столбца
     db 0c4h,0c1h,75h,0fdh,0c9h      // AVX2  vpaddw ymm1,ymm1,ymm9  - cуммируем с накопителем 1 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 2 столбца
     db 0c4h,0c1h,6dh,0fdh,0d1h      // AVX2  vpaddw ymm2,ymm2,ymm9  - cуммируем с накопителем 2 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 3 столбца
     db 0c4h,0c1h,65h,0fdh,0d9h      // AVX2  vpaddw ymm3,ymm3,ymm9  - cуммируем с накопителем 3 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 4 столбца
     db 0c4h,0c1h,5dh,0fdh,0e1h      // AVX2  vpaddw ymm4,ymm4,ymm9  - cуммируем с накопителем 4 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 5 столбца
     db 0c4h,0c1h,55h,0fdh,0e9h      // AVX2  vpaddw ymm5,ymm5,ymm9  - cуммируем с накопителем 5 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 6 столбца
     db 0c4h,0c1h,4dh,0fdh,0f1h      // AVX2  vpaddw ymm6,ymm6,ymm9  - cуммируем с накопителем 6 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 7 столбца
     db 0c4h,0c1h,45h,0fdh,0f9h      // AVX2  vpaddw ymm7,ymm7,ymm9  - cуммируем с накопителем 7 столбца
     add rdx,r14                     // Перескакиваем на соответствующий кусочек в следующий столбец
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 результат 8 столбца
     db 0c4h,041h,3dh,0fdh,0c1h      // AVX2  vpaddw ymm8,ymm8,ymm9  - cуммируем с накопителем 8 столбца
     // Крутим в цикле для всех 16 кусочков вектора и столбцов
     add rcx,32                      // Адрес следующего кусочка вектора
     mov rdx,r15
     add rdx,32                      // Адрес следующего кусочка 1 столбца
     mov r15,rdx
     // Крутим цикл кусочков
     sub r13,1
     jnz @@2
     // Посчитали накопители очередных 8 столбцов. Умножаем их на единичный вектор
     db 0c4h,0c1h,75h,0f5h,0cah       // AVX2 vpmaddwd ymm1,ymm1,ymm10
     db 0c4h,0c1h,6dh,0f5h,0d2h       // AVX2 vpmaddwd ymm2,ymm2,ymm10
     db 0c4h,0c1h,65h,0f5h,0dah       // AVX2 vpmaddwd ymm3,ymm3,ymm10
     db 0c4h,0c1h,5dh,0f5h,0e2h       // AVX2 vpmaddwd ymm4,ymm4,ymm10
     db 0c4h,0c1h,55h,0f5h,0eah       // AVX2 vpmaddwd ymm5,ymm5,ymm10
     db 0c4h,0c1h,4dh,0f5h,0f2h       // AVX2 vpmaddwd ymm6,ymm6,ymm10
     db 0c4h,0c1h,45h,0f5h,0fah       // AVX2 vpmaddwd ymm7,ymm7,ymm10
     db 0c4h,041h,3dh,0f5h,0c2h       // AVX2 vpmaddwd ymm8,ymm8,ymm10
    // Теперь горизонтально суммируем по 4 столбца и сохраняем результаты
     db 0c4h,0e2h,75h,02h,0c2h        // AVX2 vphaddd ymm0,ymm1,ymm2
     db 0c4h,062h,65h,02h,0cch        // AVX2 vphaddd ymm9,ymm3,ymm4
     db 0c4h,0c2h,7dh,02h,0c1h        // AVX2 vphaddd ymm0,ymm0,ymm9
    // Полученный вектор складываем пополам
     db 0c4h,0c3h,7dh,39h,0c1h,01     // AVX2 vextracti128 xmm9,ymm0,0x1
     db 66h,41h,0fh,0feh,0c1h         // SSE2 paddd xmm0,xmm9
     // сохраняем результат для первых четырех обработанных столбцов
     movdqu [r8],xmm0
     add r8,16
     db 0c4h,0e2h,55h,02h,0c6h        // AVX2 vphaddd ymm0,ymm5,ymm6
     db 0c4h,042h,45h,02h,0c8h        // AVX2 vphaddd ymm9,ymm7,ymm8
     db 0c4h,0c2h,7dh,02h,0c1h        // AVX2 vphaddd ymm0,ymm0,ymm9
    // Полученный вектор складываем пополам
     db 0c4h,0c3h,7dh,39h,0c1h,01     // AVX2 vextracti128 xmm9,ymm0,0x1
     db 66h,41h,0fh,0feh,0c1h         // SSE2 paddd xmm0,xmm9
     // сохраняем результат для вторых четырех обработанных столбцов
     movdqu [r8],xmm0
     add r8,16
     // Перемещаемся для обработки следущих восьми столбцов
     mov rcx,r11
     mov rdx,r12
     add rdx,4096  // 8x512
     sub r10,1
     jnz @@1
     // восстанавливаем регистры
     pop r15
     pop r14
     pop r13
     pop r12
     movdqu xmm10,[r9+80]
     movdqu xmm9,[r9+64]
     movdqu xmm8,[r9+48]
     movdqu xmm7,[r9+32]
     movdqu xmm6,[r9+16]
     movdqu xmm5,[r9]
end;

Procedure AVX2_SecondLayer_Mul(inprow,Matrix,dest : Pbyte);  //25,6 c
//                              rcx,   rdx,  r8
// Перемножает матрицу [1x32] элемента  int8 на матрицу [32x32] элемента int8 используя SIMD AVX2
// на выходе матрица [1x32] int32
asm
    .noframe
     mov r11,8                         // цикл столбцов
     // читаем строку improw [1,32]
     db 0c5h,0feh,6fh,01h               // AVX vmovdqu ymm0,[rcx]
     // Единичный столбец int16-константа
     lea r10,Ones512
     db 0c4h,0c1h,7eh,6fh,2ah           // AVX vmovdqu ymm5,[r10]
   // В цикле обрабатываем сразу по 4 стлобца
@@1:
     //1 столбец
     db 0c5h,0feh,6fh,0ah               // AVX vmovdqu ymm1,[rdx]
     db 0c4h,0e2h,7dh,04h,0c9h          // AVX2 vpmaddubsw ymm1,ymm0,ymm1
   // умножаем на единичный столбец и приводим к int32
     db 0c5h,0f5h,0f5h,0cdh             // AVX2 vpmaddwd ymm1,ymm1,ymm5
     //2 столбец
     db 48h,83h,0c2h,20h                // add rdx,20h
     db 0c5h,0feh,6fh,12h               // AVX vmovdqu ymm2,[rdx]
     db 0c4h,0e2h,7dh,04h,0d2h          // AVX2 vpmaddubsw ymm2,ymm0,ymm2
   // умножаем на единичный столбец и приводим к int32
     db 0c5h,0edh,0f5h,0d5h             // AVX2 vpmaddwd ymm2,ymm2,ymm5
     //3 столбец
     db 48h,83h,0c2h,20h                // add rdx,20h
     db 0c5h,0feh,6fh,1ah               // AVX vmovdqu ymm3,[rdx]
     db 0c4h,0e2h,7dh,04h,0dbh          // AVX2 vpmaddubsw ymm3,ymm0,ymm3
   // умножаем на единичный столбец и приводим к int32
     db 0c5h,0e5h,0f5h,0ddh             // AVX2 vpmaddwd ymm3,ymm3,ymm5
     //4 столбец
     db 48h,83h,0c2h,20h                // add rdx,20h
     db 0c5h,0feh,6fh,22h               // AVX vmovdqu ymm4,[rdx]
     db 0c4h,0e2h,7dh,04h,0e4h          // AVX2 vpmaddubsw ymm4,ymm0,ymm4
   // умножаем на единичный столбец и приводим к int32
     db 0c5h,0ddh,0f5h,0e5h             // AVX2 vpmaddwd ymm4,ymm4,ymm5
  /// Мы получили векторы для 4-х столбцов. Теперь горизонтально суммируем их, чтобы в итоге получить 4 32-разрядных результата
     db 0c4h,0e2h,75h,02h,0cah       // AVX2 vphaddd ymm1,ymm1,ymm2
     db 0c4h,0e2h,65h,02h,0dch       // AVX2 vphaddd ymm3,ymm3,ymm4
     db 0c4h,0e2h,75h,02h,0cbh       // AVX2 vphaddd ymm1,ymm1,ymm3
    // Полученный вектор складываем пополам
     db 0c4h,0e3h,7dh,39h,0cah,01 // AVX2 vextracti128 xmm2,ymm1,0x1
     db 66h,0fh,0feh,0cah         // SSE2 paddd xmm1,xmm2
     // сохраняем результат для очередных четырех обработанных столбцов
     movdqu [r8],xmm1
     add r8,16
     // крутим цикл
     add rdx,32
     sub r11,1
     jnz @@1
end;
Function AVX2_NNOut(Inprow,Matrix,Ones,Bias : Pbyte):integer; //1.65 c
//                   rcx,    rdx,  r8   r9
// Перемножает матрицу [1x32] элемента  int8 на матрицу [32x1] элемента int8 используя SIMD AVX2
// Дает int32 выход всей нейросети , используя bias последнего слоя и множитель квантования 1/64.
asm
    .noframe
   // Единичный столбец int16-константа
     db 0c4h,0c1h,7eh,6fh,18h           // AVX vmovdqu ymm3,[r8]
  // читаем строку improw [1,32]
     db 0c5h,0feh,6fh,01h               // AVX vmovdqu ymm0,[rcx]
  // читаем строку матрицы [32,1]
     db 0c5h,0feh,6fh,0Ah               // AVX vmovdqu ymm1,[rdx]
  //  перемножаем  int8
     db 0c4h,0e2h,7dh,04h,0c1h          // AVX2 vpmaddubsw ymm0,ymm0,ymm1
   // умножаем int16 на единичный столбец и приводим к int32
     db 0c5h,0fdh,0f5h,0c3h             // AVX2 vpmaddwd ymm0,ymm0,ymm3
  // Полученный 256 вектор int32  складываем пополам
     db 0c4h,0e3h,7dh,39h,0c1h,01       // AVX2 vextracti128 xmm1,ymm0,0x1
     db 66h,0fh,0feh,0c1h               // SSE2 paddd xmm0,xmm1
  // Горизонтально суммируем 4 элемента в xmm0
     db 66h,0fh,70h,0c8h,4eh            // SSE2 pshufd xmm1,xmm0,4eh
     db 66h,0fh,0feh,0c1h               // SSE2 paddd xmm0,xmm1
     db 0f2h,0fh,70h,0c8h,4eh           // SSE2 pshuflw xmm1,xmm0,4eh
     db 66h,0fh,0feh,0c1h               // SSE2 paddd xmm0,xmm1
  // Результат перемножения
     db 66h,0fh,7eh,0c0h                // movd eax,xmm0
  // Добавляем биас
     db 41h,03h,01h                     // add eax,DWORD ptr [r8]
end;
Procedure AVX2_RELU_64(Summs,Biases,Permut,Res : Pbyte);  //1,97c
//                      rcx,   rdx     r    r9
// Получая на вход строку из 32 выходов нейронов (int32)  + 32 биаса (int32) реализует RELU и  сжимает выход  до int8.Использует SIMD AVX2
asm
  .noframe
  // первые 8 int32 элементов
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // суммируем с первыми 8 биасами
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - результат 1
  // Следующие 8 int32 элементов
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // суммируем со вторыми  8 биасами
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - результат 2
  // Упаковываем все 2 результа по 8 int32 элемента в int16 представление (с сатурацией со знаком)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // множитель квантования (1/64)
  db 0c5h,0e5h,71h,0e0h,06             // AVX2 vpsraw ymm3,ymm0,06
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  // третьи 8 int32 элементов
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // суммируем с третьими 8 биасами
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - результат 3
  // четвертые 8 int32 элементов
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // суммируем с четвертыми  8 биасами
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - результат 4
  // Упаковываем все 2 результа по 8 int32 элемента в int16 представление (с сатурацией со знаком)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // множитель квантования (1/64)
  db 0c5h,0fdh,71h,0e0h,06h              // AVX2 vpsraw ymm0,ymm0,06
  // Теперь пакуем 16 int16 в  int8 (с сатурацией без знака ) + RELU
  db 0c5h,0e5h,67h,0c0h                  // AVX2 vpackuswb ymm0,ymm3,ymm0
  // Выравниваем данные и возвращаем результат
  db 0c4h,0c1h,7eh,6fh,08h               // AVX vmovdqu ymm1,[r8]
  db 0c4h,0e2h,75h,36h,0c0h              // AVX2 vpermd ymm0,ymm1,ymm0
  db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
end;
Procedure AVX2_RELU_128(Summs,Biases,Permut,Res : Pbyte);  //1,97c
//                      rcx,   rdx     r    r9
// Получая на вход строку из 32 выходов нейронов (int32)  + 32 биаса (int32) реализует RELU и  сжимает выход  до int8.Использует SIMD AVX2
asm
  .noframe
  // первые 8 int32 элементов
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // суммируем с первыми 8 биасами
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - результат 1
  // Следующие 8 int32 элементов
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // суммируем со вторыми  8 биасами
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - результат 2
  // Упаковываем все 2 результа по 8 int32 элемента в int16 представление (с сатурацией со знаком)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // множитель квантования (1/128)
  db 0c5h,0e5h,71h,0e0h,07             // AVX2 vpsraw ymm3,ymm0,07
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  // третьи 8 int32 элементов
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // суммируем с третьими 8 биасами
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - результат 3
  // четвертые 8 int32 элементов
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // суммируем с четвертыми  8 биасами
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - результат 4
  // Упаковываем все 2 результа по 8 int32 элемента в int16 представление (с сатурацией со знаком)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // множитель квантования (1/128)
  db 0c5h,0fdh,71h,0e0h,07h              // AVX2 vpsraw ymm0,ymm0,07
  // Теперь пакуем 16 int16 в  int8 (с сатурацией без знака ) + RELU
  db 0c5h,0e5h,67h,0c0h                  // AVX2 vpackuswb ymm0,ymm3,ymm0
  // Выравниваем данные и возвращаем результат
  db 0c4h,0c1h,7eh,6fh,08h               // AVX vmovdqu ymm1,[r8]
  db 0c4h,0e2h,75h,36h,0c0h              // AVX2 vpermd ymm0,ymm1,ymm0
  db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
end;
Procedure AVX2_RELU_256(Summs,Biases,Permut,Res : Pbyte);  //1,97c
//                      rcx,   rdx     r    r9
// Получая на вход строку из 32 выходов нейронов (int32)  + 32 биаса (int32) реализует RELU и  сжимает выход  до int8.Использует SIMD AVX2
asm
  .noframe
  // первые 8 int32 элементов
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // суммируем с первыми 8 биасами
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - результат 1
  // Следующие 8 int32 элементов
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // суммируем со вторыми  8 биасами
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - результат 2
  // Упаковываем все 2 результа по 8 int32 элемента в int16 представление (с сатурацией со знаком)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // множитель квантования (1/256)
  db 0c5h,0e5h,71h,0e0h,08             // AVX2 vpsraw ymm3,ymm0,08
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  // третьи 8 int32 элементов
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // суммируем с третьими 8 биасами
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - результат 3
  // четвертые 8 int32 элементов
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // суммируем с четвертыми  8 биасами
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - результат 4
  // Упаковываем все 2 результа по 8 int32 элемента в int16 представление (с сатурацией со знаком)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // множитель квантования (1/256)
  db 0c5h,0fdh,71h,0e0h,08h              // AVX2 vpsraw ymm0,ymm0,08
  // Теперь пакуем 16 int16 в  int8 (с сатурацией без знака ) + RELU
  db 0c5h,0e5h,67h,0c0h                  // AVX2 vpackuswb ymm0,ymm3,ymm0
  // Выравниваем данные и возвращаем результат
  db 0c4h,0c1h,7eh,6fh,08h               // AVX vmovdqu ymm1,[r8]
  db 0c4h,0e2h,75h,36h,0c0h              // AVX2 vpermd ymm0,ymm1,ymm0
  db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
end;
Procedure AVX2_RELU_ACC(Acc16,Permut,Dest : Pbyte); // 10c  на 512
//                       rcx,  rdx    r8
// Получая на вход   аккумулятор за выбранный цвет (256 элементов int16) реализует RELU и  сжимает выход  до int8.Использует SIMD AVX2
asm
  .noframe
  // Карта перемешивания элементов
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  mov r10,8                              // счетчик 8*(16+16)=256
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
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 49h,83h,0c0h,20h                    // add r8, 20h
  // Крутим цикл
  sub r10,1
  jnz @@1
end;


Procedure AVX2_CopyAcc(Source,Dest : Pbyte);
//                       rcx,  rdx
// Копирует int16 аккумулятор за 1 цвет.  Сохраняет по адресу  DEST ( может совпадать с SOURCE)
asm
  .noframe
   mov r10,16                              // счетчик   16*16=256
@@1:
   // читаем строку источника (16 элементов int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
    // Сохраняем обновленные данные
    db 0c5h,0feh,7fh,02h                    // AVX vmovdqu [rdx],ymm0
    // Следующие 16 int16 элементов
    db 48h,83h,0c1h,20h                    // add rcx,20h
    db 48h,83h,0c2h,20h                    // add rdx,20h
    // Крутим цикл
    sub r10,1
    jnz @@1
end;
Procedure AVX2_SetFeauture(Source,NetIndex,Dest : Pbyte);  //8,21 c
//                          rcx,    rdx,    r8
// Обновляет (устанавливает фичу) int16 аккумулятора за 1 цвет.  Сохраняет по адресу  DEST ( может совпадать с SOURCE)
asm
  .noframe
   mov r10,16                               // счетчик  16*16=256
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
    db 48h,83h,0c1h,20h                    // add rcx,20h
    db 48h,83h,0c2h,20h                    // add rdx,20h
    db 49h,83h,0c0h,20h                    // add r8, 20h
    // Крутим цикл
    sub r10,1
    jnz @@1
end;
Procedure AVX2_ReSetFeauture(Source,NetIndex,Dest : Pbyte); // 8,21 c
//                          rcx,    rdx,    r8
// Обновляет (убирает фичу)  int16 аккумулятора за 1 цвет. Сохраняет по адресу  DEST ( может совпадать с SOURCE)
asm
  .noframe
   mov r10,16                              // счетчик  16*16=256
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
    db 48h,83h,0c1h,20h                    // add rcx,20h
    db 48h,83h,0c2h,20h                    // add rdx,20h
    db 49h,83h,0c0h,20h                    // add r8, 20h
    // Крутим цикл
    sub r10,1
    jnz @@1
end;
Procedure AVX2_UpdFeauture(Source,NetIndexAdd,NetIndexSUB,Dest : Pbyte);   //11,37 c
//                          rcx,    rdx,         r8        r9
// Обновляет (добавляет + убирает фичи) половину int16 аккумулятора (за 1 цвет). На входе адрес источника половинки аккумулятора int16 и начальный адрес нужной фичи в сетке int16. Сохраняет половинку аккумулятора по адресу  DEST ( может совпадать с SOURCE)
asm
  .noframe
   mov r10,16                              // счетчик  16*16=256
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
    db 48h,83h,0c1h,20h                    // add rcx,20h
    db 48h,83h,0c2h,20h                    // add rdx,20h
    db 49h,83h,0c0h,20h                    // add r8, 20h
    db 49h,83h,0c1h,20h                    // add r9, 20h
    // Крутим цикл
    sub r10,1
    jnz @@1
end;
Function ForwardPass(SideToMove:integer;var Pass:TForwardPass):integer; //312c на 512
// Проход по нейросети. На входе загруженная сеть, очередь хода и структура аккумулятора, на выходе - Оценка позции
begin
  //в зависимости от очереди хода расставляем аккумуляторы в нужном порядке
  AVX2_RELU_ACC(@Pass.Acc16[SideToMove],@permut1,@Pass.Inputs8);
  AVX2_RELU_ACC(@Pass.Acc16[SideToMove xor 1],@permut1,@Pass.Inputs8[half]);
  //1
  AVX2_FirstLayer_Mul(@Pass.Inputs8,@Net.FirstLayer,@Pass.TempFirst,@Pass.store);
  if Net.w1=128
      then AVX2_RELU_128(@Pass.TempFirst,@Net.biasFirst,@permut,@Pass.RELUFirst)
      else AVX2_RELU_64(@Pass.TempFirst,@Net.biasFirst,@permut,@Pass.RELUFirst);
  //2
  AVX2_SecondLayer_Mul(@Pass.RELUFirst,@Net.SecondLayer,@Pass.TempSecond);
  if Net.w2=128
     then AVX2_RELU_128(@Pass.TempSecond,@Net.biasSecond,@permut,@Pass.RELUSecond)
     else AVX2_RELU_64(@Pass.TempSecond,@Net.biasSecond,@permut,@Pass.RELUSecond);
  // output
  Result:=NetReSigma(AVX2_NNOut(@Pass.RELUSecond,@Net.outlayer,@Ones512,@Net.outbias));
end;

Function loadnet(filename:string):boolean;
var
  res,w,size,i,j : integer;
  ver   : int16;
  f   :TFileStream;
begin
  Result:=false;
  // Открываем файл и проверяем верисю нейросети
  f:=TFileStream.Create(filename,fmOpenRead);
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
  size:=size*half*2;
  // Считываем Flayer weights int16
  res:=f.Read(Net.Flayer,size);
  if res<>size then
    begin
     Writeln('Cant read Flayer weights!');
     exit;
    end;

  // Считываем FirstLayer weights int8
  res:=f.Read(Net.FirstLayer,hidden1*32);
  if res<>hidden1*32 then
    begin
     Writeln('Cant read a FirstLayer weights!');
     exit;
    end;
  // Считываем SecondLayer weights int8
  res:=f.Read(Net.SecondLayer,32*32);
  if res<>32*32 then
    begin
     Writeln('Cant read a SecondLayer weights!');
     exit;
    end;
  // Считываем OutLayer weights int8
  res:=f.Read(Net.outlayer,32);
  if res<>32 then
    begin
     Writeln('Cant read a OutLayer weights!');
     exit;
    end;
  // Считываем Flayer biases int16
  res:=f.Read(Net.Fbias,half*2);
  if res<>half*2 then
    begin
     Writeln('Cant read a Flayer biases!');
     exit;
    end;
  // Считываем FirstLayer biases int32
  res:=f.Read(Net.biasFirst,4*32);
  if res<>4*32 then
    begin
     Writeln('Cant read a FirstLayer biases!');
     exit;
    end;
  // Считываем SecondLayer biases int32
  res:=f.Read(Net.biasSecond,4*32);
  if res<>4*32 then
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
  Net.MaxSigma:=j;
  for i:=0 to j do
    begin
      Net.Sigma[i]:=ReSigma((i/Net.scale_out)/Net.scale_act);
    end;
  f.Free;
 // writeln('NET Version - ',ver);
 // writeln('Scale_act = ',Net.scale_act:6:2);
 // writeln('w1 = ',Net.w1);
 // writeln('w2 = ',Net.w2);
 // writeln('Scale_out = ',Net.scale_out);
//  writeln('Model -',Net.model);
  Result:=True;
end;

Function GetBlockIndex(Piese:integer;sq:integer):integer;
// Вычисляет индекс положения фигуры на доске. На входе - фигура любого цвета и поле, которое она занимает, на выходе - индекс внутри блока
begin
  Result:=PieseBlock[Piese]+sq;
end;

Procedure SetPiesesWhiteAcc(WhiteFrameStartIndex:integer;Piese:integer;var Board:TBoard;var Pass:TForwardPass);
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
      Whiteindex:=(WhiteFrameStartIndex+GetBlockIndex(P,sq)) shl 8;
      AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[Whiteindex],@Pass.Acc16[white]);
    end;
end;
Procedure SetPiesesBlackAcc(BlackFrameStartIndex:integer;Piese:integer;var Board:TBoard;var Pass:TForwardPass);
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
      Blackindex:=(BlackFrameStartIndex+GetBlockIndex(-P,sq xor 56)) shl 8;
      AVX2_SetFeauture(@Pass.Acc16[black],@Net.Flayer[Blackindex],@Pass.Acc16[black]);
    end;
end;
Function GetWhiteFrameIndex(model:integer;var Board:TBoard):integer;
// В зависимости от выбранной модели нейросети и положения на доске возвращает начальный индекс белого фрейма.
var
  res,ind:integer;
begin
  res:=0;
  If model=0 then res:=0 else   // Zero-model
  If model=1 then
   begin
    ind:=0;
    if (Board.Pieses[queen] and Board.Occupancy[white])<>0 then ind:=ind+1;   // Q-model
    res:=ind*ModelBlockSize;
   end else
  If model=2 then
   begin
    ind:=0;
    if (Board.Pieses[queen] and Board.Occupancy[white])<>0 then ind:=ind+2;   // QR-model
    if (Board.Pieses[rook] and Board.Occupancy[white])<>0 then ind:=ind+1;
    res:=ind*ModelBlockSize;
   end else
  If model=3 then
   begin
    ind:=0;
    if (Board.Pieses[queen] and Board.Occupancy[white])<>0 then ind:=ind+4;   // QRM-model
    if (Board.Pieses[rook] and Board.Occupancy[white])<>0 then ind:=ind+2;
    if ((Board.Pieses[bishop] or Board.Pieses[knight]) and Board.Occupancy[white])<>0 then ind:=ind+1;
    res:=ind*ModelBlockSize;
   end;
  Result:=res;
end;
Function GetBlackFrameIndex(model:integer;var Board:TBoard):integer;
// В зависимости от выбранной модели нейросети и положения на доске возвращает начальный индекс черного фрейма.
var
  res,ind:integer;
begin
  res:=0;
  If model=0 then res:=0 else   // Zero-model
  If model=1 then
   begin
    ind:=0;
    if (Board.Pieses[queen] and Board.Occupancy[black])<>0 then ind:=ind+1;   // Q-model
    res:=ind*ModelBlockSize;
   end else
  If model=2 then
   begin
    ind:=0;
    if (Board.Pieses[queen] and Board.Occupancy[black])<>0 then ind:=ind+2;   // QR-model
    if (Board.Pieses[rook] and Board.Occupancy[black])<>0 then ind:=ind+1;
    res:=ind*ModelBlockSize;
   end else
  If model=3 then
   begin
    ind:=0;
    if (Board.Pieses[queen] and Board.Occupancy[black])<>0 then ind:=ind+4;   // QRM-model
    if (Board.Pieses[rook] and Board.Occupancy[black])<>0 then ind:=ind+2;
    if ((Board.Pieses[bishop] or Board.Pieses[knight]) and Board.Occupancy[black])<>0 then ind:=ind+1;
    res:=ind*ModelBlockSize;
   end;
  Result:=res;
end;
Procedure FillWhiteAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
// Заполняет структуру белого аккумулятора  по позиции на доске
var
  sq,Whiteindex,WhiteFrameStartIndex : integer;
begin
  WhiteFrameStartIndex:=GetWhiteFrameIndex(model,Board);
  // Устанавливаем белого короля
  sq:=Board.KingSq[white];
  Whiteindex:=(WhiteFrameStartIndex+GetBlockIndex(King,sq)) shl 8;
  // Для первой устанавливаемой фигуры в качестве источника берем биасы
  AVX2_SetFeauture(@Net.Fbias,@Net.Flayer[Whiteindex],@Pass.Acc16[white]);
 // Устанавливаем черного короля
  sq:=Board.KingSq[black];
  Whiteindex:=(WhiteFrameStartIndex+GetBlockIndex(-King,sq)) shl 8;
  AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[Whiteindex],@Pass.Acc16[white]);
  //  Теперь устанавливаем фигуры
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Queen,Board,Pass);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Rook,Board,Pass);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Bishop,Board,Pass);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Knight,Board,Pass);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Pawn,Board,Pass);
  // Устанавливаем рокировки
  If (Board.CastleRights and 1)<>0 then AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[WShortCastle],@Pass.Acc16[white]);
  If (Board.CastleRights and 2)<>0 then AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[WLongCastle] ,@Pass.Acc16[white]);
  If (Board.CastleRights and 4)<>0 then AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[BShortCastle],@Pass.Acc16[white]);
  If (Board.CastleRights and 8)<>0 then AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[BLongCastle] ,@Pass.Acc16[white]);
end;
Procedure FillBlackAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
// Заполняет структуру черного аккумулятора  по позиции на доске
var
  sq,Blackindex,BlackFrameStartIndex : integer;
begin
  BlackFrameStartIndex:=GetBlackFrameIndex(model,Board);
  // Устанавливаем белого короля
  sq:=Board.KingSq[white] xor 56;
  Blackindex:=(BlackFrameStartIndex+GetBlockIndex(-King,sq)) shl 8;
  // Для первой устанавливаемой фигуры в качестве источника берем биасы
  AVX2_SetFeauture(@Net.Fbias,@Net.Flayer[Blackindex],@Pass.Acc16[black]);
 // Устанавливаем черного короля
  sq:=Board.KingSq[black] xor 56;
  Blackindex:=(BlackFrameStartIndex+GetBlockIndex(King,sq)) shl 8;
  AVX2_SetFeauture(@Pass.Acc16[black],@Net.Flayer[Blackindex],@Pass.Acc16[black]);
  //  Теперь устанавливаем фигуры
  SetPiesesBlackAcc(BlackFrameStartIndex,Queen,Board,Pass);
  SetPiesesBlackAcc(BlackFrameStartIndex,Rook,Board,Pass);
  SetPiesesBlackAcc(BlackFrameStartIndex,Bishop,Board,Pass);
  SetPiesesBlackAcc(BlackFrameStartIndex,Knight,Board,Pass);
  SetPiesesBlackAcc(BlackFrameStartIndex,Pawn,Board,Pass);
  // Устанавливаем рокировки
  If (Board.CastleRights and 1)<>0 then AVX2_SetFeauture(@Pass.Acc16[black],@Net.Flayer[BShortCastle],@Pass.Acc16[black]);
  If (Board.CastleRights and 2)<>0 then AVX2_SetFeauture(@Pass.Acc16[black],@Net.Flayer[BLongCastle] ,@Pass.Acc16[black]);
  If (Board.CastleRights and 4)<>0 then AVX2_SetFeauture(@Pass.Acc16[black],@Net.Flayer[WShortCastle],@Pass.Acc16[black]);
  If (Board.CastleRights and 8)<>0 then AVX2_SetFeauture(@Pass.Acc16[black],@Net.Flayer[WLongCastle] ,@Pass.Acc16[black]);
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
  If WhiteFrameStartIndex<>Undo.WFrame then FillWhiteAcc16(Net.model,Board,NewPass) else     // Пересчитываем весь аккумулятор с нуля если изменился индекс фрейма
    begin
      // Переставляем ходившую фигуру
      AddWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Piese,dest)) shl 8;
      RemWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Frompiese,from)) shl 8;
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
          AddWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(MyRook,rookdest)) shl 8;
          RemWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(MyRook,rookfrom)) shl 8;
          AVX2_UPdFeauture(@NewPass.Acc16[white],@Net.Flayer[AddWhiteindex],@Net.Flayer[REMWhiteindex],@NewPass.Acc16[white]);
        end else
      // Если было взятие (в том числе на проходе) - убираем побитую фигуру
      if ((move and CaptureFlag)<>0) then
        begin
          capsq:=dest;
          If Undo.isEnnPass then capsq:=capsq-PawnPush[stm];
          RemWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Board.CapturedPiese,capsq)) shl 8;
          AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[RemWhiteIndex],@NewPass.Acc16[white]);
        end;
      // Если в результате хода поменялись права на рокировку (какая-то из сторон потеряла их) - обновляем
      if Undo.CastleRights<>Board.CastleRights then
        begin
          if (Undo.CastleRights and 1)<>(Board.CastleRights and 1) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[WShortCastle],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 2)<>(Board.CastleRights and 2) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[WLongCastle ],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 4)<>(Board.CastleRights and 4) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[BShortCastle],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 8)<>(Board.CastleRights and 8) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[BLongCastle] ,@NewPass.Acc16[white]);
        end;
    end;
// Обновляем черный аккумулятор
  BlackFrameStartIndex:=GetBlackFrameIndex(Net.model,Board);
  If BlackFrameStartIndex<>Undo.BFrame then FillBlackAcc16(Net.model,Board,NewPass) else     // Пересчитываем весь аккумулятор с нуля если изменился индекс фрейма
    begin
      // Переставляем ходившую фигуру
      AddBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Piese,dest xor 56)) shl 8;
      RemBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Frompiese,from xor 56)) shl 8;
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
          AddBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-MyRook,rookdest xor 56)) shl 8;
          RemBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-MyRook,rookfrom xor 56)) shl 8;
          AVX2_UPdFeauture(@NewPass.Acc16[black],@Net.Flayer[AddBlackindex],@Net.Flayer[REMBlackindex],@NewPass.Acc16[black]);
        end else
      // Если было взятие (в том числе на проходе) - убираем побитую фигуру
      if ((move and CaptureFlag)<>0) then
        begin
          capsq:=dest;
          If Undo.isEnnPass then capsq:=capsq-PawnPush[stm];
          RemBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Board.CapturedPiese,capsq xor 56)) shl 8;
          AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[RemBlackIndex],@NewPass.Acc16[black]);
        end;
      // Если в результате хода поменялись права на рокировку (какая-то из сторон потеряла их) - обновляем
      if Undo.CastleRights<>Board.CastleRights then
        begin
          if (Undo.CastleRights and 1)<>(Board.CastleRights and 1) then AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[BShortCastle],@NewPass.Acc16[black]);
          if (Undo.CastleRights and 2)<>(Board.CastleRights and 2) then AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[BLongCastle ],@NewPass.Acc16[black]);
          if (Undo.CastleRights and 4)<>(Board.CastleRights and 4) then AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[WShortCastle],@NewPass.Acc16[black]);
          if (Undo.CastleRights and 8)<>(Board.CastleRights and 8) then AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[WLongCastle] ,@NewPass.Acc16[black]);
        end;
    end;
end;
end.
