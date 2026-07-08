Unit bbs_AreaIndex;

// ===========================================================================
//  Mystic fork - ANSIMIDX Area Index reader (reconstruction of the A38 feature
//  absent from the GPL A38 source).  Compile-checked only; verify on a node.
//
//  Chunk 1 LoadAreaIdxCfg    Chunk 2 GatherAreaStats    Chunk 3 BuildAreaIdxOrder
//  Chunk 4 display           Chunk 5 keys + read + wired via MI menu command
//
//  Source-lag notes: group_list=true + exclude_groups need a per-base group
//  field not present in A38 records (flagged fallbacks).  Rows render as plain
//  columns + highlight bar; full str1-4 template styling is a later polish pass.
// ===========================================================================

Interface

Uses
  m_Strings,
  m_IniReader,
  BBS_Records,
  BBS_Core,
  BBS_IO,
  BBS_Ansi_MenuBox,
  BBS_DataBase,
  BBS_MsgBase_ABS,
  BBS_MsgBase_JAM,
  BBS_MsgBase_Squish;

Const
  MaxAreaIdx = 4096;

Type
  RecAreaIdxCfg = Record
    GroupList     : Boolean;
    ExcludeGroups : String;
    ShowDivs      : Boolean;
    NewAtTop      : Boolean;
    SnapNew       : Boolean;
    NoIndex       : Boolean;
    WinX1, WinY1, WinA1 : Byte;
    WinX2, WinY2, WinA2 : Byte;
    SrchX, SrchY, SrchA : Byte;
    PctActive     : Boolean;
    PctFormat     : Byte;
    PctLength     : Byte;
    PctX, PctY    : Byte;
    PctLoChar     : Byte;
    PctLoAttr     : Byte;
    PctHiChar     : Byte;
    PctHiAttr     : Byte;
    Str : Array[1..9] of String;
  End;

  RecAreaIdxBase = Record
    MBase   : RecMessageBase;
    BaseNum : LongInt;               // real base number (position in mbases.dat)
    Total   : LongInt;
    NewC    : LongInt;
    Yours   : LongInt;
  End;

  TAreaIdxList = Array[1..MaxAreaIdx] of RecAreaIdxBase;

  RecAreaIdxEntry = Record
    IsDivider : Boolean;
    DivText   : String;
    BaseIdx   : Integer;
  End;

  TAreaIdxOrder = Array[1..MaxAreaIdx + 64] of RecAreaIdxEntry;

Procedure LoadAreaIdxCfg   (FileName: String; Var Cfg: RecAreaIdxCfg);
Procedure GatherAreaStats  (Var List: TAreaIdxList; Var Count: Integer);
Procedure BuildAreaIdxOrder(Var Cfg: RecAreaIdxCfg; Var List: TAreaIdxList;
                            Count: Integer; Var Order: TAreaIdxOrder;
                            Var OrderCount: Integer);
Function  FormatNetAddr    (Var A: RecEchoMailAddr) : String;
Procedure AreaIndex;

Implementation

Uses
  BBS_MsgBase;                       // implementation-only: ChangeArea/ReadMessages

Function FormatNetAddr (Var A: RecEchoMailAddr) : String;
Var
  S : String;
Begin
  S := strI2S(A.Zone) + ':' + strI2S(A.Net) + '/' + strI2S(A.Node);
  If A.Point > 0 Then S := S + '.' + strI2S(A.Point);
  FormatNetAddr := S;
End;

Procedure ParseCoord (S: String; Var X, Y, A: Byte);
  Function Chunk (Var Str: String) : Byte;
  Var
    Cm  : LongInt;
    V   : LongInt;
    Cod : Integer;
    Sub : String;
  Begin
    Cm := Pos(',', Str);
    If Cm > 0 Then Begin
      Sub := Copy(Str, 1, Cm - 1);
      Delete (Str, 1, Cm);
    End Else Begin
      Sub := Str;
      Str := '';
    End;
    Val (Sub, V, Cod);
    If Cod <> 0 Then V := 0;
    Chunk := Byte(V);
  End;
Begin
  X := Chunk(S);
  Y := Chunk(S);
  A := Chunk(S);
End;

Procedure LoadAreaIdxCfg (FileName: String; Var Cfg: RecAreaIdxCfg);
Var
  Ini : TIniReader;
  I   : Byte;
