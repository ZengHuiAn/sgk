using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using Spine;
using Spine.Unity;

public class SpineEventListener : MonoBehaviour {
    public delegate void SpineEvent(string eventName, string strValue, int intValue, float floatValue);
    public SpineEvent onSpineEvent = null;
    public Spine.AnimationState state;

    private void Start() {
        Watch();        
    }

    public void Watch () {
        if (state != null) {
            state.Event -= OnSpineEvent;
            state = null;
        }

        IAnimationStateComponent animation = GetComponent<IAnimationStateComponent>();
        if (animation == null) {
            return;
        }

        state = animation.AnimationState;

        if (state != null) {
            state.Event += OnSpineEvent;
        }
    }

    void OnDestroy() {
        if (state != null) {
            state.Event -= OnSpineEvent;
            state = null;
        }
        onSpineEvent = null;
    }

    void OnSpineEvent(TrackEntry trackEntry, Spine.Event e) {
        if (onSpineEvent == null) {
            defaultSpineEvent(e.Data.Name, e.String, e.Int, e.Float);
        } else {
            onSpineEvent(e.Data.Name, e.String, e.Int, e.Float);
        }
    }

    void defaultSpineEvent(string eventName, string strValue, int intValue, float floatValue) {
    }
}
