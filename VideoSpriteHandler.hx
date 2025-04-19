import vlc.MP4Handler;
import psychlua.LuaUtils;

var global:Array<{sprite:FlxSprite, video:MP4Handler}> = [];

var playedVideoName:String = null;

var globalTag:String = null;

function makeVideoSprite(tag:String, videoPath:String, x:Float, y:Float, camera:String, ?scaleX:Float, ?scaleY:Float)
{
	if (playedVideoName != tag) { //fix double video issue
		playedVideoName = tag;

		var local:{sprite:FlxSprite, video:MP4Handler} =
		{
			sprite: null,

			video: null,
		};

		globalTag = tag;

		var sprite:FlxSprite = new FlxSprite();

		sprite.camera = LuaUtils.cameraFromString(camera);

		sprite.setPosition(x, y);

		game.modchartSprites[tag] = sprite;

		local.sprite = sprite;

		game.add(sprite);

		if (scaleX != null && scaleY != null) sprite.scale.set(scaleX, scaleY);

		setSubStateVar("paused", false);

		var video:MP4Handler = new MP4Handler();

		video.alpha = 0.0;

		video.canSkip = false;
		if (!video.canSkip) setSubStateVar("canSkip", true); //Pause Menu

		video.finishCallback = function()
		{
			//game.startAndEnd();
			setSubStateVar("paused", false);
			setSubStateVar("canSkip", false);
			sprite.destroy();
			game.callOnLuas('onVideoFinished', [tag]); //NOTE: That was added by someone.
			return;
		}

		local.video = video;

		video.playVideo(Paths.video(tag));
	
		global.push(local);
		//trace('bro the video has been started!');
	}
}

function onUpdate(elapsed:Float):Void
{
	if (!getSubStateVar("paused") && getSubStateVar("canSkip"))
	{
		if (FlxG.android.justReleased.BACK) {
			game.openPauseMenu();
			setSubStateVar("paused", true);
		}
	}

	for (i in 0 ... global.length)
	{
		var local:{sprite:FlxSprite, video:MP4Handler} = global[i];

		if (local.video.bitmapData != null)
		{
			local.sprite.loadGraphic(local.video.bitmapData);
		}
	}
}

function pauseVideo():Void
{
	for (i in 0 ... global.length)
	{
		var local:{sprite:FlxSprite, video:MP4Handler} = global[i];

		local.video.pause();
			
		if (FlxG.autoPause)
		{
			if (FlxG.signals.focusGained.has(local.video.resume))
			{
				FlxG.signals.focusGained.remove(local.video.resume);
			}

			if (FlxG.signals.focusLost.has(local.video.pause))
			{
				FlxG.signals.focusLost.remove(local.video.pause);
			}
		}
	}
}

function resumeVideo():Void
{
	for (i in 0 ... global.length)
	{
		var local:{sprite:FlxSprite, video:MP4Handler} = global[i];

		local.video.resume();

		if (FlxG.autoPause)
		{
			if (!FlxG.signals.focusGained.has(local.video.resume))
			{
				FlxG.signals.focusGained.add(local.video.resume);
			}

			if (!FlxG.signals.focusLost.has(local.video.pause))
			{
				FlxG.signals.focusLost.add(local.video.pause);
			}
		}
	}
}

function finishVideo():Void
{
	for (i in 0 ... global.length)
	{
		var local:{sprite:FlxSprite, video:MP4Handler} = global[i];

		//local.video.stop();
		local.video.dispose();
		game.inCutscene = false;
		
		local.sprite.destroy();
		game.callOnLuas('onVideoFinished', [globalTag]); //NOTE: That was added by someone.
	}
}

function onDestroy():Void
{
	while (global.length > 0.0)
	{
		global[0].video.dispose();

		global.shift();
	}
}

createGlobalCallback('makeVideoSprite', makeVideoSprite);
createGlobalCallback('resumeVideo', resumeVideo);
createGlobalCallback('pauseVideo', pauseVideo);
createGlobalCallback('finishVideo', finishVideo);
