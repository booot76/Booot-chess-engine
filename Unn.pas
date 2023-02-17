unit Unn;

interface
uses SysUtils,Classes,uBitBoards,uBoard,uAttacks,DateUtils;

Const
  current_version=4;  // ��� ��������� ��� �������� ����
  hidden1=512;  // ����� �������� � ������ ����
  half=hidden1 div 2;
  // ������������ ����������� ����� �� ������� ��������
  scale_weight16=1;
  scale_weight8=64;
  // ���� ������ 8 �������� �����
  limit8=255;
  ones512 : array[0..63] of int16=(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1);
  Permut : array[0..7] of integer=(1,5,0,4,3,7,2,6);
  Permut1 : array[0..7] of integer=(0,1,4,5,2,3,6,7);
  ModelBlockSize=64*12+2+2; // � ���������� ��������� � �����

  PieseBlock:array[-King..King] of integer=(704,640,576,512,448,384,0,0,64,128,192,256,320);

  WShortCastle=768 shl 8;
  WLongCastle =769 shl 8;
  BShortCastle=770 shl 8;
  BLongCastle =771 shl 8;
  MaxFrameSize=ModelBlockSize;

Type
  TNeuralNetWeights =packed record
     model       : integer; //������ ���������
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
     Acc16     : array[white..black,0..Half-1] of int16; // ��������� ��� ����������� 16 ���  � ����� ������ ���� ����� � ���� ������ ��������
     Inputs8   : array[0..Hidden1-1] of byte;
     TempFirst : array[0..31] of integer;  // ��������� ����� ������� ������� ���� �� RELU - 32 int32 ���������
     RELUFirst : array[0..31] of byte;     // ��������� ������� ���� ����� RELU
     TempSecond: array[0..31] of integer;  // ��������� ����� ������� ������� ���� �� RELU 32 int32 ���������
     RELUSecond: array[0..31] of byte;     // ��������� ������� ���� ����� RELU
     store     : array[0..11*16-1] of byte // ��������� ��� ���������
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
// �� �������� ����������� [0..1] ��������������� ������ �������
begin
  If y<0.001 then y:=0.001;
  if y>0.999 then y:=0.999;
  result:=round(-400*ln((1/y)-1));
