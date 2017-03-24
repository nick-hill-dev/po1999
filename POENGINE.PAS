unit POENGINE;

{*** The main game engine ***}
{*** Game play area dimensions: 5,5,540,475 ***}

interface

var
  {* 8 players can have 5 missiles on screen at once}
  {* Maximum players: 15}
    NumLives, PCOL: Array[1..15] of ShortInt;
    X, Y, DIR: Array[1..15] of Integer;
    NumKills, Alive: Array[1..15] of Integer;
    MissDIR, MissX, MissY: Array[1..15,1..20] of Integer;
    NumActiveMissiles, MaxActiveMissiles: Array[1..15] of shortint;
    StillInGame: Array[1..15] of ShortInt;
  {* The keys each player uses}
    KUp, KDown, KLeft, KRight, KFire: array[1..8] of Char;
  {* Number of each type of player or object}
    NumPlayers, NumPlayersAlive: Integer;
    NumAIPlayers, NumHumanPlayers: Integer;
    NumObjects, MaxObjects: Integer;
  {* Object variables}
    ObjX, ObjY, ObjNum: Array[1..20] of Integer;
  {* AI variables}
    VICTIM: Array[1..15] of ShortInt;
    VICTIMTYPE: Array[1..15] of ShortInt;
    LevAISkill: Integer;
  {* For Control Loop variables}
    A, D, G: Integer;
  {* The key caught from the keyboard}
    C: Char;
  {* Second delay amount}
    SDelay: Integer;

{* Accessible procedures and functions}
  procedure DrawBorders;
  procedure DrawStats;
  procedure DrawBoard;
  procedure DrawPlayer(NUM: Integer);
  procedure CreateMissile(PLN: Integer);
  procedure HideMissile(PLN,N: Integer);
  procedure DelMissile(PLN,N: Integer);
  procedure LoseLife(Z, PLN: Integer);
  procedure DrawObjects;
  procedure CreateObject;
  procedure DeleteObject(NUM: Integer);
  procedure CheckObjCollision(PLN: Integer);
  procedure ChooseVictim(NUM: Integer);
  procedure ProcessAI(NUM: Integer);
  procedure CheckMissCollision(PLN,MISSNUM,CX,CY: Integer);
  procedure ProcessMissiles(PLN: Integer);
  procedure PlayLevel;

implementation
uses crt, graph;


procedure DrawBorders;
begin
  SetFillStyle(1,7); Bar(0,0,544,4); Bar(0,0,4,479);
  Bar(541,0,544,479); Bar(0,476,544,479);
end;


procedure DrawStats;
var
  E,F: Integer;
  I2S: String;
begin
  SetFillStyle(1,0); SetTextStyle(DefaultFont,HorizDir,1);
  for E:=0 to NumPlayers-1 do Bar(553,(E*27)+20,627,(E*27)+41);
  {* Draw in lives...etc}
  for E:=0 to NumPlayers-1 do begin
    if Alive[E+1]=1 then begin {* If player alive...}
      SetColor(8); for F:=1 to 5 do Circle(545+(F*14),(E*27)+28,5);
      for F:=1 to NumLives[E+1] do begin
        SetFillStyle(1,PCOL[E+1]); SetColor(PCOL[E+1]);
        Circle(545+(F*14),(E*27)+28,5);
        PieSlice(545+(F*14),(E*27)+28,0,360,3);
      end;
      STR(NumKills[E+1],I2S); SetColor(15); OutTextXY(610,(E*27)+31,I2S);
    end else begin {* Player dead!}
      SetFillStyle(1,15); Bar(553,(E*27)+20,627,(E*27)+41);
      if StillInGame[E+1]=1 then begin
        SetFillStyle(1,PCOL[E+1]); SetColor(PCOL[E+1]);
        PieSlice(557,(E*27)+26,0,360,5);
        STR(NumKills[E+1],I2S); SetColor(0); OutTextXY(560,(E*27)+31,'Kills: '+I2S);
      end;
    end;
  end;
end;


procedure DrawBoard;
begin
  SetFillStyle(1,0); Bar(5,5,540,475);
  DrawBorders;
  SetFillStyle(1,1); Bar(545,0,639,479);
  SetFillStyle(1,9); Bar(547,2,637,477);
  SetFillStyle(1,15); Bar(550,10,630,426);
  DrawStats;
