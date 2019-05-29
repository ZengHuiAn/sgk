using UnityEngine;
using UnityEngine.AI;
using System.Collections.Generic;
using System.Collections;
using System;

namespace SGK
{
    public class MapWayMoveController : MonoBehaviour
    {
        public delegate void Delegate(GameObject go);
        public float setY;
        public WayInfo[] waypoints;
        //public PointInfo[] points;
        [System.Serializable]
        public struct WayInfo
        {
            public string name;
            public Vector3[] positions;
            public Color color;
            public int direction;
            public string callbackName;
            public RepeatType repeatType;
            public bool visiable;
        }

        //[System.Serializable]
        //public struct PointInfo
        //{
        //    public Vector3 position;
        //    public Color color;
        //    public string pointName;
        //    public int direction;
        //    public string callbackName;
        //}
        public enum RepeatType
        {
            None = 0,
            Yoyo = 1,
            Loop = 2,
        }
        public class Character
        {
            public GameObject obj;
            public MapPlayer player;
            public NavMeshAgent agent;
            public bool pause;
            public bool moving;
            public WayInfo wayInfo;
            public int target;
            public float process;
            public Character(GameObject _obj)
            {
                obj = _obj;
                player = obj.GetComponent<MapPlayer>();
                agent = obj.GetComponent<NavMeshAgent>();
                pause = false;
                moving = false;
                target = 0;
                process = 0;
            }
        };

        [SerializeField]
        Dictionary<long, Character> characters = new Dictionary<long, Character>();
        Dictionary<string, Delegate> callbacks = new Dictionary<string, Delegate>();
        Dictionary<string, WayInfo> wayInfoByName = new Dictionary<string, WayInfo>();

        void Start()
        {
            for (int i = 0; i < waypoints.Length; i++)
            {
                wayInfoByName[waypoints[i].name] = waypoints[i];
            }
        }

        void Update()
        {
            foreach (var character in characters)
            {
                if (character.Value.moving && character.Value.agent != null && !character.Value.agent.pathPending && !character.Value.pause)
                {
                    //if (character.Value.agent.remainingDistance <= character.Value.agent.stoppingDistance)
                    if (character.Value.agent.remainingDistance <= character.Value.agent.stoppingDistance )
                    {
                        switch (character.Value.wayInfo.repeatType)
                        {
                            case RepeatType.None:
                                if (character.Value.target >= character.Value.wayInfo.positions.Length - 1)//是否到达终点
                                {
                                    character.Value.agent.isStopped = true;
                                    character.Value.moving = false;

                                    if (character.Value.wayInfo.direction != -1)
                                    {
                                        StartCoroutine(SetDirection(character.Value.player, character.Value.wayInfo.direction));
                                        //character.Value.player.SetDirection(character.Value.wayInfo.direction);
                                    }
                                    Delegate _callback;
                                    if (callbacks.TryGetValue(character.Value.wayInfo.callbackName, out _callback))//触发回调
                                    {
                                        _callback(character.Value.obj);
                                    }

                                    //if (character.Value.agent.isStopped)
                                    //{

                                    //}
                                }
                                else
                                {
                                    character.Value.target = character.Value.target + 1;
                                    character.Value.process = (float)character.Value.target / (float)(character.Value.wayInfo.positions.Length - 1);
                                    character.Value.agent.SetDestination(character.Value.wayInfo.positions[character.Value.target]);
                                    character.Value.agent.isStopped = false;
                                }
                                break;
                            case RepeatType.Yoyo:
                                character.Value.target = character.Value.target + 1;
                                int pos = 0;
                                // float idx = Mathf.Ceil((float)(character.Value.target + 1) / (float)(character.Value.wayInfo.positions.Length));
                                if (Mathf.Ceil((float)(character.Value.target + 1)/ (float)(character.Value.wayInfo.positions.Length))%2 == 1)
                                {
                                    pos = character.Value.target % character.Value.wayInfo.positions.Length;
                                }
                                else
                                {
                                    pos = character.Value.wayInfo.positions.Length - (character.Value.target % character.Value.wayInfo.positions.Length) - 1;
                                }
                                //Debug.Log("测试 "+ pos);
                                character.Value.agent.SetDestination(character.Value.wayInfo.positions[pos]);
                                break;
                            case RepeatType.Loop:
                                character.Value.target = (character.Value.target + 1) % character.Value.wayInfo.positions.Length;
                                character.Value.agent.SetDestination(character.Value.wayInfo.positions[character.Value.target]);
                                break;
                            default:
                                break;
                        }
                        
                    }
                }
            }
        }

        IEnumerator SetDirection(MapPlayer player, int direction)
        {
            yield return new WaitForSeconds(0.1f);
            player.SetDirection(direction);
        }

