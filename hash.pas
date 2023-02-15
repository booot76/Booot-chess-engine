unit hash;
// Юнит содержит функции, связанные с хеш подсистемой движка.
interface
uses params,bitboards,history,make;
Function GetRandom64(var count:integer):int64;
Function GetRandom32(var count:integer):cardinal;
Procedure FillZobrist;
Function GetHashKey(color : integer;EnPass : integer) : int64;
Function GetPawnKey : cardinal;
Function HashProbe(color : integer; depth : integer;ply:integer;alpha:integer;beta:integer):integer;
Procedure HashPVStore(color : integer; depth : integer;ply:integer;value:integer;move:integer);
Procedure HashBetaStore(color : integer; depth : integer;ply:integer;value:integer;move:integer);
Procedure HashAlphaStore(color : integer; depth : integer;ply:integer;value:integer);
Procedure HashNullStore(color : integer; depth : integer;ply:integer;value:integer);
Procedure ClearHash;
implementation
 Type Trandom64=array[1..833] of int64;
      Trandom32=array[1..128] of cardinal;
 const RandomValues64:Trandom64 = (
   $1D39247E33776D41, $2AF7398005AAA5C7, $44DB015024623547, $1C15F73E62A76AE2,
   $75834465489C0C89, $3290AC3A203001BF, $0FBBAD1F61042279, $683A908FF2FB60CA,
   $0D7E765D58755C10, $1A083822CEAFE02D, $1605D5F0E25EC3B0, $5021FF5CD13A2ED5,
   $40BDF15D4A672E32, $011355146FD56395, $5DB4832046F3D9E5, $239F8B2D7FF719CC,
   $05D1A1AE85B49AA1, $679F848F6E8FC971, $7449BBFF801FED0B, $7D11CDB1C3B7ADF0,
   $02C7709E781EB7CC, $73218F1C9510786C, $331478F3AF51BBE6, $4BB38DE5E7219443,
   $2A649C6EBCFD50FC, $0DBD98A352AFD40B, $07D2074B81D79217, $19F3C751D3E92AE1,
   $34AB30F062B19ABF, $7B0500AC42047AC4, $49452CA81A09D85D, $24AA6C514DA27500,
   $4C9F34427501B447, $14A68FD73C910841, $271B9B83461CBD93, $03488B95B0F1850F,
   $637B2B34FF93C040, $09D1BC9A3DD90A94, $3575668334A1DD3B, $735E2B97A4C45A23,
   $18727070F1BD400B, $1FCBACD259BF02E7, $5310A7C2CE9B6555, $3F983FE0FE5D8244,
   $1F74D14F7454A824, $51EBDC4AB9BA3035, $5C82C505DB9AB0FA, $7CF7FE8A3430B241,
   $3253A729B9BA3DDE, $0C74C368081B3075, $39BC6C87167C33E7, $7EF48F2B83024E20,
   $11D505D4C351BD7F, $6568FCA92C76A243, $4DE0B0F40F32A7B8, $16D693460CC37E5D,
   $42E240CB63689F2F, $6D2BDCDAE2919661, $42880B0236E4D951, $5F0F4A5898171BB6,
   $39F890F579F92F88, $13C5B5F47356388B, $63DC359D8D231B78, $6C16CA8AEA98AD76,
   $5355F900C2A82DC7, $07FB9F855A997142, $5093417AA8A7ED5E, $7BCBC38DA25A7F3C,
   $19FC8A768CF4B6D4, $637A7780DECFC0D9, $0249A47AEE0E41F7, $79AD695501E7D1E8,
   $14ACBAF4777D5776, $7145B6BECCDEA195, $5ABF2AC8201752FC, $24C3C94DF9C8D3F6,
   $3B6E2924F03912EA, $0CE26C0B95C980D9, $249CD132BFBF7CC4, $699D662AF4243939,
   $27E6AD7891165C3F, $0535F040B9744FF1, $54B3F4FA5F40D873, $72B12C32127FED2B,
   $6E954D3C7B411F47, $1A85AC909A24EAA1, $70AC4CD9F04F21F5, $79B89D3E99A075C2,
   $07B3E2B2B5C907B1, $2366E5B8C54F48B8, $2E4A9346CC3F7CF2, $1920C04D47267BBD,
   $07BF02C6B49E2AE9, $092237AC237F3859, $7F07F64EF8ED14D0, $0DE8DCA9F03CC54E,
   $1C1633264DB49C89, $33F22C3D0B0B38ED, $390E5FB44D01144B, $5BFEA5B4712768E9,
   $1E1032911FA78984, $1A74ACB964E78CB3, $4F80F7A035DAFB04, $6304D09A0B3738C4,
   $2171E64683023A08, $5B9B63EB9CEFF80C, $506AACF489889342, $1881AFC9A3A701D6,
   $6503080440750644, $5FD395339CDBF4A7, $6F927DBCF00C20F2, $7B32F7D1E03680EC,
   $39FD7620E7316243, $05A7E8A57DB91B77, $35889C6E15630A75, $4A750A09CE9573F7,
   $4F464CEC899A2F8A, $7538639CE705B824, $3C79A0FF5580EF7F, $6DE6C87F8477609D,
   $799E81F05BC93F31, $06536B8CF3428A8C, $17D7374C60087B73, $2246637CFF328532,
   $043FCAE60CC0EBA0, $120E449535DD359E, $70EB093B15B290CC, $73A1921916591CBD,
   $56436C9FE1A1AA8D, $6FAC4B70633B8F81, $3B215798D45DF7AF, $45F20042F24F1768,
   $130F80F4E8EB7462, $7F6712FFCFD75EA1, $2E623FD67468AA70, $5D2C5BC84BC8D8FC,
   $7EED120D54CF2DD9, $22FE545401165F1C, $491800E98FB99929, $008BD68E6AC10365,
   $5EC468145B7605F6, $1BEDE3A3AEF53302, $43539603D6C55602, $2A969B5C691CCB7A,
   $287832D392EFEE56, $65942C7B3C7E11AE, $5ED2D633CAD004F6, $21F08570F420E565,
   $3415938D7DA94E3C, $11B859E59ECB6350, $10CFF333E0ED804A, $28AED140BE0BB7DD,
   $45CC1D89724FA456, $5648F680F11A2741, $2D255069F0B7DAB3, $1BC5A38EF729ABD4,
   $6F2F054308F6A2BC, $2F2042F5CC5C2858, $480412BAB7F5BE2A, $2EF3AF4A563DFE43,
   $19AFE59AE451497F, $52593803DFF1E840, $74F076E65F2CE6F0, $11379625747D5AF3,
   $3CE5D2248682C115, $1DA4243DE836994F, $066F70B33FE09017, $4DC4DE189B671A1C,
   $51039AB7712457C3, $407A3F80C31FB4B4, $346EE9C5E64A6E7C, $33819A42ABE61C87,
   $21A007933A522A20, $2DF16F761598AA4F, $763C4A1371B368FD, $7793C46702E086A0,
   $57288E012AEB8D31, $5E336A2A4BC1C44B, $0BF692B38D079F23, $2C604A7A177326B3,
   $4850E73E03EB6064, $4FC447F1E53C8E1B, $305CA3F564268D99, $1AE182C8BC9474E8,
   $24FC4BD4FC5558CA, $6755178D58FC4E76, $69B97DB1A4C03DFE, $79B5B7C4ACC67C96,
   $7C6A82D64B8655FB, $1C684CB6C4D24417, $0EC97D2917456ED0, $6703DF9D2924E97E,
   $4547F57E42A7444E, $78E37644E7CAD29E, $7E9A44E9362F05FA, $08BD35CC38336615,
   $1315E5EB3A129ACE, $14061B871E04DF75, $5F1D9F9D784BA010, $3BBA57B68871B59D,
   $52B7ADEEDED1F73F, $77A255D83BC373F8, $57F4F2448C0CEB81, $595BE88CD210FFA7,
   $336F52F8FF4728E7, $274049DAC312AC71, $22F61BB6E437FDB5, $4F2A5CB07F6A35B3,
   $07D380BDA5BF7859, $16B9F7E06C453A21, $7BA2484C8A0FD54E, $73A678CAD9A2E38C,
   $39B0BF7DDE437BA2, $7CAF55C1BF8A4424, $18FCF680573FA594, $4C0563B89F495AC3,
   $40E087931A00930D, $0CFFA9412EB642C1, $68CA39053261169F, $7A1EE967D27579E2,
   $1D1D60E5076F5B6F, $3810E399B6F65BA2, $32095B6D4AB5F9B1, $35CAB62109DD038A,
   $290B24499FCFAFB1, $77A225A07CC2C6BD, $513E5E634C70E331, $4361C0CA3F692F12,
   $5941ACA44B20A45B, $528F7C8602C5807B, $52AB92BEB9613989, $1D1DFA2EFC557F73,
   $722FF175F572C348, $1D1260A51107FE97, $7A249A57EC0C9BA2, $04208FE9E8F7F2D6,
   $5A110C6058B920A0, $0CD9A497658A5698, $56FD23C8F9715A4C, $284C847B9D887AAE,
   $04FEABFBBDB619CB, $742E1E651C60BA83, $1A9632E65904AD3C, $081B82A13B51B9E2,
   $506E6744CD974924, $30183DB56FFC6A79, $0ED9B915C66ED37E, $5E11E86D5873D484,
   $7678647E3519AC6E, $1B85D488D0F20CC5, $5AB9FE6525D89021, $0D151D86ADB73615,
   $2865A54EDCC0F019, $13C42566AEF98FFB, $19E7AFEABE000731, $48CBFF086DDF285A,
   $7F9B6AF1EBF78BAF, $58627E1A149BBA21, $2CD16E2ABD791E33, $5363EFF5F0977996,
   $0CE2A38C344A6EED, $1A804AADB9CFA741, $107F30421D78C5DE, $501F65EDB3034D07,
   $37624AE5A48FA6E9, $157BAF61700CFF4E, $3A6C27934E31188A, $549503536ABCA345,
   $088E049589C432E0, $7943AEE7FEBF21B8, $6C3B8E3E336139D3, $364F6FFA464EE52E,
   $560F6DCEDC314222, $56963B0DCA418FC0, $16F50EDF91E513AF, $6F1955914B609F93,
   $565601C0364E3228, $6CB53939887E8175, $3AC7A9A18531294B, $3344C470397BBA52,
   $65D34954DAF3CEBD, $34B81B3FA97511E2, $3422061193D6F6A7, $071582401C38434D,
   $7A13F18BBEDC4FF5, $3C4097B116C524D2, $59B97885E2F2EA28, $19170A5DC3115544,
   $6F423357E7C6A9F9, $325928EE6E6F8794, $50E4366228B03343, $565C31F7DE89EA27,
   $30F5611484119414, $5873DB391292ED4F, $7BD94E1D8E17DEBC, $47D9F16864A76E94,
   $147AE053EE56E63C, $48C93882F9475F5F, $3A9BF55BA91F81CA, $59A11FBB3D9808E4,
   $0FD22063EDC29FCA, $33F256D8ACA0B0B9, $303031A8B4516E84, $35DD37D5871448AF,
   $69F6082B05542E4E, $6BFAFA33D7254B59, $1255ABB50D532280, $39AB4CE57F2D34F3,
   $693501D628297551, $462C58F97DD949BF, $4D454F8F19C5126A, $3BE83F4ECC2BDECB,
   $5C842B7E2819E230, $3A89142E007503B8, $23BC941D0A5061CB, $69F6760E32CD8021,
   $09C7E552BC76492F, $052F54934DA55CC9, $0107FCCF064FCF56, $098954D51FFF6580,
   $23B70EDB1955C4BF, $4330DE426430F69D, $4715ED43E8A45C0A, $28D7E4DAB780A08D,
   $0572B974F03CE0BB, $357D2E985E1419C7, $68D9ECBE2CF3D73F, $2FE4B17170E59750,
   $11317BA87905E790, $7FBF21EC8A1F45EC, $1725CABFCB045B00, $164E915CD5E2B207,
   $3E2B8BCBF016D66D, $3E7444E39328A0AC, $785B2B4FBCDE44B7, $49353FEA39BA63B1,
   $1DD01AAFCD53486A, $1FCA8A92FD719F85, $7C7C95D827357AFA, $18A6A990C8B35EBD,
   $4CCB7005C6B9C28D, $3BDBB92C43B17F26, $2A70B5B4F89695A2, $694C39A54A98307F,
   $37A0B174CFF6F36E, $54DBA84729AF48AD, $2E18BC1AD9704A68, $2DE0966DAF2F8B1C,
   $39C11D5B1E43A07E, $64972D68DEE33360, $14628D38D0C20584, $5BC0D2B6AB90A559,
   $52733C4335C6A72F, $7E75D99D94A70F4D, $6CED1983376FA72B, $17FCAACBF030BC24,
   $7B77497B32503B12, $0547EDDFB81CCB94, $79999CDFF70902CB, $4FFE1939438E9B24,
   $029626E3892D95D7, $12FAE24291F2B3F1, $63E22C147B9C3403, $4678B6D860284A1C,
   $5873888850659AE7, $0981DCD296A8736D, $1F65789A6509A440, $1FF38FED72E9052F,
   $6479EE5B9930578C, $67F28ECD2D49EECD, $56C074A581EA17FE, $5544F7D774B14AEF,
   $7B3F0195FC6F290F, $12153635B2C0CF57, $7F5126DBBA5E0CA7, $7A76956C3EAFB413,
   $3D5774A11D31AB39, $0A1B083821F40CB4, $7B4A38E32537DF62, $150113646D1D6E03,
   $4DA8979A0041E8A9, $3BC36E078F7515D7, $5D0A12F27AD310D1, $7F9D1A2E1EBE1327,
   $5A3A361B1C5157B1, $5CDD7D20903D0C25, $36833336D068F707, $4E68341F79893389,
   $2B9090168DD05F34, $43954B3252DC25E5, $3438C2B67F98E5E9, $10DCD78E3851A492,
   $5BC27AB5447822BF, $1B3CDB65F82CA382, $367B7896167B4C84, $3FCED1B0048EAC50,
   $29119B60369FFEBD, $1FFF7AC80904BF45, $2C12FB171817EEE7, $2F08DA9177DDA93D,
   $1B0CAB936E65C744, $3559EB1D04E5E932, $437B45B3F8D6F2BA, $43A9DC228CAAC9E9,
   $73B8B6675A6507FF, $1FC477DE4ED681DA, $67378D8ECCEF96CB, $6DD856D94D259236,
   $2319CE15B0B4DB31, $073973751F12DD5E, $0A8E849EB32781A5, $61925C71285279F5,
   $74C04BF1790C0EFE, $4DDA48153C94938A, $1D266D6A1CC0542C, $7440FB816508C4FE,
   $13328503DF48229F, $56BF7BAEE43CAC40, $4838D65F6EF6748F, $1E152328F3318DEA,
   $0F8419A348F296BF, $72C8834A5957B511, $57A023A73260B45C, $14EBC8ABCFB56DAE,
   $1FC10D0F989993E0, $5E68A2355B93CAE6, $244CFE79AE538BBE, $1D1D84FCCE371425,
   $51D2B1AB2DDFB636, $2FD7E4B9E72CD38C, $65CA5B96B7552210, $5D69A0D8AB3B546D,
   $604D51B25FBF70E2, $73AA8A564FB7AC9E, $1A8C1E992B941148, $2AC40A2703D9BEA0,
   $764DBEAE7FA4F3A6, $1E99B96E70A9BE8B, $2C5E9DEB57EF4743, $3A938FEE32D29981,
   $26E6DB8FFDF5ADFE, $469356C504EC9F9D, $48763C5B08D1908C, $3F6C6AF859D80055,
   $7F7CC39420A3A545, $1BFB227EBDF4C5CE, $09039D79D6FC5C5C, $0FE88B57305E2AB6,
   $209E8C8C35AB96DE, $7A7E393983325753, $56B6D0ECC617C699, $5FEA21EA9E7557E3,
   $367C1FA481680AF8, $4A1E3785A9E724E5, $1CFC8BED0D681639, $518D8549D140CAEA,
   $4ED0FE7E9DC91335, $64DBF0634473F5D2, $1761F93A44D5AEFE, $53898E4C3910DA55,
   $734DE8181F6EC39A, $2680B122BAA28D97, $298AF231C85BAFAB, $7983EED3740847D5,
   $66C1A2A1A60CD889, $1E17E49642A3E4C1, $6DB454E7BADC0805, $50B704CAB602C329,
   $4CC317FB9CDDD023, $66B4835D9EAFEA22, $219B97E26FFC81BD, $261E4E4C0A333A9D,
   $1FE2CCA76517DB90, $57504DFA8816EDBB, $39571FA04DC089C8, $1DDC0325259B27DE,
   $4F3F4688801EB9AA, $74F5D05C10CAB243, $38B6525C21A42B0E, $36F60E2BA4FA6800,
   $6B3593803173E0CE, $1C4CD6257C5A3603, $2F0C317D32ADAA8A, $258E5A80C7204C4B,
   $0B889D624D44885D, $74D14597E660F855, $54347F66EC8941C3, $6699ED85B0DFB40D,
   $2472F6207C2D0484, $42A1E7B5B459AEB5, $2B4F6451CC1D45EC, $63767572AE3D6174,
   $259E0BD101731A28, $116D0016CB948F09, $2CF9C8CA052F6E9F, $0B090A7560A968E3,
   $2BEEDDB2DDE06FF1, $58EFC10B06A2068D, $46E57A78FBD986E0, $2EAB8CA63CE802D7,
   $14A195640116F336, $7C0828DD624EC390, $574BBE77E6116AC7, $004456AF10F5FB53,
   $6BE9EA2ADF4321C7, $03219A39EE587A30, $49787FEF17AF9924, $21E9300CD8520548,
   $5B45E522E4B1B4EF, $349C3B3995091A36, $54490AD526F14431, $12A8F216AF9418C2,
   $001F837CC7350524, $1877B51E57A764D5, $22853B80F17F58EE, $193E1DE72D36D310,
   $33598080CE64A656, $252F59CF0D9F04BB, $523C8E176D113600, $1BDA0492E7E4586E,
   $21E0BD5026C619BF, $3B097ADAF088F94E, $0D14DEDB30BE846E, $795CFFA23AF5F6F4,
   $3871700761B3F743, $4A672B91E9E4FA16, $64C8E531BFF53B55, $241260ED4AD1E87D,
   $106C09B972D2E822, $7FBA195410E5CA30, $7884D9BC6CB569D8, $0647DFEDCD894A29,
   $63573FF03E224774, $4FC8E9560F91B123, $1DB956E450275779, $38D91274B9E9D4FB,
   $22EBEE47E2FBFCE1, $59F1F30CCD97FB09, $6FED53D75FD64E6B, $2E6D02C36017F67F,
   $29AA4D20DB084E9B, $364BE8D8B25396C1, $70CB6AF7C2D5BCF0, $18F076A4F7A2322E,
   $3F84470805E69B5F, $14C3251F06F90CF3, $3E003E616A6591E9, $3925A6CD0421AFF3,
   $61BDD1307C66E300, $3F8D5108E27E0D48, $240AB57A8B888B20, $7C87614BAF287E07,
   $6F02CDD06FFDB432, $21082C0466DF6C0A, $0215E577001332C8, $539BB9C3A48DB6CF,
   $2738259634305C14, $61CF4F94C97DF93D, $1B6BACA2AE4E125B, $758F450C88572E0B,
   $159F587D507A8359, $3063E962E045F54D, $60E8ED72C0DFF5D1, $7B64978555326F9F,
   $7D080D236DA814BA, $0C90FD9B083F4558, $106F72FE81E2C590, $7976033A39F7D952,
   $24EC0132764CA04B, $733EA705FAE4FA77, $34D8F77BC3E56167, $1E21F4F903B33FD9,
   $1D765E419FB69F6D, $530C088BA61EA5EF, $5D94337FBFAF7F5B, $1A4E4822EB4D7A59,
   $6FFE73E81B637FB3, $5DF957BC36D8B9CA, $64D0E29EEA8838B3, $08DD9BDFD96B9F63,
   $087E79E5A57D1D13, $6328E230E3E2B3FB, $1C2559E30F0946BE, $720BF5F26F4D2EAA,
   $30774D261CC609DB, $443F64EC5A371195, $4112CF68649A260E, $5813F2FAB7F5C5CA,
   $660D3257380841EE, $59AC2C7873F910A3, $6846963877671A17, $13B633ABFA3469F8,
   $40C0F5A60EF4CDCF, $4AF21ECD4377B28C, $57277707199B8175, $506C11B9D90E8B1D,
   $583CC2687A19255F, $4A29C6465A314CD1, $6D2DF21216235097, $35635C95FF7296E2,
   $22AF003AB672E811, $52E762596BF68235, $1AEBA33AC6ECC6B0, $144F6DE09134DFB6,
   $6C47BEC883A7DE39, $6AD047C430A12104, $25B1CFDBA0AB4067, $7C45D833AFF07862,
   $5092EF950A16DA0B, $1338E69C052B8E7B, $455A4B4CFE30E3F5, $6B02E63195AD0CF8,
   $6B17B224BAD6BF27, $51E0CCD25BB9C169, $5E0C89A556B9AE70, $50065E535A213CF6,
   $1C1169FA2777B874, $78EDEFD694AF1EED, $6DC93D9526A50E68, $6E97F453F06791ED,
   $32AB0EDB696703D3, $3A6853C7E70757A7, $31865CED6120F37D, $67FEF95D92607890,
   $1F2B1D1F15F6DC9C, $369E38A8965C6B65, $2A9119FF184CCCF4, $743C732873F24C13,
   $7B4A3D794A9A80D2, $3550C2321FD6109C, $371F77E76BB8417E, $6BFA9AAE5EC05779,
   $4D04F3FF001A4778, $63273522064480CA, $1F91508BFFCFC14A, $049A7F41061A9E60,
   $7CB6BE43A9F2FE9B, $08DE8A1C7797DA9B, $0F9887E6078735A1, $35B4071DBFC73A66,
   $230E343DFBA08D33, $43ED7F5A0FAE657D, $3A88A0FBBCB05C63, $21874B8B4D2DBC4F,
   $1BDEA12E35F6A8C9, $53C065C6C8E63528, $634A1D250E7A8D6B, $56B04D3B7651DD7E,
   $5E90277E7CB39E2D, $2C046F22062DC67D, $310BB459132D0A26, $3FA9DDFB67E2F199,
   $0E09B88E1914F7AF, $10E8B35AF3EEAB37, $1EEDECA8E272B933, $54C718BC4AE8AE5F,
   $01536D601170FC20, $11B534F885818A06, $6C8177F83F900978, $190E714FADA5156E,
   $3592BF39B0364963, $09C350C893AE7DC1, $2C042E70F8B383F2, $349B52E587A1EE60,
   $7B152FE3FF26DA89, $3E666E6F69AE2C15, $3B544EBE544C19F9, $6805A1E290CF2456,
   $24B33C9D7ED25117, $674733427B72F0C1, $0A804D18B7097475, $57E3306D881EDB4F,
   $4AE7D6A36EB5DBCB, $2D8D5432157064C8, $51E649DE1E7F268B, $0A328A1CEDFE552C,
   $07A3AEC79624C7DA, $04547DDC3E203C94, $190A98FD5071D263, $1A4FF12616EEFC89,
   $76F7FD1431714200, $30C05B1BA332F41C, $0D2636B81555A786, $46C9FEB55D120902,
   $4CEC0A73B49C9921, $4E9D2827355FC492, $19EBB029435DCB0F, $4659D2B743848A2C,
   $163EF2C96B33BE31, $74F85198B05A2E7D, $5A0F544DD2B1FB18, $03727073C2E134B1,
   $47F6AA2DE59AEA61, $352787BAA0D7C22F, $1853EAB63B5E0B35, $2BBDCDD7ED5C0860,
   $4F05DAF5AC8D77B0, $49CAD48CEBF4A71E, $7A4C10EC2158C4A6, $59E92AA246BF719E,
   $13AE978D09FE5557, $730499AF921549FF, $4E4B705B92903BA4, $7F577222C14F0A3A,
   $55B6344CF97AAFAE, $3862225B055B6960, $4AC09AFBDDD2CDB4, $5AF8E9829FE96B5F,
   $35FDFC5D3132C498, $310CB380DB6F7503, $687FBB46217A360E, $2102AE466EBB1148,
   $78549E1A3AA5E00D, $07A69AFDCC42261A, $44C118BFE78FEAAE, $79F4892ED96BD438,
   $1AF3DBE25D8F45DA, $75B4B0B0D2DEEEB4, $162ACEEFA82E1C84, $046E3ECAAF453CE9,
   $705D129681949A4C, $164781CE734B3C84, $1C2ED44081CE5FBD, $522E23F3925E319E,
   $177E00F9FC32F791, $2BC60A63A6F3B3F2, $222BBFAE61725606, $486289DDCC3D6780,
   $7DC7785B8EFDFC80, $0AF38731C02BA980, $1FAB64EA29A2DDF7, $64D9429322CD065A,
   $1DA058C67844F20C, $24C0E332B70019B0, $233003B5A6CFE6AD, $5586BD01C5C217F6,
   $5E5637885F29BC2B, $7EBA726D8C94094B, $0A56A5F0BFE39272, $579476A84EE20D06,
   $1E4C1269BAA4BF37, $17EFEE45B0DEE640, $1D95B0A5FCF90BC6, $13CBE0B699C2585D,
   $65FA4F227A2B6D79, $55F9E858292504D5, $42B5A03F71471A6F, $59300222B4561E00,
   $4E2F8642CA0712DC, $7CA9723FBB2E8988, $2785338347F2BA08, $461BB3A141E50E8C,
   $150F361DAB9DEC26, $1F6A419D382595F4, $64A53DC924FE7AC9, $142DE49FFF7A7C3D,
   $0C335248857FA9E7, $0A9C32D5EAE45305, $66C42178C4BBB92E, $71F1CE2490D20B07,
   $71BCC3D275AFE51A, $6728E8C83C334074, $16FBF83A12884624, $01A1549FD6573DA5,
   $5FA7867CAF35E149, $56986E2EF3ED091B, $117F1DD5F8886C61, $520D8C88C8FFE65F,
   $31D71DCE64B2C310, $7165B587DF898190, $257E6339DD2CF3A0, $1EF6E6DBB1961EC9,
   $70CC73D90BC26E24, $621A6B35DF0C3AD7, $003A93D8B2806962, $1C99DED33CB890A1,
   $4F3145DE0ADD4289, $50E4427A5514FB72, $77C621CC9FB3A483, $67A34DAC4356550B,

   $17E72B072F8E9756, $5557ACC65E78761B, $2764ECCBE96ECFB2, $22E2B3255597DAB5,
   $40B32EE44795C6C3, $7BAE0A4CB2583256, $73EEC81180A47ECB, $551FFF9FA941B218,
   $091508AF2FA889F5, $61B32AA868338AE9, $6C9938731A864401, $2F7043154CF2BC7D,
   $69262FC474850311, $0E652D1B7BC96113, $11228D7655A3DA89, $37AE15B14D0FEAA1,
   $02CE33625AC66F20, $78D9B035FB5D8A14, $717C91D21427860A, $2867CAB88BC9AF48,
   $763F1C2E494AFE4D, $48001E8CDDD27712, $400F3B30F32F543C, $466EFF70A285AA00,
   $195075C5B8CBADA7, $5D377D6DB6FF2011, $0F84AA0AB71E2426, $5BECF05E7D7BCA2D,
   $07AB01113585DAAB, $678D11E5357B18B5, $5CDB0D6E3BB98961, $2E1ECD285D5A3E7E,
   $59C229B1FB6FD0D8, $443AE63C0154137C, $37250C7121ECBDF4, $10AF9B4B85ACFD63,
   $4D43B710F78AABEB, $2457B45F9335B8F1, $21266DF0548EB860, $46549B3743E4A19E,
   $78EA4DE922FC2D8D, $5B3EDDE1A13A5AE7, $35D20752212F554A, $265FEAEC1AFDA596,
   $74D1BD329C0E30AB, $0134AFE791A71E87, $777E7D97520C11BB, $14977B441DC72BEF,
   $268A9649E9579A1B, $301DD855A5F141FE, $3394FD6846D3A0CB, $27367E9108810C10,$5157BEEC0E5D3846
   );
   RandomValues32 :Trandom32=(
  $A5AEED11, $57064E63, $5DB20CE3, $D28AE04F,
  $20F64862, $144B7AA0, $753BB59C, $6DFA47DB,
  $CAB78AE4, $A1379EA2, $F9BEBD62, $B75677FF,
  $FD918B6D, $11220B89, $82966048, $93B1FB86,
  $B44442B6, $04776D22, $A0BC6CDB, $B564B7E4,
  $9F5CD398, $B87AFF27, $499DA232, $BF4C9B53,
  $EC4BA037, $26F8D74A, $5929369E, $84869F67,
  $E7131655, $D1A68AAA, $F435C61A, $E25331FD,
  $2375DCDD, $43D3DD42, $D7BA2795, $BAB49EAC,
  $2D6F7983, $BCE018F1, $5EACDA5B, $59B39FE0,
  $14B977E2, $AF815BB8, $75394CE0, $6845E1BA,
  $3E24089F, $2136A050, $54366787, $1E1D5CD1,
  $D435CE14, $DF542DEB, $41ACAE6E, $436B5674,
  $8F7F40DE, $9A6F6263, $5B253198, $5A699CDA,
  $1E2879EE, $E7FED371, $8EEE8034, $D90ED7BE,
  $66EDF385, $7F3236A7, $454A43C5, $083D59EF,
  $3A967F4E, $9C9F4259, $80DBC8C9, $64818CD8,
  $E727C8C0, $E287C964, $3D32EDFC, $C7896B6E,
  $E0F238DE, $A246ECD8, $C7862FFC, $2AB3FC9E,
  $0B1A0201, $C517C35C, $EB601C9D, $219CF91E,
  $1C1FA7E2, $244D1E08, $17E3380F, $BCEEC204,
  $DD426360, $816F3D73, $EF12B9C5, $90AFE552,
  $DA33F6D3, $FEF4C677, $A3E9AC4E, $11CEE21C,
  $31CBF768, $BBF9D252, $2CFC17EB, $D46EEFF8,
  $8FAB6411, $AF618E04, $1685F7AE, $0A5DB5F3,
  $6036FDD3, $7C1BD830, $479E8313, $64F1D611,
  $853C999D, $433FF5CF, $F43AEF4B, $8AF00326,
  $92B89201, $459A298C, $301060D1, $08FD4B55,
  $92AAE7E4, $C5208CCF, $432D126A, $2991D880,
  $91E2DC51, $31F2670B, $334D06CB, $71E0EF0F,
  $6D322975, $6E163472, $AA926263, $8869728F,
  $6CE60337, $9E537956, $B3D2D3EB, $3D93532E
 );
