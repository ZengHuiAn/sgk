using UnityEngine;
using System;
using System.Collections.Generic;
using XLua;

using System.Reflection;
using System.Runtime.InteropServices;
using System.IO;

public static class CustomSettings
{
    [LuaCallCSharp]
    public static List<Type> LuaCallCSharp {
        get {
            return new List<Type>() {
                typeof(Application),
                typeof(Time),
                typeof(Screen),
                typeof(SleepTimeout),
                typeof(Resources),
                typeof(Physics),
                typeof(RenderSettings),
                typeof(QualitySettings),
                typeof(GL),

                typeof(System.Action),
                typeof(UnityEngine.Events.UnityAction),

                typeof(Component),
                typeof(Transform),
                typeof(Vector2),
                typeof(Vector3),
                typeof(Vector4),
                typeof(Quaternion),
                typeof(Material),
                typeof(Rigidbody),
                typeof(Camera),
                typeof(AudioSource),

                typeof(UnityEngine.Object),
                typeof(GameObject),
                typeof(TrackedReference),

                typeof(Time),
                typeof(Texture),
                typeof(Texture2D),
                typeof(Shader),
                typeof(Renderer),
                typeof(WWW),
                typeof(CameraClearFlags),
                typeof(AudioClip),
                typeof(AssetBundle),
                typeof(ParticleSystem),
                typeof(AsyncOperation),
                typeof(LightType),
                typeof(SleepTimeout),
                typeof(Animator),
                // typeof(Input),
                typeof(KeyCode),
                typeof(SkinnedMeshRenderer),
                typeof(Space),
                typeof(MeshRenderer),
                typeof(SpriteRenderer),

                typeof(Collider),
                typeof(BoxCollider),
                typeof(MeshCollider),
                typeof(SphereCollider),
                typeof(CharacterController),
                typeof(CapsuleCollider),
                typeof(Animation),
                typeof(AnimationClip),
                typeof(AnimationState),
                typeof(AnimationBlendMode),
                typeof(QueueMode),
                typeof(PlayMode),
                typeof(WrapMode),

                typeof(QualitySettings),
                typeof(RenderSettings),
                typeof(BlendWeights),
                typeof(RenderTexture),

                typeof(Sprite),
                typeof(RectTransform),
                typeof(Resources),
                typeof(System.Collections.IEnumerator),
                typeof(System.Collections.Generic.IEnumerator<object>),

                typeof(UnityEngine.SceneManagement.SceneManager),
                typeof(UnityEngine.Events.UnityEvent),
                typeof(UnityEngine.TextAsset),
                typeof(UnityEngine.Color),
                typeof(UnityEngine.ColorUtility),
                typeof(UnityEngine.PlayerPrefs),
                typeof(UnityEngine.MonoBehaviour),
                typeof(UnityEngine.Behaviour),

                typeof(UnityEngine.EventSystems.UIBehaviour),
                typeof(UnityEngine.Events.UnityEventBase),
                typeof(UnityEngine.Events.UnityEvent<int>),

                typeof(UnityEngine.Canvas),
                typeof(UnityEngine.UI.Button),
                typeof(UnityEngine.UI.Button.ButtonClickedEvent),
                typeof(UnityEngine.UI.Text),
                typeof(UnityEngine.UI.Slider),
                typeof(UnityEngine.UI.ScrollRect),
                typeof(UnityEngine.UI.Scrollbar),
                typeof(UnityEngine.UI.Slider.SliderEvent),
                typeof(UnityEngine.UI.Selectable),
                typeof(UnityEngine.TextMesh),
                // typeof(System.String),

                typeof(UnityEngine.UI.InputField),
                typeof(UnityEngine.UI.Image),
                typeof(UnityEngine.UI.RawImage),
                typeof(UnityEngine.UI.MaskableGraphic),
                typeof(UnityEngine.UI.Graphic),
                typeof(UnityEngine.UI.Toggle),
                typeof(UnityEngine.UI.ToggleGroup),
                typeof(UnityEngine.UI.ContentSizeFitter),
                typeof(UnityEngine.UI.HorizontalLayoutGroup),
                typeof(UnityEngine.UI.VerticalLayoutGroup),
                typeof(UnityEngine.UI.HorizontalOrVerticalLayoutGroup),
                typeof(UnityEngine.UI.LayoutGroup),
                typeof(UnityEngine.UI.CanvasScaler),
                typeof(UnityEngine.UI.Dropdown),
                typeof(UnityEngine.UI.Dropdown.OptionDataList),
                typeof(UnityEngine.UI.Outline),

                typeof(UnityEngine.AI.NavMeshAgent),

                typeof(List<UnityEngine.UI.Dropdown.OptionData>),
                typeof(UnityEngine.CanvasGroup),
                typeof(RaycastHit),
                
                typeof(Spine.Unity.SkeletonAnimation),
                typeof(Spine.Unity.SkeletonRenderer),
                typeof(Spine.Unity.SkeletonGraphic),
                typeof(Spine.Unity.SkeletonDataAsset),
                typeof(Spine.AnimationState),
                typeof(Spine.TrackEntry),
                typeof(Spine.Skeleton),
                typeof(Spine.AnimationStateData),
                typeof(Spine.SkeletonData),
                typeof(Spine.Animation),

                typeof(DG.Tweening.Tween),
                typeof(DG.Tweening.RotateMode),
                typeof(DG.Tweening.DOTween),
                // typeof(DG.Tweening.DOTweenAnimation),
                typeof(DG.Tweening.Tweener),
                typeof(DG.Tweening.ShortcutExtensions46),
                typeof(DG.Tweening.ShortcutExtensions),
                typeof(DG.Tweening.TweenExtensions),
                // typeof(DG.Tweening.TweenSettingsExtensions),
                typeof(TweenSettingsExtensions_LUA),
                typeof(DG.Tweening.Core.TweenerCore<float, float, DG.Tweening.Plugins.Options.FloatOptions>),
                typeof(DG.Tweening.Core.TweenerCore<UnityEngine.Color,UnityEngine.Color,DG.Tweening.Plugins.Options.ColorOptions>),
                typeof(DG.Tweening.Core.TweenerCore<UnityEngine.Vector2,UnityEngine.Vector2,DG.Tweening.Plugins.Options.VectorOptions>),
                typeof(DG.Tweening.Core.TweenerCore<Vector3, Vector3, DG.Tweening.Plugins.Options.VectorOptions>),
                typeof(DG.Tweening.Core.TweenerCore<Quaternion, Quaternion, DG.Tweening.Plugins.Options.QuaternionOptions>),
                typeof(DG.Tweening.Core.TweenerCore<Quaternion, Vector3, DG.Tweening.Plugins.Options.QuaternionOptions>),
                typeof(DG.Tweening.Ease),

                typeof(SGK.Localization.ShortcutExtensions),
                typeof(SGK.AudioSourceVolumeController),
                typeof(SGK.AudioSourceVolumeController.AudioType),
                typeof(SGK.BackgroundMusicService),
                typeof(SGK.BackgroundMusicService.SceneMusicInfo),
                typeof(SGK.BattleCameraScriptAction),
                typeof(SGK.BattleCameraScriptAction.ActionType),
                typeof(SGK.BattlefieldEventDispatcher),
                typeof(SGK.BattlefieldObject),
                typeof(SGK.BattlefieldObject.SpineEvent),
                typeof(SGK.BattlefieldObjectAssistant),
                typeof(SGK.BattlefieldObjectEnemy),
                typeof(SGK.BattlefieldObjectPartner),
                typeof(SGK.BattlefieldObjectPartner.Icon),
                typeof(SGK.BattlefieldObjectPet),
                typeof(SGK.BattlefieldObjectWithBar),
                typeof(SGK.BattlefieldSkillButton),
                typeof(SGK.BattlefieldTimelineItem),
                typeof(SGK.Battle.BattlefieldTargetSelectorManager),
                typeof(SGK.BattlefieldTimeout),
                typeof(SGK.Battle.BattleCameraController),
                typeof(BattlefieldSkillManager2),
                typeof(UGUISimpleLayout),
                typeof(SGK.BattlefiledHeadManager),
                typeof(SGK.CharacterIcon),
                typeof(SGK.CharacterSprite),
                typeof(SGK.CoroutineService),
                typeof(SGK.CoroutineServiceConfig),
                typeof(SGK.CreateCharacterLoad),
                typeof(SGK.Database),
                typeof(SGK.Database.BattlefieldCharacterConfig),
                typeof(SGK.DialogPlayer),
                typeof(SGK.DialogPlayerMoveController),
                typeof(SGK.DialogPlayerMoveController.Delegate),
                typeof(SGK.DialogPlayerMoveController.PointInfo),
                typeof(SGK.DialogService),
                typeof(SGK.DialogService.DialogInfo),
                typeof(SGK.DialogSprite),
                typeof(SGK.DropdownController),
                typeof(SGK.dropdownView),
                typeof(SGK.EncounterFight),
                typeof(SGK.EquipIcon),
                typeof(SGK.EquipPrefixIcon),
                typeof(SGK.EquipPrefixIcon.ColorInfo),
                typeof(SGK.FileUtils),
                typeof(SGK.FollowMovement3d),
                typeof(SGK.FormationSlots),
                typeof(SGK.GameObjectPool),
                typeof(SGK.GameObjectPoolManager),
                typeof(SGK.GuideMask),
                typeof(SGK.ImageExtension),
                typeof(SGK.ImageLoader),
                typeof(SGK.RawImageWWWExtension),
                typeof(SGK.SkeletonAnimationExtension),
                typeof(SGK.InscIcon),
                typeof(SGK.IService),
                typeof(SGK.ItemIcon),
                typeof(SGK.LuaBehaviour),
                typeof(SGK.LuaBehaviour.LuaObjectAction),
                typeof(SGK.LuaController),
                typeof(SGK.LuaController.DispatchEventDelegate),
                typeof(SGK.LuaController.StartLuaCoroutineDelegate),
                typeof(SGK.LuaController.SyncDelegate),
                typeof(SGK.LuaLoader),
                typeof(SGK.MapClickableObject),
                typeof(SGK.MapClickableScript),
                typeof(SGK.MapController),
                typeof(SGK.MapHelper),
                typeof(SGK.MapInteractableMenu),
                typeof(SGK.MapInteractableMenuPlayer),
                typeof(SGK.MapInteractableObject),
                typeof(SGK.MapMonster),
                typeof(SGK.MapNpcScript),
                typeof(SGK.MapPlayer),
                typeof(SGK.MapPlayerCamera),
                typeof(SGK.MapPortal),
                typeof(SGK.MapSceneController),
                typeof(SGK.MapWayMoveController),
                typeof(SGK.MapWayMoveController.Character),
                typeof(SGK.MapWayMoveController.Delegate),
                typeof(SGK.MapWayMoveController.RepeatType),
                typeof(SGK.MapWayMoveController.WayInfo),
                typeof(SGK.MapWaypointMovement),
                typeof(SGK.MaskableGameObject),
                typeof(SGK.MaskableSkeletonAnimation),
                typeof(SGK.MediaPlayerHelper),
                typeof(SGK.MediaPlayerHelper.EventDelegate),
                typeof(SGK.MiniMapFollowPlayer),
                typeof(SGK.NetworkService),
                //typeof(SGK.newCharacterIcon),
                //typeof(SGK.newCharacterIcon.ColorInfo),
                //typeof(SGK.newEquipIcon),
                //typeof(SGK.newEquipIcon.ColorInfo),
                //typeof(SGK.newItemIcon),
                //typeof(SGK.newItemIcon.ColorInfo),
                typeof(SGK.NonBreakingSpaceText),
                typeof(SGK.ParticleSystemSortingLayer),
                typeof(SGK.PatchManager),
                typeof(SGK.PatchManager.ServerInfo),
                typeof(SGK.PlayerIcon),
                typeof(SGK.QualityConfig),
                typeof(SGK.QualityConfig.ColorInfo),
                typeof(SGK.RecycleObject),
                typeof(SGK.ResourcesManager),
                typeof(SGK.RotateNumber),
                typeof(SGK.SceneService),
                typeof(SGK.SortChinese),
                typeof(SGK.SpriteOutline),
                typeof(SGK.TextEffect),
                typeof(SGK.TitleIcon),
                typeof(SGK.TitleItem),
                typeof(SGK.UIDotCounter),
                typeof(SGK.UIReference),
                typeof(SGK.GetSystemInfo),
                typeof(SGK.NotificationCenter),
                typeof(SGK.UGUISpriteAnimation),
                typeof(SGK.UGUILocalize),
                typeof(SGK.Localize),
                typeof(SGK.DialogAnim),
                typeof(SGK.TreeViewItem),
                typeof(SGK.TreeViewControl),
                typeof(SGK.TreeViewData),
                typeof(SGK.FollowTargetTips),
                typeof(SGK.moveMapItem),

                typeof(CameraClickEventListener),
                typeof(UGUIColorSelector),
                typeof(FollowCamera),
                typeof(NumberMovement),
                typeof(FollowSpineBone),

                typeof(UGUIClickEventListener),
                typeof(UGUIPointerEventListener),
                typeof(ModelClickEventListener),

                typeof(InlineText),

                typeof(UGUISpriteSelector),
                typeof(UGUIColorSelector),
                typeof(UGUISelectorGroup),
                typeof(UGUICanvasRendererColorSelector),
                typeof(UGUISelector),
                typeof(UGUISelectorGroup),

                typeof(UIMultiScroller),

                typeof(UGUIScrollRectEventListener),
                typeof(UGUIScrollRectEventListener.ScrollDelegate),
                typeof(AssetManager),
                typeof(AssetVersion),

                // typeof(WaypointMovement),
            };
        }
    }