end;
Function NetReSigma(y:integer):integer;
// ������� ����� �������� ������ �� ������ ������ �� ���������
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
// ����������� ������� [1x512] ���������  int8 �� ������� [512x32] ��������� int8 ��������� SIMD AVX2
// �� ������ ������� [1x32] int32 ���������
asm
  .noframe
 // ��������� ��� ��������, ����������� ��� ���������� ������ Windows
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
    // ������ ������
     lea r10,Ones512;
     db 0c4h,41h,07eh,06fh,12h       // AVX vmovdqu ymm10,[r10]
     mov r10,4                       // �������  ������� (������������ �� 8 �������� �� 1 ������ �����) 8*4=32
     // ��������� ��������� ���������
     mov r11,rcx
     mov r14,512 // ����� ������� (���������� ����� ���������)
 @@1:
     // �������� ���������� ��� ���� 8 �������������� ��������
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
     // ������ ��������� ������� �������
     db 0c5h,0feh,06fh,01h           // AVX   vmovdqu ymm0,[rcx]
     // ��������������� ����������� ��� �� ��������������� ������� ������� �� 8 �������������� �������� � ��������� � ����������� ������� �������
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 ��������� 1 �������
     db 0c4h,0c1h,75h,0fdh,0c9h      // AVX2  vpaddw ymm1,ymm1,ymm9  - c�������� � ����������� 1 �������
     add rdx,r14                     // ������������� �� ��������������� ������� � ��������� �������
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 ��������� 2 �������
     db 0c4h,0c1h,6dh,0fdh,0d1h      // AVX2  vpaddw ymm2,ymm2,ymm9  - c�������� � ����������� 2 �������
     add rdx,r14                     // ������������� �� ��������������� ������� � ��������� �������
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 ��������� 3 �������
     db 0c4h,0c1h,65h,0fdh,0d9h      // AVX2  vpaddw ymm3,ymm3,ymm9  - c�������� � ����������� 3 �������
     add rdx,r14                     // ������������� �� ��������������� ������� � ��������� �������
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 ��������� 4 �������
     db 0c4h,0c1h,5dh,0fdh,0e1h      // AVX2  vpaddw ymm4,ymm4,ymm9  - c�������� � ����������� 4 �������
     add rdx,r14                     // ������������� �� ��������������� ������� � ��������� �������
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 ��������� 5 �������
     db 0c4h,0c1h,55h,0fdh,0e9h      // AVX2  vpaddw ymm5,ymm5,ymm9  - c�������� � ����������� 5 �������
     add rdx,r14                     // ������������� �� ��������������� ������� � ��������� �������
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 ��������� 6 �������
     db 0c4h,0c1h,4dh,0fdh,0f1h      // AVX2  vpaddw ymm6,ymm6,ymm9  - c�������� � ����������� 6 �������
     add rdx,r14                     // ������������� �� ��������������� ������� � ��������� �������
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 ��������� 7 �������
     db 0c4h,0c1h,45h,0fdh,0f9h      // AVX2  vpaddw ymm7,ymm7,ymm9  - c�������� � ����������� 7 �������
     add rdx,r14                     // ������������� �� ��������������� ������� � ��������� �������
     db 0c5h,07eh,06fh,0Ah           // AVX   vmovdqu ymm9,[rdx]
     db 0c4h,042h,7dh,04h,0c9h       // AVX2  vpmaddubsw ymm9,ymm0,ymm9  - int16 ��������� 8 �������
     db 0c4h,041h,3dh,0fdh,0c1h      // AVX2  vpaddw ymm8,ymm8,ymm9  - c�������� � ����������� 8 �������
     // ������ � ����� ��� ���� 16 �������� ������� � ��������
     add rcx,32                      // ����� ���������� ������� �������
     mov rdx,r15
     add rdx,32                      // ����� ���������� ������� 1 �������
     mov r15,rdx
     // ������ ���� ��������
     sub r13,1
     jnz @@2
     // ��������� ���������� ��������� 8 ��������. �������� �� �� ��������� ������
     db 0c4h,0c1h,75h,0f5h,0cah       // AVX2 vpmaddwd ymm1,ymm1,ymm10
     db 0c4h,0c1h,6dh,0f5h,0d2h       // AVX2 vpmaddwd ymm2,ymm2,ymm10
     db 0c4h,0c1h,65h,0f5h,0dah       // AVX2 vpmaddwd ymm3,ymm3,ymm10
     db 0c4h,0c1h,5dh,0f5h,0e2h       // AVX2 vpmaddwd ymm4,ymm4,ymm10
     db 0c4h,0c1h,55h,0f5h,0eah       // AVX2 vpmaddwd ymm5,ymm5,ymm10
     db 0c4h,0c1h,4dh,0f5h,0f2h       // AVX2 vpmaddwd ymm6,ymm6,ymm10
     db 0c4h,0c1h,45h,0f5h,0fah       // AVX2 vpmaddwd ymm7,ymm7,ymm10
     db 0c4h,041h,3dh,0f5h,0c2h       // AVX2 vpmaddwd ymm8,ymm8,ymm10
    // ������ ������������� ��������� �� 4 ������� � ��������� ����������
     db 0c4h,0e2h,75h,02h,0c2h        // AVX2 vphaddd ymm0,ymm1,ymm2
     db 0c4h,062h,65h,02h,0cch        // AVX2 vphaddd ymm9,ymm3,ymm4
     db 0c4h,0c2h,7dh,02h,0c1h        // AVX2 vphaddd ymm0,ymm0,ymm9
    // ���������� ������ ���������� �������
     db 0c4h,0c3h,7dh,39h,0c1h,01     // AVX2 vextracti128 xmm9,ymm0,0x1
     db 66h,41h,0fh,0feh,0c1h         // SSE2 paddd xmm0,xmm9
     // ��������� ��������� ��� ������ ������� ������������ ��������
     movdqu [r8],xmm0
     add r8,16
     db 0c4h,0e2h,55h,02h,0c6h        // AVX2 vphaddd ymm0,ymm5,ymm6
     db 0c4h,042h,45h,02h,0c8h        // AVX2 vphaddd ymm9,ymm7,ymm8
     db 0c4h,0c2h,7dh,02h,0c1h        // AVX2 vphaddd ymm0,ymm0,ymm9
    // ���������� ������ ���������� �������
     db 0c4h,0c3h,7dh,39h,0c1h,01     // AVX2 vextracti128 xmm9,ymm0,0x1
     db 66h,41h,0fh,0feh,0c1h         // SSE2 paddd xmm0,xmm9
     // ��������� ��������� ��� ������ ������� ������������ ��������
     movdqu [r8],xmm0
     add r8,16
     // ������������ ��� ��������� �������� ������ ��������
     mov rcx,r11
     mov rdx,r12
     add rdx,4096  // 8x512
     sub r10,1
     jnz @@1
     // ��������������� ��������
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
// ����������� ������� [1x32] ��������  int8 �� ������� [32x32] �������� int8 ��������� SIMD AVX2
// �� ������ ������� [1x32] int32
asm
    .noframe
     mov r11,8                         // ���� ��������
     // ������ ������ improw [1,32]
     db 0c5h,0feh,6fh,01h               // AVX vmovdqu ymm0,[rcx]
     // ��������� ������� int16-���������
     lea r10,Ones512
     db 0c4h,0c1h,7eh,6fh,2ah           // AVX vmovdqu ymm5,[r10]
   // � ����� ������������ ����� �� 4 �������
@@1:
     //1 �������
     db 0c5h,0feh,6fh,0ah               // AVX vmovdqu ymm1,[rdx]
     db 0c4h,0e2h,7dh,04h,0c9h          // AVX2 vpmaddubsw ymm1,ymm0,ymm1
   // �������� �� ��������� ������� � �������� � int32
     db 0c5h,0f5h,0f5h,0cdh             // AVX2 vpmaddwd ymm1,ymm1,ymm5
     //2 �������
     db 48h,83h,0c2h,20h                // add rdx,20h
     db 0c5h,0feh,6fh,12h               // AVX vmovdqu ymm2,[rdx]
     db 0c4h,0e2h,7dh,04h,0d2h          // AVX2 vpmaddubsw ymm2,ymm0,ymm2
   // �������� �� ��������� ������� � �������� � int32
     db 0c5h,0edh,0f5h,0d5h             // AVX2 vpmaddwd ymm2,ymm2,ymm5
     //3 �������
     db 48h,83h,0c2h,20h                // add rdx,20h
     db 0c5h,0feh,6fh,1ah               // AVX vmovdqu ymm3,[rdx]
     db 0c4h,0e2h,7dh,04h,0dbh          // AVX2 vpmaddubsw ymm3,ymm0,ymm3
   // �������� �� ��������� ������� � �������� � int32
     db 0c5h,0e5h,0f5h,0ddh             // AVX2 vpmaddwd ymm3,ymm3,ymm5
     //4 �������
     db 48h,83h,0c2h,20h                // add rdx,20h
     db 0c5h,0feh,6fh,22h               // AVX vmovdqu ymm4,[rdx]
     db 0c4h,0e2h,7dh,04h,0e4h          // AVX2 vpmaddubsw ymm4,ymm0,ymm4
   // �������� �� ��������� ������� � �������� � int32
     db 0c5h,0ddh,0f5h,0e5h             // AVX2 vpmaddwd ymm4,ymm4,ymm5
  /// �� �������� ������� ��� 4-� ��������. ������ ������������� ��������� ��, ����� � ����� �������� 4 32-��������� ����������
     db 0c4h,0e2h,75h,02h,0cah       // AVX2 vphaddd ymm1,ymm1,ymm2
     db 0c4h,0e2h,65h,02h,0dch       // AVX2 vphaddd ymm3,ymm3,ymm4
     db 0c4h,0e2h,75h,02h,0cbh       // AVX2 vphaddd ymm1,ymm1,ymm3
    // ���������� ������ ���������� �������
     db 0c4h,0e3h,7dh,39h,0cah,01 // AVX2 vextracti128 xmm2,ymm1,0x1
     db 66h,0fh,0feh,0cah         // SSE2 paddd xmm1,xmm2
     // ��������� ��������� ��� ��������� ������� ������������ ��������
     movdqu [r8],xmm1
     add r8,16
     // ������ ����
     add rdx,32
     sub r11,1
     jnz @@1
end;
Function AVX2_NNOut(Inprow,Matrix,Ones,Bias : Pbyte):integer; //1.65 c
//                   rcx,    rdx,  r8   r9
// ����������� ������� [1x32] ��������  int8 �� ������� [32x1] �������� int8 ��������� SIMD AVX2
// ���� int32 ����� ���� ��������� , ��������� bias ���������� ���� � ��������� ����������� 1/64.
asm
    .noframe
   // ��������� ������� int16-���������
     db 0c4h,0c1h,7eh,6fh,18h           // AVX vmovdqu ymm3,[r8]
  // ������ ������ improw [1,32]
     db 0c5h,0feh,6fh,01h               // AVX vmovdqu ymm0,[rcx]
  // ������ ������ ������� [32,1]
     db 0c5h,0feh,6fh,0Ah               // AVX vmovdqu ymm1,[rdx]
  //  �����������  int8
     db 0c4h,0e2h,7dh,04h,0c1h          // AVX2 vpmaddubsw ymm0,ymm0,ymm1
   // �������� int16 �� ��������� ������� � �������� � int32
     db 0c5h,0fdh,0f5h,0c3h             // AVX2 vpmaddwd ymm0,ymm0,ymm3
  // ���������� 256 ������ int32  ���������� �������
     db 0c4h,0e3h,7dh,39h,0c1h,01       // AVX2 vextracti128 xmm1,ymm0,0x1
     db 66h,0fh,0feh,0c1h               // SSE2 paddd xmm0,xmm1
  // ������������� ��������� 4 �������� � xmm0
     db 66h,0fh,70h,0c8h,4eh            // SSE2 pshufd xmm1,xmm0,4eh
     db 66h,0fh,0feh,0c1h               // SSE2 paddd xmm0,xmm1
     db 0f2h,0fh,70h,0c8h,4eh           // SSE2 pshuflw xmm1,xmm0,4eh
     db 66h,0fh,0feh,0c1h               // SSE2 paddd xmm0,xmm1
  // ��������� ������������
     db 66h,0fh,7eh,0c0h                // movd eax,xmm0
  // ��������� ����
     db 41h,03h,01h                     // add eax,DWORD ptr [r8]
