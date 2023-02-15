unit table;

interface
uses params,bitboards,SysUtils;
var
   kingrot : array[0..63,1..2] of integer;
   PieseRot : array[0..63,0..7] of integer;
   kingidx : array[0..63] of integer;
Procedure TableInit;
Procedure TableLoad;
Function isTable:boolean;
Function Probe(color:integer;ply:integer):integer;
implementation
Procedure TableInit;
var
  i:integer;
begin
KingRot[a1,1]:=a1;KingRot[a1,2]:=0;KingRot[b1,1]:=b1;KingRot[b1,2]:=0;KingRot[c1,1]:=c1;KingRot[c1,2]:=0;KingRot[d1,1]:=d1;KingRot[d1,2]:=0;
KingRot[e1,1]:=d1;KingRot[e1,2]:=7;KingRot[f1,1]:=c1;KingRot[f1,2]:=7;KingRot[g1,1]:=b1;KingRot[g1,2]:=7;KingRot[h1,1]:=a1;KingRot[h1,2]:=7;
KingRot[a2,1]:=b1;KingRot[a2,2]:=1;KingRot[b2,1]:=b2;KingRot[b2,2]:=0;KingRot[c2,1]:=c2;KingRot[c2,2]:=0;KingRot[d2,1]:=d2;KingRot[d2,2]:=0;
KingRot[e2,1]:=d2;KingRot[e2,2]:=7;KingRot[f2,1]:=c2;KingRot[f2,2]:=7;KingRot[g2,1]:=b2;KingRot[g2,2]:=7;KingRot[h2,1]:=b1;KingRot[h2,2]:=6;
KingRot[a3,1]:=c1;KingRot[a3,2]:=1;KingRot[b3,1]:=c2;KingRot[b3,2]:=1;KingRot[c3,1]:=c3;KingRot[c3,2]:=0;KingRot[d3,1]:=d3;KingRot[d3,2]:=0;
KingRot[e3,1]:=d3;KingRot[e3,2]:=7;KingRot[f3,1]:=c3;KingRot[f3,2]:=7;KingRot[g3,1]:=c2;KingRot[g3,2]:=6;KingRot[h3,1]:=c1;KingRot[h3,2]:=6;
KingRot[a4,1]:=d1;KingRot[a4,2]:=1;KingRot[b4,1]:=d2;KingRot[b4,2]:=1;KingRot[c4,1]:=d3;KingRot[c4,2]:=1;KingRot[d4,1]:=d4;KingRot[d4,2]:=0;
KingRot[e4,1]:=d4;KingRot[e4,2]:=7;KingRot[f4,1]:=d3;KingRot[f4,2]:=6;KingRot[g4,1]:=d2;KingRot[g4,2]:=6;KingRot[h4,1]:=d1;KingRot[h4,2]:=6;
KingRot[a5,1]:=d1;KingRot[a5,2]:=2;KingRot[b5,1]:=d2;KingRot[b5,2]:=2;KingRot[c5,1]:=d3;KingRot[c5,2]:=2;KingRot[d5,1]:=d4;KingRot[d5,2]:=2;
KingRot[e5,1]:=d4;KingRot[e5,2]:=4;KingRot[f5,1]:=d3;KingRot[f5,2]:=5;KingRot[g5,1]:=d2;KingRot[g5,2]:=5;KingRot[h5,1]:=d1;KingRot[h5,2]:=5;
KingRot[a6,1]:=c1;KingRot[a6,2]:=2;KingRot[b6,1]:=c2;KingRot[b6,2]:=2;KingRot[c6,1]:=c3;KingRot[c6,2]:=2;KingRot[d6,1]:=d3;KingRot[d6,2]:=3;
KingRot[e6,1]:=d3;KingRot[e6,2]:=4;KingRot[f6,1]:=c3;KingRot[f6,2]:=4;KingRot[g6,1]:=c2;KingRot[g6,2]:=5;KingRot[h6,1]:=c1;KingRot[h6,2]:=5;
KingRot[a7,1]:=b1;KingRot[a7,2]:=2;KingRot[b7,1]:=b2;KingRot[b7,2]:=2;KingRot[c7,1]:=c2;KingRot[c7,2]:=3;KingRot[d7,1]:=d2;KingRot[d7,2]:=3;
KingRot[e7,1]:=d2;KingRot[e7,2]:=4;KingRot[f7,1]:=c2;KingRot[f7,2]:=4;KingRot[g7,1]:=b2;KingRot[g7,2]:=4;KingRot[h7,1]:=b1;KingRot[h7,2]:=5;
KingRot[a8,1]:=a1;KingRot[a8,2]:=2;KingRot[b8,1]:=b1;KingRot[b8,2]:=3;KingRot[c8,1]:=c1;KingRot[c8,2]:=3;KingRot[d8,1]:=d1;KingRot[d8,2]:=3;
KingRot[e8,1]:=d1;KingRot[e8,2]:=4;KingRot[f8,1]:=c1;KingRot[f8,2]:=4;KingRot[g8,1]:=b1;KingRot[g8,2]:=4;KingRot[h8,1]:=a1;KingRot[h8,2]:=4;