Function GetRandom64(var count:integer):int64;
// Функция генерит случайное 64-битное число

begin
  inc(count);
  result:=RandomValues64[count];
end;

Function GetRandom32(var count:integer):cardinal;
// Функция генерит случайное 32-битное число
begin
  inc(count);
  result:=RandomValues32[count];
end;

Procedure FillZobrist;
// Заполнение хеш таблиц.
var
  i,count,con: integer;
begin
  count:=0;con:=0;
  for i:=0 to 63 do
    begin
     WPZobr[i]:=GetRandom64(count);
     BPZobr[i]:=GetRandom64(count);
     WNZobr[i]:=GetRandom64(count);
     BNZobr[i]:=GetRandom64(count);
     WBZobr[i]:=GetRandom64(count);
     BBZobr[i]:=GetRandom64(count);
     WRZobr[i]:=GetRandom64(count);
     BRZobr[i]:=GetRandom64(count);
     WQZobr[i]:=GetRandom64(count);
     BQZobr[i]:=GetRandom64(count);
     WKZobr[i]:=GetRandom64(count);
     BKZobr[i]:=GetRandom64(count);
     EnPassZobr[i]:=GetRandom64(count);
     WPZobr32[i]:=GetRandom32(con);
     BPZobr32[i]:=GetRandom32(con);
    end;
  ZColor:=GetRandom64(count);