end;
Procedure AVX2_RELU_64(Summs,Biases,Permut,Res : Pbyte);  //1,97c
//                      rcx,   rdx     r    r9
// ������� �� ���� ������ �� 32 ������� �������� (int32)  + 32 ����� (int32) ��������� RELU �  ������� �����  �� int8.���������� SIMD AVX2
asm
  .noframe
  // ������ 8 int32 ���������
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // ��������� � ������� 8 �������
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - ��������� 1
  // ��������� 8 int32 ���������
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // ��������� �� �������  8 �������
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - ��������� 2
  // ����������� ��� 2 �������� �� 8 int32 �������� � int16 ������������� (� ���������� �� ������)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // ��������� ����������� (1/64)
  db 0c5h,0e5h,71h,0e0h,06             // AVX2 vpsraw ymm3,ymm0,06
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  // ������ 8 int32 ���������
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // ��������� � �������� 8 �������
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - ��������� 3
  // ��������� 8 int32 ���������
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // ��������� � ����������  8 �������
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - ��������� 4
  // ����������� ��� 2 �������� �� 8 int32 �������� � int16 ������������� (� ���������� �� ������)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // ��������� ����������� (1/64)
  db 0c5h,0fdh,71h,0e0h,06h              // AVX2 vpsraw ymm0,ymm0,06
  // ������ ������ 16 int16 �  int8 (� ���������� ��� ����� ) + RELU
  db 0c5h,0e5h,67h,0c0h                  // AVX2 vpackuswb ymm0,ymm3,ymm0
  // ����������� ������ � ���������� ���������
  db 0c4h,0c1h,7eh,6fh,08h               // AVX vmovdqu ymm1,[r8]
  db 0c4h,0e2h,75h,36h,0c0h              // AVX2 vpermd ymm0,ymm1,ymm0
  db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
end;
Procedure AVX2_RELU_128(Summs,Biases,Permut,Res : Pbyte);  //1,97c
//                      rcx,   rdx     r    r9
// ������� �� ���� ������ �� 32 ������� �������� (int32)  + 32 ����� (int32) ��������� RELU �  ������� �����  �� int8.���������� SIMD AVX2
asm
  .noframe
  // ������ 8 int32 ���������
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // ��������� � ������� 8 �������
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - ��������� 1
  // ��������� 8 int32 ���������
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // ��������� �� �������  8 �������
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - ��������� 2
  // ����������� ��� 2 �������� �� 8 int32 �������� � int16 ������������� (� ���������� �� ������)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // ��������� ����������� (1/128)
  db 0c5h,0e5h,71h,0e0h,07             // AVX2 vpsraw ymm3,ymm0,07
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  // ������ 8 int32 ���������
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // ��������� � �������� 8 �������
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - ��������� 3
  // ��������� 8 int32 ���������
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // ��������� � ����������  8 �������
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - ��������� 4
  // ����������� ��� 2 �������� �� 8 int32 �������� � int16 ������������� (� ���������� �� ������)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // ��������� ����������� (1/128)
  db 0c5h,0fdh,71h,0e0h,07h              // AVX2 vpsraw ymm0,ymm0,07
  // ������ ������ 16 int16 �  int8 (� ���������� ��� ����� ) + RELU
  db 0c5h,0e5h,67h,0c0h                  // AVX2 vpackuswb ymm0,ymm3,ymm0
  // ����������� ������ � ���������� ���������
  db 0c4h,0c1h,7eh,6fh,08h               // AVX vmovdqu ymm1,[r8]
  db 0c4h,0e2h,75h,36h,0c0h              // AVX2 vpermd ymm0,ymm1,ymm0
  db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
end;
Procedure AVX2_RELU_256(Summs,Biases,Permut,Res : Pbyte);  //1,97c
//                      rcx,   rdx     r    r9
// ������� �� ���� ������ �� 32 ������� �������� (int32)  + 32 ����� (int32) ��������� RELU �  ������� �����  �� int8.���������� SIMD AVX2
asm
  .noframe
  // ������ 8 int32 ���������
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // ��������� � ������� 8 �������
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - ��������� 1
  // ��������� 8 int32 ���������
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // ��������� �� �������  8 �������
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - ��������� 2
  // ����������� ��� 2 �������� �� 8 int32 �������� � int16 ������������� (� ���������� �� ������)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // ��������� ����������� (1/256)
  db 0c5h,0e5h,71h,0e0h,08             // AVX2 vpsraw ymm3,ymm0,08
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  // ������ 8 int32 ���������
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // ��������� � �������� 8 �������
  db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
  db 0c5h,0f5h,0feh,0c0h                 // AVX2 vpaddd ymm0,ymm1,ymm0  - ��������� 3
  // ��������� 8 int32 ���������
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 48h,83h,0c2h,20h                    // add rdx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // ��������� � ����������  8 �������
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  db 0c5h,0edh,0feh,0c9h                 // AVX2 vpaddd ymm1,ymm2,ymm1  - ��������� 4
  // ����������� ��� 2 �������� �� 8 int32 �������� � int16 ������������� (� ���������� �� ������)
  db 0c5h,0f5h,6bh,0c0h                  // AVX2 vpackssdw ymm0,ymm1,ymm0
  // ��������� ����������� (1/256)
  db 0c5h,0fdh,71h,0e0h,08h              // AVX2 vpsraw ymm0,ymm0,08
  // ������ ������ 16 int16 �  int8 (� ���������� ��� ����� ) + RELU
  db 0c5h,0e5h,67h,0c0h                  // AVX2 vpackuswb ymm0,ymm3,ymm0
  // ����������� ������ � ���������� ���������
  db 0c4h,0c1h,7eh,6fh,08h               // AVX vmovdqu ymm1,[r8]
  db 0c4h,0e2h,75h,36h,0c0h              // AVX2 vpermd ymm0,ymm1,ymm0
  db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
