using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;
using UnityEditor.IMGUI.Controls;


public class SpriteAtlasManagerWindow : EditorWindow, SpriteAtlasManagerWindow.AtlasListView.IDelegate {
    public class AtlasListView : TreeView
    {
        public bool select_origin_with_pack = true;
        public bool multiSelectEnable = false;
        public interface IDelegate
        {
            void onSelectChange(AtlasListView view, SpriteAtlasData data, SpriteAtlasData.SpriteInfo si, Sprite s);
            int GetReferenceCount(Sprite sprite);
            List<GameObject> GetReserenceObjects(Sprite sprite);
        }

        int _dirty = 0;
        List<SpriteAtlasData> _atlasList = new List<SpriteAtlasData>();
        public List<SpriteAtlasData> atlasList {
            get { return _atlasList; }
            set { _atlasList = value; Reload(); }
        }
        
        SpriteReferenceInfo _refInfo {
            get {
                return SpriteReferenceInfo.Instance;
            }
        }

        IDelegate _delegate;

        public AtlasListView(IDelegate _delegate) : base(new TreeViewState() /*, new AssetListTreeHeader()*/) {
            this._delegate = _delegate;
        }

        protected override TreeViewItem BuildRoot() {
            TreeViewItem root = new TreeViewItem { id = -1, depth = -1, displayName = "Sprites", children = new List<TreeViewItem>() };

            for (int i = 0; i < atlasList.Count; i++) {
                TreeViewItem parent = new TreeViewItem((i + 1) * 100000, 0, string.IsNullOrEmpty(atlasList[i].path) ? atlasList[i].name : atlasList[i].path);
                root.AddChild(parent);
                for (int j = 0; j < atlasList[i].sprites.Length; j++) {
                    var info = atlasList[i].sprites[j];
                    string name = info.name;
                    if (info.origins != null) {
                        name = string.Format("({0}) ", info.origins.Length) + name;
                    }
                    TreeViewItem sprite = new TreeViewItem((i + 1) * 100000 + (j + 1) * 100, 1, name);
                    parent.AddChild(sprite);

                    if (atlasList[i].sprites[j].origins != null) {
                        for (int k = 0; k < atlasList[i].sprites[j].origins.Length; k++) {
                            sprite.AddChild(new TreeViewItem((i + 1) * 100000 + (j + 1) * 100 + k + 1, 2, atlasList[i].sprites[j].origins[k].name));
                        }
                        sprite.AddChild(new TreeViewItem((i + 1) * 100000 + (j + 1) * 100 + atlasList[i].sprites[j].origins.Length + 1, 2, "----"));
                    }
                }
            }
            SetupDepthsFromParentsAndChildren(root);
            return root;
        }