end;

Function GetHashKey(color : integer;EnPass : integer) : int64;
// Функция возвращает хеш ключ текущей позиции
var
   temp : bitboard;
   res : int64;
   bit : integer;
  begin
    res:=0;
    temp:=AllPieses;
    while temp<>0 do
      begin
       bit:=BitScanForward(temp);
       case WhatPiese(bit) of
         empty : writeln('Error in BitBoards!');
         pawn : res:=res xor WPZobr[bit];
         -pawn : res:=res xor BPZobr[bit];
         knight : res:=res xor WNZobr[bit];
         -knight : res:=res xor BNZobr[bit];
         bishop : res:=res xor WBZobr[bit];
         -bishop : res:=res xor BBZobr[bit];
         rook : res:=res xor WRZobr[bit];
         -rook : res:=res xor BRZobr[bit];
         queen : res:=res xor WQZobr[bit];
         -queen : res:=res xor BQZobr[bit];
         king : res:=res xor WKZobr[bit];
         -king : res:=res xor BKZobr[bit];
         end;
        temp:=temp and NotOnly[bit]; 
      end;
    if EnPass<>0 then res:=res xor EnPassZobr[EnPass];
    if color=black then res:=res xor ZColor;
    Result:=res;
  end;

Function GetPawnKey : cardinal;
// Функция возвращает пешечный хеш ключ текущей позиции.
var
   temp : bitboard;
   res : cardinal;
   bit : integer;
  begin
    res:=0;
    temp:=WhitePawns or BlackPawns;
    while temp<>0 do
      begin
       bit:=BitScanForward(temp);
         case WhatPiese(bit) of
           empty : writeln('Error in BitBoards!');
           pawn : res:=res xor WPZobr32[bit];
           -pawn : res:=res xor BPZobr32[bit];
         end;
        temp:=temp and NotOnly[bit]; 
      end;
    Result:=res;
  end;

