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
{$V-}
{$F-}
{$M 16384,163840,655360}
program ZZT;
uses Crt, Dos, Video, Keys, Sounds, Input, TxtWind;

const
	MAX_STAT = 150;
	MAX_ELEMENT = 53;
	MAX_BOARD = 100;
	MAX_FLAG = 10;
	BOARD_WIDTH = 60;
	BOARD_HEIGHT = 25;
	WORLD_FILE_HEADER_SIZE = 512;
	HIGH_SCORE_COUNT = 30;
	TORCH_DURATION = 200;
	TORCH_DX = 8;
	TORCH_DY = 5;
	TORCH_DIST_SQR = 50;
	{}
	E_EMPTY = 0;
	E_BOARD_EDGE = 1;
	E_MESSAGE_TIMER = 2;
	E_MONITOR = 3; { State - Title screen }
	E_PLAYER = 4; { State - Playing }
	E_AMMO = 5;
	E_TORCH = 6;
	E_GEM = 7;
	E_KEY = 8;
	E_DOOR = 9;
	E_SCROLL = 10;
	E_PASSAGE = 11;
	E_DUPLICATOR = 12;
	E_BOMB = 13;
	E_ENERGIZER = 14;
	E_STAR = 15;
	E_CONVEYOR_CW = 16;
	E_CONVEYOR_CCW = 17;
	E_BULLET = 18;
	E_WATER = 19;
	E_FOREST = 20;
	E_SOLID = 21;
	E_NORMAL = 22;
	E_BREAKABLE = 23;
	E_BOULDER = 24;
	E_SLIDER_NS = 25;
	E_SLIDER_EW = 26;
	E_FAKE = 27;
	E_INVISIBLE = 28;
	E_BLINK_WALL = 29;
	E_TRANSPORTER = 30;
	E_LINE = 31;
	E_RICOCHET = 32;
	E_BLINK_RAY_EW = 33;
	E_BEAR = 34;
	E_RUFFIAN = 35;
	E_OBJECT = 36;
	E_SLIME = 37;
	E_SHARK = 38;
	E_SPINNING_GUN = 39;
	E_PUSHER = 40;
	E_LION = 41;
	E_TIGER = 42;
	E_BLINK_RAY_NS = 43;
	E_CENTIPEDE_HEAD = 44;
	E_CENTIPEDE_SEGMENT = 45;
	E_TEXT_BLUE = 47;
	E_TEXT_GREEN = 48;
	E_TEXT_CYAN = 49;
	E_TEXT_RED = 50;
	E_TEXT_PURPLE = 51;
	E_TEXT_YELLOW = 52;
	E_TEXT_WHITE = 53;
	{}
	E_TEXT_MIN = E_TEXT_BLUE;
	{}
	CATEGORY_ITEM = 1;
	CATEGORY_CREATURE = 2;
	CATEGORY_TERRAIN = 3;
	{}
	COLOR_SPECIAL_MIN = $F0;
	COLOR_CHOICE_ON_BLACK = $FF;
	COLOR_WHITE_ON_CHOICE = $FE;
	COLOR_CHOICE_ON_CHOICE = $FD;
	{}
	SHOT_SOURCE_PLAYER = 0;
	SHOT_SOURCE_ENEMY = 1;
	{}
	PROMPT_NUMERIC = 0;
	PROMPT_ALPHANUM = 1;
	PROMPT_ANY = 2;
