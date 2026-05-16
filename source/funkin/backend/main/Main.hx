package funkin.backend.main;

import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;
import flixel.FlxGame;
import flixel.FlxState;
import funkin.menus.title.TitleState;

#if mobile
import mobile.Storage;
#end

class Main extends Sprite
{
	static final GAME_WIDTH:Int  = 1280;
	static final GAME_HEIGHT:Int = 720;

	#if web
	static final FRAMERATE:Int = 60;
	#elseif mobile
	static final FRAMERATE:Int = 60;
	#else
	static final FRAMERATE:Int = 144;
	#end

	var initialState:Class<FlxState> = TitleState;
	var zoom:Float        = -1;
	var skipSplash:Bool   = true;
	var startFullscreen:Bool = false;

	var gameWidth:Int  = GAME_WIDTH;
	var gameHeight:Int = GAME_HEIGHT;

	public static var fpsCounter:FPS;

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(
			UncaughtErrorEvent.UNCAUGHT_ERROR,
			onUncaughtError
		);

		#if mobile
		Storage.init();
		Storage.extractAssets(lime.app.Application.current.meta.get("version"));
		#end

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	private function init(?e:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int  = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth  / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom       = Math.min(ratioX, ratioY);
			gameWidth  = Math.ceil(stageWidth  / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		addChild(new FlxGame(gameWidth, gameHeight, initialState, FRAMERATE, FRAMERATE, skipSplash, startFullscreen));

		#if !mobile
		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);
		#end
	}

	private function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();

		var message:String = (e.error is String)
			? cast(e.error, String)
			: Std.string(e.error);

		lime.app.Application.current.window.alert('Uncaught error:\n$message', "Error");
	}
}
