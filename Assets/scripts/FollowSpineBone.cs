using UnityEngine;
using System.Collections;
using UnityEngine.UI;
using Spine.Unity;
using System.Collections.Generic;

public class FollowSpineBone : MonoBehaviour {
    public GameObject target;
    public string boneName;
	public float x;
	public float y;
    public Vector3 localOffset = Vector3.zero;

	void Update () {
        Follow();
    }

#if UNITY_EDITOR
	static Dictionary<string, bool> errorBone = new Dictionary<string, bool>();
#endif

    [ContextMenu("Execute")]
    void Follow() {
        if (target == null) {
            return;
        }
		SkeletonGraphic skeletonGraphic = target.GetComponent<SkeletonGraphic> ();
		if(skeletonGraphic != null && skeletonGraphic.Skeleton != null && boneName != ""){
			Spine.Bone _bone = skeletonGraphic.Skeleton.FindBone (boneName);
			if (_bone == null) {
				Debug.LogFormat("skeletonGraphic bone {0} of object {1} no found", boneName, target.name);
				return;
			}
			Vector3 _pos = new Vector3(_bone.WorldX, _bone.WorldY, 0) *100;
			x = _bone.WorldX;
			y = _bone.WorldY;
			gameObject.transform.localPosition = _pos;//target.transform.TransformPoint(_pos);
			return;
		}

        SkeletonAnimation skeletonAnimation = target.GetComponent<SkeletonAnimation>();

        if (skeletonAnimation == null || skeletonAnimation.skeleton == null) {
            return;
        }
		if (boneName != "") {
			Spine.Bone bone = skeletonAnimation.skeleton.FindBone (boneName);
			if (bone == null) {
#if UNITY_EDITOR
				string key = boneName + "@" + skeletonAnimation.skeletonDataAsset.name;
				if (!errorBone.ContainsKey(key)) {
					Debug.LogErrorFormat ("skeletonAnimation bone {0} of {1} no found", boneName, skeletonAnimation.skeletonDataAsset.name);
					errorBone[key] = true;
				}
#endif
				return;
			}

			Vector3 pos = new Vector3 (bone.WorldX, bone.WorldY, 0);
			gameObject.transform.position = target.transform.TransformPoint (pos + localOffset);
		}
    }
}