    [CSharpCallLua]
    public static List<Type> CSharpCallLua {
        get {
            return new List<Type>() {
                typeof(Spine.AnimationState.TrackEntryDelegate),
                typeof(UIMultiScroller.SystemAction_Go_Int),
				typeof(ChatContent.OnRefreshItem),
				typeof(newScrollText.SystemAction_Go_Int),
                typeof(System.Action),
                typeof(System.Action<Texture2D,Action<bool>>),
                typeof(UnityEngine.Events.UnityAction),
                typeof(UnityEngine.Events.UnityAction<bool>),
                typeof(UnityEngine.Events.UnityAction<float>),
                typeof(UnityEngine.Events.UnityAction<int>),
                typeof(UnityEngine.Events.UnityAction<Vector2>),
                typeof(System.Action<object>),
                typeof(System.Action<string>),
				typeof(System.Action<string,int>),
                typeof(System.Action<float>),
                typeof(System.Action<int>),
                typeof(System.Action<Vector3>),
                typeof(System.Action<UnityEngine.Object>),
                typeof(System.Action<Vector3, GameObject>),
                typeof(System.Action<bool, GameObject>),
                typeof(DG.Tweening.TweenCallback),
                typeof(SGK.LuaBehaviour.LuaObjectAction),
                typeof(SGK.BattlefieldObject.SpineEvent),
                typeof(UGUIPointerEventListener.VectorDelegate),
                typeof(UGUIPointerEventListener.VectorDelegate2),
                typeof(UGUIScrollRectEventListener.ScrollDelegate),
                typeof(ModelClickEventListener.modelclickDelegate),
                typeof(SGK.MediaPlayerHelper.EventDelegate),
                typeof(SGK.DialogPlayerMoveController.Delegate),
                
                typeof(SGK.MapWayMoveController.Delegate),
                //typeof(UnityEngine.UI.ScrollRect.ScrollRectEvent),
                
            };
        }
    }

