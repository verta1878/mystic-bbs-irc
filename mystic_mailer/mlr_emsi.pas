// ====================================================================
// mystic_mailer : sample FidoNet mailer front-end for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on/sample for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// mlr_emsi - the EMSI (Electronic Mail Standard Identification) handshake
// used by classic dialup FidoNet mailers (FrontDoor / InterMail / T-Mail).
// After the modem connects, mailers announce themselves with EMSI_INQ,
// exchange EMSI_DAT (address, system, password, capabilities) protected by
// a CRC16, and confirm with EMSI_ACK / retry with EMSI_NAK.
//
// SCOPE: this implements the HANDSHAKE faithfully (the part that is truly
// "EMSI" and that lets the front-end identify a node + settle a session).
// The mail-bundle transfer that follows (classically Zmodem) is left as a
// documented stub - the existing tosser consumes the packets once they land.
//
// Reference: FSC-0056 (EMSI).  Transport-agnostic: it talks to any object
// exposing ReadAvail:String and WriteStr(S):Integer, so it runs over the
// serial layer here and could run over a socket unchanged.
// ====================================================================

Unit mlr_Emsi;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Interface

Uses
  mdm_Serial;

Const
  // EMSI packet markers (sent as literal text on the wire).
  EMSI_INQ = '**EMSI_INQC816';    // "are you an EMSI mailer?"  (INQ + its CRC)
  EMSI_REQ = '**EMSI_REQA77E';    // "please send your EMSI_DAT"
  EMSI_ACK = '**EMSI_ACKA490';    // "got your EMSI_DAT ok"
  EMSI_NAK = '**EMSI_NAKEEC3';    // "bad EMSI_DAT, resend"
  EMSI_CLR = '**EMSI_CLReB1E';    // "handshake complete, clear to transfer"
  EMSI_HBT = '**EMSI_HBTeaEE';    // heartbeat (keep-alive during long ops)

  EMSI_DAT_PFX = '**EMSI_DAT';    // EMSI_DAT prefix; followed by len + body + CRC

Type
  // What we learned about the remote node from its EMSI_DAT.
  TEmsiSession = Record
    Valid     : Boolean;
    Addresses : String;    // space-separated FTN addresses (the {...} list)
    SysName   : String;
    Sysop     : String;
    Location  : String;
    Password  : String;
    Protocols : String;    // e.g. {ZAP,ZMO,DZA}
    RawDat    : String;    // the full received EMSI_DAT body, for logging
  End;

  TEmsi = Class
  Private
    FSer     : TModemSerial;
    FTimeout : LongInt;
    Function  ReadLineTO (TimeoutMS: LongInt): String;
  Public
    Constructor Create (ASer: TModemSerial);

    // Detector helper: does this pending text look like an EMSI mailer?
    // (front-end calls this on the first bytes after CONNECT.)
    Class Function LooksLikeEmsi (Const Sniff: String): Boolean;

    // Send our EMSI_INQ a few times (caller/answer both may INQ).
    Procedure SendInq;

    // Send our EMSI_DAT built from our own node details.
    Procedure SendDat (Const MyAddr, MySys, MySysop, MyLoc, MyPassword: String);

    // Wait for and parse the remote's EMSI_DAT.  Verifies CRC; on success
    // fills Session and sends EMSI_ACK, else sends EMSI_NAK.
    Function  RecvDat (Var Session: TEmsiSession; TimeoutMS: LongInt = 20000): Boolean;

    Property Serial : TModemSerial Read FSer;
  End;

// CRC16 (CCITT, poly $1021) over a string - EMSI's packet checksum.
Function EmsiCrc16 (Const S: String): Word;

Implementation

Uses
  SysUtils;

// CRC16-CCITT (poly $1021, init $FFFF - the "CCITT-FALSE" variant; the
// canonical check value CRC("123456789") = $29B1).  EMSI packet checksum.
Function EmsiCrc16 (Const S: String): Word;
Var
  I, J : LongInt;
  CRC  : Word;
Begin
  CRC := $FFFF;
  For I := 1 to Length(S) Do Begin
    CRC := CRC xor (Word(Ord(S[I])) shl 8);
    For J := 1 to 8 Do
      If (CRC and $8000) <> 0 Then
        CRC := (CRC shl 1) xor $1021
      Else
        CRC := CRC shl 1;
  End;
  EmsiCrc16 := CRC;
End;

