package mobile;

#if mobile
import lime.system.System as LimeSystem;
import openfl.Assets;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;

class Storage
{
	#if android
	public static final externalDirectory:String = LimeSystem.applicationStorageDirectory;
	#elseif ios
	public static final externalDirectory:String = LimeSystem.documentsDirectory;
	#else
	public static final externalDirectory:String = "./";
	#end

	static final VERSION_FILE:String = "extracted.version";

	static final MANAGED_DIRS:Array<String> = [
		"assets/images",
		"assets/data",
		"assets/music",
		"assets/sounds",
		"assets/fonts",
		"mods",
	];

	public static function init():Void
	{
		ensureDirectory(externalDirectory);

		for (dir in MANAGED_DIRS)
			ensureDirectory(externalDirectory + dir);
	}

	public static function path(relativePath:String):String
	{
		return externalDirectory + relativePath;
	}

	public static function exists(relativePath:String):Bool
	{
		return FileSystem.exists(path(relativePath));
	}

	public static function extractAssets(appVersion:String, force:Bool = false, ?onProgress:Int->Int->String->Void):Void
	{
		var versionPath = path(VERSION_FILE);

		if (!force && FileSystem.exists(versionPath))
		{
			var storedVersion = StringTools.trim(File.getContent(versionPath));
			if (storedVersion == appVersion)
				return;
		}

		var assetList:Array<String> = Assets.list();
		var total:Int  = assetList.length;
		var current:Int = 0;

		for (asset in assetList)
		{
			current++;

			var destPath = path(asset);
			var destDir  = Path.directory(destPath);

			ensureDirectory(destDir);

			if (!force && FileSystem.exists(destPath))
			{
				if (onProgress != null)
					onProgress(current, total, asset);
				continue;
			}

			try
			{
				var bytes = Assets.getBytes(asset);
				if (bytes != null)
					File.saveBytes(destPath, bytes);
			}
			catch (e:Dynamic) {}

			if (onProgress != null)
				onProgress(current, total, asset);
		}

		File.saveContent(versionPath, appVersion);
	}

	public static function saveContent(relativePath:String, content:String):Void
	{
		var fullPath = path(relativePath);
		ensureDirectory(Path.directory(fullPath));
		File.saveContent(fullPath, content);
	}

	public static function saveBytes(relativePath:String, bytes:haxe.io.Bytes):Void
	{
		var fullPath = path(relativePath);
		ensureDirectory(Path.directory(fullPath));
		File.saveBytes(fullPath, bytes);
	}

	public static function getContent(relativePath:String):Null<String>
	{
		var fullPath = path(relativePath);
		if (!FileSystem.exists(fullPath))
			return null;
		return File.getContent(fullPath);
	}

	public static function getBytes(relativePath:String):Null<haxe.io.Bytes>
	{
		var fullPath = path(relativePath);
		if (!FileSystem.exists(fullPath))
			return null;
		return File.getBytes(fullPath);
	}

	public static function deleteFile(relativePath:String):Bool
	{
		var fullPath = path(relativePath);
		if (!FileSystem.exists(fullPath))
			return false;

		try
		{
			FileSystem.deleteFile(fullPath);
			return true;
		}
		catch (e:Dynamic)
		{
			return false;
		}
	}

	public static function listDirectory(relativePath:String):Array<String>
	{
		var fullPath = path(relativePath);
		if (!FileSystem.exists(fullPath) || !FileSystem.isDirectory(fullPath))
			return [];
		return FileSystem.readDirectory(fullPath);
	}

	private static function ensureDirectory(fullPath:String):Void
	{
		if (fullPath == null || fullPath == "" || FileSystem.exists(fullPath))
			return;

		var parts = fullPath.replace("\\", "/").split("/");
		var built = "";

		for (part in parts)
		{
			if (part == "")
			{
				built += "/";
				continue;
			}

			built += (built == "" || built == "/") ? part : "/" + part;

			if (!FileSystem.exists(built))
			{
				try { FileSystem.createDirectory(built); }
				catch (e:Dynamic) {}
			}
		}
	}
}
#end
  
