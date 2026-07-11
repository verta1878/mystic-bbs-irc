// ====================================================================
// Mystic BBS Software               Copyright 1997-2013 By James Coyle
// ====================================================================
//
// This file is part of Mystic BBS.
//
// Mystic BBS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Mystic BBS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Mystic BBS.  If not, see <http://www.gnu.org/licenses/>.
//
// ====================================================================
//
// A40: Built-in AreaFix.  A remote node sends a NetMail addressed to
// "AreaFix" (password in the subject) whose body contains commands to
// link/unlink echos, list areas, rescan, change password, etc.  Mystic
// processes the commands and replies with a NetMail summarising results.
//
// Works on existing structures (no records change): RecEchoMailNode.
// AreaFixPass, <base>.lnk (File of RecEchoMailExport), mbases.dat.  Reuses
// IsExportNode / AddExportByBase / RemoveExportFromBase (bbs_database) and
// SaveMessage / GetMBaseByNetZone (mutil_common).
//
// ====================================================================
Unit MUTIL_EchoFix;

{$I M_OPS.PAS}

Interface

Uses
  mUtil_EchoCore;

Function ProcessedByAreaFix (Var PKT: TPKTReader) : Boolean;

Implementation

Uses
  DOS,
  m_Strings,
  m_FileIO,
  BBS_Records,
  BBS_DataBase,
  mUtil_Common;

// Find the active echomail node whose address matches the message origin
// and whose AreaFix password matches PW.  PKT.MsgOrig carries the full
// Zone/Net/Node origin so we can match properly.  Point is ignored (a
// point authenticates through its boss node).
Function GetNodeByAuth (Addr: RecEchoMailAddr; PW: String; Var TempNode: RecEchoMailNode) : Boolean;
Var
  F : File;
Begin
  Result := False;

  Assign (F, bbsCfg.DataPath + 'echonode.dat');

  If Not ioReset(F, SizeOf(RecEchoMailNode), fmRWDN) Then Exit;

  While Not Eof(F) And Not Result Do Begin
    ioRead(F, TempNode);

    If Not TempNode.Active Then Continue;

    Result := (Addr.Zone = TempNode.Address.Zone) and
              (Addr.Net  = TempNode.Address.Net)  and
              (Addr.Node = TempNode.Address.Node) and
              (strUpper(PW) = strUpper(TempNode.AreaFixPass));
  End;

  Close (F);
End;

// Save the node record back to echonode.dat (used by %PWD, %COMPRESS).
Procedure SaveEchoNode (Var Node: RecEchoMailNode);
Var
  F : File;
Begin
  Assign (F, bbsCfg.DataPath + 'echonode.dat');

  If Not ioReset(F, SizeOf(RecEchoMailNode), fmRWDN) Then Exit;

  Seek    (F, Node.Index - 1);
  ioWrite (F, Node);
  Close   (F);
End;

// Is this base an echomail area available to the node?  "Available" = an
// echomail base (NetType 1) with a tag, whose network domain matches the
// node's domain.
Function BaseInNodeDomain (Var MBase: RecMessageBase; Var Node: RecEchoMailNode) : Boolean;
Begin
  BaseInNodeDomain := (MBase.NetType = 1) and (MBase.EchoTag <> '') and
                      (strUpper(bbsCfg.NetDomain[MBase.NetAddr]) = strUpper(Node.Domain));
End;

// Append one bounded line to the response buffer.
Procedure AddLine (Var Buf: RecMessageText; Var Lines: Integer; Str: String);
Begin
  If Lines < mysMaxMsgLines Then Begin
    Inc (Lines);
    Buf[Lines] := Copy(Str, 1, 79);
  End;
End;

// Find a message base by echo tag.
Function GetBaseByTag (Tag: String; Var MBase: RecMessageBase) : Boolean;
Var
  F : File;
Begin
  Result := False;

  Assign (F, bbsCfg.DataPath + 'mbases.dat');

  If Not ioReset(F, SizeOf(RecMessageBase), fmRWDN) Then Exit;

  While Not Eof(F) And Not Result Do Begin
    ioRead(F, MBase);

    If (MBase.NetType = 1) and (strUpper(MBase.EchoTag) = strUpper(Tag)) Then
      Result := True;
  End;

  Close (F);
End;

// Parse an optional "R=# / D=#" rescan qualifier (comma or space
// separated from the tag).  RC = messages, RD = days; 0 if absent.
Procedure ParseRescan (Str: String; Var RC, RD: LongInt);
Var
  P : Byte;
