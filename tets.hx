package mobile.objects;

import flixel.input.FlxInput;
import flixel.input.FlxPointer;
import flixel.input.IFlxInput;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import mobile.backend.TouchFunctions;

/**
 * A simple button class that calls a function when clicked by the touch.
 */
class TouchButton extends TypedTouchButton<FlxSprite>
{
	/**
	 * Used with public variable status, means not highlighted or pressed.
	 */
	public static inline var NORMAL:Int = 0;

	/**
	 * Used with public variable status, means highlighted (usually from touch over).
	 */
	public static inline var HIGHLIGHT:Int = 1;

	/**
	 * Used with public variable status, means pressed (usually from touch click).
	 */
	public static inline var PRESSED:Int = 2;

	/**
	 * A simple tag that returns the button's graphic name in upper case.
	**/
	public var tag:String;
	/**
	 * The `FlxMobileInputID` that are assigned to this button.
	**/
	public var IDs:Array<FlxMobileInputID> = [];
	/**
	 * A Small invisible bounds used for colision
	**/
	public var bounds:FlxSprite = new FlxSprite();

	/**
	 * Creates a new `TouchButton` object
	 * and a callback function on the UI thread.
	 *
	 * @param   X         The x position of the button.
	 * @param   Y         The y position of the button.
	 * @param   IDs        The button's IDs(used for input handling so be careful).
	 */
	public function new(X:Float = 0, Y:Float = 0, ?IDs:Array<FlxMobileInputID> = null):Void
	{
		super(X, Y);

		this.IDs = IDs == null ? [] : IDs;
	}

	public inline function centerInBounds()
	{
		setPosition(bounds.x + ((bounds.width - frameWidth) / 2), bounds.y + ((bounds.height - frameHeight) / 2));
	}

	public inline function centerBounds()
	{
		bounds.setPosition(x + ((frameWidth - bounds.width) / 2), y + ((frameHeight - bounds.height) / 2));
	}
}

/**
 * A simple button class that calls a function when clicked by the touch.
 */
#if !display
@:generic
#end
class TypedTouchButton<T:FlxSprite> extends FlxSprite implements IFlxInput
{
	/**
	 * The label that appears on the button. Can be any `FlxSprite`.
	 */
	public var label(default, set):T;

	/**
	 * Whether you can press the button simply by releasing the touch button over it (default).
	 * If false, the input has to be pressed while hovering over the button.
	 */
	public var allowSwiping:Bool = true;

	/**
	 * Whether the button can use multiple fingers on it.
	 */
	public var multiTouch:Bool = false;

	/**
	 * Maximum distance a pointer can move to still trigger event handlers.
	 * If it moves beyond this limit, onOut is triggered.
	 * Defaults to `Math.POSITIVE_INFINITY` (i.e. no limit).
	 */
	public var maxInputMovement:Float = Math.POSITIVE_INFINITY;

	/**
	 * The properties of this button's `onUp` event (callback function, sound).
	 */
	public var onUp(default, null):TouchButtonEvent;

	/**
	 * The properties of this button's `onDown` event (callback function, sound).
	 */
	public var onDown(default, null):TouchButtonEvent;

	/**
	 * The properties of this button's `onOver` event (callback function, sound).
	 */
	public var onOver(default, null):TouchButtonEvent;

	/**
	 * The properties of this button's `onOut` event (callback function, sound).
	 */
	public var onOut(default, null):TouchButtonEvent;
    
    /**
	 * Shows the current state of the button, either `TouchButton.NORMAL`,
	 * `TouchButton.HIGHLIGHT` or `TouchButton.PRESSED`.
	 */
	public var status(default, set):Int;

	/**
	 * The alpha's the button should use depednging on the status.
	**/
	public var statusAlphas:Array<Float> = [1.0, 1.0, 0.7];

	/**
	 * How many alpha to add/substract from the current alpha for the label.
	**/
	public var labelAlphaDiff:Float = 0.05;

	/**
	 * If the button and label should change alpha according to the status.
	**/
	public var dynamicAlpha:Bool = true;

	public var justReleased(get, never):Bool;
	public var released(get, never):Bool;
	public var pressed(get, never):Bool;
	public var justPressed(get, never):Bool;

	/**
	 * We cast label to a `FlxSprite` for internal operations to avoid Dynamic casts in C++
	 */
	var _spriteLabel:FlxSprite;

