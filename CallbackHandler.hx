package psychlua;

class CallbackHandler
{
	public static inline function call(l:State, fname:String):Int
	{
		//trace('calling $fname');
		var cbf:Dynamic = Lua_helper.callbacks.get(fname);

		//Local functions have the lowest priority
		//This is to prevent a "for" loop being called in every single operation,
		//so that it only loops on reserved/special functions
		if(cbf == null) 
		{
			//trace('looping thru scripts');
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua == l)
				{
					//trace('found script');
					cbf = script.callbacks.get(fname);
					break;
				}
		}
			
		if(cbf == null) return 0;

		var nparams:Int = Lua.gettop(l);
		var args:Array<Dynamic> = [];

		for (i in 0...nparams) {
			args[i] = Convert.fromLua(l, i + 1);
		}

        /* this code doesn't work because I'm using Sirox's linc_luajit
		var ret:Dynamic = null;

		ret = Reflect.callMethod(null,cbf,args);
		*/
		var ret:Dynamic = Reflect.callMethod(null, cbf, args);

		if(ret != null){
			Convert.toLua(l, ret);
		}
		return 1;
	}
}
