package funkin.menus.mainmenu;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import funkin.menus.title.TitleState;
import funkin.menus.freeplay.FreeplayState;
import funkin.menus.story.StoryMenuState;
import funkin.menus.options.OptionsMenu;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	#if !switch
	var optionShit:Array<String> = ['story mode', 'freeplay', 'donate'];
	#else
	var optionShit:Array<String> = ['story mode', 'freeplay'];
	#end

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	var selectedSomethin:Bool = false;

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

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic('assets/images/menuBG.png');
		bg.scrollFactor.set(0, 0.18);
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic('assets/images/menuDesat.png');
		magenta.scrollFactor.set(0, 0.18);
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible  = false;
		magenta.antialiasing = true;
		magenta.color    = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var tex = FlxAtlasFrames.fromSparrow('assets/images/FNF_main_menu_assets.png', 'assets/images/FNF_main_menu_assets.xml');

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 160));
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle',     optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
			menuItems.add(menuItem);
		}

		FlxG.camera.follow(camFollow, null, 0.06);

		var versionText:FlxText = new FlxText(5, FlxG.height - 18, 0, "v" + Application.current.meta.get('version'), 12);
		versionText.scrollFactor.set();
		versionText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionText);

		changeItem();

		super.create();
	}

	// ---------------------------------------------------------------
	//  Update
	// ---------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!selectedSomethin)
		{
			_handleInput();
			_handleTouch();
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite) { spr.screenCenter(X); });
	}

	// ---------------------------------------------------------------
	//  Input
	// ---------------------------------------------------------------

	private function _handleInput():Void
	{
		if (controls.UP_P)
		{
			FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt);
			changeItem(-1);
		}

		if (controls.DOWN_P)
		{
			FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt);
			changeItem(1);
		}

		if (controls.BACK)
			FlxG.switchState(new TitleState());

		if (controls.ACCEPT)
			selectItem();
	}

	#if mobile
	private function _handleTouch():Void
	{
		for (touch in FlxG.touches.justStarted())
		{
			menuItems.forEach(function(spr:FlxSprite)
			{
				if (spr.ID == curSelected && touch.overlaps(spr))
					selectItem();
			});

			var touchY:Float = touch.screenY;
			var midY:Float   = FlxG.height * 0.5;

			if (touchY < midY - 60)
			{
				FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt);
				changeItem(-1);
			}
			else if (touchY > midY + 60)
			{
				FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt);
				changeItem(1);
			}
		}
	}
	#else
	private function _handleTouch():Void {}
	#end

	// ---------------------------------------------------------------
	//  Actions
	// ---------------------------------------------------------------

	function selectItem():Void
	{
		if (optionShit[curSelected] == 'donate')
		{
			#if linux
			Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
			#else
			FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
			#end
			return;
		}

		selectedSomethin = true;
		FlxG.sound.play('assets/sounds/confirmMenu' + TitleState.soundExt);
		FlxFlicker.flicker(magenta, 1.1, 0.15, false);

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (curSelected != spr.ID)
			{
				FlxTween.tween(spr, {alpha: 0}, 0.4, {
					ease: FlxEase.quadOut,
					onComplete: function(_) { spr.kill(); }
				});
			}
			else
			{
				FlxFlicker.flicker(spr, 1, 0.06, false, false, function(_)
				{
					switch (optionShit[curSelected])
					{
						case 'story mode': FlxG.switchState(new StoryMenuState());
						case 'freeplay':   FlxG.switchState(new FreeplayState());
						case 'options':    FlxG.switchState(new OptionsMenu());
					}
				});
			}
		});
	}

	function changeItem(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, menuItems.length - 1);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play(spr.ID == curSelected ? 'selected' : 'idle');

			if (spr.ID == curSelected)
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);

			spr.updateHitbox();
		});
	}
}