type
	TString50 = string[50];
	TCoord = record
		X: integer;
		Y: integer;
	end;
	TTile = record
		Element: byte;
		Color: byte;
	end;
	TElementDrawProc = procedure(x, y: integer; var ch: byte);
	TElementTickProc = procedure(statId: integer);
	TElementTouchProc = procedure(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	TElementDef = record
		Character: char;
		Color: byte;
		Destructible: boolean;
		Pushable: boolean;
		VisibleInDark: boolean;
		PlaceableOnTop: boolean;
		Walkable: boolean;
		HasDrawProc: boolean;
		DrawProc: TElementDrawProc;
		Cycle: integer;
		TickProc: TElementTickProc;
		TouchProc: TElementTouchProc;
		EditorCategory: integer;
		EditorShortcut: char;
		Name: string[20];
		CategoryName: string[20];
		Param1Name: string[20];
		Param2Name: string[20];
		ParamBulletTypeName: string[20];
		ParamBoardName: string[20];
		ParamDirName: string[20];
		ParamTextName: string[20];
		ScoreValue: integer;
	end;
	TStat = record
		X, Y: byte;
		StepX, StepY: integer;
		Cycle: integer;
		P1, P2, P3: byte;
		Follower: integer;
		Leader: integer;
		Under: TTile;
		Data: ^string;
		DataPos: integer;
		DataLen: integer;
		unk1, unk2: pointer;
	end;
	TRleTile = record
		Count: byte;
		Tile: TTile;
	end;
	TBoardInfo = record
		MaxShots: byte;
		IsDark: boolean;
		NeighborBoards: array[0 .. 3] of byte;
		ReenterWhenZapped: boolean;
		Message: string[58];
		StartPlayerX: byte;
		StartPlayerY: byte;
		TimeLimitSec: integer;
		unk1: array[70 .. 85] of byte;
	end;
	TWorldInfo = record
		Ammo: integer;
		Gems: integer;
		Keys: array [1..7] of boolean;
		Health: integer;
		CurrentBoard: integer;
		Torches: integer;
		TorchTicks: integer;
		EnergizerTicks: integer;
		unk1: integer;
		Score: integer;
		Name: string[20];
		Flags: array[1 .. MAX_FLAG] of string[20];
		BoardTimeSec: integer;
		BoardTimeHsec: integer;
		IsSave: boolean;
		unkPad: array[0 .. 13] of byte;
	end;
	TEditorStatSetting = record
		P1, P2, P3: byte;
		StepX, StepY: integer;
	end;
	TBoard = record
		Name: TString50;
		Tiles: array[0 .. BOARD_WIDTH + 1] of array[0 .. BOARD_HEIGHT + 1] of TTile;
		StatCount: integer;
		Stats: array[0 .. MAX_STAT + 1] of TStat;
		Info: TBoardInfo;      
	end;
	TWorld = record
		BoardCount: integer;
		BoardData: array[0 .. MAX_BOARD] of pointer;
		BoardLen: array[0 .. MAX_BOARD] of integer;
		Info: TWorldInfo;
		EditorStatSettings: array[0 .. MAX_ELEMENT] of TEditorStatSetting;
	end;
	THighScoreEntry = record
		Name: TString50;
		Score: integer;
	end;
	THighScoreList = array[1 .. HIGH_SCORE_COUNT] of THighScoreEntry;
	TIoTmpBuf = array[0 .. 19999] of byte;
	TDrawMode = (DrawingOff, DrawingOn, TextEntry);
const
	ColorNames: array[1 .. 7] of string[8] =
		('Blue', 'Green', 'Cyan', 'Red', 'Purple', 'Yellow', 'White');
	{}
	DiagonalDeltaX: array[0 .. 7] of integer = (-1, 0, 1, 1, 1, 0, -1, -1);
	DiagonalDeltaY: array[0 .. 7] of integer = (1, 1, 1, 0, -1, -1, -1, 0);
	NeighborDeltaX: array[0 .. 3] of integer = (0, 0, -1, 1);
	NeighborDeltaY: array[0 .. 3] of integer = (-1, 1, 0, 0);
	{}
	TileBorder: TTile = (Element: E_NORMAL; Color: $0E);
	TileBoardEdge: TTile = (Element: E_BOARD_EDGE; Color: $00);
	StatTemplateDefault: TStat = (
		X: 0; Y: 0; StepX: 0; StepY: 0;
		Cycle: 0; P1: 0; P2: 0; P3: 0;
		Follower: -1; Leader: -1
	);
	LineChars: string[16] = #249#208#210#186#181#188#187#185#198#200#201#204#205#202#203#206;
	ProgressAnimColors: array[0 .. 7] of byte = ($14, $1C, $15, $1D, $16, $1E, $17, $1F);
	ProgressAnimStrings: array[0 .. 7] of string[5] =
		('....|', '...*/', '..*.-', '.*..\', '*...|', '..../', '....-', '....\');
	NeighborBoardStrs: array[0 .. 3] of string[20] =
		('       Board '#24, '       Board '#25, '       Board '#27, '       Board '#26);
	TransporterNSChars: string = '^~^-v_v-';
	TransporterEWChars: string = '(<('#179')>)'#179;
	StarAnimChars: string = #179'/'#196'\';
var
	unkVar_0472: integer;
	unkVar_0474: integer;

	TransitionTable: array[1 .. 80*25] of TCoord;
	LoadedGameFileName: TString50;
	SavedGameFileName: TString50;
	SavedBoardFileName: TString50;
	StartupWorldFileName: TString50;
	Board: TBoard;
	World: TWorld;
	MessageAmmoNotShown: boolean;
	MessageOutOfAmmoNotShown: boolean;
	MessageNoShootingNotShown: boolean;
	MessageTorchNotShown: boolean;
	MessageOutOfTorchesNotShown: boolean;
	MessageRoomNotDarkNotShown: boolean;
	MessageHintTorchNotShown: boolean;
	MessageForestNotShown: boolean;
	MessageFakeNotShown: boolean;
	MessageGemNotShown: boolean;
	MessageEnergizerNotShown: boolean;
	unkVar_4AB6: array[0 .. 14] of byte;

	GameTitleExitRequested: boolean;
	GamePlayExitRequested: boolean;
	GameStateElement: integer;
	ReturnBoardId: integer;

	TransitionTableSize: integer;
	TickSpeed: byte;

	IoTmpBuf: ^TIoTmpBuf;

	ElementDefs: array[0 .. MAX_ELEMENT] of TElementDef;
	EditorPatternCount: integer;
	EditorPatterns: array[1 .. 10] of byte;

	TickTimeDuration: integer;
	CurrentTick: integer;
	CurrentStatTicked: integer;
	GamePaused: boolean;
	TickTimeCounter: integer;

	ForceDarknessOff: boolean;
	InitialTextAttr: byte;

	OopChar: char;
	OopWord: string[20];
	OopValue: integer;

	DebugEnabled: boolean;

	HighScoreList: THighScoreList;
	ConfigRegistrant: string;
	ConfigWorldFile: TString50;
	EditorEnabled: boolean;
	JustStarted: boolean;

procedure InitElementsGame; forward;
procedure InitEditorStatSettings; forward;
procedure HighScoresLoad; forward;
procedure DrawPlayerSurroundings(x, y: integer; bombPhase: integer); forward;
function WorldGetFlagPosition(name: TString50): integer; forward;
procedure InitElementsEditor; forward;
procedure GameDebugPrompt; forward;
procedure WorldSetFlag(name: TString50); forward;
procedure WorldClearFlag(name: TString50); forward;
procedure ElementPushablePush(x, y: integer; deltaX, deltaY: integer); forward;
procedure ElementMove(oldX, oldY, newX, newY: integer); forward;

procedure SidebarClearLine(y: integer);
	begin
		VideoWriteText(60, y, $11, #179'                   ');
	end;

procedure SidebarClear;
	var
		i: integer;
	begin
		for i := 3 to 24 do
			SidebarClearLine(i);
	end;

procedure GenerateTransitionTable;
	var
		ix, iy: integer;
		t: TCoord;
	begin
		TransitionTableSize := 0;
		for iy := 1 to BOARD_HEIGHT do
			for ix := 1 to BOARD_WIDTH do begin
				TransitionTableSize := TransitionTableSize + 1;
				TransitionTable[TransitionTableSize].X := ix;
				TransitionTable[TransitionTableSize].Y := iy;
			end;

		{ shuffle }
		for ix := 1 to TransitionTableSize do begin
			iy := Random(TransitionTableSize) + 1;
			t := TransitionTable[iy];
			TransitionTable[iy] := TransitionTable[ix];
			TransitionTable[ix] := t;
		end;
	end;

procedure AdvancePointer(var address: pointer; count: integer);
	begin
		address := Ptr(Seg(address^), Ofs(address^) + count);
	end;

procedure BoardClose;
	var
		ix, iy: integer;
		ptr: pointer;
		rle: TRleTile;
	begin
		ptr := IoTmpBuf;

		Move(Board.Name, ptr^, SizeOf(Board.Name));
		AdvancePointer(ptr, SizeOf(Board.Name));

		ix := 1;
		iy := 1;
		rle.Count := 1;
		rle.Tile := Board.Tiles[ix][iy];
		repeat
			ix := ix + 1;
			if ix > BOARD_WIDTH then begin
				ix := 1;
				iy := iy + 1;
			end;
			if (Board.Tiles[ix][iy].Color = rle.Tile.Color) and
				(Board.Tiles[ix][iy].Element = rle.Tile.Element) and
				(rle.Count < 255) and (iy <= BOARD_HEIGHT) then
			begin
				rle.Count := rle.Count + 1;
			end else begin
				Move(rle, ptr^, SizeOf(rle));
				AdvancePointer(ptr, SizeOf(rle));
				rle.Tile := Board.Tiles[ix][iy];
				rle.Count := 1;
			end;
		until iy > BOARD_HEIGHT;

		Move(Board.Info, ptr^, SizeOf(Board.Info));
		AdvancePointer(ptr, SizeOf(Board.Info));

		Move(Board.StatCount, ptr^, SizeOf(Board.StatCount));
		AdvancePointer(ptr, SizeOf(Board.StatCount));

		for ix := 0 to Board.StatCount do begin
			with Board.Stats[ix] do begin
				if DataLen > 0 then begin
					for iy := 1 to (ix - 1) do begin
						if Board.Stats[iy].Data = Data then
							DataLen := -iy;
					end;
				end;
				Move(Board.Stats[ix], ptr^, SizeOf(TStat));
				AdvancePointer(ptr, SizeOf(TStat));
				if DataLen > 0 then begin
					Move(Data^, ptr^, DataLen);
					FreeMem(Data, DataLen);
					AdvancePointer(ptr, DataLen);
				end;
			end;
		end;

		FreeMem(World.BoardData[World.Info.CurrentBoard], World.BoardLen[World.Info.CurrentBoard]);
		World.BoardLen[World.Info.CurrentBoard] := Ofs(ptr^) - Ofs(IoTmpBuf^);
		GetMem(World.BoardData[World.Info.CurrentBoard], World.BoardLen[World.Info.CurrentBoard]);
		Move(IoTmpBuf^, World.BoardData[World.Info.CurrentBoard]^, World.BoardLen[World.Info.CurrentBoard]);
	end;

procedure BoardOpen(boardId: integer);
	var
		ptr: pointer;
		ix, iy: integer;
		rle: TRleTile;
	begin
		if boardId > World.BoardCount then
			boardId := World.Info.CurrentBoard;

		ptr := World.BoardData[boardId];

		Move(ptr^, Board.Name, SizeOf(Board.Name));
		AdvancePointer(ptr, SizeOf(Board.Name));

		ix := 1;
		iy := 1;
		rle.Count := 0;
		repeat
			if rle.Count <= 0 then begin
				Move(ptr^, rle, SizeOf(rle));
				AdvancePointer(ptr, SizeOf(rle));
			end;
			Board.Tiles[ix][iy] := rle.Tile;
			ix := ix + 1;
			if ix > BOARD_WIDTH then begin
				ix := 1;
				iy := iy + 1;
			end;
			rle.Count := rle.Count - 1;
		until iy > BOARD_HEIGHT;

		Move(ptr^, Board.Info, SizeOf(Board.Info));
		AdvancePointer(ptr, SizeOf(Board.Info));

		Move(ptr^, Board.StatCount, SizeOf(Board.StatCount));
		AdvancePointer(ptr, SizeOf(Board.StatCount));

		for ix := 0 to Board.StatCount do
			with Board.Stats[ix] do begin
				Move(ptr^, Board.Stats[ix], SizeOf(TStat));
				AdvancePointer(ptr, SizeOf(TStat));
				if DataLen > 0 then begin
					GetMem(Data, DataLen);
					Move(ptr^, Data^, DataLen);
					AdvancePointer(ptr, DataLen);
				end else if DataLen < 0 then begin
					Data := Board.Stats[-DataLen].Data;
					DataLen := Board.Stats[-DataLen].DataLen;
				end;
			end;

		World.Info.CurrentBoard := boardId;
	end;

procedure BoardChange(boardId: integer);
	begin
		Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Element := E_PLAYER;
		Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Color := ElementDefs[E_PLAYER].Color;
		BoardClose;
		BoardOpen(boardId);
	end;

procedure BoardCreate;
	var
		ix, iy, i: integer;
	begin
		Board.Name := '';
		Board.Info.Message := '';
		Board.Info.MaxShots := 255;
		Board.Info.IsDark := false;
		Board.Info.ReenterWhenZapped := false;
		Board.Info.TimeLimitSec := 0;
		for i := 0 to 3 do
			Board.Info.NeighborBoards[i] := 0;

		for ix := 0 to BOARD_WIDTH+1 do begin
			Board.Tiles[ix][0] := TileBoardEdge;
			Board.Tiles[ix][BOARD_HEIGHT+1] := TileBoardEdge;
		end;
		for iy := 0 to BOARD_HEIGHT+1 do begin
			Board.Tiles[0][iy] := TileBoardEdge;
			Board.Tiles[BOARD_WIDTH+1][iy] := TileBoardEdge;
		end;

		for ix := 1 to BOARD_WIDTH do
			for iy := 1 to BOARD_HEIGHT do begin
				Board.Tiles[ix][iy].Element := E_EMPTY;
				Board.Tiles[ix][iy].Color := 0;
			end;

		for ix := 1 to BOARD_WIDTH do begin
			Board.Tiles[ix][1] := TileBorder;
			Board.Tiles[ix][BOARD_HEIGHT] := TileBorder;
		end;
		for iy := 1 to BOARD_HEIGHT do begin
			Board.Tiles[1][iy] := TileBorder;
			Board.Tiles[BOARD_WIDTH][iy] := TileBorder;
		end;

		Board.Tiles[BOARD_WIDTH div 2][BOARD_HEIGHT div 2].Element := E_PLAYER;
		Board.Tiles[BOARD_WIDTH div 2][BOARD_HEIGHT div 2].Color := ElementDefs[E_PLAYER].Color;
		Board.StatCount := 0;
		Board.Stats[0].X := BOARD_WIDTH div 2;
		Board.Stats[0].Y := BOARD_HEIGHT div 2;
		Board.Stats[0].Cycle := 1;
		Board.Stats[0].Under.Element := E_EMPTY;
		Board.Stats[0].Under.Color := 0;
		Board.Stats[0].Data := nil;
		Board.Stats[0].DataLen := 0;
	end;

procedure ResetMessageNotShownFlags;
	begin
		MessageAmmoNotShown := true;
		MessageOutOfAmmoNotShown := true;
		MessageNoShootingNotShown := true;
		MessageTorchNotShown := true;
		MessageOutOfTorchesNotShown := true;
		MessageRoomNotDarkNotShown := true;
		MessageHintTorchNotShown := true;
		MessageForestNotShown := true;
		MessageFakeNotShown := true;
		MessageGemNotShown := true;
		MessageEnergizerNotShown := true;
	end;

procedure WorldCreate;
	var
		i: integer;
	begin
		InitElementsGame;
		World.BoardCount := 0;
		World.BoardLen[0] := 0;
		InitEditorStatSettings;
		ResetMessageNotShownFlags;
		BoardCreate;
		World.Info.IsSave := false;
		World.Info.CurrentBoard := 0;
		World.Info.Ammo := 0;
		World.Info.Gems := 0;
		World.Info.Health := 100;
		World.Info.EnergizerTicks := 0;
		World.Info.Torches := 0;
		World.Info.TorchTicks := 0;
		World.Info.Score := 0;
		World.Info.BoardTimeSec := 0;
		World.Info.BoardTimeHsec := 0;
		for i := 1 to 7 do
			World.Info.Keys[i] := false;
		for i := 1 to MAX_FLAG do
			World.Info.Flags[i] := '';
		BoardChange(0);
		Board.Name := 'Introduction screen';
		LoadedGameFileName := '';
		World.Info.Name := '';
	end;

procedure TransitionDrawToFill(chr: char; color: integer);
	var
		i: integer;
	begin
		for i := 1 to TransitionTableSize do
			VideoWriteText(TransitionTable[i].X - 1, TransitionTable[i].Y - 1, color, chr);
	end;

{$F+}

procedure BoardDrawTile(x, y: integer);
	var
		ch: byte;
	begin
		with Board.Tiles[x][y] do begin
			if not Board.Info.IsDark
				or (ElementDefs[Board.Tiles[x][y].Element].VisibleInDark)
				or (
					(World.Info.TorchTicks > 0)
					and ((Sqr(Board.Stats[0].X - x) + Sqr(Board.Stats[0].Y - y) * 2) < TORCH_DIST_SQR)
				) or ForceDarknessOff then
			begin
				if Element = E_EMPTY then
					VideoWriteText(x - 1, y - 1, $0F, ' ')
				else if ElementDefs[Element].HasDrawProc then begin
					ElementDefs[Element].DrawProc(x, y, ch);
					VideoWriteText(x - 1, y - 1, Color, Chr(ch));
				end else if Element < E_TEXT_MIN then
					VideoWriteText(x - 1, y - 1, Color, ElementDefs[Element].Character)
				else begin
					{ Text drawing }
					if Element = E_TEXT_WHITE then
						VideoWriteText(x - 1, y - 1, $0F, Chr(Board.Tiles[x][y].Color))
					else if VideoMonochrome then
						VideoWriteText(x - 1, y - 1, ((Element - E_TEXT_MIN) + 1) * 16, Chr(Board.Tiles[x][y].Color))
					else
						VideoWriteText(x - 1, y - 1, (((Element - E_TEXT_MIN) + 1) * 16) + $F, Chr(Board.Tiles[x][y].Color));
				end
			end else begin
				{ Darkness }
				VideoWriteText(x - 1, y - 1, $07, #176);
			end;
		end;
	end;

{$F-}

procedure BoardDrawBorder;
	var
		ix, iy: integer;
	begin
		for ix := 1 to BOARD_WIDTH do begin
			BoardDrawTile(ix, 1);
			BoardDrawTile(ix, BOARD_HEIGHT);
		end;

		for iy := 1 to BOARD_HEIGHT do begin
			BoardDrawTile(1, iy);
			BoardDrawTile(BOARD_WIDTH, iy);
		end;
	end;

procedure TransitionDrawToBoard;
	var
		i: integer;
	begin
		BoardDrawBorder;

		for i := 1 to TransitionTableSize do
			with TransitionTable[i] do
				BoardDrawTile(X, Y);
	end;

procedure SidebarPromptCharacter(editable: boolean; x, y: integer; prompt: TString50; var value: byte);
	var
		i, newValue: integer;
	begin
		SidebarClearLine(y);
		VideoWriteText(x, y, Integer(editable) + $1E, prompt);
		SidebarClearLine(y + 1);
		VideoWriteText(x + 5, y + 1, $9F, #31);
		SidebarClearLine(y + 2);

		repeat
			for i := (value - 4) to (value + 4) do
				VideoWriteText(((x + i) - value) + 5, y + 2, $1E, Chr((i + $100) mod $100));

			if editable then begin
				Delay(25);
				InputUpdate;
				if InputKeyPressed = KEY_TAB then
					InputDeltaX := 9;

				newValue := value + InputDeltaX;
				if value <> newValue then begin
					value := (newValue + $100) mod $100;
					SidebarClearLine(y + 2);
				end;
			end;
		until (InputKeyPressed = KEY_ENTER) or (InputKeyPressed = KEY_ESCAPE) or not editable or InputShiftPressed;

		VideoWriteText(x + 5, y + 1, $1F, #31);
	end;

procedure SidebarPromptSlider(editable: boolean; x, y: integer; prompt: string; var value: byte);
	var
		newValue: integer;
		startChar, endChar: char;
	begin
		if prompt[Length(prompt) - 2] = ';' then begin
			startChar := prompt[Length(prompt) - 1];
			endChar := prompt[Length(prompt)];
			prompt := Copy(prompt, 1, Length(prompt) - 3);
		end else begin
			startChar := '1';
			endChar := '9';
		end;

		SidebarClearLine(y);
		VideoWriteText(x, y, Integer(editable) + $1E, prompt);
		SidebarClearLine(y + 1);
		SidebarClearLine(y + 2);
		VideoWriteText(x, y + 2, $1e, startChar + '....:....' + endChar);

		repeat
			if editable then begin
				if InputJoystickMoved then
					Delay(45);
				VideoWriteText(x + value + 1, y + 1, $9F, #31);

				InputUpdate;
				if (InputKeyPressed >= '1') and (InputKeyPressed <= '9') then begin
					value := Ord(InputKeyPressed) - 49;
					SidebarClearLine(y + 1);
				end else begin
					newValue := value + InputDeltaX;
					if (value <> newValue) and (newValue >= 0) and (newValue <= 8) then begin
						value := newValue;
						SidebarClearLine(y + 1);
					end;
				end;
			end;
		until (InputKeyPressed = KEY_ENTER) or (InputKeyPressed = KEY_ESCAPE) or not editable or InputShiftPressed;

		VideoWriteText(x + value + 1, y + 1, $1F, #31);
	end;

procedure SidebarPromptChoice(editable: boolean; y: integer; prompt, choiceStr: string; var result: byte);
	var
		i, j, choiceCount: integer;
		newResult: integer;
	begin
		SidebarClearLine(y);
		SidebarClearLine(y + 1);
		SidebarClearLine(y + 2);
		VideoWriteText(63, y, Integer(editable) + $1E, prompt);
		VideoWriteText(63, y + 2, $1E, choiceStr);

		choiceCount := 1;
		for i := 1 to Length(choiceStr) do
			if choiceStr[i] = ' ' then
				choiceCount := choiceCount + 1;

		repeat
			j := 0;
			i := 1;
			while (j < result) and (i < Length(choiceStr)) do begin
				if choiceStr[i] = ' ' then
					j := j + 1;
				i := i + 1;
			end;

			if editable then begin
				VideoWriteText(62 + i, y + 1, $9F, #31);
				Delay(35);
				InputUpdate;

				newResult := result + InputDeltaX;
				if (result <> newResult) and (newResult >= 0) and (newResult <= (choiceCount - 1)) then begin
					result := newResult;
					SidebarClearLine(y + 1);
				end;
			end;
		until (InputKeyPressed = KEY_ENTER) or (InputKeyPressed = KEY_ESCAPE) or not editable or InputShiftPressed;

		VideoWriteText(62 + i, y + 1, $1F, #31);
	end;

procedure SidebarPromptDirection(editable: boolean; y: integer; prompt: string; var deltaX, deltaY: integer);
	var
		choice: byte;
	begin
		if deltaY = -1 then
			choice := 0
		else if deltaY = 1 then
			choice := 1
		else if deltaX = -1 then
			choice := 2
		else
			choice := 3;
		SidebarPromptChoice(editable, y, prompt, #24' '#25' '#27' '#26, choice);
		deltaX := NeighborDeltaX[choice];
		deltaY := NeighborDeltaY[choice];
	end;

procedure PromptString(x, y, arrowColor, color, width: integer; mode: byte; var buffer: TString50);
	var
		i: integer;
		oldBuffer: string;
		firstKeyPress: boolean;
	begin
		oldBuffer := buffer;
		firstKeyPress := true;

		repeat
			for i := 0 to (width - 1) do begin
				VideoWriteText(x + i, y, color, ' ');
				VideoWriteText(x + i, y - 1, arrowColor, ' ');
			end;
			VideoWriteText(x + width, y - 1, arrowColor, ' ');
			VideoWriteText(x + Length(buffer), y - 1, (arrowColor div $10) * 16 + $0F, #31);
			VideoWriteText(x, y, color, buffer);

			InputReadWaitKey;

			if (Length(buffer) < width) and (InputKeyPressed >= #32) and (InputKeyPressed < #128) then begin
				if firstKeyPress then
					buffer := '';
				case mode of
					PROMPT_NUMERIC: begin
						if (InputKeyPressed in ['0' .. '9']) then begin
							buffer := buffer + InputKeyPressed;
						end;
					end;
					PROMPT_ANY: begin
						buffer := buffer + InputKeyPressed;
					end;
					PROMPT_ALPHANUM: begin
						if (UpCase(InputKeyPressed) in ['A' .. 'Z'])
							or (InputKeyPressed in ['0' .. '9'])
							or (InputKeyPressed = '-') then
						begin
							buffer := buffer + UpCase(InputKeyPressed);
						end;
					end;
				end;
			end else if (InputKeyPressed = KEY_LEFT) or (InputKeyPressed = KEY_BACKSPACE) then begin
				buffer := Copy(buffer, 1, Length(buffer) - 1);
			end;

			firstKeyPress := false;
		until (InputKeyPressed = KEY_ENTER) or (InputKeyPressed = KEY_ESCAPE);
		if InputKeyPressed = KEY_ESCAPE then begin
			buffer := oldBuffer;
		end;
	end;

function SidebarPromptYesNo(message: string; defaultReturn: boolean): boolean;
	begin
		SidebarClearLine(3);
		SidebarClearLine(4);
		SidebarClearLine(5);
		VideoWriteText(63, 5, $1F, message);
		VideoWriteText(63 + Length(message), 5, $9E, '_');

		repeat
			InputReadWaitKey;
		until UpCase(InputKeyPressed) in [KEY_ESCAPE, 'N', 'Y'];
		if UpCase(InputKeyPressed) = 'Y' then
			defaultReturn := true
		else
			defaultReturn := false;

		SidebarClearLine(5);
		SidebarPromptYesNo := defaultReturn;
	end;

procedure SidebarPromptString(prompt: string; extension: TString50; var filename: string; promptMode: byte);
	begin
		SidebarClearLine(3);
		SidebarClearLine(4);
		SidebarClearLine(5);
		VideoWriteText(75 - Length(prompt), 3, $1F, prompt);
		VideoWriteText(63, 5, $0F, '        ' + extension);

		PromptString(63, 5, $1E, $0F, 8, promptMode, filename);

		SidebarClearLine(3);
		SidebarClearLine(4);
		SidebarClearLine(5);
	end;

procedure PauseOnError;
	begin
		SoundQueue(1, SoundParse('s004x114x9'));
		Delay(2000);
	end;

function DisplayIOError: boolean;
	var
		errorMsg: TString50;
	begin
		if IOResult = 0 then begin
			DisplayIOError := false;
			exit;
		end;

		case IOResult of
			2: errorMsg := 'File not found!';
			3: errorMsg := 'Path not found!';
			101: errorMsg := 'Disk full!';
		else errorMsg := 'DOS Error!' end;
		SidebarClearLine(5);
		VideoWriteText(63, 5, $1F, errorMsg);
		PauseOnError;
		DisplayIOError := true;
	end;

procedure WorldUnload;
	var
		i: integer;
	begin
		BoardClose;
		for i := 0 to World.BoardCount do
			FreeMem(World.BoardData[i], World.BoardLen[i]);
	end;

function WorldLoad(filename, extension: TString50; titleOnly: boolean): boolean;
	var
		f: file;
		ptr: pointer;
		boardId: integer;
		loadProgress: integer;
	procedure SidebarAnimateLoading;
		begin
			VideoWriteText(69, 5, ProgressAnimColors[loadProgress], ProgressAnimStrings[loadProgress]);
			loadProgress := (loadProgress + 1) mod 8;
		end;
	begin
		WorldLoad := false;
		loadProgress := 0;

		SidebarClearLine(4);
		SidebarClearLine(5);
		SidebarClearLine(5);
		VideoWriteText(62, 5, $1F, 'Loading.....');

		Assign(f, filename + extension);
		Reset(f, 1);

		if not DisplayIOError then begin
			WorldUnload;
			BlockRead(f, IoTmpBuf^, WORLD_FILE_HEADER_SIZE);

			if not DisplayIOError then begin
				ptr := IoTmpBuf;
				Move(ptr^, World.BoardCount, SizeOf(World.BoardCount));
				AdvancePointer(ptr, SizeOf(World.BoardCount));

				if World.BoardCount < 0 then begin
					if World.BoardCount <> -1 then begin
						VideoWriteText(63, 5, $1E, 'You need a newer');
						VideoWriteText(63, 6, $1E, ' version of ZZT!');
						exit;
					end else begin
						Move(ptr^, World.BoardCount, SizeOf(World.BoardCount));
						AdvancePointer(ptr, SizeOf(World.BoardCount));
					end;
				end;

				Move(ptr^, World.Info, SizeOf(World.Info));
				AdvancePointer(ptr, SizeOf(World.Info));

				if titleOnly then begin
					World.BoardCount := 0;
					World.Info.CurrentBoard := 0;
					World.Info.IsSave := true;
				end;

				for boardId := 0 to World.BoardCount do begin
					SidebarAnimateLoading;
					BlockRead(f, World.BoardLen[boardId], 2);
					GetMem(World.BoardData[boardId], World.BoardLen[boardId]);
					BlockRead(f, World.BoardData[boardId]^, World.BoardLen[boardId]);
				end;

				Close(f);

				BoardOpen(World.Info.CurrentBoard);
				LoadedGameFileName := filename;
				WorldLoad := true;

				HighScoresLoad;

				SidebarClearLine(5);
			end;
		end;
	end;

procedure WorldSave(filename, extension: TString50);
	var
		f: file;
		i: integer;
		unk1: integer;
		ptr: pointer;
		version: integer;
	begin
		BoardClose;
		VideoWriteText(63, 5, $1F, 'Saving...');

		Assign(f, filename + extension);
		Rewrite(f, 1);
		if DisplayIOError then exit;

		ptr := IoTmpBuf;
		FillChar(IoTmpBuf^, WORLD_FILE_HEADER_SIZE, 0);
		version := -1;
		Move(version, ptr^, SizeOf(version));
		AdvancePointer(ptr, SizeOf(version));

		Move(World.BoardCount, ptr^, SizeOf(World.BoardCount));
		AdvancePointer(ptr, SizeOf(World.BoardCount));

		Move(World.Info, ptr^, SizeOf(World.Info));
		AdvancePointer(ptr, SizeOf(World.Info));

		BlockWrite(f, IoTmpBuf^, WORLD_FILE_HEADER_SIZE);
		if DisplayIOError then exit;

		for i := 0 to World.BoardCount do begin
			BlockWrite(f, World.BoardLen[i], 2);
			if DisplayIOError then exit;

			BlockWrite(f, World.BoardData[i]^, World.BoardLen[i]);
			if DisplayIOError then exit;
		end;

		Close(f);
		BoardOpen(World.Info.CurrentBoard);
		SidebarClearLine(5);
	end;

procedure GameWorldSave(prompt: TString50; var filename: TString50; extension: TString50);
	var
		newFilename: TString50;
	begin
		newFilename := filename;
		SidebarPromptString(prompt, extension, newFilename, PROMPT_ALPHANUM);
		if (InputKeyPressed <> KEY_ESCAPE) and (Length(newFilename) <> 0) then begin
			filename := newFilename;
			if extension = '.ZZT' then
				World.Info.Name := filename;
			WorldSave(filename, extension);
		end;
	end;

function GameWorldLoad(extension: TString50): boolean;
	var
		textWindow: TTextWindowState;
		fileSearchRec: SearchRec;
		entryName: string;
	begin
		if extension = '.ZZT' then
			textWindow.Title := 'ZZT Worlds'
		else
			textWindow.Title := 'Saved Games';
		GameWorldLoad := false;
		textWindow.LinePos := 1;
		textWindow.Selectable := true;
		textWindow.LineCount := 0;

		FindFirst('*' + extension, AnyFile, fileSearchRec);
		while DosError = 0 do begin
			entryName := Copy(fileSearchRec.Name, 1, Length(fileSearchRec.name) - 4);
			if entryName = 'TOWN' then
				entryName := 'TOWN       The Town of ZZT';
			if entryName = 'DEMO' then
				entryName := 'DEMO       Demo of the ZZT World Editor';
			if entryName = 'CAVES' then
				entryName := 'CAVES      The Caves of ZZT';
			if entryName = 'DUNGEONS' then
				entryName := 'DUNGEONS   The Dungeons of ZZT';
			if entryName = 'CITY' then
				entryName := 'CITY       Underground City of ZZT';
			if entryName = 'BEST' then
				entryName := 'BEST       The Best of ZZT';
			if entryName = 'PHYSICS' then
				entryName := 'PHYSICS    The Physics Behind ZZT';
			if entryName = 'TOUR' then
				entryName := 'TOUR       Guided Tour ZZT''s Other Worlds';
			TextWindowAppend(textWindow, entryName);
			FindNext(fileSearchRec);
		end;
		TextWindowAppend(textWindow, 'Exit');

		TextWindowDrawOpen(textWindow);
		TextWindowSelect(textWindow, false, false);
		TextWindowDrawClose;

		if (textWindow.LinePos < textWindow.LineCount) and not TextWindowRejected then begin
			entryName := textWindow.Lines[textWindow.LinePos]^;
			if Pos(' ', entryName) <> 0 then
				entryName := Copy(entryName, 1, Pos(' ', entryName) - 1);

			GameWorldLoad := WorldLoad(entryName, extension, false);
			TransitionDrawToFill(#219, $44);
		end;

		TextWindowFree(textWindow);
	end;

procedure EditorOpenEditTextWindow(var state: TTextWindowState);
	begin
		SidebarClear;
		VideoWriteText(61, 4, $30, ' Return ');
		VideoWriteText(64, 5, $1F, ' Insert line');
		VideoWriteText(61, 7, $70, ' Ctrl-Y ');
		VideoWriteText(64, 8, $1F, ' Delete line');
		VideoWriteText(61, 10, $30, ' Cursor keys ');
		VideoWriteText(64, 11, $1F, ' Move cursor');
		VideoWriteText(61, 13, $70, ' Insert ');
		VideoWriteText(64, 14, $1F, ' Insert mode: ');
		VideoWriteText(61, 16, $30, ' Delete ');
		VideoWriteText(64, 17, $1F, ' Delete char');
		VideoWriteText(61, 19, $70, ' Escape ');
		VideoWriteText(64, 20, $1F, ' Exit editor');
		TextWindowEdit(state);
	end;

procedure EditorEditHelpFile;
	var
		textWindow: TTextWindowState;
		filename: TString50;
	begin
		filename := '';
		SidebarPromptString('File to edit', '.HLP', filename, PROMPT_ALPHANUM);
		if Length(filename) <> 0 then begin
			TextWindowOpenFile(filename + '.HLP', textWindow);
			textWindow.Title := 'Editing ' + filename;
			TextWindowDrawOpen(textWindow);
			EditorOpenEditTextWindow(textWindow);
			TextWindowSaveFile(filename + '.HLP', textWindow);
			TextWindowFree(textWindow);
			TextWindowDrawClose;
		end;
	end;

procedure CopyStatDataToTextWindow(statId: integer; var state: TTextWindowState);
	var
		dataStr: string;
		dataPtr: pointer;
		dataChr: char;
		i: integer;
	begin
		with Board.Stats[statId] do begin
			state.LineCount := 0;
			dataStr := '';
			dataPtr := Data;

			for i := 0 to DataLen do begin
				Move(dataPtr^, dataChr, 1);
				if dataChr = KEY_ENTER then begin
					TextWindowAppend(state, dataStr);
					dataStr := '';
				end else begin
					dataStr := dataStr + dataChr;
				end;
				AdvancePointer(dataPtr, 1);
			end;
		end;
	end;

procedure AddStat(tx, ty: integer; element: byte; color, tcycle: integer; template: TStat);
	begin
		if Board.StatCount < MAX_STAT then begin
			Board.StatCount := Board.StatCount + 1;
			Board.Stats[Board.StatCount] := template;
			with Board.Stats[Board.StatCount] do begin
				X := tx;
				Y := ty;
				Cycle := tcycle;
				Under := Board.Tiles[tx][ty];
				DataPos := 0;
			end;

			if template.Data <> nil then begin
				GetMem(Board.Stats[Board.StatCount].Data, template.DataLen);
				Move(template.Data^, Board.Stats[Board.StatCount].Data^, template.DataLen);
			end;

			if ElementDefs[Board.Tiles[tx][ty].Element].PlaceableOnTop then
				Board.Tiles[tx][ty].Color := (color and $0F) + (Board.Tiles[tx][ty].Color and $70)
			else
				Board.Tiles[tx][ty].Color := color;
			Board.Tiles[tx][ty].Element := element;

			if ty > 0 then
				BoardDrawTile(tx, ty);
		end;
	end;

procedure RemoveStat(statId: integer);
	var
		i: integer;
	label StatDataInUse;
	begin
		with Board.Stats[statId] do begin
			if DataLen <> 0 then begin
				for i := 1 to Board.StatCount do begin
					if (Board.Stats[i].Data = Data) and (i <> statId) then
						goto StatDataInUse;
				end;
				FreeMem(Data, DataLen);
			end;

		StatDataInUse:
			if statId < CurrentStatTicked then
				CurrentStatTicked := CurrentStatTicked - 1;

			Board.Tiles[X][Y] := Under;
			if Y > 0 then
				BoardDrawTile(X, Y);

			for i := 1 to Board.StatCount do begin
				if Board.Stats[i].Follower >= statId then begin
					if Board.Stats[i].Follower = statId then
						Board.Stats[i].Follower := -1
					else
						Board.Stats[i].Follower := Board.Stats[i].Follower - 1;
				end;

				if Board.Stats[i].Leader >= statId then begin
					if Board.Stats[i].Leader = statId then
						Board.Stats[i].Leader := -1
					else
						Board.Stats[i].Leader := Board.Stats[i].Leader - 1;
				end;
			end;

			for i := (statId + 1) to Board.StatCount do
				Board.Stats[i - 1] := Board.Stats[i];
			Board.StatCount := Board.StatCount - 1;
		end;
	end;

function GetStatIdAt(x, y: integer): integer;
	var
		i: integer;
	begin
		i := -1;
		repeat
			i := i + 1;
		until ((Board.Stats[i].X = x) and (Board.Stats[i].Y = y)) or (i > Board.StatCount);

		if i > Board.StatCount then
			GetStatIdAt := -1
		else
			GetStatIdAt := i;
	end;

function BoardPrepareTileForPlacement(x, y: integer): boolean;
	var
		statId: integer;
		result: boolean;
	begin
		statId := GetStatIdAt(x, y);
		if statId > 0 then begin
			RemoveStat(statId);
			result := true;
		end else if statId < 0 then begin
			if not ElementDefs[Board.Tiles[x][y].Element].PlaceableOnTop then
				Board.Tiles[x][y].Element := E_EMPTY;
			result := true;
		end else begin { statId = 0 (player) cannot be modified }
			result := false;
		end;
		BoardDrawTile(x, y);
		BoardPrepareTileForPlacement := result;
	end;

procedure MoveStat(statId: integer; newX, newY: integer);
	var
		iUnder: TTile;
		ix, iy: integer;
		oldX, oldY: integer;
		oldBgColor: integer;
	begin
		with Board.Stats[statId] do begin
			oldBgColor := Board.Tiles[newX][newY].Color and $F0;

			iUnder := Board.Stats[statId].Under;
			Board.Stats[statId].Under := Board.Tiles[newX][newY];

			if Board.Tiles[X][Y].Element = E_PLAYER then
				Board.Tiles[newX][newY].Color := Board.Tiles[X][Y].Color
			else if Board.Tiles[newX][newY].Element = E_EMPTY then
				Board.Tiles[newX][newY].Color := Board.Tiles[X][Y].Color and $0F
			else
				Board.Tiles[newX][newY].Color := (Board.Tiles[X][Y].Color and $0F) + (Board.Tiles[newX][newY].Color and $70);

			Board.Tiles[newX][newY].Element := Board.Tiles[X][Y].Element;
			Board.Tiles[X][Y] := iUnder;

			oldX := X;
			oldY := Y;
			X := newX;
			Y := newY;

			BoardDrawTile(X, Y);
			BoardDrawTile(oldX, oldY);

			if (statId = 0) and Board.Info.IsDark and (World.Info.TorchTicks > 0) then begin
				if (Sqr(oldX-X) + Sqr(oldY-Y)) = 1 then begin
					for ix := (X - TORCH_DX - 3) to (X + TORCH_DX + 3) do
						if (ix >= 1) and (ix <= BOARD_WIDTH) then
							for iy := (Y - TORCH_DY - 3) to (Y + TORCH_DY + 3) do
								if (iy >= 1) and (iy <= BOARD_HEIGHT) then
									if (((Sqr(ix-oldX))+(Sqr(iy-oldY)*2)) < TORCH_DIST_SQR) xor
										(((Sqr(ix-newX))+(Sqr(iy-newY)*2)) < TORCH_DIST_SQR) then
										BoardDrawTile(ix, iy);
				end else begin
					DrawPlayerSurroundings(oldX, oldY, 0);
					DrawPlayerSurroundings(X, Y, 0);
				end;
			end;

		end;
	end;

function EditorGetBoardName(boardId: integer; titleScreenIsNone: boolean): TString50;
	var
		boardData: pointer;
		copiedName: TString50;
	begin
		if (boardId = 0) and titleScreenIsNone then
			EditorGetBoardName := 'None'
		else if (boardId = World.Info.CurrentBoard) then
			EditorGetBoardName := Board.Name
		else begin
			boardData := World.BoardData[boardId];
			Move(boardData^, copiedName, SizeOf(copiedName));
			EditorGetBoardName := copiedName;
		end;
	end;

function EditorSelectBoard(title: string; currentBoard: integer; titleScreenIsNone: boolean): integer;
	var
		unk1: string;
		i: integer;
		unk2: integer;
		textWindow: TTextWindowState;
	begin
		textWindow.Title := title;
		textWindow.LinePos := currentBoard + 1;
		textWindow.Selectable := true;
		textWindow.LineCount := 0;
		for i := 0 to World.BoardCount do begin
			TextWindowAppend(textWindow, EditorGetBoardName(i, titleScreenIsNone));
		end;
		TextWindowAppend(textWindow, 'Add new board');
		TextWindowDrawOpen(textWindow);
		TextWindowSelect(textWindow, false, false);
		TextWindowDrawClose;
		TextWindowFree(textWindow);
		if InputKeyPressed = KEY_ESCAPE then
			EditorSelectBoard := 0
		else
			EditorSelectBoard := textWindow.LinePos - 1;
	end;

procedure PopupPromptString(question: string; var buffer: TString50);
	var
		x, y: integer;
	begin
		VideoWriteText(3, 18, $4F, TEXT_WINDOW_STR_TOP);
		VideoWriteText(3, 19, $4F, TEXT_WINDOW_STR_TEXT);
		VideoWriteText(3, 20, $4F, TEXT_WINDOW_STR_SEP);
		VideoWriteText(3, 21, $4F, TEXT_WINDOW_STR_TEXT);
		VideoWriteText(3, 22, $4F, TEXT_WINDOW_STR_TEXT);
		VideoWriteText(3, 23, $4F, TEXT_WINDOW_STR_BOTTOM);
		VideoWriteText(4 + (TEXT_WINDOW_WIDTH - Length(question)) div 2, 19, $4F, question);
		buffer := '';
		PromptString(10, 22, $4F, $4E, TEXT_WINDOW_WIDTH - 16, PROMPT_ANY, buffer);
		for y := 18 to 23 do
			for x := 3 to (TEXT_WINDOW_WIDTH + 3) do
				BoardDrawTile(x + 1, y + 1);
	end;

procedure EditorAppendBoard;
	begin
		if World.BoardCount < MAX_BOARD then begin
			BoardClose;

			World.BoardCount := World.BoardCount + 1;
			World.Info.CurrentBoard := World.BoardCount;
			World.BoardLen[World.BoardCount] := 0;
			BoardCreate;

			TransitionDrawToBoard;

			repeat
				PopupPromptString('Room'#39's Title:', Board.Name);
			until Length(Board.Name) <> 0;

			TransitionDrawToBoard;
		end;
	end;

procedure EditorLoop;
	var
		selectedCategory: integer;
		elemMenuColor: integer;
		wasModified: boolean;
		editorExitRequested: boolean;
		drawMode: TDrawMode;
		cursorX, cursorY: integer;
		cursorPattern, cursorColor: integer;
		i, iElem: integer;
		canModify: boolean;
		unk1: array[0 .. 49] of byte;
		copiedStat: TStat;
		copiedHasStat: boolean;
		copiedTile: TTile;
		copiedX, copiedY: integer;
		cursorBlinker: integer;

	procedure EditorDrawSidebar;
		var
			i: integer;
			copiedChr: byte;
		begin
			SidebarClear;
			SidebarClearLine(1);
			VideoWriteText(61, 0, $1F, '     - - - -       ');
			VideoWriteText(62, 1, $70, '  ZZT Editor   ');
			VideoWriteText(61, 2, $1F, '     - - - -       ');
			VideoWriteText(61, 4, $70, ' L ');
			VideoWriteText(64, 4, $1F, ' Load');
			VideoWriteText(61, 5, $30, ' S ');
			VideoWriteText(64, 5, $1F, ' Save');
			VideoWriteText(70, 4, $70, ' H ');
			VideoWriteText(73, 4, $1E, ' Help');
			VideoWriteText(70, 5, $30, ' Q ');
			VideoWriteText(73, 5, $1F, ' Quit');
			VideoWriteText(61, 7, $70, ' B ');
			VideoWriteText(65, 7, $1F, ' Switch boards');
			VideoWriteText(61, 8, $30, ' I ');
			VideoWriteText(65, 8, $1F, ' Board Info');
			VideoWriteText(61, 10, $70, '  f1   ');
			VideoWriteText(68, 10, $1F, ' Item');
			VideoWriteText(61, 11, $30, '  f2   ');
			VideoWriteText(68, 11, $1F, ' Creature');
			VideoWriteText(61, 12, $70, '  f3   ');
			VideoWriteText(68, 12, $1F, ' Terrain');
			VideoWriteText(61, 13, $30, '  f4   ');
			VideoWriteText(68, 13, $1F, ' Enter text');
			VideoWriteText(61, 15, $70, ' Space ');
			VideoWriteText(68, 15, $1F, ' Plot');
			VideoWriteText(61, 16, $30, '  Tab  ');
			VideoWriteText(68, 16, $1F, ' Draw mode');
			VideoWriteText(61, 18, $70, ' P ');
			VideoWriteText(64, 18, $1F, ' Pattern');
			VideoWriteText(61, 19, $30, ' C ');
			VideoWriteText(64, 19, $1F, ' Color:');

			{ Colors }
			for i := 9 to 15 do
				VideoWriteText(61 + i, 22, i, #219);

			{ Patterns }
			for i := 1 to EditorPatternCount do
				VideoWriteText(61 + i, 22, $0F, ElementDefs[EditorPatterns[i]].Character);

			if ElementDefs[copiedTile.Element].HasDrawProc then
				ElementDefs[copiedTile.Element].DrawProc(copiedX, copiedY, copiedChr)
			else
				copiedChr := Ord(ElementDefs[copiedTile.Element].Character);
			VideoWriteText(62 + EditorPatternCount, 22, copiedTile.Color, Chr(copiedChr));

			VideoWriteText(61, 24, $1F, ' Mode:');
		end;

	procedure EditorDrawTileAndNeighborsAt(x, y: integer);
		var
			i, ix, iy: integer;
		begin
			BoardDrawTile(x, y);
			for i := 0 to 3 do begin
				ix := x + NeighborDeltaX[i];
				iy := y + NeighborDeltaY[i];
				if (ix >= 1) and (ix <= BOARD_WIDTH) and (iy >= 1) and (iy <= BOARD_HEIGHT) then
					BoardDrawTile(ix, iy);
			end;
		end;

	procedure EditorUpdateSidebar;
		begin
			if drawMode = DrawingOn then
				VideoWriteText(68, 24, $9E, 'Drawing on ')
			else if drawMode = TextEntry then
				VideoWriteText(68, 24, $9E, 'Text entry ')
			else if drawMode = DrawingOff then
				VideoWriteText(68, 24, $1E, 'Drawing off');

			VideoWriteText(72, 19, $1E, ColorNames[cursorColor - 8]);
			VideoWriteText(61 + cursorPattern, 21, $1F, #31);
			VideoWriteText(61 + cursorColor, 21, $1F, #31);
		end;

	procedure EditorDrawRefresh;
		var
			boardNumStr: string;
		begin
			BoardDrawBorder;
			EditorDrawSidebar;
			Str(World.Info.CurrentBoard, boardNumStr);
			TransitionDrawToBoard;

			if Length(Board.Name) <> 0 then
				VideoWriteText((59 - Length(Board.Name)) div 2, 0, $70, ' ' + Board.Name + ' ')
			else
				VideoWriteText(26, 0, $70, ' Untitled ');
		end;

	procedure EditorSetAndCopyTile(x, y, element, color: byte);
		begin
			Board.Tiles[x][y].Element := element;
			Board.Tiles[x][y].Color := color;

			copiedTile := Board.Tiles[x][y];
			copiedHasStat := false;
			copiedX := x;
			copiedY := y;

			EditorDrawTileAndNeighborsAt(x, y);
		end;

	procedure EditorAskSaveChanged;
		begin
			InputKeyPressed := #0;
			if wasModified then
				if SidebarPromptYesNo('Save first? ', true) then
					if InputKeyPressed <> KEY_ESCAPE then
						GameWorldSave('Save world', LoadedGameFileName, '.SAV');
			World.Info.Name := LoadedGameFileName;
		end;

	function EditorPrepareModifyTile(x, y: integer): boolean;
		begin
			wasModified := true;
			EditorPrepareModifyTile := BoardPrepareTileForPlacement(x, y);
			EditorDrawTileAndNeighborsAt(x, y);
		end;

	function EditorPrepareModifyStatAtCursor: boolean;
		begin
			if Board.StatCount < MAX_STAT then
				EditorPrepareModifyStatAtCursor := EditorPrepareModifyTile(cursorX, cursorY)
			else
				EditorPrepareModifyStatAtCursor := false;
		end;

	procedure EditorPlaceTile(x, y: integer);
		begin
			with Board.Tiles[x][y] do begin
				if cursorPattern <= EditorPatternCount then begin
					if EditorPrepareModifyTile(x, y) then begin
						Element := EditorPatterns[cursorPattern];
						Color := cursorColor;
					end;
				end else if copiedHasStat then begin
					if EditorPrepareModifyStatAtCursor then begin
						AddStat(x, y, copiedTile.Element, copiedTile.Color, copiedStat.Cycle, copiedStat);
					end
				end else begin
					if EditorPrepareModifyTile(x, y) then begin
						Board.Tiles[x][y] := copiedTile;
					end;
				end;

				EditorDrawTileAndNeighborsAt(x, y);
			end;
		end;

	procedure EditorEditBoardInfo;
		var
			state: TTextWindowState;
			i: integer;
			numStr: TString50;
			exitRequested: boolean;

		function BoolToString(val: boolean): string;
			begin
				if val then
					BoolToString := 'Yes'
				else
					BoolToString := 'No ';
			end;

		begin
			state.Title := 'Board Information';
			TextWindowDrawOpen(state);
			state.LinePos := 1;
			state.LineCount := 9;
			state.Selectable := true;
			exitRequested := false;
			for i := 1 to state.LineCount do
				New(state.Lines[i]);

			repeat
				state.Selectable := true;
				state.LineCount := 10;
				for i := 1 to state.LineCount do
					New(state.Lines[i]);

				state.Lines[1]^ := '         Title: ' + Board.Name;

				Str(Board.Info.MaxShots, numStr);
				state.Lines[2]^ := '      Can fire: ' + numStr + ' shots.';

				state.Lines[3]^ := ' Board is dark: ' + BoolToString(Board.Info.IsDark);

				for i := 4 to 7 do begin
					state.Lines[i]^ := NeighborBoardStrs[i - 4] + ': ' +
						EditorGetBoardName(Board.Info.NeighborBoards[i - 4], true);
				end;

				state.Lines[8]^ := 'Re-enter when zapped: ' + BoolToString(Board.Info.ReenterWhenZapped);

				Str(Board.Info.TimeLimitSec, numStr);
				state.Lines[9]^ := '  Time limit, 0=None: ' + numStr + ' sec.';

				state.Lines[10]^ := '          Quit!';

				TextWindowSelect(state, false, false);
				if (InputKeyPressed = KEY_ENTER) and (state.LinePos >= 1) and (state.LinePos <= 8) then
					wasModified := true;
				if (InputKeyPressed = KEY_ENTER) then
					case state.LinePos of
						1: begin
							PopupPromptString('New title for board:', Board.Name);
							exitRequested := true;
							TextWindowDrawClose;
						end;
						2: begin
							Str(Board.Info.MaxShots, numStr);
							SidebarPromptString('Maximum shots?', '', numStr, PROMPT_NUMERIC);
							if Length(numStr) <> 0 then
								Val(numStr, Board.Info.MaxShots, i);
							EditorDrawSidebar;
						end;
						3: begin
							Board.Info.IsDark := not Board.Info.IsDark;
						end;
						4, 5, 6, 7: begin
							Board.Info.NeighborBoards[state.LinePos - 4]
								:= EditorSelectBoard(
									NeighborBoardStrs[state.LinePos - 4],
									Board.Info.NeighborBoards[state.LinePos - 4],
									true
								);
							if Board.Info.NeighborBoards[state.LinePos - 4] > World.BoardCount then
								EditorAppendBoard;
							exitRequested := true;
						end;
						8: begin
							Board.Info.ReenterWhenZapped := not Board.Info.ReenterWhenZapped;
						end;
						9: begin
							Str(Board.Info.TimeLimitSec, numStr);
							SidebarPromptString('Time limit?', ' Sec', numStr, PROMPT_NUMERIC);
							if Length(numStr) <> 0 then
								Val(numStr, Board.Info.TimeLimitSec, i);
							EditorDrawSidebar;
						end;
						10: begin
							exitRequested := true;
							TextWindowDrawClose;
						end;
					end
				else begin
					exitRequested := true;
					TextWindowDrawClose;
				end;
			until exitRequested;

			TextWindowFree(state);
		end;

	procedure EditorEditStatText(statId: integer; prompt: string);
		var
			state: TTextWindowState;
			iLine, iChar: integer;
			unk1: array[0 .. 51] of byte;
			dataChar: char;
			dataPtr: pointer;
		begin
			with Board.Stats[statId] do begin
				state.Title := prompt;
				TextWindowDrawOpen(state);
				state.LinePos := 1;
				state.Selectable := false;
				CopyStatDataToTextWindow(statId, state);

				if DataLen > 0 then begin
					FreeMem(Data, DataLen);
					DataLen := 0;
				end;

				EditorOpenEditTextWindow(state);

				for iLine := 1 to state.LineCount do
					DataLen := DataLen + Length(state.Lines[iLine]^) + 1;
				GetMem(Data, DataLen);

				dataPtr := Data;
				for iLine := 1 to state.LineCount do begin
					for iChar := 1 to Length(state.Lines[iLine]^) do begin
						dataChar := state.Lines[iLine]^[iChar];
						Move(dataChar, dataPtr^, 1);
						AdvancePointer(dataPtr, 1);
					end;

					dataChar := #13;
					Move(dataChar, dataPtr^, 1);
					AdvancePointer(dataPtr, 1);
				end;

				TextWindowFree(state);
				TextWindowDrawClose;
				InputKeyPressed := #0;
			end;
		end;

	procedure EditorEditStat(statId: integer);
		var
			element: byte;
			i: integer;
			categoryName: string;
			selectedBoard: byte;
			iy: integer;
			promptByte: byte;

		procedure EditorEditStatSettings(selected: boolean);
			begin
				with Board.Stats[statId] do begin
					InputKeyPressed := #0;
					iy := 9;

					if Length(ElementDefs[element].Param1Name) <> 0 then begin
						if Length(ElementDefs[element].ParamTextName) = 0 then begin
							SidebarPromptSlider(selected, 63, iy, ElementDefs[element].Param1Name, P1);
						end else begin
							if P1 = 0 then
								P1 := World.EditorStatSettings[element].P1;
							BoardDrawTile(X, Y);
							SidebarPromptCharacter(selected, 63, iy, ElementDefs[element].Param1Name, P1);
							BoardDrawTile(X, Y);
						end;
						if selected then
							World.EditorStatSettings[element].P1 := P1;
						iy := iy + 4;
					end;

					if (InputKeyPressed <> KEY_ESCAPE) and
						(Length(ElementDefs[element].ParamTextName) <> 0) then
					begin
						if selected then
							EditorEditStatText(statId, ElementDefs[element].ParamTextName);
					end;

					if (InputKeyPressed <> KEY_ESCAPE) and
						(Length(ElementDefs[element].Param2Name) <> 0) then
					begin
						promptByte := (P2 mod $80);
						SidebarPromptSlider(selected, 63, iy, ElementDefs[element].Param2Name, promptByte);
						if selected then begin
							P2 := (P2 and $80) + promptByte;
							World.EditorStatSettings[element].P2 := P2;
						end;
						iy := iy + 4;
					end;

					if (InputKeyPressed <> KEY_ESCAPE) and
						(Length(ElementDefs[element].ParamBulletTypeName) <> 0) then
					begin
						promptByte := (P2) div $80;
						SidebarPromptChoice(selected, iy, ElementDefs[element].ParamBulletTypeName,
							'Bullets Stars', promptByte);
						if selected then begin
							P2 := (P2 mod $80) + (promptByte * $80);
							World.EditorStatSettings[element].P2 := P2;
						end;
						iy := iy + 4;
					end;

					if (InputKeyPressed <> KEY_ESCAPE) and
						(Length(ElementDefs[element].ParamDirName) <> 0) then
					begin
						SidebarPromptDirection(selected, iy, ElementDefs[element].ParamDirName,
							StepX, StepY);
						if selected then begin
							World.EditorStatSettings[element].StepX := StepX;
							World.EditorStatSettings[element].StepY := StepY;
						end;
						iy := iy + 4;
					end;

					if (InputKeyPressed <> KEY_ESCAPE) and
						(Length(ElementDefs[element].ParamBoardName) <> 0) then
					begin
						if selected then begin
							selectedBoard := EditorSelectBoard(ElementDefs[element].ParamBoardName, P3, true);
							if selectedBoard <> 0 then begin
								P3 := selectedBoard;
								World.EditorStatSettings[element].P3 := World.Info.CurrentBoard;
								if P3 > World.BoardCount then begin
									EditorAppendBoard;
									copiedHasStat := false;
									copiedTile.Element := 0;
									copiedTile.Color := $0F;
								end;
								World.EditorStatSettings[element].P3 := P3;
							end else begin
								InputKeyPressed := KEY_ESCAPE;
							end;
							iy := iy + 4;
						end else begin
							VideoWriteText(63, iy, $1F, 'Room: ' + Copy(EditorGetBoardName(P3, true), 1, 10));
						end;
					end;
				end;
			end;

		begin
			with Board.Stats[statId] do begin
				SidebarClear;

				element := Board.Tiles[X][Y].Element;
				wasModified := true;

				categoryName := '';
				for i := 0 to element do begin
					if (ElementDefs[i].EditorCategory = ElementDefs[element].EditorCategory)
						and (Length(ElementDefs[i].CategoryName) <> 0) then
					begin
						categoryName := ElementDefs[i].CategoryName;
					end;
				end;

				VideoWriteText(64, 6, $1E, categoryName);
				VideoWriteText(64, 7, $1F, ElementDefs[element].Name);

				EditorEditStatSettings(false);
				EditorEditStatSettings(true);

				if InputKeyPressed <> KEY_ESCAPE then begin
					copiedHasStat := true;
					copiedStat := Board.Stats[statId];
					copiedTile := Board.Tiles[X][Y];
					copiedX := X;
					copiedY := Y;
				end;
			end;
		end;

	procedure EditorTransferBoard;
		var
			i: byte;
			f: file;
		label TransferEnd;
		begin
			i := 1;
			SidebarPromptChoice(true, 3, 'Transfer board:', 'Import Export', i);
			if InputKeyPressed <> KEY_ESCAPE then begin
				if i = 0 then begin
					SidebarPromptString('Import board', '.BRD', SavedBoardFileName, PROMPT_ALPHANUM);
					if (InputKeyPressed <> KEY_ESCAPE) and (Length(SavedBoardFileName) <> 0) then begin
						Assign(f, SavedBoardFileName + '.BRD');
						Reset(f, 1);
						if DisplayIOError then goto TransferEnd;

						BoardClose;
						FreeMem(World.BoardData[World.Info.CurrentBoard], World.BoardLen[World.Info.CurrentBoard]);
						BlockRead(f, World.BoardLen[World.Info.CurrentBoard], 2);
						if not DisplayIOError then begin
							GetMem(World.BoardData[World.Info.CurrentBoard], World.BoardLen[World.Info.CurrentBoard]);
							BlockRead(f, World.BoardData[World.Info.CurrentBoard]^,
								World.BoardLen[World.Info.CurrentBoard]);
						end;

						if DisplayIOError then begin
							World.BoardLen[World.Info.CurrentBoard] := 0;
							BoardCreate;
							EditorDrawRefresh;
						end else begin
							BoardOpen(World.Info.CurrentBoard);
							EditorDrawRefresh;
						end;
					end;
				end else if i = 1 then begin
					SidebarPromptString('Export board', '.BRD', SavedBoardFileName, PROMPT_ALPHANUM);
					if (InputKeyPressed <> KEY_ESCAPE) and (Length(SavedBoardFileName) <> 0) then begin
						Assign(f, SavedBoardFileName + '.BRD');
						Rewrite(f, 1);
						if DisplayIOError then goto TransferEnd;

						BoardClose;
						BlockWrite(f, World.BoardLen[World.Info.CurrentBoard], 2);
						BlockWrite(f, World.BoardData[World.Info.CurrentBoard]^,
							World.BoardLen[World.Info.CurrentBoard]);
						BoardOpen(World.Info.CurrentBoard);

						if DisplayIOError then begin
						end else begin
							Close(f);
						end;
					end;
				end;
			end;
		TransferEnd:
			EditorDrawSidebar;
		end;

	procedure EditorFloodFill(x, y: integer; from: TTile);
		var
			i: integer;
			tileAt: TTile;
			toFill, filled: byte;
			xPosition: array[0 .. 255] of integer;
			yPosition: array[0 .. 255] of integer;
		begin
			toFill := 1;
			filled := 0;
			while toFill <> filled do begin
				tileAt := Board.Tiles[x][y];
				EditorPlaceTile(x, y);
				if (Board.Tiles[x][y].Element <> tileAt.Element)
					or (Board.Tiles[x][y].Color <> tileAt.Color) then
					for i := 0 to 3 do
						with Board.Tiles[x + NeighborDeltaX[i]][y + NeighborDeltaY[i]] do begin
							if (Element = from.Element)
								and ((from.Element = 0) or (Color = from.Color)) then
							begin
								xPosition[toFill] := x + NeighborDeltaX[i];
								yPosition[toFill] := y + NeighborDeltaY[i];
								toFill := toFill + 1;
							end;
						end;

				filled := filled + 1;
				x := xPosition[filled];
				y := yPosition[filled];
			end;
		end;

	begin
		if World.Info.IsSave or (WorldGetFlagPosition('SECRET') >= 0) then begin
			WorldUnload;
			WorldCreate;
		end;
		InitElementsEditor;
		CurrentTick := 0;
		wasModified := false;
		cursorX := 30;
		cursorY := 12;
		drawMode := DrawingOff;
		cursorPattern := 1;
		cursorColor := $0E;
		cursorBlinker := 0;
		copiedHasStat := false;
		copiedTile.Element := 0;
		copiedTile.Color := $0F;

		BoardChange(World.Info.CurrentBoard);
		EditorDrawRefresh;

		editorExitRequested := false;
		repeat
			if drawMode = DrawingOn then
				EditorPlaceTile(cursorX, cursorY);
			InputUpdate;
			if (InputKeyPressed = #0) and (InputDeltaX = 0) and (InputDeltaY = 0) and not InputShiftPressed then begin
				if SoundHasTimeElapsed(TickTimeCounter, 15) then
					cursorBlinker := (cursorBlinker + 1) mod 3;
				if cursorBlinker = 0  then
					BoardDrawTile(cursorX, cursorY)
				else
					VideoWriteText(cursorX - 1, cursorY - 1, $0F, #197);
				EditorUpdateSidebar;
			end else begin
				BoardDrawTile(cursorX, cursorY);
			end;

			if drawMode = TextEntry then begin
				if (InputKeyPressed >= #32) and (InputKeyPressed < #128) then begin
					if EditorPrepareModifyTile(cursorX, cursorY) then begin
						Board.Tiles[cursorX][cursorY].Element := (cursorColor - 9) + E_TEXT_MIN;
						Board.Tiles[cursorX][cursorY].Color := Ord(InputKeyPressed);
						EditorDrawTileAndNeighborsAt(cursorX, cursorY);
						InputDeltaX := 1;
						InputDeltaY := 0;
					end;
					InputKeyPressed := #0;
				end else if (InputKeyPressed = KEY_BACKSPACE) and (cursorX > 1)
					and EditorPrepareModifyTile(cursorX - 1, cursorY) then
				begin
					cursorX := cursorX - 1;
				end else if (InputKeyPressed = KEY_ENTER) or (InputKeyPressed = KEY_ESCAPE) then begin
					drawMode := DrawingOff;
					InputKeyPressed := #0;
				end;
			end;

			with Board.Tiles[cursorX][cursorY] do begin
				if InputShiftPressed or (InputKeyPressed = ' ') then begin
					InputShiftAccepted := true;
					if (Element = 0)
						or (ElementDefs[Element].PlaceableOnTop and copiedHasStat and (cursorPattern > EditorPatternCount))
						or (InputDeltaX <> 0) or (InputDeltaY <> 0) then
					begin
						EditorPlaceTile(cursorX, cursorY);
					end else begin
						canModify := EditorPrepareModifyTile(cursorX, cursorY);
						if canModify then
							Board.Tiles[cursorX][cursorY].Element := 0;
					end;
				end;

				if (InputDeltaX <> 0) or (InputDeltaY <> 0) then begin
					cursorX := cursorX + InputDeltaX;
					if cursorX < 1 then
						cursorX := 1;
					if cursorX > BOARD_WIDTH then
						cursorX := BOARD_WIDTH;

					cursorY := cursorY + InputDeltaY;
					if cursorY < 1 then
						cursorY := 1;
					if cursorY > BOARD_HEIGHT then
						cursorY := BOARD_HEIGHT;

					VideoWriteText(cursorX - 1, cursorY - 1, $0F, #197);
					if (InputKeyPressed = #0) and InputJoystickEnabled then
						Delay(70);
					InputShiftAccepted := false;
				end;

				case UpCase(InputKeyPressed) of
					'`': EditorDrawRefresh;
					'P': begin
						VideoWriteText(62, 21, $1F, '       ');
						if cursorPattern <= EditorPatternCount then
							cursorPattern := cursorPattern + 1
						else
							cursorPattern := 1;
					end;
					'C': begin
						VideoWriteText(72, 19, $1E, '       ');
						VideoWriteText(69, 21, $1F, '        ');
						if (cursorColor mod $10) <> $0F then
							cursorColor := cursorColor + 1
						else
							cursorColor := ((cursorColor div $10) * $10) + 9;
					end;
					'L': begin
						EditorAskSaveChanged;
						if (InputKeyPressed <> KEY_ESCAPE) and GameWorldLoad('.ZZT') then begin
							if World.Info.IsSave or (WorldGetFlagPosition('SECRET') >= 0) then begin
								if not DebugEnabled then begin
									SidebarClearLine(3);
									SidebarClearLine(4);
									SidebarClearLine(5);
									VideoWriteText(63, 4, $1E, 'Can not edit');
									if World.Info.IsSave then
										VideoWriteText(63, 5, $1E, 'a saved game!')
									else
										VideoWriteText(63, 5, $1E, '  ' + World.Info.Name + '!');
									PauseOnError;
									WorldUnload;
									WorldCreate;
								end;
							end;
							wasModified := false;
							EditorDrawRefresh;
						end;
						EditorDrawSidebar;
					end;
					'S': begin
						GameWorldSave('Save world:', LoadedGameFileName, '.ZZT');
						if InputKeyPressed <> KEY_ESCAPE then
							wasModified := false;
						EditorDrawSidebar;
					end;
					'Z': begin
						if SidebarPromptYesNo('Clear board? ', false) then begin
							for i := Board.StatCount downto 1 do
								RemoveStat(i);
							BoardCreate;
							EditorDrawRefresh;
						end else begin
							EditorDrawSidebar;
						end;
					end;
					'N': begin
						if SidebarPromptYesNo('Make new world? ', false) and (InputKeyPressed <> KEY_ESCAPE) then begin
							EditorAskSaveChanged;
							if (InputKeyPressed <> KEY_ESCAPE) then begin
								WorldUnload;
								WorldCreate;
								EditorDrawRefresh;
								wasModified := false;
							end;
						end;
						EditorDrawSidebar;
					end;
					'Q', KEY_ESCAPE: begin
						editorExitRequested := true;
					end;
					'B': begin
						i := EditorSelectBoard('Switch boards', World.Info.CurrentBoard, false);
						if (InputKeyPressed <> KEY_ESCAPE) then begin
							if (i > World.BoardCount) then
								if SidebarPromptYesNo('Add new board? ', false) then
									EditorAppendBoard;
							BoardChange(i);
							EditorDrawRefresh;
						end;
						EditorDrawSidebar;
					end;
					'?': begin
						GameDebugPrompt;
						EditorDrawSidebar;
					end;
					KEY_TAB: begin
						if drawMode = DrawingOff then
							drawMode := DrawingOn
						else
							drawMode := DrawingOff;
					end;
					KEY_F1, KEY_F2, KEY_F3: begin
						VideoWriteText(cursorX - 1, cursorY - 1, $0F, #197);
						for i := 3 to 20 do
							SidebarClearLine(i);
						case InputKeyPressed of
							KEY_F1: selectedCategory := CATEGORY_ITEM;
							KEY_F2: selectedCategory := CATEGORY_CREATURE;
							KEY_F3: selectedCategory := CATEGORY_TERRAIN;
						end;
						i := 3; { Y position for text writing }
						for iElem := 0 to MAX_ELEMENT do begin
							if ElementDefs[iElem].EditorCategory = selectedCategory then begin
								if Length(ElementDefs[iElem].CategoryName) <> 0 then begin
									i := i + 1;
									VideoWriteText(65, i, $1E, ElementDefs[iElem].CategoryName);
									i := i + 1;
								end;

								VideoWriteText(61, i, ((i mod 2) shl 6) + $30, ' ' + ElementDefs[iElem].EditorShortcut + ' ');
								VideoWriteText(65, i, $1F, ElementDefs[iElem].Name);
								if ElementDefs[iElem].Color = COLOR_CHOICE_ON_BLACK then
									elemMenuColor := (cursorColor mod $10) + $10
								else if ElementDefs[iElem].Color = COLOR_WHITE_ON_CHOICE then
									elemMenuColor := (cursorColor * $10) - $71
								else if ElementDefs[iElem].Color = COLOR_CHOICE_ON_CHOICE then
									elemMenuColor := ((cursorColor - 8) * $11) + 8
								else if (ElementDefs[iElem].Color and $70) = $00 then
									elemMenuColor := (ElementDefs[iElem].Color mod $10) + $10
								else
									elemMenuColor := ElementDefs[iElem].Color;
								VideoWriteText(78, i, elemMenuColor, ElementDefs[iElem].Character);

								i := i + 1;
							end;
						end;
						InputReadWaitKey;
						for iElem := 1 to MAX_ELEMENT do begin
							if (ElementDefs[iElem].EditorCategory = selectedCategory)
								and (ElementDefs[iElem].EditorShortcut = UpCase(InputKeyPressed)) then
							begin
								if iElem = E_PLAYER then begin
									if EditorPrepareModifyTile(cursorX, cursorY) then
										MoveStat(0, cursorX, cursorY);
								end else begin
									if ElementDefs[iElem].Color = COLOR_CHOICE_ON_BLACK then
										elemMenuColor := cursorColor
									else if ElementDefs[iElem].Color = COLOR_WHITE_ON_CHOICE then
										elemMenuColor := (cursorColor * $10) - $71
									else if ElementDefs[iElem].Color = COLOR_CHOICE_ON_CHOICE then
										elemMenuColor := ((cursorColor - 8) * $11) + 8
									else
										elemMenuColor := ElementDefs[iElem].Color;

									if ElementDefs[iElem].Cycle = -1 then begin
										if EditorPrepareModifyTile(cursorX, cursorY) then
											EditorSetAndCopyTile(cursorX, cursorY, iElem, elemMenuColor);
									end else begin
										if EditorPrepareModifyStatAtCursor then begin
											AddStat(cursorX, cursorY, iElem, elemMenuColor,
												ElementDefs[iElem].Cycle, StatTemplateDefault);
											with Board.Stats[Board.StatCount] do begin
												if Length(ElementDefs[iElem].Param1Name) <> 0 then
													P1 := World.EditorStatSettings[iElem].P1;
												if Length(ElementDefs[iElem].Param2Name) <> 0 then
													P2 := World.EditorStatSettings[iElem].P2;
												if Length(ElementDefs[iElem].ParamDirName) <> 0 then begin
													StepX := World.EditorStatSettings[iElem].StepX;
													StepY := World.EditorStatSettings[iElem].StepY;
												end;
												if Length(ElementDefs[iElem].ParamBoardName) <> 0 then
													P3 := World.EditorStatSettings[iElem].P3;
											end;
											EditorEditStat(Board.StatCount);
											if InputKeyPressed = KEY_ESCAPE then
												RemoveStat(Board.StatCount);
										end;
									end;
								end;
							end;
						end;
						EditorDrawSidebar;
					end;
					KEY_F4: begin
						if drawMode <> TextEntry then
							drawMode := TextEntry
						else
							drawMode := DrawingOff;
					end;
					'H': begin
						TextWindowDisplayFile('editor.hlp', 'World editor help');
					end;
					'X': begin
						EditorFloodFill(cursorX, cursorY, Board.Tiles[cursorX][cursorY]);
					end;
					'!': begin
						EditorEditHelpFile;
						EditorDrawSidebar;
					end;
					'T': begin
						EditorTransferBoard;
					end;
					KEY_ENTER: begin
						if GetStatIdAt(cursorX, cursorY) >= 0 then begin
							EditorEditStat(GetStatIdAt(cursorX, cursorY));
							EditorDrawSidebar;
						end else begin
							copiedHasStat := false;
							copiedTile := Board.Tiles[cursorX][cursorY];
						end;
					end;
					'I': begin
						EditorEditBoardInfo;
					end;
				end;
			end;

			if editorExitRequested then begin
				EditorAskSaveChanged;
				if InputKeyPressed = KEY_ESCAPE then begin
					editorExitRequested := false;
					EditorDrawSidebar;
				end;
			end;
		until editorExitRequested;

		InputKeyPressed := #0;
		InitElementsGame;
	end;

procedure HighScoresLoad;
	var
		f: file of THighScoreList;
		i: integer;
	begin
		Assign(f, World.Info.Name + '.HI');
		Reset(f);
		if IOResult = 0 then begin
			Read(f, HighScoreList);
		end;
		Close(f);
		if IOResult <> 0 then begin
			for i := 1 to 30 do begin
				HighScoreList[i].Name := '';
				HighScoreList[i].Score := -1;
			end;
		end;
	end;

procedure HighScoresSave;
	var
		f: file of THighScoreList;
	begin
		Assign(f, World.Info.Name + '.HI');
		Rewrite(f);
		Write(f, HighScoreList);
		Close(f);
		if DisplayIOError then begin
		end else begin
		end;
	end;

procedure HighScoresInitTextWindow(var state: TTextWindowState);
	var
		i: integer;
		scoreStr: string;
	begin
		state.LineCount := 0;
		TextWindowAppend(state, 'Score  Name');
		TextWindowAppend(state, '-----  ----------------------------------');
		for i := 1 to HIGH_SCORE_COUNT do begin
			if Length(HighScoreList[i].Name) <> 0 then begin
				Str(HighScoreList[i].Score:5, scoreStr);
				TextWindowAppend(state, scoreStr + '  ' + HighScoreList[i].Name);
			end;
		end;
	end;

procedure HighScoresDisplay(linePos: integer);
	var
		state: TTextWindowState;
	begin
		state.LinePos := linePos;
		HighScoresInitTextWindow(state);
		if (state.LineCount > 2) then begin
			state.Title := 'High scores for ' + World.Info.Name;
			TextWindowDrawOpen(state);
			TextWindowSelect(state, false, true);
			TextWindowDrawClose;
		end;
		TextWindowFree(state);
	end;

procedure HighScoresAdd(score: integer);
	var
		textWindow: TTextWindowState;
		name: TString50;
		i, listPos: integer;
	begin
		listPos := 1;
		while (listPos <= 30) and (score < HighScoreList[listPos].Score) do
			listPos := listPos + 1;
		if (listPos <= 30) and (score > 0) then begin
			for i := 29 downto listPos do
				HighScoreList[i + 1] := HighScoreList[i];
			HighScoreList[listPos].Score := score;
			HighScoreList[listPos].Name := '-- You! --';

			HighScoresInitTextWindow(textWindow);
			textWindow.LinePos := listPos;
			textWindow.Title := 'New high score for ' + World.Info.Name;
			TextWindowDrawOpen(textWindow);
			TextWindowDraw(textWindow, false, false);

			name := '';
			PopupPromptString('Congratulations!  Enter your name:', name);
			HighScoreList[listPos].Name := name;
			HighScoresSave;

			TextWindowDrawClose;
			TransitionDrawToBoard;
			TextWindowFree(textWindow);
		end;
	end;

function Signum(val: integer): integer;
	begin
		if val > 0 then
			Signum := 1
		else if val < 0 then
			Signum := -1
		else
			Signum := 0;
	end;

function Difference(a, b: integer): integer;
	begin
		if (a - b) >= 0 then
			Difference := a - b
		else
			Difference := b - a;
	end;

procedure GameUpdateSidebar;
	var
		numStr: string[8];
		i: integer;
	begin
		if GameStateElement = E_PLAYER then begin
			if Board.Info.TimeLimitSec > 0 then begin
				VideoWriteText(64, 6, $1E, '   Time:');
				Str(Board.Info.TimeLimitSec - World.Info.BoardTimeSec, numStr);
				VideoWriteText(72, 6, $1E, numStr + ' ');
			end else begin
				SidebarClearLine(6);
			end;

			if World.Info.Health < 0 then
				World.Info.Health := 0;

			Str(World.Info.Health, numStr);
			VideoWriteText(72, 7, $1E, numStr + ' ');
			Str(World.Info.Ammo, numStr);
			VideoWriteText(72, 8, $1E, numStr + '  ');
			Str(World.Info.Torches, numStr);
			VideoWriteText(72, 9, $1E, numStr + ' ');
			Str(World.Info.Gems, numStr);
			VideoWriteText(72, 10, $1E, numStr + ' ');
			Str(World.Info.Score, numStr);
			VideoWriteText(72, 11, $1E, numStr + ' ');

			if World.Info.TorchTicks = 0 then
				VideoWriteText(75, 9, $16, '    ')
			else begin
				for i := 2 to 5 do begin
					if i <= ((World.Info.TorchTicks * 5) div TORCH_DURATION) then
						VideoWriteText(73 + i, 9, $16, #177)
					else
						VideoWriteText(73 + i, 9, $16, #176);
				end;
			end;

			for i := 1 to 7 do begin
				if World.Info.Keys[i] then
					VideoWriteText(71 + i, 12, $18 + i, ElementDefs[E_KEY].Character)
				else
					VideoWriteText(71 + i, 12, $1F, ' ');
			end;

			if SoundEnabled then
				VideoWriteText(65, 15, $1F, ' Be quiet')
			else
				VideoWriteText(65, 15, $1F, ' Be noisy');

			if DebugEnabled then begin
				Str(MemAvail, numStr);
				VideoWriteText(69, 4, $1E, 'm' + numStr + ' ');
			end;
		end;
	end;

procedure DisplayMessage(time: integer; message: string);
	begin
		if GetStatIdAt(0, 0) <> -1 then begin
			RemoveStat(GetStatIdAt(0, 0));
			BoardDrawBorder;
		end;

		if Length(message) <> 0 then begin
			AddStat(0, 0, E_MESSAGE_TIMER, 0, 1, StatTemplateDefault);
			Board.Stats[Board.StatCount].P2 := Time div (TickTimeDuration + 1);
			Board.Info.Message := message;
		end;
	end;

procedure DamageStat(attackerStatId: integer);
	var
		oldX, oldY: integer;
	begin
		with Board.Stats[attackerStatId] do begin
			if attackerStatId = 0 then begin
				if World.Info.Health > 0 then begin
					World.Info.Health := World.Info.Health - 10;

					GameUpdateSidebar;
					DisplayMessage(100, 'Ouch!');

					Board.Tiles[X][Y].Color := $70 + (ElementDefs[E_PLAYER].Color mod $10);

					if World.Info.Health > 0 then begin
						World.Info.BoardTimeSec := 0;
						if Board.Info.ReenterWhenZapped then begin
							SoundQueue(4, #32#1#35#1#39#1#48#1#16#1);

							{ Move player to start }
							Board.Tiles[X][Y].Element := E_EMPTY;
							BoardDrawTile(X, Y);
							oldX := X;
							oldY := Y;
							X := Board.Info.StartPlayerX;
							Y := Board.Info.StartPlayerY;
							DrawPlayerSurroundings(oldX, oldY, 0);
							DrawPlayerSurroundings(X, Y, 0);

							GamePaused := true;
						end;
						SoundQueue(4, #16#1#32#1#19#1#35#1);
					end else begin
						SoundQueue(5, #32#3#35#3#39#3#48#3#39#3#42#3#50#3#55#3#53#3#56#3#64#3#69#3#16#10);
					end;
				end;
			end else begin
				case Board.Tiles[X][Y].Element of
					E_BULLET: SoundQueue(3, #32#1);
					E_OBJECT: begin end;
				else
					SoundQueue(3, #64#1#16#1#80#1#48#1)
				end;
				RemoveStat(attackerStatId);
			end;
		end;
	end;

procedure BoardDamageTile(x, y: integer);
	var
		statId: integer;
	begin
		statId := GetStatIdAt(x, y);
		if statId <> -1 then begin
			DamageStat(statId);
		end else begin
			Board.Tiles[x][y].Element := E_EMPTY;
			BoardDrawTile(x, y);
		end;
	end;

procedure BoardAttack(attackerStatId: integer; x, y: integer);
	begin
		if (attackerStatId = 0) and (World.Info.EnergizerTicks > 0) then begin
			World.Info.Score := ElementDefs[Board.Tiles[x][y].Element].ScoreValue + World.Info.Score;
			GameUpdateSidebar;
		end else begin
			DamageStat(attackerStatId);
		end;

		if (attackerStatId > 0) and (attackerStatId <= CurrentStatTicked) then
			CurrentStatTicked := CurrentStatTicked - 1;

		if (Board.Tiles[x][y].Element = E_PLAYER) and (World.Info.EnergizerTicks > 0) then begin
			World.Info.Score := ElementDefs[Board.Tiles[Board.Stats[attackerStatId].X][Board.Stats[attackerStatId].Y].Element]
				.ScoreValue + World.Info.Score;
			GameUpdateSidebar;
		end else begin
			BoardDamageTile(x, y);
			SoundQueue(2, #16#1);
		end;
	end;

function BoardShoot(element: byte; tx, ty, deltaX, deltaY: integer; source: integer): boolean;
	begin
		if ElementDefs[Board.Tiles[tx + deltaX][ty + deltaY].Element].Walkable
			or (Board.Tiles[tx + deltaX][ty + deltaY].Element = E_WATER) then
		begin
			AddStat(tx + deltaX, ty + deltaY, element, ElementDefs[element].Color, 1, StatTemplateDefault);
			with Board.Stats[Board.StatCount] do begin
				P1 := source;
				StepX := deltaX;
				StepY := deltaY;
				P2 := 100;
			end;
			BoardShoot := true;
		end else if (Board.Tiles[tx + deltaX][ty + deltaY].Element = E_BREAKABLE)
			or (
				ElementDefs[Board.Tiles[tx + deltaX][ty + deltaY].Element].Destructible
				and ((Board.Tiles[tx + deltaX][ty + deltaY].Element = E_PLAYER) = Boolean(source))
				and (World.Info.EnergizerTicks <= 0)
			) then
		begin
			BoardDamageTile(tx + deltaX, ty + deltaY);
			SoundQueue(2, #16#1);
			BoardShoot := true;
		end else begin
			BoardShoot := false;
		end;
	end;

procedure CalcDirectionRnd(var deltaX, deltaY: integer);
	begin
		deltaX := Random(3) - 1;

		if deltaX = 0 then
			deltaY := Random(2) * 2 - 1
		else
			deltaY := 0;
	end;

procedure CalcDirectionSeek(x, y: integer; var deltaX, deltaY: integer);
	begin
		deltaX := 0;
		deltaY := 0;

		if (Random(2) < 1) or (Board.Stats[0].Y = y) then
			deltaX := Signum(Board.Stats[0].X - x);

		if deltaX = 0 then
			deltaY := Signum(Board.Stats[0].Y - y);

		if World.Info.EnergizerTicks > 0 then begin
			deltaX := -deltaX;
			deltaY := -deltaY;
		end;
	end;

procedure TransitionDrawBoardChange;
	begin
		TransitionDrawToFill(#219, $05);
		TransitionDrawToBoard;
	end;

procedure BoardEnter;
	begin
		Board.Info.StartPlayerX := Board.Stats[0].X;
		Board.Info.StartPlayerY := Board.Stats[0].Y;

		if Board.Info.IsDark and MessageHintTorchNotShown then begin
			DisplayMessage(200, 'Room is dark - you need to light a torch!');
			MessageHintTorchNotShown := false;
		end;

		World.Info.BoardTimeSec := 0;
		GameUpdateSidebar;
	end;

procedure BoardPassageTeleport(x, y: integer);
	var
		oldBoard: integer;
		col: byte;
		ix, iy: integer;
		newX, newY: integer;
	begin
		col := Board.Tiles[x][y].Color;

		oldBoard := World.Info.CurrentBoard;
		BoardChange(Board.Stats[GetStatIdAt(x, y)].P3);

		newX := 0;
		for ix := 1 to BOARD_WIDTH do
			for iy := 1 to BOARD_HEIGHT do
				if (Board.Tiles[ix][iy].Element = E_PASSAGE) and (Board.Tiles[ix][iy].Color = col) then begin
					newX := ix;
					newY := iy;
				end;

		Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Element := E_EMPTY;
		Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Color := 0;
		if newX <> 0 then begin
			Board.Stats[0].X := newX;
			Board.Stats[0].Y := newY;
		end;

		GamePaused := true;
		SoundQueue(4, #48#1#52#1#55#1#49#1#53#1#56#1#50#1#54#1#57#1#51#1#55#1#58#1#52#1#56#1#64#1);
		TransitionDrawBoardChange;
		BoardEnter;
	end;

procedure GameDebugPrompt;
	var
		input: TString50;
		i: integer;
		toggle: boolean;
	begin
		input := '';
		SidebarClearLine(4);
		SidebarClearLine(5);

		PromptString(63, 5, $1E, $0F, 11, PROMPT_ANY, input);

		toggle := true;
		if (input[1] = '+') or (input[1] = '-') then begin
			if input[1] = '-' then
				toggle := false;
			input := Copy(input, 2, Length(input) - 1);
			for i := 1 to Length(input) do
				input[i] := UpCase(input[i]);

			if toggle = true then
				WorldSetFlag(input)
			else
				WorldClearFlag(input);
		end;

		if WorldGetFlagPosition('DEBUG') >= 0 then begin
			if input = 'health' then
				World.Info.Health := World.Info.Health + 50
			else if input = 'ammo' then
				World.Info.Ammo := World.Info.Ammo + 5
			else if input = 'keys' then
				for i := 1 to 7 do World.Info.Keys[i] := true
			else if input = 'torches' then
				World.Info.Torches := World.Info.Torches + 3
			else if input = 'time' then
				World.Info.BoardTimeSec := World.Info.BoardTimeSec - 30
			else if input = 'gems' then
				World.Info.Gems := World.Info.Gems + 5
			else if input = 'dark' then begin
				Board.Info.IsDark := toggle;
				TransitionDrawToBoard;
			end else if input = 'zap' then begin
				for i := 0 to 3 do begin
					BoardDamageTile(Board.Stats[0].X + NeighborDeltaX[i], Board.Stats[0].Y + NeighborDeltaY[i]);
					Board.Tiles[Board.Stats[0].X + NeighborDeltaX[i]][Board.Stats[0].Y + NeighborDeltaY[i]].Element := E_EMPTY;
					BoardDrawTile(Board.Stats[0].X + NeighborDeltaX[i], Board.Stats[0].Y + NeighborDeltaY[i]);
				end;
			end;
		end;

		SoundQueue(10, #39#4);
		SidebarClearLine(4);
		SidebarClearLine(5);
		GameUpdateSidebar;
	end;

procedure OopError(statId: integer; message: string);
	begin
		with Board.Stats[statId] do begin
			DisplayMessage(200, 'ERR: ' + message);
			SoundQueue(5, #80#10);
			DataPos := -1;
		end;
	end;

procedure OopReadChar(statId: integer; var position: integer);
	begin
		with Board.Stats[statId] do begin
			if (position >= 0) and (position < DataLen) then begin
				Move(Ptr(Seg(Data^), Ofs(Data^) + position)^, OopChar, 1);
				Inc(position);
			end else begin
				OopChar := #0
			end;
		end;
	end;

procedure OopReadWord(statId: integer; var position: integer);
	begin
		OopWord := '';
		repeat
			OopReadChar(statId, position);
		until OopChar <> ' ';
		OopChar := UpCase(OopChar);
		if (OopChar < '0') or (OopChar > '9') then begin
			while ((OopChar >= 'A') and (OopChar <= 'Z')) or (OopChar = ':')
				or ((OopChar >= '0') and (OopChar <= '9')) or (OopChar = '_') do
			begin
				OopWord := OopWord + OopChar;
				OopReadChar(statId, position);
				OopChar := UpCase(OopChar);
			end;
		end;
		if position > 0 then
			Dec(position);
	end;

procedure OopReadValue(statId: integer; var position: integer);
	var
		s: string[20];
		code: integer;
	begin
		s := '';
		repeat
			OopReadChar(statId, position)
		until OopChar <> ' ';

		OopChar := UpCase(OopChar);
		while (OopChar >= '0') and (OopChar <= '9') do begin
			s := s + OopChar;
			OopReadChar(statId, position);
			OopChar := UpCase(OopChar);
		end;

		if position > 0 then
			position := position - 1;

		if Length(s) <> 0 then
			Val(s, OopValue, code)
		else
			OopValue := -1;
	end;

procedure OopSkipLine(statId: integer; var position: integer);
	begin
		repeat
			OopReadChar(statId, position);
		until (OopChar = #0) or (OopChar = #13);
	end;

function OopParseDirection(statId: integer; var position: integer; var dx, dy: integer): boolean;
	begin
		with Board.Stats[statId] do begin
			OopParseDirection := true;

			if (OopWord = 'N') or (OopWord = 'NORTH') then begin
				dx := 0;
				dy := -1;
			end else if (OopWord = 'S') or (OopWord = 'SOUTH') then begin
				dx := 0;
				dy := 1;
			end else if (OopWord = 'E') or (OopWord = 'EAST') then begin
				dx := 1;
				dy := 0;
			end else if (OopWord = 'W') or (OopWord = 'WEST') then begin
				dx := -1;
				dy := 0;
			end else if (OopWord = 'I') or (OopWord = 'IDLE') then begin
				dx := 0;
				dy := 0;
			end else if (OopWord = 'SEEK') then begin
				CalcDirectionSeek(X, Y, dx, dy);
			end else if (OopWord = 'FLOW') then begin
				dx := StepX;
				dy := StepY;
			end else if (OopWord = 'RND') then begin
				CalcDirectionRnd(dx, dy)
			end else if (OopWord = 'RNDNS') then begin
				dx := 0;
				dy := Random(2) * 2 - 1;
			end else if (OopWord = 'RNDNE') then begin
				dx := Random(2);
				if dx = 0 then dy := -1 else dy := 0;
			end else if (OopWord = 'CW') then begin
				OopReadWord(statId, position);
				OopParseDirection := OopParseDirection(statId, position, dy, dx);
				dx := -dx;
			end else if (OopWord = 'CCW') then begin
				OopReadWord(statId, position);
				OopParseDirection := OopParseDirection(statId, position, dy, dx);
				dy := -dy;
			end else if (OopWord = 'RNDP') then begin
				OopReadWord(statId, position);
				OopParseDirection := OopParseDirection(statId, position, dy, dx);
				if Random(2) = 0 then
					dx := -dx
				else
					dy := -dy;
			end else if (OopWord = 'OPP') then begin
				OopReadWord(statId, position);
				OopParseDirection := OopParseDirection(statId, position, dx, dy);
				dx := -dx;
				dy := -dy;
			end else begin
				dx := 0;
				dy := 0;
				OopParseDirection := false;
			end;
		end;
	end;

procedure OopReadDirection(statId: integer; var position: integer; var dx, dy: integer);
	begin
		OopReadWord(statId, position);
		if not OopParseDirection(statId, position, dx, dy) then
			OopError(statId, 'Bad direction');
	end;

function OopFindString(statId: integer; s: string): integer;
	var
		pos, wordPos, cmpPos: integer;
	label NoMatch;
	begin
		with Board.Stats[statId] do begin
			pos := 0;
			while pos <= DataLen do begin
				wordPos := 1;
				cmpPos := pos;
				repeat
					OopReadChar(statId, cmpPos);
					if UpCase(s[wordPos]) <> UpCase(OopChar) then
						goto NoMatch;
					wordPos := wordPos + 1;
				until wordPos > Length(s);

				{ string matches }
				OopReadChar(statId, cmpPos);
				OopChar := UpCase(OopChar);
				if ((OopChar >= 'A') and (OopChar <= 'Z')) or (OopChar = '_') then begin
					{ word continues, match invalid }
				end else begin
					{ word complete, match valid }
					OopFindString := pos;
					exit;
				end;

			NoMatch:
				pos := pos + 1;
			end;
			OopFindString := -1;
		end;
	end;

function OopIterateStat(statId: integer; var iStat: integer; lookup: string): boolean;
	var
		pos: integer;
		found: boolean;
	begin
		iStat := iStat + 1;
		found := false;

		if lookup = 'ALL' then begin
			if iStat <= Board.StatCount then
				found := true;
		end else if lookup = 'OTHERS' then begin
			if iStat <= Board.StatCount then begin
				if iStat <> statId then
					found := true
				else begin
					iStat := iStat + 1;
					found := (iStat <= Board.StatCount);
				end;
			end;
		end else if lookup = 'SELF' then begin
			if (statId > 0) and (iStat <= statId) then begin
				iStat := statId;
				found := true;
			end;
		end else begin
			while (iStat <= Board.StatCount) and not found do begin
				if Board.Stats[iStat].Data <> nil then begin
					pos := 0;
					OopReadChar(iStat, pos);
					if OopChar = '@' then begin
						OopReadWord(iStat, pos);
						if OopWord = lookup then
							found := true;
					end;
				end;

				if not found then
					iStat := iStat + 1;
			end;
		end;

		OopIterateStat := found;
	end;

function OopFindLabel(statId: integer; sendLabel: string; var iStat, iDataPos: integer; labelPrefix: string): boolean;
	var
		targetSplitPos: integer;
		unk1: integer;
		targetLookup: string[20];
		objectMessage: string[20];
		foundStat: boolean;
	label FindNextStat;
	begin
		foundStat := false;
		targetSplitPos := Pos(':', sendLabel);
		if targetSplitPos <= 0 then begin
			{ if there is no target, we only check statId }
			if iStat < statId then begin
				objectMessage := sendLabel;
				iStat := statId;
				targetSplitPos := 0;
				foundStat := true;
			end;
		end else begin
			targetLookup := Copy(sendLabel, 1, targetSplitPos - 1);
			objectMessage := Copy(sendLabel, targetSplitPos + 1, Length(sendLabel) - targetSplitPos);
		FindNextStat:
			foundStat := OopIterateStat(statId, iStat, targetLookup);
		end;

		if foundStat then begin
			if objectMessage = 'RESTART' then begin
				iDataPos := 0;
			end else begin
				iDataPos := OopFindString(iStat, labelPrefix + objectMessage);
				{ if lookup target exists, there may be more stats }
				if (iDataPos < 0) and (targetSplitPos > 0) then
					goto FindNextStat;
			end;
			foundStat := iDataPos >= 0;
		end;

		OopFindLabel := foundStat;
	end;

function WorldGetFlagPosition(name: TString50): integer;
	var
		i: integer;
	begin
		WorldGetFlagPosition := -1;
		for i := 1 to MAX_FLAG do begin
			if World.Info.Flags[i] = name then
				WorldGetFlagPosition := i;
		end;
	end;

procedure WorldSetFlag(name: TString50);
	var
		i: integer;
	begin
		if WorldGetFlagPosition(name) < 0 then begin
			i := 1;
			while (i < MAX_FLAG) and (Length(World.Info.Flags[i]) <> 0) do
				i := i + 1;
			World.Info.Flags[i] := name;
		end;
	end;

procedure WorldClearFlag(name: TString50);
	var
		i: integer;
	begin
		if WorldGetFlagPosition(name) >= 0 then
			World.Info.Flags[WorldGetFlagPosition(name)] := '';
	end;

function OopStringToWord(input: TString50): TString50;
	var
		output: TString50;
		i: integer;
	begin
		output := '';
		for i := 1 to Length(input) do begin
			if ((input[i] >= 'A') and (input[i] <= 'Z'))
				or ((input[i] >= '0') and (input[i] <= '9')) then
				output := output + input[i]
			else if ((input[i] >= 'a') and (input[i] <= 'z')) then
				output := output + Chr(Ord(input[i]) - $20);
		end;
		OopStringToWord := output;
	end;

function OopParseTile(var statId, position: integer; var tile: TTile): boolean;
	var
		i: integer;
	label ColorFound;
	begin
		OopParseTile := false;
		tile.Color := 0;

		OopReadWord(statId, position);
		for i := 1 to 7 do begin
			if OopWord = OopStringToWord(ColorNames[i]) then begin
				tile.Color := i + $08;
				OopReadWord(statId, position);
				goto ColorFound;
			end;
		end;
	ColorFound:

		for i := 0 to MAX_ELEMENT do begin
			if OopWord = OopStringToWord(ElementDefs[i].Name) then begin
				OopParseTile := true;
				tile.Element := i;
				exit;
			end;
		end;
	end;

function GetColorForTileMatch(var tile: TTile): byte;
	begin
		if ElementDefs[tile.Element].Color < COLOR_SPECIAL_MIN then
			GetColorForTileMatch := ElementDefs[tile.Element].Color and $07
		else if ElementDefs[tile.Element].Color = COLOR_WHITE_ON_CHOICE then
			GetColorForTileMatch := ((tile.Color shr 4) and $0F) + 8
		else
			GetColorForTileMatch := (tile.Color and $0F);
	end;

function FindTileOnBoard(var x, y: integer; tile: TTile): boolean;
	begin
		FindTileOnBoard := false;
		while true do begin
			x := x + 1;
			if x > BOARD_WIDTH then begin
				x := 1;
				y := y + 1;
				if y > BOARD_HEIGHT then
					exit;
			end;

			if Board.Tiles[x][y].Element = tile.Element then
				if ((tile.Color = 0) or (GetColorForTileMatch(Board.Tiles[x][y]) = tile.Color)) then begin
					FindTileOnBoard := true;
					exit;
				end;
		end;
	end;

procedure OopPlaceTile(x, y: integer; var tile: TTile);
	var
		color: byte;
	begin
		if Board.Tiles[x][y].Element <> E_PLAYER then begin
			color := tile.Color;
			if ElementDefs[tile.Element].Color < COLOR_SPECIAL_MIN then
				color := ElementDefs[tile.Element].Color
			else begin
				if color = 0 then
					color := Board.Tiles[x][y].Color;

				if color = 0 then
					color := $0F;

				if ElementDefs[tile.Element].Color = COLOR_WHITE_ON_CHOICE then
					color := ((color - 8) * $10) + $0F;
			end;

			if Board.Tiles[x][y].Element = tile.Element then
				Board.Tiles[x][y].Color := color
			else begin
				BoardDamageTile(x, y);
				if ElementDefs[tile.Element].Cycle >= 0 then begin
					AddStat(x, y, tile.Element, color, ElementDefs[tile.Element].Cycle, StatTemplateDefault);
				end else begin
					Board.Tiles[x][y].Element := tile.Element;
					Board.Tiles[x][y].Color := color;
				end;
			end;

			BoardDrawTile(x, y);
		end;
	end;

function OopCheckCondition(statId: integer; var position: integer): boolean;
	var
		deltaX, deltaY: integer;
		tile: TTile;
		ix, iy: integer;
	begin
		with Board.Stats[statId] do begin
			if OopWord = 'NOT' then begin
				OopReadWord(statId, position);
				OopCheckCondition := not OopCheckCondition(statId, position);
			end else if OopWord = 'ALLIGNED' then begin
				OopCheckCondition := (X = Board.Stats[0].X) or (Y = Board.Stats[0].Y);
			end else if OopWord = 'CONTACT' then begin
				OopCheckCondition := (Sqr(X - Board.Stats[0].X) + Sqr(Y - Board.Stats[0].Y)) = 1;
			end else if OopWord = 'BLOCKED' then begin
				OopReadDirection(statId, position, deltaX, deltaY);
				OopCheckCondition := not ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable;
			end else if OopWord = 'ENERGIZED' then begin
				OopCheckCondition := World.Info.EnergizerTicks > 0;
			end else if OopWord = 'ANY' then begin
				if not OopParseTile(statId, position, tile) then
					OopError(statId, 'Bad object kind');

				ix := 0;
				iy := 1;
				OopCheckCondition := FindTileOnBoard(ix, iy, tile);
			end else begin
				OopCheckCondition := WorldGetFlagPosition(OopWord) >= 0;
			end;
		end;
	end;

function OopReadLineToEnd(statId: integer; var position: integer) : string;
	var
		s: string;
	begin
		s := '';
		OopReadChar(statId, position);
		while (OopChar <> #0) and (OopChar <> #13) do begin
			s := s + OopChar;
			OopReadChar(statId, position);
		end;
		OopReadLineToEnd := s;
	end;

function OopSend(statId: integer; sendLabel: string; ignoreLock: boolean): boolean;
	var
		iDataPos, iStat: integer;
		ignoreSelfLock: boolean;
	begin
		if statId < 0 then begin
			{ if statId is negative, label send will always succeed on self }
			{ this is used for in-game events (f.e. TOUCH, SHOT) }
			statId := -statId;
			ignoreSelfLock := true;
		end else begin
			ignoreSelfLock := false;
		end;

		OopSend := false;
		iStat := 0;

		while OopFindLabel(statId, sendLabel, iStat, iDataPos, #13':') do begin
			if ((Board.Stats[iStat].P2 = 0) or (ignoreLock)) or ((statId = iStat) and not ignoreSelfLock) then begin
				if iStat = statId then
					OopSend := true;

				Board.Stats[iStat].DataPos := iDataPos;
			end;
		end;
	end;

procedure OopExecute(statId: integer; var position: integer; name: TString50);
	var
		textWindow: TTextWindowState;
		textLine: string;
		deltaX, deltaY: integer;
		ix, iy: integer;
		stopRunning: boolean;
		replaceStat: boolean;
		endOfProgram: boolean;
		replaceTile: TTile;
		namePosition: integer;
		lastPosition: integer;
		repeatInsNextTick: boolean;
		lineFinished: boolean;
		labelPtr: pointer;
		labelDataPos: integer;
		labelStatId: integer;
		counterPtr: ^integer;
		counterSubtract: boolean;
		bindStatId: integer;
		insCount: integer;
		argTile: TTile;
		argTile2: TTile;
	label StartParsing;
	label ReadInstruction;
	label ReadCommand;
	begin
		with Board.Stats[statId] do begin
		StartParsing:
			textWindow.Selectable := false;
			textWindow.LinePos := 1;
			textWindow.LineCount := 0;
			stopRunning := false;
			repeatInsNextTick := false;
			replaceStat := false;
			endOfProgram := false;
			insCount := 0;
			repeat
		ReadInstruction:
				lineFinished := true;
				lastPosition := position;
				OopReadChar(statId, position);

				{ skip labels }
				while OopChar = ':' do begin
					repeat
						OopReadChar(statId, position);
					until (OopChar = #0) or (OopChar = #13);
					OopReadChar(statId, position);
				end;

				if OopChar = #39 { apostrophe } then begin
					OopSkipLine(statId, position);
				end else if OopChar = '@' then begin
					OopSkipLine(statId, position);
				end else if (OopChar = '/') or (OopChar = '?') then begin
					if OopChar = '/' then
						repeatInsNextTick := true;

					OopReadWord(statId, position);
					if OopParseDirection(statId, position, deltaX, deltaY) then begin
						if (deltaX <> 0) or (deltaY <> 0) then begin
							if not ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable then
								ElementPushablePush(X + deltaX, Y + deltaY, deltaX, deltaY);

							if ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable then begin
								MoveStat(statId, X + deltaX, Y + deltaY);
								repeatInsNextTick := false;
							end;
						end else begin
							repeatInsNextTick := false;
						end;

						OopReadChar(statId, position);
						if OopChar <> #13 then
							Dec(position);

						stopRunning := true;
					end else begin
						OopError(statId, 'Bad direction');
					end;
				end else if OopChar = '#' then begin
		ReadCommand:
					OopReadWord(statId, position);
					if OopWord = 'THEN' then
						OopReadWord(statId, position);
					if Length(OopWord) = 0 then
						goto ReadInstruction;
					Inc(insCount);
					if Length(OopWord) <> 0 then begin
						if OopWord = 'GO' then begin
							OopReadDirection(statId, position, deltaX, deltaY);

							if not ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable then
								ElementPushablePush(X + deltaX, Y + deltaY, deltaX, deltaY);

							if ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable then begin
								MoveStat(statId, X + deltaX, Y + deltaY);
							end else begin
								repeatInsNextTick := true;
							end;

							stopRunning := true;
						end else if OopWord = 'TRY' then begin
							OopReadDirection(statId, position, deltaX, deltaY);

							if not ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable then
								ElementPushablePush(X + deltaX, Y + deltaY, deltaX, deltaY);

							if ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable then begin
								MoveStat(statId, X + deltaX, Y + deltaY);
								stopRunning := true;
							end else begin
								goto ReadCommand;
							end;
						end else if OopWord = 'WALK' then begin
							OopReadDirection(statId, position, deltaX, deltaY);
							StepX := deltaX;
							StepY := deltaY;
						end else if OopWord = 'SET' then begin
							OopReadWord(statId, position);
							WorldSetFlag(OopWord);
						end else if OopWord = 'CLEAR' then begin
							OopReadWord(statId, position);
							WorldClearFlag(OopWord);
						end else if OopWord = 'IF' then begin
							OopReadWord(statId, position);
							if OopCheckCondition(statId, position) then
								goto ReadCommand;
						end else if OopWord = 'SHOOT' then begin
							OopReadDirection(statId, position, deltaX, deltaY);
							if BoardShoot(E_BULLET, X, Y, deltaX, deltaY, SHOT_SOURCE_ENEMY) then
								SoundQueue(2, #48#1#38#1);
							stopRunning := true;
						end else if OopWord = 'THROWSTAR' then begin
							OopReadDirection(statId, position, deltaX, deltaY);
							if BoardShoot(E_STAR, X, Y, deltaX, deltaY, SHOT_SOURCE_ENEMY) then
								begin end;
							stopRunning := true;
						end else if (OopWord = 'GIVE') or (OopWord = 'TAKE') then begin
							if OopWord = 'TAKE' then
								counterSubtract := true
							else
								counterSubtract := false;

							OopReadWord(statId, position);
							if OopWord = 'HEALTH' then
								counterPtr := @World.Info.Health
							else if OopWord = 'AMMO' then
								counterPtr := @World.Info.Ammo
							else if OopWord = 'GEMS' then
								counterPtr := @World.Info.Gems
							else if OopWord = 'TORCHES' then
								counterPtr := @World.Info.Torches
							else if OopWord = 'SCORE' then
								counterPtr := @World.Info.Score
							else if OopWord = 'TIME' then
								counterPtr := @World.Info.BoardTimeSec
							else
								counterPtr := nil;

							if counterPtr <> nil then begin
								OopReadValue(statId, position);
								if OopValue > 0 then begin
									if counterSubtract then
										OopValue := -OopValue;

									if (counterPtr^ + OopValue) >= 0 then begin
										counterPtr^ := counterPtr^ + OopValue;
									end else begin
										goto ReadCommand;
									end;
								end;
							end;

							GameUpdateSidebar;
						end else if OopWord = 'END' then begin
							position := -1;
							OopChar := #0;
						end else if OopWord = 'ENDGAME' then begin
							World.Info.Health := 0;
						end else if OopWord = 'IDLE' then begin
							stopRunning := true;
						end else if OopWord = 'RESTART' then begin
							position := 0;
							lineFinished := false;
						end else if OopWord = 'ZAP' then begin
							OopReadWord(statId, position);

							labelStatId := 0;
							while OopFindLabel(statId, OopWord, labelStatId, labelDataPos, #13':') do begin
								labelPtr := Board.Stats[labelStatId].Data;
								AdvancePointer(labelPtr, labelDataPos + 1);

								Char(labelPtr^) := #39;
							end;
						end else if OopWord = 'RESTORE' then begin
							OopReadWord(statId, position);

							labelStatId := 0;
							while OopFindLabel(statId, OopWord, labelStatId, labelDataPos, #13#39) do
								repeat
									labelPtr := Board.Stats[labelStatId].Data;
									AdvancePointer(labelPtr, labelDataPos + 1);

									Char(labelPtr^) := ':';

									labelDataPos := OopFindString(labelStatId, #13#39 + OopWord + #13);
								until labelDataPos <= 0;
						end else if OopWord = 'LOCK' then begin
							P2 := 1;
						end else if OopWord = 'UNLOCK' then begin
							P2 := 0;
						end else if OopWord = 'SEND' then begin
							OopReadWord(statId, position);
							if OopSend(statId, OopWord, false) then
								lineFinished := false;
						end else if OopWord = 'BECOME' then begin
							if OopParseTile(statId, position, argTile) then begin
								replaceStat := true;
								replaceTile.Element := argTile.Element;
								replaceTile.Color := argTile.Color;
							end else begin
								OopError(statId, 'Bad #BECOME');
							end;
						end else if OopWord = 'PUT' then begin
							OopReadDirection(statId, position, deltaX, deltaY);
							if (deltaX = 0) and (deltaY = 0) then
								OopError(statId, 'Bad #PUT')
							else if not OopParseTile(statId, position, argTile) then
								OopError(statId, 'Bad #PUT')
							else if ((X + deltaX) > 0)
								and ((X + deltaX) <= BOARD_WIDTH)
								and ((Y + deltaY) > 0)
								and ((Y + deltaY) < BOARD_HEIGHT) then
							begin
								if not ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable then
									ElementPushablePush(X + deltaX, Y + deltaY, deltaX, deltaY);

								OopPlaceTile(X + deltaX, Y + deltaY, argTile);
							end;
						end else if OopWord = 'CHANGE' then begin
							if not OopParseTile(statId, position, argTile) then
								OopError(statId, 'Bad #CHANGE');
							if not OopParseTile(statId, position, argTile2) then
								OopError(statId, 'Bad #CHANGE');

							ix := 0;
							iy := 1;
							if (argTile2.Color = 0)
								and (ElementDefs[argTile2.Element].Color < COLOR_SPECIAL_MIN)
							then
								argTile2.Color := ElementDefs[argTile2.Element].Color;

							while FindTileOnBoard(ix, iy, argTile) do
								OopPlaceTile(ix, iy, argTile2);
						end else if OopWord = 'PLAY' then begin
							textLine := SoundParse(OopReadLineToEnd(statId, position));
							if Length(textLine) <> 0 then
								SoundQueue(-1, textLine);
							lineFinished := false;
						end else if OopWord = 'CYCLE' then begin
							OopReadValue(statId, position);
							if OopValue > 0 then
								Cycle := OopValue;
						end else if OopWord = 'CHAR' then begin
							OopReadValue(statId, position);
							if (OopValue > 0) and (OopValue <= 255) then begin
								P1 := OopValue;
								BoardDrawTile(X, Y);
							end;
						end else if OopWord = 'DIE' then begin
							replaceStat := true;
							replaceTile.Element := E_EMPTY;
							replaceTile.Color := $0F;
						end else if OopWord = 'BIND' then begin
							OopReadWord(statId, position);
							bindStatId := 0;
							if OopIterateStat(statId, bindStatId, OopWord) then begin
								FreeMem(Data, DataLen);
								Data := Board.Stats[bindStatId].Data;
								DataLen := Board.Stats[bindStatId].DataLen;
								position := 0;
							end;
						end else begin
							textLine := OopWord;
							if OopSend(statId, OopWord, false) then begin
								lineFinished := false;
							end else begin
								if Pos(':', textLine) <= 0 then begin
									OopError(statId, 'Bad command ' + textLine);
								end;
							end;
						end;
					end;

					if lineFinished then
						OopSkipLine(statId, position);
				end else if OopChar = #13 then begin
					if textWindow.LineCount > 0 then
						TextWindowAppend(textWindow, '');
				end else if OopChar = #0 then begin
					endOfProgram := true;
				end else begin
					textLine := OopChar + OopReadLineToEnd(statId, position);
					TextWindowAppend(textWindow, textLine);
				end;
			until endOfProgram or stopRunning or repeatInsNextTick or replaceStat or (insCount > 32);

			if repeatInsNextTick then
				position := lastPosition;

			if OopChar = #0 then
				position := -1;

			if textWindow.LineCount > 1 then begin
				namePosition := 0;
				OopReadChar(statId, namePosition);
				if OopChar = '@' then begin
					name := OopReadLineToEnd(statId, namePosition);
				end;

				if Length(name) = 0 then
					name := 'Interaction';

				textWindow.Title := name;
				TextWindowDrawOpen(textWindow);
				TextWindowSelect(textWindow, true, false);
				TextWindowDrawClose;
				TextWindowFree(textWindow);

				if Length(textWindow.Hyperlink) <> 0 then
					if OopSend(statId, textWindow.Hyperlink, false) then
						goto StartParsing;
			end else if textWindow.LineCount = 1 then begin
				DisplayMessage(200, textWindow.Lines[1]^);
				TextWindowFree(textWindow);
			end;

			if replaceStat then begin
				ix := X;
				iy := Y;
				DamageStat(statId);
				OopPlaceTile(ix, iy, replaceTile);
			end;
		end;
	end;

{$F+}

procedure ElementDefaultTick(statId: integer);
	begin
	end;

procedure ElementDefaultTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
	end;

procedure ElementDefaultDraw(x, y: integer; var ch: byte);
	begin
		ch := Ord('?');
	end;

procedure ElementMessageTimerTick(statId: integer);
	begin
		with Board.Stats[statId] do begin
			case X of
				0: begin
					VideoWriteText((60 - Length(Board.Info.Message)) div 2, 24, 9 + (P2 mod 7), ' '+Board.Info.Message+' ');
					P2 := P2 - 1;
					if P2 <= 0 then begin
						RemoveStat(statId);
						CurrentStatTicked := CurrentStatTicked - 1;
						BoardDrawBorder;
						Board.Info.Message := '';
					end;
				end;
			end;
		end;
	end;

procedure ElementDamagingTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		BoardAttack(sourceStatId, x, y);
	end;

procedure ElementLionTick(statId: integer);
	var
		deltaX, deltaY: integer;
	begin
		with Board.Stats[statId] do begin
			if P1 < Random(10) then
				CalcDirectionRnd(deltaX, deltaY)
			else
				CalcDirectionSeek(X, Y, deltaX, deltaY);

			if ElementDefs[Board.Tiles[X + deltaX][Y + deltaY].Element].Walkable then begin
				MoveStat(statId, X + deltaX, Y + deltaY);
			end else if Board.Tiles[X + deltaX][Y + deltaY].Element = E_PLAYER then begin
				BoardAttack(statId, X + deltaX, Y + deltaY)
			end;
		end;
	end;

procedure ElementTigerTick(statId: integer);
	var
		shot: boolean;
		element: byte;
	begin
		with Board.Stats[statId] do begin
			element := E_BULLET;
			if P2 >= $80 then
				element := E_STAR;

			if (Random(10) * 3) <= (P2 mod $80) then begin
				if Difference(X, Board.Stats[0].X) <= 2 then begin
					shot := BoardShoot(element, X, Y, 0, Signum(Board.Stats[0].Y - Y), SHOT_SOURCE_ENEMY);
				end else begin
					shot := false;
				end;

				if not shot then begin
					if Difference(Y, Board.Stats[0].Y) <= 2 then begin
						shot := BoardShoot(element, X, Y, Signum(Board.Stats[0].X - X), 0, SHOT_SOURCE_ENEMY);
					end;
				end;
			end;

			ElementLionTick(statId);
		end;
	end;

procedure ElementRuffianTick(statId: integer);
	begin
		with Board.Stats[statId] do begin
			if (StepX = 0) and (StepY = 0) then begin
				if (P2 + 8) <= Random(17) then begin
					if P1 >= Random(9) then
						CalcDirectionSeek(X, Y, StepX, StepY)
					else
						CalcDirectionRnd(StepX, StepY);
				end;
			end else begin
				if ((Y = Board.Stats[0].Y) or (X = Board.Stats[0].X)) and (Random(9) <= P1) then begin
					CalcDirectionSeek(X, Y, StepX, StepY);
				end;

				with Board.Tiles[X + StepX][Y + StepY] do begin
					if Element = E_PLAYER then begin
						BoardAttack(statId, X + StepX, Y + StepY)
					end else if ElementDefs[Element].Walkable then begin
						MoveStat(statId, X + StepX, Y + StepY);
						if (P2 + 8) <= Random(17) then begin
							StepX := 0;
							StepY := 0;
						end;
					end else begin
						StepX := 0;
						StepY := 0;
					end;
				end;

			end;
		end;
	end;

procedure ElementBearTick(statId: integer);
	var
		deltaX, deltaY: integer;
	label Movement;
	begin
		with Board.Stats[statId] do begin
			if X <> Board.Stats[0].X then
				if Difference(Y, Board.Stats[0].Y) <= (8 - P1) then begin
					deltaX := Signum(Board.Stats[0].X - X);
					deltaY := 0;
					goto Movement;
				end;

			if Difference(X, Board.Stats[0].X) <= (8 - P1) then begin
				deltaY := Signum(Board.Stats[0].Y - Y);
				deltaX := 0;
			end else begin
				deltaX := 0;
				deltaY := 0;
			end;

		Movement:
			with Board.Tiles[X + deltaX][Y + deltaY] do begin
				if ElementDefs[Element].Walkable then begin
					MoveStat(statId, X + deltaX, Y + deltaY);
				end else if (Element = E_PLAYER) or (Element = E_BREAKABLE) then begin
					BoardAttack(statId, X + deltaX, Y + deltaY)
				end;
			end;

		end;
	end;

procedure ElementCentipedeHeadTick(statId: integer);
	var
		ix, iy: integer;
		tx, ty: integer;
		tmp: integer;
	begin
		with Board.Stats[statId] do begin
			if (X = Board.Stats[0].X) and (Random(10) < P1) then begin
				StepY := Signum(Board.Stats[0].Y - Y);
				StepX := 0;
			end else if (Y = Board.Stats[0].Y) and (Random(10) < P1) then begin
				StepX := Signum(Board.Stats[0].X - X);
				StepY := 0;
			end else if ((Random(10) * 4) < P2) or ((StepX = 0) and (StepY = 0)) then begin
				CalcDirectionRnd(StepX, StepY);
			end;

			if not ElementDefs[Board.Tiles[X + StepX][Y + StepY].Element].Walkable
				and (Board.Tiles[X + StepX][Y + StepY].Element <> E_PLAYER) then
			begin
				ix := StepX;
				iy := StepY;
				tmp := ((Random(2) * 2) - 1) * StepY;
				StepY := ((Random(2) * 2) - 1) * StepX;
				StepX := tmp;
				if not ElementDefs[Board.Tiles[X + StepX][Y + StepY].Element].Walkable
					and (Board.Tiles[X + StepX][Y + StepY].Element <> E_PLAYER) then
				begin
					StepX := -StepX;
					StepY := -StepY;
					if not ElementDefs[Board.Tiles[X + StepX][Y + StepY].Element].Walkable
						and (Board.Tiles[X + StepX][Y + StepY].Element <> E_PLAYER) then
					begin
						if ElementDefs[Board.Tiles[X - ix][Y - iy].Element].Walkable
							or (Board.Tiles[X - ix][Y - iy].Element = E_PLAYER) then
						begin
							StepX := -ix;
							StepY := -iy;
						end else begin
							StepX := 0;
							StepY := 0;
						end;
					end;
				end;
			end;

			if (StepX = 0) and (StepY = 0) then begin
				Board.Tiles[X][Y].Element := E_CENTIPEDE_SEGMENT;
				Leader := -1;
				while Board.Stats[statId].Follower > 0 do begin
					tmp := Board.Stats[statId].Follower;
					Board.Stats[statId].Follower := Board.Stats[statId].Leader;
					Board.Stats[statId].Leader := tmp;
					statId := tmp;
				end;
				Board.Stats[statId].Follower := Board.Stats[statId].Leader;
				Board.Tiles[Board.Stats[statId].X][Board.Stats[statId].Y].Element := E_CENTIPEDE_HEAD;
			end else if Board.Tiles[X + StepX][Y + StepY].Element = E_PLAYER then begin
				if Follower <> -1 then begin
					Board.Tiles[Board.Stats[Follower].X][Board.Stats[Follower].Y].Element := E_CENTIPEDE_HEAD;
					Board.Stats[Follower].StepX := StepX;
					Board.Stats[Follower].StepY := StepY;
					BoardDrawTile(Board.Stats[Follower].X, Board.Stats[Follower].Y);
				end;
				BoardAttack(statId, X + StepX, Y + StepY);
			end else begin
				MoveStat(statId, X + StepX, Y + StepY);
				tx := X - StepX;
				ty := Y - StepY;
				ix := StepX;
				iy := StepY;

				repeat
					with Board.Stats[statId] do begin
						tx := X - StepX;
						ty := Y - StepY;
						ix := StepX;
						iy := StepY;
						if Follower < 0 then begin
							if (Board.Tiles[tx - ix][ty - iy].Element = E_CENTIPEDE_SEGMENT)
								and (Board.Stats[GetStatIdAt(tx - ix, ty - iy)].Leader < 0) then
							begin
								Follower := GetStatIdAt(tx - ix, ty - iy)
							end else if (Board.Tiles[tx - iy][ty - ix].Element = E_CENTIPEDE_SEGMENT)
								and (Board.Stats[GetStatIdAt(tx - iy, ty - ix)].Leader < 0) then
							begin
								Follower := GetStatIdAt(tx - iy, ty - ix);
							end else if (Board.Tiles[tx + iy][ty + ix].Element = E_CENTIPEDE_SEGMENT)
								and (Board.Stats[GetStatIdAt(tx + iy, ty + ix)].Leader < 0) then
							begin
								Follower := GetStatIdAt(tx + iy, ty + ix);
							end;
						end;

						if Follower > 0 then begin
							Board.Stats[Follower].Leader := statId;
							Board.Stats[Follower].P1 := P1;
							Board.Stats[Follower].P2 := P2;
							Board.Stats[Follower].StepX := tx - Board.Stats[Follower].X;
							Board.Stats[Follower].StepY := ty - Board.Stats[Follower].Y;
							MoveStat(Follower, tx, ty);
						end;
						statId := Follower;
					end;
				until statId = -1;
			end;
		end;
	end;

procedure ElementCentipedeSegmentTick(statId: integer);
	begin
		with Board.Stats[statId] do begin
			if Leader < 0 then begin
				if Leader < -1 then
					Board.Tiles[X][Y].Element := E_CENTIPEDE_HEAD
				else
					Leader := Leader - 1;
			end;
		end;
	end;

procedure ElementBulletTick(statId: integer);
	var
		ix, iy: integer;
		iStat: integer;
		iElem: byte;
		firstTry: boolean;
	label TryMove;
	begin
		with Board.Stats[statId] do begin
			firstTry := true;

		TryMove:
			ix := X + StepX;
			iy := Y + StepY;
			iElem := Board.Tiles[ix][iy].Element;

			if ElementDefs[iElem].Walkable or (iElem = E_WATER) then begin
				MoveStat(statId, ix, iy);
				exit;
			end;

			if (iElem = E_RICOCHET) and firstTry then begin
				StepX := -StepX;
				StepY := -StepY;
				SoundQueue(1, #249#1);
				firstTry := false;
				goto TryMove;
				exit;
			end;

			if (iElem = E_BREAKABLE)
				or (ElementDefs[iElem].Destructible and ((iElem = E_PLAYER) or (P1 = 0))) then
			begin
				if ElementDefs[iElem].ScoreValue <> 0 then begin
					World.Info.Score := World.Info.Score + ElementDefs[iElem].ScoreValue;
					GameUpdateSidebar;
				end;
				BoardAttack(statId, ix, iy);
				exit;
			end;

			if (Board.Tiles[X + StepY][Y + StepX].Element = E_RICOCHET) and firstTry then begin
				ix := StepX;
				StepX := -StepY;
				StepY := -ix;
				SoundQueue(1, #249#1);
				firstTry := false;
				goto TryMove;
				exit;
			end;

			if (Board.Tiles[X - StepY][Y - StepX].Element = E_RICOCHET) and firstTry then begin
				ix := StepX;
				StepX := StepY;
				StepY := ix;
				SoundQueue(1, #249#1);
				firstTry := false;
				goto TryMove;
				exit;
			end;

			RemoveStat(statId);
			CurrentStatTicked := CurrentStatTicked - 1;
			if (iElem = E_OBJECT) or (iElem = E_SCROLL) then begin
				iStat := GetStatIdAt(ix, iy);
				if OopSend(-iStat, 'SHOT', false) then begin end;
			end;
		end;
	end;

procedure ElementSpinningGunDraw(x, y: integer; var ch: byte);
	begin
		case CurrentTick mod 8 of
			0, 1: ch := 24;
			2, 3: ch := 26;
			4, 5: ch := 25;
		else ch := 27 end;
	end;

procedure ElementLineDraw(x, y: integer; var ch: byte);
	var
		i, v, shift: integer;
	begin
		v := 1;
		shift := 1;
		for i := 0 to 3 do begin
			case Board.Tiles[x + NeighborDeltaX[i]][y + NeighborDeltaY[i]].Element of
				E_LINE, E_BOARD_EDGE: v := v + shift;
			end;
			shift := shift shl 1;
		end;
		ch := Ord(LineChars[v]);
	end;

procedure ElementSpinningGunTick(statId: integer);
	var
		shot: boolean;
		deltaX, deltaY: integer;
		element: byte;
	begin
		with Board.Stats[statId] do begin
			BoardDrawTile(X, Y);

			element := E_BULLET;
			if P2 >= $80 then
				element := E_STAR;

			if Random(9) < (P2 mod $80) then begin
				if Random(9) <= P1 then begin
					if Difference(X, Board.Stats[0].X) <= 2 then begin
						shot := BoardShoot(element, X, Y, 0, Signum(Board.Stats[0].Y - Y), SHOT_SOURCE_ENEMY);
					end else begin
						shot := false;
					end;

					if not shot then begin
						if Difference(Y, Board.Stats[0].Y) <= 2 then begin
							shot := BoardShoot(element, X, Y, Signum(Board.Stats[0].X - X), 0, SHOT_SOURCE_ENEMY);
						end;
					end;
				end else begin
					CalcDirectionRnd(deltaX, deltaY);
					shot := BoardShoot(element, X, Y, deltaX, deltaY, SHOT_SOURCE_ENEMY);
				end;
			end;
		end;
	end;

procedure ElementConveyorTick(x, y: integer; direction: integer);
	var
		i: integer;
		iStat: integer;
		ix, iy: integer;
		canMove: boolean;
		tiles: array[0..7] of TTile;
		iMin, iMax: integer;
		tmpTile: TTile;
	begin
		if direction = 1 then begin
			iMin := 0;
			iMax := 8;
		end else begin
			iMin := 7;
			iMax := -1;
		end;

		canMove := true;
		i := iMin;
		repeat
			tiles[i] := Board.Tiles[x + DiagonalDeltaX[i]][y + DiagonalDeltaY[i]];
			with tiles[i] do begin
				if Element = E_EMPTY then
					canMove := true
				else if not ElementDefs[Element].Pushable then
					canMove := false;
			end;
			i := i + direction;
		until i = iMax;

		i := iMin;
		repeat
			with tiles[i] do begin
				if canMove then begin
					if ElementDefs[Element].Pushable then begin
						ix := x + DiagonalDeltaX[(i - direction + 8) mod 8];
						iy := y + DiagonalDeltaY[(i - direction + 8) mod 8];
						if ElementDefs[Element].Cycle > -1 then begin
							tmpTile := Board.Tiles[x + DiagonalDeltaX[i]][y + DiagonalDeltaY[i]];
							iStat := GetStatIdAt(x + DiagonalDeltaX[i], y + DiagonalDeltaY[i]);
							Board.Tiles[x + DiagonalDeltaX[i]][y + DiagonalDeltaY[i]] := tiles[i];
							Board.Tiles[ix][iy].Element := E_EMPTY;
							MoveStat(iStat, ix, iy);
							Board.Tiles[x + DiagonalDeltaX[i]][y + DiagonalDeltaY[i]] := tmpTile;
						end else begin
							Board.Tiles[ix][iy] := tiles[i];
							BoardDrawTile(ix, iy);
						end;
						if not ElementDefs[tiles[(i + direction + 8) mod 8].Element].Pushable then begin
							Board.Tiles[x + DiagonalDeltaX[i]][y + DiagonalDeltaY[i]].Element := E_EMPTY;
							BoardDrawTile(x + DiagonalDeltaX[i], y + DiagonalDeltaY[i]);
						end;
					end else begin
						canMove := false;
					end;
				end else if Element = E_EMPTY then
					canMove := true
				else if not ElementDefs[Element].Pushable then
					canMove := false;
			end;
			i := i + direction;
		until i = iMax;
	end;

procedure ElementConveyorCWDraw(x, y: integer; var ch: byte);
	begin
		case (CurrentTick div ElementDefs[E_CONVEYOR_CW].Cycle) mod 4 of
			0: ch := 179;
			1: ch := 47;
			2: ch := 196;
		else ch := 92 end;
	end;

procedure ElementConveyorCWTick(statId: integer);
	begin
		with Board.Stats[statId] do begin
			BoardDrawTile(X, Y);
			ElementConveyorTick(X, Y, 1);
		end;
	end;

procedure ElementConveyorCCWDraw(x, y: integer; var ch: byte);
	begin
		case (CurrentTick div ElementDefs[E_CONVEYOR_CCW].Cycle) mod 4 of
			3: ch := 179;
			2: ch := 47;
			1: ch := 196;
		else ch := 92 end;
	end;

procedure ElementConveyorCCWTick(statId: integer);
	begin
		with Board.Stats[statId] do begin
			BoardDrawTile(X, Y);
			ElementConveyorTick(X, Y, -1);
		end;
	end;

procedure ElementBombDraw(x, y: integer; var ch: byte);
	begin
		with Board.Stats[GetStatIdAt(x, y)] do
			if P1 <= 1 then
				ch := 11
			else
				ch := 48 + P1;
	end;

procedure ElementBombTick(statId: integer);
	var
		oldX, oldY: integer;
	begin
		with Board.Stats[statId] do begin
			if P1 > 0 then begin
				P1 := P1 - 1;
				BoardDrawTile(X, Y);

				if P1 = 1 then begin
					SoundQueue(1, #96#1#80#1#64#1#48#1#32#1#16#1);
					DrawPlayerSurroundings(X, Y, 1);
				end else if P1 = 0 then begin
					oldX := X;
					oldY := Y;
					RemoveStat(statId);
					DrawPlayerSurroundings(oldX, oldY, 2);
				end else begin
					if (P1 mod 2) = 0 then
						SoundQueue(1, #248#1)
					else
						SoundQueue(1, #245#1);
				end;
			end;
		end;
	end;

procedure ElementBombTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		with Board.Stats[GetStatIdAt(x, y)] do begin
			if P1 = 0 then begin
				P1 := 9;
				BoardDrawTile(X, Y);
				DisplayMessage(200, 'Bomb activated!');
				SoundQueue(4, #48#1#53#1#64#1#69#1#80#1);
			end else begin
				ElementPushablePush(X, Y, deltaX, deltaY);
			end;
		end;
	end;

procedure ElementTransporterMove(x, y, deltaX, deltaY: integer);
	var
		ix, iy: integer;
		newX, newY: integer;
		iStat: integer;
		finishSearch: boolean;
		isValidDest: boolean;
	begin
		with Board.Stats[GetStatIdAt(x + deltaX, y + deltaY)] do begin
			if (deltaX = StepX) and (deltaY = StepY) then begin
				ix := X;
				iy := Y;
				newX := -1;
				finishSearch := false;
				isValidDest := true;
				repeat
					ix := ix + deltaX;
					iy := iy + deltaY;
					with Board.Tiles[ix][iy] do begin
						if Element = E_BOARD_EDGE then
							finishSearch := true
						else if isValidDest then begin
							isValidDest := false;

							if not ElementDefs[Element].Walkable then
								ElementPushablePush(ix, iy, deltaX, deltaY);

							if ElementDefs[Element].Walkable then begin
								finishSearch := true;
								newX := ix;
								newY := iy;
							end else begin
								newX := -1
							end;
						end;
						if Element = E_TRANSPORTER then begin
							iStat := GetStatIdAt(ix, iy);
							if (Board.Stats[iStat].StepX = -deltaX) and (Board.Stats[iStat].StepY = -deltaY) then
								isValidDest := true;
						end;
					end;
				until finishSearch;
				if newX <> -1 then begin
					ElementMove(X - deltaX, Y - deltaY, newX, newY);
					SoundQueue(3, #48#1#66#1#52#1#70#1#56#1#74#1#64#1#82#1);
				end;
			end;
		end;
	end;

procedure ElementTransporterTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		ElementTransporterMove(x - deltaX, y - deltaY, deltaX, deltaY);
		deltaX := 0;
		deltaY := 0;
	end;

procedure ElementTransporterTick(statId: integer);
	begin
		with Board.Stats[statId] do
			BoardDrawTile(X, Y);
	end;

procedure ElementTransporterDraw(x, y: integer; var ch: byte);
	begin
		with Board.Stats[GetStatIdAt(x, y)] do begin
			if StepX = 0 then
				ch := Ord(TransporterNSChars[StepY * 2 + 3 + (CurrentTick div Cycle) mod 4])
			else
				ch := Ord(TransporterEWChars[StepX * 2 + 3 + (CurrentTick div Cycle) mod 4]);
		end;
	end;

procedure ElementStarDraw(x, y: integer; var ch: byte);
	begin
		ch := Ord(StarAnimChars[(CurrentTick mod 4) + 1]);
		Board.Tiles[x][y].Color := Board.Tiles[x][y].Color + 1;
		if Board.Tiles[x][y].Color > 15 then
			Board.Tiles[x][y].Color := 9;
	end;

procedure ElementStarTick(statId: integer);
	begin
		with Board.Stats[statId] do begin
			P2 := P2 - 1;
			if P2 <= 0 then begin
				RemoveStat(statId);
			end else if (P2 mod 2) = 0 then begin
				CalcDirectionSeek(X, Y, StepX, StepY);
				with Board.Tiles[X + StepX][Y + StepY] do begin
					if (Element = E_PLAYER) or (Element = E_BREAKABLE) then begin
						BoardAttack(statId, X + StepX, Y + StepY);
					end else begin
						if not ElementDefs[Element].Walkable then
							ElementPushablePush(X + StepX, Y + StepY, StepX, StepY);

						if ElementDefs[Element].Walkable or (Element = E_WATER) then
							MoveStat(statId, X + StepX, Y + StepY);
					end;
				end;
			end else begin
				BoardDrawTile(X, Y);
			end;
		end;
	end;

procedure ElementEnergizerTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		SoundQueue(9, #32#3#35#3#36#3#37#3#53#3#37#3#35#3#32#3
			+ #48#3#35#3#36#3#37#3#53#3#37#3#35#3#32#3
			+ #48#3#35#3#36#3#37#3#53#3#37#3#35#3#32#3
			+ #48#3#35#3#36#3#37#3#53#3#37#3#35#3#32#3
			+ #48#3#35#3#36#3#37#3#53#3#37#3#35#3#32#3
			+ #48#3#35#3#36#3#37#3#53#3#37#3#35#3#32#3
			+ #48#3#35#3#36#3#37#3#53#3#37#3#35#3#32#3);

		Board.Tiles[x][y].Element := E_EMPTY;
		BoardDrawTile(x, y);

		World.Info.EnergizerTicks := 75;
		GameUpdateSidebar;

		if MessageEnergizerNotShown then begin
			DisplayMessage(200, 'Energizer - You are invincible');
			MessageEnergizerNotShown := false;
		end;

		if OopSend(0, 'ALL:ENERGIZE', false) then begin end;
	end;

procedure ElementSlimeTick(statId: integer);
	var
		dir, color, changedTiles: integer;
		startX, startY: integer;
	begin
		with Board.Stats[statId] do begin
			if P1 < P2 then
				P1 := P1 + 1
			else begin
				color := Board.Tiles[X][Y].Color;
				P1 := 0;
				startX := X;
				startY := Y;
				changedTiles := 0;

				for dir := 0 to 3 do begin
					if ElementDefs[Board.Tiles[startX + NeighborDeltaX[dir]][startY + NeighborDeltaY[dir]].Element].Walkable then begin
						if changedTiles = 0 then begin
							MoveStat(statId, startX + NeighborDeltaX[dir], startY + NeighborDeltaY[dir]);
							Board.Tiles[startX][startY].Color := color;
							Board.Tiles[startX][startY].Element := E_BREAKABLE;
							BoardDrawTile(startX, startY);
						end else begin
							AddStat(startX + NeighborDeltaX[dir], startY + NeighborDeltaY[dir], E_SLIME, color,
								ElementDefs[E_SLIME].Cycle, StatTemplateDefault);
							Board.Stats[Board.StatCount].P2 := P2;
						end;

						changedTiles := changedTiles + 1;
					end;
				end;

				if changedTiles = 0 then begin
					RemoveStat(statId);
					Board.Tiles[startX][startY].Element := E_BREAKABLE;
					Board.Tiles[startX][startY].Color := color;
					BoardDrawTile(startX, startY);
				end;
			end;
		end;
	end;

procedure ElementSlimeTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	var
		color: integer;
	begin
		color := Board.Tiles[x][y].Color;
		DamageStat(GetStatIdAt(x, y));
		Board.Tiles[x][y].Element := E_BREAKABLE;
		Board.Tiles[x][y].Color := color;
		BoardDrawTile(x, y);
		SoundQueue(2, #32#1#35#1);
	end;

procedure ElementSharkTick(statId: integer);
	var
		deltaX, deltaY: integer;
	begin
		with Board.Stats[statId] do begin
			if P1 < Random(10) then
				CalcDirectionRnd(deltaX, deltaY)
			else
				CalcDirectionSeek(X, Y, deltaX, deltaY);

			if Board.Tiles[X + deltaX][Y + deltaY].Element = E_WATER then
				MoveStat(statId, X + deltaX, Y + deltaY)
			else if Board.Tiles[X + deltaX][Y + deltaY].Element = E_PLAYER then
				BoardAttack(statId, X + deltaX, Y + deltaY);
		end;
	end;

procedure ElementBlinkWallDraw(x, y: integer; var ch: byte);
	begin
		ch := 206;
	end;

procedure ElementBlinkWallTick(statId: integer);
	var
		ix, iy: integer;
		hitBoundary: boolean;
		playerStatId: integer;
		el: integer;
	begin
		with Board.Stats[statId] do begin
			if P3 = 0 then
				P3 := P1 + 1;
			if P3 = 1 then begin
				ix := X + StepX;
				iy := Y + StepY;

				if StepX <> 0 then
					el := E_BLINK_RAY_EW
				else
					el := E_BLINK_RAY_NS;

				while (Board.Tiles[ix][iy].Element = el)
					and (Board.Tiles[ix][iy].Color = Board.Tiles[X][Y].Color) do
				begin
					Board.Tiles[ix][iy].Element := E_EMPTY;
					BoardDrawTile(ix, iy);
					ix := ix + StepX;
					iy := iy + StepY;
					P3 := (P2) * 2 + 1;
				end;

				if ((X + StepX) = ix) and ((Y + StepY) = iy) then begin
					hitBoundary := false;
					repeat
						if (Board.Tiles[ix][iy].Element <> E_EMPTY) and (ElementDefs[Board.Tiles[ix][iy].Element].Destructible) then
							BoardDamageTile(ix, iy);

						if Board.Tiles[ix][iy].Element = E_PLAYER then begin
							playerStatId := GetStatIdAt(ix, iy);
							if StepX <> 0 then begin
								if Board.Tiles[ix][iy - 1].Element = E_EMPTY then
									MoveStat(playerStatId, ix, iy - 1)
								else if Board.Tiles[ix][iy + 1].Element = E_EMPTY then
									MoveStat(playerStatId, ix, iy + 1);
							end else begin
								if Board.Tiles[ix + 1][iy].Element = E_EMPTY then
									MoveStat(playerStatId, ix + 1, iy)
								else if Board.Tiles[ix - 1][iy].Element = E_EMPTY then
									MoveStat(playerStatId, ix + 1, iy);
							end;

							if Board.Tiles[ix][iy].Element = E_PLAYER then begin
								while World.Info.Health > 0 do
									DamageStat(playerStatId);
								hitBoundary := true;
							end;
						end;

						if Board.Tiles[ix][iy].Element = E_EMPTY then begin
							Board.Tiles[ix][iy].Element := el;
							Board.Tiles[ix][iy].Color := Board.Tiles[X][Y].Color;
							BoardDrawTile(ix, iy);
						end else begin
							hitBoundary := true;
						end;

						ix := ix + StepX;
						iy := iy + StepY;
					until hitBoundary;

					P3 := (P2 * 2) + 1;
				end;
			end else begin
				P3 := P3 - 1;
			end;
		end;
	end;

{$F-}

procedure ElementMove(oldX, oldY, newX, newY: integer);
	var
		statId: integer;
	begin
		statId := GetStatIdAt(oldX, oldY);

		if statId >= 0 then begin
			MoveStat(statId, newX, newY);
		end else begin
			Board.Tiles[newX][newY] := Board.Tiles[oldX][oldY];
			BoardDrawTile(newX, newY);
			Board.Tiles[oldX][oldY].Element := E_EMPTY;
			BoardDrawTile(oldX, oldY);
		end;
	end;

procedure ElementPushablePush(x, y: integer; deltaX, deltaY: integer);
	var
		unk1: integer;
	begin
		with Board.Tiles[x][y] do begin
			if ((Element = E_SLIDER_NS) and (deltaX = 0)) or ((Element = E_SLIDER_EW) and (deltaY = 0))
				or ElementDefs[Element].Pushable then
			begin
				if Board.Tiles[x + deltaX][y + deltaY].Element = E_TRANSPORTER then
					ElementTransporterMove(x, y, deltaX, deltaY)
				else if Board.Tiles[x + deltaX][y + deltaY].Element <> E_EMPTY then
					ElementPushablePush(x + deltaX, y + deltaY, deltaX, deltaY);

				if not ElementDefs[Board.Tiles[x + deltaX][y + deltaY].Element].Walkable
					and ElementDefs[Board.Tiles[x + deltaX][y + deltaY].Element].Destructible
					and (Board.Tiles[x + deltaX][y + deltaY].Element <> E_PLAYER) then
				begin
					BoardDamageTile(x + deltaX, y + deltaY);
				end;

				if ElementDefs[Board.Tiles[x + deltaX][y + deltaY].Element].Walkable then
					ElementMove(x, y, x + deltaX, y + deltaY);
			end;
		end;
	end;

{$F+}

procedure ElementDuplicatorDraw(x, y: integer; var ch: byte);
	begin
		with Board.Stats[GetStatIdAt(x, y)] do
			case P1 of
				1: ch := 250;
				2: ch := 249;
				3: ch := 248;
				4: ch := 111;
				5: ch := 79;
			else ch := 250 end;
	end;

procedure ElementObjectTick(statId: integer);
	var
		retVal: boolean;
	begin
		with Board.Stats[statId] do begin
			if DataPos >= 0 then
				OopExecute(statId, DataPos, 'Interaction');

			if (StepX <> 0) or (StepY <> 0) then begin
				if ElementDefs[Board.Tiles[X + StepX][Y + StepY].Element].Walkable then
					MoveStat(statId, X + StepX, Y + StepY)
				else
					retVal := OopSend(-statId, 'THUD', false);
			end;
		end;
	end;

procedure ElementObjectDraw(x, y: integer; var ch: byte);
	begin
		ch := Board.Stats[GetStatIdAt(x, y)].P1;
	end;

procedure ElementObjectTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	var
		statId: integer;
		retVal: boolean;
	begin
		statId := GetStatIdAt(x, y);
		retVal := OopSend(-statId, 'TOUCH', false);
	end;

procedure ElementDuplicatorTick(statId: integer);
	var
		sourceStatId: integer;
	begin
		with Board.Stats[statId] do begin
			if P1 <= 4 then begin
				P1 := P1 + 1;
				BoardDrawTile(X, Y);
			end else begin
				P1 := 0;
				if Board.Tiles[X - StepX][Y - StepY].Element = E_PLAYER then begin
					ElementDefs[Board.Tiles[X + StepX][Y + StepY].Element]
						.TouchProc(X + StepX, Y + StepY, 0, InputDeltaX, InputDeltaY);
				end else begin
					if Board.Tiles[X - StepX][Y - StepY].Element <> E_EMPTY then
						ElementPushablePush(X - StepX, Y - StepY, -StepX, -StepY);

					if Board.Tiles[X - StepX][Y - StepY].Element = E_EMPTY then begin
						sourceStatId := GetStatIdAt(X + StepX, Y + StepY);
						if sourceStatId > 0 then begin
							if Board.StatCount < (MAX_STAT + 24) then begin
								AddStat(X - StepX, Y - StepY,
									Board.Tiles[X + StepX][Y + StepY].Element,
									Board.Tiles[X + StepX][Y + StepY].Color,
									Board.Stats[sourceStatId].Cycle, Board.Stats[sourceStatId]);
								BoardDrawTile(X - StepX, Y - StepY);
							end;
						end else if sourceStatId <> 0 then begin
							Board.Tiles[X - StepX][Y - StepY]
								:= Board.Tiles[X + StepX][Y + StepY];
							BoardDrawTile(X - StepX, Y - StepY);
						end;

						SoundQueue(3, #48#2#50#2#52#2#53#2#55#2);
					end else begin
						SoundQueue(3, #24#1#22#1);
					end;
				end;

				P1 := 0;
				BoardDrawTile(X, Y);
			end;

			Cycle := (9 - P2) * 3;
		end;
	end;

procedure ElementScrollTick(statId: integer);
	begin
		with Board.Stats[statId] do begin
			Board.Tiles[X][Y].Color := Board.Tiles[X][Y].Color + 1;
			if Board.Tiles[X][Y].Color > $0F then
				Board.Tiles[X][Y].Color := $09;

			BoardDrawTile(X, Y);
		end;
	end;

procedure ElementScrollTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	var
		textWindow: TTextWindowState;
		statId: integer;
		unk1: integer;
	begin
		statId := GetStatIdAt(x, y);

		with Board.Stats[statId] do begin
			textWindow.Selectable := false;
			textWindow.LinePos := 1;

			SoundQueue(2, SoundParse('c-c+d-d+e-e+f-f+g-g'));

			DataPos := 0;
			OopExecute(statId, DataPos, 'Scroll');
		end;

		RemoveStat(GetStatIdAt(x, y));
	end;

procedure ElementKeyTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	var
		key: integer;
	begin
		key := Board.Tiles[x][y].Color mod 8;

		if World.Info.Keys[key] then begin
			DisplayMessage(200, 'You already have a '+ColorNames[key]+' key!');
			SoundQueue(2, #48#2#32#2);
		end else begin
			World.Info.Keys[key] := true;
			Board.Tiles[x][y].Element := E_EMPTY;
			GameUpdateSidebar;
			DisplayMessage(200, 'You now have the '+ColorNames[key]+' key.');
			SoundQueue(2, #64#1#68#1#71#1#64#1#68#1#71#1#64#1#68#1#71#1#80#2);
		end;
	end;

procedure ElementAmmoTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		World.Info.Ammo := World.Info.Ammo + 5;

		Board.Tiles[x][y].Element := E_EMPTY;
		GameUpdateSidebar;
		SoundQueue(2, #48#1#49#1#50#1);

		if MessageAmmoNotShown then begin
			MessageAmmoNotShown := false;
			DisplayMessage(200, 'Ammunition - 5 shots per container.');
		end;
	end;

procedure ElementGemTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		World.Info.Gems := World.Info.Gems + 1;
		World.Info.Health := World.Info.Health + 1;
		World.Info.Score := World.Info.Score + 10;

		Board.Tiles[x][y].Element := E_EMPTY;
		GameUpdateSidebar;
		SoundQueue(2, #64#1#55#1#52#1#48#1);

		if MessageGemNotShown then begin
			MessageGemNotShown := false;
			DisplayMessage(200, 'Gems give you Health!');
		end;
	end;

procedure ElementPassageTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		BoardPassageTeleport(x, y);
		deltaX := 0;
		deltaY := 0;
	end;

procedure ElementDoorTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	var
		key: integer;
	begin
		key := (Board.Tiles[x][y].Color div 16) mod 8;

		if World.Info.Keys[key] then begin
			Board.Tiles[x][y].Element := E_EMPTY;
			BoardDrawTile(x, y);

			World.Info.Keys[key] := false;
			GameUpdateSidebar;

			DisplayMessage(200, 'The '+ColorNames[key]+' door is now open.');
			SoundQueue(3, #48#1#55#1#59#1#48#1#55#1#59#1#64#4);
		end else begin
			DisplayMessage(200, 'The '+ColorNames[key]+' door is locked!');
			SoundQueue(3, #23#1#16#1);
		end;
	end;

procedure ElementPushableTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		ElementPushablePush(x, y, deltaX, deltaY);
		SoundQueue(2, #21#1);
	end;

procedure ElementPusherDraw(x, y: integer; var ch: byte);
	begin
		with Board.Stats[GetStatIdAt(x, y)] do begin
			if StepX = 1 then
				ch := 16
			else if StepX = -1 then
				ch := 17
			else if StepY = -1 then
				ch := 30
			else
				ch := 31;
		end;
	end;

procedure ElementPusherTick(statId: integer);
	var
		i, startX, startY: integer;
	begin
		with Board.Stats[statId] do begin
			startX := X;
			startY := Y;

			if not ElementDefs[Board.Tiles[X + StepX][Y + StepY].Element].Walkable then begin
				ElementPushablePush(X + StepX, Y + StepY, StepX, StepY);
			end;
		end;

		statId := GetStatIdAt(startX, startY);
		with Board.Stats[statId] do begin
			if ElementDefs[Board.Tiles[X + StepX][Y + StepY].Element].Walkable then begin
				MoveStat(statId, X + StepX, Y + StepY);
				SoundQueue(2, #21#1);

				if Board.Tiles[X - (StepX * 2)][Y - (StepY * 2)].Element = E_PUSHER then begin
					i := GetStatIdAt(X - (StepX * 2), Y - (StepY * 2));
					if (Board.Stats[i].StepX = StepX) and (Board.Stats[i].StepY = StepY) then
						ElementDefs[E_PUSHER].TickProc(i);
				end;
			end;
		end;
	end;

procedure ElementTorchTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		World.Info.Torches := World.Info.Torches + 1;
		Board.Tiles[x][y].Element := E_EMPTY;

		BoardDrawTile(x, y);
		GameUpdateSidebar;

		if MessageTorchNotShown then begin
			DisplayMessage(200, 'Torch - used for lighting in the underground.');
		end;
		MessageTorchNotShown := false;

		SoundQueue(3, #48#1#57#1#52#2);
	end;

procedure ElementInvisibleTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		with Board.Tiles[x][y] do begin
			Element := E_NORMAL;
			BoardDrawTile(x, y);

			SoundQueue(3, #18#1#16#1);
			DisplayMessage(100, 'You are blocked by an invisible wall.');
		end;
	end;

procedure ElementForestTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		Board.Tiles[x][y].Element := E_EMPTY;
		BoardDrawTile(x, y);

		SoundQueue(3, #57#1);

		if MessageForestNotShown then begin
			DisplayMessage(200, 'A path is cleared through the forest.');
		end;
		MessageForestNotShown := false;
	end;

procedure ElementFakeTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		if MessageFakeNotShown then begin
			DisplayMessage(150, 'A fake wall - secret passage!');
		end;
		MessageFakeNotShown := false;
	end;

procedure ElementBoardEdgeTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	var
		neighborId: integer;
		boardId: integer;
		entryX, entryY: integer;
	begin
		entryX := Board.Stats[0].X;
		entryY := Board.Stats[0].Y;
		if deltaY = -1 then begin
			neighborId := 0;
			entryY := BOARD_HEIGHT;
		end else if deltaY = 1 then begin
			neighborId := 1;
			entryY := 1;
		end else if deltaX = -1 then begin
			neighborId := 2;
			entryX := BOARD_WIDTH;
		end else begin
			neighborId := 3;
			entryX := 1;
		end;

		if Board.Info.NeighborBoards[neighborId] <> 0 then begin
			boardId := World.Info.CurrentBoard;
			BoardChange(Board.Info.NeighborBoards[neighborId]);
			if Board.Tiles[entryX][entryY].Element <> E_PLAYER then begin
				ElementDefs[Board.Tiles[entryX][entryY].Element].TouchProc(
					entryX, entryY, sourceStatId, InputDeltaX, InputDeltaY);
			end;

			if ElementDefs[Board.Tiles[entryX][entryY].Element].Walkable
				or (Board.Tiles[entryX][entryY].Element = E_PLAYER) then
			begin
				if Board.Tiles[entryX][entryY].Element <> E_PLAYER then
					MoveStat(0, entryX, entryY);

				TransitionDrawBoardChange;
				deltaX := 0;
				deltaY := 0;
				BoardEnter;
			end else begin
				BoardChange(boardId);
			end;
		end;
	end;

procedure ElementWaterTouch(x, y: integer; sourceStatId: integer; var deltaX, deltaY: integer);
	begin
		SoundQueue(3, #64#1#80#1);
		DisplayMessage(100, 'Your way is blocked by water.');
	end;

{$F-}

procedure DrawPlayerSurroundings(x, y: integer; bombPhase: integer);
	var
		ix, iy: integer;
		istat: integer;
		result: boolean;
	begin
		for ix := ((x - TORCH_DX) - 1) to ((x + TORCH_DX) + 1) do
			if (ix >= 1) and (ix <= BOARD_WIDTH) then
				for iy := ((y - TORCH_DY) - 1) to ((y + TORCH_DY) + 1) do
					if (iy >= 1) and (iy <= BOARD_HEIGHT) then
						with Board.Tiles[ix][iy] do begin
							if (bombPhase > 0) and ((Sqr(ix-x) + Sqr(iy-y)*2) < TORCH_DIST_SQR) then begin
								if bombPhase = 1 then begin
									if Length(ElementDefs[Element].ParamTextName) <> 0 then begin
										istat := GetStatIdAt(ix, iy);
										if istat > 0 then
											result := OopSend(-istat, 'BOMBED', false);
									end;

									if ElementDefs[Element].Destructible or (Element = E_STAR) then
										BoardDamageTile(ix, iy);

									if (Element = E_EMPTY) or (Element = E_BREAKABLE) then begin
										Element := E_BREAKABLE;
										Color := $09 + Random(7);
										BoardDrawTile(ix, iy);
									end;
								end else begin
									if Element = E_BREAKABLE then
										Element := E_EMPTY;
								end;
							end;
							BoardDrawTile(ix, iy);
						end;
	end;

{$F+}

procedure GamePromptEndPlay;
	begin
		if World.Info.Health <= 0 then begin
			GamePlayExitRequested := true;
			BoardDrawBorder;
		end else begin
			GamePlayExitRequested := SidebarPromptYesNo('End this game? ', true);
			if InputKeyPressed = #27 then
				GamePlayExitRequested := false;
		end;
		InputKeyPressed := #0;
	end;

procedure ElementPlayerTick(statId: integer);
	var
		unk1, unk2, unk3: integer;
		i: integer;
		bulletCount: integer;
	begin
		with Board.Stats[statId] do begin
			if World.Info.EnergizerTicks > 0 then begin
				if ElementDefs[E_PLAYER].Character = #2 then
					ElementDefs[E_PLAYER].Character := #1
				else
					ElementDefs[E_PLAYER].Character := #2;

				if (CurrentTick mod 2) <> 0 then
					Board.Tiles[X][Y].Color := $0F
				else
					Board.Tiles[X][Y].Color := (((CurrentTick mod 7) + 1) * 16) + $0F;

				BoardDrawTile(X, Y);
			end else if (Board.Tiles[X][Y].Color <> $1F) or (ElementDefs[E_PLAYER].Character <> #2) then begin
				Board.Tiles[X][Y].Color := $1F;
				ElementDefs[E_PLAYER].Character := #2;
				BoardDrawTile(X, Y);
			end;

			if World.Info.Health <= 0 then begin
				InputDeltaX := 0;
				InputDeltaY := 0;
				InputShiftPressed := false;

				if GetStatIdAt(0,0) = -1 then
					DisplayMessage(32000, ' Game over  -  Press ESCAPE');

				TickTimeDuration := 0;
				SoundBlockQueueing := true;
			end;
			if InputShiftPressed then begin
				if (InputDeltaX <> 0) or (InputDeltaY <> 0) then begin
					if Board.Info.MaxShots = 0 then begin
						if MessageNoShootingNotShown then
							DisplayMessage(200, 'Can'#39't shoot in this place!');
						MessageNoShootingNotShown := false;
					end else if World.Info.Ammo = 0 then begin
						if MessageOutOfAmmoNotShown then
							DisplayMessage(200, 'You don'#39't have any ammo!');
						MessageOutOfAmmoNotShown := false;
					end else begin
						bulletCount := 0;
						for i := 0 to Board.StatCount do
							if (Board.Tiles[Board.Stats[i].X][Board.Stats[i].Y].Element = E_BULLET)
								and (Board.Stats[i].P1 = SHOT_SOURCE_PLAYER)
							then
								bulletCount := bulletCount + 1;

						if bulletCount < Board.Info.MaxShots then begin
							if BoardShoot(E_BULLET, X, Y, InputDeltaX, InputDeltaY, SHOT_SOURCE_PLAYER) then begin
								World.Info.Ammo := World.Info.Ammo - 1;
								GameUpdateSidebar;

								SoundQueue(2, #64#1#48#1#32#1);

								InputDeltaX := 0;
								InputDeltaY := 0;
							end;
						end;
					end;
				end;
			end else if (InputDeltaX <> 0) or (InputDeltaY <> 0) then begin
				ElementDefs[Board.Tiles[X + InputDeltaX][Y + InputDeltaY].Element].TouchProc(
					X + InputDeltaX, Y + InputDeltaY, 0, InputDeltaX, InputDeltaY);
				if (InputDeltaX <> 0) or (InputDeltaY <> 0) then begin
					if SoundEnabled and not SoundIsPlaying then
						Sound(110);
					if ElementDefs[Board.Tiles[X + InputDeltaX][Y + InputDeltaY].Element].Walkable then begin
						if SoundEnabled and not SoundIsPlaying then
							NoSound;

						MoveStat(0, X + InputDeltaX, Y + InputDeltaY);
					end else if SoundEnabled and not SoundIsPlaying then begin
						NoSound;
					end;
				end;
			end;

			case UpCase(InputKeyPressed) of
				'T': begin
					if World.Info.TorchTicks <= 0 then begin
						if World.Info.Torches > 0 then begin
							if Board.Info.IsDark then begin
								World.Info.Torches := World.Info.Torches - 1;
								World.Info.TorchTicks := TORCH_DURATION;

								DrawPlayerSurroundings(X, Y, 0);
								GameUpdateSidebar;
							end else begin
								if MessageRoomNotDarkNotShown then begin
									DisplayMessage(200, 'Don'#39't need torch - room is not dark!');
									MessageRoomNotDarkNotShown := false;
								end;
							end;
						end else begin
							if MessageOutOfTorchesNotShown then begin
								DisplayMessage(200, 'You don'#39't have any torches!');
								MessageOutOfTorchesNotShown := false;
							end;
						end;
					end;
				end;
				#27, 'Q': begin
					GamePromptEndPlay;
				end;
				'S': begin
					GameWorldSave('Save game:', SavedGameFileName, '.SAV');
				end;
				'P': begin
					if World.Info.Health > 0 then
						GamePaused := true;
				end;
				'B': begin
					SoundEnabled := not SoundEnabled;
					SoundClearQueue;
					GameUpdateSidebar;
					InputKeyPressed := ' ';
				end;
				'H': begin
					TextWindowDisplayFile('GAME.HLP', 'Playing ZZT');
				end;
				'F': begin
					TextWindowDisplayFile('ORDER.HLP', 'Order form');
				end;
				'?': begin
					GameDebugPrompt;
					InputKeyPressed := #0;
				end;
			end;

			if World.Info.TorchTicks > 0 then begin
				World.Info.TorchTicks := World.Info.TorchTicks - 1;
				if World.Info.TorchTicks <= 0 then begin
					DrawPlayerSurroundings(X, Y, 0);
					SoundQueue(3, #48#1#32#1#16#1);
				end;

				if (World.Info.TorchTicks mod 40) = 0 then
					GameUpdateSidebar;
			end;

			if World.Info.EnergizerTicks > 0 then begin
				World.Info.EnergizerTicks := World.Info.EnergizerTicks - 1;

				if World.Info.EnergizerTicks = 10 then
					SoundQueue(9, #32#3#26#3#23#3#22#3#21#3#19#3#16#3)
				else if World.Info.EnergizerTicks <= 0 then begin
					Board.Tiles[X][Y].Color := ElementDefs[E_PLAYER].Color;
					BoardDrawTile(X, Y);
				end;
			end;

			if (Board.Info.TimeLimitSec > 0) and (World.Info.Health > 0) then
				if SoundHasTimeElapsed(World.Info.BoardTimeHsec, 100) then begin
					World.Info.BoardTimeSec := World.Info.BoardTimeSec + 1;

					if (Board.Info.TimeLimitSec - 10) = World.Info.BoardTimeSec then begin
						DisplayMessage(200, 'Running out of time!');
						SoundQueue(3, #64#6#69#6#64#6#53#6#64#6#69#6#64#10);
					end else if World.Info.BoardTimeSec > Board.Info.TimeLimitSec then begin
						DamageStat(0);
					end;

					GameUpdateSidebar;
				end;
		end;
	end;

procedure ElementMonitorTick(statId: integer);
	begin
		if UpCase(InputKeyPressed) in [#27, 'A', 'E', 'H', 'N', 'P', 'Q', 'R', 'S', 'W', '|'] then
			GamePlayExitRequested := true;
	end;

{$F-}

procedure GameAboutScreen;
	begin
		TextWindowDisplayFile('ABOUT.HLP', 'About ZZT...');
	end;

procedure GamePlayLoop(boardChanged: boolean);
	var
		exitLoop: boolean;
		pauseBlink: boolean;
	procedure GameDrawSidebar;
		begin
			SidebarClear;
			SidebarClearLine(0);
			SidebarClearLine(1);
			SidebarClearLine(2);
			VideoWriteText(61, 0, $1F, '    - - - - -      ');
			VideoWriteText(62, 1, $70, '      ZZT      ');
			VideoWriteText(61, 2, $1F, '    - - - - -      ');
			if GameStateElement = E_PLAYER then begin
				VideoWriteText(64, 7, $1E, ' Health:');
				VideoWriteText(64, 8, $1E, '   Ammo:');
				VideoWriteText(64, 9, $1E, 'Torches:');
				VideoWriteText(64, 10, $1E, '   Gems:');
				VideoWriteText(64, 11, $1E, '  Score:');
				VideoWriteText(64, 12, $1E, '   Keys:');
				VideoWriteText(62, 7, $1F, ElementDefs[E_PLAYER].Character);
				VideoWriteText(62, 8, $1B, ElementDefs[E_AMMO].Character);
				VideoWriteText(62, 9, $16, ElementDefs[E_TORCH].Character);
				VideoWriteText(62, 10, $1B, ElementDefs[E_GEM].Character);
				VideoWriteText(62, 12, $1F, ElementDefs[E_KEY].Character);
				VideoWriteText(62, 14, $70, ' T ');
				VideoWriteText(65, 14, $1F, ' Torch');
				VideoWriteText(62, 15, $30, ' B ');
				VideoWriteText(62, 16, $70, ' H ');
				VideoWriteText(65, 16, $1F, ' Help');
				VideoWriteText(67, 18, $30, ' '#24#25#26#27' ');
				VideoWriteText(72, 18, $1F, ' Move');
				VideoWriteText(61, 19, $70, ' Shift '#24#25#26#27' ');
				VideoWriteText(72, 19, $1F, ' Shoot');
				VideoWriteText(62, 21, $70, ' S ');
				VideoWriteText(65, 21, $1F, ' Save game');
				VideoWriteText(62, 22, $30, ' P ');
				VideoWriteText(65, 22, $1F, ' Pause');
				VideoWriteText(62, 23, $70, ' Q ');
				VideoWriteText(65, 23, $1F, ' Quit');
			end else if GameStateElement = E_MONITOR then begin
				SidebarPromptSlider(false, 66, 21, 'Game speed:;FS', TickSpeed);
				VideoWriteText(62, 21, $70, ' S ');
				VideoWriteText(62, 7, $30, ' W ');
				VideoWriteText(65, 7, $1E, ' World:');

				if Length(World.Info.Name) <> 0 then
					VideoWriteText(69, 8, $1F, World.Info.Name)
				else
					VideoWriteText(69, 8, $1F, 'Untitled');

				VideoWriteText(62, 11, $70, ' P ');
				VideoWriteText(65, 11, $1F, ' Play');
				VideoWriteText(62, 12, $30, ' R ');
				VideoWriteText(65, 12, $1E, ' Restore game');
				VideoWriteText(62, 13, $70, ' Q ');
				VideoWriteText(65, 13, $1E, ' Quit');
				VideoWriteText(62, 16, $30, ' A ');
				VideoWriteText(65, 16, $1F, ' About ZZT!');
				VideoWriteText(62, 17, $70, ' H ');
				VideoWriteText(65, 17, $1E, ' High Scores');

				if EditorEnabled then begin
					VideoWriteText(62, 18, $30, ' E ');
					VideoWriteText(65, 18, $1E, ' Board Editor');
				end;
			end;
		end;
	begin
		GameDrawSidebar;
		GameUpdateSidebar;

		if JustStarted then begin
			if Length(ConfigRegistrant) = 0 then
				GameAboutScreen;
			if Length(StartupWorldFileName) <> 0 then begin
				SidebarClearLine(8);
				VideoWriteText(69, 8, $1F, StartupWorldFileName);
				if not WorldLoad(StartupWorldFileName, '.ZZT', true) then WorldCreate;
			end;
			ReturnBoardId := World.Info.CurrentBoard;
			BoardChange(0);
			JustStarted := false;
		end;

		Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Element := GameStateElement;
		Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Color := ElementDefs[GameStateElement].Color;

		if GameStateElement = E_MONITOR then begin
			DisplayMessage(0, '');
			VideoWriteText(62, 5, $1B, 'Pick a command:');
		end;

		if boardChanged then
			TransitionDrawBoardChange;

		TickTimeDuration := TickSpeed * 2;
		GamePlayExitRequested := false;
		exitLoop := false;

		CurrentTick := Random(100);
		CurrentStatTicked := Board.StatCount + 1;

		repeat
			if GamePaused then begin
				if SoundHasTimeElapsed(TickTimeCounter, 25) then
					pauseBlink := not pauseBlink;

				if pauseBlink then begin
					VideoWriteText(Board.Stats[0].X - 1, Board.Stats[0].Y - 1,
						ElementDefs[E_PLAYER].Color, ElementDefs[E_PLAYER].Character);
				end else begin
					if Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Element = E_PLAYER then
						VideoWriteText(Board.Stats[0].X - 1, Board.Stats[0].Y - 1, $0F, ' ')
					else
						BoardDrawTile(Board.Stats[0].X, Board.Stats[0].Y);
				end;

				VideoWriteText(64, 5, $1F, 'Pausing...');
				InputUpdate;

				if InputKeyPressed = KEY_ESCAPE then
					GamePromptEndPlay;

				if (InputDeltaX <> 0) or (InputDeltaY <> 0) then begin
					ElementDefs[Board.Tiles[Board.Stats[0].X + InputDeltaX][Board.Stats[0].Y + InputDeltaY].Element].TouchProc(
						Board.Stats[0].X + InputDeltaX, Board.Stats[0].Y + InputDeltaY, 0, InputDeltaX, InputDeltaY);
				end;

				if ((InputDeltaX <> 0) or (InputDeltaY <> 0))
					and ElementDefs[Board.Tiles[Board.Stats[0].X + InputDeltaX][Board.Stats[0].Y + InputDeltaY].Element].Walkable
				then begin
					{ Move player }
					if Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Element = E_PLAYER then
						MoveStat(0, Board.Stats[0].X + InputDeltaX, Board.Stats[0].Y + InputDeltaY)
					else begin
						BoardDrawTile(Board.Stats[0].X, Board.Stats[0].Y);
						Board.Stats[0].X := Board.Stats[0].X + InputDeltaX;
						Board.Stats[0].Y := Board.Stats[0].Y + InputDeltaY;
						Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Element := E_PLAYER;
						Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Color := ElementDefs[E_PLAYER].Color;
						BoardDrawTile(Board.Stats[0].X, Board.Stats[0].Y);
						DrawPlayerSurroundings(Board.Stats[0].X, Board.Stats[0].Y, 0);
						DrawPlayerSurroundings(Board.Stats[0].X - InputDeltaX, Board.Stats[0].Y - InputDeltaY, 0);
					end;

					{ Unpause }
					GamePaused := false;
					SidebarClearLine(5);
					CurrentTick := Random(100);
					CurrentStatTicked := Board.StatCount + 1;
					World.Info.IsSave := true;
				end;

			end else begin { not GamePaused }
				if CurrentStatTicked <= Board.StatCount then begin
					with Board.Stats[CurrentStatTicked] do begin
						if (Cycle <> 0) and ((CurrentTick mod Cycle) = (CurrentStatTicked mod Cycle)) then
							ElementDefs[Board.Tiles[X][Y].Element].TickProc(CurrentStatTicked);

						CurrentStatTicked := CurrentStatTicked + 1;
					end;
				end;
			end;

			if (CurrentStatTicked > Board.StatCount) and not GamePlayExitRequested then begin
				{ all stats ticked }
				if SoundHasTimeElapsed(TickTimeCounter, TickTimeDuration) then begin
					{ next cycle }
					CurrentTick := CurrentTick + 1;
					if CurrentTick > 420 then
						CurrentTick := 1;
					CurrentStatTicked := 0;

					InputUpdate;
				end;
			end;
		until (exitLoop or GamePlayExitRequested) and GamePlayExitRequested;

		SoundClearQueue;

		if GameStateElement = E_PLAYER then begin
			if World.Info.Health <= 0 then begin
				HighScoresAdd(World.Info.Score);
			end;
		end else if GameStateElement = E_MONITOR then begin
			SidebarClearLine(5);
		end;

		Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Element := E_PLAYER;
		Board.Tiles[Board.Stats[0].X][Board.Stats[0].Y].Color := ElementDefs[E_PLAYER].Color;

		SoundBlockQueueing := false;
	end;

procedure GameTitleLoop;
	var
		boardChanged: boolean;
		startPlay: boolean;
	begin
		GameTitleExitRequested := false;
		JustStarted := true;
		ReturnBoardId := 0;
		boardChanged := true;
		repeat
			BoardChange(0);
			repeat
				GameStateElement := E_MONITOR;
				startPlay := false;
				GamePaused := false;
				GamePlayLoop(boardChanged);
				boardChanged := false;

				case UpCase(InputKeyPressed) of
					'W': begin
						if GameWorldLoad('.ZZT') then begin
							ReturnBoardId := World.Info.CurrentBoard;
							boardChanged := true;
						end;
					end;
					'P': begin
						if World.Info.IsSave and not DebugEnabled then begin
							startPlay := WorldLoad(World.Info.Name, '.ZZT', false);
							ReturnBoardId := World.Info.CurrentBoard;
						end else begin
							startPlay := true;
						end;
						if startPlay then begin
							BoardChange(ReturnBoardId);
							BoardEnter;
						end;
					end;
					'A': begin
						GameAboutScreen;
					end;
					'E': if EditorEnabled then begin
						EditorLoop;
						ReturnBoardId := World.Info.CurrentBoard;
						boardChanged := true;
					end;
					'S': begin
						SidebarPromptSlider(true, 66, 21, 'Game speed:;FS', TickSpeed);
						InputKeyPressed := #0;
					end;
					'R': begin
						if GameWorldLoad('.SAV') then begin
							ReturnBoardId := World.Info.CurrentBoard;
							BoardChange(ReturnBoardId);
							startPlay := true;
						end;
					end;
					'H': begin
						HighScoresLoad;
						HighScoresDisplay(1);
					end;
					'|': begin
						GameDebugPrompt;
					end;
					KEY_ESCAPE, 'Q': begin
						GameTitleExitRequested := SidebarPromptYesNo('Quit ZZT? ', true);
					end;
				end;

				if startPlay then begin
					GameStateElement := E_PLAYER;
					GamePaused := true;
					GamePlayLoop(true);
					boardChanged := true;
				end;
			until boardChanged or GameTitleExitRequested;
		until GameTitleExitRequested;
	end;

procedure InitElementDefs;
	var
		i: integer;
	begin
		for i := 0 to MAX_ELEMENT do
			with ElementDefs[i] do begin
				Character := ' ';
				Color := COLOR_CHOICE_ON_BLACK;
				Destructible := false;
				Pushable := false;
				VisibleInDark := false;
				PlaceableOnTop := false;
				Walkable := false;
				HasDrawProc := false;
				Cycle := -1;
				TickProc := ElementDefaultTick;
				DrawProc := ElementDefaultDraw;
				TouchProc := ElementDefaultTouch;
				EditorCategory := 0;
				EditorShortcut := #0;
				Name := '';
				CategoryName := '';
				Param1Name := '';
				Param2Name := '';
				ParamBulletTypeName := '';
				ParamBoardName := '';
				ParamDirName := '';
				ParamTextName := '';
				ScoreValue := 0;
			end;

		ElementDefs[0].Character := ' ';
		ElementDefs[0].Color := $70;
		ElementDefs[0].Pushable := true;
		ElementDefs[0].Walkable := true;
		ElementDefs[0].Name := 'Empty';

		ElementDefs[3].Character := ' ';
		ElementDefs[3].Color := $07;
		ElementDefs[3].Cycle := 1;
		ElementDefs[3].TickProc := ElementMonitorTick;
		ElementDefs[3].Name := 'Monitor';

		ElementDefs[19].Character := #176;
		ElementDefs[19].Color := $F9;
		ElementDefs[19].PlaceableOnTop := true;
		ElementDefs[19].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[19].TouchProc := ElementWaterTouch;
		ElementDefs[19].EditorShortcut := 'W';
		ElementDefs[19].Name := 'Water';
		ElementDefs[19].CategoryName := 'Terrains:';

		ElementDefs[20].Character := #176;
		ElementDefs[20].Color := $20;
		ElementDefs[20].Walkable := false;
		ElementDefs[20].TouchProc := ElementForestTouch;
		ElementDefs[20].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[20].EditorShortcut := 'F';
		ElementDefs[20].Name := 'Forest';

		ElementDefs[4].Character := #2;
		ElementDefs[4].Color := $1F;
		ElementDefs[4].Destructible := true;
		ElementDefs[4].Pushable := true;
		ElementDefs[4].VisibleInDark := true;
		ElementDefs[4].Cycle := 1;
		ElementDefs[4].TickProc := ElementPlayerTick;
		ElementDefs[4].EditorCategory := CATEGORY_ITEM;
		ElementDefs[4].EditorShortcut := 'Z';
		ElementDefs[4].Name := 'Player';
		ElementDefs[4].CategoryName := 'Items:';

		ElementDefs[41].Character := #234;
		ElementDefs[41].Color := $0C;
		ElementDefs[41].Destructible := true;
		ElementDefs[41].Pushable := true;
		ElementDefs[41].Cycle := 2;
		ElementDefs[41].TickProc := ElementLionTick;
		ElementDefs[41].TouchProc := ElementDamagingTouch;
		ElementDefs[41].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[41].EditorShortcut := 'L';
		ElementDefs[41].Name := 'Lion';
		ElementDefs[41].CategoryName := 'Beasts:';
		ElementDefs[41].Param1Name := 'Intelligence?';
		ElementDefs[41].ScoreValue := 1;

		ElementDefs[42].Character := #227;
		ElementDefs[42].Color := $0B;
		ElementDefs[42].Destructible := true;
		ElementDefs[42].Pushable := true;
		ElementDefs[42].Cycle := 2;
		ElementDefs[42].TickProc := ElementTigerTick;
		ElementDefs[42].TouchProc := ElementDamagingTouch;
		ElementDefs[42].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[42].EditorShortcut := 'T';
		ElementDefs[42].Name := 'Tiger';
		ElementDefs[42].Param1Name := 'Intelligence?';
		ElementDefs[42].Param2Name := 'Firing rate?';
		ElementDefs[42].ParamBulletTypeName := 'Firing type?';
		ElementDefs[42].ScoreValue := 2;

		ElementDefs[44].Character := #233;
		ElementDefs[44].Destructible := true;
		ElementDefs[44].Cycle := 2;
		ElementDefs[44].TickProc := ElementCentipedeHeadTick;
		ElementDefs[44].TouchProc := ElementDamagingTouch;
		ElementDefs[44].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[44].EditorShortcut := 'H';
		ElementDefs[44].Name := 'Head';
		ElementDefs[44].CategoryName := 'Centipedes';
		ElementDefs[44].Param1Name := 'Intelligence?';
		ElementDefs[44].Param2Name := 'Deviance?';
		ElementDefs[44].ScoreValue := 1;

		ElementDefs[45].Character := 'O';
		ElementDefs[45].Destructible := true;
		ElementDefs[45].Cycle := 2;
		ElementDefs[45].TickProc := ElementCentipedeSegmentTick;
		ElementDefs[45].TouchProc := ElementDamagingTouch;
		ElementDefs[45].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[45].EditorShortcut := 'S';
		ElementDefs[45].Name := 'Segment';
		ElementDefs[45].ScoreValue := 3;

		ElementDefs[18].Character := #248;
		ElementDefs[18].Color := $0F;
		ElementDefs[18].Destructible := true;
		ElementDefs[18].Cycle := 1;
		ElementDefs[18].TickProc := ElementBulletTick;
		ElementDefs[18].TouchProc := ElementDamagingTouch;
		ElementDefs[18].Name := 'Bullet';

		ElementDefs[15].Character := 'S';
		ElementDefs[15].Color := $0F;
		ElementDefs[15].Destructible := false;
		ElementDefs[15].Cycle := 1;
		ElementDefs[15].TickProc := ElementStarTick;
		ElementDefs[15].TouchProc := ElementDamagingTouch;
		ElementDefs[15].HasDrawProc := true;
		ElementDefs[15].DrawProc := ElementStarDraw;
		ElementDefs[15].Name := 'Star';

		ElementDefs[8].Character := #12;
		ElementDefs[8].Pushable := true;
		ElementDefs[8].TouchProc := ElementKeyTouch;
		ElementDefs[8].EditorCategory := CATEGORY_ITEM;
		ElementDefs[8].EditorShortcut := 'K';
		ElementDefs[8].Name := 'Key';

		ElementDefs[5].Character := #132;
		ElementDefs[5].Color := $03;
		ElementDefs[5].Pushable := true;
		ElementDefs[5].TouchProc := ElementAmmoTouch;
		ElementDefs[5].EditorCategory := CATEGORY_ITEM;
		ElementDefs[5].EditorShortcut := 'A';
		ElementDefs[5].Name := 'Ammo';

		ElementDefs[7].Character := #4;
		ElementDefs[7].Pushable := true;
		ElementDefs[7].TouchProc := ElementGemTouch;
		ElementDefs[7].Destructible := true;
		ElementDefs[7].EditorCategory := CATEGORY_ITEM;
		ElementDefs[7].EditorShortcut := 'G';
		ElementDefs[7].Name := 'Gem';

		ElementDefs[11].Character := #240;
		ElementDefs[11].Color := COLOR_WHITE_ON_CHOICE;
		ElementDefs[11].Cycle := 0;
		ElementDefs[11].VisibleInDark := true;
		ElementDefs[11].TouchProc := ElementPassageTouch;
		ElementDefs[11].EditorCategory := CATEGORY_ITEM;
		ElementDefs[11].EditorShortcut := 'P';
		ElementDefs[11].Name := 'Passage';
		ElementDefs[11].ParamBoardName := 'Room thru passage?';

		ElementDefs[9].Character := #10;
		ElementDefs[9].Color := COLOR_WHITE_ON_CHOICE;
		ElementDefs[9].TouchProc := ElementDoorTouch;
		ElementDefs[9].EditorCategory := CATEGORY_ITEM;
		ElementDefs[9].EditorShortcut := 'D';
		ElementDefs[9].Name := 'Door';

		ElementDefs[10].Character := #232;
		ElementDefs[10].Color := $0F;
		ElementDefs[10].TouchProc := ElementScrollTouch;
		ElementDefs[10].TickProc := ElementScrollTick;
		ElementDefs[10].Pushable := true;
		ElementDefs[10].Cycle := 1;
		ElementDefs[10].EditorCategory := CATEGORY_ITEM;
		ElementDefs[10].EditorShortcut := 'S';
		ElementDefs[10].Name := 'Scroll';
		ElementDefs[10].ParamTextName := 'Edit text of scroll';

		ElementDefs[12].Character := #250;
		ElementDefs[12].Color := $0F;
		ElementDefs[12].Cycle := 2;
		ElementDefs[12].TickProc := ElementDuplicatorTick;
		ElementDefs[12].HasDrawProc := true;
		ElementDefs[12].DrawProc := ElementDuplicatorDraw;
		ElementDefs[12].EditorCategory := CATEGORY_ITEM;
		ElementDefs[12].EditorShortcut := 'U';
		ElementDefs[12].Name := 'Duplicator';
		ElementDefs[12].ParamDirName := 'Source direction?';
		ElementDefs[12].Param2Name := 'Duplication rate?;SF';

		ElementDefs[6].Character := #157;
		ElementDefs[6].Color := $06;
		ElementDefs[6].VisibleInDark := true;
		ElementDefs[6].TouchProc := ElementTorchTouch;
		ElementDefs[6].EditorCategory := CATEGORY_ITEM;
		ElementDefs[6].EditorShortcut := 'T';
		ElementDefs[6].Name := 'Torch';

		ElementDefs[39].Character := #24;
		ElementDefs[39].Cycle := 2;
		ElementDefs[39].TickProc := ElementSpinningGunTick;
		ElementDefs[39].HasDrawProc := true;
		ElementDefs[39].DrawProc := ElementSpinningGunDraw;
		ElementDefs[39].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[39].EditorShortcut := 'G';
		ElementDefs[39].Name := 'Spinning gun';
		ElementDefs[39].Param1Name := 'Intelligence?';
		ElementDefs[39].Param2Name := 'Firing rate?';
		ElementDefs[39].ParamBulletTypeName := 'Firing type?';

		ElementDefs[35].Character := #5;
		ElementDefs[35].Color := $0D;
		ElementDefs[35].Destructible := true;
		ElementDefs[35].Pushable := true;
		ElementDefs[35].Cycle := 1;
		ElementDefs[35].TickProc := ElementRuffianTick;
		ElementDefs[35].TouchProc := ElementDamagingTouch;
		ElementDefs[35].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[35].EditorShortcut := 'R';
		ElementDefs[35].Name := 'Ruffian';
		ElementDefs[35].Param1Name := 'Intelligence?';
		ElementDefs[35].Param2Name := 'Resting time?';
		ElementDefs[35].ScoreValue := 2;

		ElementDefs[34].Character := #153;
		ElementDefs[34].Color := $06;
		ElementDefs[34].Destructible := true;
		ElementDefs[34].Pushable := true;
		ElementDefs[34].Cycle := 3;
		ElementDefs[34].TickProc := ElementBearTick;
		ElementDefs[34].TouchProc := ElementDamagingTouch;
		ElementDefs[34].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[34].EditorShortcut := 'B';
		ElementDefs[34].Name := 'Bear';
		ElementDefs[34].CategoryName := 'Creatures:';
		ElementDefs[34].Param1Name := 'Sensitivity?';
		ElementDefs[34].ScoreValue := 1;

		ElementDefs[37].Character := '*';
		ElementDefs[37].Color := COLOR_CHOICE_ON_BLACK;
		ElementDefs[37].Destructible := false;
		ElementDefs[37].Cycle := 3;
		ElementDefs[37].TickProc := ElementSlimeTick;
		ElementDefs[37].TouchProc := ElementSlimeTouch;
		ElementDefs[37].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[37].EditorShortcut := 'V';
		ElementDefs[37].Name := 'Slime';
		ElementDefs[37].Param2Name := 'Movement speed?;FS';

		ElementDefs[38].Character := '^';
		ElementDefs[38].Color := $07;
		ElementDefs[38].Destructible := false;
		ElementDefs[38].Cycle := 3;
		ElementDefs[38].TickProc := ElementSharkTick;
		ElementDefs[38].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[38].EditorShortcut := 'Y';
		ElementDefs[38].Name := 'Shark';
		ElementDefs[38].Param1Name := 'Intelligence?';

		ElementDefs[16].Character := '/';
		ElementDefs[16].Cycle := 3;
		ElementDefs[16].HasDrawProc := true;
		ElementDefs[16].TickProc := ElementConveyorCWTick;
		ElementDefs[16].DrawProc := ElementConveyorCWDraw;
		ElementDefs[16].EditorCategory := CATEGORY_ITEM;
		ElementDefs[16].EditorShortcut := '1';
		ElementDefs[16].Name := 'Clockwise';
		ElementDefs[16].CategoryName := 'Conveyors:';

		ElementDefs[17].Character := '\';
		ElementDefs[17].Cycle := 2;
		ElementDefs[17].HasDrawProc := true;
		ElementDefs[17].DrawProc := ElementConveyorCCWDraw;
		ElementDefs[17].TickProc := ElementConveyorCCWTick;
		ElementDefs[17].EditorCategory := CATEGORY_ITEM;
		ElementDefs[17].EditorShortcut := '2';
		ElementDefs[17].Name := 'Counter';

		ElementDefs[21].Character := #219;
		ElementDefs[21].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[21].CategoryName := 'Walls:';
		ElementDefs[21].EditorShortcut := 'S';
		ElementDefs[21].Name := 'Solid';

		ElementDefs[22].Character := #178;
		ElementDefs[22].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[22].EditorShortcut := 'N';
		ElementDefs[22].Name := 'Normal';

		ElementDefs[31].Character := #206;
		ElementDefs[31].HasDrawProc := true;
		ElementDefs[31].DrawProc := ElementLineDraw;
		ElementDefs[31].Name := 'Line';

		ElementDefs[43].Character := #186;

		ElementDefs[33].Character := #205;

		ElementDefs[32].Character := '*';
		ElementDefs[32].Color := $0A;
		ElementDefs[32].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[32].EditorShortcut := 'R';
		ElementDefs[32].Name := 'Ricochet';

		ElementDefs[23].Character := #177;
		ElementDefs[23].Destructible := false;
		ElementDefs[23].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[23].EditorShortcut := 'B';
		ElementDefs[23].Name := 'Breakable';

		ElementDefs[24].Character := #254;
		ElementDefs[24].Pushable := true;
		ElementDefs[24].TouchProc := ElementPushableTouch;
		ElementDefs[24].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[24].EditorShortcut := 'O';
		ElementDefs[24].Name := 'Boulder';

		ElementDefs[25].Character := #18;
		ElementDefs[25].TouchProc := ElementPushableTouch;
		ElementDefs[25].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[25].EditorShortcut := '1';
		ElementDefs[25].Name := 'Slider (NS)';

		ElementDefs[26].Character := #29;
		ElementDefs[26].TouchProc := ElementPushableTouch;
		ElementDefs[26].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[26].EditorShortcut := '2';
		ElementDefs[26].Name := 'Slider (EW)';

		ElementDefs[30].Character := #197;
		ElementDefs[30].TouchProc := ElementTransporterTouch;
		ElementDefs[30].HasDrawProc := true;
		ElementDefs[30].DrawProc := ElementTransporterDraw;
		ElementDefs[30].Cycle := 2;
		ElementDefs[30].TickProc := ElementTransporterTick;
		ElementDefs[30].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[30].EditorShortcut := 'T';
		ElementDefs[30].Name := 'Transporter';
		ElementDefs[30].ParamDirName := 'Direction?';

		ElementDefs[40].Character := #16;
		ElementDefs[40].Color := COLOR_CHOICE_ON_BLACK;
		ElementDefs[40].HasDrawProc := true;
		ElementDefs[40].DrawProc := ElementPusherDraw;
		ElementDefs[40].Cycle := 4;
		ElementDefs[40].TickProc := ElementPusherTick;
		ElementDefs[40].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[40].EditorShortcut := 'P';
		ElementDefs[40].Name := 'Pusher';
		ElementDefs[40].ParamDirName := 'Push direction?';

		ElementDefs[13].Character := #11;
		ElementDefs[13].HasDrawProc := true;
		ElementDefs[13].DrawProc := ElementBombDraw;
		ElementDefs[13].Pushable := true;
		ElementDefs[13].Cycle := 6;
		ElementDefs[13].TickProc := ElementBombTick;
		ElementDefs[13].TouchProc := ElementBombTouch;
		ElementDefs[13].EditorCategory := CATEGORY_ITEM;
		ElementDefs[13].EditorShortcut := 'B';
		ElementDefs[13].Name := 'Bomb';

		ElementDefs[14].Character := #127;
		ElementDefs[14].Color := $05;
		ElementDefs[14].TouchProc := ElementEnergizerTouch;
		ElementDefs[14].EditorCategory := CATEGORY_ITEM;
		ElementDefs[14].EditorShortcut := 'E';
		ElementDefs[14].Name := 'Energizer';

		ElementDefs[29].Character := #206;
		ElementDefs[29].Cycle := 1;
		ElementDefs[29].TickProc := ElementBlinkWallTick;
		ElementDefs[29].HasDrawProc := true;
		ElementDefs[29].DrawProc := ElementBlinkWallDraw;
		ElementDefs[29].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[29].EditorShortcut := 'L';
		ElementDefs[29].Name := 'Blink wall';
		ElementDefs[29].Param1Name := 'Starting time';
		ElementDefs[29].Param2Name := 'Period';
		ElementDefs[29].ParamDirName := 'Wall direction';

		ElementDefs[27].Character := #178;
		ElementDefs[27].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[27].PlaceableOnTop := true;
		ElementDefs[27].Walkable := true;
		ElementDefs[27].TouchProc := ElementFakeTouch;
		ElementDefs[27].EditorShortcut := 'A';
		ElementDefs[27].Name := 'Fake';

		ElementDefs[28].Character := ' ';
		ElementDefs[28].EditorCategory := CATEGORY_TERRAIN;
		ElementDefs[28].TouchProc := ElementInvisibleTouch;
		ElementDefs[28].EditorShortcut := 'I';
		ElementDefs[28].Name := 'Invisible';

		ElementDefs[36].Character := #2;
		ElementDefs[36].EditorCategory := CATEGORY_CREATURE;
		ElementDefs[36].Cycle := 3;
		ElementDefs[36].HasDrawProc := true;
		ElementDefs[36].DrawProc := ElementObjectDraw;
		ElementDefs[36].TickProc := ElementObjectTick;
		ElementDefs[36].TouchProc := ElementObjectTouch;
		ElementDefs[36].EditorShortcut := 'O';
		ElementDefs[36].Name := 'Object';
		ElementDefs[36].Param1Name := 'Character?';
		ElementDefs[36].ParamTextName := 'Edit Program';

		ElementDefs[2].TickProc := ElementMessageTimerTick;

		ElementDefs[1].TouchProc := ElementBoardEdgeTouch;

		EditorPatternCount := 5;
		EditorPatterns[1] := E_SOLID;
		EditorPatterns[2] := E_NORMAL;
		EditorPatterns[3] := E_BREAKABLE;
		EditorPatterns[4] := E_EMPTY;
		EditorPatterns[5] := E_LINE;
	end;

procedure InitElementsEditor;
	begin
		InitElementDefs;
		ElementDefs[28].Character := #176;
		ElementDefs[28].Color := COLOR_CHOICE_ON_BLACK;
		ForceDarknessOff := true;
	end;

procedure InitElementsGame;
	begin
		InitElementDefs;
		ForceDarknessOff := false;
	end;

procedure InitEditorStatSettings;
	var
		i: integer;
	begin
		for i := 0 to MAX_ELEMENT do
			with World.EditorStatSettings[i] do begin
				P1 := 4;
				P2 := 4;
				P3 := 0;
				StepX := 0;
				StepY := -1;
			end;

		World.EditorStatSettings[E_OBJECT].P1 := 1;
		World.EditorStatSettings[E_BEAR].P1 := 8;
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

procedure GamePrintRegisterMessage;
	var
		i: integer;
		s: string;
		f: text;
		iy: integer;
		color: integer;
	begin
		SetCBreak(false);
		i := Random(4) + 1;
		Str(i, s);
		Assign(f, 'END' + s + '.MSG');
		Reset(f);

		iy := 0;
		color := $0F;

		if IOResult = 0 then begin
			while (IOResult = 0) and not Eof(f) do begin
				ReadLn(f, s);
				if Length(s) = 0 then
					color := color - 1;
				for i := 1 to Length(s) do begin
					VideoWriteText(i - 1, iy, color, s[i]);
					VideoWriteText(i, iy, $09, #254);
					KeysUpdateModifiers;
					if not KeysLeftShiftHeld or not KeysRightShiftHeld then
						Delay(26);
					VideoWriteText(i, iy, $0F, ' ');
				end;
				iy := iy + 1;
			end;

			GotoXY(1, 23);
			exit;
		end;
	end;

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