Begin
  FillChar (Cfg, SizeOf(Cfg), 0);

  Ini := TIniReader.Create (FileName);

  Cfg.GroupList     := Ini.ReadBoolean ('Options', 'group_list',     True);
  Cfg.ExcludeGroups := Ini.ReadString  ('Options', 'exclude_groups', '');
  Cfg.ShowDivs      := Ini.ReadBoolean ('Options', 'show_divs',      True);
  Cfg.NewAtTop      := Ini.ReadBoolean ('Options', 'new_at_top',     True);
  Cfg.SnapNew       := Ini.ReadBoolean ('Options', 'snap_new',       False);
  Cfg.NoIndex       := Ini.ReadBoolean ('Options', 'no_index',       False);

  ParseCoord (Ini.ReadString('Coords', 'Coord1', '3,6,0'),   Cfg.WinX1, Cfg.WinY1, Cfg.WinA1);
  ParseCoord (Ini.ReadString('Coords', 'Coord2', '78,20,0'), Cfg.WinX2, Cfg.WinY2, Cfg.WinA2);
  ParseCoord (Ini.ReadString('Coords', 'Coord3', '23,2,7'),  Cfg.SrchX, Cfg.SrchY, Cfg.SrchA);

  Cfg.PctActive := Ini.ReadBoolean ('Percent', 'active',     True);
  Cfg.PctFormat := Ini.ReadInteger ('Percent', 'bar_format', 1);
  Cfg.PctLength := Ini.ReadInteger ('Percent', 'bar_length', 13);
  Cfg.PctX      := Ini.ReadInteger ('Percent', 'location_X', 79);
  Cfg.PctY      := Ini.ReadInteger ('Percent', 'location_Y', 7);
  Cfg.PctLoChar := Ini.ReadInteger ('Percent', 'low_char',   176);
  Cfg.PctLoAttr := Ini.ReadInteger ('Percent', 'low_attr',   8);
  Cfg.PctHiChar := Ini.ReadInteger ('Percent', 'high_char',  219);
  Cfg.PctHiAttr := Ini.ReadInteger ('Percent', 'high_attr',  9);

  For I := 1 to 9 Do
    Cfg.Str[I] := Ini.ReadString ('Prompts', 'str' + Chr(48 + I), '');

  Ini.Free;
End;

Procedure ScanBaseStats (Var Area: RecMessageBase; Var ATotal, ANew, AYours: LongInt);
Var
  Msg      : PMsgBaseABS;
  LastRead : LongInt;
Begin
  ATotal := 0; ANew := 0; AYours := 0;

  Case Area.BaseType of
    0 : Msg := New(PMsgBaseJAM, Init);
    1 : Msg := New(PMsgBaseSquish, Init);
  Else
    Msg := Nil;
  End;

  If Msg = Nil Then Exit;

  Msg^.SetMsgPath  (Area.Path + Area.FileName);
  Msg^.SetTempFile (Session.TempPath + 'msgidx.');

  If Msg^.OpenMsgBase Then Begin
    LastRead := Msg^.GetLastRead (Session.User.UserNum);

    Msg^.SeekFirst (1);

    While Msg^.SeekFound Do Begin
      Msg^.MsgStartUp;

      Inc (ATotal);

      If Msg^.GetMsgNum > LastRead Then Inc (ANew);
      If Session.User.IsThisUser (Msg^.GetTo) Then Inc (AYours);

      Msg^.SeekNext;
    End;

    Msg^.CloseMsgBase;
  End;

  Dispose (Msg, Done);
End;

Procedure SetBaseLastRead (Var Area: RecMessageBase; LR: LongInt);
Var
  Msg : PMsgBaseABS;
Begin
  Case Area.BaseType of
    0 : Msg := New(PMsgBaseJAM, Init);
    1 : Msg := New(PMsgBaseSquish, Init);
  Else
    Msg := Nil;
  End;

  If Msg = Nil Then Exit;

  Msg^.SetMsgPath  (Area.Path + Area.FileName);
  Msg^.SetTempFile (Session.TempPath + 'msgidx.');

  If Msg^.OpenMsgBase Then Begin
    Msg^.SetLastRead (Session.User.UserNum, LR);
    Msg^.CloseMsgBase;
  End;

  Dispose (Msg, Done);
End;

Procedure GatherAreaStats (Var List: TAreaIdxList; Var Count: Integer);
Var
  BaseFile : File of RecMessageBase;
  Area     : RecMessageBase;
  RawNum   : LongInt;
