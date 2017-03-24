program Podantious;

{*** Again, made by Nicholas Hill - when oh when will I stop making these
     brilliant games? (C) 1999 Connivex ***}

uses crt, graph, DOS, poengine;

var
  Ch: Char;
  {* If keys are set up or not}
  KeysSetup: Array[1..15] of ShortInt;
  {* Setup for levels}
  NumLevels: Integer;
  LevNumObjects: Integer;
  PlLives,PlMaxActiveMissiles: Array[1..15] of Integer;
  {* Variables for end of level}
  MaxKills,MinKills,BestPlayer,WorstPlayer: Integer;
  Winner: Integer;
  OKToCont: Integer;

procedure CalcDelay;
var H1,M1,S1,MS1,H2,M2,S2,MS2,NUM: Word;
begin
  TextColor(7); ClrScr;
  WriteLn('Connivex 1999'); WriteLn;
  Writeln('Nicholas Hill''s delay calculation routine.');
  Writeln('Calculating delays...');
  GetTime(h1,m1,s1,ms1); NUM:=0;
  repeat
    DELAY(100); NUM:=NUM+1;
    GetTime(h2,m2,s2,ms2);
    GotoXY(1,5); Write(NUM); GotoXY(7,5); Writeln(H2:2,':',M2:2,':',S2:2);
  until (((S2-S1)*100)+(MS2-MS1))>=300;
  writeln('Took ',NUM,' loops of 100 for 3s.');
  SDelay:=(NUM*100) div 3;
  Delay(SDelay);
end;


procedure StartLevel;
var E: Integer;
begin
  {* Draw players... etc}
  for E:=1 to NumPlayers do begin
    if StillInGame[E]=1 then begin
      Sound(E*10); Delay(SDelay div 10); DrawPlayer(E);
      NoSound; Delay(SDelay div 15);
    end;
  end;
  for E:=1 to 3 do begin
    Sound(E*300); Delay(SDelay div 4);
    NoSound; Delay(SDelay div 4);
  end;
  for E:=1 to 2 do begin
    Sound(120); Delay(SDelay div 10);
    NoSound; Delay(SDelay div 18);
  end;
end;


procedure EndLevel;
var
  B,E: Integer;
  S1,S2: String;
begin
  MaxKills:=0;
  for B:=1 to NumPlayers do if Alive[B]=1 then Winner:=B;
  for B:=1 to 3 do begin
    for E:=10 downto 1 do begin
      Sound(E*10+100); Delay(SDelay div 50);
      Sound(E*10+120); Delay(SDelay div 50);
    end;
  end; NoSound;
  Delay(SDelay*2); SetFillStyle(1,0);
  for E:=0 to 63 do begin
    Bar(E*10,0,E*10+10,480); Delay(SDelay div 32);
  end;
  SetTextStyle(TripleXFont, HorizDir, 1);
  for B:=1 to NumPlayers do begin
    if StillInGame[B]=1 then begin
      SetColor(B); Str(B,S1); Str(NumKills[B],S2);
      OutTextXY(1,B*22,'Player '+S1+' had '+S2+' hits.');
    end;
  end;
  {* Find maximum and minimum kills}
  MaxKills:=0;
  for B:=1 to NumPlayers do begin
    if StillInGame[B]=1 then begin
      if NumKills[B]>MaxKills then begin
        MaxKills:=NumKills[B];
        BestPlayer:=B;
      end;
    end;
  end;
  MinKills:=MaxKills;
  for B:=1 to NumPlayers do begin
    if StillInGame[B]=1 then begin
      if NumKills[B]<=MinKills then begin
        MinKills:=NumKills[B];
        WorstPlayer:=B;
      end;
    end;
  end;
  SetColor(9); Rectangle(0,BestPlayer*22+3,320,BestPlayer*22+23);
  SetColor(4); Rectangle(0,WorstPlayer*22+3,320,WorstPlayer*22+23);
  SetTextStyle(SansSerifFont, HorizDir, 4);
  SetColor(15); OutTextXY(1,350,'Level over - Press ''C'' to continue...');
  REPEAT UNTIL UpCase(ReadKey)='C';