Constructor TEmsi.Create (ASer: TModemSerial);
Begin
  Inherited Create;
  FSer     := ASer;
  FTimeout := 20000;
End;

Class Function TEmsi.LooksLikeEmsi (Const Sniff: String): Boolean;
Begin
  // Any EMSI packet begins with the '**EMSI' sentinel.
  Result := Pos('**EMSI', UpperCase(Sniff)) > 0;
End;

Function TEmsi.ReadLineTO (TimeoutMS: LongInt): String;
Var
  Elapsed : LongInt;
  Chunk   : String;
  P       : LongInt;
Begin
  Result  := '';
  Elapsed := 0;
  While Elapsed < TimeoutMS Do Begin
    Chunk := FSer.ReadAvail;
    If Chunk <> '' Then Begin
      Result := Result + Chunk;
      // an EMSI packet is CR-terminated
      P := Pos(#13, Result);
      If P > 0 Then Begin
        Result := Copy(Result, 1, P - 1);
        Exit;
      End;
    End;
    Sleep(50);
    Inc(Elapsed, 50);
  End;
End;

Procedure TEmsi.SendInq;
Var
  I : LongInt;
Begin
  For I := 1 to 3 Do Begin
    FSer.WriteStr(EMSI_INQ + #13);
    Sleep(400);
  End;
End;

Procedure TEmsi.SendDat (Const MyAddr, MySys, MySysop, MyLoc, MyPassword: String);
Var
  Body, Frame : String;
  LenHex, CrcHex : String;
Begin
  // EMSI_DAT body: {addresses}{password}{link codes}{compat}{ident}...
  // We build a minimal-but-valid FSC-0056 shaped body.
  Body := '{EMSI}{' + MyAddr + '}{' + MyPassword + '}{8N1}' +
          '{ZMO,ZAP}{' + MySys + ',' + MyLoc + ',' + MySysop + '}' +
          '{Mystic-Mailer-Sample}';

  LenHex := IntToHex(Length(Body), 4);
  Frame  := EMSI_DAT_PFX + LenHex + Body;
  CrcHex := IntToHex(EmsiCrc16(Frame), 4);

  FSer.WriteStr(Frame + CrcHex + #13);
End;

Function TEmsi.RecvDat (Var Session: TEmsiSession; TimeoutMS: LongInt): Boolean;
Var
  Line, Body, CrcRx : String;
  LenVal            : LongInt;
  P                 : LongInt;

  Function Field (Var Src: String): String;
  Var A, B : LongInt;
  Begin
    Result := '';
    A := Pos('{', Src);
    If A = 0 Then Exit;
    B := Pos('}', Src);
    If B <= A Then Exit;
    Result := Copy(Src, A + 1, B - A - 1);
    Delete(Src, 1, B);
  End;

Begin
  Result := False;
  FillChar(Session, SizeOf(Session), 0);

  Line := ReadLineTO(TimeoutMS);

  P := Pos(EMSI_DAT_PFX, Line);
  If P = 0 Then Exit;                         // not an EMSI_DAT

  // strip prefix + 4-hex length
  Delete(Line, 1, P - 1 + Length(EMSI_DAT_PFX));
  If Length(Line) < 4 Then Exit;
  LenVal := StrToIntDef('$' + Copy(Line, 1, 4), 0);
  Delete(Line, 1, 4);

  If Length(Line) < LenVal + 4 Then Exit;     // need body + 4-hex CRC
  Body  := Copy(Line, 1, LenVal);
  CrcRx := Copy(Line, LenVal + 1, 4);

  // verify CRC over prefix+len+body (recompute frame as sent)
  If UpperCase(CrcRx) <>
     UpperCase(IntToHex(EmsiCrc16(EMSI_DAT_PFX + IntToHex(LenVal,4) + Body), 4))
  Then Begin
    FSer.WriteStr(EMSI_NAK + #13);
    Session.RawDat := Body;
    Exit;
  End;

  // parse the {field}{field}... body (order per our SendDat / typical DAT)
  Session.RawDat := Body;
  Field(Body);                                // {EMSI} tag
  Session.Addresses := Field(Body);
  Session.Password  := Field(Body);
  Field(Body);                                // link/compat codes
  Session.Protocols := Field(Body);
  Session.SysName   := Field(Body);           // combined sys,loc,sysop blob
  Session.Valid     := True;

  FSer.WriteStr(EMSI_ACK + #13);
  Result := True;
End;

End.
