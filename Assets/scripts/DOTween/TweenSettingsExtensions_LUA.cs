using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using DG.Tweening;

public static class TweenSettingsExtensions_LUA {
    public static Sequence Append(this Sequence s, Tween t) {
        return TweenSettingsExtensions.Append(s, t);
    }

    public static Sequence AppendCallback(this Sequence s, TweenCallback callback) {
        return TweenSettingsExtensions.AppendCallback(s, () => { callback(); callback = null; });
    }

    public static Sequence AppendInterval(this Sequence s, float interval) {
        return TweenSettingsExtensions.AppendInterval(s, interval);
    }
    public static T From<T>(this T t, bool isRelative) where T : Tweener {
        return TweenSettingsExtensions.From(t, isRelative);
    }

    public static T From<T>(this T t) where T : Tweener {
        return TweenSettingsExtensions.From(t);
    }
    
    public static Sequence Insert(this Sequence s, float atPosition, Tween t) {
        return TweenSettingsExtensions.Insert(s, atPosition, t);
    }

    public static Sequence InsertCallback(this Sequence s, float atPosition, TweenCallback callback) {
        return TweenSettingsExtensions.InsertCallback(s, atPosition, () => { callback(); callback = null; });
    }
    
    public static Sequence Join(this Sequence s, Tween t) {
        return TweenSettingsExtensions.Join(s, t);
    }

    public static T OnComplete<T>(this T t, TweenCallback action) where T : Tween {
        return TweenSettingsExtensions.OnComplete(t, () => { action(); action = null; });
    }

    public static T OnKill<T>(this T t, TweenCallback action) where T : Tween {
        return TweenSettingsExtensions.OnKill(t, () => { action(); action = null; });
    }

    public static T OnPause<T>(this T t, TweenCallback action) where T : Tween {
        return TweenSettingsExtensions.OnPause(t, () => { action(); action = null; });
    }

    public static T OnPlay<T>(this T t, TweenCallback action) where T : Tween {
        return TweenSettingsExtensions.OnPause(t, () => { action(); action = null; });
    }

    public static T OnRewind<T>(this T t, TweenCallback action) where T : Tween {
        return TweenSettingsExtensions.OnRewind(t, () => { action(); action = null; });
    }

    public static T OnStart<T>(this T t, TweenCallback action) where T : Tween {
        return TweenSettingsExtensions.OnStart(t, () => { action(); action = null; });
    }

    public static T OnStepComplete<T>(this T t, TweenCallback action) where T : Tween {
        return TweenSettingsExtensions.OnStepComplete(t, () => { action(); action = null; });
    }
    public static T OnUpdate<T>(this T t, TweenCallback action) where T : Tween {
        return TweenSettingsExtensions.OnUpdate(t, () => { action(); action = null; }); 
    }

    public static T OnWaypointChange<T>(this T t, TweenCallback<int> action) where T : Tween {
        return TweenSettingsExtensions.OnWaypointChange(t, (v) => { action(v); action = null; });
    }
    
    public static Sequence Prepend(this Sequence s, Tween t) {
        return TweenSettingsExtensions.Prepend(s, t);
    }

    public static Sequence PrependCallback(this Sequence s, TweenCallback callback) {
        return TweenSettingsExtensions.PrependCallback(s, () => { callback(); callback = null; });
    }

    public static Sequence PrependInterval(this Sequence s, float interval) {
        return TweenSettingsExtensions.PrependInterval(s, interval);
    }

    public static T SetAs<T>(this T t, TweenParams tweenParams) where T : Tween {
        return TweenSettingsExtensions.SetAs(t, tweenParams);
    }

    public static T SetAs<T>(this T t, Tween asTween) where T : Tween {
        return TweenSettingsExtensions.SetAs(t, asTween);
    }

    public static T SetAutoKill<T>(this T t) where T : Tween {
        return TweenSettingsExtensions.SetAutoKill(t);
    }


    public static T SetAutoKill<T>(this T t, bool autoKillOnCompletion) where T : Tween {
        return TweenSettingsExtensions.SetAutoKill(t, autoKillOnCompletion);
    }

    public static T SetDelay<T>(this T t, float delay) where T : Tween {
        return TweenSettingsExtensions.SetDelay(t, delay);
    }

    public static T SetEase<T>(this T t, Ease ease) where T : Tween {
        return TweenSettingsExtensions.SetEase(t, ease);
    }

    public static T SetEase<T>(this T t, EaseFunction customEase) where T : Tween {
        return TweenSettingsExtensions.SetEase(t, (v1, v2, v3, v4) => { float f = customEase(v1, v2, v3, v4); customEase = null; return f; });
    }

    public static T SetEase<T>(this T t, AnimationCurve animCurve) where T : Tween {
        return TweenSettingsExtensions.SetEase(t, animCurve);
    }


    public static T SetEase<T>(this T t, Ease ease, float amplitude, float period) where T : Tween {
        return TweenSettingsExtensions.SetEase(t, ease, amplitude, period);
    }

    public static T SetEase<T>(this T t, Ease ease, float overshoot) where T : Tween {
        return TweenSettingsExtensions.SetEase(t, ease, overshoot);
    }