        protected override void RowGUI(RowGUIArgs args) {
            SpriteAtlasData atlas = null;
            SpriteAtlasData.SpriteInfo sprite = null;
            Sprite origin = null;

            Get(args.item.id, out atlas, out sprite, out origin);

            if (atlas == null) {
                Debug.LogWarningFormat("atlas == null, {0}", args.item.id);
                return;
            }


            if (args.item.depth == 0) {
                base.RowGUI(args);
            } else if (args.item.depth == 1) {
                var info = sprite;

                if (_dirty < 1) {
                    if (info.FindOrigin()) {
                        EditorUtility.SetDirty(atlas);
                        _dirty += 1;
                    }
                }
                base.RowGUI(args);

                Rect re = args.rowRect;
                re.x = re.xMax - 100;
                re.width = 60;
                EditorGUI.LabelField(re, string.Format("{0}",  (_delegate == null) ? 0 : _delegate.GetReferenceCount(info.packed))); // _refInfo.GetRefCount(info.packed))

                if (info.origin != null && info.origin != info.packed) {
                    int count = (_delegate == null) ? 0 : _delegate.GetReferenceCount(info.origin);
                    if (count > 0) { 
                        re = args.rowRect;
                        re.x = re.xMax - 60;
                        re.width = 60;
                        Color c = DefaultStyles.label.normal.textColor;
                        DefaultStyles.label.normal.textColor = Color.red;
                        EditorGUI.LabelField(re, string.Format("{0}", count));
                        DefaultStyles.label.normal.textColor = c;
                    }
                }

                Rect r = args.rowRect;
                r.x = r.xMax - 15;
                var d = !EditorGUI.Toggle(r, !info.delete);
                if (d != info.delete) {
                    info.delete = d;
                    EditorUtility.SetDirty(atlas);
                }
            } else if (args.item.depth == 2) {
                Rect r = args.rowRect;
                r.x += 60;
                r.width = 300;
                if (args.rowRect.width < 500) {
                    r.width = args.rowRect.width - 200;
                }

                bool e = GUI.enabled;
                if (args.item.displayName == "----") {
                    EditorGUI.BeginChangeCheck();
                    origin = (Sprite)EditorGUI.ObjectField(r, origin, typeof(Sprite), false);
                    if (origin != null && EditorGUI.EndChangeCheck()) {
                        // manual find origin
                        TextureImporter importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(origin.texture)) as TextureImporter;
                        if (importer != null && importer.textureType == TextureImporterType.Sprite && importer.spriteImportMode == SpriteImportMode.Single) {
                            sprite.AddOrigin(origin);
                            sprite.origin = origin;
                            EditorUtility.SetDirty(atlas);
                            Reload();
                        }
                    }
                } else { 
                    GUI.enabled = false;
                    EditorGUI.ObjectField(r, origin, typeof(Sprite), false);
                    GUI.enabled = e;

                    r.x = r.xMax;
                    r.width = 15;

                    bool is_origin = origin == sprite.origin;

                    bool nt = EditorGUI.Toggle(r, is_origin);
                    if (nt != is_origin) {
                        if (is_origin) {
                            sprite.origin = sprite.packed;
                        } else {
                            sprite.origin = origin;
                        }
                        EditorUtility.SetDirty(atlas);
                    }

                    if (sprite.origin == origin) {
                        r.x = r.xMax + 15;
                        r.width = 15;
                        bool nu = EditorGUI.Toggle(r, sprite.update);
                        if (nu != sprite.update) {
                            EditorUtility.SetDirty(atlas);
                            sprite.update = nu;
                        }
                    }

                    int count = (_delegate == null) ? 0 : _delegate.GetReferenceCount(origin);
                    if (count > 0) {
                        Rect re = args.rowRect;
                        re.x = re.xMax - 60;
                        re.width = 60;
                        Color c = DefaultStyles.label.normal.textColor;
                        DefaultStyles.label.normal.textColor = Color.red;
                        EditorGUI.LabelField(re, string.Format("{0}", count));
                        DefaultStyles.label.normal.textColor = c;
                    }
                }
            }
        }


        public override void OnGUI(Rect rect) {
            if (_dirty > 0) {
                _dirty = 0;
                Reload();
            }
            base.OnGUI(rect);
            if (Event.current.type == EventType.MouseDown && Event.current.button == 0 && rect.Contains(Event.current.mousePosition)) {
                SetSelection(new int[0], TreeViewSelectionOptions.FireSelectionChanged);
            }
        }

        protected override bool CanMultiSelect(TreeViewItem item) {
            return multiSelectEnable;
        }

        public List<SpriteAtlasData> GetSpriteAtlasDatasList() {
            IList<int> selectedIds = GetSelection();
            List<SpriteAtlasData> objs = new List<SpriteAtlasData>();
            foreach (int id in selectedIds) {
                SpriteAtlasData atlas = null;
                SpriteAtlasData.SpriteInfo sprite = null;
                Sprite origin = null;

                Get(id, out atlas, out sprite, out origin);

                if (!objs.Contains(atlas)) {
                    objs.Add(atlas);
                }
            }
            return objs;
        }

        void Get(int id, out SpriteAtlasData atlas, out SpriteAtlasData.SpriteInfo sprite, out Sprite origin) {
            int atlasIndex = Mathf.FloorToInt(id / 100000) - 1;
            int spriteIndex = Mathf.FloorToInt(id % 100000 / 100) - 1;
            int originIndex = id % 100 - 1;

            atlas  = null;
            sprite = null;
            origin = null;

            if (atlasIndex >= 0 && atlasIndex < atlasList.Count) {
                atlas = atlasList[atlasIndex];
            }
            if (atlas == null) return;

            if (spriteIndex >= 0) {
                sprite = atlas.sprites[spriteIndex];
            }

            if (originIndex >= 0 && originIndex < sprite.origins.Length) {
                origin = sprite.origins[originIndex];
            }
        }