	/** 
	 * We don't need an ID here, so let's just use `Int` as the type.
	 */
	var input:FlxInput<Int>;

	/**
	 * The input currently pressing this button, if none, it's `null`. Needed to check for its release.
	 */
	var currentInput:IFlxInput;

	/**
	 * Creates a new `FlxTypedButton` object with a gray background.
	 *
	 * @param   X         The x position of the button.
	 * @param   Y         The y position of the button.
	 */
	public function new(X:Float = 0, Y:Float = 0):Void
	{
		super(X, Y);

		onUp = new TouchButtonEvent();
		onDown = new TouchButtonEvent();
		onOver = new TouchButtonEvent();
		onOut = new TouchButtonEvent();

		// Since this is a UI element, the default scrollFactor is (0, 0)
		scrollFactor.set();

		input = new FlxInput(0);
	}

	/**
	 * Called by the game state when state is changed (if this object belongs to the state)
	 */
	override public function destroy():Void
	{
		label = FlxDestroyUtil.destroy(label);
		_spriteLabel = null;

		onUp = FlxDestroyUtil.destroy(onUp);
		onDown = FlxDestroyUtil.destroy(onDown);
		onOver = FlxDestroyUtil.destroy(onOver);
		onOut = FlxDestroyUtil.destroy(onOut);

		currentInput = null;
		input = null;

		super.destroy();
	}

	/**
	 * Called by the game loop automatically, handles touch over and click detection.
	 */
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (visible)
		{
			// Update the button, but only if at least either touches are enabled
			#if FLX_POINTER_INPUT
			updateButton();
			#end
		}

