package funkin.backend.score;

import flixel.FlxG;

class Highscore
{
	public static var songScores:Map<String, Int> = new Map();

	// ---------------------------------------------------------------
	//  Save
	// ---------------------------------------------------------------

	public static function saveScore(song:String, score:Int = 0, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);

		if (!songScores.exists(daSong) || songScores.get(daSong) < score)
			setScore(daSong, score);
	}

	public static function saveWeekScore(week:Int = 1, score:Int = 0, diff:Int = 0):Void
	{
		var daWeek:String = formatSong('week' + week, diff);

		if (!songScores.exists(daWeek) || songScores.get(daWeek) < score)
			setScore(daWeek, score);
	}

	// ---------------------------------------------------------------
	//  Get
	// ---------------------------------------------------------------

	public static function getScore(song:String, diff:Int):Int
	{
		var key:String = formatSong(song, diff);
		if (!songScores.exists(key))
			setScore(key, 0);
		return songScores.get(key);
	}

	public static function getWeekScore(week:Int, diff:Int):Int
	{
		var key:String = formatSong('week' + week, diff);
		if (!songScores.exists(key))
			setScore(key, 0);
		return songScores.get(key);
	}

	// ---------------------------------------------------------------
	//  Format
	// ---------------------------------------------------------------

	public static function formatSong(song:String, diff:Int):String
	{
		return switch (diff)
		{
			case 0:  song + '-easy';
			case 2:  song + '-hard';
			default: song;
		};
	}

	// ---------------------------------------------------------------
	//  Persistence
	// ---------------------------------------------------------------

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;
	}

	private static function setScore(song:String, score:Int):Void
	{
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}
}