    [BlackList]
    public static List<List<string>> BlackList {
        get {
            return new List<List<string>> () {
                new List<string> () { "UnityEngine.WWW", "movie" },
                new List<string> () { "UnityEngine.WWW", "GetMovieTexture" },
                new List<string> () { "UIPanel", "GetMainGameViewSize" },
                new List<string> () { "UnityEngine.Texture2D", "alphaIsTransparency" },
                new List<string> () { "UnityEngine.MonoBehaviour", "runInEditMode" },
                new List<string> () { "UnityEngine.Light", "lightmappingMode" },
                new List<string> () { "UnityEngine.Light", "areaSize" },
                new List<string> () { "UnityEngine.UI.Text", "OnRebuildRequested" },
                new List<string> () { "UnityEngine.Texture", "imageContentsHash" },
                new List<string> () { "SGK.Database", "SerializeAllData" },
                new List<string> () { "SGK.Database", "loadTableFromServer" },
                new List<string> () { "SGK.Database", "LoadConfigFromServer" },
                new List<string> () { "UIWidget", "showHandles", },
                new List<string> () { "UIWidget", "showHandlesWithMoveTool" , },
                new List<string> () { "UnityEngine.UI.Graphic", "OnRebuildRequested" , },
                new List<string> () { "ImageMaterial", "_active", },
                new List<string> () { "UGUISelector", "NextValue", },
                new List<string> () { "SGK.UIReference", "DoSomething", },
                new List<string> () { "ScrollViewContent", "CopyFromUIMultiScroller", },
                new List<string> () { "UIMultiScroller", "ChangeToScrollViewContent", },
            };
        }
    }

#if UNITY_EDITOR
    public static bool CheckProperty(PropertyInfo prop) {
        return prop.IsDefined(typeof(LuaCallCSharpAttribute), false);
    }