Function HashProbe(color : integer; depth : integer;ply:integer;alpha:integer;beta:integer):integer;
// Запрос в хеш. Если позиция уже была рассмотрена то возвращаем оценку
label l1;
var
   indx,i,res,minh,maxh:integer;
begin
res:=HashNoFound;
minh:=-mate;
maxh:=mate;
// Вычисляем индекс ячейки хеша где может храниться нужная нам информация
  indx:=tree[ply].HashKey and HashMask;
  if (color=white) then
     begin
       for i:=1 to 4 do
         if WhiteTable[indx][i].key=tree[ply].HashKey then
            begin
             // Эта позиция уже рассматривалась и мы можем использовать информацию
             // Как минимум можно взять лучший ранее рассматриваемый ход из позиции (если он есть)
               WhiteTable[indx][i].age:=age;
               tree[ply].Hashmove:=WhiteTable[indx][i].move;
             // Если глубина перебора, сохраненная в хеше больше или равна текущей, то все готово для хеш-отсечения
             // Ставим ограничение на возраст хеша:
               if (WhiteTable[indx][i].mindepth>=depth)  then
                begin
                 minh:=WhiteTable[indx][i].minvalue;
                 if (minh>=beta) then
                  begin
                   result:=minh;
                   exit;
                  end;
                end;
              if (WhiteTable[indx][i].maxdepth>=depth)  then
                begin
                  maxh:=WhiteTable[indx][i].maxvalue;
                  if (maxh<=alpha) then
                   begin
                    result:=maxh;
                    exit;
                   end;
                end;
              if minh=maxh then res:=maxh;
              break;
            end;
     end
