using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;

namespace SGK {
    //[ExecuteInEditMode]
    // [RequireComponent(typeof(SpriteRenderer))]
    public class CharacterSprite : MonoBehaviour {

		[Range(0,7)]
		public int direction = 0;
		public bool idle = true;
        public bool alwaysControllAnimation = true;

        [Range(1,10)]
		public int frameCount = 5;

		[Range(0.01f, 1)]
		public float frameRate = 0.1f;

		[Range(0, 1)]
		public float minStatusChangeTime = 0.2f;

        [SerializeField]
        [Range(0, 1)]
        float toAlpha = 1;
        public float alpha
        {
            get { return toAlpha; }
            set
            {
                if (toAlpha != value)
                {
                    toAlpha = value;
                    ChangeAlpha(toAlpha, 0);
                }
            }
        }

        public Sprite [] sprites = new Sprite[0];

		float pass = 0;
		SpriteRenderer spriteRenderer;
        // MeshRenderer meshRenderer;
		Spine.Unity.SkeletonAnimation skeletonAnimation;

		int _direction = -1;
		bool _idle = false;
		float idleTime = 0;
        float fromAlpha = 1;

        float beginTime = 0;
        float duringTime = 0;
        void Start() {
			spriteRenderer = GetComponent<SpriteRenderer>();
			skeletonAnimation = GetComponent<Spine.Unity.SkeletonAnimation>();
            // meshRenderer = GetComponent<MeshRenderer>();
            if (skeletonAnimation && skeletonAnimation.skeleton != null && skeletonAnimation.skeleton.A != toAlpha)
            {
                skeletonAnimation.skeleton.A = toAlpha;
                //ChangeAlpha(0, 1, 2);
            }
            //if (meshRenderer != null)
            //{
            //    meshRenderer.material.DOFade(1, 1);
            //}
        }

        void OnBecameVisible()
        {
            if (skeletonAnimation == null)
            {
                return;
            }
            skeletonAnimation.enabled = true;
        }

        void OnBecameInvisible()
        {
            if (skeletonAnimation == null)
            {
                return;
            }
            skeletonAnimation.enabled = false;
        }

        public void SetDirty() {
			_direction = -1;
		}

		// Update is called once per frame
		void Update () {
			if (direction < 0 || direction > 7) {
				direction = 0;
			}

			bool flip = direction > 4;

			if (spriteRenderer != null) {
				int start = (flip ? (8-direction) : direction) * frameCount;
				if (!idle) {
					start += frameCount * 5;
				}

				pass += Time.deltaTime;
				pass = pass % (frameRate * frameCount);
				if (start + (int)(pass / frameRate) < sprites.Length) {
					spriteRenderer.sprite = sprites[start + (int)(pass / frameRate)];
					spriteRenderer.flipX = flip;
				}
			}

            /*
                    if (skeletonAnimation != null) {
                        skeletonAnimation.enabled = IsVisibleFrom(Camera.main);
                    }
            */

			if (alwaysControllAnimation && skeletonAnimation != null && (direction != _direction || idle != _idle)) {
				if ((Time.time - idleTime) >= minStatusChangeTime) {
					idleTime = Time.time;
				} else {
					idle = _idle;
					if (direction == _direction){
						return;
					}
				}

				_direction = direction;
				if (_direction > 4) {
					_direction = 8 - direction;
				}

				if (skeletonAnimation.state != null) {
					skeletonAnimation.state.SetAnimation(0, string.Format("{0}{1}", idle ? "idle" : "run", _direction + 1), true);
				}

				if (skeletonAnimation.skeleton != null) {
					skeletonAnimation.skeleton.FlipX = flip;

                }
				_direction = direction;
				_idle = idle;
			}
            if (skeletonAnimation && skeletonAnimation.skeleton != null)
            {
                if (skeletonAnimation.skeleton.A != toAlpha)
                {
                    if (duringTime != 0)
                    {
                        //float deltaAlpha = (toAlpha - fromAlpha) / duringTime * Time.deltaTime;
                        //skeletonAnimation.skeleton.a = skeletonAnimation.skeleton.a + deltaAlpha;
                        //float _alpha = (Time.time - beginTime) >= duringTime ? toAlpha : (toAlpha - fromAlpha) / duringTime * (Time.time - beginTime);
                        float _alpha = (toAlpha - fromAlpha) / duringTime * (Time.time - beginTime) + fromAlpha;
                        if (_alpha > 1)
                        {
                            skeletonAnimation.skeleton.A = 1;
                        }
                        else if (_alpha < 0)
                        {
                            skeletonAnimation.skeleton.A = 0;
                        }
                        else
                        {
                            skeletonAnimation.skeleton.A = _alpha;
                        }                        
                    }
                    else
                    {
                        skeletonAnimation.skeleton.A = toAlpha;
                    }
                }
                else if (duringTime != 0)
                {
                    duringTime = 0;
                }
            }
        }

        public void ChangeAlpha(float from ,float to, float time)
        {      
            fromAlpha = from;
            toAlpha = to;
            duringTime = time;
            beginTime = Time.time;
        }
        public void ChangeAlpha(float to, float time)
        {
            if (skeletonAnimation && skeletonAnimation.skeleton != null)
            {
                ChangeAlpha(skeletonAnimation.skeleton.A, to, time);
            }
        }

        bool IsVisibleFrom(Camera camera)
		{
			Plane[] planes = GeometryUtility.CalculateFrustumPlanes(camera);
			return GeometryUtility.TestPlanesAABB(planes, GetComponent<Renderer>().bounds);
		}
	}
}