using XLua;

namespace SGK {
    public interface IService {
        void Register(LuaEnv luaState);
        void Dispose();
    }
}