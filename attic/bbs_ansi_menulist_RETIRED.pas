// ====================================================================
// RETIRED - not built, kept for reference / scene history
// --------------------------------------------------------------------
// TAnsiMenuList: the OLD list widget, fully replaced by TAnsiListBox in
// mystic/bbs_ansi_menubox.pas.  All 14 consumers (bbs_areaindex + 13
// bbs_cfg_* editors) were migrated to TAnsiListBox; A51 ships TAnsiListBox
// only (zero TAnsiMenuList).  This is the extracted interface + impl of the
// old class, retained (not deleted) for GPL-3 attribution and Mystic scene
// history.  Retired from the active unit on 2026-07-06 (fork).
// ====================================================================

// ====================================================================
// MIGRATION SCAFFOLD (fork): TAnsiMenuList is the OLD list widget being
// replaced by TAnsiListBox (above).  It is re-added here TEMPORARILY so the
// 14 consumers still compile while they are migrated to TAnsiListBox one at
// a time.  Once all consumers are migrated, this whole block + its impls are
// retired to attic/ (A51 ships TAnsiListBox only, zero TAnsiMenuList).
// ====================================================================
Type
  TAnsiMenuListStatusProc = Procedure (Num: Word; Str: String);
  TAnsiMenuListSearchProc = Procedure (Var Owner: Pointer; Str: String);

  TAnsiMenuListBoxRec = Record
    Name   : String;
    Tagged : Byte;                     { 0 = false, 1 = true, 2 = never }
  End;

  TAnsiMenuList = Class
    List       : Array[1..10000] of ^TAnsiMenuListBoxRec;
    Box        : TAnsiMenuBox;
    HiAttr     : Byte;
    LoAttr     : Byte;
    PosBar     : Boolean;
    Format     : Byte;
    LoChars    : String;
    HiChars    : String;
    ExitCode   : Char;
    Picked     : Integer;
    TopPage    : Integer;
    NoWindow   : Boolean;
    ListMax    : Integer;
    AllowTag   : Boolean;
    TagChar    : Char;
    TagKey     : Char;
    TagPos     : Byte;
    TagAttr    : Byte;
    Marked     : Word;
    StatusProc : TAnsiMenuListStatusProc;
    Width      : Integer;
    WinSize    : Integer;
    X1         : Byte;
    Y1         : Byte;
    NoInput    : Boolean;
    LastBarPos : Byte;
    SearchProc : TAnsiMenuListSearchProc;
    SearchX    : Byte;
    SearchY    : Byte;
    SearchA    : Byte;

    Constructor Create;
    Destructor  Destroy; Override;
    Procedure   Open (BX1, BY1, BX2, BY2: Byte);
    Procedure   Close;
    Procedure   Add (Str: String; B: Byte);
    Procedure   Get (Num: Word; Var Str: String; Var B: Boolean);
    Procedure   SetStatusProc (P: TAnsiMenuListStatusProc);
    Procedure   SetSearchProc (P: TAnsiMenuListSearchProc);
    Procedure   Clear;
    Procedure   Delete (RecPos : Word);
    Procedure   UpdatePercent;
    Procedure   UpdateBar (X, Y: Byte; RecPos: Word; IsHi: Boolean);
    Procedure   Update;
  End;

// ==================== MIGRATION SCAFFOLD: TAnsiMenuList impls ====================
// (temporary - retired with the class once all 14 consumers move to TAnsiListBox)

Constructor TAnsiMenuList.Create;
Begin
  Inherited Create;

  Box        := TAnsiMenuBox.Create;
  ListMax    := 0;
  HiAttr     := 15 + 1 * 16;
  LoAttr     := 1  + 7 * 16;
  PosBar     := True;
  Format     := 0;
  LoChars    := #13#27;
  HiChars    := '';
  NoWindow   := False;
  AllowTag   := False;
  TagChar    := '*';
  TagKey     := #09;
  TagPos     := 0;
  TagAttr    := 15 + 7 * 16;
  Marked     := 0;
  Picked     := 1;
  NoInput    := False;
  LastBarPos := 0;
  StatusProc := NIL;
  SearchProc := @DefListBoxSearch;
  SearchX    := 0;
  SearchY    := 0;
  SearchA    := 0;
  TopPage    := 1;

  Session.io.BufFlush;
End;

Procedure TAnsiMenuList.Clear;
Var
  Count : Word;
Begin
  For Count := 1 to ListMax Do
    Dispose(List[Count]);

  ListMax := 0;
  Marked  := 0;
End;

Procedure TAnsiMenuList.Delete (RecPos : Word);
Var
  Count : Word;
Begin
  If List[RecPos] <> NIL Then Begin
    Dispose (List[RecPos]);

    For Count := RecPos To ListMax - 1 Do
      List[Count] := List[Count + 1];

    Dec (ListMax);
  End;
End;

Destructor TAnsiMenuList.Destroy;
Begin
  Box.Free;

  Clear;

  Inherited Destroy;
End;