		input.update();
	}

	/**
	 * Just draws the button graphic and text label to the screen.
	 */
	override public function draw():Void
	{
		super.draw();

		if (_spriteLabel != null && _spriteLabel.graphic != null && _spriteLabel.pixels != null && _spriteLabel.visible)
		{
            if(_spriteLabel.cameras != cameras)
    			_spriteLabel.cameras = cameras;
			_spriteLabel.draw();
		}
	}

	#if FLX_DEBUG
	/**
	 * Helper function to draw the debug graphic for the label as well.
	 */
	override public function drawDebug():Void
	{
		super.drawDebug();

		if (_spriteLabel != null)
			_spriteLabel.drawDebug();
	}
	#end

	/**
	 * Basic button update logic - searches for overlaps with touches and
	 * the touch and calls `updateStatus()`.
	 */
	function updateButton():Void
	{
		var overlapFound = checkTouchOverlap();

		if (currentInput != null && currentInput.justReleased && overlapFound)
			onUpHandler();

		if (status != TouchButton.NORMAL && (!overlapFound || (currentInput != null && currentInput.justReleased)))
			onOutHandler();
	}

	function checkTouchOverlap():Bool
	{
		var overlap = false;

		for (camera in cameras){
            for(touch in FlxG.touches.list)
				if (checkInput(touch, touch, touch.justPressedPosition, camera))
					overlap = true;
        }
		return overlap;
	}

	function checkInput(pointer:FlxPointer, input:IFlxInput, justPressedPosition:FlxPoint, camera:FlxCamera):Bool
	{
		if (maxInputMovement != Math.POSITIVE_INFINITY
			&& justPressedPosition.distanceTo(pointer.getScreenPosition(FlxPoint.weak())) > maxInputMovement
			&& input == currentInput)
		{
			currentInput = null;
		}
		else if (overlapsPoint(pointer.getWorldPosition(camera, _point), true, camera))
		{
			updateStatus(input);
			return true;
		}

		return false;
	}

	/**
	 * Updates the button status by calling the respective event handler function.
	 */
	function updateStatus(input:IFlxInput):Void
	{
		if (input.justPressed)
		{
			currentInput = input;
			onDownHandler();
		}
		else if (status == TouchButton.NORMAL)
		{
			// Allow 'swiping' to press a button (dragging it over the button while pressed)
			if (allowSwiping && input.pressed)
				onDownHandler();
			else
				onOverHandler();
		}
	}

	function updateLabelPosition()
	{
		if (_spriteLabel != null)
		{
			_spriteLabel.x = ((width - _spriteLabel.width) / 2) + (pixelPerfectPosition ? Math.floor(x) : x);
			_spriteLabel.y = ((height - _spriteLabel.height) / 2) + (pixelPerfectPosition ? Math.floor(y) : y);
		}
	}

	function updateLabelScale()
	{
		if (_spriteLabel != null)
			_spriteLabel.scale.set(scale.x, scale.y);
	}

	function updateAlpha()
	{
		if (statusAlphas.length > status && dynamicAlpha)
			alpha = statusAlphas[status];
	}

	/**
	 * Internal function that handles the onUp event.
	 */
	function onUpHandler():Void
	{
		status = TouchButton.NORMAL;
		input.release();
		currentInput = null;
		onUp.fire(); // Order matters here, because onUp.fire() could cause a state change and destroy this object.
	}

	/**
	 * Internal function that handles the onDown event.
	 */
	function onDownHandler():Void
	{
		status = TouchButton.PRESSED;
		input.press();
		onDown.fire(); // Order matters here, because onDown.fire() could cause a state change and destroy this object.
	}

	/**
	 * Internal function that handles the onOver event.
	 */
	function onOverHandler():Void
	{
		status = TouchButton.HIGHLIGHT;
		onOver.fire(); // Order matters here, because onOver.fire() could cause a state change and destroy this object.
	}

	/**
	 * Internal function that handles the onOut event.
	 */
	function onOutHandler():Void
	{
		status = TouchButton.NORMAL;
		input.release();
		onOut.fire(); // Order matters here, because onOut.fire() could cause a state change and destroy this object.
	}

	function set_label(Value:T):T
	{
		if (Value != null)
		{
			// use the same FlxPoint object for both
			Value.scrollFactor.put();
			Value.scrollFactor = scrollFactor;
		}

		label = Value;
		_spriteLabel = label;

		updateLabelPosition();

		return Value;
	}

	function set_status(Value:Int):Int
	{
		status = Value;
		updateAlpha();
		return status;
	}

	override function set_alpha(Value:Float):Float
	{
		super.set_alpha(Value);
		if(_spriteLabel != null && dynamicAlpha)
			_spriteLabel.alpha = alpha == 0 ? 0 : alpha + labelAlphaDiff;
		return alpha;
	}


	override function set_x(Value:Float):Float
	{
		super.set_x(Value);
		updateLabelPosition();
		return x;
	}

	override function set_y(Value:Float):Float
	{
		super.set_y(Value);
		updateLabelPosition();
		return y;
	}

	override function set_color(Value:FlxColor):Int
	{
		if(_spriteLabel != null)
			_spriteLabel.color = Value;
		Value.brightness += 0.12;
		super.set_color(Value);
		return Value;
	}

	override private function set_width(Value:Float)
	{
		super.set_width(Value);
		updateLabelScale();
		return Value;
	}

	override private function set_height(Value:Float)
	{
		super.set_height(Value);
		updateLabelScale();
		return Value;
	}

	override public function updateHitbox()
	{
		super.updateHitbox();
		if(_spriteLabel != null)
			_spriteLabel.updateHitbox();
	}

	inline function get_justReleased():Bool
		return input.justReleased;

	inline function get_released():Bool
		return input.released;

	inline function get_pressed():Bool
		return input.pressed;

	inline function get_justPressed():Bool
		return input.justPressed;
}

/** 
 * Helper function for `TouchButton` which handles its events.
 */
private class TouchButtonEvent implements IFlxDestroyable
{
	/**
	 * The callback function to call when this even fires.
	 */
	public var callback:Void->Void;

	#if FLX_SOUND_SYSTEM
	/**
	 * The sound to play when this event fires.
	 */
	public var sound:FlxSound;
	#end

	/**
	 * @param   Callback   The callback function to call when this even fires.
	 * @param   sound      The sound to play when this event fires.
	 */
	public function new(?Callback:Void->Void, ?sound:FlxSound):Void
	{
		callback = Callback;

		#if FLX_SOUND_SYSTEM
		this.sound = sound;
		#end
	}

	/**
	 * Cleans up memory.
	 */
	public inline function destroy():Void
	{
		callback = null;

		#if FLX_SOUND_SYSTEM
		sound = FlxDestroyUtil.destroy(sound);
		#end
	}

	/**
	 * Fires this event (calls the callback and plays the sound)
	 */
	public inline function fire():Void
	{
		if (callback != null)
			callback();

		#if FLX_SOUND_SYSTEM
		if (sound != null)
			sound.play(true);
		#end
	}
}
