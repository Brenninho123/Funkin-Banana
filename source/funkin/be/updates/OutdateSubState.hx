package funkin.be.updates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;
import funkin.menus.mainmenu.MainMenuState;

class OutdatedSubState extends MusicBeatState
{
	public static var leftState:Bool = false;

	override function create():Void
	{
		super.create();

		var localVersion:String = "v" + Application.current.meta.get('version');

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			'HEY! You\'re running an outdated version of the game!\n'
			+ 'Your version is $localVersion.\n'
			+ 'Press ACCEPT to go to itch.io for the latest version, or BACK to ignore this.',
			32
		);
		txt.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float):Void
	{
		if (controls.ACCEPT)
			FlxG.openURL("https://ninja-muffin24.itch.io/funkin");

		if (controls.BACK)
		{
			leftState = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}
}