else
     begin
       for i:=1 to 4 do
         if BlackTable[indx][i].key=tree[ply].HashKey then
            begin
              // Эта позиция уже рассматривалась и мы можем использовать информацию
             // Как минимум можно взять лучший ранее рассматриваемый ход из позиции (если он есть)
               BlackTable[indx][i].age:=age;
               tree[ply].Hashmove:=BlackTable[indx][i].move;
             // Если глубина перебора, сохраненная в хеше больше или равна текущей, то все готово для хеш-отсечения
               if (BlackTable[indx][i].mindepth>=depth)  then
                begin
                minh:=BlackTable[indx][i].minvalue;
                if (minh>=beta) then
                  begin
                   result:=minh;
                   exit;
                  end;
                end;
               if (BlackTable[indx][i].maxdepth>=depth)   then
                begin
                 maxh:=BlackTable[indx][i].maxvalue;
                 if (maxh<=alpha) then
                  begin
                   result:=maxh;
                   exit;
                  end;
                end;
              if minh=maxh then res:=maxh;
              break;
            end;
     end;
Result:=res;
 end;

Procedure HashPVStore(color : integer; depth : integer;ply:integer;value:integer;move:integer);
// Запись результата перебора позиции в хеш
var
   indx,bestentry,bestvalue,i,score,tage,agedelta : integer;
