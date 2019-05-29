using UnityEngine;
using XLua;

namespace SGK {
    public class NetworkService : MonoBehaviour, IService {
		public void Register(LuaEnv luaState) {
            luaState.AddBuildin ("network", XLua.LuaDLL.Lua.LoadNetwork);
            luaState.AddBuildin ("VM", XLua.LuaDLL.Lua.LoadVM);
			luaState.AddBuildin ("WordFilter", XLua.LuaDLL.Lua.LoadWordFilter);
			luaState.AddBuildin ("protobuf.c", XLua.LuaDLL.Lua.LoadProtobuf);
            luaState.AddBuildin ("WELLRNG512a", XLua.LuaDLL.Lua.LoadWELLRNG512a);
        }

        public void Dispose() {

        }
    }
}