Procedure TAnsiMenuList.UpdateBar (X, Y: Byte; RecPos: Word; IsHi: Boolean);
Var
  Str  : String;
  Attr : Byte;
Begin
  If IsHi Then
    Attr := HiAttr
  Else
    Attr := LoAttr;

  If RecPos <= ListMax Then Begin
    Str := ' ' + List[RecPos]^.Name + ' ';

    Case Format of
      0 : Str := strPadR(Str, Width, ' ');
      1 : Str := strPadL(Str, Width, ' ');
      2 : Str := strPadC(Str, Width, ' ');
    End;
  End Else
    Str := strRep(' ', Width);

  WriteXY (X, Y, Attr, Str);

  If AllowTag Then
    If (RecPos <= ListMax) and (List[RecPos]^.Tagged = 1) Then
      WriteXY (TagPos, Y, TagAttr, TagChar)
    Else
      WriteXY (TagPos, Y, TagAttr, ' ');
End;

Procedure TAnsiMenuList.UpdatePercent;
Var
  NewPos : LongInt;
Begin
  If Not PosBar Then Exit;

  If (ListMax > 0) and (WinSize > 0) Then Begin
    NewPos := (Picked * WinSize) DIV ListMax;

    If Picked >= ListMax Then NewPos := Pred(WinSize);

    If (NewPos < 0) or (Picked = 1) Then NewPos := 0;

    NewPos := Y1 + 1 + NewPos;

    If LastBarPos <> NewPos Then Begin
      If LastBarPos > 0 Then
        WriteXY (X1 + Width + 1, LastBarPos, Box.BoxAttr2, #176);

      LastBarPos := NewPos;

      WriteXY (X1 + Width + 1, NewPos, Box.BoxAttr2, #178);
    End;
  End;
End;

Procedure TAnsiMenuList.Update;
Var
  Loop   : LongInt;
  CurRec : Integer;
Begin
  For Loop := 0 to WinSize - 1 Do Begin
    CurRec := TopPage + Loop;

    UpdateBar (X1 + 1, Y1 + 1 + Loop, CurRec, CurRec = Picked);
  End;

  UpdatePercent;

  Session.io.BufFlush;
End;

Procedure TAnsiMenuList.Open (BX1, BY1, BX2, BY2 : Byte);

  Procedure DownArrow;
  Begin
    If Picked < ListMax Then Begin
      If Picked >= TopPage + WinSize - 1 Then Begin
        Inc (TopPage);
        Inc (Picked);

        Update;
      End Else Begin
        UpdateBar (X1 + 1, Y1 + Picked - TopPage + 1, Picked, False);

        Inc (Picked);

        UpdateBar (X1 + 1, Y1 + Picked - TopPage + 1, Picked, True);

        UpdatePercent;
      End;
    End;
  End;

Var
  Ch          : Char;
  Count       : Word;
  StartPos    : Word;
  EndPos      : Word;
  First       : Boolean;
  SavedRec    : Word;
  SavedTop    : Word;
  SearchStr   : String;
  LastWasChar : Boolean;
Begin
  If Not NoWindow Then
    Box.Open (BX1, BY1, BX2, BY2);

  If SearchX = 0 Then SearchX := BX1 + 2;
  If SearchY = 0 Then SearchY := BY2;
  If SearchA = 0 Then SearchA := Box.BoxAttr4;

  X1 := BX1;
  Y1 := BY1;

  If (Picked < TopPage) or (Picked < 1) or (Picked > ListMax) or (TopPage < 1) or (TopPage > ListMax) Then Begin
    Picked  := 1;
    TopPage := 1;
  End;

  Width   := BX2 - X1 - 1;
  WinSize := BY2 - Y1 - 1;
  TagPos  := X1 + 1;

  While Picked > TopPage + WinSize - 1 Do
    Inc (TopPage);

  If PosBar Then
    For Count := 1 to WinSize Do
      WriteXY (X1 + Width + 1, Y1 + Count, Box.BoxAttr2, #176);

  If NoInput Then Exit;

  Update;

  LastWasChar := False;
  SearchStr   := '';

  Repeat
    If Not LastWasChar Then Begin
      If Assigned(SearchProc) And (SearchStr <> '') Then
        SearchProc (Self, '');

      SearchStr := ''
    End Else
      LastWasChar := False;

    If Assigned(StatusProc) Then
      If ListMax > 0 Then
        StatusProc(Picked, List[Picked]^.Name)
      Else
        StatusProc(Picked, '');

    Ch := Session.io.GetKey;

    If Session.io.IsArrow Then Begin
      Case Ch of
        #71 : If Picked > 1 Then Begin { home }
                Picked  := 1;
                TopPage := 1;
                Update;
              End;
        #72 : If (Picked > 1) Then Begin
                If Picked <= TopPage Then Begin
                  Dec (Picked);
                  Dec (TopPage);

                  Update;
                End Else Begin
                  UpdateBar (X1 + 1, Y1 + Picked - TopPage + 1, Picked, False);

                  Dec (Picked);

                  UpdateBar (X1 + 1, Y1 + Picked - TopPage + 1, Picked, True);

                  UpdatePercent;
                End;
              End;
        #73,
        #75 : If (TopPage > 1) or (Picked > 1) Then Begin { page up / left arrow }
                If Picked - WinSize > 1 Then Dec (Picked, WinSize) Else Picked := 1;
                If TopPage - WinSize < 1 Then TopPage := 1 Else Dec(TopPage, WinSize);
                Update;
              End;
        #79 : If Picked < ListMax Then Begin { end }
                If ListMax > WinSize Then TopPage := ListMax - WinSize + 1;
                Picked := ListMax;
                Update;
              End;
        #80 : DownArrow;
        #77,
        #81 : If (Picked <> ListMax) Then Begin { pgdn/right }
                If ListMax > WinSize Then Begin
                  If Picked + WinSize > ListMax Then
                    Picked := ListMax
                  Else
                    Inc (Picked, WinSize);

                  Inc (TopPage, WinSize);

                  If TopPage + WinSize > ListMax Then TopPage := ListMax - WinSize + 1;
                End Else Begin
                  Picked := ListMax;
                End;

                Update;
              End;
      Else
        If Pos(Ch, HiChars) > 0 Then Begin
          If SearchStr <> '' Then Begin
            SearchStr := '';
            If Assigned(SearchProc) Then
              SearchProc(Self, SearchStr);
          End;

          ExitCode := Ch;
          Exit;
        End;
      End;
    End Else
      If AllowTag and (Ch = TagKey) and (List[Picked]^.Tagged <> 2) Then Begin
        If (List[Picked]^.Tagged = 1) Then Begin
          Dec (List[Picked]^.Tagged);
          Dec (Marked);
        End Else Begin
          List[Picked]^.Tagged := 1;
          Inc (Marked);
        End;

        DownArrow;
      End Else
      If Pos(Ch, LoChars) > 0 Then Begin
        If SearchStr <> '' Then Begin
          SearchStr := '';
          If Assigned(SearchProc) Then
            SearchProc(Self, SearchStr);
        End;

        ExitCode := Ch;
        Exit;
      End Else Begin
        If Ch <> #01 Then Begin
          If Ch = #25 Then Begin
            LastWasChar := False;
            Continue;
          End;

          If Ch = #8 Then Begin
            If Length(SearchStr) > 0 Then
              Dec(SearchStr[0])
            Else
              Continue;
          End Else
            If Ord(Ch) < 32 Then
              Continue
            Else
              SearchStr := SearchStr + UpCase(Ch);
        End;

        SavedTop    := TopPage;
        SavedRec    := Picked;
        LastWasChar := True;
        First       := True;
        StartPos    := Picked + 1;
        EndPos      := ListMax;

        If Assigned(SearchProc) Then
          SearchProc(Self, SearchStr);

        If StartPos > ListMax Then StartPos := 1;

        Count := StartPos;

        While (Count <= EndPos) Do Begin
          If Pos(strUpper(SearchStr), strUpper(List[Count]^.Name)) > 0 Then Begin

            While Count <> Picked Do Begin
              If Picked < Count Then Begin
                If Picked < ListMax Then Inc (Picked);
                If Picked > TopPage + WinSize - 1 Then Inc (TopPage);
              End Else
              If Picked > Count Then Begin
                If Picked > 1 Then Dec (Picked);
                If Picked < TopPage Then Dec (TopPage);
              End;
            End;
            Break;
          End;

          If (Count = ListMax) and First Then Begin
            Count    := 0;
            StartPos := 1;
            EndPos   := Picked - 1;
            First    := False;
          End;

          Inc (Count);
        End;

        If TopPage <> SavedTop Then
          Update
        Else
        If Picked <> SavedRec Then Begin
          UpdateBar (X1 + 1, Y1 + SavedRec - SavedTop + 1, SavedRec, False);
          UpdateBar (X1 + 1, Y1 + Picked - TopPage + 1, Picked, True);
          UpdatePercent;
        End;
      End;
  Until False;
End;

Procedure TAnsiMenuList.Close;
Begin
  If Not NoWindow Then Box.Close;
End;

Procedure TAnsiMenuList.Add (Str : String; B : Byte);
Begin
  Inc (ListMax);
  New (List[ListMax]);

  List[ListMax]^.Name   := Str;
  List[ListMax]^.Tagged := B;

  If B = 1 Then Inc(Marked);
End;

Procedure TAnsiMenuList.Get (Num : Word; Var Str : String; Var B : Boolean);
Begin
  Str := '';
  B   := False;

  If Num <= ListMax Then Begin
    Str := List[Num]^.Name;
    B   := List[Num]^.Tagged = 1;
  End;
End;

Procedure TAnsiMenuList.SetSearchProc (P: TAnsiMenuListSearchProc);
Begin
  SearchProc := P;
End;

Procedure TAnsiMenuList.SetStatusProc (P: TAnsiMenuListStatusProc);
Begin
  StatusProc := P;
End;