end;


procedure GameInit;
var grDriver, grMode, ErrCode: Integer;
begin
  {* Initialise graphics}
  grDriver:=Detect; InitGraph(grDriver,grMode,'');
  ErrCode:=GraphResult; if ErrCode<>grOk then Halt(1);
  SetTextStyle(DefaultFont, HorizDir, 1);
  for A:=1 to 15 do KeysSetup[A]:=0;
end;


procedure SetupPlayer(PLN: Integer);
var S1: String;
begin
  if StillInGame[PLN]=1 then begin
    {* Main player variables, x,y...etc, and get keys for each player}
    X[PLN]:=Random(500)+20; Y[PLN]:=Random(430)+20; DIR[PLN]:=Random(4)+1;
    PCOL[PLN]:=PLN; NumActiveMissiles[PLN]:=0; Alive[PLN]:=1;
    NumLives[PLN]:=PlLives[PLN];
    MaxActiveMissiles[PLN]:=PlMaxActiveMissiles[PLN];
    if (PLN<=NumHumanPlayers) and (KeysSetup[PLN]<>1) then begin
      SetColor(15); Rectangle(290,70,600,148);
      SetFillStyle(1,0); Bar(291,71,599,147);
      SetColor(PLN); Str(PLN,S1);
      OutTextXY(300,80,'Player '+S1+' - Press key for UP:');
      KUp[PLN]:=UpCase(ReadKey);
      OutTextXY(300,92,'Player '+S1+' - Press key for DOWN:');
      KDown[PLN]:=UpCase(ReadKey);
      OutTextXY(300,104,'Player '+S1+' - Press key for LEFT:');
      KLeft[PLN]:=UpCase(ReadKey);
      OutTextXY(300,116,'Player '+S1+' - Press key for RIGHT:');
      KRight[PLN]:=UpCase(ReadKey);
      OutTextXY(300,128,'Player '+S1+' - Press key for FIRE:');
      KFire[PLN]:=UpCase(ReadKey);
      KeysSetup[PLN]:=1;
    end;
    {* Set initial AI victims :}
    if (PLN>NumHumanPlayers) and (Random(10)>4) then
      VICTIM[PLN]:=Random(NumPlayers+1);
  end else Alive[PLN]:=0;
end;


procedure InitLevel(NumHuman,NumAI,AISkill: Integer);
var E: Integer;
begin
  for E:=1 to 15 do begin
    NumKills[E]:=0; Alive[E]:=0;
  end;
  {* Number of each thing}
  NumHumanPlayers:=NumHuman;
  NumAIPlayers:=NumAI;
  NumPlayers:=NumAIPlayers+NumHumanPlayers;
  NumPlayersAlive:=0;
  for E:=1 to NumPlayers do begin
    if StillInGame[E]=1 then NumPlayersAlive:=NumPlayersAlive+1;
  end;
  NumObjects:=0; MaxObjects:=LevNumObjects;
  LevAISkill:=AISkill;
end;


procedure GetPlayerTypes(HumanYN,AIYN: Integer);
var S1: String;
begin
  SetColor(15); Rectangle(50,350,400,420);
  SetFillStyle(1,0); Bar(51,351,399,419);
  if HumanYN=1 then repeat
    OutTextXY(60,370,'Enter number of human players (0-8): ');
    ReadLn(NumHumanPlayers);
  until (NumHumanPlayers>-1) and (NumHumanPlayers<9);
  if AIYN=1 then repeat
    Str(15-NumHumanPlayers,S1);
    OutTextXY(60,390,'Enter number of AI players (0-'+S1+'): ');
    Readln(NumAIPlayers);
  until (NumAIPlayers>-1) and (NumAIPlayers<(16-NumHumanPlayers));
