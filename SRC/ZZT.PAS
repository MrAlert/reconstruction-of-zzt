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
					'R': ResetConfig := true;
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
		tmp: integer;
		cfgJoystickSupport, cfgMouseSupport, cfgJoystick, cfgMouse, cfgMono: boolean;
		joystickSupported, mouseSupported: boolean;
		cfgLastMode, cfgJoystickX, cfgJoystickY: integer;
	begin
		ConfigInvalid := true;
		EditorEnabled := true;
		ConfigRegistrant := '';
		ConfigWorldFile := '';
		SerialNumber := 'NONE';

		Assign(cfgFile, 'ZZT.CFG');
		Reset(cfgFile);
		if IOResult = 0 then begin
			ReadLn(cfgFile, tmp);
			ConfigInvalid := (tmp and 1) <> 0;
			cfgJoystickSupport := (tmp and 2) <> 0;
			cfgMouseSupport := (tmp and 4) <> 0;
			cfgJoystick := (tmp and 8) <> 0;
			cfgMouse := (tmp and 16) <> 0;
			cfgMono := (tmp and 32) <> 0;
			ReadLn(cfgFile, cfgJoystickX);
			ReadLn(cfgFile, cfgJoystickY);
			ReadLn(cfgFile, cfgLastMode);
			ReadLn(cfgFile, ConfigWorldFile);
			ReadLn(cfgFile, ConfigRegistrant);
			if Eof(cfgFile) then
				SerialNumber := 'NONE'
			else
				ReadLn(cfgFile, SerialNumber);
			Close(cfgFile);
		end;

		if ConfigWorldFile[1] = '*' then begin
			EditorEnabled := false;
			ConfigWorldFile := Copy(ConfigWorldFile, 2, Length(ConfigWorldFile) - 1);
		end;
		if Length(ConfigWorldFile) <> 0 then begin
			StartupWorldFileName := ConfigWorldFile;
		end;
		InputInitDevices;
		joystickSupported := InputJoystickEnabled;
		mouseSupported := InputMouseEnabled;

		if JoystickXInitial = 0 then
			Inc(JoystickXInitial);
		if JoystickYInitial = 0 then
			Inc(JoystickYInitial);
		tmp := Abs(((JoystickXInitial - cfgJoystickX) * 100) div JoystickXInitial)
			+ Abs(((JoystickYInitial - cfgJoystickY) * 100) div JoystickYInitial);

		if ConfigInvalid or ResetConfig
			or (joystickSupported and (tmp > 50))
			or (joystickSupported <> cfgJoystickSupport)
			or (mouseSupported <> cfgMouseSupport)
			or cfgMouse or (LastMode <> cfgLastMode) then
		begin
			ConfigInvalid := false;
			cfgJoystick := InputJoystickEnabled;
			cfgMouse := InputMouseEnabled;

			Window(1, 1, 80, 25);
			TextBackground(Brown);
			ClrScr;
			TextColor(White);
			TextColor(White);
			Writeln;
			Writeln('                        ZZT:  The Object-Oriented Game');
			TextColor(Yellow);
			if Length(ConfigRegistrant) = 0 then
				Writeln('                             Shareware version 3.0')
			else
				Writeln('                                  Version 3.0');
			Writeln('                            Created by Tim Sweeney');
			GotoXY(1, 7);
			TextColor(Blue);
			Write('================================================================================');
			GotoXY(1, 24);
			Write('================================================================================');
			TextColor(White);
			GotoXY(30, 7);
			Write(' Game Configuration ');
			GotoXY(1, 25);
			Write(' Copyright (c) 1991 Potomac Computer Systems               Press ... to abort');
			TextColor(Black);
			TextBackground(LightGray);
			GotoXY(66, 25);
			Write('ESC');
			Window(1, 8, 80, 23);
			TextBackground(Blue);
			ClrScr;
			TextColor(Yellow);
			if not InputConfigure then
				GameTitleExitRequested := true
			else begin
				TextColor(LightGreen);
				if not VideoConfigure then
					GameTitleExitRequested := true;
			end;

			if not GameTitleExitRequested then begin
				Rewrite(cfgFile);
				tmp := (Integer(ConfigInvalid) shl 0)
					+ (Integer(joystickSupported) shl 1)
					+ (Integer(mouseSupported) shl 2)
					+ (Integer(InputJoystickEnabled) shl 3)
					+ (Integer(InputMouseEnabled) shl 4)
					+ (Integer(VideoMonochrome) shl 5);
				WriteLn(cfgFile, tmp);
				WriteLn(cfgFile, JoystickXInitial);
				WriteLn(cfgFile, JoystickYInitial);
				WriteLn(cfgFile, LastMode);
				WriteLn(cfgFile, ConfigWorldFile);
				WriteLn(cfgFile, ConfigRegistrant);
				WriteLn(cfgFile, SerialNumber);
				Close(cfgFile);
			end;
			Window(1, 1, 80, 25);
		end else begin
			InputJoystickEnabled := cfgJoystick;
			InputMouseEnabled := cfgMouse;
			VideoMonochrome := cfgMono;
		end;
	end;

begin
	WorldFileDescCount := 7;
	WorldFileDescKeys[1] := 'TOWN';
	WorldFileDescValues[1] := 'TOWN       The Town of ZZT';
	WorldFileDescKeys[2] := 'DEMO';
	WorldFileDescValues[2] := 'DEMO       Demo of the ZZT World Editor';
	WorldFileDescKeys[3] := 'CAVES';
	WorldFileDescValues[3] := 'CAVES      The Caves of ZZT';
	WorldFileDescKeys[4] := 'DUNGEONS';
	WorldFileDescValues[4] := 'DUNGEONS   The Dungeons of ZZT';
	WorldFileDescKeys[5] := 'CITY';
	WorldFileDescValues[5] := 'CITY       Underground City of ZZT';
	WorldFileDescKeys[6] := 'BEST';
	WorldFileDescValues[6] := 'BEST       The Best of ZZT';
	WorldFileDescKeys[7] := 'TOUR';
	WorldFileDescValues[7] := 'TOUR       Guided Tour ZZT'#39's Other Worlds';

	Randomize;
	SetCBreak(false);
	InitialTextAttr := TextAttr;

	StartupWorldFileName := 'TOWN';
	ResourceDataFileName := 'ZZT.DAT';
	ResetConfig := false;
	GameTitleExitRequested := false;
	ParseArguments;
	GameConfigure;

	if not GameTitleExitRequested then begin
		VideoInstall;
		TextWindowClear := BoardDrawTile;
		OrderPrintId := @SerialNumber;
		Port[PORT_CGA_PALETTE] := 1;
		New(IoTmpBuf);

		VideoHideCursor;
		ClrScr;

		TickSpeed := 4;
		DebugEnabled := false;
		SavedGameFileName := 'SAVED';
		SavedBoardFileName := 'TEMP';
		GenerateTransitionTable;
		WorldCreate;

		GameTitleLoop;

		Dispose(IoTmpBuf);
	end;

	SoundUninstall;
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
