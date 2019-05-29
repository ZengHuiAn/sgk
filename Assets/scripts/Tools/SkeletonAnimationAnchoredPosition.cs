using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Spine.Unity;
[RequireComponent(typeof (SkeletonAnimation))]
public class SkeletonAnimationAnchoredPosition : MonoBehaviour {
    public string boneName;

    bool recordLocation = false;
    Vector3 originPosition;

    void ChangeLocation() {
        if (string.IsNullOrEmpty(boneName)) {
            return;
        }

        SkeletonAnimation skeletonAnimation = GetComponent<SkeletonAnimation>();
        if (skeletonAnimation != null) {
            if (skeletonAnimation.skeleton == null) {
                return;
            }

            if (!recordLocation) {
                originPosition = transform.localPosition;
                recordLocation = true;
            }

            Spine.Bone bone = skeletonAnimation.skeleton.FindBone(boneName);
            if (bone != null) {
                transform.localPosition = originPosition - new Vector3(bone.WorldX * transform.localScale.x, bone.WorldY * transform.localScale.y, 0);
            }
        }
    }

    void ResetLocation() {
        if (recordLocation) {
            transform.localPosition = originPosition;
            recordLocation = false;
        }
    }

    private void OnEnable() {
        ChangeLocation();
    }

    private void Update() {
        ChangeLocation();
    }

    private void OnDisable() {
        ResetLocation();
    }

    public static void Attach(SkeletonAnimation animation, string boneName) {
        SkeletonAnimationAnchoredPosition mt = animation.gameObject.GetComponent<SkeletonAnimationAnchoredPosition>();
        if (mt == null) {
            mt = animation.gameObject.AddComponent<SkeletonAnimationAnchoredPosition>();
        }
        mt.boneName = boneName;
        mt.ResetLocation();
    }
}