end;

procedure SetupCustomLevel;
var E: Integer;
begin
  GetPlayerTypes(1,1); {* Player setup}
  InitLevel(NumHumanPlayers,NumAIPlayers,LevAISkill);
  SetColor(15); Rectangle(90,10,400,100);
  SetFillStyle(1,0); Bar(91,11,399,99);
  SetTextStyle(DefaultFont,HorizDir,1);
  {* User input setup}
  OutTextXY(100,20,'Enter AI skill level (1-5):'); Readln(LevAISkill);
  OutTextXY(100,40,'Enter maximum objects (0-20):');
  repeat
    ReadLn(LevNumObjects);
  until (LevNumObjects>-1) and (LevNumObjects<21);
  OutTextXY(100,60,'Enter starting lives (1-5):');
  repeat
    ReadLn(PlLives[1]);
  until (PlLives[1]>0) and (PlLives[1]<6);
  for E:=1 to NumPlayers do PlLives[E]:=PlLives[1];
  OutTextXY(100,80,'Enter maximum missiles (0-20):');
  repeat
    ReadLn(PlMaxActiveMissiles[1]);
  until (PlMaxActiveMissiles[1]>-1) and (PlMaxActiveMissiles[1]<21);
  for E:=1 to NumPlayers do PlMaxActiveMissiles[E]:=PlMaxActiveMissiles[1];
end;


