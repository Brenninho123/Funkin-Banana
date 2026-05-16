package funkin.menus.options;

import Controls.Control;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.backend.objects.Alphabet;
import funkin.menus.title.TitleState;
import funkin.menus.mainmenu.MainMenuState;

class OptionsMenu extends MusicBeatState
{
	var curSelected:Int       = 0;
	var isSettingControl:Bool = false;

	var controlsStrings:Array<String> = [];

	private var grpControls:FlxTypedGroup<Alphabet>;

	// ---------------------------------------------------------------
	//  Create
	// ---------------------------------------------------------------

	override function create():Void
	{
		controlsStrings = CoolUtil.coolTextFile('assets/data/controls.txt');

		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		grpControls = new FlxTypedGroup<Alphabet>();
		add(grpControls);

		for (i in 0...controlsStrings.length)
		{
			if (controlsStrings[i].indexOf('set') != -1)
			{
				var controlLabel:Alphabet = new Alphabet(
					0,
					(70 * i) + 30,
					controlsStrings[i].substring(3) + ': ' + controlsStrings[i + 1],
					true,
					false
				);
				controlLabel.isMenuItem = true;
				controlLabel.targetY    = i;
				grpControls.add(controlLabel);
			}
		}

		super.create();
	}

	// ---------------------------------------------------------------
	//  Update
	// ---------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.ACCEPT)
			changeBinding();

		if (isSettingControl)
		{
			waitingInput();
		}
		else
		{
			if (controls.BACK)    FlxG.switchState(new MainMenuState());
			if (controls.UP_P)   changeSelection(-1);
			if (controls.DOWN_P) changeSelection(1);
		}
	}

	// ---------------------------------------------------------------
	//  Actions
	// ---------------------------------------------------------------

	function waitingInput():Void
	{
		var keysDown = FlxG.keys.getIsDown();
		if (keysDown.length > 0)
			PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, keysDown[0].ID, null);
	}

	function changeBinding():Void
	{
		if (!isSettingControl)
			isSettingControl = true;
	}

	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected = FlxMath.wrap(curSelected + change, 0, grpControls.length - 1);

		var i:Int = 0;
		for (item in grpControls.members)
		{
			item.targetY = i - curSelected;
			item.alpha   = (item.targetY == 0) ? 1.0 : 0.6;
			i++;
		}
	}
}
