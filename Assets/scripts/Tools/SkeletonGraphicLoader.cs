using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.U2D;
using UnityEngine.UI;
using Spine.Unity;

namespace SGK {
	public class SkeletonGraphicLoader : MonoBehaviour {
        public System.Action onLoad;

        static void AfterLoad(SkeletonGraphic skeletonGraphic, SkeletonDataAsset skeletonDataAsset, string[] actions = null) {
            skeletonGraphic.skeletonDataAsset = skeletonDataAsset;
            if (actions == null && actions.Length >= 1) {
                skeletonGraphic.startingAnimation = actions[0];
            }
            skeletonGraphic.Initialize(true);
            if (skeletonGraphic.AnimationState != null && actions != null) {
                for (int i = 0; i < actions.Length; i++) {
                    skeletonGraphic.AnimationState.SetAnimation(i, actions[i], (i == (actions.Length - 1)));
                }
            }
        }

        public static SkeletonGraphicLoader Load(SkeletonGraphic skeletonGraphic, string skeletonData, string[] actions = null) {
            if (string.IsNullOrEmpty(skeletonData)) {
                AfterLoad(skeletonGraphic, null, actions);
                return null;
            }

            SkeletonGraphicLoader loader = skeletonGraphic.gameObject.GetComponent<SkeletonGraphicLoader>();
			if (loader != null) {
                Destroy(loader);
			}

            loader = skeletonGraphic.gameObject.AddComponent<SkeletonGraphicLoader>();
            loader.skeletonGraphic = skeletonGraphic;
			loader.skeletonDataFileName = skeletonData;
			loader.actions = actions;

            return loader;
		}

        public SkeletonGraphic skeletonGraphic;
        public string skeletonDataFileName = null;

        string[] actions = null;
        // bool loop = true;

        private void Start() {
            DoLoad();
        }

        void DoLoad() {
            if (string.IsNullOrEmpty(skeletonDataFileName)) {
                return;
            }

            SGK.ResourcesManager.LoadAsync(this, skeletonDataFileName + ".asset", typeof(SkeletonDataAsset), (o1) => {
                AfterLoad(skeletonGraphic, o1 as SkeletonDataAsset, actions);
                if (onLoad != null) {
                    onLoad();
                }
            });
        }
    }

    /*
	public static class skeletonGraphicExtension {
        public static void UpdateskeletonGraphic(this Skele animation, string name, string action = null, bool loop = true) {
            skeletonGraphicLoader.Load(animation, name, action, loop);
        }
    }
    */
}