    public static bool CheckField(FieldInfo field) {
        return field.IsDefined(typeof(LuaCallCSharpAttribute), false);
    }

    static HashSet<Type> exported_type;
    static HashSet<Type> checked_type = new HashSet<Type>();
    public static bool CheckType(Type t) {
        if (t.IsDefined(typeof(LuaCallCSharpAttribute), false)) {
            return true;
        }

        if (t.IsNested) {
            return true;
        }

        if (exported_type == null) {
            exported_type = GetGenConfig();
        }

        if (exported_type.Contains(t)) {
            return true;
        }

        if (checked_type.Contains(t)) {
            return false;
        }

        return false;
    }

    static void AddToList(ref HashSet<Type> list, Func<object> get) {
        object obj = get();
        if (obj is Type) {
            list.Add(obj as Type);
        } else if (obj is IEnumerable<Type>) {
            list.UnionWith(obj as IEnumerable<Type>);
        }
    }

    static void MergeCfg(ref HashSet<Type> list, MemberInfo test, Type cfg_type, Func<object> get_cfg) {
        if (test.IsDefined(typeof(LuaCallCSharpAttribute), false)) {
            AddToList(ref list, get_cfg);
        }
    }

    static HashSet<Type> GetGenConfig() {
        HashSet<Type> ExportSet = new HashSet<Type>();
        /*
        foreach (var t in Utils.GetAllTypes()) {
            if (!t.IsInterface && typeof(GenConfig).IsAssignableFrom(t)) {
                var cfg = Activator.CreateInstance(t) as GenConfig;
                if (cfg.LuaCallCSharp != null) ExportSet.UnionWith(cfg.LuaCallCSharp);
            }

            MergeCfg(ref ExportSet, t, null, () => t);

            if (!t.IsAbstract || !t.IsSealed) continue;

            var fields = t.GetFields(BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly);
            for (int i = 0; i < fields.Length; i++) {
                var field = fields[i];
                MergeCfg(ref ExportSet, field, field.FieldType, () => field.GetValue(null));
            }

            var props = t.GetProperties(BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.DeclaredOnly);
            for (int i = 0; i < props.Length; i++) {
                var prop = props[i];
                MergeCfg(ref ExportSet, prop, prop.PropertyType, () => prop.GetValue(null, null));
            }
        }
        */
        return ExportSet;
    }
#endif
    [MonoPInvokeCallback(typeof(XLua.LuaDLL.lua_CSFunction))]
    internal static int LoadString(IntPtr L) {
        string str = XLua.LuaDLL.Lua.lua_tostring (L, 1);
        string name = null;
        if (XLua.LuaDLL.Lua.lua_isstring (L, 2)) {
            name = XLua.LuaDLL.Lua.lua_tostring (L, 2);
        }
        if (XLua.LuaDLL.Lua.luaL_loadbuffer (L, str, name) != 0) {
            Debug.LogWarning (XLua.LuaDLL.Lua.lua_tostring (L, -1));
            return 0;
        }
        return 1;
    }