    public static T SetId<T>(this T t, object id) where T : Tween {
        return TweenSettingsExtensions.SetId(t, id);
    }

    /*
    public static TweenerCore<Vector3, Path, PathOptions> SetLookAt(this TweenerCore<Vector3, Path, PathOptions> t, float lookAhead, Vector3? forwardDirection = default(Vector3?), Vector3? up = default(Vector3?)) {
        return TweenSettingsExtensions.SetLookAt(t, lookAhead, forwardDirection, up);
    }

    public static TweenerCore<Vector3, Path, PathOptions> SetLookAt(this TweenerCore<Vector3, Path, PathOptions> t, Vector3 lookAtPosition, Vector3? forwardDirection = default(Vector3?), Vector3? up = default(Vector3?)) {
        return TweenSettingsExtensions.
    }

    public static TweenerCore<Vector3, Path, PathOptions> SetLookAt(this TweenerCore<Vector3, Path, PathOptions> t, Transform lookAtTransform, Vector3? forwardDirection = default(Vector3?), Vector3? up = default(Vector3?)) {
        return TweenSettingsExtensions.
    }
    */

    public static T SetLoops<T>(this T t, int loops, LoopType loopType) where T : Tween {
        return TweenSettingsExtensions.SetLoops(t, loops, loopType);
    }

    public static T SetLoops<T>(this T t, int loops) where T : Tween {
        return TweenSettingsExtensions.SetLoops(t, loops);
    }

    /*
    public static Tweener SetOptions(this TweenerCore<float, float, FloatOptions> t, bool snapping) {
        return TweenSettingsExtensions.SetOptions(t, snapping);
    }

    public static Tweener SetOptions(this TweenerCore<Rect, Rect, RectOptions> t, bool snapping) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Color, Color, ColorOptions> t, bool alphaOnly) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Quaternion, Vector3, QuaternionOptions> t, bool useShortest360Route = true) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Vector4, Vector4, VectorOptions> t, AxisConstraint axisConstraint, bool snapping = false) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Vector4, Vector4, VectorOptions> t, bool snapping) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Vector3, Vector3, VectorOptions> t, AxisConstraint axisConstraint, bool snapping = false) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Vector3, Vector3, VectorOptions> t, bool snapping) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Vector2, Vector2, VectorOptions> t, AxisConstraint axisConstraint, bool snapping = false) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Vector3, Vector3[], Vector3ArrayOptions> t, bool snapping) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<Vector3, Vector3[], Vector3ArrayOptions> t, AxisConstraint axisConstraint, bool snapping = false) {
        return TweenSettingsExtensions.
    }

    public static TweenerCore<Vector3, Path, PathOptions> SetOptions(this TweenerCore<Vector3, Path, PathOptions> t, AxisConstraint lockPosition, AxisConstraint lockRotation = AxisConstraint.None) {
        return TweenSettingsExtensions.
    }

    public static Tweener SetOptions(this TweenerCore<string, string, StringOptions> t, bool richTextEnabled, ScrambleMode scrambleMode = ScrambleMode.None, string scrambleChars = null) {
        return TweenSettingsExtensions.
    }

    public static TweenerCore<Vector3, Path, PathOptions> SetOptions(this TweenerCore<Vector3, Path, PathOptions> t, bool closePath, AxisConstraint lockPosition = AxisConstraint.None, AxisConstraint lockRotation = AxisConstraint.None) {
        return TweenSettingsExtensions.
    }


    public static Tweener SetOptions(this TweenerCore<Vector2, Vector2, VectorOptions> t, bool snapping) {
        return TweenSettingsExtensions.
    }
    */
    public static T SetRecyclable<T>(this T t, bool recyclable) where T : Tween {
        return TweenSettingsExtensions.SetRecyclable(t, recyclable);
    }

    public static T SetRecyclable<T>(this T t) where T : Tween {
        return TweenSettingsExtensions.SetRecyclable(t);
    }


    public static T SetRelative<T>(this T t, bool isRelative) where T : Tween {
        return TweenSettingsExtensions.SetRelative(t, isRelative);
    }

    public static T SetRelative<T>(this T t) where T : Tween {
        return TweenSettingsExtensions.SetRelative(t);
    }

    public static T SetSpeedBased<T>(this T t) where T : Tween {
        return TweenSettingsExtensions.SetSpeedBased(t);
    }

    public static T SetSpeedBased<T>(this T t, bool isSpeedBased) where T : Tween {
        return TweenSettingsExtensions.SetSpeedBased(t, isSpeedBased);
    }
    public static T SetTarget<T>(this T t, object target) where T : Tween {
        return TweenSettingsExtensions.SetTarget(t, target);
    }

    public static T SetUpdate<T>(this T t, UpdateType updateType, bool isIndependentUpdate) where T : Tween {
        return TweenSettingsExtensions.SetUpdate(t, updateType, isIndependentUpdate);
    }

    public static T SetUpdate<T>(this T t, bool isIndependentUpdate) where T : Tween {
        return TweenSettingsExtensions.SetUpdate(t, isIndependentUpdate);
    }

    public static T SetUpdate<T>(this T t, UpdateType updateType) where T : Tween {
        return TweenSettingsExtensions.SetUpdate(t, updateType);
    }

}
