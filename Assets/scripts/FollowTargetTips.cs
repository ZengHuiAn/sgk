using System.Collections.Generic;
using UnityEngine;
using XLua;

namespace SGK
{
    public class FollowTargetTips : MonoBehaviour
    {
        public GameObject player;
        public struct TargetTip
        {
            public GameObject tip;
            public GameObject target;
            public GameObject arrow;
        }
        Dictionary<long, TargetTip> followTargets = new Dictionary<long, TargetTip>();
        public void Init(GameObject obj)
        {
            player = obj;
        }
        public void Add(long id, LuaTable t)
        {
            TargetTip targetTip;
            if (followTargets.TryGetValue(id, out targetTip))
            {
                Debug.Log("target id already exist");
                return;
            }
            targetTip.tip = t.Get<GameObject>("tip");
            targetTip.target = t.Get<GameObject>("target");
            targetTip.arrow = t.Get<GameObject>("arrow");
            followTargets[id] = targetTip;
        }

        public void Remove(long id)
        {
            TargetTip targetTip;
            if (!followTargets.TryGetValue(id, out targetTip))
            {
                return;
            }
            followTargets.Remove(id);
        }
        public void Clear()
        {
            followTargets.Clear();
        }
        void Update()
        {
            if (player == null)
            {
                return;
            }
            foreach (var targetTip in followTargets)
            {
                if (targetTip.Value.target != null & targetTip.Value.tip != null)
                {
                    //是否可见

                    Vector3 posViewport = UnityEngine.Camera.main.WorldToViewportPoint(targetTip.Value.target.transform.position);
                    var _rect = new UnityEngine.Rect(0, 0, 1, 1);
                    bool _visible = _rect.Contains(posViewport);
                    targetTip.Value.tip.SetActive(!_visible);

                    float _x = targetTip.Value.target.transform.position.x - player.transform.position.x;
                    float _y = targetTip.Value.target.transform.position.z - player.transform.position.z;

                    //arrow旋转
                    float a = UnityEngine.Mathf.Atan2(_y, _x) * UnityEngine.Mathf.Rad2Deg;
                    targetTip.Value.arrow.transform.localRotation = Quaternion.Euler(0, 0, a - 90);

                    //更新位置
                    float _off_x = UnityEngine.Screen.width / 2 - targetTip.Value.tip.GetComponent<UnityEngine.RectTransform>().sizeDelta.x / 2;
                    float _off_y = UnityEngine.Screen.height / 2 - targetTip.Value.tip.GetComponent<UnityEngine.RectTransform>().sizeDelta.y / 2;
                    float delta_x = 1;
                    float delta_y = 1;
                    if (_x < 0)
                    {
                        delta_x = -1; 
                    }
                    if (_y >= 0)
                    {
                        //_off_y = _off_y - 115;//减去上下资源条宽度
                    }
                    else
                    {
                        //_off_y = _off_y - 150;
                        delta_y = -1;
                    }

                    float limit = Mathf.Atan2(_off_y, _off_x) * Mathf.Rad2Deg;
                    float _a = Vector3.Angle(new Vector3(_x, _y, 0), new Vector3(delta_x *1, 0, 0));
                    if (_a < limit)
                    {
                        float offset = Mathf.Tan(Mathf.Deg2Rad * _a) * _off_x;
                        targetTip.Value.tip.transform.localPosition = new Vector3(delta_x * _off_x, delta_y * offset, 0);

                    }
                    else if (_a > limit)
                    {
                        float offset = Mathf.Tan(Mathf.Deg2Rad * (90 - _a)) * _off_y;
                        targetTip.Value.tip.transform.localPosition = new Vector3(delta_x * offset, delta_y * _off_y, 0);
                    }
                    else
                    {
                        targetTip.Value.tip.transform.localPosition = new Vector3(delta_x * _off_x, delta_y * _off_y, 0);
                    }
                }
            }
        }
    }
}