end;
Procedure AVX2_RELU_ACC(Acc16,Permut,Dest : Pbyte); // 10c  �� 512
//                       rcx,  rdx    r8
// ������� �� ����   ����������� �� ��������� ���� (256 ��������� int16) ��������� RELU �  ������� �����  �� int8.���������� SIMD AVX2
asm
  .noframe
  // ����� ������������� ���������
  db 0c5h,0feh,6fh,12h                   // AVX vmovdqu ymm2,[rdx]
  mov r10,8                              // ������� 8*(16+16)=256
@@1:
  // ����� ������ 16 �������� ������������ int16
  db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
  // ����� ������ 16 �������� ������������ int16
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 0c5h,0feh,6fh,09h                   // AVX vmovdqu ymm1,[rcx]
  // ������ ������  2 �� 16 int16 �  int8 (� ���������� ��� ����� ) + RELU
  db 0c5h,0fdh,67h,0c1h                  // AVX2 vpackuswb ymm0,ymm0,ymm1
  // ������������  ��� ����������� �������
  db 0c4h,0e2h,6dh,36h,0c0h              // AVX2 vpermd ymm0,ymm2,ymm0
  // ��������� 32 int8 ��������
  db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
  // ��������� 16 int16 ���������
  db 48h,83h,0c1h,20h                    // add rcx,20h
  db 49h,83h,0c0h,20h                    // add r8, 20h
  // ������ ����
  sub r10,1
  jnz @@1
end;


Procedure AVX2_CopyAcc(Source,Dest : Pbyte);
//                       rcx,  rdx
// �������� int16 ����������� �� 1 ����.  ��������� �� ������  DEST ( ����� ��������� � SOURCE)
asm
  .noframe
   mov r10,16                              // �������   16*16=256
@@1:
   // ������ ������ ��������� (16 ��������� int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
    // ��������� ����������� ������
    db 0c5h,0feh,7fh,02h                    // AVX vmovdqu [rdx],ymm0
    // ��������� 16 int16 ���������
    db 48h,83h,0c1h,20h                    // add rcx,20h
    db 48h,83h,0c2h,20h                    // add rdx,20h
    // ������ ����
    sub r10,1
    jnz @@1
end;
Procedure AVX2_SetFeauture(Source,NetIndex,Dest : Pbyte);  //8,21 c
//                          rcx,    rdx,    r8
// ��������� (������������� ����) int16 ������������ �� 1 ����.  ��������� �� ������  DEST ( ����� ��������� � SOURCE)
asm
  .noframe
   mov r10,16                               // �������  16*16=256
@@1:
   // ������ ������ ��������� (16 ��������� int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // ������ ������ ����� (16 ��������� int16)
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    // ������������� (����������)
    db 0c5h,0fdh,0fdh,0c1h                 // AVX2 vpaddw ymm0,ymm0,ymm1
    // ��������� ����������� ������
    db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
    // ��������� 16 int16 ���������
    db 48h,83h,0c1h,20h                    // add rcx,20h
    db 48h,83h,0c2h,20h                    // add rdx,20h
    db 49h,83h,0c0h,20h                    // add r8, 20h
    // ������ ����
    sub r10,1
    jnz @@1
end;
Procedure AVX2_ReSetFeauture(Source,NetIndex,Dest : Pbyte); // 8,21 c
//                          rcx,    rdx,    r8
// ��������� (������� ����)  int16 ������������ �� 1 ����. ��������� �� ������  DEST ( ����� ��������� � SOURCE)
asm
  .noframe
   mov r10,16                              // �������  16*16=256
@@1:
   // ������ ������ ��������� (16 ��������� int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // ������ ������ ����� (16 ��������� int16)
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    // ������������� (��������)
    db 0c5h,0fdh,0f9h,0c1h                 // AVX2 vpsubw ymm0,ymm0,ymm1
    // ��������� ����������� ������
    db 0c4h,0c1h,7eh,7fh,00h               // AVX vmovdqu [r8],ymm0
    // ��������� 16 int16 ���������
    db 48h,83h,0c1h,20h                    // add rcx,20h
    db 48h,83h,0c2h,20h                    // add rdx,20h
    db 49h,83h,0c0h,20h                    // add r8, 20h
    // ������ ����
    sub r10,1
    jnz @@1