end;


procedure DrawPlayer(NUM: Integer);
begin
  SetColor(PCOL[NUM]);
  {* Draw the player onto the board}
  if DIR[NUM]=1 then begin
    MoveTo(X[NUM],Y[NUM]-10); LineTo(X[NUM]-10,Y[NUM]+10);
    LineTo(X[NUM]+10,Y[NUM]+10); LineTo(X[NUM],Y[NUM]-10);
  end else if DIR[NUM]=2 then begin
    MoveTo(X[NUM],Y[NUM]+10); LineTo(X[NUM]-10,Y[NUM]-10);
    LineTo(X[NUM]+10,Y[NUM]-10); LineTo(X[NUM],Y[NUM]+10);
  end else if DIR[NUM]=3 then begin
    MoveTo(X[NUM]-10,Y[NUM]); LineTo(X[NUM]+10,Y[NUM]-10);
    LineTo(X[NUM]+10,Y[NUM]+10); LineTo(X[NUM]-10,Y[NUM]);
  end else if DIR[NUM]=4 then begin
    MoveTo(X[NUM]+10,Y[NUM]); LineTo(X[NUM]-10,Y[NUM]-10);
    LineTo(X[NUM]-10,Y[NUM]+10); LineTo(X[NUM]+10,Y[NUM]);
  end;
end;


procedure CreateMissile(PLN: Integer);
begin
  {* Create a new missile!}
  if NumActiveMissiles[PLN]<MaxActiveMissiles[PLN] then begin
    NumActiveMissiles[PLN]:=NumActiveMissiles[PLN]+1;
    MissX[PLN,NumActiveMissiles[PLN]]:=X[PLN];
    MissY[PLN,NumActiveMissiles[PLN]]:=Y[PLN];
    MissDIR[PLN,NumActiveMissiles[PLN]]:=DIR[PLN];
  end;
end;


procedure HideMissile(PLN,N: Integer);
begin
  {* Clear missile from display}
  MoveTo(MissX[PLN,N],MissY[PLN,N]); SetColor(0);
  if MissDIR[PLN,N]=1 then LineTo(MissX[PLN,N],MissY[PLN,N]-50);
  if MissDIR[PLN,N]=2 then LineTo(MissX[PLN,N],MissY[PLN,N]+50);
  if MissDIR[PLN,N]=3 then LineTo(MissX[PLN,N]-50,MissY[PLN,N]);
  if MissDIR[PLN,N]=4 then LineTo(MissX[PLN,N]+50,MissY[PLN,N]);
end;


procedure DelMissile(PLN,N: Integer);
begin
  {* Clear missile from display}
  HideMissile(PLN,N);
  if NumActiveMissiles[PLN]>0 then begin
    {* Actually delete missile}
    MissX[PLN,N]:=MissX[PLN,NumActiveMissiles[PLN]];
    MissY[PLN,N]:=MissY[PLN,NumActiveMissiles[PLN]];
    MissDIR[PLN,N]:=MissDIR[PLN,NumActiveMissiles[PLN]];
    NumActiveMissiles[PLN]:=NumActiveMissiles[PLN]-1;
  end;
end;


