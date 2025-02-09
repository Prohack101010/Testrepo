package scripting;

import flixel.FlxBasic;
import Character;
import psychlua.LuaUtils;

import Song;
import WeekData;

import openfl.Lib;

#if windows import cpp.*; #end

#if LUA_ALLOWED
import psychlua.FunkinLua;
#end

import Highscore;

#if HSCRIPT_ALLOWED
import tea.SScript;

class StateHScript extends SScript
{
    public static var onSubstate:Bool = false;
	public var modFolder:String;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	public static function initHaxeModule(parent:FunkinLua)
	{
		if(parent.statehscript == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.statehscript = new StateHScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
	{
		var hs:StateHScript = try parent.statehscript catch (e) null;
		if(hs == null)
		{
			trace('initializing haxe interp for: ${parent.scriptName}');
			parent.statehscript = new StateHScript(parent, code, varsToBring);
		}
		else
		{
			hs.doString(code);
			@:privateAccess
			if(hs.parsingException != null)
			{
			    //State
			    if(Std.is(FlxG.state, ScriptState) && ScriptState.instance != null) ScriptState.instance.addTextToDebug('ERROR ON LOADING (${hs.origin}): ${hs.parsingException.message}', FlxColor.RED);
				else if (!onSubstate) HScriptStateHandler.instance.addTextToDebug('ERROR ON LOADING (${hs.origin}): ${hs.parsingException.message}', FlxColor.RED);
				//Substate
				if(Std.is(FlxG.state.subState, ScriptSubstate) && ScriptSubstate.instance != null) ScriptSubstate.instance.addTextToDebug('ERROR ON LOADING (${hs.origin}): ${hs.parsingException.message}', FlxColor.RED);
			    else if (onSubstate) HScriptSubStateHandler.instance.addTextToDebug('ERROR ON LOADING (${hs.origin}): ${hs.parsingException.message}', FlxColor.RED);
			}
		}
	}
	#end

	//Window Shit
	static function windowTweenUpdateX(value:Float)
	{
		Lib.application.window.x = Math.floor(value);
	}
	
	private function windowTweenUpdateY(value:Float)
	{
		Lib.application.window.y = Math.floor(value);
	}
	
	private function windowTweenUpdateWidth(value:Float)
	{
		Lib.application.window.width = Math.floor(value);
	}
	
	private function windowTweenUpdateHeight(value:Float)
	{
		Lib.application.window.height = Math.floor(value);
	}
	
	private function windowTweenUpdateAlpha(value:Float)
	{
		#if windows WindowsCPP.setWindowAlpha(value); #end
	}

	//Window Shit end

	public var origin:String;
	override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null)
	{
		if (file == null)
			file = '';

		this.varsToBring = varsToBring;
	
		super(file, false, false);

		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null)
		{
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		#end

		if (scriptFile != null && scriptFile.length > 0)
		{
			this.origin = scriptFile;
			#if MODS_ALLOWED
			var myFolder:Array<String> = scriptFile.split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}

		preset();
		execute();
	}

	var varsToBring:Any = null;
	override function preset() {
		super.preset();

		// Some very commonly used classes
		set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxSound', flixel.system.FlxSound);
		set('SwipeUtil', mobile.backend.SwipeUtil);
		set('FlxText', flixel.text.FlxText);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', backend.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxFlicker', flixel.effects.FlxFlicker);
		set('FlxColor', CustomFlxColor);
		set('controls', PlayerSettings.player1.controls); //fix controls
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('File', sys.io.File);
		set('Json', haxe.Json);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end
		set('Lib', openfl.Lib);
		set('ScriptingVars', scripting.ScriptingVars);
		set('CustomSwitchState', extras.CustomSwitchState);
		set('CoolUtil', CoolUtil);
		set('MusicBeatState', MusicBeatState);
		
		set('AttachedText', AttachedText);
		set('MenuCharacter', MenuCharacter);
		set('DialogueCharacterEditorState', editors.DialogueCharacterEditorState);
		set('DialogueEditorState', editors.DialogueEditorState);
		set('MenuCharacterEditorState', editors.MenuCharacterEditorState);
		set('WeekEditorState', editors.WeekEditorState);
		set('GameplayChangersSubstate', GameplayChangersSubstate);
		set('ControlsSubState', options.ControlsSubState);
		set('NoteOffsetState', options.NoteOffsetState);
		set('NotesSubState', options.NotesSubState);

		//For Scriptable States

		set('FlxFlicker', flixel.effects.FlxFlicker);
		set('FlxBackdrop', flixel.addons.display.FlxBackdrop);
		set('FlxOgmo3Loader', flixel.addons.editors.ogmo.FlxOgmo3Loader);
		set('FlxTilemap', flixel.tile.FlxTilemap);
		set('Process', sys.io.Process);
		set('FlxGradient', flixel.util.FlxGradient);

        set("switchToScriptSubstate", function(name:String, ?doTransition:Bool = true)
		{
			FlxTransitionableState.skipNextTransIn = !doTransition;
			FlxTransitionableState.skipNextTransOut = !doTransition;
			MusicBeatState.switchState(new ScriptSubstate(name));
		});
        set('openScriptSubState', function(substate:String)
        {
            FlxG.state.openSubState(new ScriptSubstate(substate));
        });

		set('loadSong', function(?name:String = null, ?difficultyNum:Int = -1)
		{
			if(name == null || name.length < 1)
				name = PlayState.SONG.song;
			if (difficultyNum == -1)
				difficultyNum = PlayState.storyDifficulty;

			var poop = Highscore.formatSong(name, difficultyNum);
			PlayState.SONG = Song.loadFromJson(poop, name);
			PlayState.storyDifficulty = difficultyNum;
			FlxG.state.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			FlxG.camera.followLerp = 0;
		});
		set('loadWeek', function (songs:Array<String>, diffInt:Int)
		{
			PlayState.storyPlaylist = songs;
		
			Difficulty.loadFromWeek();
		
			var diffic = Difficulty.getFilePath(diffInt);
			if (diffic == null) diffic = '';
		
			PlayState.storyDifficulty = diffInt;
		
			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
		});
		
		set('doWindowTweenX', function(pos:Int, time:Float, theEase:Dynamic)
		{
			FlxTween.num(Lib.application.window.x, pos, time, {ease: theEase}, windowTweenUpdateX);
		});
		set('doWindowTweenY', function(pos:Int, time:Float, theEase:Dynamic)
		{
			FlxTween.num(Lib.application.window.y, pos, time, {ease: theEase}, windowTweenUpdateY);
		});
		set('doWindowTweenWidth', function(pos:Int, time:Float, theEase:Dynamic)
		{
			FlxTween.num(Lib.application.window.width, pos, time, {ease: theEase}, windowTweenUpdateWidth);
		});
		set('doWindowTweenHeight', function(pos:Int, time:Float, theEase:Dynamic)
		{
			FlxTween.num(Lib.application.window.height, pos, time, {ease: theEase}, windowTweenUpdateHeight);
		});
		set("setWindowX", function(pos:Int)
		{
			Lib.application.window.x = pos;
		});
		set("setWindowY", function(pos:Int)
		{
			Lib.application.window.y = pos;
		});
		set("setWindowWidth", function(pos:Int)
		{
			Lib.application.window.width = pos;
		});
		set("setWindowHeight", function(pos:Int)
		{
			Lib.application.window.height = pos;
		});
		set("getWindowX", function(pos:Int)
		{
			return Lib.application.window.x;
		});
		set("getWindowY", function(pos:Int)
		{
			return Lib.application.window.y;
		});
		set("getWindowWidth", function(pos:Int)
		{
			return Lib.application.window.width;
		});
		set("getWindowHeight", function(pos:Int)
		{
			return Lib.application.window.height;
		});

		//Global Vars

		set("setGlobalVar", function(id:String, data:Dynamic)
		{
			ScriptingVars.globalVars.set(id, data);
		});
		set("getGlobalVar", function(id:String)
		{
			return ScriptingVars.globalVars.get(id);
		});
		set("existsGlobalVar", function(id:String)
		{
			return ScriptingVars.globalVars.exists(id);
		});
		set("removeGlobalVar", function(id:String)
		{
			ScriptingVars.globalVars.remove(id);
		});

		//CPP

		set('changeTitle', function(titleText:String)
		{
			#if windows lime.app.Application.current.window.title = titleText;
			WindowsCPP.reDefineMainWindowTitle(lime.app.Application.current.window.title); #end
		});
		
		set('getDeviceRAM', function()
		{
			#if windows WindowsCPP.reDefineMainWindowTitle(lime.app.Application.current.window.title);
			return WindowsCPP.obtainRAM(); #end
		});
		
		set('screenCapture', function(path:String)
		{
			#if windows WindowsCPP.reDefineMainWindowTitle(lime.app.Application.current.window.title);
			WindowsCPP.windowsScreenShot(path); #end
		});
	
		set('showMessageBox', function(message:String, caption:String, icon:cpp.WindowsAPI.MessageBoxIcon = MSG_WARNING)
		{
			#if windows WindowsCPP.reDefineMainWindowTitle(lime.app.Application.current.window.title);
			WindowsCPP.showMessageBox(caption, message, icon); #end
		});
		
		set('setWindowAlpha', function(a:Float)
		{
			#if windows WindowsCPP.reDefineMainWindowTitle(lime.app.Application.current.window.title);
			WindowsCPP.setWindowAlpha(a); #end
		});
		set('getWindowAlpha', function()
		{
			#if windows WindowsCPP.reDefineMainWindowTitle(lime.app.Application.current.window.title);
			return WindowsCPP.getWindowAlpha(); #end
		});
		set('doWindowTweenAlpha', function(alpha:Float, time:Float, theEase:Dynamic)
		{
			#if windows FlxTween.num(WindowsCPP.getWindowAlpha(), alpha, time, {ease: theEase}, windowTweenUpdateAlpha); #end
		});
	
		set('setBorderColor', function(r:Int, g:Int, b:Int)
		{
			#if windows WindowsCPP.reDefineMainWindowTitle(lime.app.Application.current.window.title);
			WindowsCPP.setWindowBorderColor(r, g, b); #end
		});
		
		set('hideTaskbar', function(hide:Bool)
		{
			#if windows WindowsCPP.reDefineMainWindowTitle(lime.app.Application.current.window.title);
			WindowsCPP.hideTaskbar(hide); #end
		});
	
		set('getCursorX', function()
		{
			#if windows return WindowsCPP.getCursorPositionX(); #end
		});
	
		set('getCursorY', function()
		{
			#if windows return WindowsCPP.getCursorPositionY(); #end
		});
	
		set('clearTerminal', function()
		{
			#if windows WindowsTerminalCPP.clearTerminal(); #end
		});
	
		set('showConsole', function()
		{
			#if windows WindowsTerminalCPP.allocConsole(); #end
		});
	
		set('setConsoleTitle', function(title:String)
		{
			#if windows WindowsTerminalCPP.setConsoleTitle(title); #end
		});
	
		set('disableCloseConsole', function()
		{
			#if windows WindowsTerminalCPP.disableCloseConsoleWindow(); #end
		});
	
		set('hideConsole', function()
		{
			#if windows WindowsTerminalCPP.hideConsoleWindow(); #end
		});
	
		set('sendNotification', function(title:String, desc:String)
		{
			#if windows var powershellCommand = "powershell -Command \"& {$ErrorActionPreference = 'Stop';"
				+ "$title = '"
				+ desc
				+ "';"
				+ "[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null;"
				+ "$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText01);"
				+ "$toastXml = [xml] $template.GetXml();"
				+ "$toastXml.GetElementsByTagName('text').AppendChild($toastXml.CreateTextNode($title)) > $null;"
				+ "$xml = New-Object Windows.Data.Xml.Dom.XmlDocument;"
				+ "$xml.LoadXml($toastXml.OuterXml);"
				+ "$toast = [Windows.UI.Notifications.ToastNotification]::new($xml);"
				+ "$toast.Tag = 'Test1';"
				+ "$toast.Group = 'Test2';"
				+ "$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('"
				+ title
				+ "');"
				+ "$notifier.Show($toast);}\"";
	
			if (title != null && title != "" && desc != null && desc != "")
				new Process(powershellCommand); #end
		});

		//Utils
	
		set('fpsLerp', function(v1:Float, v2:Float, ratio:Float)
		{
			return CoolUtil.fpsLerp(v1, v2, ratio);
		});
	
		set('getFPSRatio', function(ratio:Float)
		{
			return CoolUtil.getFPSRatio(ratio);
		});
	
		set('askToGemini', function(key:String, input:String)
		{
			return CoolUtil.askToGemini(key, input);
		});
		
		//Scriptable States END

		// Functions & Variables
		set('setVar', function(name:String, value:Dynamic) {
		    //State
		    if (Std.is(FlxG.state, PlayState)) PlayState.instance.variables.set(name, value);
			else if (Std.is(FlxG.state, ScriptState)) ScriptState.instance.variables.set(name, value);
			//Substate
			if (Std.is(FlxG.state.subState, ScriptSubstate)) ScriptSubstate.instance.variables.set(name, value);
			return value;
		});
		set('getVar', function(name:String) {
			var result:Dynamic = null;
			//State
			if (Std.is(FlxG.state, ScriptState)) if(ScriptState.instance.variables.exists(name)) result = ScriptState.instance.variables.get(name);
			else if(PlayState.instance.variables.exists(name) && Std.is(FlxG.state, PlayState)) result = PlayState.instance.variables.get(name);
			//Substate
			if(PlayState.instance.variables.exists(name) && Std.is(FlxG.state.subState, ScriptSubstate)) result = ScriptSubstate.instance.variables.get(name);
			return result;
		});
		set('removeVar', function(name:String)
		{
		    //State
			if(Std.is(FlxG.state, PlayState))
		    {
    			if(PlayState.instance.variables.exists(name))
    			{
    				PlayState.instance.variables.remove(name);
    				return true;
    			}
			}
			else if(ScriptState.instance.variables.exists(name) && Std.is(FlxG.state, ScriptState))
			{
				ScriptState.instance.variables.remove(name);
				return true;
			}
			//Substate
			if(PlayState.instance.variables.exists(name) && Std.is(FlxG.state.subState, ScriptSubstate))
		    {
    			if(ScriptSubstate.instance.variables.exists(name))
    			{
    				ScriptSubstate.instance.variables.remove(name);
    				return true;
    			}
			}
			return false;
		});
		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			//State
			if(Std.is(FlxG.state, ScriptState)) ScriptState.instance.addTextToDebug(text, color);
			else if (!onSubstate) HScriptStateHandler.instance.addTextToDebug(text, color);			
			//Substate
			if(Std.is(FlxG.state.subState, ScriptSubstate)) ScriptSubstate.instance.addTextToDebug(text, color);
			else if (onSubstate) HScriptSubStateHandler.instance.addTextToDebug(text, color);
		});
		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if(modName == null)
			{
				if(this.modFolder == null)
				{
				    //State
					if(Std.is(FlxG.state, ScriptState)) ScriptState.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
			        else if (!onSubstate) HScriptStateHandler.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
			        //Substate
			        if(Std.is(FlxG.state.subState, ScriptSubstate)) ScriptSubstate.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
			        else if (onSubstate) HScriptSubStateHandler.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
					return null;
				}
				modName = this.modFolder;
			}
			return ModFunctions.getModSetting(saveTag, modName);
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_LEFT_P');
				case 'down': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_DOWN_P');
				case 'up': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_UP_P');
				case 'right': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_RIGHT_P');
				default: return Reflect.getProperty(MusicBeatState.instance.controls, name);
			}
			return false;
		});
		set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_LEFT');
				case 'down': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_DOWN');
				case 'up': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_UP');
				case 'right': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_RIGHT');
				default: return Reflect.getProperty(MusicBeatState.instance.controls, name);
			}
			return false;
		});
		set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
			    case 'left': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_LEFT_R');
				case 'down': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_DOWN_R');
				case 'up': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_UP_R');
				case 'right': return Reflect.getProperty(MusicBeatState.instance.controls, 'NOTE_RIGHT_R');
				default: return Reflect.getProperty(MusicBeatState.instance.controls, name);
			}
			return false;
		});

		// For adding your own callbacks
		#if HXVIRTUALPAD_ALLOWED
		//OMG
		set('virtualPadPressed', function(buttonPostfix:String):Bool
		{
		    //State
		    if(Std.is(FlxG.state, ScriptState) && !onSubstate) return ScriptState.checkVPadPress(buttonPostfix, 'pressed');
		    else if (!onSubstate) return HScriptStateHandler.checkVPadPress(buttonPostfix, 'pressed');
		    //Substate
		    if(Std.is(FlxG.state.subState, ScriptSubstate) && onSubstate) return ScriptSubstate.checkVPadPress(buttonPostfix, 'pressed');
		    else if (onSubstate) return HScriptSubStateHandler.checkVPadPress(buttonPostfix, 'pressed');
		    return false;
		});
		
		set('virtualPadJustPressed', function(buttonPostfix:String):Bool
		{
		    //State
		    if(Std.is(FlxG.state, ScriptState) && !onSubstate) return ScriptState.checkVPadPress(buttonPostfix, 'justPressed');
		    else if (!onSubstate) return HScriptStateHandler.checkVPadPress(buttonPostfix, 'justPressed');
		    //Substate
		    if(Std.is(FlxG.state.subState, ScriptSubstate) && onSubstate) return ScriptSubstate.checkVPadPress(buttonPostfix, 'justPressed');
		    else if (onSubstate) return HScriptSubStateHandler.checkVPadPress(buttonPostfix, 'justPressed');
		    return false;
		});
		
		set('virtualPadReleased', function(buttonPostfix:String):Bool
		{
		    //State
		    if(Std.is(FlxG.state, ScriptState) && !onSubstate) return ScriptState.checkVPadPress(buttonPostfix, 'released');
		    else if (!onSubstate) return HScriptStateHandler.checkVPadPress(buttonPostfix, 'released');
		    //Substate
		    if(Std.is(FlxG.state.subState, ScriptSubstate) && onSubstate) return ScriptSubstate.checkVPadPress(buttonPostfix, 'released');
		    else if (onSubstate) return HScriptSubStateHandler.checkVPadPress(buttonPostfix, 'released');
		    return false;
		});
		
		set('virtualPadJustReleased', function(buttonPostfix:String):Bool
		{
		    //State
		    if(Std.is(FlxG.state, ScriptState) && !onSubstate) return ScriptState.checkVPadPress(buttonPostfix, 'justReleased');
		    else if (!onSubstate) return HScriptStateHandler.checkVPadPress(buttonPostfix, 'justReleased');
		    //Substate
		    if(Std.is(FlxG.state.subState, ScriptSubstate) && onSubstate) return ScriptSubstate.checkVPadPress(buttonPostfix, 'justReleased');
		    else if (onSubstate) return HScriptSubStateHandler.checkVPadPress(buttonPostfix, 'justReleased');
		    return false;
		});
		
		set('addVirtualPad', function(DPad:String, Action:String):Void
		{
		    //State
		    if(Std.is(FlxG.state, ScriptState) && !onSubstate) return ScriptState.instance.addHxVirtualPad(ScriptState.dpadMode.get(DPad), ScriptState.actionMode.get(Action));
		    else if (!onSubstate) return HScriptStateHandler.instance.addHxVirtualPad(HScriptStateHandler.dpadMode.get(DPad), HScriptStateHandler.actionMode.get(Action));
		    //Substate
		    if(Std.is(FlxG.state.subState, ScriptSubstate) && onSubstate) return ScriptSubstate.instance.addHxVirtualPad(ScriptSubstate.dpadMode.get(DPad), ScriptSubstate.actionMode.get(Action));
		    else if (onSubstate) return HScriptSubStateHandler.instance.addHxVirtualPad(HScriptSubStateHandler.dpadMode.get(DPad), HScriptSubStateHandler.actionMode.get(Action));
		});
		
		set('addVirtualPadCamera', function():Void
		{
		    //State
		    if(Std.is(FlxG.state, ScriptState) && !onSubstate) return ScriptState.instance.addHxVirtualPadCamera();
		    else if (!onSubstate) return HScriptStateHandler.instance.addHxVirtualPadCamera();
		    //Substate
		    if(Std.is(FlxG.state.subState, ScriptSubstate)) return ScriptSubstate.instance.addHxVirtualPadCamera();
		    else if (onSubstate) return HScriptSubStateHandler.instance.addHxVirtualPadCamera();
		});
		
		set('removeVirtualPad', function():Void
		{
		    //State
		    if(Std.is(FlxG.state, ScriptState) && !onSubstate) return ScriptState.instance.removeHxVirtualPad();
		    else if (!onSubstate) return HScriptStateHandler.instance.removeHxVirtualPad();
		    //Substate
		    if(Std.is(FlxG.state.subState, ScriptSubstate)) return ScriptSubstate.instance.removeHxVirtualPad();
		    else if (onSubstate) return HScriptSubStateHandler.instance.removeHxVirtualPad();
		});
		#end
		
		// not very tested but should work
		#if LUA_ALLOWED
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
		    //State
		    if(Std.is(FlxG.state, ScriptState))
		    {
    			for (script in ScriptState.instance.luaArray)
    				if(script != null && script.lua != null && !script.closed)
    					Lua_helper.add_callback(script.lua, name, func);
			}
			//Substate
			if(Std.is(FlxG.state.subState, ScriptSubstate))
		    {
    			for (script in ScriptSubstate.instance.luaArray)
    				if(script != null && script.lua != null && !script.closed)
    					Lua_helper.add_callback(script.lua, name, func);
			}

			FunkinLua.customFunctions.set(name, func);
		});

		// this one was tested
		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			
			if(parentLua != null) Lua_helper.add_callback(funk.lua, name, func);
			else FunkinLua.luaTrace('createCallback ($name): 3rd argument is null', false, false, FlxColor.RED);
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';

				set(libName, Type.resolveClass(str + libName));
			}
			catch (e:Dynamic) {
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				#if LUA_ALLOWED
				if(parentLua != null)
				{
					FunkinLua.lastCalledScript = parentLua;
					FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
					return;
				}
				#end
				if(HScriptStateHandler.instance != null || ScriptState.instance != null) {
    				if(Std.is(FlxG.state, ScriptState) && ScriptState.instance != null) ScriptState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
    			    else if (!onSubstate) HScriptStateHandler.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
				}
				else if (HScriptSubStateHandler.instance != null || ScriptSubstate.instance != null) {
    				if(Std.is(FlxG.state.subState, ScriptSubstate) && ScriptSubstate.instance != null) ScriptSubstate.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
    			    else if (onSubstate) HScriptSubStateHandler.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
			    }
				else trace('$origin - $msg');
			}
		});
		#if LUA_ALLOWED
		set('parentLua', parentLua);
		#else
		set('parentLua', null);
		#end
		set('this', this);
		if (onSubstate)
		    set('game', FlxG.state.subState);
		else
		    set('game', FlxG.state);

		set('buildTarget', FunkinLua.getBuildTarget());

		set('Function_Stop', FunkinLua.Function_Stop);
		set('Function_Continue', FunkinLua.Function_Continue);
		set('Function_StopLua', FunkinLua.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', FunkinLua.Function_StopHScript);
		set('Function_StopAll', FunkinLua.Function_StopAll);
		
		if (onSubstate) {
    		set('add', FlxG.state.subState.add);
    		set('insert', FlxG.state.subState.insert);
    		set('remove', FlxG.state.subState.remove);
    		set('close', FlxG.state.subState.close);
		}
		else {
    		set('add', FlxG.state.add);
    		set('insert', FlxG.state.insert);
    		set('remove', FlxG.state.remove);
		}

		if(Std.is(FlxG.state, ScriptState))
		{
			setSpecialObject(ScriptState.instance, false, ScriptState.instance.instancesExclude);
		}
		else if (Std.is(FlxG.state, ScriptSubstate))
		{
			setSpecialObject(ScriptSubstate.instance, false, ScriptSubstate.instance.instancesExclude);
		}

		if(varsToBring != null) {
			for (key in Reflect.fields(varsToBring)) {
				key = key.trim();
				var value = Reflect.field(varsToBring, key);
				//trace('Key $key: $value');
				set(key, Reflect.field(varsToBring, key));
			}
			varsToBring = null;
		}
	}

	public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):TeaCall {
		if (funcToRun == null) return null;

		if(!exists(funcToRun)) {
			#if LUA_ALLOWED
			FunkinLua.luaTrace(origin + ' - No HScript function named: $funcToRun', false, false, FlxColor.RED);
			#else
			//State
			if(Std.is(FlxG.state, ScriptState) && ScriptState.instance != null) ScriptState.instance.addTextToDebug(origin + ' - No HScript function named: $funcToRun', FlxColor.RED);
			else if (!onSubstate) HScriptStateHandler.instance.addTextToDebug(origin + ' - No HScript function named: $funcToRun', FlxColor.RED);
			//Substate
			if(Std.is(FlxG.state.subState, ScriptSubstate) && ScriptSubstate.instance != null) ScriptSubstate.instance.addTextToDebug(origin + ' - No HScript function named: $funcToRun', FlxColor.RED);
			else if (onSubstate) HScriptSubStateHandler.instance.addTextToDebug(origin + ' - No HScript function named: $funcToRun', FlxColor.RED);
			#end
			return null;
		}

		final callValue = call(funcToRun, funcArgs);
		if (!callValue.succeeded)
		{
			final e = callValue.exceptions[0];
			if (e != null) {
				var msg:String = e.toString();
				#if LUA_ALLOWED
				if(parentLua != null)
				{
					FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
					return null;
				}
				#end
				if(Std.is(FlxG.state, ScriptState) && ScriptState.instance != null) ScriptState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
			    else if (!onSubstate) HScriptStateHandler.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
			    
			    if(Std.is(FlxG.state.subState, ScriptSubstate) && ScriptSubstate.instance != null) ScriptSubstate.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
			    else if (onSubstate) HScriptSubStateHandler.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
			}
			return null;
		}
		return callValue;
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>):TeaCall {
		if (funcToRun == null) return null;
		return call(funcToRun, funcArgs);
	}

	override public function destroy()
	{
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end

		super.destroy();
	}
}