        void OnDrawGizmosSelected()
        {
            if (waypoints != null)
            {
                for (int i = 0; i < waypoints.Length; i++)
                {
                    if (waypoints[i].visiable)
                    {
                        Gizmos.color = waypoints[i].color;
                        for (int j = 0; j < waypoints[i].positions.Length; j++)
                        {

                            Vector3 from = waypoints[i].positions[j];
                            Gizmos.DrawCube(from, new Vector3(0.2f, 0.2f, 0.2f));
                            if (waypoints[i].repeatType != RepeatType.Loop && j == waypoints[i].positions.Length - 1)
                            {
                                break;
                            }
                            Vector3 to = (j == waypoints[i].positions.Length - 1) ? waypoints[i].positions[0] : waypoints[i].positions[j + 1];
                            Gizmos.DrawLine(from, to);
                        }
                    }
                }
            }
        }

        public Character Get(long id)
        {
            Character character;
            if (characters.TryGetValue(id, out character))
            {
                return character;
            }
            return null;
        }

        public GameObject Add(long id, GameObject prefab, Transform parent)
        {
            Character character;
            if (characters.TryGetValue(id, out character))
            {
                return character.obj;
            }
            GameObject obj = GameObject.Instantiate(prefab, parent);
            characters[id] = new Character(obj);
            characters[id].player.id = id;
            //obj.SetActive(true);
            return obj;
        }

        public GameObject Add(long id, GameObject obj)
        {
            Character character;
            if (characters.TryGetValue(id, out character))
            {
                return character.obj;
            }
            characters[id] = new Character(obj);
            characters[id].player.id = id;
            return obj;
        }

        public void Remove(long id)
        {
            Character character;
            if (!characters.TryGetValue(id, out character))
            {
                return;
            }

            characters.Remove(id);

            Destroy(character.obj);
        }

        public void Remove(long id, bool remove)
        {
            Character character;
            if (!characters.TryGetValue(id, out character))
            {
                return;
            }

            characters.Remove(id);

            if (remove)
            {
                Destroy(character.obj);
            }
        }

        public void AddCallback(string id, Delegate func)
        {
            callbacks[id] = func;
        }

        public void isStopped(long id, bool value)
        {
            Character character;
            if (characters.TryGetValue(id, out character))
            {
                if (character.agent != null)
                {
                    character.pause = value;
                    character.agent.isStopped = value;                   
                }
               
            }
        }

        public void StartMove(long id, string name,int taget_id)
        {
            WayInfo wayInfo;
            Character character;
            if (characters.TryGetValue(id, out character) && wayInfoByName.TryGetValue(name, out wayInfo))
            {
                if (character.agent != null)
                {
                    if (taget_id >= wayInfo.positions.Length)
                    {
                        return;
                    }
                    character.moving = true;
                    character.wayInfo = wayInfo;
                    character.target = taget_id;
                    character.agent.isStopped = false;
                    character.agent.SetDestination(wayInfo.positions[taget_id]);
                }
            }

        }

        public void StartMove(long id, int way_id,int taget_id)
        {
            Character character;
            if (characters.TryGetValue(id, out character) && way_id < waypoints.Length)
            {
                if (character.agent != null)
                {
                    if (taget_id >= waypoints[way_id].positions.Length)
                    {
                        Debug.Log("taget_id is overflow");
                        taget_id = 0;
                    }
                    character.moving = true;
                    character.wayInfo = waypoints[way_id];
                    character.target = taget_id;
                    character.agent.isStopped = false;
                    character.agent.SetDestination(waypoints[way_id].positions[taget_id]);
                }
            }
        }