begin
  bestentry:=0;
  bestvalue:=-Mate;
  indx := tree[ply].HashKey and HashMask;
  if color=white then
     begin
       for i:=1 to 4 do
         begin
           if WhiteTable[indx][i].key=tree[ply].HashKey then
             begin
             // Запись об этой позиции в хеше уже есть!
               WhiteTable[indx][i].age:=age;
               if (depth>WhiteTable[indx][i].draft) then
                begin
                 WhiteTable[indx][i].draft:=depth;
                end;
               if (depth>=WhiteTable[indx][i].movedepth)  then
                 begin
                   WhiteTable[indx][i].movedepth:=depth;
                   WhiteTable[indx][i].move:=move;
                 end;
               if (depth>=WhiteTable[indx][i].mindepth)  then
                 begin
                   WhiteTable[indx][i].mindepth:=depth;
                   WhiteTable[indx][i].minvalue:=value;
                 end;
               if (depth>=WhiteTable[indx][i].maxdepth) then
                 begin
                   WhiteTable[indx][i].maxdepth:=depth;
                   WhiteTable[indx][i].maxvalue:=value;
                 end;
              exit;
             end;
      // Вычисляем "оценку" имеющихся ячеек для схемы замещения. Более предпочитетльными для замещения являются "старые" записи
      // и записи с минимальной глубиной вхождения
          tage:=WhiteTable[indx][i].age;
          agedelta:=abs(age-tage);
          score:=agedelta*256-WhiteTable[indx][i].draft;
          if score>bestvalue then
            begin
              bestvalue:=score;
              bestentry:=i;
            end;
         end;
    // Найдена предпочтительная ячейка для замещения - записываем в нее информацию по текущей позиции
       WhiteTable[indx][bestentry].key:=tree[ply].HashKey;
       WhiteTable[indx][bestentry].move:=move;
       WhiteTable[indx][bestentry].age:=age;
       WhiteTable[indx][bestentry].draft:=depth;
       WhiteTable[indx][bestentry].minvalue:=value;
       WhiteTable[indx][bestentry].mindepth:=depth;
       WhiteTable[indx][bestentry].movedepth:=depth;
       WhiteTable[indx][bestentry].maxdepth:=depth;
       WhiteTable[indx][bestentry].maxvalue:=value;
     end
else begin
       for i:=1 to 4 do
         begin
           if BlackTable[indx][i].key=tree[ply].HashKey then
             begin
             // Запись об этой позиции в хеше уже есть!
               BlackTable[indx][i].age:=age;
               if (depth>BlackTable[indx][i].draft)  then
                begin
                 BlackTable[indx][i].draft:=depth;
                end;
               if depth>=BlackTable[indx][i].movedepth then
                 begin
                   BlackTable[indx][i].movedepth:=depth;
                   BlackTable[indx][i].move:=move;
                 end;
               if (depth>=BlackTable[indx][i].mindepth)  then
                 begin
                   BlackTable[indx][i].mindepth:=depth;
                   BlackTable[indx][i].minvalue:=value;
                 end;
               if (depth>=BlackTable[indx][i].maxdepth)  then
                 begin
                   BlackTable[indx][i].maxdepth:=depth;
                   BlackTable[indx][i].maxvalue:=value;
                 end;
              exit;
             end;
      // Вычисляем "оценку" имеющихся ячеек для схемы замещения. Более предпочитетльными для замещения являются "старые" записи
      // и записи с минимальной глубиной вхождения
          tage:=BlackTable[indx][i].age;
          agedelta:=abs(age-tage);
          score:=agedelta*256-BlackTable[indx][i].draft;
          if score>bestvalue then
            begin
              bestvalue:=score;
              bestentry:=i;
            end;
         end;
    // Найдена предпочтительная ячейка для замещения - записываем в нее информацию по текущей позиции
       BlackTable[indx][bestentry].key:=tree[ply].HashKey;
       BlackTable[indx][bestentry].move:=move;
       BlackTable[indx][bestentry].age:=age;
       BlackTable[indx][bestentry].draft:=depth;
       BlackTable[indx][bestentry].minvalue:=value;
       BlackTable[indx][bestentry].mindepth:=depth;
       BlackTable[indx][bestentry].movedepth:=depth;
       BlackTable[indx][bestentry].maxdepth:=depth;
       BlackTable[indx][bestentry].maxvalue:=value;
     end;
