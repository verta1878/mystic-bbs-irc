Unit SDL_TTF;

// ====================================================================
// Minimal SDL_ttf header — just enough for mdl/m_sdlcrt.pas to compile.
// At link time the real libSDL_ttf must be present.
// ====================================================================

Interface

Uses
  SDL;

Type
  TTF_Font = Record end;
  pTTF_Font = ^TTF_Font;

Function  TTF_Init : LongInt; cdecl; external 'SDL_ttf';
Procedure TTF_Quit; cdecl; external 'SDL_ttf';
Function  TTF_OpenFont (filename: PChar; ptsize: LongInt) : pTTF_Font; cdecl; external 'SDL_ttf';
Procedure TTF_CloseFont (font: pTTF_Font); cdecl; external 'SDL_ttf';
Function  TTF_RenderText_Shaded (font: pTTF_Font; text: PChar; fg, bg: TSDL_Color) : pSDL_Surface; cdecl; external 'SDL_ttf';

Implementation

End.