    [MonoPInvokeCallback(typeof(XLua.LuaDLL.lua_CSFunction))]
    internal static int PrintWarning(IntPtr L) {
        return Print_ (L, Debug.LogWarning);
    }

    [MonoPInvokeCallback(typeof(XLua.LuaDLL.lua_CSFunction))]
    internal static int PrintError(IntPtr L) {
        return Print_ (L, Debug.LogError);
    }

    internal static int Print_(IntPtr L, System.Action<string> print) {
        try {
            int n = XLua.LuaDLL.Lua.lua_gettop(L);
            string s = String.Empty;

            if (0 != XLua.LuaDLL.Lua.xlua_getglobal(L, "tostring")) {
                return XLua.LuaDLL.Lua.luaL_error(L, "can not get tostring in print:");
            }

            for (int i = 1; i <= n; i++) {
                XLua.LuaDLL.Lua.lua_pushvalue(L, -1);  /* function to be called */
                XLua.LuaDLL.Lua.lua_pushvalue(L, i);   /* value to print */
                if (0 != XLua.LuaDLL.Lua.lua_pcall(L, 1, 1, 0)) {
                    return XLua.LuaDLL.Lua.lua_error(L);
                }
                s += XLua.LuaDLL.Lua.lua_tostring(L, -1);

                if (i != n) s += "\t";

                XLua.LuaDLL.Lua.lua_pop(L, 1);  /* pop result */
            }

            XLua.LuaDLL.Lua.luaL_where(L, 1);
            string stack = XLua.LuaDLL.Lua.lua_tostring(L, -1);
            XLua.LuaDLL.Lua.lua_pop(L, 1);
            
            print("LUA: " + stack + s);
            return 0;
        } catch (System.Exception e) {
            return XLua.LuaDLL.Lua.luaL_error(L, "c# exception in print:" + e);
        }
    }