end;

Procedure HashBetaStore(color : integer; depth : integer;ply:integer;value:integer;move:integer);
// Запись результата перебора позиции в хеш
var
   indx,bestentry,bestvalue,i,score,tage,agedelta : integer;
begin
  bestentry:=0;
  bestvalue:=-Mate;
  indx := tree[ply].HashKey and HashMask;
  if color=white then
     begin
       for i:=1 to 4 do
         begin
           if WhiteTable[indx][i].key=tree[ply].HashKey then
             begin
             // Запись об этой позиции в хеше уже есть!
               WhiteTable[indx][i].age:=age;
               if (depth>WhiteTable[indx][i].draft)then
                begin
                 WhiteTable[indx][i].draft:=depth;
                end;
               if depth>=WhiteTable[indx][i].movedepth then
                 begin
                   WhiteTable[indx][i].movedepth:=depth;
                   WhiteTable[indx][i].move:=move;
                 end;
               if (depth>=WhiteTable[indx][i].mindepth)  then
                 begin
                   WhiteTable[indx][i].mindepth:=depth;
                   WhiteTable[indx][i].minvalue:=value;
                 end;
              exit;
             end;
      // Вычисляем "оценку" имеющихся ячеек для схемы замещения. Более предпочитетльными для замещения являются "старые" записи
      // и записи с минимальной глубиной вхождения
          tage:=WhiteTable[indx][i].age;
          agedelta:=abs(age-tage);
          score:=agedelta*256-WhiteTable[indx][i].draft;
          if score>bestvalue then
            begin
              bestvalue:=score;
              bestentry:=i;
            end;
         end;
    // Найдена предпочтительная ячейка для замещения - записываем в нее информацию по текущей позиции
       WhiteTable[indx][bestentry].key:=tree[ply].HashKey;
       WhiteTable[indx][bestentry].move:=move;
       WhiteTable[indx][bestentry].age:=age;
       WhiteTable[indx][bestentry].draft:=depth;
       WhiteTable[indx][bestentry].minvalue:=value;
       WhiteTable[indx][bestentry].mindepth:=depth;
       WhiteTable[indx][bestentry].movedepth:=depth;
       WhiteTable[indx][bestentry].maxdepth:=0;
       WhiteTable[indx][bestentry].maxvalue:=0;
     end
else begin
       for i:=1 to 4 do
         begin
           if BlackTable[indx][i].key=tree[ply].HashKey then
             begin
             // Запись об этой позиции в хеше уже есть!
               BlackTable[indx][i].age:=age;
               if (depth>BlackTable[indx][i].draft)  then
                begin
                 BlackTable[indx][i].draft:=depth;
                end;
               if depth>=BlackTable[indx][i].movedepth then
                 begin
                   BlackTable[indx][i].movedepth:=depth;
                   BlackTable[indx][i].move:=move;
                 end;
               if (depth>=BlackTable[indx][i].mindepth)  then
                 begin
                   BlackTable[indx][i].mindepth:=depth;
                   BlackTable[indx][i].minvalue:=value;
                 end;
              exit;
             end;
      // Вычисляем "оценку" имеющихся ячеек для схемы замещения. Более предпочитетльными для замещения являются "старые" записи
      // и записи с минимальной глубиной вхождения
          tage:=BlackTable[indx][i].age;
          agedelta:=abs(age-tage);
          score:=agedelta*256-BlackTable[indx][i].draft;
          if score>bestvalue then
            begin
              bestvalue:=score;
              bestentry:=i;
            end;
         end;
    // Найдена предпочтительная ячейка для замещения - записываем в нее информацию по текущей позиции
       BlackTable[indx][bestentry].key:=tree[ply].HashKey;
       BlackTable[indx][bestentry].move:=move;
       BlackTable[indx][bestentry].age:=age;
       BlackTable[indx][bestentry].draft:=depth;
       BlackTable[indx][bestentry].minvalue:=value;
       BlackTable[indx][bestentry].mindepth:=depth;
       BlackTable[indx][bestentry].movedepth:=depth;
       BlackTable[indx][bestentry].maxdepth:=0;
       BlackTable[indx][bestentry].maxvalue:=0;
     end;
end;
Procedure HashAlphaStore(color : integer; depth : integer;ply:integer;value:integer);
// Запись результата перебора позиции в хеш
var
   indx,bestentry,bestvalue,i,score,tage,agedelta : integer;
begin
  bestentry:=0;
  bestvalue:=-Mate;
  indx := tree[ply].HashKey and HashMask;
  if color=white then
     begin
       for i:=1 to 4 do
         begin
           if WhiteTable[indx][i].key=tree[ply].HashKey then
             begin
             // Запись об этой позиции в хеше уже есть!
               WhiteTable[indx][i].age:=age;
               if (depth>WhiteTable[indx][i].draft) then
                begin
                 WhiteTable[indx][i].draft:=depth;
                end;
               if (depth>=WhiteTable[indx][i].maxdepth)  then
                 begin
                   WhiteTable[indx][i].maxdepth:=depth;
                   WhiteTable[indx][i].maxvalue:=value;
                 end;
              exit;
             end;
      // Вычисляем "оценку" имеющихся ячеек для схемы замещения. Более предпочитетльными для замещения являются "старые" записи
      // и записи с минимальной глубиной вхождения
          tage:=WhiteTable[indx][i].age;
          agedelta:=abs(age-tage);
          score:=agedelta*256-WhiteTable[indx][i].draft;
          if score>bestvalue then
            begin
              bestvalue:=score;
              bestentry:=i;
            end;
         end;
    // Найдена предпочтительная ячейка для замещения - записываем в нее информацию по текущей позиции
       WhiteTable[indx][bestentry].key:=tree[ply].HashKey;
       WhiteTable[indx][bestentry].move:=0;
       WhiteTable[indx][bestentry].age:=age;
       WhiteTable[indx][bestentry].draft:=depth;
       WhiteTable[indx][bestentry].minvalue:=0;
       WhiteTable[indx][bestentry].mindepth:=0;
       WhiteTable[indx][bestentry].movedepth:=0;
       WhiteTable[indx][bestentry].maxdepth:=depth;
       WhiteTable[indx][bestentry].maxvalue:=value;
     end
