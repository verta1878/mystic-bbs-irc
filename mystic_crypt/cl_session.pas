// ====================================================================
// mystic_crypt : optional cryptlib (SSH/TLS) example for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on module for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// cl_session - TCryptSession: a thin wrapper that stands up an SSH or TLS
// session over an existing (already-accepted / connected) socket handle using
// cryptlib, then pushes/pops encrypted data.  This is the seam a future MIS
// SSH server (a 7th server type beside telnet) or TLS-wrapped SMTP/POP3 would
// build on.  If cryptlib is not present the wrapper reports Ready=False and the
// caller falls back to plaintext, exactly as stock Mystic does.
// ====================================================================

Unit cl_Session;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Interface

Uses
  SysUtils,
  cl_Bind;

Const
  // cryptlib session type ids (stable public values from cryptlib.h).
  CRYPT_SESSION_SSH        = 1;   // SSH client
  CRYPT_SESSION_SSH_SERVER = 2;   // SSH server
  CRYPT_SESSION_SSL        = 4;   // TLS/SSL client
  CRYPT_SESSION_SSL_SERVER = 5;   // TLS/SSL server

  // A few attribute ids used to attach the network session / keys.
  CRYPT_SESSINFO_NETWORKSOCKET = 6014;
  CRYPT_SESSINFO_PRIVATEKEY    = 6017;
  CRYPT_SESSINFO_ACTIVE        = 6001;

Type
  TCryptRole = (crSSHServer, crSSHClient, crTLSServer, crTLSClient);

  TCryptSession = Class
  Private
    FSession : TCryptHandle;
    FReady   : Boolean;
    FInited  : Boolean;
  Public
    Constructor Create;
    Destructor  Destroy; Override;

    // Load cryptlib and cryptInit().  True if secure sessions are available.
    Function  Available (Const LibName: String = ''): Boolean;

    // Create a session of the given role bound to an OS socket handle.
    // (PrivKey is a cryptlib key handle for server roles; 0 for clients.)
    Function  StartSession (Role: TCryptRole; SocketHandle: LongInt;
                            PrivKey: LongInt = 0): Boolean;

    // Push/pop encrypted data once the session is active.
    Function  Send (Const Data: String): LongInt;
    Function  Recv (Max: LongInt = 4096): String;

    Procedure Stop;

    Property Ready : Boolean Read FReady;
  End;

Implementation

Constructor TCryptSession.Create;
Begin
  Inherited Create;
  FSession := 0;
  FReady   := False;
  FInited  := False;
End;

Destructor TCryptSession.Destroy;
Begin
  Stop;
  If FInited and Assigned(cryptEnd) Then cryptEnd();
  Inherited Destroy;
End;

Function TCryptSession.Available (Const LibName: String): Boolean;
Begin
  Result := False;
  If Not LoadCryptlib(LibName) Then Exit;      // no cl32.dll => secure off
  If cryptInit() <> 0 Then Exit;               // cryptInit returns 0 on success
  FInited := True;
  Result := True;
End;

Function TCryptSession.StartSession (Role: TCryptRole; SocketHandle: LongInt;
                                     PrivKey: LongInt): Boolean;
Var
  SType : LongInt;
Begin
  Result := False;
  FReady := False;
  If Not FInited Then Exit;

  Case Role of
    crSSHServer : SType := CRYPT_SESSION_SSH_SERVER;
    crSSHClient : SType := CRYPT_SESSION_SSH;
    crTLSServer : SType := CRYPT_SESSION_SSL_SERVER;
    crTLSClient : SType := CRYPT_SESSION_SSL;
  Else
    SType := CRYPT_SESSION_SSH_SERVER;
  End;

  // CRYPT_UNUSED user handle is -1 in cryptlib.
  If cryptCreateSession(FSession, -1, SType) <> 0 Then Exit;

  // Attach the OS socket cryptlib should run the secure protocol over.
  If cryptSetAttribute(FSession, CRYPT_SESSINFO_NETWORKSOCKET, SocketHandle) <> 0 Then Begin
    Stop; Exit;
  End;

  // Server roles need a private key / host key.
  If (Role in [crSSHServer, crTLSServer]) and (PrivKey <> 0) Then
    cryptSetAttribute(FSession, CRYPT_SESSINFO_PRIVATEKEY, PrivKey);

  // Activate: performs the handshake.
  If cryptSetAttribute(FSession, CRYPT_SESSINFO_ACTIVE, 1) <> 0 Then Begin
    Stop; Exit;
  End;

  FReady := True;
  Result := True;
End;

Function TCryptSession.Send (Const Data: String): LongInt;
Var
  Copied : LongInt;
  Tmp    : String;
Begin
  Result := 0;
  If (Not FReady) or (Data = '') Then Exit;
  Tmp := Data;
  Copied := 0;
  If cryptPushData(FSession, @Tmp[1], Length(Tmp), Copied) = 0 Then
    Result := Copied;
End;

Function TCryptSession.Recv (Max: LongInt): String;
Var
  Buf    : Array of Char;
  Copied : LongInt;
Begin
  Result := '';
  If Not FReady Then Exit;
  SetLength(Buf, Max);
  Copied := 0;
  If cryptPopData(FSession, @Buf[0], Max, Copied) = 0 Then
    If Copied > 0 Then Begin
      SetLength(Result, Copied);
      Move(Buf[0], Result[1], Copied);
    End;
End;

Procedure TCryptSession.Stop;
Begin
  If (FSession <> 0) and Assigned(cryptDestroySession) Then
    cryptDestroySession(FSession);
  FSession := 0;
  FReady := False;
End;

End.