class CustomFlxColor {
	public static var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
	public static var BLACK(default, null):Int = FlxColor.BLACK;
	public static var WHITE(default, null):Int = FlxColor.WHITE;
	public static var GRAY(default, null):Int = FlxColor.GRAY;

	public static var GREEN(default, null):Int = FlxColor.GREEN;
	public static var LIME(default, null):Int = FlxColor.LIME;
	public static var YELLOW(default, null):Int = FlxColor.YELLOW;
	public static var ORANGE(default, null):Int = FlxColor.ORANGE;
	public static var RED(default, null):Int = FlxColor.RED;
	public static var PURPLE(default, null):Int = FlxColor.PURPLE;
	public static var BLUE(default, null):Int = FlxColor.BLUE;
	public static var BROWN(default, null):Int = FlxColor.BROWN;
	public static var PINK(default, null):Int = FlxColor.PINK;
	public static var MAGENTA(default, null):Int = FlxColor.MAGENTA;
	public static var CYAN(default, null):Int = FlxColor.CYAN;

	public static function fromInt(Value:Int):Int 
	{
		return cast FlxColor.fromInt(Value);
	}

	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
	{
		return cast FlxColor.fromRGB(Red, Green, Blue, Alpha);
	}
	public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
	{	
		return cast FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);
	}

	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
	{
		return cast FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);
	}

	public static function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
	{	
		return cast FlxColor.fromHSB(Hue, Sat, Brt, Alpha);
	}
	public static function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
	{	
		return cast FlxColor.fromHSL(Hue, Sat, Light, Alpha);
	}
	public static function fromString(str:String):Int
	{
		return cast FlxColor.fromString(str);
	}
}
#end