end;
Procedure AVX2_UpdFeauture(Source,NetIndexAdd,NetIndexSUB,Dest : Pbyte);   //11,37 c
//                          rcx,    rdx,         r8        r9
// ��������� (��������� + ������� ����) �������� int16 ������������ (�� 1 ����). �� ����� ����� ��������� ��������� ������������ int16 � ��������� ����� ������ ���� � ����� int16. ��������� ��������� ������������ �� ������  DEST ( ����� ��������� � SOURCE)
asm
  .noframe
   mov r10,16                              // �������  16*16=256
@@1:
   // ������ ������ ��������� (16 ��������� int16)
    db 0c5h,0feh,6fh,01h                   // AVX vmovdqu ymm0,[rcx]
   // ������ ������ �����1 (16 ��������� int16)
    db 0c5h,0feh,6fh,0Ah                   // AVX vmovdqu ymm1,[rdx]
    // ������ ������ �����2 (16 ��������� int16)
    db 0c4h,0c1h,7eh,6fh,10h               // AVX vmovdqu ymm2,[r8]
    // �������������1  (����������)
    db 0c5h,0fdh,0fdh,0c1h                 // AVX2 vpaddw ymm0,ymm0,ymm1
    // �������������2 (��������)
    db 0c5h,0fdh,0f9h,0c2h                 // AVX2 vpsubw ymm0,ymm0,ymm2
    // ��������� ����������� ������
    db 0c4h,0c1h,7eh,7fh,01h               // AVX vmovdqu [r9],ymm0
    // ��������� 16 int16 ���������
    db 48h,83h,0c1h,20h                    // add rcx,20h
    db 48h,83h,0c2h,20h                    // add rdx,20h
    db 49h,83h,0c0h,20h                    // add r8, 20h
    db 49h,83h,0c1h,20h                    // add r9, 20h
    // ������ ����
    sub r10,1
    jnz @@1
end;
Function ForwardPass(SideToMove:integer;var Pass:TForwardPass):integer; //312c �� 512
// ������ �� ���������. �� ����� ����������� ����, ������� ���� � ��������� ������������, �� ������ - ������ ������
begin
  //� ����������� �� ������� ���� ����������� ������������ � ������ �������
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
  // ��������� ���� � ��������� ������ ���������
  f:=TFileStream.Create(filename,fmOpenRead);
  res:=f.Read(ver,2); // 16-��� �������������
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
  // ��������� ��������� scale_act - ��� ������� �� �������� �������� � ����� �� ������ � ������ ��������.
  Net.scale_act:=0;
  res:=f.Read(w,2);  // 16 ��� �������������  = scale_act*100
  if res<>2 then
    begin
      Writeln('Cant read a scale_act byte!');
      exit;
    end;
  Net.scale_act:=w/100; // ����� ���� � �������
  // ��������� ��������� scale_out - ��� ������� �� �������� �������� � ����� �� ������ � ������ ��������.
  Net.scale_out:=0;
  res:=f.Read(w,2);  // 16 ��� �������������
  if res<>2 then
    begin
      Writeln('Cant read a scale_out byte!');
      exit;
    end;
  Net.scale_out:=w;
  // ��������� ����� ������ ���������
   res:=f.Read(Net.model,2);
   if res<>2 then
    begin
     Writeln('Cant read a model number!');
     exit;
    end;
  // ��������� ��������� w1 - ��� ������� �� �������� �������� � ����� �� ������ � ������ ��������.
  res:=f.Read(w,2);  // 16 ��� �������������
  if res<>2 then
    begin
      Writeln('Cant read a w1 byte!');
      exit;
    end;
  Net.w1:=w;
   // ��������� ��������� w2 - ��� ������� �� �������� �������� � ����� �� ������ � ������ ��������.
  res:=f.Read(w,2);  // 16 ��� �������������
  if res<>2 then
    begin
      Writeln('Cant read a w2 byte!');
      exit;
    end;
  Net.w2:=w;
  // ��������� ������ ������ � ��������� ���� � ������
  size:=ModelFrameSize(Net.model);
  if size=0 then
    begin
      Writeln('Unknown model!');
      exit;
    end;
  size:=size*half*2;
  // ��������� Flayer weights int16
  res:=f.Read(Net.Flayer,size);
  if res<>size then
    begin
     Writeln('Cant read Flayer weights!');
     exit;
    end;

  // ��������� FirstLayer weights int8
  res:=f.Read(Net.FirstLayer,hidden1*32);
  if res<>hidden1*32 then
    begin
     Writeln('Cant read a FirstLayer weights!');
     exit;
    end;
  // ��������� SecondLayer weights int8
  res:=f.Read(Net.SecondLayer,32*32);
  if res<>32*32 then
    begin
     Writeln('Cant read a SecondLayer weights!');
     exit;
    end;
  // ��������� OutLayer weights int8
  res:=f.Read(Net.outlayer,32);
  if res<>32 then
    begin
     Writeln('Cant read a OutLayer weights!');
     exit;
    end;
  // ��������� Flayer biases int16
  res:=f.Read(Net.Fbias,half*2);
  if res<>half*2 then
    begin
     Writeln('Cant read a Flayer biases!');
     exit;
    end;
  // ��������� FirstLayer biases int32
  res:=f.Read(Net.biasFirst,4*32);
  if res<>4*32 then
    begin
     Writeln('Cant read a FirstLayer biases!');
     exit;
    end;
  // ��������� SecondLayer biases int32
  res:=f.Read(Net.biasSecond,4*32);
  if res<>4*32 then
    begin
     Writeln('Cant read a SecondLayer biases!');
     exit;
    end;
  // ��������� OutLayer biases int32
  res:=f.Read(Net.outbias,4);
  if res<>4 then
    begin
     Writeln('Cant read a OutLayer biases!');
     exit;
    end;
  // ��������� ������� ���� ��� �������� �� ����� ����������
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
// ��������� ������ ��������� ������ �� �����. �� ����� - ������ ������ ����� � ����, ������� ��� ��������, �� ������ - ������ ������ �����
begin
  Result:=PieseBlock[Piese]+sq;