PieseRot[a1,0]:=a1;PieseRot[b1,0]:=b1;PieseRot[c1,0]:=c1;PieseRot[d1,0]:=d1;PieseRot[e1,0]:=e1;PieseRot[f1,0]:=f1;PieseRot[g1,0]:=g1;PieseRot[h1,0]:=h1;
PieseRot[a2,0]:=a2;PieseRot[b2,0]:=b2;PieseRot[c2,0]:=c2;PieseRot[d2,0]:=d2;PieseRot[e2,0]:=e2;PieseRot[f2,0]:=f2;PieseRot[g2,0]:=g2;PieseRot[h2,0]:=h2;
PieseRot[a3,0]:=a3;PieseRot[b3,0]:=b3;PieseRot[c3,0]:=c3;PieseRot[d3,0]:=d3;PieseRot[e3,0]:=e3;PieseRot[f3,0]:=f3;PieseRot[g3,0]:=g3;PieseRot[h3,0]:=h3;
PieseRot[a4,0]:=a4;PieseRot[b4,0]:=b4;PieseRot[c4,0]:=c4;PieseRot[d4,0]:=d4;PieseRot[e4,0]:=e4;PieseRot[f4,0]:=f4;PieseRot[g4,0]:=g4;PieseRot[h4,0]:=h4;
PieseRot[a5,0]:=a5;PieseRot[b5,0]:=b5;PieseRot[c5,0]:=c5;PieseRot[d5,0]:=d5;PieseRot[e5,0]:=e5;PieseRot[f5,0]:=f5;PieseRot[g5,0]:=g5;PieseRot[h5,0]:=h5;
PieseRot[a6,0]:=a6;PieseRot[b6,0]:=b6;PieseRot[c6,0]:=c6;PieseRot[d6,0]:=d6;PieseRot[e6,0]:=e6;PieseRot[f6,0]:=f6;PieseRot[g6,0]:=g6;PieseRot[h6,0]:=h6;
PieseRot[a7,0]:=a7;PieseRot[b7,0]:=b7;PieseRot[c7,0]:=c7;PieseRot[d7,0]:=d7;PieseRot[e7,0]:=e7;PieseRot[f7,0]:=f7;PieseRot[g7,0]:=g7;PieseRot[h7,0]:=h7;
PieseRot[a8,0]:=a8;PieseRot[b8,0]:=b8;PieseRot[c8,0]:=c8;PieseRot[d8,0]:=d8;PieseRot[e8,0]:=e8;PieseRot[f8,0]:=f8;PieseRot[g8,0]:=g8;PieseRot[h8,0]:=h8;

