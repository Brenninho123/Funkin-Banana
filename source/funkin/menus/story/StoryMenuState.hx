package funkin.menus.story;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.menus.title.TitleState;
import funkin.menus.mainmenu.MainMenuState;
import funkin.gameplay.PlayState;
import funkin.backend.score.Highscore;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	var weekData:Array<Dynamic> = [
		['Tutorial'],
		['Bopeebo', 'Fresh', 'Dadbattle'],
		['Spookeez', 'South'],
		['Pico', 'Philly', 'Blammed'],
		['Satin-Panties', 'High', 'Milf'],
		['Cocoa', 'Eggnog', 'Winter-Horrorland'],
		['Senpai', 'Roses', 'Thorns']
	];

	var weekCharacters:Array<Dynamic> = [
		['dad',              'bf', 'gf'],
		['dad',              'bf', 'gf'],
		['spooky',           'bf', 'gf'],
		['pico',             'bf', 'gf'],
		['mom',              'bf', 'gf'],
		['parents-christmas','bf', 'gf'],
		['senpai',           'bf', 'gf']
	];

	var weekNames:Array<String> = [
		"",
		"Daddy Dearest",
		"Spooky Month",
		"PICO",
		"MOMMY MUST MURDER",
		"RED SNOW",
		"hating simulator ft. moawling"
	];

	public static var weekUnlocked:Array<Bool> = [true, true, true, true, true, true, true];

	var curWeek:Int       = 0;
	var curDifficulty:Int = 1;
	var lerpScore:Int     = 0;
	var intendedScore:Int = 0;

	var movedBack:Bool    = false;
	var selectedWeek:Bool = false;
	var stopSpamming:Bool = false;

	var scoreText:FlxText;
	var txtWeekTitle:FlxText;
	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	// ---------------------------------------------------------------
	//  Create
	// ---------------------------------------------------------------

	override function create():Void
	{
		transIn  = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
			FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);

		persistentUpdate = persistentDraw = true;

		var ui_tex = FlxAtlasFrames.fromSparrow(
			'assets/images/campaign_menu_UI_assets.png',
			'assets/images/campaign_menu_UI_assets.xml'
		);

		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		scoreText = new FlxText(10, 10, 0, "WEEK SCORE: 0", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.setFormat("assets/fonts/vcr.ttf", 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		grpLocks          = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		for (i in 0...weekData.length)
		{
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, i);
			weekThing.y      += (weekThing.height + 20) * i;
			weekThing.targetY = i;
			weekThing.screenCenter(X);
			weekThing.antialiasing = true;
			grpWeekText.add(weekThing);

			if (!weekUnlocked[i])
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.antialiasing = true;
				lock.ID = i;
				grpLocks.add(lock);
			}
		}

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter(
				(FlxG.width * 0.25) * (1 + char) - 150,
				weekCharacters[curWeek][char]
			);
			weekCharacterThing.y += 70;
			weekCharacterThing.antialiasing = true;

			switch (weekCharacterThing.character)
			{
				case 'dad' | 'gf':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
					weekCharacterThing.updateHitbox();
				case 'bf':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
					weekCharacterThing.updateHitbox();
					weekCharacterThing.x -= 80;
				case 'pico':
					weekCharacterThing.flipX = true;
				case 'parents-christmas':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
					weekCharacterThing.updateHitbox();
			}

			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle',  'arrow left');
		leftArrow.animation.addByPrefix('press', 'arrow push left');
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		sprDifficulty.frames = ui_tex;
		sprDifficulty.animation.addByPrefix('easy',   'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard',   'HARD');
		sprDifficulty.animation.play('normal');
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle',  'arrow right');
		rightArrow.animation.addByPrefix('press', 'arrow push right', 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(yellowBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font      = rankText.font;
		txtTracklist.color     = 0xFFe55777;
		add(txtTracklist);

		add(scoreText);
		add(txtWeekTitle);

		changeDifficulty();
		updateText();

		super.create();
	}

	// ---------------------------------------------------------------
	//  Update
	// ---------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));
		scoreText.text = "WEEK SCORE:" + lerpScore;

		txtWeekTitle.text = weekNames[curWeek].toUpperCase();
		txtWeekTitle.x    = FlxG.width - (txtWeekTitle.width + 10);

		difficultySelectors.visible = weekUnlocked[curWeek];

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				_handleInput();
				_handleTouch();

				rightArrow.animation.play(controls.RIGHT ? 'press' : 'idle');
				leftArrow.animation.play(controls.LEFT   ? 'press' : 'idle');
			}

			if (controls.ACCEPT)
				selectWeek();
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play('assets/sounds/cancelMenu' + TitleState.soundExt);
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	// ---------------------------------------------------------------
	//  Input
	// ---------------------------------------------------------------

	private function _handleInput():Void
	{
		if (controls.UP_P)   changeWeek(-1);
		if (controls.DOWN_P) changeWeek(1);

		if (controls.RIGHT_P) changeDifficulty(1);
		if (controls.LEFT_P)  changeDifficulty(-1);
	}

	#if mobile
	private function _handleTouch():Void
	{
		for (touch in FlxG.touches.justStarted())
		{
			var touchX:Float = touch.screenX;
			var touchY:Float = touch.screenY;
			var midX:Float   = FlxG.width  * 0.5;
			var midY:Float   = FlxG.height * 0.5;

			if (touchY < midY - 80)
				changeWeek(-1);
			else if (touchY > midY + 80)
				changeWeek(1);

			if (touchX < midX - 120)
				changeDifficulty(-1);
			else if (touchX > midX + 120)
				changeDifficulty(1);

			grpWeekText.forEach(function(item:MenuItem)
			{
				if (touch.overlaps(item) && item.targetY == 0 && weekUnlocked[curWeek])
					selectWeek();
			});
		}
	}
	#else
	private function _handleTouch():Void {}
	#end

	// ---------------------------------------------------------------
	//  Actions
	// ---------------------------------------------------------------

	function selectWeek():Void
	{
		if (!weekUnlocked[curWeek])
			return;

		if (!stopSpamming)
		{
			FlxG.sound.play('assets/sounds/confirmMenu' + TitleState.soundExt);
			grpWeekText.members[curWeek].week.animation.resume();
			grpWeekCharacters.members[1].animation.play('bfConfirm');
			stopSpamming = true;
		}

		var diffic:String = switch (curDifficulty)
		{
			case 0: '-easy';
			case 2: '-hard';
			default: '';
		};

		PlayState.storyPlaylist  = weekData[curWeek];
		PlayState.isStoryMode    = true;
		PlayState.storyDifficulty = curDifficulty;
		PlayState.SONG           = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
		PlayState.storyWeek      = curWeek;
		PlayState.campaignScore  = 0;

		selectedWeek = true;

		new FlxTimer().start(1, function(_)
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			FlxG.switchState(new PlayState());
		});
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, 2);

		sprDifficulty.offset.x = 0;

		switch (curDifficulty)
		{
			case 0: sprDifficulty.animation.play('easy');   sprDifficulty.offset.x = 20;
			case 1: sprDifficulty.animation.play('normal'); sprDifficulty.offset.x = 70;
			case 2: sprDifficulty.animation.play('hard');   sprDifficulty.offset.x = 20;
		}

		sprDifficulty.alpha = 0;
		sprDifficulty.y     = leftArrow.y - 15;

		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end
	}

	function changeWeek(change:Int = 0):Void
	{
		curWeek = FlxMath.wrap(curWeek + change, 0, weekData.length - 1);

		var i:Int = 0;
		for (item in grpWeekText.members)
		{
			item.targetY = i - curWeek;
			item.alpha   = (item.targetY == 0 && weekUnlocked[curWeek]) ? 1.0 : 0.6;
			i++;
		}

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt);
		updateText();
	}

	function updateText():Void
	{
		for (i in 0...3)
			grpWeekCharacters.members[i].animation.play(weekCharacters[curWeek][i]);

		var dadChar = grpWeekCharacters.members[0];

		switch (dadChar.animation.curAnim.name)
		{
			case 'parents-christmas':
				dadChar.offset.set(200, 200);
				dadChar.setGraphicSize(Std.int(dadChar.width * 0.99));
			case 'senpai':
				dadChar.offset.set(130, 0);
				dadChar.setGraphicSize(Std.int(dadChar.width * 1.4));
			case 'mom':
				dadChar.offset.set(100, 200);
				dadChar.setGraphicSize(Std.int(dadChar.width * 1));
			case 'dad':
				dadChar.offset.set(120, 200);
				dadChar.setGraphicSize(Std.int(dadChar.width * 1));
			default:
				dadChar.offset.set(100, 100);
				dadChar.setGraphicSize(Std.int(dadChar.width * 1));
		}

		txtTracklist.text = "Tracks\n";
		for (song in (weekData[curWeek] : Array<String>))
			txtTracklist.text += "\n" + song;

		txtTracklist.text = txtTracklist.text.toUpperCase();
		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end
	}
}
