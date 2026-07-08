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
Unit MUTIL_ImportMsgBase;

{$I M_OPS.PAS}

Interface

Procedure uImportMessageBases;

Implementation

Uses
  DOS,
  m_FileIO,
  m_Strings,
  mUtil_Common,
  mUtil_Status,
  BBS_Records,
  BBS_DataBase;

// Create message bases from JAM/Squish data files found in DirPath.  When
// Recurse is set (A40.1 search_subdir), also descend into subdirectories off
// the message base directory, creating bases with their real subdir path.
Procedure ImportFromDir (DirPath: String; Recurse: Boolean; Var CreatedBases: LongInt);
Var
  MBase    : RecMessageBase;
  Info     : SearchRec;
  BaseName : String;
  BaseExt  : String;
  Count    : Byte;
Begin
  FindFirst (DirPath + '*', AnyFile, Info);

  While DosError = 0 Do Begin
    BaseName := JustFileName(Info.Name);
    BaseExt  := strUpper(JustFileExt(Info.Name));

    If ((BaseExt = 'JHR') or (BaseExt = 'SQD')) And (BaseName <> '') And Not IsDupeMBase(BaseName) Then Begin
      ProcessStatus (BaseName, False);

      FillChar (MBase, SizeOf(MBase), #0);
      Inc      (CreatedBases);

      MBase.Index     := GenerateMBaseIndex;
      MBase.Name      := BaseName;
      MBase.QWKName   := BaseName;
      MBase.NewsName  := strReplace(BaseName, ' ', '.');
      MBase.EchoTag   := BaseName;
      MBase.FileName  := BaseName;
      MBase.Path      := DirPath;
      MBase.NetType   := INI.ReadInteger(Header_IMPORTMB, 'net_type', 0);
      MBase.ColQuote  := bbsCfg.ColorQuote;
      MBase.ColText   := bbsCfg.ColorText;
      MBase.ColTear   := bbsCfg.ColorTear;
      MBase.ColOrigin := bbsCfg.ColorOrigin;
      MBase.ColKludge := bbsCfg.ColorKludge;
      MBase.Origin    := bbsCfg.Origin;
      MBase.BaseType  := Ord(BaseExt = 'SQD');
      MBase.ListACS   := INI.ReadString(Header_IMPORTMB, 'acs_list', '');
      MBase.ReadACS   := INI.ReadString(Header_IMPORTMB, 'acs_read', '');
      MBase.PostACS   := INI.ReadString(Header_IMPORTMB, 'acs_post', '');
      MBase.NewsACS   := INI.ReadString(Header_IMPORTMB, 'acs_news', '');
      MBase.SysopACS  := INI.ReadString(Header_IMPORTMB, 'acs_sysop', 's255');
      MBase.Header    := INI.ReadString(Header_IMPORTMB, 'header', 'msghead');
      MBase.RTemplate := INI.ReadString(Header_IMPORTMB, 'read_template', 'ansimrd');
      MBase.ITemplate := INI.ReadString(Header_IMPORTMB, 'index_template', 'ansimlst');
      MBase.MaxMsgs   := INI.ReadInteger(Header_IMPORTMB, 'max_msgs', 500);
      MBase.MaxAge    := INI.ReadInteger(Header_IMPORTMB, 'max_msgs_age', 365);
      MBase.DefNScan  := INI.ReadInteger(Header_IMPORTMB, 'new_scan', 1);
      MBase.DefQScan  := INI.ReadInteger(Header_IMPORTMB, 'qwk_scan', 1);
      MBase.NetAddr   := 1;

      MBase.FileName := strReplace(MBase.FileName, '/', '_');
      MBase.FileName := strReplace(MBase.FileName, '\', '_');

      For Count := 1 to 30 Do
        If Addr2Str(bbsCfg.NetAddress[Count]) = INI.ReadString(Header_IMPORTNA, 'netaddress', '') Then Begin
          MBase.NetAddr := Count;

          Break;
        End;

      If INI.ReadString(Header_IMPORTMB, 'use_autosig', '1') = '1' Then
        MBase.Flags := MBase.Flags OR MBAutoSigs;

      If INI.ReadString(Header_IMPORTMB, 'use_realname', '0') = '1' Then
        MBase.Flags := MBase.Flags OR MBRealNames;

      If INI.ReadString(Header_IMPORTMB, 'kill_kludge', '1') = '1' Then
        MBase.Flags := MBase.Flags OR MBKillKludge;

      If INI.ReadString(Header_IMPORTMB, 'private_base', '0') = '1' Then
        MBase.Flags := MBase.Flags OR MBPrivate;

      AddMessageBase(MBase);
    End;

    FindNext(Info);
  End;

  FindClose(Info);

  If Recurse Then Begin
    FindFirst (DirPath + '*', Directory, Info);

    While DosError = 0 Do Begin
      If (Info.Attr and Directory <> 0) and (Info.Name <> '.') and (Info.Name <> '..') Then
        ImportFromDir (DirPath + Info.Name + PathChar, True, CreatedBases);

      FindNext(Info);
    End;

    FindClose(Info);
  End;
End;

Procedure uImportMessageBases;
Var
  CreatedBases : LongInt = 0;
  Recurse      : Boolean;
Begin
  ProcessName   ('Import Message Bases', True);
  ProcessResult (rWORKING, False);

  Recurse := INI.ReadBoolean(Header_IMPORTMB, 'search_subdir', False);

  ImportFromDir (bbsCfg.MsgsPath, Recurse, CreatedBases);

  ProcessStatus ('Created |15' + strI2S(CreatedBases) + ' |07base(s)', True);
  ProcessResult (rDONE, True);
End;

End.