Begin
  RC  := 0;
  RD  := 0;
  Str := strUpper(Str);

  P := Pos('R=', Str);
  If P > 0 Then RC := strS2I(Copy(Str, P + 2, 8));

  P := Pos('D=', Str);
  If P > 0 Then RD := strS2I(Copy(Str, P + 2, 8));
End;

// Append a rescan request to the AreaFix rescan queue (areafix.rsn in the DATA
// folder).  One line per request: NodeIndex|BaseIndex|Count|Days.  The export
// pass (uEchoExport) reads and clears this queue and performs the re-exports,
// which keeps the message-base export logic in one place and avoids a circular
// unit dependency.  BaseIndex 0 = "all linked areas".  Count 0 defaults to 250
// at export time; Days 0 = not a day-based rescan.
Procedure QueueRescan (NodeIdx, BaseIdx, Cnt, Days: LongInt);
Var
  F : Text;
Begin
  Assign (F, bbsCfg.DataPath + 'areafix.rsn');

  {$I-}
  Append (F);
  If IOResult <> 0 Then ReWrite (F);
  {$I+}
  If IOResult <> 0 Then Exit;

  WriteLn (F, strI2S(NodeIdx) + '|' + strI2S(BaseIdx) + '|' +
              strI2S(Cnt) + '|' + strI2S(Days));

  Close (F);
End;

Function ProcessedByAreaFix (Var PKT: TPKTReader) : Boolean;
Var
  Node   : RecEchoMailNode;
  RBuf   : RecMessageText;
  RLines : Integer;
  NmBase : RecMessageBase;
  Count  : LongInt;
  Line   : String;
  Cmd    : String;
  Arg    : String;
  Tag    : String;
  Sign   : Char;
  RC, RD : LongInt;
  MBase  : RecMessageBase;
  HelpF  : Text;
  HelpS  : String;

  // List available areas, optionally filtered by linked state, each line
  // marked "[X] TAG" (X = linked) or "[ ] TAG" (unlinked).
  Procedure ListAreas (WantLinked, WantUnlinked, WantAll: Boolean);
  Var
    LF     : File;
    LB     : RecMessageBase;
    Linked : Boolean;
    Mark   : String;
  Begin
    Assign (LF, bbsCfg.DataPath + 'mbases.dat');
    If Not ioReset(LF, SizeOf(RecMessageBase), fmRWDN) Then Exit;

    While Not Eof(LF) Do Begin
      ioRead(LF, LB);

      If Not BaseInNodeDomain(LB, Node) Then Continue;

      Linked := IsExportNode(LB, Node.Index);

      If WantAll or (WantLinked and Linked) or (WantUnlinked and Not Linked) Then Begin
        If Linked Then Mark := '[*] ' Else Mark := '[ ] ';
        AddLine (RBuf, RLines, Mark + LB.EchoTag);
      End;
    End;

    Close (LF);
  End;