PieseRot[a1,1]:=a1;PieseRot[b1,1]:=a2;PieseRot[c1,1]:=a3;PieseRot[d1,1]:=a4;PieseRot[e1,1]:=a5;PieseRot[f1,1]:=a6;PieseRot[g1,1]:=a7;PieseRot[h1,1]:=a8;
PieseRot[a2,1]:=b1;PieseRot[b2,1]:=b2;PieseRot[c2,1]:=b3;PieseRot[d2,1]:=b4;PieseRot[e2,1]:=b5;PieseRot[f2,1]:=b6;PieseRot[g2,1]:=b7;PieseRot[h2,1]:=b8;
PieseRot[a3,1]:=c1;PieseRot[b3,1]:=c2;PieseRot[c3,1]:=c3;PieseRot[d3,1]:=c4;PieseRot[e3,1]:=c5;PieseRot[f3,1]:=c6;PieseRot[g3,1]:=c7;PieseRot[h3,1]:=c8;
PieseRot[a4,1]:=d1;PieseRot[b4,1]:=d2;PieseRot[c4,1]:=d3;PieseRot[d4,1]:=d4;PieseRot[e4,1]:=d5;PieseRot[f4,1]:=d6;PieseRot[g4,1]:=d7;PieseRot[h4,1]:=d8;
PieseRot[a5,1]:=e1;PieseRot[b5,1]:=e2;PieseRot[c5,1]:=e3;PieseRot[d5,1]:=e4;PieseRot[e5,1]:=e5;PieseRot[f5,1]:=e6;PieseRot[g5,1]:=e7;PieseRot[h5,1]:=e8;
PieseRot[a6,1]:=f1;PieseRot[b6,1]:=f2;PieseRot[c6,1]:=f3;PieseRot[d6,1]:=f4;PieseRot[e6,1]:=f5;PieseRot[f6,1]:=f6;PieseRot[g6,1]:=f7;PieseRot[h6,1]:=f8;
PieseRot[a7,1]:=g1;PieseRot[b7,1]:=g2;PieseRot[c7,1]:=g3;PieseRot[d7,1]:=g4;PieseRot[e7,1]:=g5;PieseRot[f7,1]:=g6;PieseRot[g7,1]:=g7;PieseRot[h7,1]:=g8;
PieseRot[a8,1]:=h1;PieseRot[b8,1]:=h2;PieseRot[c8,1]:=h3;PieseRot[d8,1]:=h4;PieseRot[e8,1]:=h5;PieseRot[f8,1]:=h6;PieseRot[g8,1]:=h7;PieseRot[h8,1]:=h8;

PieseRot[a1,3]:=a8;PieseRot[b1,3]:=b8;PieseRot[c1,3]:=c8;PieseRot[d1,3]:=d8;PieseRot[e1,3]:=e8;PieseRot[f1,3]:=f8;PieseRot[g1,3]:=g8;PieseRot[h1,3]:=h8;
PieseRot[a2,3]:=a7;PieseRot[b2,3]:=b7;PieseRot[c2,3]:=c7;PieseRot[d2,3]:=d7;PieseRot[e2,3]:=e7;PieseRot[f2,3]:=f7;PieseRot[g2,3]:=g7;PieseRot[h2,3]:=h7;
PieseRot[a3,3]:=a6;PieseRot[b3,3]:=b6;PieseRot[c3,3]:=c6;PieseRot[d3,3]:=d6;PieseRot[e3,3]:=e6;PieseRot[f3,3]:=f6;PieseRot[g3,3]:=g6;PieseRot[h3,3]:=h6;
PieseRot[a4,3]:=a5;PieseRot[b4,3]:=b5;PieseRot[c4,3]:=c5;PieseRot[d4,3]:=d5;PieseRot[e4,3]:=e5;PieseRot[f4,3]:=f5;PieseRot[g4,3]:=g5;PieseRot[h4,3]:=h5;
PieseRot[a5,3]:=a4;PieseRot[b5,3]:=b4;PieseRot[c5,3]:=c4;PieseRot[d5,3]:=d4;PieseRot[e5,3]:=e4;PieseRot[f5,3]:=f4;PieseRot[g5,3]:=g4;PieseRot[h5,3]:=h4;
PieseRot[a6,3]:=a3;PieseRot[b6,3]:=b3;PieseRot[c6,3]:=c3;PieseRot[d6,3]:=d3;PieseRot[e6,3]:=e3;PieseRot[f6,3]:=f3;PieseRot[g6,3]:=g3;PieseRot[h6,3]:=h3;
PieseRot[a7,3]:=a2;PieseRot[b7,3]:=b2;PieseRot[c7,3]:=c2;PieseRot[d7,3]:=d2;PieseRot[e7,3]:=e2;PieseRot[f7,3]:=f2;PieseRot[g7,3]:=g2;PieseRot[h7,3]:=h2;
PieseRot[a8,3]:=a1;PieseRot[b8,3]:=b1;PieseRot[c8,3]:=c1;PieseRot[d8,3]:=d1;PieseRot[e8,3]:=e1;PieseRot[f8,3]:=f1;PieseRot[g8,3]:=g1;PieseRot[h8,3]:=h1;