Begin
  Count  := 0;
  RawNum := 0;

  Assign (BaseFile, bbsCfg.DataPath + 'mbases.dat');
  {$I-} Reset (BaseFile); {$I+}
  If IoResult <> 0 Then Exit;

  While (Not Eof(BaseFile)) and (Count < MaxAreaIdx) Do Begin
    Read (BaseFile, Area);
    Inc (RawNum);

    If Session.User.Access (Area.ListACS) Then Begin
      Inc (Count);
      List[Count].MBase   := Area;
      List[Count].BaseNum := RawNum;
      ScanBaseStats (Area, List[Count].Total, List[Count].NewC, List[Count].Yours);
    End;
  End;

  Close (BaseFile);
End;

Procedure BuildAreaIdxOrder (Var Cfg: RecAreaIdxCfg; Var List: TAreaIdxList;
                             Count: Integer; Var Order: TAreaIdxOrder;
                             Var OrderCount: Integer);
Var
  Idx     : Array[1..MaxAreaIdx] of Integer;
  N       : Integer;
  I, J, T : Integer;
  LastCat : Integer;
  Cat     : Integer;

  Function CatOf (B: Integer) : Integer;
  Begin
    If Cfg.GroupList Then
      CatOf := 0
    Else
    If List[B].MBase.NetType = 0 Then
      CatOf := 0
    Else
      CatOf := List[B].MBase.NetAddr;
  End;

  Function Less (A, B: Integer) : Boolean;
  Var
    Ca, Cb : Integer;
  Begin
    Ca := CatOf(A);
    Cb := CatOf(B);

    If Ca <> Cb Then Begin
      Less := Ca < Cb;
      Exit;
    End;

    If Cfg.NewAtTop Then
      If (List[A].NewC > 0) <> (List[B].NewC > 0) Then Begin
        Less := List[A].NewC > 0;
        Exit;
      End;

    Less := strUpper(List[A].MBase.Name) < strUpper(List[B].MBase.Name);
  End;

Begin
  OrderCount := 0;

  N := 0;
  For I := 1 to Count Do Begin
    Inc (N);
    Idx[N] := I;
  End;

  For I := 2 to N Do Begin
    T := Idx[I];
    J := I - 1;
    While (J >= 1) and Less(T, Idx[J]) Do Begin
      Idx[J + 1] := Idx[J];
      Dec (J);
    End;
    Idx[J + 1] := T;
  End;

  LastCat := -1;

  For I := 1 to N Do Begin
    Cat := CatOf(Idx[I]);

    If Cfg.ShowDivs and (Not Cfg.GroupList) and (Cat <> LastCat) and (Cat > 0) Then
      If OrderCount < MaxAreaIdx + 64 Then Begin
        Inc (OrderCount);
        Order[OrderCount].IsDivider := True;
        Order[OrderCount].BaseIdx   := 0;
        Order[OrderCount].DivText   := FormatNetAddr(bbsCfg.NetAddress[Cat]);
      End;

    LastCat := Cat;

    If OrderCount < MaxAreaIdx + 64 Then Begin
      Inc (OrderCount);
      Order[OrderCount].IsDivider := False;
      Order[OrderCount].BaseIdx   := Idx[I];
      Order[OrderCount].DivText   := '';
    End;
  End;
End;

