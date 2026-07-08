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
Unit MUTIL_EchoExport;

{$I M_OPS.PAS}

Interface

Uses
  BBS_Records,
  BBS_MsgBase_ABS,
  BBS_MsgBase_JAM,
  BBS_MsgBase_Squish,
  mUtil_EchoImport;

Procedure uEchoExport;

Procedure EchoExportMessage (Var MBase: RecMessageBase; Var MsgBase: PMsgBaseABS; Var Links: TEchoMailLinks; Var TotalNet, TotalEcho: LongInt);
Procedure EchoBundleMessages;

Implementation

Uses
  DOS,
  m_Strings,
  m_FileIO,
  m_DateTime,
  mUtil_Common,
  mUtil_Status,
  mUtil_EchoCore,
  BBS_DataBase;

// Adds packet name into a FLO-type file if it does not exist already
// Should this also remove any packets that do not exist?  i think so...

Procedure AddToFLOQueue (FloName, PacketFN: String);
Var
  T   : Text;
  Str : String;
Begin
  FileMode := 66;

  Assign (T, FloName);
  {$I-} Reset (T); {$I+}

  If IoResult <> 0 Then Begin
    {$I-} ReWrite(T); {$I+}
    Reset(T);
  End;

  While Not Eof(T) Do Begin
    ReadLn (T, Str);

    If (strUpper(Str) = strUpper(PacketFN)) or (strUpper(Copy(Str, 2, 255)) = strUpper(PacketFN)) Then Begin
      Close (T);
      Exit;
    End;
  End;

  Append  (T);
  WriteLn (T, '^' + PacketFN);
  Close   (T);
End;

Procedure EchoBundleMessages;
Var
  F          : File;
  PH         : RecPKTHeader;
  DirInfo    : SearchRec;
  NodeIndex  : LongInt;
  EchoNode   : RecEchoMailNode;
  PKTName    : String;
  BundleName : String;
  BundlePath : String;
  Temp       : String;
  FLOName    : String;
  OrigAddr   : RecEchoMailAddr;
  CheckInc   : Boolean;
Begin
  FindFirst (TempPath + '*', AnyFile, DirInfo);

  While DosError = 0 Do Begin
    If DirInfo.Attr AND Directory = 0 Then Begin
      NodeIndex := strS2I(JustFileExt(DirInfo.Name));
      PKTName   := JustFileName(DirInfo.Name) + '.pkt';

      GetNodeByIndex (NodeIndex, EchoNode);
      FileReName     (TempPath + DirInfo.Name, TempPath + PKTName);

      Assign    (F, TempPath + PKTName);
      Reset     (F, 1);
      BlockRead (F, PH, SizeOf(PH));
      Close     (F);

      OrigAddr.Zone := PH.OrigZone;
      OrigAddr.Net  := PH.OrigNet;
      OrigAddr.Node := PH.OrigNode;

      BundlePath := GetFTNOutPath(EchoNode);
      FLOName    := BundlePath + GetFTNFlowName(EchoNode.Address);
      CheckInc   := False;

      DirCreate (BundlePath);

      Case EchoNode.MailType of
        0 : FLOName := FLOName + '.flo';
        1 : FLOName := FLOName + '.clo';
        2 : FLOName := FLOName + '.dlo';
        3 : FLOName := FLOName + '.hlo';
      End;

      If EchoNode.ArcType = '' Then Begin
        FileReName    (TempPath + PKTName, BundlePath + PKTName);
        AddToFLOQueue (FLOName, BundlePath + PKTName);
      End Else Begin
        If Not (EchoNode.LPKTPtr in [48..57, 97..122]) Then
          EchoNode.LPKTPtr := 48;

        If EchoNode.LPKTDay <> DayOfWeek(CurDateDos) Then Begin
          EchoNode.LPKTDay := DayOfWeek(CurDateDos);
          EchoNode.LPKTPtr := 48;
        End Else
          CheckInc := True;

        BundleName := BundlePath + GetFTNArchiveName(OrigAddr, EchoNode.Address) + '.' + Copy(strLower(DayString[DayOfWeek(CurDateDos)]), 1, 2) + Char(EchoNode.LPKTPtr);

        If CheckInc And Not FileExist(BundleName) Then Begin
          BundleName := GetFTNBundleExt(True, BundleName);

          EchoNode.LPKTPtr := Byte(BundleName[Length(BundleName)]);
        End;

        SaveEchoMailNode(EchoNode);

        ExecuteArchive (TempPath, BundleName, EchoNode.ArcType, TempPath + PKTName, 1);
        FileErase      (TempPath + PKTName);
        AddToFLOQueue  (FLOName, BundleName);
      End;
    End;

    FindNext (DirInfo);
  End;

  FindClose (DirInfo);