PieseRot[a1,2]:=h1;PieseRot[b1,2]:=h2;PieseRot[c1,2]:=h3;PieseRot[d1,2]:=h4;PieseRot[e1,2]:=h5;PieseRot[f1,2]:=h6;PieseRot[g1,2]:=h7;PieseRot[h1,2]:=h8;
PieseRot[a2,2]:=g1;PieseRot[b2,2]:=g2;PieseRot[c2,2]:=g3;PieseRot[d2,2]:=g4;PieseRot[e2,2]:=g5;PieseRot[f2,2]:=g6;PieseRot[g2,2]:=g7;PieseRot[h2,2]:=g8;
PieseRot[a3,2]:=f1;PieseRot[b3,2]:=f2;PieseRot[c3,2]:=f3;PieseRot[d3,2]:=f4;PieseRot[e3,2]:=f5;PieseRot[f3,2]:=f6;PieseRot[g3,2]:=f7;PieseRot[h3,2]:=f8;
PieseRot[a4,2]:=e1;PieseRot[b4,2]:=e2;PieseRot[c4,2]:=e3;PieseRot[d4,2]:=e4;PieseRot[e4,2]:=e5;PieseRot[f4,2]:=e6;PieseRot[g4,2]:=e7;PieseRot[h4,2]:=e8;
PieseRot[a5,2]:=d1;PieseRot[b5,2]:=d2;PieseRot[c5,2]:=d3;PieseRot[d5,2]:=d4;PieseRot[e5,2]:=d5;PieseRot[f5,2]:=d6;PieseRot[g5,2]:=d7;PieseRot[h5,2]:=d8;
PieseRot[a6,2]:=c1;PieseRot[b6,2]:=c2;PieseRot[c6,2]:=c3;PieseRot[d6,2]:=c4;PieseRot[e6,2]:=c5;PieseRot[f6,2]:=c6;PieseRot[g6,2]:=c7;PieseRot[h6,2]:=c8;
PieseRot[a7,2]:=b1;PieseRot[b7,2]:=b2;PieseRot[c7,2]:=b3;PieseRot[d7,2]:=b4;PieseRot[e7,2]:=b5;PieseRot[f7,2]:=b6;PieseRot[g7,2]:=b7;PieseRot[h7,2]:=b8;
PieseRot[a8,2]:=a1;PieseRot[b8,2]:=a2;PieseRot[c8,2]:=a3;PieseRot[d8,2]:=a4;PieseRot[e8,2]:=a5;PieseRot[f8,2]:=a6;PieseRot[g8,2]:=a7;PieseRot[h8,2]:=a8;

PieseRot[a1,4]:=h8;PieseRot[b1,4]:=g8;PieseRot[c1,4]:=f8;PieseRot[d1,4]:=e8;PieseRot[e1,4]:=d8;PieseRot[f1,4]:=c8;PieseRot[g1,4]:=b8;PieseRot[h1,4]:=a8;
PieseRot[a2,4]:=h7;PieseRot[b2,4]:=g7;PieseRot[c2,4]:=f7;PieseRot[d2,4]:=e7;PieseRot[e2,4]:=d7;PieseRot[f2,4]:=c7;PieseRot[g2,4]:=b7;PieseRot[h2,4]:=a7;
PieseRot[a3,4]:=h6;PieseRot[b3,4]:=g6;PieseRot[c3,4]:=f6;PieseRot[d3,4]:=e6;PieseRot[e3,4]:=d6;PieseRot[f3,4]:=c6;PieseRot[g3,4]:=b6;PieseRot[h3,4]:=a6;
PieseRot[a4,4]:=h5;PieseRot[b4,4]:=g5;PieseRot[c4,4]:=f5;PieseRot[d4,4]:=e5;PieseRot[e4,4]:=d5;PieseRot[f4,4]:=c5;PieseRot[g4,4]:=b5;PieseRot[h4,4]:=a5;
PieseRot[a5,4]:=h4;PieseRot[b5,4]:=g4;PieseRot[c5,4]:=f4;PieseRot[d5,4]:=e4;PieseRot[e5,4]:=d4;PieseRot[f5,4]:=c4;PieseRot[g5,4]:=b4;PieseRot[h5,4]:=a4;
PieseRot[a6,4]:=h3;PieseRot[b6,4]:=g3;PieseRot[c6,4]:=f3;PieseRot[d6,4]:=e3;PieseRot[e6,4]:=d3;PieseRot[f6,4]:=c3;PieseRot[g6,4]:=b3;PieseRot[h6,4]:=a3;
PieseRot[a7,4]:=h2;PieseRot[b7,4]:=g2;PieseRot[c7,4]:=f2;PieseRot[d7,4]:=e2;PieseRot[e7,4]:=d2;PieseRot[f7,4]:=c2;PieseRot[g7,4]:=b2;PieseRot[h7,4]:=a2;
PieseRot[a7,4]:=h1;PieseRot[b8,4]:=g1;PieseRot[c8,4]:=f1;PieseRot[d8,4]:=e1;PieseRot[e8,4]:=d1;PieseRot[f8,4]:=c1;PieseRot[g8,4]:=b1;PieseRot[h8,4]:=a1;