end;

Procedure SetPiesesWhiteAcc(WhiteFrameStartIndex:integer;Piese:integer;var Board:TBoard;var Pass:TForwardPass);
// ������������� ���� ����� ���������� ���� (������  �����) � ����� ����������. �� ����� - ��������� ����� ������ ������ � ������� ��������������� ������
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
// ������������� ���� ����� ���������� ���� (������  �����) � ������ ����������. �� ����� - ��������� ����� ������� ������ � ������� ��������������� ������
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
// � ����������� �� ��������� ������ ��������� � ��������� �� ����� ���������� ��������� ������ ������ ������.
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
// � ����������� �� ��������� ������ ��������� � ��������� �� ����� ���������� ��������� ������ ������� ������.
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
// ��������� ��������� ������ ������������  �� ������� �� �����
var
  sq,Whiteindex,WhiteFrameStartIndex : integer;
begin
  WhiteFrameStartIndex:=GetWhiteFrameIndex(model,Board);
  // ������������� ������ ������
  sq:=Board.KingSq[white];
  Whiteindex:=(WhiteFrameStartIndex+GetBlockIndex(King,sq)) shl 8;
  // ��� ������ ��������������� ������ � �������� ��������� ����� �����
  AVX2_SetFeauture(@Net.Fbias,@Net.Flayer[Whiteindex],@Pass.Acc16[white]);
 // ������������� ������� ������
  sq:=Board.KingSq[black];
  Whiteindex:=(WhiteFrameStartIndex+GetBlockIndex(-King,sq)) shl 8;
  AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[Whiteindex],@Pass.Acc16[white]);
  //  ������ ������������� ������
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Queen,Board,Pass);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Rook,Board,Pass);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Bishop,Board,Pass);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Knight,Board,Pass);
  SetPiesesWhiteAcc(WhiteFrameStartIndex,Pawn,Board,Pass);
  // ������������� ���������
  If (Board.CastleRights and 1)<>0 then AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[WShortCastle],@Pass.Acc16[white]);
  If (Board.CastleRights and 2)<>0 then AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[WLongCastle] ,@Pass.Acc16[white]);
  If (Board.CastleRights and 4)<>0 then AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[BShortCastle],@Pass.Acc16[white]);
  If (Board.CastleRights and 8)<>0 then AVX2_SetFeauture(@Pass.Acc16[white],@Net.Flayer[BLongCastle] ,@Pass.Acc16[white]);
end;
Procedure FillBlackAcc16(model:integer;var Board:Tboard;var Pass:TForwardPass);
// ��������� ��������� ������� ������������  �� ������� �� �����
var
  sq,Blackindex,BlackFrameStartIndex : integer;
begin
  BlackFrameStartIndex:=GetBlackFrameIndex(model,Board);
  // ������������� ������ ������
  sq:=Board.KingSq[white] xor 56;
  Blackindex:=(BlackFrameStartIndex+GetBlockIndex(-King,sq)) shl 8;
  // ��� ������ ��������������� ������ � �������� ��������� ����� �����
  AVX2_SetFeauture(@Net.Fbias,@Net.Flayer[Blackindex],@Pass.Acc16[black]);
 // ������������� ������� ������
  sq:=Board.KingSq[black] xor 56;
  Blackindex:=(BlackFrameStartIndex+GetBlockIndex(King,sq)) shl 8;
  AVX2_SetFeauture(@Pass.Acc16[black],@Net.Flayer[Blackindex],@Pass.Acc16[black]);
  //  ������ ������������� ������
  SetPiesesBlackAcc(BlackFrameStartIndex,Queen,Board,Pass);
  SetPiesesBlackAcc(BlackFrameStartIndex,Rook,Board,Pass);
  SetPiesesBlackAcc(BlackFrameStartIndex,Bishop,Board,Pass);
  SetPiesesBlackAcc(BlackFrameStartIndex,Knight,Board,Pass);
  SetPiesesBlackAcc(BlackFrameStartIndex,Pawn,Board,Pass);
  // ������������� ���������
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
// ��������� ������������. ������ ��������� ��� ���������� ����� �������������.
var
   Piese,FromPiese,from,dest,capsq,rookfrom,rookdest,myrook,stm,WhiteFrameStartIndex,BlackFrameStartIndex : integer;
   AddwhiteIndex,RemwhiteIndex,AddblackIndex,RemblackIndex : integer;
