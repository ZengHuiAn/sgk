using DG.Tweening;

namespace SGK
{
    namespace Action
    {
        [XLua.LuaCallCSharp]
        public static class DelayTime {            
            public static Tween Create(float delay) {
                float a = 0;
                return DOTween.To (() => a, x => a = x, 1, delay); 
            }
        }
    }
}
