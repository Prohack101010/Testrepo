package psychlua;

class CallbackHandler
{
	public static inline function callback_handler(l:State, fname:String):Int {

		var cbf = callbacks.get(fname);

		if(cbf == null) {
			return 0;
		}

		var nparams:Int = Lua.gettop(l);
		var args:Array<Dynamic> = [];

		for (i in 0...nparams) {
			args[i] = Convert.fromLua(l, i + 1);
		}

		var ret:Dynamic = Reflect.callMethod(null, cbf, args);

		if(ret != null){
			Convert.toLua(l, ret);
		}

		/* return the number of results */
		return 1;

	} //callback_handler
}
