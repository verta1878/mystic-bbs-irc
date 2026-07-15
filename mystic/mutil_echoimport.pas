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
Unit MUTIL_EchoImport;

{$I M_OPS.PAS}

Interface

Uses
  m_FileIO,
  BBS_Records;

Type
  TEchoMailLinkRec = Record
    Node    : RecEchoMailNode;
    PKTFile : TFileBuffer;
    PKTBase : String[8];
  End;

  TEchoMailLinks = Array of TEchoMailLinkRec;

Procedure uEchoImport;
Procedure ReadEchoMailLinks (Var Links: TEchoMailLinks; PKTBase: String);

Implementation

Uses
  DOS,
  m_Strings,
  Classes,
  m_DateTime,
  AView,
  BBS_DataBase,
  BBS_MsgBase_ABS,
  BBS_MsgBase_JAM,
  BBS_MsgBase_Squish,
  mUtil_Common,
  mUtil_Status,
  mUtil_EchoCore,
  mUtil_EchoFix,
  mUtil_EchoExport;

Procedure SavePKTMsgToBase (Var MB: PMsgBaseABS; Var PKT: TPKTReader; Netmail, StripSeenBy: Boolean);
Var
  Count : LongInt;
Begin
  MB^.StartNewMsg;

  If NetMail Then
    MB^.SetMailType (mmtNetMail)
  Else
    MB^.SetMailType (mmtEchoMail);

  MB^.SetLocal (False);
  MB^.SetOrig  (PKT.PKTOrig);
  MB^.SetDest  (PKT.PKTDest);

  MB^.SetPriv     ((PKT.MsgHDR.Attribute AND pktPrivate <> 0) OR NetMail);
  MB^.SetCrash    (PKT.MsgHDR.Attribute AND pktCrash    <> 0);
  MB^.SetRcvd     (PKT.MsgHDR.Attribute AND pktReceived <> 0);
  MB^.SetSent     (False);  // force to send to downlinks?
  MB^.SetHold     (PKT.MsgHDR.Attribute AND pktHold     <> 0);
  MB^.SetKillSent (PKT.MsgHDR.Attribute AND pktKillSent <> 0);

  MB^.SetFrom     (PKT.MsgFrom);
  MB^.SetTo       (PKT.MsgTo);
  MB^.SetSubj     (PKT.MsgSubj);
  MB^.SetDate     (PKT.MsgDate);
  MB^.SetTime     (PKT.MsgTime);

  For Count := 1 to PKT.MsgLines Do Begin
    If Copy(PKT.MsgText[Count]^, 1, 9) = 'SEEN-BY: ' Then Begin
      PKT.MsgText[Count]^ := #1 + PKT.MsgText[Count]^;

      If StripSeenBy Then Continue;
    End;

    If (PKT.MsgText[Count]^[1] = #1) Then
      MB^.DoKludgeLn(PKT.MsgText[Count]^)
    Else
      MB^.DoStringLn(PKT.MsgText[Count]^);
  End;

  MB^.WriteMsg;
End;

Procedure ReadEchoMailLinks (Var Links: TEchoMailLinks; PKTBase: String);
Var
  NodeFile : TFileBuffer;
  Node     : RecEchoMailNode;
  Total    : LongInt;
Begin
  Links    := NIL;
  NodeFile := TFileBuffer.Create(8 * 1024);

  If NodeFile.OpenStream(bbsCfg.DataPath + 'echonode.dat', SizeOf(RecEchoMailNode), fmOpen, fmRWDN) Then
    While Not NodeFile.EOF Do Begin
      NodeFile.ReadRecord(Node);

      If Not Node.Active Then
        Continue;

      Total := Length(Links);

      SetLength(Links, Total + 1);

      Links[Total].Node    := Node;
      Links[Total].PKTFile := NIL;
      Links[Total].PKTBase := PKTBase;
    End;

  NodeFile.Free;
End;

Procedure uEchoImport;
Var
  TotalEcho   : LongInt;
  TotalNet    : LongInt;
  TotalDupes  : LongInt;
  TossEcho    : LongInt;
  TossNet     : LongInt;
  DupeIndex   : LongInt;
  DupeMBase   : RecMessageBase;
  CreateBases : Boolean;
  StripSeenBy : Boolean;
  PKT         : TPKTReader;
  Dupes       : TPKTDupe;
  Status      : LongInt;
  ForwardList : Array[1..50] of String[35];
  ForwardSize : Byte = 0;
  TwitList    : Array[1..100] of String[40];
  TwitSize    : Byte = 0;
  DownLinks   : TEchoMailLinks;

  Procedure ImportPacketFile (PktFN: String);
  Var
    MsgBase : PMsgBaseABS;
    CurTag  : String;
    MBase   : RecMessageBase;
    Count   : LongInt;
    Route   : RecEchoMailNode;
    TempStr : String;
    TempI   : LongInt;

    // A43: twit filter - check if a message's From, To, or originating address
    // matches any entry in the twit list.  Returns True if the message should
    // be silently dropped.
    Function IsTwit : Boolean;
    Var T : Byte; AddrStr : String;
    Begin
      Result := False;
      If TwitSize = 0 Then Exit;
      AddrStr := strUpper(Addr2Str(PKT.MsgOrig));
      For T := 1 to TwitSize Do
        If (TwitList[T] = strUpper(PKT.MsgFrom)) or
           (TwitList[T] = strUpper(PKT.MsgTo)) or
           (TwitList[T] = AddrStr) Then Begin
          Result := True;
          Exit;
        End;
    End;

  Begin
    If Not PKT.Open(PktFN) Then Begin
      Log (3, '!', '   ' + JustFile(PktFN) + ' is not valid PKT');

      Exit;
    End;

    // A41: PKT password enforcement.  If the matching echonode has a PKTPass
    // set, the inbound packet must carry the same password or it is rejected.
    For Count := 0 to Length(Downlinks) - 1 Do
      If (Downlinks[Count].Node.Address.Zone = PKT.PKTOrig.Zone) and
         (Downlinks[Count].Node.Address.Net  = PKT.PKTOrig.Net) and
         (Downlinks[Count].Node.Address.Node = PKT.PKTOrig.Node) and
         (Downlinks[Count].Node.PKTPass <> '') Then Begin
        TempStr := '';
        For TempI := 1 to 8 Do
          If PKT.PKTHeader.Password[TempI] <> #0 Then
            TempStr := TempStr + PKT.PKTHeader.Password[TempI];
        If strUpper(TempStr) <> strUpper(Downlinks[Count].Node.PKTPass) Then Begin
          Log (2, '!', '   ' + JustFile(PktFN) + ' PKT password mismatch from ' +
               strI2S(PKT.PKTOrig.Zone) + ':' + strI2S(PKT.PKTOrig.Net) + '/' +
               strI2S(PKT.PKTOrig.Node) + '; rejecting');
          PKT.Close;
          Exit;
        End;
        Break;
      End;

    If Not IsValidAKA(PKT.PKTDest.Zone, PKT.PKTDest.Net, PKT.PKTDest.Node, 0) Then Begin
      Log (3, '!', '   ' + JustFile(PktFN) + ' does not match an AKA');

      PKT.Close;

      Exit;
    End;

    ProcessStatus ('Importing ' + JustFile(PktFN), False);

    BarOne.Reset;

    CurTag  := '';
    MsgBase := NIL;
    Status  := 20;

    While PKT.GetMessage Do Begin
      If Status MOD 20 = 0 Then
        BarOne.Update (PKT.MsgFile.FilePosRaw, PKT.MsgFile.FileSizeRaw);

      Inc (Status);

      If PKT.MsgArea = 'NETMAIL' Then Begin

        If Not ProcessedByAreaFix(PKT) Then
        If Not ProcessedByFileFix(PKT) Then
          If IsValidAKA(PKT.MsgDest.Zone, PKT.MsgDest.Net, PKT.MsgDest.Node, PKT.MsgDest.Point) Then Begin

            If GetMBaseByNetZone(PKT.MsgDest.Zone, MBase) Then Begin
              For Count := 1 to ForwardSize Do
                If strUpper(strStripB(strWordGet(1, ForwardList[Count], ';'), ' ')) = strUpper(PKT.MsgTo) Then
                  PKT.MsgTo := strStripB(strWordGet(2, ForwardList[Count], ';'), ' ');

              CurTag := '';

              If MsgBase <> NIL Then Begin
                MsgBase^.CloseMsgBase;

                Dispose (MsgBase, Done);

                MsgBase := NIL;
              End;

              MessageBaseOpen  (MsgBase, MBase);

              // A43: twit filter applies to netmail too
              If IsTwit Then Begin
                Log (3, '!', '      Twit filtered netmail: ' + PKT.MsgFrom);
                Continue;
              End;

              SavePKTMsgToBase (MsgBase, PKT, True, StripSeenBy);

              Log (2, '+', '      Netmail from ' + PKT.MsgFrom + ' to ' + PKT.MsgTo);

              Inc (TotalNet);
            End;
          End Else
          If GetNodeByRoute(PKT.MsgDest, Route) Then Begin
            // can/should we allow routing to multiple destinations for
            // netmail?

            If Route.Active Then Begin
              // generate outbound packet name etc etc
              // add Via to the bottom?
              // write OUT file
            End;
            // log here if not active but should have been routed?

            Log (2, '+', '      Re-routing netmail sent from ' + Addr2Str(PKT.MsgOrig) + ' to ' + Addr2Str(Route.Address));
          End Else
            Log (2, '!', '   No netmail route/destination: ' + PKT.MsgTo + '@' + Addr2Str(PKT.MsgDest));
            // option to toss to badmsg?  how do we handle orphans?
      End Else Begin
        // Echomail msg

        If Dupes.IsDuplicate(PKT.MsgCRC) Then Begin
          Log (3, '!', '      Duplicate message found in ' + PKT.MsgArea);

          If DupeIndex <> -1 Then Begin
            If (MsgBase <> NIL) and (CurTag <> '-DUPEMSG-') Then Begin
              MsgBase^.CloseMsgBase;

              Dispose (MsgBase, Done);

              MsgBase := NIL;
              CurTag  := '-DUPEMSG-';
            End;

            If MsgBase = NIL Then
              MessageBaseOpen (MsgBase, DupeMBase);

            SavePKTMsgToBase (MsgBase, PKT, False, StripSeenBy);
          End;

          Inc (TotalDupes);
        End Else Begin
          If CurTag <> PKT.MsgArea Then Begin
            If Not GetMBaseByTag(PKT.MsgArea, MBase) Then Begin
              Log (2, '!', '   Area ' + PKT.MsgArea + ' does not exist');

              If Not CreateBases Then Continue;

              If FileExist(bbsCfg.MsgsPath + PKT.MsgArea + '.sqd') or
                 FileExist(bbsCfg.MsgsPath + PKT.MsgArea + '.jhr') Then Begin
                   Log (2, '!', '   Skip create base; datafiles already exist: ' + PKT.MsgArea);

                   Continue;
              End;

              FillChar (MBase, SizeOf(MBase), #0);

              MBase.Index     := GenerateMBaseIndex;
              MBase.Name      := PKT.MsgArea;
              MBase.QWKName   := PKT.MsgArea;
              MBase.NewsName  := PKT.MsgArea;
              MBase.FileName  := PKT.MsgArea;
              MBase.EchoTag   := PKT.MsgArea;
              MBase.Path      := bbsCfg.MsgsPath;
              MBase.NetType   := 1;
              MBase.ColQuote  := bbsCfg.ColorQuote;
              MBase.ColText   := bbsCfg.ColorText;
              MBase.ColTear   := bbsCfg.ColorTear;
              MBase.ColOrigin := bbsCfg.ColorOrigin;
              MBase.ColKludge := bbsCfg.ColorKludge;
              MBase.Origin    := bbsCfg.Origin;
              MBase.BaseType  := INI.ReadInteger(Header_ECHOIMPORT, 'base_type', 0);
              MBase.Header    := INI.ReadString (Header_ECHOIMPORT, 'header', 'msghead');
              MBase.RTemplate := INI.ReadString (Header_ECHOIMPORT, 'read_template', 'ansimrd');
              MBase.ITemplate := INI.ReadString (Header_ECHOIMPORT, 'index_template', 'ansimlst');
              MBase.MaxMsgs   := INI.ReadInteger(Header_ECHOIMPORT, 'max_msgs', 500);
              MBase.MaxAge    := INI.ReadInteger(Header_ECHOIMPORT, 'max_msgs_age', 365);
              MBase.DefNScan  := INI.ReadInteger(Header_ECHOIMPORT, 'new_scan', 1);
              MBase.DefQScan  := INI.ReadInteger(Header_ECHOIMPORT, 'qwk_scan', 1);
              MBase.NetAddr   := 1;

              For Count := 1 to 30 Do
                If bbsCfg.NetAddress[Count].Zone = PKT.PKTHeader.DestZone Then Begin
                  MBase.NetAddr := Count;
                  Break;
                End;

              MBase.FileName := strReplace(MBase.FileName, '/', '_');
              MBase.FileName := strReplace(MBase.FileName, '\', '_');

              // ADDRESS SPECIFIC CONFIGURATION

              TempStr := Addr2Str(bbsCfg.NetAddress[MBase.NetAddr]) + '_';

              MBase.ListACS   := INI.ReadString(Header_ECHOIMPORT, TempStr + 'acs_list', INI.ReadString(Header_ECHOIMPORT, 'acs_list', ''));
              MBase.ReadACS   := INI.ReadString(Header_ECHOIMPORT, TempStr + 'acs_read', INI.ReadString(Header_ECHOIMPORT, 'acs_read', ''));
              MBase.PostACS   := INI.ReadString(Header_ECHOIMPORT, TempStr + 'acs_post', INI.ReadString(Header_ECHOIMPORT, 'acs_post', ''));
              MBase.NewsACS   := INI.ReadString(Header_ECHOIMPORT, TempStr + 'acs_news', INI.ReadString(Header_ECHOIMPORT, 'acs_news', ''));
              MBase.SysopACS  := INI.ReadString(Header_ECHOIMPORT, TempStr + 'acs_sysop', INI.ReadString(Header_ECHOIMPORT, 'acs_sysop', 's255'));

              If INI.ReadString(Header_ECHOIMPORT, TempStr + 'use_realname', INI.ReadString(Header_ECHOIMPORT, 'use_realname', '0')) = '1' Then
                MBase.Flags := MBase.Flags OR MBRealNames;

              /////

              If INI.ReadString(Header_ECHOIMPORT, 'lowercase_filename', '1') = '1' Then
                MBase.FileName := strLower(MBase.FileName);

              If INI.ReadString(Header_ECHOIMPORT, 'use_autosig', '1') = '1' Then
                MBase.Flags := MBase.Flags OR MBAutoSigs;

              If INI.ReadString(Header_ECHOIMPORT, 'kill_kludge', '1') = '1' Then
                MBase.Flags := MBase.Flags OR MBKillKludge;

              AddMessageBase(MBase);

              // Try to figure out who the uplink is and autolink

              If GetNodeByAddress(Addr2Str(PKT.PKTOrig), Route) Then
                AddExportByBase (MBase, Route.Index);
            End;

            If MsgBase <> NIL Then Begin
              MsgBase^.CloseMsgBase;

              Dispose (MsgBase, Done);

              MsgBase := NIL;
            End;

            MessageBaseOpen(MsgBase, MBase);

            CurTag := PKT.MsgArea;
          End;

          // A43: twit filter - silently drop messages from/to twit-listed names or addresses
          If IsTwit Then Begin
            Log (3, '!', '      Twit filtered: ' + PKT.MsgFrom + ' in ' + PKT.MsgArea);
            Continue;
          End;

          Log (3, '+', '      Import #' + strI2S(MsgBase^.GetHighMsgNum + 1) + ' to ' + strStripPipe(MBase.Name));

          SavePKTMsgToBase (MsgBase, PKT, False, StripSeenBy);

          Dupes.AddDuplicate(PKT.MsgCRC);

          EchoExportMessage(MBase, MsgBase, Downlinks, TossNet, TossEcho);

          Inc (TotalEcho);
        End;
      End;
    End;

    If MsgBase <> NIL Then Begin
      MsgBase^.CloseMsgBase;

      Dispose (MsgBase, Done);

      MsgBase := NIL;
    End;

    PKT.Close;

    FileErase (PktFN);

    BarOne.Update (1, 1);
  End;

  Procedure ImportPacketBundle (PktBundle: String);
  Var
    DirInfo    : SearchRec;
    ArcType    : String[4] = '';
    Count      : LongInt;
    Count2     : LongInt;
    BundleList : TStringList;
  Begin
    For Count := 1 to Length(Downlinks) Do Begin
      For Count2 := 1 to 30 Do Begin
        If strUpper(JustFileName(PktBundle)) = strUpper(GetFTNArchiveName(Downlinks[Count - 1].Node.Address, bbsCfg.NetAddress[Count2])) Then Begin
          ArcType := Downlinks[Count - 1].Node.ArcType;

          Break;
        End;
      End;

      If ArcType <> '' Then Break;
    End;

    If ArcType = '' Then Begin
      Case GetArchiveType(bbsCfg.InboundPath + PktBundle) of
        'A' : ArcType := 'ARJ';
        'R' : ArcType := 'RAR';
        'Z' : ArcType := 'ZIP';
        'L' : ArcType := 'LZH';
      Else
        Log (2, '!', '   Cannot find arctype for ' + PktBundle + '; skipping');

        Exit;
      End;
    End;

    ProcessStatus ('Extracting ' + PktBundle, False);

    ExecuteArchive (TempPath, bbsCfg.InboundPath + PktBundle, ArcType, '*', 2);

    BundleList := TStringList.Create;

    FindFirst (TempPath + '*', AnyFile, DirInfo);

    While DosError = 0 Do Begin
      If DirInfo.Attr And Directory = 0 Then Begin
        If strUpper(JustFileExt(DirInfo.Name)) = 'PKT' Then
          BundleList.Add(FormatDate(DateDos2DT(DirInfo.Time), 'YYYYMMDDHHIISS') + ' ' + DirInfo.Name);
      End;

      FindNext (DirInfo);
    End;

    FindClose (DirInfo);

    BundleList.Sort;

    If BundleList.Count = 0 Then
      Log (2, '!', '   Unable to extract bundle; skipping')
    Else Begin
      For Count := 1 to BundleList.Count Do
        ImportPacketFile (TempPath + strWordGet(2, BundleList.Strings[Count - 1], ' '));

      FileErase (bbsCfg.InboundPath + PktBundle);
    End;

    BundleList.Free;
  End;

Var
  DirInfo  : SearchRec;
  Count    : LongInt;
  FileExt  : String;
  PktList  : TStringList;
  FileName : String;
Begin
  TotalEcho  := 0;
  TotalNet   := 0;
  TotalDupes := 0;
  TossEcho   := 0;
  TossNet    := 0;

  ProcessName   ('Importing EchoMail', True);
  ProcessResult (rWORKING, False);

  DirClean (TempPath, '');

  If Not DirExists(bbsCfg.InboundPath) Then Begin
    ProcessStatus ('Inbound directory does not exist', True);
    ProcessResult (rFATAL, True);

    Exit;
  End;

  // read INI values

  CreateBases := INI.ReadBoolean(Header_ECHOIMPORT, 'auto_create', False);
  StripSeenBy := INI.ReadBoolean(Header_ECHOIMPORT, 'strip_seenby', False);
  DupeIndex   := INI.ReadInteger(Header_ECHOIMPORT, 'dupe_msg_index', -1);
  Count       := INI.ReadInteger(Header_ECHOIMPORT, 'dupe_db_size', 32000);

  // Read in forward list from INI

  FillChar (ForwardList, SizeOf(ForwardList), #0);

  Ini.SetSequential(True);

  Repeat
    FileExt := INI.ReadString(Header_ECHOIMPORT, 'forward', '');

    If FileExt = '' Then Break;

    Inc (ForwardSize);

    ForwardList[ForwardSize] := strStripB(FileExt, ' ');
  Until ForwardSize = 50;

  // A43: read twit filter list from INI (up to 100 names or addresses)
  FillChar (TwitList, SizeOf(TwitList), #0);

  Ini.SetSequential(True);

  Repeat
    FileExt := INI.ReadString(Header_ECHOIMPORT, 'twit', '');

    If FileExt = '' Then Break;

    Inc (TwitSize);

    TwitList[TwitSize] := strUpper(strStripB(FileExt, ' '));
  Until TwitSize = 100;

  INI.SetSequential(False);

  Dupes := TPKTDupe.Create(Count);
  PKT   := TPKTReader.Create;

  If DupeIndex <> -1 Then
    If Not GetMBaseByIndex (DupeIndex, DupeMBase) Then
      DupeIndex := -1;

  PktList := TStringList.Create;

  FindFirst (bbsCfg.InboundPath + '*', AnyFile, DirInfo);

  While DosError = 0 Do Begin
    If DirInfo.Attr And Directory = 0 Then
      PktList.Add(FormatDate(DateDos2DT(DirInfo.Time), 'YYYYMMDDHHIISS') + ' ' + DirInfo.Name);

    FindNext (DirInfo);
  End;

  FindClose (DirInfo);

  ReadEchoMailLinks(DownLinks, GetFTNPKTName);

  PktList.Sort;

  For Count := 1 to PktList.Count Do Begin
    FileName := strWordGet(2, PktList.Strings[Count - 1], ' ');
    FileExt  := Copy(strUpper(JustFileExt(FileName)), 1, 2);

    If FileExt = 'PK' Then
      ImportPacketFile(bbsCfg.InboundPath + FileName)
    Else
    If (FileExt = 'SU') or
       (FileExt = 'MO') or
       (FileExt = 'TU') or
       (FileExt = 'WE') or
       (FileExt = 'TH') or
       (FileExt = 'FR') or
       (FileExt = 'SA') Then
         ImportPacketBundle(FileName)
    Else
      Log (2, '!', '   Unknown inbound file ' + FileName);
  End;

  For Count := 1 to Length(DownLinks) Do
    If Assigned(Downlinks[Count - 1].PKTFile) Then Begin
      FileName := #0#0;

      Downlinks[Count - 1].PKTFile.WriteBlock(FileName[1], 2);
      Downlinks[Count - 1].PKTFile.Free;
    End;

  PKT.Free;
  Dupes.Free;
  PktList.Free;

  If TossEcho + TossNet > 0 Then Begin
    ProcessStatus ('Bundling Messages', False);

    EchoBundleMessages;
  End;

  ProcessStatus ('|15' + strI2S(TotalEcho) + ' |07echo |15' + strI2S(TotalNet) + ' |07net |15' + strI2S(TotalDupes) + ' |07dupe |15' + strI2S(TossEcho + TossNet) + ' |07toss', True);
  ProcessResult (rDONE, True);

  FileErase (bbsCfg.SemaPath + fn_SemFileEchoIn);
End;

End.
