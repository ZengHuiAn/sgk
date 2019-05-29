/*
 * Tencent is pleased to support the open source community by making xLua available.
 * Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace XLua
{
#if true
    using ObjectReference = WeakReference;
#else
    class ObjectReference
    {
        private object reference;
        public object Target { get { return reference; } }
        public ObjectReference(object obj) { reference = obj; }
    }
#endif

    public class ObjectPool
    {
        const int LIST_END = -1;
        const int ALLOCED = -2;
        struct Slot
        {
            public int next;

            public ObjectReference obj;

            public Slot(int next, object obj)
            {
                this.next = next;
                this.obj = new ObjectReference(obj);
            }
        }

        private Slot[] list = new Slot[512];
        private int freelist = LIST_END;
        private int count = 0;

        public object this[int i]
        {
            get
            {
                if (i >= 0 && i < count)
                {
                    return list[i].obj.Target;
                }

                return null;
            }
        }

        public void Clear()
        {
            freelist = LIST_END;
            count = 0;
            list = new Slot[512];
        }

        void extend_capacity()
        {
            Slot[] new_list = new Slot[list.Length * 2];
            for (int i = 0; i < list.Length; i++)
            {
                new_list[i] = list[i];
            }
            list = new_list;
        }


        static ObjectPool _instance = null;
        public int Add(object obj)
        {
            _instance = this;

            int index = LIST_END;

            if (freelist != LIST_END)
            {
                index = freelist;
                list[index].obj = new ObjectReference(obj);
                freelist = list[index].next;
                list[index].next = ALLOCED;
            }
            else
            {
                if (count == list.Length)
                {
                    extend_capacity();
                }
                index = count;
                list[index] = new Slot(ALLOCED, obj);
                count = index + 1;
            }

            return index;
        }

        public bool TryGetValue(int index, out object obj)
        {
            if (index >= 0 && index < count && list[index].next == ALLOCED)
            {
                obj = list[index].obj.Target;
                return true;
            }

            obj = null;
            return false;
        }

        public object Get(int index)
        {
            if (index >= 0 && index < count)
            {
                return list[index].obj.Target;
            }
            return null;
        }

        public object Remove(int index)
        {
            if (index >= 0 && index < count && list[index].next == ALLOCED)
            {
                object o = list[index].obj.Target;
                list[index].obj = null;
                list[index].next = freelist;
                freelist = index;
                return o;
            }

            return null;
        }

        public object Replace(int index, object o)
        {
            if (index >= 0 && index < count)
            {
                object obj = list[index].obj.Target;
                list[index].obj = new ObjectReference(o);
                return obj;
            }

            return null;
        }

        public int Check(int check_pos, int max_check, Func<object, bool> checker, Dictionary<object, int> reverse_map)
        {
            if (count == 0)
            {
                return 0;
            }
            for (int i = 0; i < Math.Min(max_check, count); ++i)
            {
                check_pos %= count;
                if (list[check_pos].next == ALLOCED && !Object.ReferenceEquals(list[check_pos].obj.Target, null))
                {
                    if (!checker(list[check_pos].obj.Target))
                    {
                        object obj = Replace(check_pos, null);
                        int obj_index;
                        if (reverse_map.TryGetValue(obj, out obj_index) && obj_index == check_pos)
                        {
                            reverse_map.Remove(obj);
                        }
                    }
                }
                ++check_pos;
            }

            return check_pos %= count;
        }

        public static void DUMP() {
            for (int i = 0; i < _instance.list.Length; i++) {
                if (_instance.list[i].obj == null) {
                    continue;
                }

                object obj = _instance.list[i].obj.Target;
                if (obj == null) {
                    continue;
                }

                if ("null".Equals(obj.ToString())) {
                    continue;
                }

                Type t = obj.GetType();
                if (t.IsAssignableFrom(typeof(UnityEngine.Component))) {
                    UnityEngine.Component com = (UnityEngine.Component)obj;
                    UnityEngine.Debug.LogFormat("{2}: {0}@{1}", com, com.gameObject ? com.gameObject.name : "-", obj.GetType());
                } else if (t.IsAssignableFrom(typeof(UnityEngine.MonoBehaviour))) {
                    UnityEngine.MonoBehaviour com = (UnityEngine.MonoBehaviour)obj;
                    UnityEngine.Debug.LogFormat("{2}: {0}@{1}", com, com.gameObject ? com.gameObject.name : "-", obj.GetType());
                } else { 
                    UnityEngine.Debug.LogFormat("{1}: {0}", obj, obj.GetType());
                }
            }
        }
    }
}