else begin
       for i:=1 to 4 do
         begin
           if BlackTable[indx][i].key=tree[ply].HashKey then
             begin
             // Запись об этой позиции в хеше уже есть!
               BlackTable[indx][i].age:=age;
               if (depth>BlackTable[indx][i].draft)  then
                begin
                 BlackTable[indx][i].draft:=depth;
                end;
               if (depth>=BlackTable[indx][i].maxdepth)  then
                 begin
                   BlackTable[indx][i].maxdepth:=depth;
                   BlackTable[indx][i].maxvalue:=value;
                 end;
              exit;
             end;
      // Вычисляем "оценку" имеющихся ячеек для схемы замещения. Более предпочитетльными для замещения являются "старые" записи
      // и записи с минимальной глубиной вхождения
          tage:=BlackTable[indx][i].age;
          agedelta:=abs(age-tage);
          score:=agedelta*256-BlackTable[indx][i].draft;
          if score>bestvalue then
            begin
              bestvalue:=score;
              bestentry:=i;
            end;
         end;
    // Найдена предпочтительная ячейка для замещения - записываем в нее информацию по текущей позиции
       BlackTable[indx][bestentry].key:=tree[ply].HashKey;
       BlackTable[indx][bestentry].move:=0;
       BlackTable[indx][bestentry].age:=age;
       BlackTable[indx][bestentry].draft:=depth;
       BlackTable[indx][bestentry].minvalue:=0;
       BlackTable[indx][bestentry].mindepth:=0;
       BlackTable[indx][bestentry].movedepth:=0;
       BlackTable[indx][bestentry].maxdepth:=depth;
       BlackTable[indx][bestentry].maxvalue:=value;
     end;
end;
Procedure HashNullStore(color : integer; depth : integer;ply:integer;value:integer);
// Запись результата перебора позиции в хеш
var
   indx,bestentry,bestvalue,i,score,tage,agedelta : integer;
begin
  bestentry:=0;
  bestvalue:=-Mate;
  indx := tree[ply].HashKey and HashMask;
  if color=white then
     begin
       for i:=1 to 4 do
         begin
           if WhiteTable[indx][i].key=tree[ply].HashKey then
             begin
             // Запись об этой позиции в хеше уже есть!
               WhiteTable[indx][i].age:=age;
               if (depth>WhiteTable[indx][i].draft)  then  WhiteTable[indx][i].draft:=depth;
               if (depth>=WhiteTable[indx][i].mindepth) then
                 begin
                   WhiteTable[indx][i].mindepth:=depth;
                   WhiteTable[indx][i].minvalue:=value;
                 end;
              exit;
             end;
      // Вычисляем "оценку" имеющихся ячеек для схемы замещения. Более предпочитетльными для замещения являются "старые" записи
      // и записи с минимальной глубиной вхождения
          tage:=WhiteTable[indx][i].age;
          agedelta:=abs(age-tage);
          score:=agedelta*256-WhiteTable[indx][i].draft;
          if score>bestvalue then
            begin
              bestvalue:=score;
              bestentry:=i;
            end;
         end;
    // Найдена предпочтительная ячейка для замещения - записываем в нее информацию по текущей позиции
       WhiteTable[indx][bestentry].key:=tree[ply].HashKey;
       WhiteTable[indx][bestentry].move:=0;
       WhiteTable[indx][bestentry].age:=age;
       WhiteTable[indx][bestentry].draft:=depth;
       WhiteTable[indx][bestentry].minvalue:=value;
       WhiteTable[indx][bestentry].mindepth:=depth;
       WhiteTable[indx][bestentry].movedepth:=0;
       WhiteTable[indx][bestentry].maxdepth:=0;
       WhiteTable[indx][bestentry].maxvalue:=0;
     end
else begin
       for i:=1 to 4 do
         begin
           if BlackTable[indx][i].key=tree[ply].HashKey then
             begin
             // Запись об этой позиции в хеше уже есть!
               BlackTable[indx][i].age:=age;
               if (depth>BlackTable[indx][i].draft) then  BlackTable[indx][i].draft:=depth;
               if (depth>=BlackTable[indx][i].mindepth)  then
                 begin
                   BlackTable[indx][i].mindepth:=depth;
                   BlackTable[indx][i].minvalue:=value;
                 end;
              exit;
             end;
      // Вычисляем "оценку" имеющихся ячеек для схемы замещения. Более предпочитетльными для замещения являются "старые" записи
      // и записи с минимальной глубиной вхождения
          tage:=BlackTable[indx][i].age;
          agedelta:=abs(age-tage);
          score:=agedelta*256-BlackTable[indx][i].draft;
          if score>bestvalue then
            begin
              bestvalue:=score;
              bestentry:=i;
            end;
         end;
    // Найдена предпочтительная ячейка для замещения - записываем в нее информацию по текущей позиции
       BlackTable[indx][bestentry].key:=tree[ply].HashKey;
       BlackTable[indx][bestentry].move:=0;
       BlackTable[indx][bestentry].age:=age;
       BlackTable[indx][bestentry].draft:=depth;
       BlackTable[indx][bestentry].minvalue:=value;
       BlackTable[indx][bestentry].mindepth:=depth;
       BlackTable[indx][bestentry].movedepth:=0;
       BlackTable[indx][bestentry].maxdepth:=0;
       BlackTable[indx][bestentry].maxvalue:=0;
     end;
end;
Procedure ClearHash;
 // Очищаем хеш (используется только при начале новой игры).
var
  i,j:integer;
begin
  For i:=0 to HashSize do
   for j:=1 to 4 do
   begin
    WhiteTable[i][j].key:=0;
    WhiteTable[i][j].move:=0;
    WhiteTable[i][j].minvalue:=0;
    WhiteTable[i][j].maxvalue:=0;
    WhiteTable[i][j].age:=0;
    WhiteTable[i][j].draft:=0;
    WhiteTable[i][j].mindepth:=0;
    WhiteTable[i][j].movedepth:=0;
    WhiteTable[i][j].maxdepth:=0;
    BlackTable[i][j].key:=0;
    BlackTable[i][j].move:=0;
    BlackTable[i][j].minvalue:=0;
    BlackTable[i][j].maxvalue:=0;
    BlackTable[i][j].age:=0;
    BlackTable[i][j].draft:=0;
    BlackTable[i][j].mindepth:=0;
    BlackTable[i][j].movedepth:=0;
    BlackTable[i][j].maxdepth:=0;
   end;
  For i:=0 to PHashSize do
   begin
    PTable[i].key:=0;
    PTable[i].wpassvector:=0;
    PTable[i].bpassvector:=0;
   end;
end;


end.



