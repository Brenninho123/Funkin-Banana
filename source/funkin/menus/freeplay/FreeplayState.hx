package funkin.menus.freeplay;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.backend.objects.Alphabet;
import funkin.menus.title.TitleState;
import funkin.gameplay.PlayState;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<String> = [];

	var curSelected:Int    = 0;
	var curDifficulty:Int  = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int     = 0;
	var intendedScore:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;

	// ---------------------------------------------------------------
	//  Create
	// ---------------------------------------------------------------

	override function create():Void
	{
		songs = CoolUtil.coolTextFile('assets/data/freeplaySonglist.txt');

		var isDebug:Bool = false;
		#if debug
		isDebug = true;
		#end

		if (StoryMenuState.weekUnlocked[2] || isDebug)
		{
			songs.push('Spookeez');
			songs.push('South');
		}

		if (StoryMenuState.weekUnlocked[3] || isDebug)
		{
			songs.push('Pico');
			songs.push('Philly');
			songs.push('Blammed');
		}

		if (StoryMenuState.weekUnlocked[4] || isDebug)
		{
			songs.push('Satin-Panties');
			songs.push('High');
			songs.push('Milf');
		}

		if (StoryMenuState.weekUnlocked[5] || isDebug)
		{
			songs.push('Cocoa');
			songs.push('Eggnog');
			songs.push('Winter-Horrorland');
		}

		if (StoryMenuState.weekUnlocked[6] || isDebug)
		{
			songs.push('Senpai');
			songs.push('Roses');
			songs.push('Thorns');
		}

		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i], true, false);
			songText.isMenuItem = true;
			songText.targetY    = i;
			grpSongs.add(songText);
		}

		var scoreX:Float = FlxG.width * 0.7;

		var scoreBG:FlxSprite = new FlxSprite(scoreX - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		scoreText = new FlxText(scoreX, 5, 0, "", 32);
		scoreText.setFormat("assets/fonts/vcr.ttf", 32, FlxColor.WHITE, RIGHT);
		add(scoreText);

		diffText = new FlxText(scoreX, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		changeSelection();
		changeDiff();

		super.create();
	}

	// ---------------------------------------------------------------
	//  Update
	// ---------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

		if (controls.UP_P)    changeSelection(-1);
		if (controls.DOWN_P)  changeSelection(1);
		if (controls.LEFT_P)  changeDiff(-1);
		if (controls.RIGHT_P) changeDiff(1);

		if (controls.BACK)
			FlxG.switchState(new MainMenuState());

		if (controls.ACCEPT)
			selectSong();
	}

	// ---------------------------------------------------------------
	//  Actions
	// ---------------------------------------------------------------

	function selectSong():Void
	{
		var poop:String = Highscore.formatSong(songs[curSelected].toLowerCase(), curDifficulty);

		PlayState.SONG            = Song.loadFromJson(poop, songs[curSelected].toLowerCase());
		PlayState.isStoryMode     = false;
		PlayState.storyDifficulty = curDifficulty;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.switchState(new PlayState());
	}

	function changeDiff(change:Int = 0):Void
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, 2);

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected], curDifficulty);
		#end

		diffText.text = switch (curDifficulty)
		{
			case 0:  "EASY";
			case 2:  "HARD";
			default: "NORMAL";
		};
	}

	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected], curDifficulty);
		#end

		FlxG.sound.playMusic('assets/music/' + songs[curSelected] + "_Inst" + TitleState.soundExt, 0);

		var i:Int = 0;
		for (item in grpSongs.members)
		{
			item.targetY = i - curSelected;
			item.alpha   = (item.targetY == 0) ? 1.0 : 0.6;
			i++;
		}
	}
}
