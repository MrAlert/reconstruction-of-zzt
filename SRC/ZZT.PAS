{
	Copyright (c) 2020 Adrian Siekierka

	Based on a reconstruction of code from ZZT,
	Copyright 1991 Epic MegaGames, used with permission.

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
}

{$I-}
{$M 16384,163840,655360}
program ZZT;
uses Crt, Dos, Video, Keys, Sounds, Input, TxtWind, GameVars, Elements, Editor, Oop, Game;

procedure ParseArguments;
	var
		i: integer;
		pArg: string;
	begin
		for i := 1 to ParamCount do begin
			pArg := ParamStr(i);
			if pArg[1] = '/' then begin
				case UpCase(pArg[2]) of
					'T': begin
						SoundTimeCheckCounter := 0;
						UseSystemTimeForElapsed := false;
					end;
				end;
			end else begin
				StartupWorldFileName := pArg;
				if (Length(StartupWorldFileName) > 4) and (StartupWorldFileName[Length(StartupWorldFileName) - 3] = '.') then begin
					StartupWorldFileName := Copy(StartupWorldFileName, 1, Length(StartupWorldFileName) - 4);
				end;
			end;
		end;
	end;

procedure GameConfigure;
	var
		cfgFile: text;
	begin
		EditorEnabled := true;
		ConfigRegistrant := '';
		ConfigWorldFile := '';

		Assign(cfgFile, 'REGISTER');
		Reset(cfgFile);
		if IOResult = 0 then begin
			ReadLn(cfgFile, ConfigRegistrant);
			if IOResult = 0 then begin
				ReadLn(cfgFile, ConfigWorldFile);
				if IOResult <> 0 then begin
					ConfigWorldFile := '';
				end else begin
					if ConfigWorldFile[1] = '*' then begin
						EditorEnabled := false;
						ConfigWorldFile := Copy(ConfigWorldFile, 2, Length(ConfigWorldFile) - 1);
					end;
				end;
			end;
		end;

		if Length(ConfigWorldFile) <> 0 then begin
			StartupWorldFileName := ConfigWorldFile;
		end;
	end;

begin
	SetCBreak(false);
	Randomize;

	StartupWorldFileName := 'TOWN';
	GameConfigure;
	InitialTextAttr := TextAttr;
	TextWindowClear := BoardDrawTile;

	ClrScr;
	WriteLn;
	WriteLn;
	WriteLn('               ZZT (tm)                  Copyright 1991');
	WriteLn;
	WriteLn('       The Object-Oriented Game          Potomac Computer Systems');
	WriteLn('                                         10406 Holbrook Drive');
	WriteLn('      Shareware Version 2.00            Potomac, MD 20854');
	WriteLn;
	if Length(ConfigRegistrant) <> 0 then begin
		if ConfigRegistrant = '*' then
			WriteLn('   Registered copy:  Thanks for supporting shareware.')
		else
			WriteLn('  Copy registered to ', ConfigRegistrant, ': Thanks for your support.');
		WriteLn;
	end;

	InputConfigure;
	VideoConfigure;

	Port[PORT_CGA_PALETTE] := 1;
	New(IoTmpBuf);

	VideoHideCursor;
	ClrScr;

	TickSpeed := 4;
	DebugEnabled := false;
	SavedGameFileName := 'SAVED';
	SavedBoardFileName := 'TEMP';
	GenerateTransitionTable;
	ParseArguments;
	WorldCreate;

	GameTitleLoop;

	SoundUninstall;
	Dispose(IoTmpBuf);
	SoundClearQueue;

	Port[PORT_CGA_PALETTE] := 0;
	TextAttr := InitialTextAttr;
	ClrScr;

	if Length(ConfigRegistrant) = 0 then begin
		GamePrintRegisterMessage;
	end else begin
		Writeln;
		Writeln('  Thank you for playing ZZT.');
		Writeln;
	end;

	VideoShowCursor;
end.