procedure SetupCampaignLevel(L: Integer);
var E: Integer;
begin
  if L=1 then begin
    LevNumObjects:=15; InitLevel(1,1,1);
    PlLives[1]:=5; PlMaxActiveMissiles[1]:=10;
    PlLives[2]:=2; PlMaxActiveMissiles[2]:=1;
  end;
  if L=2 then begin
    LevNumObjects:=8; InitLevel(1,7,1);
    PlLives[1]:=5; PlMaxActiveMissiles[1]:=3;
    for E:=2 to 8 do PlLives[E]:=1;
    for E:=2 to 8 do PlMaxActiveMissiles[E]:=1;
  end;
  if L=3 then begin
    LevNumObjects:=5; InitLevel(1,3,2);
    PlLives[1]:=4; PlMaxActiveMissiles[1]:=2;
    for E:=2 to 4 do PlLives[E]:=2;
    for E:=2 to 4 do PlMaxActiveMissiles[E]:=2;
  end;
  if L=4 then begin
    LevNumObjects:=5; InitLevel(1,2,2);
    PlLives[1]:=5; PlMaxActiveMissiles[1]:=2;
    for E:=2 to 3 do PlLives[E]:=5;
    for E:=2 to 3 do PlMaxActiveMissiles[E]:=2;
  end;
  if L=5 then begin
    LevNumObjects:=3; InitLevel(1,2,2);
    PlLives[1]:=4; PlMaxActiveMissiles[1]:=1;
    for E:=2 to 3 do PlLives[E]:=5;
    for E:=2 to 3 do PlMaxActiveMissiles[E]:=2;
  end;
  if L=6 then begin
    LevNumObjects:=3; InitLevel(1,14,3);
    PlLives[1]:=4; PlMaxActiveMissiles[1]:=3;
    for E:=2 to 15 do PlLives[E]:=1;
    for E:=2 to 15 do PlMaxActiveMissiles[E]:=2;
  end;
  if L=7 then begin
    LevNumObjects:=0; InitLevel(1,1,5);
    PlLives[1]:=3; PlMaxActiveMissiles[1]:=1;
    PlLives[2]:=5; PlMaxActiveMissiles[2]:=2;
  end;
  if L=8 then begin
    LevNumObjects:=2; InitLevel(1,14,3);
    PlLives[1]:=5; PlMaxActiveMissiles[1]:=4;
    for E:=2 to 15 do PlLives[E]:=3;
    for E:=2 to 15 do PlMaxActiveMissiles[E]:=3;
  end;
  if L=9 then begin
    LevNumObjects:=1; InitLevel(1,9,3);
    PlLives[1]:=2; PlMaxActiveMissiles[1]:=1;
    for E:=2 to 10 do PlLives[E]:=2;
    for E:=2 to 10 do PlMaxActiveMissiles[E]:=2;
  end;
  if L=10 then begin
    LevNumObjects:=2; InitLevel(1,14,3);
    PlLives[1]:=5; PlMaxActiveMissiles[1]:=1;
    for E:=2 to 5 do PlLives[E]:=5;
    for E:=2 to 5 do PlMaxActiveMissiles[E]:=5;
    for E:=6 to 9 do PlLives[E]:=3;
    for E:=6 to 9 do PlMaxActiveMissiles[E]:=3;
    for E:=10 to 14 do PlLives[E]:=1;
    for E:=10 to 14 do PlMaxActiveMissiles[E]:=1;
  end;
  if L=11 then begin
    LevNumObjects:=1; InitLevel(1,3,4);
    PlLives[1]:=2; PlMaxActiveMissiles[1]:=1;
    PlLives[2]:=3; PlMaxActiveMissiles[2]:=1;
    PlLives[3]:=4; PlMaxActiveMissiles[3]:=1;
    PlLives[4]:=5; PlMaxActiveMissiles[4]:=5;
  end;
  if L=12 then begin
    LevNumObjects:=0; InitLevel(1,2,4);
    PlLives[1]:=2; PlMaxActiveMissiles[1]:=2;
    for E:=2 to 3 do PlLives[E]:=4;
    for E:=2 to 3 do PlMaxActiveMissiles[E]:=5;
  end;
  if L=13 then begin
    LevNumObjects:=1; InitLevel(1,14,4);
    PlLives[1]:=5; PlMaxActiveMissiles[1]:=2;
    for E:=2 to 15 do PlLives[E]:=4;
    for E:=2 to 15 do PlMaxActiveMissiles[E]:=3;
  end;
  if L=14 then begin
    LevNumObjects:=20; InitLevel(1,9,4);
    PlLives[1]:=2; PlMaxActiveMissiles[1]:=1;
    for E:=2 to 9 do PlLives[E]:=3;
    for E:=2 to 9 do PlMaxActiveMissiles[E]:=2;
    PlLives[10]:=5; PlMaxActiveMissiles[10]:=1;
  end;
  if L=15 then begin
    LevNumObjects:=0; InitLevel(1,2,5);
    PlLives[1]:=2; PlMaxActiveMissiles[1]:=0;
    PlLives[2]:=2; PlMaxActiveMissiles[1]:=1;
    PlLives[3]:=5; PlMaxActiveMissiles[1]:=5;
  end;
  if L=16 then begin
    LevNumObjects:=2; InitLevel(1,14,5);
    PlLives[1]:=2; PlMaxActiveMissiles[1]:=1;
    for E:=2 to 15 do PlLives[E]:=5;
    for E:=2 to 15 do PlMaxActiveMissiles[E]:=5;
  end;
  for E:=1 to NumPlayers do SetupPlayer(E);
  {* Specify X and Y positions for some levels}
  if L=1 then begin
    X[1]:=100; Y[1]:=50; Dir[1]:=2;
    X[2]:=100; Y[2]:=400; Dir[2]:=2;
  end;
  if L=4 then begin
    for E:=1 to NumPlayers do Y[E]:=300;
  end;
  if L=8 then begin
    for E:=1 to 15 do begin
      X[E]:=E*30; if (E mod 2)=1 then Y[E]:=200 else Y[E]:=180;
    end;
  end;
  if L=10 then begin
    for E:=1 to 15 do begin
      Y[E]:=E*22; if (E mod 2)=1 then X[E]:=20 else X[E]:=525;
      if (E mod 2)=1 then DIR[E]:=4 else DIR[E]:=3;
    end;
  end;
  if L=12 then begin
    X[1]:=20; Y[1]:=460; DIR[1]:=1;
    X[2]:=300; Y[2]:=100; DIR[2]:=2;
    X[3]:=60; Y[3]:=460; DIR[3]:=1;
  end;
  if L=16 then begin
    X[1]:=30; Y[1]:=30; DIR[1]:=4;
    X[2]:=515; Y[2]:=30; DIR[2]:=3;
    X[3]:=30; Y[3]:=450; DIR[3]:=4;
    X[4]:=515; Y[4]:=450; DIR[4]:=3;
    X[5]:=50; Y[5]:=50; DIR[5]:=4;
    X[6]:=495; Y[6]:=50; DIR[6]:=3;
    X[7]:=50; Y[7]:=430; DIR[7]:=4;
    X[8]:=495; Y[8]:=430; DIR[8]:=3;
    X[9]:=70; Y[9]:=70; DIR[9]:=4;
    X[10]:=475; Y[10]:=70; DIR[10]:=3;
    X[11]:=70; Y[11]:=410; DIR[11]:=4;
    X[12]:=475; Y[12]:=410; DIR[12]:=3;
    X[13]:=90; Y[13]:=90; DIR[13]:=4;
    X[14]:=455; Y[14]:=90; DIR[14]:=3;
    X[15]:=90; Y[15]:=390; DIR[15]:=4;
  end;
