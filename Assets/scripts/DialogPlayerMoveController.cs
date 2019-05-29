using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.AI;
using UnityEngine.Events;
namespace SGK
{
    public class DialogPlayerMoveController : MonoBehaviour
    {
        public delegate void Delegate(GameObject go);

        public PointInfo[] movePoint = new PointInfo[0];

        public int speed = 2;
        public float boxSize = 0.5f;
        public int minOrder = 0;
        public int maxOrder = 0;
        public Vector2 offset = Vector2.zero;

        float maxHeight;
        float minHeight;
        float unitHeight;

        bool init = false;
        bool controllOrder = false;
        [System.Serializable]
        public struct PointInfo
        {
            public string name;
            public Vector3 position;
            public int direction;
            public System.Action callback;
        }

        [SerializeField]
        Dictionary<long, DialogPlayer> characters = new Dictionary<long, DialogPlayer>();
        // Dictionary<string, System.Action> callbacks = new Dictionary<string, System.Action>();
        Dictionary<string, PointInfo> points = new Dictionary<string, PointInfo>();

        void Awake()
        {
            InitData();
            for (int i = 0; i < movePoint.Length; i++)
            {
                if (movePoint[i].name != "")
                {
                    points[movePoint[i].name] = movePoint[i];
                }
            }
        }

#if UNITY_EDITOR
        void OnDrawGizmosSelected()
        {
            if (this.gameObject.activeInHierarchy && enabled)
            {
                Gizmos.color = Color.red;
                foreach (var item in movePoint)
                {

                    Gizmos.DrawCube(this.gameObject.transform.TransformPoint(item.position), new Vector3(boxSize, boxSize, boxSize));
                }
            }
        }
#endif

        void InitData()
        {
            if (init)
            {
                return;
            }
            if (movePoint.Length > 1 && (maxOrder - minOrder) > 0)
            {
                maxHeight = movePoint[0].position.y;
                minHeight = movePoint[0].position.y;
                foreach (var item in movePoint)
                {
                    if (maxHeight < item.position.y)
                    {
                        maxHeight = item.position.y;
                    }
                    if (minHeight > item.position.y)
                    {
                        minHeight = item.position.y;
                    }
                }

                unitHeight = (maxHeight - minHeight) / (maxOrder - minOrder);
                controllOrder = true;
            }
            init = true;
        }

        public GameObject Get(long id)
        {
            DialogPlayer character;
            if (characters.TryGetValue(id, out character))
            {
                if (character != null) {
                    return character.gameObject;
                }
            }
            return null;
        }

        public DialogPlayer Add(long id, GameObject obj)
        {
            DialogPlayer character;
            if (characters.TryGetValue(id, out character))
            {
                return character;
            }

            DialogPlayer player = obj.GetComponent<DialogPlayer>();
            if (player != null)
            {
                InitData();
                player.InitData(controllOrder, maxOrder, minOrder, maxHeight, minHeight, unitHeight, speed);
                characters[id] = player;
                return characters[id];
            }
            return null;
        }


        public void Remove(long id)
        {
            DialogPlayer character;
            if (!characters.TryGetValue(id, out character))
            {
                return;
            }
            characters.Remove(id);
            if (character != null) {
                Destroy(character.gameObject);
            }
        }

        public void SetPoint(long id, string name)
        {
            PointInfo point;
            DialogPlayer character;
            if (characters.TryGetValue(id, out character) && points.TryGetValue(name, out point))
            {
                if (character != null) {
                    character.SetPoint(point);
                }
            }
        }


        public void MoveTo(long id, PointInfo point, System.Action calllback)
        {
            DialogPlayer character;
            if (characters.TryGetValue(id, out character)) {
                //移动
                if (character != null) {
                    PointInfo _point = point;
                    _point.callback = calllback;
                    character.MoveTo(_point);
                }
            }
        }

        public void MoveTo(long id, Vector3 pos, System.Action calllback)
        {
            DialogPlayer character;
            if (characters.TryGetValue(id, out character))
            {
                if (character != null) {
                    PointInfo point;
                    point.position = pos;
                    point.name = "";
                    point.direction = -1;
                    point.callback = calllback;

                    character.MoveTo(point);
                }
            }
        }

        public void MoveTo(long id, Vector3 pos)
        {
            MoveTo(id, pos, null);
        }

        public void MoveCharacter(long characterID, int posIndex)
        {
            MoveCharacter(characterID, posIndex, null);
        }

        public void MoveCharacter(long characterID, int posIndex, System.Action calllback)
        {
            if (movePoint.GetValue(posIndex) != null)
            {
                MoveTo(characterID, movePoint[posIndex], calllback);
            }
        }
        public void MoveCharacter(long characterID, string name)
        {
            MoveCharacter(characterID, name, null);
        }

        public void MoveCharacter(long characterID, string name, System.Action calllback)
        {
            PointInfo point;
            if (points.TryGetValue(name, out point))
            {
                MoveTo(characterID, point, calllback);
            }
        }

        public Vector3 GetPoint(int posIndex)
        {
            return movePoint[posIndex].position;
        }

        public Vector3 GetPoint(string name)
        {
            PointInfo point;
            if (points.TryGetValue(name, out point))
            {
                return point.position;
            }
            Debug.LogError(name + " point not exist");
            return Vector3.zero;
        }
        public PointInfo GetPointInfo(string name)
        {
            PointInfo point;
            if (points.TryGetValue(name, out point))
            {
                return point;
            }
            Debug.LogError(name + " point not exist");
            return point;
        }

        [ContextMenu("Adjust")]
        void Adjust()
        {
            for (int i = 0; i < movePoint.Length; i++)
            {
                movePoint[i].position.x = movePoint[i].position.x + offset.x;
                movePoint[i].position.y = movePoint[i].position.y + offset.y;
            }
        }
    }
}