package funkin.backend.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.menus.title.TitleState;

using StringTools;

enum abstract AlphabetAlign(String) to String
{
	var LEFT   = "left";
	var CENTER = "center";
	var RIGHT  = "right";
}

class Alphabet extends FlxSpriteGroup
{
	public static final CHAR_WIDTH:Float  = 40;
	public static final CHAR_HEIGHT:Float = 55;
	public static final LINE_HEIGHT:Float = 60;
	public static final SPACE_WIDTH:Float = 40;
	public static final TYPE_SPACING:Int  = 3;

	public var delay:Float = 0.05;
	public var paused:Bool = false;

	public var targetY:Float   = 0;
	public var isMenuItem:Bool = false;

	public var alignment:AlphabetAlign = LEFT;

	public var text(default, set):String = "";

	public var talkingSound:String = "GF_";
	public var talkingChance:Float = 40;

	public var onTypingComplete:Void->Void = null;

	private var _isBold:Bool  = false;
	private var _isTyped:Bool = false;

	private var _splitWords:Array<String> = [];
	private var _lastSprite:AlphaCharacter;
	private var _lastWasSpace:Bool = false;
	private var _xPosResetted:Bool = false;
	private var _yMulti:Float = 1;
	private var _typingTimer:FlxTimer;

	// ---------------------------------------------------------------
	//  Constructor
	// ---------------------------------------------------------------

	public function new(x:Float, y:Float, text:String = "", bold:Bool = false, typed:Bool = false)
	{
		super(x, y);

		_isBold  = bold;
		_isTyped = typed;

		if (text != "")
			this.text = text;
	}

	// ---------------------------------------------------------------
	//  Public API
	// ---------------------------------------------------------------

	/**
		Replaces the current text with new content.
		Clears all existing characters and rebuilds.
	**/
	public function setText(newText:String, ?typed:Bool):Void
	{
		_isTyped = typed ?? _isTyped;
		text     = newText;
	}

	/**
		Immediately completes any in-progress typed animation.
	**/
	public function skipTyping():Void
	{
		if (_typingTimer != null && !_typingTimer.finished)
		{
			_typingTimer.cancel();
			_typingTimer = null;
			clearChars();
			_buildText();
		}
	}

	/** Tints every character in the group. **/
	public function setColor(color:FlxColor):Void
	{
		forEach(function(spr:FlxSprite) { spr.color = color; });
	}

	/**
		Returns the total pixel width of the rendered text.
	**/
	public function getLineWidth():Float
	{
		if (_lastSprite == null)
			return 0;
		return (_lastSprite.x - x) + _lastSprite.width;
	}

	// ---------------------------------------------------------------
	//  Internal build
	// ---------------------------------------------------------------

	private function set_text(value:String):String
	{
		text = value;
		clearChars();
		_reset();
		_splitWords = value.split("");

		if (value != "")
		{
			if (_isTyped)
				_startTypedText();
			else
				_buildText();
		}

		return text;
	}

	private function _reset():Void
	{
		_lastSprite    = null;
		_lastWasSpace  = false;
		_xPosResetted  = false;
		_yMulti        = 1;

		if (_typingTimer != null)
		{
			_typingTimer.cancel();
			_typingTimer = null;
		}
	}

	private function clearChars():Void
	{
		forEach(function(spr:FlxSprite) { spr.kill(); });
		clear();
	}

	private function _buildText():Void
	{
		var xPos:Float = 0;

		for (character in _splitWords)
		{
			if (character == "\n")
			{
				_yMulti      += 1;
				xPos          = 0;
				_lastSprite   = null;
				continue;
			}

			if (character == " " || character == "-")
			{
				_lastWasSpace = true;
				continue;
			}

			if (!AlphaCharacter.isSupported(character))
				continue;

			if (_lastSprite != null)
				xPos = _lastSprite.x + _lastSprite.width;

			if (_lastWasSpace)
			{
				xPos         += SPACE_WIDTH;
				_lastWasSpace = false;
			}

			var letter:AlphaCharacter = new AlphaCharacter(xPos, (_yMulti - 1) * LINE_HEIGHT);
			_applyCharacter(letter, character);
			add(letter);
			_lastSprite = letter;
		}

		_applyAlignment();
	}