begin
  from:=move and 63;
  dest:=(move shr 6) and 63;
  Piese:=Board.Pos[dest];       // ��������� ������ �������� ����� MakeMove
  stm:=Board.SideToMove xor 1;  // ��������� ������ �������� ����� MakeMove
  // ���� ��� - ����������� ����� (��� ������� - �� �������, ������ �������������� �����)
  if (move and PromoteFlag)<>0 then
    begin
      if stm=white
        then FromPiese:=Pawn
        else FromPiese:=-Pawn;
    end else FromPiese:=Piese;
  // ��������� ����� �����������
  WhiteFrameStartIndex:=GetWhiteFrameIndex(Net.model,Board);
  If WhiteFrameStartIndex<>Undo.WFrame then FillWhiteAcc16(Net.model,Board,NewPass) else     // ������������� ���� ����������� � ���� ���� ��������� ������ ������
    begin
      // ������������ �������� ������
      AddWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Piese,dest)) shl 8;
      RemWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Frompiese,from)) shl 8;
      // ��� ������� ������� � ���� ���������  ����� ���������� �����������
      AVX2_UPdFeauture(@OldPass.Acc16[white],@Net.Flayer[AddWhiteindex],@Net.Flayer[REMWhiteindex],@NewPass.Acc16[white]);
      // ���� ���� ���������, �� ������ ������ ����������� ��� - ���������� �����
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
      // ���� ���� ������ (� ��� ����� �� �������) - ������� ������� ������
      if ((move and CaptureFlag)<>0) then
        begin
          capsq:=dest;
          If Undo.isEnnPass then capsq:=capsq-PawnPush[stm];
          RemWhiteIndex:=(WhiteFrameStartIndex+GetBlockIndex(Board.CapturedPiese,capsq)) shl 8;
          AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[RemWhiteIndex],@NewPass.Acc16[white]);
        end;
      // ���� � ���������� ���� ���������� ����� �� ��������� (�����-�� �� ������ �������� ��) - ���������
      if Undo.CastleRights<>Board.CastleRights then
        begin
          if (Undo.CastleRights and 1)<>(Board.CastleRights and 1) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[WShortCastle],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 2)<>(Board.CastleRights and 2) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[WLongCastle ],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 4)<>(Board.CastleRights and 4) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[BShortCastle],@NewPass.Acc16[white]);
          if (Undo.CastleRights and 8)<>(Board.CastleRights and 8) then AVX2_ReSetFeauture(@NewPass.Acc16[white],@Net.Flayer[BLongCastle] ,@NewPass.Acc16[white]);
        end;
    end;
// ��������� ������ �����������
  BlackFrameStartIndex:=GetBlackFrameIndex(Net.model,Board);
  If BlackFrameStartIndex<>Undo.BFrame then FillBlackAcc16(Net.model,Board,NewPass) else     // ������������� ���� ����������� � ���� ���� ��������� ������ ������
    begin
      // ������������ �������� ������
      AddBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Piese,dest xor 56)) shl 8;
      RemBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Frompiese,from xor 56)) shl 8;
      // ��� ������� �������  � ���� ���������  ����� ���������� �����������
      AVX2_UPdFeauture(@OldPass.Acc16[black],@Net.Flayer[AddBlackindex],@Net.Flayer[REMBlackindex],@NewPass.Acc16[black]);
      // ���� ���� ���������, �� ������ ������ ����������� ��� - ���������� �����
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
      // ���� ���� ������ (� ��� ����� �� �������) - ������� ������� ������
      if ((move and CaptureFlag)<>0) then
        begin
          capsq:=dest;
          If Undo.isEnnPass then capsq:=capsq-PawnPush[stm];
          RemBlackIndex:=(BlackFrameStartIndex+GetBlockIndex(-Board.CapturedPiese,capsq xor 56)) shl 8;
          AVX2_ReSetFeauture(@NewPass.Acc16[black],@Net.Flayer[RemBlackIndex],@NewPass.Acc16[black]);
        end;
      // ���� � ���������� ���� ���������� ����� �� ��������� (�����-�� �� ������ �������� ��) - ���������
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
