using UnityEngine;
using DG.Tweening;
using Spine.Unity;

namespace SGK
{

    public class DialogSprite : MonoBehaviour
    {

        [Range(0, 7)]
        public int direction = 0;
        public bool idle = true;
        public bool alwaysControllAnimation = true;

        [Range(0, 1)]
        public float minStatusChangeTime = 0.2f;

        public SkeletonGraphic skeletonAnimation;

        int _direction = -1;
        bool _idle = true;
        float idleTime = 0;

        void Start()
        {
            skeletonAnimation = GetComponent<Spine.Unity.SkeletonGraphic>();
        }

        public void SetDirty()
        {
            _direction = -1;
        }

        // Update is called once per frame
        void Update()
        {
            if (direction < 0 || direction > 7)
            {
                direction = 0;
            }

            bool flip = direction > 4;

            if (alwaysControllAnimation && skeletonAnimation != null && (direction != _direction || idle != _idle))
            {
                if ((Time.time - idleTime) >= minStatusChangeTime)
                {
                    idleTime = Time.time;
                }
                else
                {
                    //idle = _idle;
                    if (direction == _direction)
                    {
                        return;
                    }
                }

                _direction = direction;
                if (_direction > 4)
                {
                    _direction = 8 - direction;
                }

                if (skeletonAnimation.AnimationState != null)
                {
                    skeletonAnimation.AnimationState.SetAnimation(0, string.Format("{0}{1}", idle ? "idle" : "run", _direction + 1), true);
                }

                if (skeletonAnimation.AnimationState != null)
                {
                    skeletonAnimation.Skeleton.FlipX = flip;

                }
                _direction = direction;
                _idle = idle;
            }
        }

       
    }
}