Begin
  Result := False;

  // AreaFix only; FileFix (A41) shares the detection but is out of A40
  // scope - returning False lets FileFix mail toss normally.
  If strUpper(PKT.MsgTo) <> 'AREAFIX' Then Exit;

  // Authenticate: subject holds the password; origin must match a
  // configured active node.  On failure, consume the message (so it is
  // not tossed publicly) but send no reply (no password oracle).
  If Not GetNodeByAuth(PKT.MsgOrig, PKT.MsgSubj, Node) Then Begin
    Result := True;
    Exit;
  End;

  RLines := 0;
  AddLine (RBuf, RLines, 'AreaFix results for ' + Node.Description + ':');
  AddLine (RBuf, RLines, '');

  For Count := 1 to PKT.MsgLines Do Begin
    Line := PKT.MsgText[Count]^;

    If (Line = '') or (Line[1] = #1) or (Copy(Line, 1, 7) = 'SEEN-BY') Then Continue;

    Line := strStripB(strStripB(Line, #32), #9);
    If Line = '' Then Continue;

    Cmd := strUpper(strWordGet(1, Line, ' '));
    Arg := strStripB(Copy(Line, Length(strWordGet(1, Line, #32)) + 1, 255), #32);

    If Cmd = '%HELP' Then Begin
      Assign (HelpF, bbsCfg.DataPath + 'areafixhelp.txt');
      {$I-} Reset (HelpF); {$I+}
      If IOResult = 0 Then Begin
        While Not Eof(HelpF) Do Begin
          ReadLn (HelpF, HelpS);
          AddLine (RBuf, RLines, HelpS);
        End;
        Close (HelpF);
      End Else
        AddLine (RBuf, RLines, 'No help file is available.');
    End Else
    If Cmd = '%LIST' Then Begin
      AddLine (RBuf, RLines, 'Available areas:');
      ListAreas (False, False, True);
    End Else
    If Cmd = '%LINKED' Then Begin
      AddLine (RBuf, RLines, 'Linked areas:');
      ListAreas (True, False, False);
    End Else
    If Cmd = '%UNLINKED' Then Begin
      AddLine (RBuf, RLines, 'Unlinked areas:');
      ListAreas (False, True, False);
    End Else
    If Cmd = '%PWD' Then Begin
      Node.AreaFixPass := Copy(strStripB(Arg, #32), 1, 20);
      SaveEchoNode (Node);
      AddLine (RBuf, RLines, 'Password changed.');
    End Else
    If Cmd = '%COMPRESS' Then Begin
      Node.ArcType := Copy(strStripB(Arg, #32), 1, 4);
      SaveEchoNode (Node);
      If Node.ArcType = '' Then
        AddLine (RBuf, RLines, 'Compression set to: raw PKT')
      Else
        AddLine (RBuf, RLines, 'Compression set to: ' + Node.ArcType);
    End Else
    If Cmd = '%RESCAN' Then Begin
      ParseRescan (Arg, RC, RD);
      QueueRescan (Node.Index, 0, RC, RD);
      If RD > 0 Then
        AddLine (RBuf, RLines, 'Rescan queued for all linked areas (last ' + strI2S(RD) + ' days).')
      Else If RC > 0 Then
        AddLine (RBuf, RLines, 'Rescan queued for all linked areas (last ' + strI2S(RC) + ' msgs).')
      Else
        AddLine (RBuf, RLines, 'Rescan queued for all linked areas (last 250 msgs).');
    End Else
    If (Line[1] In ['+', '-', '=']) or (Cmd[1] <> '%') Then Begin
      // +/-/= ECHOTAG, or a bare tag (= add).
      If Line[1] In ['+', '-', '='] Then Begin
        Sign := Line[1];
        Tag  := strWordGet(1, Copy(Line, 2, 255), ' ');
      End Else Begin
        Sign := '+';
        Tag  := strWordGet(1, Line, ' ');
      End;

      Tag := strWordGet(1, Tag, ',');
      ParseRescan (Copy(Line, Pos(Tag, Line) + Length(Tag), 255), RC, RD);

      If GetBaseByTag(Tag, MBase) Then Begin
        Case Sign of
          '-' : Begin
                  RemoveExportFromBase (MBase, Node.Index);
                  AddLine (RBuf, RLines, 'Removed: ' + Tag);
                End;
          '=' : Begin
                  If IsExportNode(MBase, Node.Index) Then Begin
                    QueueRescan (Node.Index, MBase.Index, RC, RD);
                    AddLine (RBuf, RLines, 'Rescan queued: ' + Tag);
                  End Else
                    AddLine (RBuf, RLines, 'Not linked (cannot rescan): ' + Tag);
                End;
        Else
          If IsExportNode(MBase, Node.Index) Then
            AddLine (RBuf, RLines, 'Already linked: ' + Tag)
          Else Begin
            AddExportByBase (MBase, Node.Index);
            AddLine (RBuf, RLines, 'Added: ' + Tag);

            // +TAG with an R=/D= qualifier also rescans the newly linked base.
            If (RC > 0) or (RD > 0) Then Begin
              QueueRescan (Node.Index, MBase.Index, RC, RD);
              AddLine (RBuf, RLines, 'Rescan queued: ' + Tag);
            End;
          End;
        End;
      End Else
        AddLine (RBuf, RLines, 'Unknown area: ' + Tag);
    End;
  End;

  // Consume the request regardless of outcome.
  Result := True;

  // Send the NetMail reply back to the requesting node.  The reply is written
  // into the netmail base (NetType 3) returned by GetMBaseByNetZone and
  // addressed to Node.Address; SaveMessage marks it netmail and sets the
  // destination (see the NetType-3 fix in mutil_common.SaveMessage).
  If GetMBaseByNetZone(Node.Address.Zone, NmBase) Then
    SaveMessage (NmBase, 'AreaFix', PKT.MsgFrom, 'AreaFix Results',
                 Node.Address, RBuf, RLines);
End;

End.