procedure LoseLife(Z, PLN: Integer);
var LX,LY,NUM,B: Integer;
begin
  NumLives[Z]:=NumLives[Z]-1;
  LX:=X[Z]; LY:=Y[Z];
  {* Flash player}
  SetFillStyle(1,PCOL[PLN]); Bar(LX-10,LY-10,LX+10,LY+10);
  {* Give credit where credit is due... :}
  NumKills[PCOL[PLN]]:=NumKills[PCOL[PLN]]+1;
  {* And if player is truely dead... THEN KILL 'IM!}
  if NumLives[Z]<1 then begin
    {* Delete all missiles}
    for B:=1 to NumActiveMissiles[Z] do DelMissile(Z,B);
    Alive[Z]:=0;
    NumPlayersAlive:=NumPlayersAlive-1;
    Sound(900); Delay(500); Sound(1900); Delay(200); NoSound;
    {* Hide player from view}
    SetFillStyle(1,0); Bar(LX-10,LY-10,LX+10,LY+10);
  end;
end;


procedure DrawObjects;
var
  B,E,ONum,OX,OY: Integer;
begin
  for B:=1 to NumObjects do begin
    OX:=ObjX[B];
    OY:=ObjY[B];
    ONum:=ObjNum[B];
    if ONum=1 then begin
      for E:=10 downto 1 do begin
        SetColor(E); SetFillStyle(1,E);
        Circle(OX,OY,E);
      end;
    end;
    if ONum=2 then begin
      for E:=-1 to 1 do begin
        SetColor(9); MoveTo(OX+E,OY-10); LineTo(OX+E,OY+10);
        MoveTo(OX-10,OY+E); LineTo(OX+10,OY+E);
      end;
    end;
    if ONum=3 then begin
      SetColor(3); Circle(OX,OY,10);
      SetColor(4); MoveTo(OX-10,OY-10); LineTo(OX+10,OY+10);
      MoveTo(OX+10,OY-10); LineTo(OX-10,OY+10);
    end;
  end;
end;


procedure CreateObject;
var ONum,OX,OY: Integer;
begin
  if (NumObjects<MaxObjects) and (NumObjects<20) then begin
    NumObjects:=NumObjects+1; ONum:=random(20);
    OX:=Random(530)+5; OY:=Random(470)+5;
    if ONum<12 then ObjNum[NumObjects]:=1;
    if (ONum>11) and (ONum<18) then ObjNum[NumObjects]:=2;
    if (ONum>17) then ObjNum[NumObjects]:=3;
    ObjX[NumObjects]:=OX; ObjY[NumObjects]:=OY;
  end;
end;


procedure DeleteObject(NUM: Integer);
begin
  {* Hide it}
  SetFillStyle(1,0);
  Bar(ObjX[NUM]-10,ObjY[NUM]-10,ObjX[NUM]+10,ObjY[NUM]+10);
  {* Actually delete it}
  if NumObjects>0 then begin
    ObjX[NUM]:=ObjX[NumObjects];
    ObjY[NUM]:=ObjY[NumObjects];
    ObjNum[NUM]:=ObjNum[NumObjects];
    NumObjects:=NumObjects-1;
  end;
end;


procedure CheckObjCollision(PLN: Integer);
var B,E,PX,PY,OX,OY,ONum: Integer;
begin
  PX:=X[PLN]; PY:=Y[PLN];
  for B:=1 to NumObjects do begin
    OX:=ObjX[B]; OY:=ObjY[B]; ONum:=ObjNum[B];
    if (PX>=OX-15) and (PX<=OX+15) and (PY>=OY-15) and (PY<=OY+15) then begin
      {* Add object to player}
      {* 1=New life, 2=Increase active missiles, 3=Kill all}
      sound(500); Delay(100); Sound(300); Delay(200); NoSound;
      if ONum=1 then if NumLives[PLN]<5 then NumLives[PLN]:=NumLives[PLN]+1;
      if ONum=2 then MaxActiveMissiles[PLN]:=MaxActiveMissiles[PLN]+1;
      if ONum=3 then begin
        for E:=1 to NumPlayers do begin
          if (Alive[E]=1) and (E<>PLN) then LoseLife(E,PLN);
        end;
      end;
      {* Delete the object}
      DeleteObject(B);
      {* Show new stats}
      DrawStats;
    end;
  end;
end;


procedure ChooseVictim(NUM: Integer);
var E: Integer;
begin
  {* Choose victim or object to chase after}
  if Random(5)>LevAISkill then begin
    VICTIMTYPE[NUM]:=2;
    if NumObjects>0 then VICTIM[NUM]:=Random(NumObjects)+1
    else VICTIMTYPE[NUM]:=1;
  end else VICTIMTYPE[NUM]:=1;
  if VICTIMTYPE[NUM]=1 then begin
    VICTIM[NUM]:=Random(NumPlayers)+1;
    While Alive[VICTIM[NUM]]=0 DO VICTIM[NUM]:=Random(NumPlayers)+1;
    if (LevAISkill>3) and (Random(4)>(6-LevAISkill)) then begin
      {* Force picking human - 10 attempts}
      if NumHumanPlayers>0 then begin
        VICTIM[NUM]:=Random(NumHumanPlayers)+1;
        for E:=1 to 10 do begin
          if Alive[VICTIM[NUM]]=0 then
            VICTIM[NUM]:=Random(NumHumanPlayers)+1;
        end;
      end;
    end;
  end;
end;


procedure ProcessAI(NUM: Integer);
begin
  {* Process AI player movements}
  {* Check to see if stupid computer player goes off edge of play area}
  if Y[NUM]>459 then DIR[NUM]:=1;
  if Y[NUM]<16 then DIR[NUM]:=2;
  if X[NUM]>524 then DIR[NUM]:=3;
  if X[NUM]<16 then DIR[NUM]:=4;
  {* Create a new missile!}
  if ((LevAISkill<3) and (Random(150)=1)) or
  ((LevAISkill=3) and (Random(80)=1)) or
  ((LevAISkill>3) AND (Random(50)=1)) then begin
    if NumActiveMissiles[NUM]<MaxActiveMissiles[NUM] then CreateMissile(NUM);
  end;
  {* Move around, or choose some podantic (!) victim}
  if (NumPlayersAlive>3) and (RANDOM(900)=1) then ChooseVictim(NUM);
  if (NumPlayersAlive>3) and (RANDOM(900)=1) then VICTIM[NUM]:=0;
  if (NumPlayersAlive<4) and (RANDOM(150)=1) then ChooseVictim(NUM);
  if (NumPlayersAlive<4) and (RANDOM(400)=1) then VICTIM[NUM]:=0;
  if (RANDOM(100)=1) and (VICTIM[NUM]=0) then DIR[NUM]:=RANDOM(4)+1;
  if (VICTIM[NUM]<>0) then begin
    if (VICTIMTYPE[NUM]=1) and (Alive[Victim[NUM]]=0) then Victim[NUM]:=0;
    if (VICTIMTYPE[NUM]=2) and (NumObjects<Victim[NUM]) then Victim[NUM]:=0;
  end;
  if (VICTIM[NUM]=0) and (Random(100)=1) then DIR[NUM]:=Random(4)+1;
  if (VICTIM[NUM]>0) and (VICTIMTYPE[NUM]=1) then begin
    {* Move toward the victim...}
    if X[VICTIM[NUM]]<X[NUM] then DIR[NUM]:=3;
    if X[VICTIM[NUM]]>X[NUM] then DIR[NUM]:=4;
    if Y[VICTIM[NUM]]<Y[NUM] then DIR[NUM]:=1;
    if Y[VICTIM[NUM]]>Y[NUM] then DIR[NUM]:=2;
    {* If 'in' victim, then move away}
    if (X[NUM]>=X[VICTIM[NUM]]-3) and (X[NUM]<=X[VICTIM[NUM]]+3)
    and (Y[NUM]>=Y[VICTIM[NUM]]-3) and (Y[NUM]<=Y[VICTIM[NUM]]+3)
    THEN VICTIM[NUM]:=0;
  end;
  if (VICTIM[NUM]>0) and (VICTIMTYPE[NUM]=2) then begin
    {* Move toward the object...}
    if ObjX[VICTIM[NUM]]<X[NUM] then DIR[NUM]:=3;
    if ObjX[VICTIM[NUM]]>X[NUM] then DIR[NUM]:=4;
    if ObjY[VICTIM[NUM]]<Y[NUM] then DIR[NUM]:=1;
    if ObjY[VICTIM[NUM]]>Y[NUM] then DIR[NUM]:=2;
    {* If 'in' object, then move away}
    if (X[NUM]>=ObjX[VICTIM[NUM]]-3) and (X[NUM]<=ObjX[VICTIM[NUM]]+3)
    and (Y[NUM]>=ObjY[VICTIM[NUM]]-3) and (Y[NUM]<=ObjY[VICTIM[NUM]]+3)
    THEN VICTIM[NUM]:=0;
  end;
end;


procedure CheckMissCollision(PLN,MISSNUM,CX,CY: Integer);
var Z: Integer;
begin
  {* Check to see if missile hits player}
  for Z:=1 to NumPlayers do begin
    if ALIVE[Z]=1 then begin
      if (CX>=X[Z]-10) and (CX<=X[Z]+10) and (CY>=Y[Z]-10) and (CY<=Y[Z]+10)
      then begin
        Sound(100); Delay(50); Sound(300); Delay(90);
        Sound(1300); Delay(30); NoSound;
        DelMissile(PLN,MISSNUM);
        LoseLife(Z,PLN); {Z: Who killed, PLN: Who kills}
        DrawStats;
      end;
    end;
  end;
  {* Check to see if Missile goes off edge of play area}
  if (CX<6) or (CX>539) or (CY<6) or (CY>464) then begin
    DelMissile(PLN,MISSNUM); DrawBorders;
  end;
end;


procedure ProcessMissiles(PLN: Integer);
var
  MX,MY,MDIR,B: Integer;
begin
  {* Make temporary variables for faster processing}
  for B:=1 to NumActiveMissiles[PLN] do begin
    HideMissile(PLN,B);
    MX:=MissX[PLN,B]; MY:=MissY[PLN,B]; MDIR:=MissDIR[PLN,B];
    {* Depending on direction, draw missile in new pos}
    if MDIR=1 then begin
      MissY[PLN,B]:=MissY[PLN,B]-5;
      SetColor(15); MoveTo(MX,MY-55); LineTo(MX,MY-5);
    end else if MDIR=2 then begin
      MissY[PLN,B]:=MissY[PLN,B]+5;
      SetColor(15); MoveTo(MX,MY+55); LineTo(MX,MY+5);
   end else if MDIR=3 then begin
      MissX[PLN,B]:=MissX[PLN,B]-5;
      SetColor(15); MoveTo(MX-55,MY); LineTo(MX-5,MY);
    end else if MDIR=4 then begin
      MissX[PLN,B]:=MissX[PLN,B]+5;
      SetColor(15); MoveTo(MX+55,MY); LineTo(MX+5,MY);
    end;
    {* Find points to check for collision, and check it}
    MX:=MissX[PLN,B]; MY:=MissY[PLN,B]; MDIR:=MissDIR[PLN,B];
    if MDIR=1 then MY:=MY-51;
    if MDIR=2 then MY:=MY+51;
    if MDIR=3 then MX:=MX-51;
    if MDIR=4 then MX:=MX+51;
    CheckMissCollision(PLN,B,MX,MY);
  end;
end;


procedure PlayLevel;
var Cycles: ShortInt;
begin
  Cycles:=0;
  repeat
    Cycles:=Cycles+1; If Cycles=11 then Cycles:=0;
    C:='^'; if Keypressed=true then C:=UpCase(ReadKey);
    for G:=1 to NumHumanPlayers do begin                {* Process humans}
      if Alive[G]=1 then begin
        if C=KUp[G] then DIR[G]:=1;
        if C=KDown[G] then DIR[G]:=2;
        if C=KLeft[G] then DIR[G]:=3;
        if C=KRight[G] then DIR[G]:=4;
        if C=KFire[G] then CreateMissile(G);
      end;
      {* Check for boundaries - Only required f/ humans - AI handled o/wise};
      if X[G]<16 then X[G]:=16;
      if Y[G]<16 then Y[G]:=16;
      if X[G]>529 then X[G]:=529;
      if Y[G]>464 then Y[G]:=464;
    end;
    for G:=NumHumanPlayers+1 to NumPlayers do begin     {* Process AI}
      if Alive[G]=1 then ProcessAI(G);
    end;
    for G:=1 to NumPlayers do begin                     {* Process all}
      if Alive[G]=1 then begin
        SetFillStyle(1,0); Bar(X[G]-10,Y[G]-10,X[G]+10,Y[G]+10);
        {* Move it!}
        if DIR[G]=1 then Y[G]:=Y[G]-1;
        if DIR[G]=2 then Y[G]:=Y[G]+1;
        if DIR[G]=3 then X[G]:=X[G]-1;
        if DIR[G]=4 then X[G]:=X[G]+1;
        DrawPlayer(G);
        ProcessMissiles(G);
        CheckObjCollision(G);
      end;
    end;
    if Random(500-(NumPlayersAlive*20))=1 then CreateObject;
    if Cycles=10 then DrawObjects;
    Delay(SDelay div 300);
  until NumPlayersAlive<2;
end;

end.