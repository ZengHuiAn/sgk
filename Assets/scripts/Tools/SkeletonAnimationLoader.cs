using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.U2D;
using UnityEngine.UI;
using Spine.Unity;

namespace SGK {
	public class SkeletonAnimationLoader : MonoBehaviour {
        public System.Action onLoad;

		static void AfterLoad(SkeletonAnimation skeletonAnimation, SkeletonDataAsset skeletonDataAsset, string [] actions = null, bool flip = false) {
            skeletonAnimation.skeletonDataAsset = skeletonDataAsset;
            skeletonAnimation.Initialize(true);
            if (skeletonAnimation.state != null && actions != null) {
                for (int i = 0; i < actions.Length; i++) {
                    if (!string.IsNullOrEmpty(actions[i])) {
                        if (i == 0) {
                            skeletonAnimation.state.SetAnimation(0, actions[i], (i == (actions.Length - 1)));
                        } else {
                            skeletonAnimation.state.AddAnimation(0, actions[i], (i == (actions.Length - 1)), 0);
                        }
                    }
                }
            }
			if (skeletonAnimation.skeleton != null && flip) {
				skeletonAnimation.skeleton.FlipX = flip;
			}
            MaskableSkeletonAnimation msa = skeletonAnimation.gameObject.GetComponent<MaskableSkeletonAnimation>();
            if (msa != null) {
                msa.UpdateStencil();
            }
        }

		public static SkeletonAnimationLoader Load(SkeletonAnimation skeletonAnimation, string name, string[] actions = null, bool flip = false) {
            if (string.IsNullOrEmpty(name)) {
				AfterLoad(skeletonAnimation, null, actions, flip);
                return null;
            }

            SkeletonAnimationLoader loader = skeletonAnimation.gameObject.GetComponent<SkeletonAnimationLoader>();
			if (loader != null) {
                Destroy(loader);
			}

            loader = skeletonAnimation.gameObject.AddComponent<SkeletonAnimationLoader>();
            loader.skeletonAnimation = skeletonAnimation;
			loader.fileName = name;
			loader.actions = actions;
			loader.flip = flip;

            return loader;
		}

        public SkeletonAnimation skeletonAnimation;
        public string fileName = null;

        string [] actions = null;
		bool flip = false;
        private void Start() {
            DoLoad();
        }

        void DoLoad() {
            SGK.ResourcesManager.LoadAsync(this, fileName + ".asset", typeof(SkeletonDataAsset), (o) => {
				AfterLoad(skeletonAnimation, o as SkeletonDataAsset, actions, flip);

                if (onLoad != null) {
                    onLoad();
                }
            });
        }
    }

	public static class SkeletonAnimationExtension {
		public static SkeletonAnimationLoader UpdateSkeletonAnimation(this SkeletonAnimation animation, string name, string[] actions = null, bool flip = false) {
			return SkeletonAnimationLoader.Load(animation, name, actions, flip);
        }

        public static SkeletonGraphicLoader UpdateSkeletonAnimation(this SkeletonGraphic animation, string name, string[] actions = null, string material = null) {
            return SkeletonGraphicLoader.Load(animation, name, actions);
        }
    }
}