// ---------------------------------------------------------------------------
// Chunk 5: interactive reader.  ENTER reads the selected base, CTRL-N jumps to
// the next base with new mail, CTRL-R recalculates, CTRL-Z shows help, ESC
// quits.  CTRL-P/CTRL-U are stubbed for their later alphas.  Wired to MI.
// ---------------------------------------------------------------------------
Procedure AreaIndex;
Var
  Cfg        : RecAreaIdxCfg;
  List       : ^TAreaIdxList;
  Order      : ^TAreaIdxOrder;
  Count      : Integer;
  OrderCount : Integer;
  Menu       : TAnsiListBox;
  Quit       : Boolean;
  P, B       : Integer;
  SavedArrow : Boolean;
  SavedLBIdx : Boolean;

  Procedure DrawFrame;
  Begin
    Session.io.OutFile ('ansimidx', False, 0);
  End;

  Procedure PopulateList;
  Var
    I, Bx : Integer;
    Row   : String;
  Begin
    If Cfg.Str[8] <> '' Then Session.io.OutFull (Cfg.Str[8]);

    GatherAreaStats   (List^, Count);
    BuildAreaIdxOrder (Cfg, List^, Count, Order^, OrderCount);

    Menu.Clear;

    For I := 1 to OrderCount Do
      If Order^[I].IsDivider Then
        Menu.Add (Order^[I].DivText, 2)
      Else Begin
        Bx  := Order^[I].BaseIdx;
        Row := strPadR(strStripPipe(List^[Bx].MBase.Name), 46, ' ') +
               strPadL(strI2S(List^[Bx].Total), 7, ' ') +
               strPadL(strI2S(List^[Bx].NewC),  8, ' ') +
               strPadL(strI2S(List^[Bx].Yours), 8, ' ');
        Menu.Add (Row, 0);
      End;
  End;

  // next base entry with new mail after From (wraps); 0 if none
  Function NextNew (From: Integer) : Integer;
  Var
    I, K : Integer;
  Begin
    NextNew := 0;
    If OrderCount < 1 Then Exit;

    For I := 1 to OrderCount Do Begin
      K := ((From - 1 + I) Mod OrderCount) + 1;
      If (Not Order^[K].IsDivider) and (List^[Order^[K].BaseIdx].NewC > 0) Then Begin
        NextNew := K;
        Exit;
      End;
    End;
  End;

Begin
  New (List);
  New (Order);

  LoadAreaIdxCfg (Session.Theme.TextPath + 'ansimidx.ini', Cfg);

  Menu := TAnsiListBox.Create;
  Menu.NoWindow := True;
  Menu.HiAttr   := 112;
  Menu.LoAttr   := 7;
  Menu.Format   := 0;
  Menu.SearchX  := Cfg.SrchX;
  Menu.SearchY  := Cfg.SrchY;
  Menu.SearchA  := Cfg.SrchA;
  Menu.LoChars  := #13 + #14 + #16 + #18 + #21 + #26 + #27;

  SavedArrow := Session.io.AllowArrow;

  PopulateList;
  DrawFrame;

  If Cfg.SnapNew Then Begin
    P := NextNew(1);
    If P > 0 Then Menu.Picked := P;
  End;

  Quit := False;

  Repeat
    Menu.Open (Cfg.WinX1, Cfg.WinY1, Cfg.WinX2, Cfg.WinY2);

    P := Menu.Picked;

    Case Menu.ExitCode of
      #27 : Quit := True;
      #13 : If (P >= 1) and (P <= OrderCount) and (Not Order^[P].IsDivider) Then Begin
              B := Order^[P].BaseIdx;

              Session.Msgs.ChangeArea (strI2S(List^[B].BaseNum));

              // no_index: temporarily bypass the user's lightbar msg index so
              // ENTER drops straight into the reader (ansimidx.ini no_index=true)
              If Cfg.NoIndex Then Begin
                SavedLBIdx := Session.User.ThisUser.UseLBIndex;
                Session.User.ThisUser.UseLBIndex := False;
              End;

              // "read new if new exist, else start at the first message".
              // Mode 'N' is a definite read mode, so ReadMessages does NOT show
              // its read-type prompt (GetPrompt 112).  With no new mail, rewind
              // last-read to 0 first so 'N' reads from message 1.
              If List^[B].NewC = 0 Then
                SetBaseLastRead (List^[B].MBase, 0);

              Session.Msgs.ReadMessages ('N', '', '');

              If Cfg.NoIndex Then
                Session.User.ThisUser.UseLBIndex := SavedLBIdx;

              // the read flow leaves AllowArrow False -> re-enable for the list
              Session.io.AllowArrow := True;

              PopulateList;
              DrawFrame;

              If Cfg.SnapNew Then Begin
                B := NextNew(P);
                If B > 0 Then Menu.Picked := B;
              End;
            End;
      #14 : Begin
              B := NextNew(P);
              If B > 0 Then Menu.Picked := B;
            End;
      #18 : Begin
              PopulateList;
              DrawFrame;
            End;
      #26 : Begin
              Session.io.OutFile ('ansimidxhelp', True, 0);
              DrawFrame;
            End;
      #16 : ;   // CTRL-P post  -> A52 (stub)
      #21 : ;   // CTRL-U catch -> A51 (stub)
    End;
  Until Quit;

  Menu.Free;

  Session.io.AllowArrow := SavedArrow;

  Dispose (Order);
  Dispose (List);
End;

End.