	private function _startTypedText():Void
	{
		var loopNum:Int   = 0;
		var xPos:Float    = 0;
		var curRow:Int    = 0;

		_typingTimer = new FlxTimer().start(delay, function(tmr:FlxTimer)
		{
			if (paused)
			{
				tmr.reset(delay);
				return;
			}

			var ch:String = _splitWords[loopNum];

			if (ch == "\n")
			{
				_yMulti      += 1;
				xPos          = 0;
				_xPosResetted = true;
				curRow        += 1;
			}
			else if (ch == " ")
			{
				_lastWasSpace = true;
			}
			else if (AlphaCharacter.isSupported(ch))
			{
				if (_lastSprite != null && !_xPosResetted)
				{
					_lastSprite.updateHitbox();
					xPos += _lastSprite.width + TYPE_SPACING;
				}
				else
				{
					_xPosResetted = false;
				}

				if (_lastWasSpace)
				{
					xPos         += SPACE_WIDTH * 0.5;
					_lastWasSpace = false;
				}

				var letter:AlphaCharacter = new AlphaCharacter(xPos, CHAR_HEIGHT * _yMulti);
				letter.row = curRow;
				_applyCharacter(letter, ch, true);
				add(letter);
				_lastSprite = letter;

				if (talkingChance > 0 && FlxG.random.bool(talkingChance))
					FlxG.sound.play('assets/sounds/' + talkingSound + FlxG.random.int(1, 4) + TitleState.soundExt, 0.4);
			}

			loopNum++;
			tmr.time = FlxG.random.float(0.04, 0.09);
		}, _splitWords.length);

		_typingTimer.completionCallback = function(_)
		{
			_applyAlignment();
			if (onTypingComplete != null)
				onTypingComplete();
		};
	}

	private function _applyCharacter(letter:AlphaCharacter, ch:String, typed:Bool = false):Void
	{
		if (_isBold)
		{
			letter.createBold(ch);
			return;
		}

		if (typed)
			letter.x += 90;

		if (AlphaCharacter.numbers.contains(ch))
			letter.createNumber(ch);
		else if (AlphaCharacter.symbols.contains(ch))
			letter.createSymbol(ch);
		else
			letter.createLetter(ch);
	}

	private function _applyAlignment():Void
	{
		if (alignment == LEFT || members.length == 0)
			return;

		var lineWidths:Map<Int, Float> = [];

		for (member in members)
		{
			var ch = cast(member, AlphaCharacter);
			var row = ch.row;
			if (!lineWidths.exists(row) || ch.x + ch.width > lineWidths.get(row))
				lineWidths.set(row, ch.x + ch.width);
		}

		for (member in members)
		{
			var ch     = cast(member, AlphaCharacter);
			var lWidth = lineWidths.get(ch.row);

			if (alignment == CENTER)
				ch.x -= lWidth / 2;
			else if (alignment == RIGHT)
				ch.x -= lWidth;
		}
	}

	// ---------------------------------------------------------------
	//  Update
	// ---------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);
			y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.48), 0.16);
			x = FlxMath.lerp(x, (targetY * 20) + 90, 0.16);
		}

		super.update(elapsed);
	}

	override function destroy():Void
	{
		if (_typingTimer != null)
		{
			_typingTimer.cancel();
			_typingTimer = null;
		}

		onTypingComplete = null;
		super.destroy();
	}
}

// ---------------------------------------------------------------
//  AlphaCharacter
// ---------------------------------------------------------------

class AlphaCharacter extends FlxSprite
{
	public static final alphabet:String = "abcdefghijklmnopqrstuvwxyz";
	public static final numbers:String  = "1234567890";
	public static final symbols:String  = "|~#$%()*+-:;<=>@[]^_.,'!?&";

	public var row:Int = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		frames       = FlxAtlasFrames.fromSparrow('assets/images/alphabet.png', 'assets/images/alphabet.xml');
		antialiasing = true;
	}

	public static function isSupported(ch:String):Bool
	{
		var lower = ch.toLowerCase();
		return alphabet.contains(lower) || numbers.contains(ch) || symbols.contains(ch);
	}

	public function createBold(letter:String):Void
	{
		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createLetter(letter:String):Void
	{
		var letterCase:String = (letter.toLowerCase() == letter) ? "lowercase" : "capital";
		animation.addByPrefix(letter, letter + " " + letterCase, 24);
		animation.play(letter);
		updateHitbox();
		y  = (110 - height);
		y += row * Alphabet.LINE_HEIGHT;
	}

	public function createNumber(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createSymbol(letter:String):Void
	{
		switch (letter)
		{
			case '.':  animation.addByPrefix(letter, 'period',            24); animation.play(letter); y += 50;
			case "'":  animation.addByPrefix(letter, 'apostraphie',       24); animation.play(letter);
			case '?':  animation.addByPrefix(letter, 'question mark',     24); animation.play(letter);
			case '!':  animation.addByPrefix(letter, 'exclamation point', 24); animation.play(letter);
			case '&':  animation.addByPrefix(letter, 'ampersand',         24); animation.play(letter);
			case ',':  animation.addByPrefix(letter, 'comma',             24); animation.play(letter); y += 40;
			case '-':  animation.addByPrefix(letter, 'dash',              24); animation.play(letter);
			default:   animation.addByPrefix(letter, letter,              24); animation.play(letter);
		}

		updateHitbox();
	}
}