end;


procedure ShowMessage(Msg: String);
begin
  SetColor(15); Rectangle(100,100,540,150);
  SetFillStyle(1,0); Bar(101,101,539,149);
  SetTextStyle(DefaultFont,HorizDir,1);
  OutTextXY(110,110,Msg);
  OutTextXY(110,130,'Press the ''C'' key to continue...');
  REPEAT UNTIL UpCase(ReadKey)='C';
end;


procedure PlayGame(GameType: Char);
var
  E, Level: Integer;
  S1: String;
begin
  TextColor(15); SetColor(15);
  if GameType='A' then NumLevels:=16;
  if GameType='B' then begin
    NumLevels:=14; GetPlayerTypes(1,0); {* Player setup}
    NumAIPlayers:=15-NumHumanPlayers;
  end;
  if (GameType='C') or (GameType='D') then begin
    NumLevels:=1; GetPlayerTypes(1,1); {* Player setup}
  end;
  if GameType='E' then NumLevels:=1;
  OKToCont:=1; Level:=0;
  while OKToCont=1 do begin
    Level:=Level+1;
    if Level>=NumLevels then OKToCont:=0;
    Str(Level,S1);
    {* Initialise level: NumHuman,NumAI,AISKILL or Setup player: PLN};
    if GameType='A' then SetupCampaignLevel(Level);
    if GameType='B' then begin
      LevNumObjects:=15-Level;
      InitLevel(NumHumanPlayers,NumAIPlayers,(NumLevels+1) div 3);
      for E:=1 to NumPlayers do SetupPlayer(E);
      if Level>0 then for E:=1 to NumPlayers do PlLives[E]:=5;
      if Level>5 then for E:=1 to NumPlayers do PlLives[E]:=4;
      if Level>10 then for E:=1 to NumPlayers do PlLives[E]:=3;
      if Level>0 then for E:=1 to NumPlayers do PlMaxActiveMissiles[E]:=2;
      if Level>3 then for E:=1 to NumPlayers do PlMaxActiveMissiles[E]:=1;
    end;
    if (GameType='C') or (GameType='D') then begin
      if GameType='C' then LevNumObjects:=15;
      if GameType='D' then LevNumObjects:=0;
      InitLevel(NumHumanPlayers,NumAIPlayers,3);
      for E:=1 to 15 do PlLives[E]:=5;
      if GameType='C' then for E:=1 to 15 do PlMaxActiveMissiles[E]:=1;
      if GameType='D' then for E:=1 to 15 do PlMaxActiveMissiles[E]:=3;
      for E:=1 to NumPlayers do SetupPlayer(E);
    end;
    if GameType='E' then begin
      SetupCustomLevel;
      InitLevel(NumHumanPlayers,NumAIPlayers,(NumLevels+1) div 3);
      for E:=1 to NumPlayers do SetupPlayer(E);
    end;
    {* Play level}
    ShowMessage('You are on level '+S1+'.');
    DrawBoard;     {* Draw the board}
    StartLevel;    {* The startup sequence for the level}
    PlayLevel;     {* Main playing part of the game}
    EndLevel;      {* End the level}
    {* Perform checks for game type - if alive or not}
    if (GameType='A') and (Alive[1]=0) then begin
      OKToCont:=0;
      ShowMessage('You died! Game over!');
    end;
    if GameType='B' then StillInGame[WorstPlayer]:=0;
  end;
  if (GameType='C') or (GameType='D') or (GameType='E') then begin
    Str(Winner,S1);
    ShowMessage('This level is finished. Winner was player '+S1+'.');
  end;
  if (GameType='A') and (Level=16) then begin
    ShowMessage('Congratulations! Your insanity has helped you, OB1!');
    ShowMessage('You have completed the campaign.');
    ShowMessage('Be sure to email connivex@callnetuk.com!');
  end;
  if (GameType='B') then begin
    Str(BestPlayer,S1);
    ShowMessage('Survival game is over - winner was '+S1);
  end;