        public bool GetSelectAtlas(out SpriteAtlasData atlas, out SpriteAtlasData.SpriteInfo sprite, out Sprite origin) {
            atlas = null;
            sprite = null;
            origin = null;

            IList<int> sel = GetSelection();
            if (sel.Count == 0) return false;

            Get(sel[0], out atlas, out sprite, out origin);

            return true;
        }

        protected override void KeyEvent() {
            base.KeyEvent();
            if (GUIUtility.keyboardControl != treeViewControlID) {
                return;
            }

            if (Event.current.type != EventType.KeyDown) {
                return;
            }

            if (GetSelection().Count <= 0) {
                return;
            }

            SpriteAtlasData atlas = null;
            SpriteAtlasData.SpriteInfo sprite = null;
            Sprite origin = null;
            if (!GetSelectAtlas(out atlas, out sprite, out origin)) {
                return;
            }

            if (Event.current.keyCode == KeyCode.Space) {
                if (sprite != null && origin == null) {
                    if (sprite.delete || _refInfo.GetRefCount(sprite.packed) == 0) {
                        sprite.delete = !sprite.delete;
                        Repaint();
                    }
                }
            }

            if (Event.current.keyCode == KeyCode.Delete || Event.current.keyCode == KeyCode.Backspace) {
                if (origin != null) {
                    if (origin.name != sprite.name) {
                        sprite.RemoveOrigin(origin);
                        Reload();
                    }
                } else if (sprite != null) {
                    if (Event.current.control && sprite.packed == null && sprite.delete) {
                        atlas.RemoveSprite(sprite);
                        Reload();
                    } else {
                        sprite.delete = true;
                        Repaint();
                    }
                } else if (atlas) {
                    // _manager.RemoveAtlas(atlas, true);
                    // Reload();
                }
            }

            int use = 0;
            if (Event.current.keyCode == KeyCode.F5) {
                use = 1;
            } else if (Event.current.keyCode == KeyCode.F6) {
                use = 2;
            }

            if ( use != 0  && origin != null && origin == sprite.origin) {
                Sprite from = (use == 1) ? origin : sprite.packed;
                Sprite to = (use == 1) ? sprite.packed : origin;
                if (from == null || to == null || from == to) return;

                List<GameObject> objInfo = _delegate.GetReserenceObjects(from);

                if (objInfo.Count > 0) {
                    List<GameObject> objs = new List<GameObject>();
                    try {
                        for (int i = 0; i < objInfo.Count; i++) {
                            var obj = objInfo[i];
                            EditorUtility.DisplayProgressBar("replace", AssetDatabase.GetAssetPath(obj), i / objInfo.Count);

                            if (obj != null && obj.GetType() == typeof(GameObject)) {
                                GameObject go = obj as GameObject;
                                SpriteReferenceInfo.ScanGameObject(go, (c, p) => {
                                    SpriteReferenceInfo.ReplaceSprite(c, from, to);
                                });
                                EditorUtility.SetDirty(go);
                                objs.Add(go);
                            }
                        }

                        foreach (GameObject go in objs) {
                            SpriteReferenceInfo.Instance.Reload(go);
                        }
                    } catch(System.Exception e) {
                        Debug.LogError(e);
                    } finally {
                        EditorUtility.ClearProgressBar();
                    }
                    Reload();
                }
            }
        }

        protected override void SelectionChanged(IList<int> selectedIds) {
            List<Object> objs = new List<Object>();
            foreach (int id in selectedIds) {
                SpriteAtlasData atlas = null;
                SpriteAtlasData.SpriteInfo sprite = null;
                Sprite origin = null;

                Get(id, out atlas, out sprite, out origin);

                if (origin != null) {
                    objs.Add(origin);
                } else if (sprite != null) {
                    if (sprite.packed != null) {
                        objs.Add(sprite.packed);
                    }

                    if (id % 100 == 0 && select_origin_with_pack && sprite.origin != null && sprite.origin != sprite.packed) {
                        objs.Add(sprite.origin);
                    }
                } else if (atlas != null) {
                    objs.Add(atlas.texture);
                }

                if (_delegate != null) { 
                    if (atlas != null || sprite != null || origin != null) {
                        _delegate.onSelectChange(this, atlas, sprite, origin);
                    }
                }
            }
            Selection.objects = objs.ToArray();
        }

