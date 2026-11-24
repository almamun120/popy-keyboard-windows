{
  =============================================================================
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.
  =============================================================================

  Draws the Layout Viewer pictures of the Popy Layout at run time:
    page 1  BuildPopyLayoutBitmap : colour coded keyboard (Latin key, the Bangla
                                    letter it types and the longer key sequences)
                                    with vowel / fola / q / example panels
    page 2  BuildPopyRulesBitmap  : every key sequence, common conjuncts and the
                                    "careful" spellings

  The source file is plain ASCII: Bangla characters are written as code points.
  All sizes are in pixels, so the picture does not depend on the Windows DPI
  scaling.
}

unit uPopyLayoutImage;

interface

uses
  Graphics;

// Caller owns the returned bitmaps
function BuildPopyLayoutBitmap: TBitmap;
function BuildPopyRulesBitmap: TBitmap;

implementation

uses
  Classes,
  SysUtils,
  Forms;

var
  BanglaFontName: string = '';
  LatinFontName:  string = '';

  { =============================================================================== }

function FontInstalled(const AName: string): Boolean;
begin
  Result := Screen.Fonts.IndexOf(AName) >= 0;
end;

{ =============================================================================== }

procedure ResolveFonts;
begin
  if BanglaFontName <> '' then
    Exit;

  if FontInstalled('Nirmala UI') then
    BanglaFontName := 'Nirmala UI'
  else if FontInstalled('Vrinda') then
    BanglaFontName := 'Vrinda'
  else if FontInstalled('Kalpurush') then
    BanglaFontName := 'Kalpurush'
  else if FontInstalled('Siyam Rupali') then
    BanglaFontName := 'Siyam Rupali'
  else
    BanglaFontName := 'Arial Unicode MS';

  if FontInstalled('Segoe UI') then
    LatinFontName := 'Segoe UI'
  else
    LatinFontName := 'Tahoma';
end;

{ =============================================================================== }

// Rounded (R > 0) or plain rectangle; Line = clNone for no border
procedure Box(const Bmp: TBitmap; const X, Y, W, H, R: Integer; const Fill, Line: TColor);
begin
  with Bmp.Canvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := Fill;
    if Line = clNone then
      Pen.Style := psClear
    else
    begin
      Pen.Style := psSolid;
      Pen.Width := 1;
      Pen.Color := Line;
    end;
    if R > 0 then
      RoundRect(X, Y, X + W, Y + H, R * 2, R * 2)
    else
      Rectangle(X, Y, X + W, Y + H);
  end;
end;

{ =============================================================================== }

// Text with its vertical centre at CY. X is the left edge, the centre or the right
// edge (Align). When MaxW > 0 the text shrinks until it fits.
procedure Txt(const Bmp: TBitmap; const AX, CY: Integer; const S: string; const Bn, Bold: Boolean; const Px: Integer; const Col: TColor;
  const Align: TAlignment; const MaxW: Integer);
var
  X, Y, P: Integer;
begin
  with Bmp.Canvas do
  begin
    Brush.Style := bsClear;
    if Bn then
      Font.Name := BanglaFontName
    else
      Font.Name := LatinFontName;
    Font.Color := Col;
    Font.Quality := fqAntialiased;
    if Bold then
      Font.Style := [fsBold]
    else
      Font.Style := [];

    P := Px;
    Font.Height := -P;
    if MaxW > 0 then
      while (TextWidth(S) > MaxW) and (P > 8) do
      begin
        Dec(P);
        Font.Height := -P;
      end;

    X := AX;
    if Align = taCenter then
      X := AX - TextWidth(S) div 2
    else if Align = taRightJustify then
      X := AX - TextWidth(S);
    Y := CY - TextHeight(S) div 2;
    TextOut(X, Y, S);
  end;
end;

{ =============================================================================== }

function NewPageBitmap: TBitmap;
begin
  ResolveFonts;
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
end;

{ =============================================================================== }

