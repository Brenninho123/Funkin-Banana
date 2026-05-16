package;

import flixel.FlxG;
import flixel.util.FlxSignal;
import flixel.util.FlxTimer;
import io.newgrounds.NG;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.objects.events.Response;
import io.newgrounds.objects.events.Result.GetCurrentVersionResult;
import lime.app.Application;

using StringTools;

class NGio
{
	public static var isLoggedIn:Bool        = false;
	public static var medalsLoaded:Bool      = false;
	public static var scoreboardsLoaded:Bool = false;

	public static var scoreboardArray:Array<Score> = [];

	public static var onLogin:FlxSignal        = new FlxSignal();
	public static var onMedalsReady:FlxSignal  = new FlxSignal();
	public static var onScoresReady:FlxSignal  = new FlxSignal();
	public static var onVersionFetched:FlxSignal = new FlxSignal();

	public static var onError:String->Void = null;

	public static var gameVersion:String     = "";
	public static var gameVersionNums:String = "";
	public static var gotOnlineVersion:Bool  = false;

	private static var _instance:NGio = null;

	public static function noLogin(api:String):Void
	{
		gameVersion = "v" + Application.current.meta.get("version");

		if (api == null || api.length == 0)
			return;

		NG.create(api);

		new FlxTimer().start(2, function(_)
		{
			NG.core.calls.app.getCurrentVersion(gameVersion)
				.addDataHandler(function(response:Response<GetCurrentVersionResult>)
				{
					if (response.success)
					{
						gameVersion     = response.result.data.currentVersion;
						gameVersionNums = gameVersion.split(" ")[0].trim();
						gotOnlineVersion = true;
						onVersionFetched.dispatch();
					}
					else if (onError != null)
					{
						onError("Failed to fetch online version.");
					}
				})
				.send();
		});
	}

	public static function create(api:String, encKey:String, ?sessionId:String):Void
	{
		if (_instance != null)
			return;

		_instance = new NGio(api, encKey, sessionId);
	}

	inline public static function postScore(score:Int, song:String):Void
	{
		if (!isLoggedIn)
			return;

		for (id in NG.core.scoreBoards.keys())
		{
			var board:ScoreBoard = NG.core.scoreBoards.get(id);
			if (board.name == song)
				board.postScore(score);
		}
	}

	inline public static function unlockMedal(id:Int):Void
	{
		if (!isLoggedIn)
			return;

		var medal:Medal = NG.core.medals.get(id);
		if (medal != null && !medal.unlocked)
			medal.sendUnlock();
	}

	inline public static function isMedalUnlocked(id:Int):Bool
	{
		if (!isLoggedIn || !medalsLoaded)
			return false;

		var medal:Medal = NG.core.medals.get(id);
		return medal != null && medal.unlocked;
	}

	public static function getMedal(id:Int):Null<Medal>
	{
		if (!isLoggedIn || !medalsLoaded)
			return null;

		return NG.core.medals.get(id);
	}

	public static function getScoreboard(id:Int):Null<ScoreBoard>
	{
		if (!isLoggedIn || !scoreboardsLoaded)
			return null;

		return NG.core.scoreBoards.get(id);
	}

	public static function requestScores(boardId:Int, count:Int = 10, ?onDone:Array<Score>->Void):Void
	{
		if (!isLoggedIn || !scoreboardsLoaded)
			return;

		var board:ScoreBoard = NG.core.scoreBoards.get(boardId);
		if (board == null)
			return;

		board.onUpdate.addOnce(function()
		{
			scoreboardArray = board.scores;
			onScoresReady.dispatch();

			if (onDone != null)
				onDone(board.scores);
		});

		board.requestScores(count);
	}

	inline public static function logEvent(event:String):Void
	{
		if (NG.core == null)
			return;

		NG.core.calls.event.logEvent(event).send();
	}

	private function new(api:String, encKey:String, ?sessionId:String)
	{
		gameVersion = "v" + Application.current.meta.get("version");

		NG.createAndCheckSession(api, sessionId);
		NG.core.verbose = false;
		NG.core.initEncryption(encKey);

		if (NG.core.attemptingLogin)
			NG.core.onLogin.add(_onLogin);
		else
			NG.core.requestLogin(_onLogin);
	}

	private function _onLogin():Void
	{
		isLoggedIn = true;

		if (NG.core.sessionId != null)
			FlxG.save.data.sessionId = NG.core.sessionId;

		NG.core.requestMedals(_onMedalsFetched);
		NG.core.requestScoreBoards(_onBoardsFetched);

		onLogin.dispatch();
	}

	private function _onMedalsFetched():Void
	{
		medalsLoaded = true;
		onMedalsReady.dispatch();
	}

	private function _onBoardsFetched():Void
	{
		scoreboardsLoaded = true;
		onScoresReady.dispatch();
	}
}