    [MonoPInvokeCallback(typeof(XLua.LuaDLL.lua_CSFunction))]
    internal static int BATTLE_LOG(IntPtr L) {
        if (!Application.isEditor) {
            return 0;
        }

        try {
            int n = XLua.LuaDLL.Lua.lua_gettop(L);
            string s = String.Empty;

            if (0 != XLua.LuaDLL.Lua.xlua_getglobal(L, "tostring")) {
                return XLua.LuaDLL.Lua.luaL_error(L, "can not get tostring in print:");
            }

            for (int i = 1; i <= n; i++) {
                XLua.LuaDLL.Lua.lua_pushvalue(L, -1);  /* function to be called */
                XLua.LuaDLL.Lua.lua_pushvalue(L, i);   /* value to print */
                if (0 != XLua.LuaDLL.Lua.lua_pcall(L, 1, 1, 0)) {
                    return XLua.LuaDLL.Lua.lua_error(L);
                }
                s += XLua.LuaDLL.Lua.lua_tostring(L, -1);

                if (i != n) s += "\t";

                XLua.LuaDLL.Lua.lua_pop(L, 1);  /* pop result */
            }

            FileStream log_file = new FileStream("sgk.battle.log", FileMode.Append);
            if (log_file != null) {
                byte[] info = new System.Text.UTF8Encoding(true).GetBytes(s + "\n");
                log_file.Write(info, 0, info.Length);
                log_file.Close();
            }
            return 0;
        } catch (System.Exception e) {
            return XLua.LuaDLL.Lua.luaL_error(L, "c# exception in print:" + e);
        }
    }
}

namespace XLua.LuaDLL
{
    public partial class Lua
    {
        [DllImport (LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_network (IntPtr L);

        [MonoPInvokeCallback (typeof(lua_CSFunction))]
        public static int LoadNetwork (IntPtr L)
        {
            return luaopen_network (L);
        }

        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_VM(IntPtr L);

        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int lua_VM_SetDefaultLoader(lua_CSFunction func);

        [DllImport(LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int lua_VM_SetPrint(lua_CSFunction func);

        [MonoPInvokeCallback(typeof(lua_CSFunction))]
        public static int LoadVM(IntPtr L) {
            lua_VM_SetDefaultLoader(VMLoader);
            lua_VM_SetPrint(StaticLuaCallbacks.Print);
            return luaopen_VM(L);
        }

        [MonoPInvokeCallback(typeof(lua_CSFunction))]
        internal static int VMLoader(IntPtr L) {
            try {
                string filename = Lua.lua_tostring(L, 1);

                // LuaEnv self = ObjectTranslatorPool.Instance.Find(L).luaEnv;
                string real_file_path = filename;
                byte[] bytes = SGK.FileUtils.Load(ref real_file_path);
                if (bytes != null) {
                    if (Lua.xluaL_loadbuffer(L, bytes, bytes.Length, "@" + real_file_path) != 0) {
                        Lua.lua_pushstring(L, Lua.lua_tostring(L, -1));
                        return 1;
                        // return Lua.luaL_error(L, String.Format("error loading module {0} from VMLoader, {1}",
                        //    Lua.lua_tostring(L, 1), Lua.lua_tostring(L, -1)));
                    }
                    return 1;
                }
                Lua.lua_pushstring(L, string.Format(
                    "\n\tno such file '{0}' in VMLoader!", filename));
                return 1;
            } catch (System.Exception e) {
                return Lua.luaL_error(L, "c# exception in LoadFromCustomLoaders:" + e);
            }
        }


        [DllImport (LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_WordFilter (IntPtr L);

        [MonoPInvokeCallback (typeof(lua_CSFunction))]
        public static int LoadWordFilter (IntPtr L)
        {
            return luaopen_WordFilter (L);
        }

        [DllImport (LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_protobuf_c (IntPtr L);

        [MonoPInvokeCallback (typeof(lua_CSFunction))]
        public static int LoadProtobuf (IntPtr L)
        {
            return luaopen_protobuf_c (L);
        }

        [DllImport (LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int luaopen_WELLRNG512a (IntPtr L);

        [MonoPInvokeCallback (typeof(lua_CSFunction))]
        public static int LoadWELLRNG512a (IntPtr L)
        {
            return luaopen_WELLRNG512a (L);
        }

    }
}
