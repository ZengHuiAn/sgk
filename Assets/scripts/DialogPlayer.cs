using UnityEngine;
using Spine.Unity;

namespace SGK
{
    public class DialogPlayer : MonoBehaviour
    {
        public DialogSprite sprite;
        //public GameObject speak;
        //public GameObject name;
        public int speed = 5;

        DialogPlayerMoveController.PointInfo destinationPoint;
        bool moving = false;
        bool controllOrder = false;
        bool init = false;

        int minOrder = 0;
        // int maxOrder = 0;

        float maxHeight;
        // float minHeight;
        float unitHeight;

        [SerializeField]
        int _orderIndex;
        public int orderIndex
        {
            set
            {
                if (_orderIndex != value)
                {
                    _orderIndex = value;
                    this.gameObject.transform.SetSiblingIndex(_orderIndex);
                }
            }
            get
            {
                return _orderIndex;
            }
        }

        //void Start()
        //{
        //    destinationPoint.position = transform.localPosition;
        //    destinationPoint.direction = 0;
        //    destinationPoint.callback = null;
        //}

        public void InitData(bool _controllOrder, int _maxOrder, int _minOrder, float _maxHeight, float _minHeight, float _unitHeight, int _speed)
        {
            controllOrder = _controllOrder;
            // maxOrder = _maxOrder;
            minOrder = _minOrder;
            maxHeight = _maxHeight;
            // minHeight = _minHeight;
            unitHeight = _unitHeight;
            speed = _speed;

            destinationPoint.position = transform.localPosition;
            destinationPoint.direction = 0;
            destinationPoint.callback = null;
            init = true;

            if (controllOrder)
            {
                int order = (int)Mathf.Floor((maxHeight - transform.localPosition.y) / unitHeight) + minOrder;
                orderIndex = order;
                //if (sprite)
                //{
                //    sprite.GetComponent<UnityEngine.MeshRenderer>().sortingOrder = order;
                //}
                //if (speak)
                //{
                //    speak.GetComponent<Canvas>().sortingOrder = order + 1;
                //}
                //if (name)
                //{
                //    name.GetComponent<Canvas>().sortingOrder = order;
                //}
               
            }
        }
        public void MoveTo(DialogPlayerMoveController.PointInfo pointInfo)
        {
            destinationPoint = pointInfo;
            sprite.alwaysControllAnimation = true;
            moving = true;
        }

        public void SetPoint(DialogPlayerMoveController.PointInfo pointInfo)
        {
            destinationPoint = pointInfo;
            transform.localPosition = destinationPoint.position;
            sprite.direction = destinationPoint.direction;
            sprite.alwaysControllAnimation = true;
            moving = false;
        }

        public void SetDirecttion(int dir)
        {
            if (dir < 0 || dir > 7)
            {
                dir = 0;
            }
            destinationPoint.direction = dir;
        }
        public void SetSpeed(int _speed)
        {
            speed = _speed;
        }

        public void UpdateSkeleton(string skeletonName)
        {
            if (!string.IsNullOrEmpty(skeletonName))
            {
                SGK.ResourcesManager.LoadAsync(this, string.Format("roles_small/{0}/{0}_SkeletonData.asset", skeletonName), (o) =>
                {
                    if (o != null)
                    {
                        sprite.skeletonAnimation.skeletonDataAsset = o as SkeletonDataAsset;
                        sprite.skeletonAnimation.material = SGK.ResourcesManager.Load<Material>(string.Format("roles_small/{0}/{0}_SkeletonData.mat", skeletonName));
                        sprite.skeletonAnimation.Initialize(true);
                    }
                    else
                    {
                        Debug.LogError(skeletonName + "_SkeletonData not found");
                    }
                });
            }
        }

        void Update()
        {
            if (!init)
            {
                return;
            }
            if (transform.localPosition != destinationPoint.position)
            {
                Vector3 startPos = transform.localPosition;
                Vector3 endPos = destinationPoint.position;
                Vector3 velocity = endPos - startPos;


                int angle = (int)(angle360(new Vector3(0, -1, 0), velocity, new Vector3(1, 0, 0)));
                if (angle % 360 == 0)
                {
                    angle = 0;
                }

                sprite.direction = (int)Mathf.Floor((angle + 22.5f) / 45);
                sprite.idle = !moving;

                var distance = Vector3.Distance(startPos, endPos);
                if (distance <= speed)
                {
                    transform.localPosition = destinationPoint.position;
                }
                else
                {
                    Vector3 pos = Vector3.MoveTowards(startPos, endPos, speed);
                    transform.localPosition = pos;
                }
                if (controllOrder)
                {
                    int order = (int)Mathf.Floor((maxHeight - transform.localPosition.y) / unitHeight) + minOrder;
                    orderIndex = order;
                    //if (sprite)
                    //{
                    //    sprite.GetComponent<UnityEngine.MeshRenderer>().sortingOrder = order;
                    //}
                    //if (speak)
                    //{
                    //    speak.GetComponent<Canvas>().sortingOrder = order + 1;
                    //}
                    //if (name)
                    //{
                    //    name.GetComponent<Canvas>().sortingOrder = order;
                    //}
                }

            }
            else if (moving)
            {
                moving = false;
                sprite.idle = true;
                if (destinationPoint.callback != null)
                {
                    
                    //character.Value.sprite.alwaysControllAnimation = false;
                    destinationPoint.callback();
                }
                if (destinationPoint.direction != -1)
                {
                    sprite.direction = destinationPoint.direction;
                }
                if (controllOrder)
                {
                    int order = (int)Mathf.Floor((maxHeight - transform.localPosition.y) / unitHeight) + minOrder;
                    orderIndex = order;
                }
            }
            //else if (!sprite.idle)
            //{
            //    sprite.idle = true;
            //}

        }

        float angle360(Vector3 way, Vector3 to, Vector3 left)
        {
            float angle = Vector3.Angle(to, way);
            return (Vector3.Angle(to, left) > 90f) ? angle : 360f - angle;
        }
    }
}