        protected override bool CanStartDrag(CanStartDragArgs args) {
            return args.draggedItem.depth == 1;
        }

        protected override void SetupDragAndDrop(SetupDragAndDropArgs args) {
            base.SetupDragAndDrop(args);

            List<Object> objReferences = new List<Object>();
            foreach(int id in args.draggedItemIDs) {
                SpriteAtlasData atlas;
                SpriteAtlasData.SpriteInfo sprite;
                Sprite origin;
                Get(id, out atlas, out sprite, out origin);
                if (sprite != null && origin == null) {
                    if (sprite.packed != null) {
                        objReferences.Add(sprite.packed);
                    } else if (sprite.origin != null) {
                        objReferences.Add(sprite.origin);
                    }
                }
            }

            if (objReferences.Count <= 0) return;

            DragAndDrop.StartDrag("aaaaa");
            DragAndDrop.objectReferences = objReferences.ToArray();
        }

        protected override DragAndDropVisualMode HandleDragAndDrop(DragAndDropArgs args) {
            if (args.parentItem == null) {
                return DragAndDropVisualMode.Rejected;
            }

            // if (args.parentItem.id == -1) return DragAndDropVisualMode.Rejected;

            SpriteAtlasData atlas;
            SpriteAtlasData.SpriteInfo sprite;
            Sprite origin;

            Get(args.parentItem.id, out atlas, out sprite, out origin);

            List<Texture2D> draging_atlas = new List<Texture2D>();

            Object[] objs = DragAndDrop.objectReferences;

            List<Sprite> sprites = new List<Sprite>();
            foreach (var obj in DragAndDrop.objectReferences) {
                Sprite s = null;
                if (obj.GetType() == typeof(Sprite)) {
                    s = obj as Sprite;
                } else if (obj.GetType() == typeof(Texture2D)) {
                    TextureImporter importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(obj)) as TextureImporter;
                    if (importer.textureType != TextureImporterType.Sprite) {
                        continue;
                    }

                    if (importer.spriteImportMode == SpriteImportMode.Multiple) {
                        draging_atlas.Add(obj as Texture2D);
                        continue;
                    } else {
                        s = AssetDatabase.LoadAssetAtPath<Sprite>(AssetDatabase.GetAssetPath(obj));
                    }
                }

                if (s == null || s.texture == atlas.texture) continue;

                if (atlas.HaveSprite(s.name)) continue;

                sprites.Add(s);
            }

            if (atlas == null) {
                if (draging_atlas.Count == 0) {
                    return DragAndDropVisualMode.Rejected;
                }
            } else {
                if (sprites.Count == 0) {
                    return DragAndDropVisualMode.Rejected;
                }
            }

            if (!args.performDrop) { return DragAndDropVisualMode.Copy; }

            if (atlas == null) {
                foreach(Texture2D tex in draging_atlas) {
                    SpriteAtlasData spriteAtlasData = SpriteAtlasManager.Get(tex);
                    if (!atlasList.Contains(spriteAtlasData)) {
                        atlasList.Add(spriteAtlasData);
                    }
                }
            } else {
                foreach (Sprite s in sprites) {
                    atlas.AddSprite(s);
                }
            }

            DragAndDrop.AcceptDrag();
            Reload();

