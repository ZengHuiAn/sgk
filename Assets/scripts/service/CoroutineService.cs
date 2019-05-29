using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using XLua;
using XLua.LuaDLL;

namespace SGK
{
    [LuaCallCSharp]
    public class CoroutineService : MonoBehaviour, IService {
        static CoroutineService _instance;

        void YieldAndCallback_(object to_yield, System.Action callback)
        {
            StartCoroutine (CoBody (to_yield, callback));
        }

        IEnumerator CoBody (object to_yield, System.Action callback)
        {
            if (to_yield is IEnumerator)
                yield return StartCoroutine ((IEnumerator)to_yield);
            else
                yield return to_yield;
            callback ();
            callback = null;
        }

        public void Register (LuaEnv xL)
        {
            _instance = this;
        }

        List<System.Action> repeat_scheduler_list = new List<System.Action>();

        // scheduler
        // List<System.Action<float>> scheduler_list = new List<System.Action<float>>();
        void Schedule_(System.Action func) {
            repeat_scheduler_list.Add(func);
        }

        void ScheduleOnce_(System.Action func, float delay) {
            if (delay <= 0) {
                YieldAndCallback_(new WaitForEndOfFrame(), func);
            } else {
                YieldAndCallback_(new WaitForSeconds(delay), func);
            }
        }

        void Update() {
            IEnumerator<System.Action> ite = repeat_scheduler_list.GetEnumerator();
            while (ite.MoveNext()) {
                ite.Current();
            }
        }

        // lua insterface 
        public static void YieldAndCallback(object to_yield, System.Action callback) {
            if (_instance == null) {
                Debug.LogError("CoroutineService instance is null");
                return;
            }

            _instance.YieldAndCallback_(to_yield, callback);
        }

        public static void Schedule(System.Action func) {
            if (_instance == null) {
                Debug.LogError("CoroutineService instance is null");
                return;
            }
            _instance.Schedule_(func);
        }

        public static void ScheduleOnce(System.Action func, float delay) {
            if (_instance == null) {
                Debug.LogError("CoroutineService instance is null");
                return;
            }
            _instance.ScheduleOnce_(func, delay);
        }

        public static void CancelAllRepeatSchedule() {
            if (_instance != null) {
                _instance.repeat_scheduler_list.Clear();
            }
        }

        public void Dispose() {
            CancelAllRepeatSchedule();
        }

        private void OnDestroy() {
            Dispose();
        }
    }

    public static class CoroutineServiceConfig
    {
        [LuaCallCSharp]
        public static List<Type> LuaCallCSharp {
            get {
                return new List<Type> () {
                    typeof(WaitForSeconds),
                    typeof(WWW),
                    typeof(WWWForm),
                    typeof(WaitForEndOfFrame),
                };
            }
        }
    }

}