procedure BuildPopyKeysPage(const Bmp: TBitmap);
begin
  Bmp.Width := 1000;
  Bmp.Height := 676;
  Box(Bmp, 0, 0, 1000, 676, 0, $00FBF7F6, clNone);
  // ---- Header ----
  Box(Bmp, 0, 0, 1000, 66, 0, $00772F2B, clNone);
  Box(Bmp, 0, 66, 1000, 4, 0, $0023A6F5, clNone);
  Txt(Bmp, 18, 24, #$09AA#$09AA#$09BF' '#$09B2#$09C7#$0986#$0989#$099F, True, True, 27, $00FFFFFF, taLeftJustify, 0);
  Txt(Bmp, 18, 52, #$0987#$0982#$09B0#$09C7#$099C#$09BF' '#$09B9#$09B0#$09AB#$09C7' '#$099F#$09BE#$0987#$09AA' '#$0995#$09B0#$09C1#$09A8', '#$09AC#$09BE#$0982#$09B2#$09BE' '#$09B9#$09AC#$09C7#$0964' Shift / Caps Lock-'#$098F#$09B0' '#$0995#$09CB#$09A8#$09CB' '#$09AA#$09CD#$09B0#$09AD#$09BE#$09AC' '#$09A8#$09C7#$0987, True, False, 13, $00F7CDC9, taLeftJustify, 0);
  Txt(Bmp, 982, 24, 'Popy Layout', False, True, 19, $00FFFFFF, taRightJustify, 0);
  Txt(Bmp, 982, 50, 'Phonetic rule-based layout', False, False, 13, $00F7CDC9, taRightJustify, 0);
  // ---- Keyboard ----
  Box(Bmp, 18, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 18, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 24, 97, '1', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 51, 120, #$09E7, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 90, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 90, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 96, 97, '2', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 123, 120, #$09E8, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 162, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 162, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 168, 97, '3', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 195, 120, #$09E9, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 234, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 234, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 240, 97, '4', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 267, 120, #$09EA, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 306, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 306, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 312, 97, '5', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 339, 120, #$09EB, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 378, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 378, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 384, 97, '6', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 411, 120, #$09EC, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 450, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 450, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 456, 97, '7', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 483, 120, #$09ED, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 522, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 522, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 528, 97, '8', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 555, 120, #$09EE, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 594, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 594, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 600, 97, '9', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 627, 120, #$09EF, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 666, 88, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 666, 86, 66, 80, 9, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 672, 97, '0', False, True, 11, $005E4B4B, taLeftJustify, 0);
  Txt(Bmp, 699, 120, #$09E6, True, False, 24, $0033221F, taCenter, 58);
  Box(Bmp, 38, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 38, 172, 66, 80, 9, $00FFE8F3, $00E864A0);
  Txt(Bmp, 44, 183, 'q', False, True, 11, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 71, 206, #$2022, True, False, 24, $0033221F, taCenter, 58);
  Txt(Bmp, 71, 230, 'qt '#$09CE'  qq '#$0981, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 71, 244, 'qw '#$0983'  q. ?', True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 110, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 110, 172, 66, 80, 9, $00FFE8F3, $00E864A0);
  Txt(Bmp, 116, 183, 'w', False, True, 11, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 143, 206, #$0993, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 143, 230, #$09AB#$09B2#$09BE' '#$25CC#$09CD#$09AC, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 182, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 182, 172, 66, 80, 9, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 188, 183, 'e', False, True, 11, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 215, 206, #$098F, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 215, 230, #$0995#$09BE#$09B0' '#$25CC#$09C7, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 254, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 254, 172, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 260, 183, 'r', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 287, 206, #$09B0, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 287, 230, 'rr '#$09A1#$09BC'  rrh '#$09A2#$09BC, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 287, 244, 'rrr qr '#$098B, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 326, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 326, 172, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 332, 183, 't', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 359, 206, #$09A4, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 359, 230, 'th '#$09A5'  tt '#$099F, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 359, 244, 'tth '#$09A0, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 398, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 398, 172, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 404, 183, 'y', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 431, 206, #$09AF#$09BC, True, False, 20, $0033221F, taCenter, 58);
  Box(Bmp, 470, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 470, 172, 66, 80, 9, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 476, 183, 'u', False, True, 11, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 503, 206, #$0989, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 503, 230, 'uu '#$098A, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 503, 244, #$0995#$09BE#$09B0' '#$25CC#$09C1' '#$25CC#$09C2, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 542, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 542, 172, 66, 80, 9, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 548, 183, 'i', False, True, 11, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 575, 206, #$0987, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 575, 230, 'ii '#$0988, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 575, 244, #$0995#$09BE#$09B0' '#$25CC#$09BF' '#$25CC#$09C0, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 614, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 614, 172, 66, 80, 9, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 620, 183, 'o', False, True, 11, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 647, 206, #$0985, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 647, 230, 'oi '#$0990'  oo '#$0993, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 647, 244, 'ou '#$0994, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 686, 174, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 686, 172, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 692, 183, 'p', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 719, 206, #$09AA, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 719, 230, 'ph '#$09AB, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 58, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 58, 258, 66, 80, 9, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 64, 269, 'a', False, True, 11, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 91, 292, #$0986, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 91, 316, #$0995#$09BE#$09B0' '#$25CC#$09BE, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 130, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 130, 258, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 136, 269, 's', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 163, 292, #$09B8, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 163, 316, 'ss '#$09B6, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 163, 330, 'sss qs '#$09B7, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 202, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 202, 258, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 208, 269, 'd', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 235, 292, #$09A6, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 235, 316, 'dh '#$09A7'  dd '#$09A1, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 235, 330, 'ddh '#$09A2, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 274, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 274, 258, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 280, 269, 'f', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 307, 292, #$09AB, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 307, 316, '= ph', True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 346, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 346, 258, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 352, 269, 'g', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 379, 292, #$0997, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 379, 316, 'gh '#$0998, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 418, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 418, 258, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 424, 269, 'h', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 451, 292, #$09B9, True, False, 26, $0033221F, taCenter, 58);
  Box(Bmp, 490, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 490, 258, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 496, 269, 'j', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 523, 292, #$099C, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 523, 316, 'jh '#$099D, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 523, 330, 'jnnn '#$099C#$09CD#$099E, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 562, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 562, 258, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 568, 269, 'k', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 595, 292, #$0995, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 595, 316, 'kh '#$0996, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 595, 330, 'x '#$0995#$09CD#$09B7, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 634, 260, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 634, 258, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 640, 269, 'l', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 667, 292, #$09B2, True, False, 26, $0033221F, taCenter, 58);
  Box(Bmp, 78, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 78, 344, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 84, 355, 'z', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 111, 378, #$09AF, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 111, 402, #$09AB#$09B2#$09BE' '#$25CC#$09CD#$09AF, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 150, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 150, 344, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 156, 355, 'x', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 183, 378, #$0995#$09CD#$09B7, True, False, 20, $0033221F, taCenter, 58);
  Txt(Bmp, 183, 402, #$0995#$09CD' + '#$09B7, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 222, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 222, 344, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 228, 355, 'c', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 255, 378, #$099A, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 255, 402, 'ch '#$099B, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 294, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 294, 344, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 300, 355, 'v', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 327, 378, #$09AD, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 327, 402, '= bh', True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 366, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 366, 344, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 372, 355, 'b', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 399, 378, #$09AC, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 399, 402, 'bh '#$09AD, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 399, 416, #$09AF#$09C1#$0995#$09CD#$09A4' '#$09B9#$09AF#$09BC' '#$09A8#$09BE, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 438, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 438, 344, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 444, 355, 'n', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 471, 378, #$09A8, True, False, 26, $0033221F, taCenter, 58);
  Txt(Bmp, 471, 402, 'ng '#$0982'  nn '#$09A3, True, False, 10, $0089706B, taCenter, 62);
  Txt(Bmp, 471, 416, 'nnn/qn '#$099E'  nng '#$0999, True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 510, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 510, 344, 66, 80, 9, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 516, 355, 'm', False, True, 11, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 543, 378, #$09AE, True, False, 26, $0033221F, taCenter, 58);
  Box(Bmp, 582, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 582, 344, 66, 80, 9, $00EAF6E3, $007AB04C);
  Txt(Bmp, 588, 355, ',', False, True, 11, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 615, 378, #$25CC#$09CD, True, False, 20, $0033221F, taCenter, 58);
  Txt(Bmp, 615, 402, ',, '#$09CD'+ZWNJ', True, False, 10, $0089706B, taCenter, 62);
  Box(Bmp, 654, 346, 66, 80, 9, $00E6D7D3, clNone);
  Box(Bmp, 654, 344, 66, 80, 9, $00EAF6E3, $007AB04C);
  Txt(Bmp, 660, 355, '.', False, True, 11, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 687, 378, #$0964, True, False, 26, $0033221F, taCenter, 58);
  // ---- Legend ----
  Box(Bmp, 813, 88, 170, 338, 9, $00E6D7D3, clNone);
  Box(Bmp, 812, 86, 170, 338, 9, $00FFFFFF, $00EADCD9);
  Box(Bmp, 822, 86, 150, 3, 0, $0023A6F5, clNone);
  Txt(Bmp, 824, 106, #$09B0#$0999#$09C7#$09B0' '#$09B8#$0982#$0995#$09C7#$09A4, True, True, 15, $0033221F, taLeftJustify, 146);
  Box(Bmp, 824, 126, 22, 18, 5, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 856, 135, #$09B8#$09CD#$09AC#$09B0, True, False, 13, $0033221F, taLeftJustify, 114);
  Box(Bmp, 824, 151, 22, 18, 5, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 856, 160, #$09AC#$09CD#$09AF#$099E#$09CD#$099C#$09A8, True, False, 13, $0033221F, taLeftJustify, 114);
  Box(Bmp, 824, 176, 22, 18, 5, $00EAF6E3, $007AB04C);
  Txt(Bmp, 856, 185, #$099A#$09BF#$09B9#$09CD#$09A8' '#$0993' '#$09AC#$09BF#$09B0#$09BE#$09AE, True, False, 13, $0033221F, taLeftJustify, 114);
  Box(Bmp, 824, 201, 22, 18, 5, $00F5F0F0, $00BCA9A9);
  Txt(Bmp, 856, 210, #$09B8#$0982#$0996#$09CD#$09AF#$09BE, True, False, 13, $0033221F, taLeftJustify, 114);
  Box(Bmp, 824, 226, 22, 18, 5, $00FFE8F3, $00E864A0);
  Txt(Bmp, 856, 235, #$09AC#$09BF#$09B6#$09C7#$09B7' '#$0995#$09C0' (q, w)', True, False, 13, $0033221F, taLeftJustify, 114);
  Txt(Bmp, 824, 262, #$0995#$09C0#$0995#$09CD#$09AF#$09BE#$09AA' '#$09AA#$09A1#$09BC#$09BE#$09B0' '#$09A8#$09BF#$09AF#$09BC#$09AE, True, True, 13, $0033221F, taLeftJustify, 146);
  Box(Bmp, 824, 276, 146, 1, 0, $00EADCD9, clNone);
  Txt(Bmp, 824, 290, #$09AC#$09BE#$0981'-'#$0989#$09AA#$09B0#$09C7' : '#$09AF#$09C7' '#$0995#$09C0' '#$099A#$09BE#$09AA#$09AC#$09C7#$09A8, True, False, 11, $0033221F, taLeftJustify, 146);
  Txt(Bmp, 824, 307, #$09AE#$09BE#$099D#$0996#$09BE#$09A8#$09C7' : '#$09AC#$09BE#$0982#$09B2#$09BE' '#$0985#$0995#$09CD#$09B7#$09B0, True, False, 11, $0033221F, taLeftJustify, 146);
  Txt(Bmp, 824, 324, #$09A8#$09BF#$099A#$09C7' : '#$09A6#$09C1#$0987'/'#$09A4#$09BF#$09A8' '#$0995#$09C0'-'#$0995#$09CD#$09B0#$09AE, True, False, 11, $0033221F, taLeftJustify, 146);
  Txt(Bmp, 824, 341, '('#$099B#$09CB#$099F' '#$09A7#$09C2#$09B8#$09B0' '#$09B2#$09C7#$0996#$09BE')', True, False, 11, $0089706B, taLeftJustify, 146);
  Box(Bmp, 824, 368, 146, 1, 0, $00EADCD9, clNone);
  Txt(Bmp, 824, 382, #$09AE#$09CB#$09A1' '#$09AC#$09A6#$09B2#$09C7#$09B0' '#$0995#$09C0, True, True, 13, $0033221F, taLeftJustify, 146);
  Txt(Bmp, 824, 400, 'F1-F12, Ctrl+Space', False, True, 11, $00B84624, taLeftJustify, 146);
  Txt(Bmp, 824, 415, #$0985#$09A5#$09AC#$09BE' Right Win', False, True, 11, $00B84624, taLeftJustify, 146);
  // ---- Panels ----
  Box(Bmp, 19, 442, 232, 196, 9, $00E6D7D3, clNone);
  Box(Bmp, 18, 440, 232, 196, 9, $00FFFFFF, $00EADCD9);
  Box(Bmp, 28, 440, 212, 3, 0, $00F58E6C, clNone);
  Txt(Bmp, 30, 460, #$09B8#$09CD#$09AC#$09B0' '#$0993' '#$0995#$09BE#$09B0, True, True, 15, $0033221F, taLeftJustify, 208);
  Txt(Bmp, 30, 486, 'o', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 60, 486, #$0985, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 86, 486, #$2013, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 30, 506, 'a', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 60, 506, #$0986, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 86, 506, #$25CC#$09BE, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 30, 526, 'i', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 60, 526, #$0987, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 86, 526, #$25CC#$09BF, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 30, 546, 'ii', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 60, 546, #$0988, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 86, 546, #$25CC#$09C0, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 30, 566, 'u', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 60, 566, #$0989, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 86, 566, #$25CC#$09C1, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 30, 586, 'uu', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 60, 586, #$098A, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 86, 586, #$25CC#$09C2, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 142, 486, 'rrr', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 172, 486, #$098B, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 198, 486, #$25CC#$09C3, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 142, 506, 'e', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 172, 506, #$098F, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 198, 506, #$25CC#$09C7, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 142, 526, 'oi', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 172, 526, #$0990, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 198, 526, #$25CC#$09C8, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 142, 546, 'oo', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 172, 546, #$0993, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 198, 546, #$25CC#$09CB, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 142, 566, 'ou', False, True, 12, $00B84624, taLeftJustify, 0);
  Txt(Bmp, 172, 566, #$0994, True, False, 16, $0033221F, taLeftJustify, 0);
  Txt(Bmp, 198, 566, #$25CC#$09CC, True, False, 16, $0089706B, taLeftJustify, 0);
  Txt(Bmp, 30, 614, #$09AC#$09CD#$09AF#$099E#$09CD#$099C#$09A8#$09C7#$09B0' '#$09AA#$09B0#$09C7' o '#$0995#$09BF#$099B#$09C1' '#$09AC#$09B8#$09BE#$09AF#$09BC' '#$09A8#$09BE',', True, False, 11, $0089706B, taLeftJustify, 212);
  Txt(Bmp, 30, 629, #$099C#$09CB#$09A1#$09BC#$09BE' '#$09AF#$09C1#$0995#$09CD#$09A4' '#$09B9#$09A4#$09C7' '#$09A6#$09C7#$09AF#$09BC' '#$09A8#$09BE': koto = '#$0995#$09A4, True, False, 11, $0089706B, taLeftJustify, 212);
  Box(Bmp, 263, 442, 232, 196, 9, $00E6D7D3, clNone);
  Box(Bmp, 262, 440, 232, 196, 9, $00FFFFFF, $00EADCD9);
  Box(Bmp, 272, 440, 212, 3, 0, $002BA5EF, clNone);
  Txt(Bmp, 274, 460, #$09AB#$09B2#$09BE', '#$09B0#$09C7#$09AB' '#$0993' '#$09AF#$09C1#$0995#$09CD#$09A4, True, True, 15, $0033221F, taLeftJustify, 208);
  Txt(Bmp, 274, 488, #$09B0'-'#$09AB#$09B2#$09BE, True, False, 12, $0089706B, taLeftJustify, 60);
  Txt(Bmp, 338, 488, 'pr', False, True, 12, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 402, 488, #$09AA#$09CD#$09B0, True, False, 15, $0033221F, taLeftJustify, 82);
  Txt(Bmp, 274, 506, #$09B0#$09C7#$09AB, True, False, 12, $0089706B, taLeftJustify, 60);
  Txt(Bmp, 338, 506, 'durga', False, True, 12, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 402, 506, #$09A6#$09C1#$09B0#$09CD#$0997#$09BE, True, False, 15, $0033221F, taLeftJustify, 82);
  Txt(Bmp, 274, 524, #$09AF'-'#$09AB#$09B2#$09BE, True, False, 12, $0089706B, taLeftJustify, 60);
  Txt(Bmp, 338, 524, 'kz', False, True, 12, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 402, 524, #$0995#$09CD#$09AF, True, False, 15, $0033221F, taLeftJustify, 82);
  Txt(Bmp, 274, 542, #$09AC'-'#$09AB#$09B2#$09BE, True, False, 12, $0089706B, taLeftJustify, 60);
  Txt(Bmp, 338, 542, 'sw', False, True, 12, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 402, 542, #$09B8#$09CD#$09AC, True, False, 15, $0033221F, taLeftJustify, 82);
  Txt(Bmp, 274, 560, #$09B0#$200D#$09CD#$09AF, True, False, 12, $0089706B, taLeftJustify, 60);
  Txt(Bmp, 338, 560, 'rzab', False, True, 12, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 402, 560, #$09B0#$200D#$09CD#$09AF#$09BE#$09AC, True, False, 15, $0033221F, taLeftJustify, 82);
  Txt(Bmp, 274, 578, #$0985#$09CD#$09AF#$09BE, True, False, 12, $0089706B, taLeftJustify, 60);
  Txt(Bmp, 338, 578, 'ozap', False, True, 12, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 402, 578, #$0985#$09CD#$09AF#$09BE#$09AA, True, False, 15, $0033221F, taLeftJustify, 82);
  Txt(Bmp, 274, 596, #$0995#$09CD#$09B7, True, False, 12, $0089706B, taLeftJustify, 60);
  Txt(Bmp, 338, 596, 'x', False, True, 12, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 402, 596, #$0995#$09CD#$09B7, True, False, 15, $0033221F, taLeftJustify, 82);
  Txt(Bmp, 274, 614, #$099C#$09CD#$099E, True, False, 12, $0089706B, taLeftJustify, 60);
  Txt(Bmp, 338, 614, 'jnnnan', False, True, 12, $0000528A, taLeftJustify, 0);
  Txt(Bmp, 402, 614, #$099C#$09CD#$099E#$09BE#$09A8, True, False, 15, $0033221F, taLeftJustify, 82);
  Box(Bmp, 507, 442, 232, 196, 9, $00E6D7D3, clNone);
  Box(Bmp, 506, 440, 232, 196, 9, $00FFFFFF, $00EADCD9);
  Box(Bmp, 516, 440, 212, 3, 0, $00E864A0, clNone);
  Txt(Bmp, 518, 460, #$09B6#$09BF#$09AB#$099F' '#$21E7' '#$0993' q '#$2014' '#$099C#$09CB#$09A1#$09BC#$09BE', '#$09B8#$09CD#$09AC#$09BE#$09A7#$09C0#$09A8' '#$09B8#$09CD#$09AC#$09B0', '#$09AC#$09BF#$09B6#$09C7#$09B7' '#$099A#$09BF#$09B9#$09CD#$09A8, True, True, 15, $0033221F, taLeftJustify, 208);
  Txt(Bmp, 518, 488, 'ut'#$21E7'tor', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 488, #$0989#$09A4#$09CD#$09A4#$09B0, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 518, 506, 'bud'#$21E7'dhi', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 506, #$09AC#$09C1#$09A6#$09CD#$09A7#$09BF, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 518, 524, 'bo'#$21E7'i', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 524, #$09AC#$0987, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 518, 542, 'caqqd', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 542, #$099A#$09BE#$0981#$09A6, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 518, 560, 'hotthaqt', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 560, #$09B9#$09A0#$09BE#$09CE, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 518, 578, 'ko'#$21E7'oo', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 578, #$0995#$0993, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 518, 596, 'k'#$21E7'a', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 596, #$0995#$0986, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 518, 614, 'qha', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 614, #$09B9#$09BE, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 518, 632, 'jogqt', False, True, 12, $00A02B5B, taLeftJustify, 0);
  Txt(Bmp, 618, 632, #$099C#$0997#$09CE, True, False, 15, $0033221F, taLeftJustify, 110);
  Box(Bmp, 751, 442, 232, 196, 9, $00E6D7D3, clNone);
  Box(Bmp, 750, 440, 232, 196, 9, $00FFFFFF, $00EADCD9);
  Box(Bmp, 760, 440, 212, 3, 0, $007AB04C, clNone);
  Txt(Bmp, 762, 460, #$0995#$09AF#$09BC#$09C7#$0995#$099F#$09BF' '#$09B6#$09AC#$09CD#$09A6, True, True, 15, $0033221F, taLeftJustify, 208);
  Txt(Bmp, 762, 488, 'amar', False, True, 12, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 862, 488, #$0986#$09AE#$09BE#$09B0, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 762, 506, 'bangla', False, True, 12, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 862, 506, #$09AC#$09BE#$0982#$09B2#$09BE, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 762, 524, 'prem', False, True, 12, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 862, 524, #$09AA#$09CD#$09B0#$09C7#$09AE, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 762, 542, 'swadhiin', False, True, 12, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 862, 542, #$09B8#$09CD#$09AC#$09BE#$09A7#$09C0#$09A8, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 762, 560, 'xoma', False, True, 12, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 862, 560, #$0995#$09CD#$09B7#$09AE#$09BE, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 762, 578, 'bidza', False, True, 12, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 862, 578, #$09AC#$09BF#$09A6#$09CD#$09AF#$09BE, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 762, 596, 'sotz', False, True, 12, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 862, 596, #$09B8#$09A4#$09CD#$09AF, True, False, 15, $0033221F, taLeftJustify, 110);
  Txt(Bmp, 762, 614, 'ghorri', False, True, 12, $00436B1B, taLeftJustify, 0);
  Txt(Bmp, 862, 614, #$0998#$09A1#$09BC#$09BF, True, False, 15, $0033221F, taLeftJustify, 110);
  // ---- Footer ----
  Txt(Bmp, 500, 658, 'Space / Enter / Tab / '#$09A4#$09C0#$09B0'-'#$099A#$09BF#$09B9#$09CD#$09A8' '#$099A#$09BE#$09AA#$09B2#$09C7' '#$09B6#$09AC#$09CD#$09A6' '#$09B6#$09C7#$09B7' '#$09B9#$09AF#$09BC'  '#$2022'  Backspace '#$098F#$0995#$099F#$09BF' '#$0995#$09B0#$09C7' '#$0995#$09C0' '#$09AE#$09CB#$099B#$09C7'  '#$2022'  '#$09AC#$09CD#$09AF#$099E#$09CD#$099C#$09A8#$09C7#$09B0' '#$09AA#$09B0#$09C7' o '#$09AC#$09BE' q '#$09A6#$09BF#$09B2#$09C7' '#$09B8#$09BE#$09AE#$09AF#$09BC#$09BF#$0995' '#$099B#$09CB#$099F' o / q '#$09A6#$09C7#$0996#$09BE' '#$09AF#$09BE#$09AF#$09BC', '#$09AA#$09B0#$09C7#$09B0' '#$0995#$09C0'-'#$09A4#$09C7' '#$09AE#$09C1#$099B#$09C7' '#$09AF#$09BE#$09AF#$09BC, True, False, 11, $0089706B, taCenter, 970);
end;
{ =============================================================================== }

procedure BuildPopyRulesPage(const Bmp: TBitmap);
begin
  Bmp.Width := 1000;
  Bmp.Height := 664;
  Box(Bmp, 0, 0, 1000, 664, 0, $00FBF7F6, clNone);
  // ---- Header ----
  Box(Bmp, 0, 0, 1000, 66, 0, $00772F2B, clNone);
  Box(Bmp, 0, 66, 1000, 4, 0, $0023A6F5, clNone);
  Txt(Bmp, 18, 24, #$09AA#$09AA#$09BF' '#$09B2#$09C7#$0986#$0989#$099F' '#$2014' '#$09A8#$09BF#$09AF#$09BC#$09AE' '#$0993' '#$09AF#$09C1#$0995#$09CD#$09A4#$09BE#$0995#$09CD#$09B7#$09B0, True, True, 27, $00FFFFFF, taLeftJustify, 0);
  Txt(Bmp, 18, 52, #$0995#$09C0'-'#$0995#$09CD#$09B0#$09AE' '#$09A5#$09C7#$0995#$09C7' '#$09AC#$09BE#$0982#$09B2#$09BE' '#$0985#$0995#$09CD#$09B7#$09B0', '#$09B8#$09BE#$09A7#$09BE#$09B0#$09A3' '#$09AF#$09C1#$0995#$09CD#$09A4#$09BE#$0995#$09CD#$09B7#$09B0' '#$098F#$09AC#$0982' '#$09B8#$09BE#$09AC#$09A7#$09BE#$09A8#$09A4#$09BE#$09B0' '#$09A4#$09BE#$09B2#$09BF#$0995#$09BE, True, False, 13, $00F7CDC9, taLeftJustify, 0);
  Txt(Bmp, 982, 24, 'Popy Layout', False, True, 19, $00FFFFFF, taRightJustify, 0);
  Txt(Bmp, 982, 50, 'Rules & conjuncts', False, False, 13, $00F7CDC9, taRightJustify, 0);
  // ---- Consonants ----
  Box(Bmp, 18, 84, 5, 20, 2, $002BA5EF, clNone);
  Txt(Bmp, 32, 94, #$09AC#$09CD#$09AF#$099E#$09CD#$099C#$09A8', '#$099A#$09BF#$09B9#$09CD#$09A8' '#$0993' '#$09B8#$0982#$0996#$09CD#$09AF#$09BE#$09B0' '#$0995#$09C0'-'#$0995#$09CD#$09B0#$09AE, True, True, 15, $0033221F, taLeftJustify, 964);
  Box(Bmp, 18, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 26, 127, #$0995, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 127, 'k', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 125, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 133, 127, #$0996, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 127, 'kh', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 232, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 240, 127, #$0997, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 127, 'g', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 339, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 347, 127, #$0998, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 127, 'gh', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 446, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 454, 127, #$0999, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 127, 'nng', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 553, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 561, 127, #$099A, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 127, 'c', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 660, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 668, 127, #$099B, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 127, 'ch', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 767, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 775, 127, #$099C, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 127, 'j', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 874, 112, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 882, 127, #$099D, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 967, 127, 'jh', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 18, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 26, 163, #$099E, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 163, 'nnn / qn', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 125, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 133, 163, #$099F, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 163, 'tt', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 232, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 240, 163, #$09A0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 163, 'tth', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 339, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 347, 163, #$09A1, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 163, 'dd', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 446, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 454, 163, #$09A2, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 163, 'ddh', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 553, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 561, 163, #$09A3, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 163, 'nn', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 660, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 668, 163, #$09A4, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 163, 't', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 767, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 775, 163, #$09A5, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 163, 'th', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 874, 148, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 882, 163, #$09A6, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 967, 163, 'd', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 18, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 26, 199, #$09A7, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 199, 'dh', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 125, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 133, 199, #$09A8, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 199, 'n', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 232, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 240, 199, #$09AA, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 199, 'p', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 339, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 347, 199, #$09AB, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 199, 'f / ph', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 446, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 454, 199, #$09AC, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 199, 'b', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 553, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 561, 199, #$09AD, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 199, 'bh / v', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 660, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 668, 199, #$09AE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 199, 'm', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 767, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 775, 199, #$09AF#$09BC, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 199, 'y', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 874, 184, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 882, 199, #$09AF, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 967, 199, 'z', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 18, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 26, 235, #$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 235, 'r', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 125, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 133, 235, #$09B2, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 235, 'l', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 232, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 240, 235, #$09B8, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 235, 's', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 339, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 347, 235, #$09B6, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 235, 'ss', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 446, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 454, 235, #$09B7, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 235, 'sss', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 553, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 561, 235, #$09B9, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 235, 'h', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 660, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 668, 235, #$0995#$09CD#$09B7, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 235, 'x', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 767, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 775, 235, #$09A1#$09BC, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 235, 'rr', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 874, 220, 101, 30, 7, $00DCF3FF, $002BA5EF);
  Txt(Bmp, 882, 235, #$09A2#$09BC, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 967, 235, 'rrh', False, True, 12, $0000528A, taRightJustify, 46);
  Box(Bmp, 18, 256, 101, 30, 7, $00EAF6E3, $007AB04C);
  Txt(Bmp, 26, 271, #$0982, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 271, 'ng', False, True, 12, $00436B1B, taRightJustify, 46);
  Box(Bmp, 125, 256, 101, 30, 7, $00EAF6E3, $007AB04C);
  Txt(Bmp, 133, 271, #$0983, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 271, 'qw', False, True, 12, $00436B1B, taRightJustify, 46);
  Box(Bmp, 232, 256, 101, 30, 7, $00EAF6E3, $007AB04C);
  Txt(Bmp, 240, 271, #$0981, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 271, 'qq', False, True, 12, $00436B1B, taRightJustify, 46);
  Box(Bmp, 339, 256, 101, 30, 7, $00EAF6E3, $007AB04C);
  Txt(Bmp, 347, 271, #$09CE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 271, 'qt', False, True, 12, $00436B1B, taRightJustify, 46);
  Box(Bmp, 446, 256, 101, 30, 7, $00EAF6E3, $007AB04C);
  Txt(Bmp, 454, 271, #$09F3, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 271, 'qk', False, True, 12, $00436B1B, taRightJustify, 46);
  Box(Bmp, 553, 256, 101, 30, 7, $00EAF6E3, $007AB04C);
  Txt(Bmp, 561, 271, #$0964, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 271, '.', False, True, 12, $00436B1B, taRightJustify, 46);
  Box(Bmp, 660, 256, 101, 30, 7, $00EAF6E3, $007AB04C);
  Txt(Bmp, 668, 271, #$25CC#$09CD, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 271, ',,', False, True, 12, $00436B1B, taRightJustify, 46);
  Box(Bmp, 767, 256, 101, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 775, 271, #$09AC'-'#$09AB#$09B2#$09BE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 271, 'w', False, True, 12, $00A02B5B, taRightJustify, 46);
  Box(Bmp, 18, 296, 5, 20, 2, $00F58E6C, clNone);
  Txt(Bmp, 32, 306, #$09AF#$09C1#$0995#$09CD#$09A4#$09BE#$0995#$09CD#$09B7#$09B0' '#$2014' '#$09A4#$09BE#$09B2#$09BF#$0995#$09BE#$09B0' '#$09E7#$09EC#$09E9' '#$099C#$09CB#$09A1#$09BC#$09BE' '#$09A8#$09BF#$099C#$09C7' '#$09AF#$09C1#$0995#$09CD#$09A4' '#$09B9#$09AF#$09BC'; '#$09AC#$09BE#$0995#$09BF' '#$099C#$09CB#$09A1#$09BC#$09BE' '#$09B6#$09BF#$09AB#$099F' ('#$21E7') '#$099F#$09CD#$09AF#$09BE#$09AA' '#$09A6#$09BF#$09AF#$09BC#$09C7, True, True, 15, $0033221F, taLeftJustify, 964);
  Box(Bmp, 18, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 26, 339, #$0995#$09CD#$0995, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 339, 'kk', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 125, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 133, 339, #$0995#$09CD#$09A4, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 339, 'kt', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 232, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 240, 339, #$0995#$09CD#$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 339, 'kr', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 339, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 347, 339, #$0995#$09CD#$09B7#$09CD#$09AE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 339, 'xm', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 446, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 454, 339, #$0997#$09CD#$09A8, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 339, 'gn', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 553, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 561, 339, #$0999#$09CD#$0995, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 339, 'nngk', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 660, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 668, 339, #$0999#$09CD#$0997, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 339, 'nngg', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 767, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 775, 339, #$099A#$09CD#$099A, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 339, 'cc', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 874, 324, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 882, 339, #$099C#$09CD#$099C, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 967, 339, 'jj', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 18, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 26, 375, #$099C#$09CD#$099E, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 375, 'jnnn', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 125, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 133, 375, #$099E#$09CD#$099A, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 375, 'nnnc', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 232, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 240, 375, #$099E#$09CD#$099C, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 375, 'nnnj', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 339, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 347, 375, #$099F#$09CD#$099F, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 375, 'tt'#$21E7'tt', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 446, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 454, 375, #$09A4#$09CD#$09A4, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 375, 't'#$21E7't', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 553, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 561, 375, #$09A4#$09CD#$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 375, 'tr', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 660, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 668, 375, #$09A4#$09CD#$09AE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 375, 'tm', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 767, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 775, 375, #$09A6#$09CD#$09A7, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 375, 'd'#$21E7'dh', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 874, 360, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 882, 375, #$09A6#$09CD#$09AC, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 967, 375, 'dw', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 18, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 26, 411, #$09A6#$09CD#$09AE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 411, 'dm', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 125, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 133, 411, #$09A6#$09CD#$09AF, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 411, 'dz', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 232, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 240, 411, #$09A6#$09CD#$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 411, 'dr', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 339, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 347, 411, #$09A8#$09CD#$09A4, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 411, 'nt', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 446, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 454, 411, #$09A8#$09CD#$09A6, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 411, 'nd', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 553, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 561, 411, #$09A8#$09CD#$09A7, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 411, 'ndh', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 660, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 668, 411, #$09A8#$09CD#$09AE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 411, 'nm', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 767, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 775, 411, #$09A8#$09CD#$09A8, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 411, 'n'#$21E7'n', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 874, 396, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 882, 411, #$09A8#$09CD#$09A4#$09CD#$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 967, 411, 'ntr', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 18, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 26, 447, #$09AA#$09CD#$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 447, 'pr', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 125, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 133, 447, #$09AC#$09CD#$09A6, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 447, 'bd', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 232, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 240, 447, #$09AC#$09CD#$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 447, 'br', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 339, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 347, 447, #$09AE#$09CD#$09AA, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 447, 'mp', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 446, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 454, 447, #$09AE#$09CD#$09AC, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 447, 'mw', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 553, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 561, 447, #$09AE#$09CD#$09AD, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 447, 'mbh', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 660, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 668, 447, #$09B2#$09CD#$09B2, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 447, 'll', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 767, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 775, 447, #$09B6#$09CD#$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 447, 'ssr', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 874, 432, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 882, 447, #$09B6#$09CD#$099A, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 967, 447, 'ssc', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 18, 468, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 26, 483, #$09B7#$09CD#$099F, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 111, 483, 'ssstt', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 125, 468, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 133, 483, #$09B8#$09CD#$0995, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 218, 483, 'sk', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 232, 468, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 240, 483, #$09B8#$09CD#$09A4, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 325, 483, 'st', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 339, 468, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 347, 483, #$09B8#$09CD#$09A5, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 432, 483, 'sth', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 446, 468, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 454, 483, #$09B8#$09CD#$09AC, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 539, 483, 'sw', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 553, 468, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 561, 483, #$09B8#$09CD#$09AE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 646, 483, 'sm', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 660, 468, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 668, 483, #$09B8#$09CD#$09A4#$09CD#$09B0, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 753, 483, 'str', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 767, 468, 101, 30, 7, $00FFEEE6, $00F58E6C);
  Txt(Bmp, 775, 483, #$09B9#$09CD#$09AE, True, False, 16, $0033221F, taLeftJustify, 44);
  Txt(Bmp, 860, 483, 'hm', False, True, 12, $00B84624, taRightJustify, 46);
  Box(Bmp, 18, 508, 5, 20, 2, $00E864A0, clNone);
  Txt(Bmp, 32, 518, #$09B6#$09BF#$09AB#$099F' '#$21E7' = '#$099C#$09CB#$09B0' '#$0995#$09B0#$09C7' '#$09AF#$09C1#$0995#$09CD#$09A4' / '#$09B8#$09CD#$09AC#$09BE#$09A7#$09C0#$09A8' '#$09B8#$09CD#$09AC#$09B0' ('#$098F#$0995#$09BE' '#$099A#$09C7#$09AA#$09C7' '#$099B#$09BE#$09A1#$09BC#$09C1#$09A8', s '#$099A#$09BF#$09B9#$09CD#$09A8' '#$09A6#$09C7#$0996#$09BE#$09AC#$09C7')', True, True, 15, $0033221F, taLeftJustify, 964);
  Box(Bmp, 18, 536, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 26, 551, #$0989#$09A4#$09CD#$09A4#$09B0, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 193, 551, 'ut'#$21E7'tor', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 213, 536, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 221, 551, #$09AC#$09C1#$09A6#$09CD#$09A7#$09BF, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 388, 551, 'bud'#$21E7'dhi', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 408, 536, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 416, 551, #$09AD#$09BF#$09A8#$09CD#$09A8, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 583, 551, 'bhin'#$21E7'no', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 603, 536, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 611, 551, #$0989#$09A4#$09CD#$09A5#$09BE#$09A8, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 778, 551, 'ut'#$21E7'than', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 798, 536, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 806, 551, #$09AC#$0987, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 973, 551, 'bo'#$21E7'i', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 18, 572, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 26, 587, #$0995#$0993, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 193, 587, 'ko'#$21E7'oo', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 213, 572, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 221, 587, #$0985#$09AF#$09A5#$09BE, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 388, 587, 'oqzotha', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 408, 572, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 416, 587, #$0995#$09CD#$09AB, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 583, 587, 'k'#$21E7'f', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 603, 572, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 611, 587, #$09A8#$09CD#$0995, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 778, 587, 'n'#$21E7'k', False, True, 12, $00A02B5B, taRightJustify, 87);
  Box(Bmp, 798, 572, 183, 30, 7, $00FFE8F3, $00E864A0);
  Txt(Bmp, 806, 587, #$0995#$09CD#$09B9, True, False, 16, $0033221F, taLeftJustify, 85);
  Txt(Bmp, 973, 587, 'k'#$21E7'h', False, True, 12, $00A02B5B, taRightJustify, 87);
  // ---- Footer ----
  Txt(Bmp, 500, 648, 'kf = '#$0995#$09AB' ('#$099C#$09CB#$09B0' '#$0995#$09B0#$09C7' '#$0995#$09CD#$09AB' = k'#$21E7'f)  '#$2022'  '#$09B0#$200D#$09CD#$09AF' = '#$09B6#$09C1#$09B0#$09C1#$09A4#$09C7' rz, '#$0985#$09A8#$09CD#$09AF#$09A4#$09CD#$09B0' rqz  '#$2022'  '#$09AC'-'#$09AB#$09B2#$09BE' = w, '#$09B8#$09CD#$09AC#$09BE#$09A7#$09C0#$09A8' '#$09AC' = b  '#$2022'  '#$09B0#$09C7#$09AB' '#$09A8#$09BF#$099C#$09C7' '#$09A5#$09C7#$0995#$09C7' '#$09B9#$09AF#$09BC': durga = '#$09A6#$09C1#$09B0#$09CD#$0997#$09BE, True, False, 11, $0089706B, taCenter, 970);
end;

{ =============================================================================== }

function BuildPopyLayoutBitmap: TBitmap;
begin
  Result := NewPageBitmap;
  BuildPopyKeysPage(Result);
end;

{ =============================================================================== }

function BuildPopyRulesBitmap: TBitmap;
begin
  Result := NewPageBitmap;
  BuildPopyRulesPage(Result);
end;

{ =============================================================================== }

end.