            return DragAndDropVisualMode.Copy;
        }
    }

    public class ReferenceListView : TreeView
    {
        public ReferenceListView() : base(new TreeViewState() /*, new AssetListTreeHeader()*/) {
        }

        protected override TreeViewItem BuildRoot() {
            TreeViewItem root = new TreeViewItem { id = -1, depth = -1, displayName = "GameObjects", children = new List<TreeViewItem>() };

            for (int i = 0; i < _refs.Count; i++) {
                if (_refs[i] == null) {
                    TreeViewItem parent = new TreeViewItem(i * 1000, 0, "---------------------");
                    root.AddChild(parent);
                } else { 
                    TreeViewItem parent = new TreeViewItem(i * 1000, 0, (_refs[i].obj != null) ? _refs[i].obj.name : "");
                    for (int j = 0; j < _refs[i].paths.Count; j++) {
                        parent.AddChild(new TreeViewItem(i * 1000 + j + 1, 1, _refs[i].paths[j]));
                    }
                    root.AddChild(parent);
                }
            }

            SetupDepthsFromParentsAndChildren(root);
            return root;
        }

        protected override void RowGUI(RowGUIArgs args) {
            if (args.item.depth == 0) {
                Rect r = args.rowRect;
                r.x += 20;
                r.width = 300;
                int id = Mathf.FloorToInt(args.item.id / 1000);
                bool e = GUI.enabled;
                GUI.enabled = false;

                Object obj = null;
                if (id >= 0 && id < refs.Count && refs[id] != null) {
                    obj = refs[id].obj;
                }
                EditorGUI.ObjectField(r, obj, typeof(Object), false);
                GUI.enabled = e;
            } else {
                base.RowGUI(args);
            }
        }

        public override void OnGUI(Rect rect) {
            base.OnGUI(rect);
            if (Event.current.type == EventType.MouseDown && Event.current.button == 0 && rect.Contains(Event.current.mousePosition)) {
                SetSelection(new int[0], TreeViewSelectionOptions.FireSelectionChanged);
            }
        }

        protected override bool CanMultiSelect(TreeViewItem item) {
            return false;
        }

        protected override void SelectionChanged(IList<int> selectedIds) {
            List<Object> objs = new List<Object>();
            foreach (int id in selectedIds) {
                TreeViewItem item = FindItem(id, rootItem);
                if (item != null) {
                    GameObject obj = GameObject.Find(item.displayName);
                    if (obj != null) {
                        objs.Add(obj);
                    }
                }
            }
            Selection.objects = objs.ToArray();
        }

        List<SpriteReferenceInfo.GameObjectInfo> _refs = new List<SpriteReferenceInfo.GameObjectInfo>();
        public List<SpriteReferenceInfo.GameObjectInfo> refs {
            get {
                return _refs;
            }

            set {
                _refs = value;
                if (_refs == null) _refs = new List<SpriteReferenceInfo.GameObjectInfo>();
                Reload();
            }
        }
    }

    AtlasListView m_AtlasListTree;
    ReferenceListView m_ReferenceListView;
    bool scan_scene = false;

    SpriteAtlasData single {
        get {
            SpriteAtlasData s = ScriptableObject.CreateInstance<SpriteAtlasData>();
            s.name = "Sprite";
            List<Sprite> list = SpriteReferenceInfo.Instance.Top(100);
            for(int i = 0; i < list.Count; i++) { 
                s.AddSprite(list[i]);
            }
            return s;
        }
    }

    [MenuItem("Tools/Sprite Atlas Manager")]
    static void OpenTexturePacker() {
        GetWindow<SpriteAtlasManagerWindow>(false, "Sprite Atlas Manager", true).Init();
    }
    
    void Init() {
        manager = AssetDatabase.LoadAssetAtPath<SpriteAtlasManager>("Assets/Editor/SpriteAtlasManager.asset");
        if (manager == null) {
            manager = ScriptableObject.CreateInstance<SpriteAtlasManager>();
            AssetDatabase.CreateAsset(manager, "Assets/Editor/SpriteAtlasManager.asset");
        }
        manager.Reload();

        SpriteReferenceInfoDetector.watchEditorChange = true;

        foreach (var atlas in manager.atlas) {
            foreach(var sprite in atlas.sprites) {
                sprite.Cleanup();
            }
        }
    }

    static public bool DrawHeader(string text, bool forceOn = false) {
        return DrawHeader(text, text, forceOn);
    }

    static public bool DrawHeader(string text, string key, bool forceOn = false) {
        bool state = EditorPrefs.GetBool(key, true);

        GUILayout.Space(3f);
        if (!forceOn && !state) GUI.backgroundColor = new Color(0.8f, 0.8f, 0.8f);
        GUILayout.BeginHorizontal();
        GUILayout.Space(3f);

        GUI.changed = false;
#if UNITY_3_5
		if (!GUILayout.Toggle(true, text, "dragtab")) state = !state;
#else
        if (!GUILayout.Toggle(true, "<b><size=11>" + text + "</size></b>", "dragtab")) state = !state;
#endif
        if (GUI.changed) EditorPrefs.SetBool(key, state);

        GUILayout.Space(2f);
        GUILayout.EndHorizontal();
        GUI.backgroundColor = Color.white;
        if (!forceOn && !state) GUILayout.Space(3f);
        return state;
    }

    Vector2 mScroll;

    void OnGUI() {
        if (Application.isPlaying) {
            GUILayout.Label("playing");
            SpriteReferenceInfoDetector.watchEditorChange = false;
            return;
        }

        GUILayout.BeginHorizontal();
        bool scanAtlas = GUILayout.Button("Scan Atlas", GUILayout.Width(100));
        bool scanGameObject = GUILayout.Button("Scan Reference", GUILayout.Width(100));
        bool updateAtlas = GUILayout.Button("Update Atlas", GUILayout.Width(100));
        SpriteReferenceInfoDetector.watchEditorChange = GUILayout.Toggle(SpriteReferenceInfoDetector.watchEditorChange, "watching");
        scan_scene = GUILayout.Toggle(scan_scene, "scan scene");
        GUILayout.FlexibleSpace();
        GUILayout.EndHorizontal();

        Rect atlasRect = new Rect(0, 30, position.width / 2 - 5, position.height);

        if (m_AtlasListTree == null) {
            m_AtlasListTree = new AtlasListView(this);
            ReloadTreeView();
        }
        m_AtlasListTree.OnGUI(atlasRect);

        if (m_ReferenceListView == null) {
            m_ReferenceListView = new ReferenceListView();
            m_ReferenceListView.Reload();
        }

        Rect refRect = new Rect(position.width / 2 + 5, 30, position.width / 2 - 5, position.height);
        m_ReferenceListView.OnGUI(refRect);

        if (scanAtlas) {
            ScanSpriteAtlas();
        }

        if (scanGameObject) {
            SpriteReferenceInfo.Instance.Scan(scan_scene);
        }

        if (updateAtlas) {
            SpriteAtlasData atlas = null;
            SpriteAtlasData.SpriteInfo sprite = null;
            Sprite origin = null;
            if (m_AtlasListTree.GetSelectAtlas(out atlas, out sprite, out origin)) {
                TexturePacker.Pack(atlas.sprites, atlas.texture);
                atlas.Scan();
            }
        }
    }

    private void OnDestroy() {
        SpriteReferenceInfoDetector.watchEditorChange = false;
        SpriteReferenceInfo.ReleaseInstance();
        manager = null;
    }

    protected SpriteAtlasManager manager = null;

    void ScanSpriteAtlas() {
        manager.Scan(false);
        ReloadTreeView();
    }
    
    void ReloadTreeView() {
        if (m_AtlasListTree != null) {
            List<SpriteAtlasData> list = new List<SpriteAtlasData>(manager.atlas);
            list.Add(single);
            m_AtlasListTree.atlasList = list;
            m_AtlasListTree.Reload();
        }
    }

    public void onSelectChange(AtlasListView view, SpriteAtlasData atlas, SpriteAtlasData.SpriteInfo sprite, Sprite origin) {
        if (m_ReferenceListView == null) return;

        // m_ReferenceListView = new ReferenceListView();
        // m_ReferenceListView.Reload();

        if (origin != null) {
            var r = SpriteReferenceInfo.Instance.FindSpriteInfo(origin);
            m_ReferenceListView.refs = (r != null) ? r.objInfo : null;
        } else if (sprite != null) {
            var r = SpriteReferenceInfo.Instance.FindSpriteInfo(sprite.packed);
            m_ReferenceListView.refs = (r != null) ? r.objInfo : null;
        } else {
            m_ReferenceListView.refs = null;
        }

        m_ReferenceListView.ExpandAll();
    }

    public int GetReferenceCount(Sprite sprite) {
        return SpriteReferenceInfo.Instance.GetRefCount(sprite);
    }

    public List<GameObject> GetReserenceObjects(Sprite sprite) {
        List<GameObject> list = new List<GameObject>();

        var r = SpriteReferenceInfo.Instance.FindSpriteInfo(sprite);

        if (r.objInfo != null) {
            foreach (var info in r.objInfo) {
                if (info.obj.GetType() == typeof(GameObject)) {
                    list.Add(info.obj as GameObject);
                }
            }
        }
        return list;
    }
}