End;

Procedure EchoExportMessage (Var MBase: RecMessageBase; Var MsgBase: PMsgBaseABS; Var Links: TEchoMailLinks; Var TotalNet, TotalEcho: LongInt);
Var
  PH   : RecPKTHeader;
  MH   : RecPKTMessageHdr;
  DT   : DateTime;
  Temp : Word;

  Procedure WriteMessage (Var OneLink: TEchoMailLinkRec);

    Procedure WriteStr (Str: String);
    Begin
      OneLink.PKTFile.WriteBlock (Str[1], Length(Str));
    End;

  Var
    TempStr1 : String;
    TempStr2 : String;
    TempStr3 : String;
  Begin
    // if msg originated from this echomail address then do not export

    If (OneLink.Node.Address.Zone  = MsgBase^.GetOrigAddr.Zone) and
       (OneLink.Node.Address.Net   = MsgBase^.GetOrigAddr.Net)  and
       (OneLink.Node.Address.Node  = MsgBase^.GetOrigAddr.Node) and
       (OneLink.Node.Address.Point = MsgBase^.GetOrigAddr.Point) Then Exit;

    // if netmail is TO someone on this system do not export

    If MBase.NetType = 3 Then
      If IsValidAKA(MsgBase^.GetDestAddr.Zone, MsgBase^.GetDestAddr.Net, MsgBase^.GetDestAddr.Node, MsgBase^.GetDestAddr.Point) Then
        Exit;

    Log (3, '+', '      Export #' + strI2S(MsgBase^.GetMsgNum) + ' to ' + Addr2Str(OneLink.Node.Address));

    GetDate (DT.Year, DT.Month, DT.Day, Temp);
    GetTime (DT.Hour, DT.Min,   DT.Sec, Temp);

    If MBase.NetType = 3 Then Begin
      TempStr3 := GetFTNOutPath(OneLink.Node);

      DirCreate (TempStr3);

      TempStr1 := TempStr3 + GetFTNFlowName(OneLink.Node.Address);
      TempStr2 := TempStr3 + GetFTNFlowName(OneLink.Node.Address);

      Case OneLink.Node.MailType of
        1 : Begin
              TempStr1 := TempStr1 + '.cut';
              TempStr2 := TempStr2 + '.clo';
            End;
        2 : Begin
              TempStr1 := TempStr1 + '.dut';
              TempStr2 := TempStr2 + '.dlo';
            End;
        3 : Begin
              TempStr1 := TempStr1 + '.hut';
              TempStr2 := TempStr2 + '.hlo';
            End;
      Else
        TempStr1 := TempStr1 + '.out';
        TempStr2 := TempStr2 + '.flo';
      End;

      Inc (TotalNet);
    End Else Begin
      TempStr1 := TempPath + OneLink.PKTBase + '.' + strI2S(OneLink.Node.Index);

      Inc (TotalEcho);
    End;

    If Not Assigned(OneLink.PKTFile) Then Begin
      OneLink.PKTFile := TFileBuffer.Create(16 * 1024);

      OneLink.PKTFile.OpenStream(TempStr1, 1, fmOpenCreate, fmRWDN);

      FillChar (PH, SizeOf(PH), 0);

      PH.OrigZone  := MsgBase^.GetOrigAddr.Zone;
      PH.OrigNet   := MsgBase^.GetOrigAddr.Net;
      PH.OrigNode  := MsgBase^.GetOrigAddr.Node;
      PH.OrigPoint := MsgBase^.GetOrigAddr.Point;
      PH.DestZone  := OneLink.Node.Address.Zone;
      PH.DestNet   := OneLink.Node.Address.Net;
      PH.DestNode  := OneLink.Node.Address.Node;
      PH.DestPoint := OneLink.Node.Address.Point;
      PH.Year      := DT.Year;
      PH.Month     := DT.Month;
      PH.Day       := DT.Day;
      PH.Hour      := DT.Hour;
      PH.Minute    := DT.Min;
      PH.Second    := DT.Sec;
      PH.PKTType   := 2;
      PH.ProdCode  := 254;

      // Map current V2 values to V2+ values

      PH.ProdCode2 := PH.ProdCode;
      PH.OrigZone2 := PH.OrigZone;
      PH.DestZone2 := PH.DestZone;
      PH.Compat    := 1;
      PH.CompatVal := 256;

      //BlockWrite (F, PH, SizeOf(PH));
      OneLink.PKTFile.WriteBlock (PH, SizeOf(PH));
    End;

    FillChar (MH, SizeOf(MH), 0);

    MH.MsgType := 2;

    If MBase.NetType = 3 Then Begin
      MH.DestNode := MsgBase^.GetDestAddr.Node;
      MH.DestNet  := MsgBase^.GetDestAddr.Net;
    End Else Begin
      MH.DestNode := OneLink.Node.Address.Node;
      MH.DestNet  := OneLink.Node.Address.Net;
    End;

    MH.OrigNode := MsgBase^.GetOrigAddr.Node;
    MH.OrigNet  := MsgBase^.GetOrigAddr.Net;

    TempStr1 := FormatDate(DT, 'DD NNN YY  HH:II:SS') + #0;
    Move (TempStr1[1], MH.DateTime[0], 20);

    If MsgBase^.IsLocal    Then MH.Attribute := MH.Attribute OR pktLocal;
    If MsgBase^.IsCrash    Then MH.Attribute := MH.Attribute OR pktCrash;
    If MsgBase^.IsKillSent Then MH.Attribute := MH.Attribute OR pktKillSent;
    If MsgBase^.IsRcvd     Then MH.Attribute := MH.Attribute OR pktReceived;
    If MsgBase^.IsPriv     Then MH.Attribute := MH.Attribute OR pktPrivate;

    //BlockWrite (F, MH, SizeOf(MH));
    OneLink.PKTFile.WriteBlock (MH, SizeOf(MH));

    WriteStr (MsgBase^.GetTo + #0 + MsgBase^.GetFrom + #0 + MsgBase^.GetSubj + #0);
//    WriteStr (MsgBase^.GetTo   + #0);
//    WriteStr (MsgBase^.GetFrom + #0);
//    WriteStr (MsgBase^.GetSubj + #0);

    If MBase.NetType <> 3 Then
      WriteStr ('AREA:' + MBase.EchoTag + #13);

    If MBase.NetType = 3 Then
      WriteStr (#1 + 'INTL ' + Addr2Str(MsgBase^.GetDestAddr) + ' ' + Addr2Str(MsgBase^.GetOrigAddr) + #13);

    WriteStr (#1 + 'TID: ' + mysSoftwareID + ' ' + mysVersion + #13);

    MsgBase^.MsgTxtStartUp;

    While Not MsgBase^.EOM Do
      WriteStr (MsgBase^.GetString(79) + #13);

    If MBase.NetType <> 3 Then Begin
      // SEEN-BY needs to include yourself and ANYTHING it is sent to (downlinks)
      // so we need to cycle through nodes for this mbase and add ALL of them

      TempStr1 := 'SEEN-BY: ' + strI2S(MsgBase^.GetOrigAddr.Net) + '/' + strI2S(MsgBase^.GetOrigAddr.Node) + ' ';

      If MsgBase^.GetOrigAddr.Net <> OneLink.Node.Address.Net Then
        TempStr1 := TempStr1 + strI2S(OneLink.Node.Address.Net) + '/';

      TempStr1 := TempStr1 + strI2S(OneLink.Node.Address.Node);

//      WriteStr (TempStr1 + #13);
//      WriteStr (#1 + 'PATH: ' + strI2S(MsgBase^.GetOrigAddr.Net) + '/' + strI2S(MsgBase^.GetOrigAddr.Node) + #13);
      WriteStr (TempStr1 + #13 + #1 + 'PATH: ' + strI2S(MsgBase^.GetOrigAddr.Net) + '/' + strI2S(MsgBase^.GetOrigAddr.Node) + #13);
    End;

    //WriteStr (#0#0#0);
    //F.Free;
    WriteStr(#0);
    //Close (F);
  End;

Var
  ExportFile  : File of RecEchoMailExport;
  ExportIndex : RecEchoMailExport;
  Node        : RecEchoMailNode;
  Count       : LongInt;
Begin
  If MBase.NetType = 3 Then Begin
    If GetNodeByRoute(MsgBase^.GetDestAddr, Node) Then
      For Count := 1 to Length(Links) Do
        If Links[Count - 1].Node.Index = Node.Index Then
          WriteMessage(Links[Count - 1]);
    Exit;
  End;

  Assign (ExportFile, MBase.Path + MBase.FileName + '.lnk');

  If Not ioReset(ExportFile, SizeOf(RecEchoMailExport), fmRWDN) Then Exit;

  While Not Eof(ExportFile) Do Begin
    Read (ExportFile, ExportIndex);

    For Count := 1 to Length(Links) Do
      If Links[Count - 1].Node.Index = ExportIndex Then Begin
        WriteMessage(Links[Count - 1]);

        Break;
      End;
  End;

  Close (ExportFile);
End;

Procedure uEchoExport;
Var
  TotalEcho : LongInt;
  TotalNet  : LongInt;
  TotalBase : LongInt;
  MBaseFile : File of RecMessageBase;
  MBase     : RecMessageBase;
  MsgBase   : PMsgBaseABS;
  DownLinks : TEchoMailLinks;
  Count     : LongInt;
  TempStr   : String[2];
Begin
  TotalEcho := 0;
  TotalNet  := 0;

  ProcessName   ('Exporting EchoMail', True);
  ProcessResult (rWORKING, False);

  DirClean (TempPath, '');

  If Not DirExists(bbsCfg.OutboundPath) Then Begin
    ProcessStatus ('Outbound directory does not exist', True);
    ProcessResult (rFATAL, True);

    Exit;
  End;

  ReadEchoMailLinks(DownLinks, GetFTNPKTName);

  Assign (MBaseFile, bbsCfg.DataPath + 'mbases.dat');

  If ioReset(MBaseFile, SizeOf(RecMessageBase), fmRWDN) Then Begin
    While Not Eof(MBaseFile) Do Begin
      Read (MBaseFile, MBase);

      BarOne.Update (FilePos(MBaseFile), FileSize(MBaseFile));

      If MBase.NetType = 0 Then Continue;

      If (MBase.EchoTag = '') and (MBase.QwkNetID = 0) Then Begin
        Log (1, '!', '  WARNING: No TAG for ' + strStripPipe(MBase.Name));

        Continue;
      End;

      Console.WriteXYPipe (33, Console.CursorY, 7, 31, strStripPipe(MBase.Name));

      If Not MessageBaseOpen(MsgBase, MBase) Then Continue;

      TotalBase := 0;

      // use a lastread for export
      MsgBase^.SeekFirst(1);

      While MsgBase^.SeekFound Do Begin
        MsgBase^.MsgStartUp;

        If MsgBase^.IsLocal And Not MsgBase^.IsSent Then Begin
          Inc (TotalBase);

          EchoExportMessage (MBase, MsgBase, Downlinks, TotalNet, TotalEcho);

          MsgBase^.SetSent(True);
          MsgBase^.ReWriteHdr;
        End;

        MsgBase^.SeekNext;
      End;

      MsgBase^.CloseMsgBase;

      Dispose (MsgBase, Done);

      If TotalBase > 0 Then
        Log (2, '-', '  ' + strI2S(TotalBase) + ' msgs from ' + strStripPipe(MBase.Name));
    End;

    Close (MBaseFile);
  End;

  For Count := 1 to Length(DownLinks) Do
    If Assigned(Downlinks[Count - 1].PKTFile) Then Begin
      TempStr := #0#0;

      Downlinks[Count - 1].PKTFile.WriteBlock(TempStr[1], 2);
      Downlinks[Count - 1].PKTFile.Free;
    End;

  EchoBundleMessages;

  ProcessStatus ('|15' + strI2S(TotalEcho) + ' |07echo |15' + strI2S(TotalNet) + ' |07net', True);
  ProcessResult (rDONE, True);

  FileErase (bbsCfg.SemaPath + fn_SemFileEchoOut);
End;

End.