        public void StartMainWayJourney(long id, string wayNanme, string fromName, string toName, int taget)
        {
            Character character;
            WayInfo fromWay;
            WayInfo toWay;
            WayInfo mainWay;
            if (characters.TryGetValue(id, out character) && wayInfoByName.TryGetValue(wayNanme, out mainWay) && wayInfoByName.TryGetValue(fromName, out fromWay) && wayInfoByName.TryGetValue(toName, out toWay))
            {
                WayInfo wayInfo = new WayInfo();
                wayInfo.direction = toWay.direction;
                wayInfo.callbackName = toWay.callbackName;
                wayInfo.repeatType = toWay.repeatType;

                Vector3 fromPos = fromWay.positions[fromWay.positions.Length - 1];
                Vector3 toPos = toWay.positions[0];
                int FN_index = 0;//fromPos_Nearest_index 离开始点最近的点的下标
                int TN_index = 0;//toPos_Nearest_index 离结束点最近的点的下标
                for (int i = 0; i < mainWay.positions.Length - 1; i++)
                {
                    if (Vector3.Distance(fromPos, mainWay.positions[i]) < Vector3.Distance(fromPos, mainWay.positions[i + 1]))
                    {
                        if (Vector3.Distance(fromPos, mainWay.positions[i]) < Vector3.Distance(fromPos, mainWay.positions[FN_index]))
                        {
                            FN_index = i;
                        }
                    }
                    else
                    {
                        if (Vector3.Distance(fromPos, mainWay.positions[i + 1]) < Vector3.Distance(fromPos, mainWay.positions[FN_index]))
                        {
                            FN_index = i + 1;
                        }
                    }
                    if (Vector3.Distance(toPos, mainWay.positions[i]) < Vector3.Distance(toPos, mainWay.positions[i + 1]))
                    {
                        if (Vector3.Distance(toPos, mainWay.positions[i]) < Vector3.Distance(toPos, mainWay.positions[TN_index]))
                        {
                            TN_index = i;
                        }
                    }
                    else
                    {
                        if (Vector3.Distance(toPos, mainWay.positions[i + 1]) < Vector3.Distance(toPos, mainWay.positions[TN_index]))
                        {
                            TN_index = i + 1;
                        }
                    }
                }
                Vector3[] wayPositions = new Vector3[Mathf.Abs(TN_index - FN_index) + fromWay.positions.Length + toWay.positions.Length + 1];
                
                for (int i = 0; i < fromWay.positions.Length; i++)
                {
                    wayPositions[i] = fromWay.positions[i];
                }
                int idx = fromWay.positions.Length;
                if (FN_index <= TN_index)
                {              
                    for (int i = FN_index; i <= TN_index; i++)
                    {
                        wayPositions[idx] = mainWay.positions[i];
                        idx = idx + 1;
                    }
                }
                else
                {
                    for (int i = FN_index; i >= TN_index; i--)
                    {
                        wayPositions[idx] = mainWay.positions[i];
                        idx = idx + 1;
                    }
                }
                for (int i = 0; i < toWay.positions.Length; i++)
                {
                    wayPositions[idx + i] = toWay.positions[i];
                }
                wayInfo.positions = wayPositions;
                
                if (character.agent != null)
                {
                    if (taget == -1)
                    {
                        int _min = Mathf.FloorToInt(wayInfo.positions.Length * 0.2f);
                        int _max = Mathf.CeilToInt(wayInfo.positions.Length * 0.8f);
                        taget = UnityEngine.Random.Range(_min, _max);
                    }
                    else if (taget >= wayInfo.positions.Length)
                    {
                        Debug.Log("taget is overflow");
                        taget = 0;
                    }

                    character.obj.transform.position = wayInfo.positions[taget];
                    character.moving = true;
                    character.wayInfo = wayInfo;
                    character.target = taget;
                    character.agent.isStopped = false;
                    character.agent.SetDestination(wayInfo.positions[taget]);
                }

            }
        }

        
        public Vector3 GetWayPosition(string name,int pos)
        {
            WayInfo wayInfo;
            if (wayInfoByName.TryGetValue(name, out wayInfo))
            {
                return wayInfo.positions[pos];
            }
            return Vector3.zero;
        }

#if UNITY_EDITOR
        [ContextMenu("SetY")]
        void SetY()
        {
            for (int i = 0; i < waypoints.Length; i++)
            {
                for (int j = 0; j < waypoints[i].positions.Length; j++)
                {
                    waypoints[i].positions[j].y = setY;
                }
            }
        }

        [ContextMenu("Create Point")]
        void CreatePoint()
        {
            for (int i = 0; i < waypoints.Length; i++)
            {
                if (waypoints[i].visiable)
                {
                    for (int j = 0; j < waypoints[i].positions.Length; j++)
                    {
                        GameObject obj;
                        Transform trans = transform.Find(waypoints[i].name + "_" + j);
                        if (trans)
                        {
                            obj = trans.gameObject;
                        }
                        else
                        {
                            obj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                            obj.name = waypoints[i].name + "_" + j;
                            obj.transform.SetParent(transform);
                            obj.transform.localScale = new Vector3(0.25f, 0.25f, 0.25f);
                        }                       
                        obj.transform.position = waypoints[i].positions[j];
                        
                    }
                }
            }
        }

        [ContextMenu("Set Point")]
        void SetPoint()
        {
            for (int i = 0; i < waypoints.Length; i++)
            {
                if (waypoints[i].visiable)
                {
                    for (int j = 0; j < waypoints[i].positions.Length; j++)
                    {
                        Transform trans = transform.Find(waypoints[i].name + "_" + j);
                        if (trans)
                        {
                            waypoints[i].positions[j] = trans.position;
                        }
                        else
                        {
                            break;
                        }
                    }
                    
                }
            }
        }

        [ContextMenu("Set And Delete")]
        void SetAndDelete()
        {
            for (int i = 0; i < waypoints.Length; i++)
            {
                if (waypoints[i].visiable)
                {
                    for (int j = 0; j < waypoints[i].positions.Length; j++)
                    {
                        Transform trans = transform.Find(waypoints[i].name + "_" + j);
                        if (trans)
                        {
                            waypoints[i].positions[j] = trans.position;
                            GameObject.DestroyImmediate(trans.gameObject);
                        }
                        else
                        {
                            break;
                        }
                    }

                }
            }
        }

#endif
    }
}