PieseRot[a1,5]:=h8;PieseRot[b1,5]:=h7;PieseRot[c1,5]:=h6;PieseRot[d1,5]:=h5;PieseRot[e1,5]:=h4;PieseRot[f1,5]:=h3;PieseRot[g1,5]:=h2;PieseRot[h1,5]:=h1;
PieseRot[a2,5]:=g8;PieseRot[b2,5]:=g7;PieseRot[c2,5]:=g6;PieseRot[d2,5]:=g5;PieseRot[e2,5]:=g4;PieseRot[f2,5]:=g3;PieseRot[g2,5]:=g2;PieseRot[h2,5]:=g1;
PieseRot[a3,5]:=f8;PieseRot[b3,5]:=f7;PieseRot[c3,5]:=f6;PieseRot[d3,5]:=f5;PieseRot[e3,5]:=f4;PieseRot[f3,5]:=f3;PieseRot[g3,5]:=f2;PieseRot[h3,5]:=f1;
PieseRot[a4,5]:=e8;PieseRot[b4,5]:=e7;PieseRot[c4,5]:=e6;PieseRot[d4,5]:=e5;PieseRot[e4,5]:=e4;PieseRot[f4,5]:=e3;PieseRot[g4,5]:=e2;PieseRot[h4,5]:=e1;
PieseRot[a5,5]:=d8;PieseRot[b5,5]:=d7;PieseRot[c5,5]:=d6;PieseRot[d5,5]:=d5;PieseRot[e5,5]:=d4;PieseRot[f5,5]:=d3;PieseRot[g5,5]:=d2;PieseRot[h5,5]:=d1;
PieseRot[a6,5]:=c8;PieseRot[b6,5]:=c7;PieseRot[c6,5]:=c6;PieseRot[d6,5]:=c5;PieseRot[e6,5]:=c4;PieseRot[f6,5]:=c3;PieseRot[g6,5]:=c2;PieseRot[h6,5]:=c1;
PieseRot[a7,5]:=b8;PieseRot[b7,5]:=b7;PieseRot[c7,5]:=b6;PieseRot[d7,5]:=b5;PieseRot[e7,5]:=b4;PieseRot[f7,5]:=b3;PieseRot[g7,5]:=b2;PieseRot[h7,5]:=b1;
PieseRot[a7,5]:=a8;PieseRot[b8,5]:=a7;PieseRot[c8,5]:=a6;PieseRot[d8,5]:=a5;PieseRot[e8,5]:=a4;PieseRot[f8,5]:=a3;PieseRot[g8,5]:=a2;PieseRot[h8,5]:=a1;

PieseRot[a1,6]:=a8;PieseRot[b1,6]:=a7;PieseRot[c1,6]:=a6;PieseRot[d1,6]:=a5;PieseRot[e1,6]:=a4;PieseRot[f1,6]:=a3;PieseRot[g1,6]:=a2;PieseRot[h1,6]:=a1;
PieseRot[a2,6]:=b8;PieseRot[b2,6]:=b7;PieseRot[c2,6]:=b6;PieseRot[d2,6]:=b5;PieseRot[e2,6]:=b4;PieseRot[f2,6]:=b3;PieseRot[g2,6]:=b2;PieseRot[h2,6]:=b1;
PieseRot[a3,6]:=c8;PieseRot[b3,6]:=c7;PieseRot[c3,6]:=c6;PieseRot[d3,6]:=c5;PieseRot[e3,6]:=c4;PieseRot[f3,6]:=c3;PieseRot[g3,6]:=c2;PieseRot[h3,6]:=c1;
PieseRot[a4,6]:=d8;PieseRot[b4,6]:=d7;PieseRot[c4,6]:=d6;PieseRot[d4,6]:=d5;PieseRot[e4,6]:=d4;PieseRot[f4,6]:=d3;PieseRot[g4,6]:=d2;PieseRot[h4,6]:=d1;
PieseRot[a5,6]:=e8;PieseRot[b5,6]:=e7;PieseRot[c5,6]:=e6;PieseRot[d5,6]:=e5;PieseRot[e5,6]:=e4;PieseRot[f5,6]:=e3;PieseRot[g5,6]:=e2;PieseRot[h5,6]:=e1;
PieseRot[a6,6]:=f8;PieseRot[b6,6]:=f7;PieseRot[c6,6]:=f6;PieseRot[d6,6]:=f5;PieseRot[e6,6]:=f4;PieseRot[f6,6]:=f3;PieseRot[g6,6]:=f2;PieseRot[h6,6]:=f1;
PieseRot[a7,6]:=g8;PieseRot[b7,6]:=g7;PieseRot[c7,6]:=g6;PieseRot[d7,6]:=g5;PieseRot[e7,6]:=g4;PieseRot[f7,6]:=g3;PieseRot[g7,6]:=g2;PieseRot[h7,6]:=g1;
PieseRot[a7,6]:=h8;PieseRot[b8,6]:=h7;PieseRot[c8,6]:=h6;PieseRot[d8,6]:=h5;PieseRot[e8,6]:=h4;PieseRot[f8,6]:=h3;PieseRot[g8,6]:=h2;PieseRot[h8,6]:=h1;