end;


procedure ShowMenu;
begin
  {* Display the menu}
  SetFillStyle(1,0); Bar(0,0,640,480);
  SetColor(15); Rectangle(100,50,540,430);
  SetFillStyle(1,9); Bar(105,55,535,100);
  SetTextStyle(SansSerifFont,HorizDir,5);
  OutTextXY(108,48,'Podantious! 1999');
  SetColor(8);
  MoveTo(110,110); LineTo(110,420);
  LineTo(530,265); LineTo(110,110);
  SetTextStyle(DefaultFont,HorizDir,1);
  SetColor(15);
  OutTextXY(105,120,'A] Campaign');
  OutTextXY(105,170,'B] Survival of the fittest');
  OutTextXY(105,240,'C] Single game - powerups');
  OutTextXY(105,300,'D] Single game - no powerups');
  OutTextXY(105,360,'E] Custom game');
  OutTextXY(105,410,'X] Exit game');
  SetColor(7);
  OutTextXY(135,140,'Go through 16 predesigned levels.');
  OutTextXY(135,190,'Use your insanity to complete 14 levels, where the');
  OutTextXY(135,200,'worst player is thrown out of the game after each');
  OutTextXY(135,210,'level of madness.');
  OutTextXY(135,260,'A small skirmish, in which only one survives.');
  OutTextXY(135,270,'Powerups are available');
  OutTextXY(135,320,'Same as above, but without powerups, and 3 active');
  OutTextXY(135,330,'missiles at any one time.');
  OutTextXY(135,380,'Customise your game to one that suits you.');
  Ch:='1';
  While (Ch<>'A') and (CH<>'B') and (Ch<>'C')
  and (CH<>'D') and (CH<>'E') and (Ch<>'X') do Ch:=UpCase(ReadKey);
end;


begin
  {*** The main program ***}
  CalcDelay;    {* Calculate delays}
  GameInit;     {* Init game}
  repeat
    {* Make all players still in game}
    for A:=1 to 15 do StillInGame[A]:=1;
    ShowMenu;     {* Show the menu, and get settings}
    if Ch='A' then PlayGame(Ch); {* Play the game with menu choice}
    if Ch='B' then PlayGame(Ch);
    if Ch='C' then PlayGame(Ch);
    if Ch='D' then PlayGame(Ch);
    if Ch='E' then PlayGame(Ch);
  until Ch='X';
end.