PieseRot[a1,7]:=h1;PieseRot[b1,7]:=g1;PieseRot[c1,7]:=f1;PieseRot[d1,7]:=e1;PieseRot[e1,7]:=d1;PieseRot[f1,7]:=c1;PieseRot[g1,7]:=b1;PieseRot[h1,7]:=a1;
PieseRot[a2,7]:=h2;PieseRot[b2,7]:=g2;PieseRot[c2,7]:=f2;PieseRot[d2,7]:=e2;PieseRot[e2,7]:=d2;PieseRot[f2,7]:=c2;PieseRot[g2,7]:=b2;PieseRot[h2,7]:=a2;
PieseRot[a3,7]:=h3;PieseRot[b3,7]:=g3;PieseRot[c3,7]:=f3;PieseRot[d3,7]:=e3;PieseRot[e3,7]:=d3;PieseRot[f3,7]:=c3;PieseRot[g3,7]:=b3;PieseRot[h3,7]:=a3;
PieseRot[a4,7]:=h4;PieseRot[b4,7]:=g4;PieseRot[c4,7]:=f4;PieseRot[d4,7]:=e4;PieseRot[e4,7]:=d4;PieseRot[f4,7]:=c4;PieseRot[g4,7]:=b4;PieseRot[h4,7]:=a4;
PieseRot[a5,7]:=h5;PieseRot[b5,7]:=g5;PieseRot[c5,7]:=f5;PieseRot[d5,7]:=e5;PieseRot[e5,7]:=d5;PieseRot[f5,7]:=c5;PieseRot[g5,7]:=b5;PieseRot[h5,7]:=a5;
PieseRot[a6,7]:=h6;PieseRot[b6,7]:=g6;PieseRot[c6,7]:=f6;PieseRot[d6,7]:=e6;PieseRot[e6,7]:=d6;PieseRot[f6,7]:=c6;PieseRot[g6,7]:=b6;PieseRot[h6,7]:=a6;
PieseRot[a7,7]:=h7;PieseRot[b7,7]:=g7;PieseRot[c7,7]:=f7;PieseRot[d7,7]:=e7;PieseRot[e7,7]:=d7;PieseRot[f7,7]:=c7;PieseRot[g7,7]:=b7;PieseRot[h7,7]:=a7;
PieseRot[a7,7]:=h8;PieseRot[b8,7]:=g8;PieseRot[c8,7]:=f8;PieseRot[d8,7]:=e8;PieseRot[e8,7]:=d8;PieseRot[f8,7]:=c8;PieseRot[g8,7]:=b8;PieseRot[h8,7]:=a8;
for i:=0 to 63 do
  kingidx[i]:=0;
kingidx[a1]:=1;
kingidx[b1]:=2;
kingidx[c1]:=3;
kingidx[d1]:=4;
kingidx[b2]:=5;
kingidx[c2]:=6;
kingidx[d2]:=7;
kingidx[c3]:=8;
kingidx[d3]:=9;
kingidx[d4]:=10;
end;

Procedure TableLoad;
begin

end;

Function isTable:boolean;
begin

end;

Function Probe(color:integer;ply:integer):integer;
var
  wk,bk,p,score,dir:integer;
begin
 
end;


end.
