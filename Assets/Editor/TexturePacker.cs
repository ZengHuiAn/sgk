using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;
using UnityEditor.IMGUI.Controls;


public class TexturePacker : EditorWindow, SpriteAtlasManagerWindow.AtlasListView.IDelegate {
    SpriteAtlasManagerWindow.AtlasListView m_AssetList;
    SpriteAtlasManagerWindow.ReferenceListView m_refList;
    // ReferenceListView m_ReferenceListView;

    [MenuItem("Tools/Texture Packer")]
    static void OpenTexturePacker() {
        var win = EditorWindow.GetWindow<TexturePacker>(false, "Texture Packer", true);
        win.Close();

        win = EditorWindow.GetWindow<TexturePacker>(false, "Texture Packer", true);
        win.Init();
        win.Show();
    }

    List<GameObject> targetGameObjects = new List<GameObject>();
    List<SpriteAtlasData> atlas = new List<SpriteAtlasData>();
    // List<Sprite> single_sprites = new List<Sprite>();

    Dictionary<string, List<SpriteReferenceInfo.GameObjectInfo>> refInfo = new Dictionary<string, List<SpriteReferenceInfo.GameObjectInfo>>();

    bool __debug = false;

    void Init() {
        atlas.Clear();
        targetGameObjects.Clear();

        if (Selection.activeGameObject != null) {
            targetGameObjects.Add(Selection.activeGameObject);
            ScanGameObject(Selection.activeGameObject);
        }

        Reload();
    }

    void Reload() {
        atlas.Clear();
        refInfo.Clear();
        // single_sprites.Clear();

        if (__debug) { // debug
            string[] mapSceneUI = {
                "prefabs/mapSceneUI/mapSceneUI.prefab",
                "prefabs/mapSceneUI/QuestGuideTip.prefab",
                "prefabs/mapSceneUI/MainUITeam.prefab",
                "prefabs/mapSceneUI/WorldBossBuffList.prefab",
                "prefabs/mapSceneUI/mapSceneQuestList.prefab",
/*
"prefabs/battlefield/BattleDialog.prefab",
"prefabs/battlefield/BuffTips.prefab",
"prefabs/battlefield/MonsterInfo.prefab",
"prefabs/battlefield/pet.prefab",
"prefabs/battlefield/pet_enemy.prefab",
"prefabs/battlefield/RandomBuffSlots.prefab",
"prefabs/battlefield/ItemBoxPanel.prefab",
"prefabs/battlefield/randomBuffItem.prefab",
"prefabs/fightResult/FightResultFrame.prefab",
"prefabs/battlefield/storyloading.prefab",
"prefabs/battlefield/enemy.prefab",
"prefabs/battlefield/enemy2.prefab",
"prefabs/battlefield/enemy2.prefab",
"prefabs/battlefield/enemy2.prefab",
"prefabs/battlefield/enemy2.prefab",
"prefabs/battlefield/enemyBoss.prefab",
"prefabs/battlefield/BattlefieldTargetRingMenu.prefab",
"prefabs/battlefield/RoleInfoPanel.prefab",
"prefabs/battlefield/RoleInfoPanel.prefab",
"prefabs/battlefield/TeamMembers.prefab",
"prefabs/base/FightingBtn.prefab",
"prefabs/battlefield/randomBuffItem.prefab",
"prefabs/battlefield/randomHeroBuffItem.prefab",
*/
            };

            targetGameObjects.Clear();
            foreach (string s in mapSceneUI) {
                string debug_prefab = "Assets/assetbundle/" + s;
                if (!string.IsNullOrEmpty(debug_prefab) && (Selection.activeGameObject == null || AssetDatabase.GetAssetPath(Selection.activeGameObject) != debug_prefab)) {
                    GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(debug_prefab);
                    targetGameObjects.Add(obj);
                }
            }
            targetTexture = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/UI8/mapScene/mapSceneUI.png");
        }

        SpriteAtlasData single = ScriptableObject.CreateInstance<SpriteAtlasData>();
        single.name = "Sprites";
        foreach (GameObject obj in targetGameObjects) {
            var list = ScanGameObject(obj);
            foreach(var s in list) {
                string path = AssetDatabase.GetAssetPath(s.texture);
                if (path.StartsWith("Assets/assetbundle/")) continue;

                TextureImporter importer = AssetImporter.GetAtPath(path) as TextureImporter;
                if (importer == null || (importer.textureType == TextureImporterType.Sprite && importer.spriteImportMode == SpriteImportMode.Multiple)) {
                    continue;
                }

                if (!single.HaveSprite(s)) { 
                    single.AddSprite(s);
                }
            }
        }

        if (single.sprites != null && single.sprites.Length > 0) {
            atlas.Add(single);
        }

        ReloadTreeView();
    }

    string GetSpriteKey(Sprite sprite) {
        if (sprite == null) return "-";
        string path = AssetDatabase.GetAssetPath(sprite.texture);
        return sprite.name + "@" + path;
    }

    List<Sprite> ScanGameObject(GameObject obj) {
        List<Sprite> single = new List<Sprite>();
        if (obj != null) {
            SpriteReferenceInfo.ScanGameObjectSprite(obj, (o, s, p) => {
                string key = GetSpriteKey(s);

                List<SpriteReferenceInfo.GameObjectInfo> _refs;
                if (!refInfo.TryGetValue(key, out _refs)) {
                    _refs = new List<SpriteReferenceInfo.GameObjectInfo>();
                    refInfo[key] = _refs;
                    var oi = _refs.Find((i) => i.obj == obj);
                    if (oi == null) {
                        var info = new SpriteReferenceInfo.GameObjectInfo(obj);
                        info.paths.Add(p);
                        _refs.Add(info);
                    } else {
                        oi.paths.Add(p);
                    }
                }

                SpriteAtlasData a = SpriteAtlasManager.Get(s.texture);
                if (a != null ) {
                    if (!atlas.Contains(a)) {
                        atlas.Add(a);
                    }
                } else {
                    if (!single.Contains(s)) {
                        single.Add(s);
                    }
                }
            });
        }
        return single;
    }

    Texture2D targetTexture = null;
    void OnGUI() {
        List<GameObject> newObjectList = new List<GameObject>();

        bool pack = false;
        bool reload = false;
        bool update_sprite = false;

        if (m_AssetList == null) {
            m_AssetList = new SpriteAtlasManagerWindow.AtlasListView(this);
            m_AssetList.select_origin_with_pack = true;
            m_AssetList.multiSelectEnable = true;
            ReloadTreeView();
        }

        /*
        if (m_ReferenceListView == null) {
            m_ReferenceListView = new ReferenceListView();
            m_ReferenceListView.refs = single_sprites;
        }
        */

        if (m_refList == null) {
            m_refList = new SpriteAtlasManagerWindow.ReferenceListView();
            m_refList.Reload();
        }

        GUILayout.BeginVertical();
        {
            GUILayout.BeginHorizontal();
            {
                targetTexture = (Texture2D)EditorGUILayout.ObjectField(targetTexture, typeof(Texture2D), false);


                if (GUILayout.Button("Reload")) {
                    reload = true;
                }

                if (GUILayout.Button("Update Atlas")) {
                    pack = true;
                }


                if (GUILayout.Button("Update Sprite")) {
                    update_sprite = true;
                }

                if (GUILayout.Toggle(__debug, "debug") != __debug) {
                    __debug = !__debug;
                    Reload();
                }
            }
            GUILayout.EndHorizontal();

            GUILayout.Space(20);

            GUILayout.BeginHorizontal();
            {
                GUILayout.BeginVertical();
                for (int i = 0; i < targetGameObjects.Count; i++) {
                    newObjectList.Add((GameObject)EditorGUILayout.ObjectField(targetGameObjects[i], typeof(GameObject), true));
                }

                GameObject obj = (GameObject)EditorGUILayout.ObjectField(null, typeof(GameObject), true);
                if (obj != null) {
                    newObjectList.Add(obj);
                }

                GUILayout.EndVertical();

                GUILayout.Space(position.width - 120);
            }
            GUILayout.EndHorizontal();

            
        }
        GUILayout.EndVertical();


        Rect r = new Rect(
            150, 40,
            (position.width - 150) / 2, (position.height - 40));

        m_AssetList.OnGUI(r);

        /*
        Rect s = r;
        s.y = s.yMax;
        m_ReferenceListView.OnGUI(s);
        r.height = position.height - 40;
        */

        r.x = r.xMax + 10;
        
        m_refList.OnGUI(r);

        bool changed = false;
        for (int i = 0; i < newObjectList.Count; i++) {
            if (i < targetGameObjects.Count) {
                if (newObjectList[i] != targetGameObjects[i]) {
                    if (newObjectList[i] != null) {
                        if (!targetGameObjects.Contains(newObjectList[i])) {
                            ScanGameObject(newObjectList[i]);
                        }
                    }
                    changed = true;
                }
                targetGameObjects[i] = newObjectList[i];
            } else if (newObjectList[i] != null) {
                targetGameObjects.Add(newObjectList[i]);
                ScanGameObject(newObjectList[i]);
                changed = true;
            }
        }

        if (changed) {
            ReloadTreeView();
        } else if (pack) {
            List<SpriteAtlasData> data = m_AssetList.GetSpriteAtlasDatasList();
            List<SpriteAtlasData.SpriteInfo> list = new List<SpriteAtlasData.SpriteInfo>();
            foreach(var d in data) {
                list.AddRange(d.sprites);
            }
            
            Pack(list.ToArray(), targetTexture);
        } else if (reload) {
            Reload();
        }

        if (update_sprite) {
            List<SpriteAtlasData> data = m_AssetList.GetSpriteAtlasDatasList();
            foreach (GameObject o in targetGameObjects) {
                if (o != null) {
                    foreach (SpriteAtlasData d in data) {
                        foreach (SpriteAtlasData.SpriteInfo info in d.sprites) {
                            if (info.packed != null && info.origin != null && info.origin != info.packed) {
                                SpriteReferenceInfo.ScanGameObject(o, (c, p) => SpriteReferenceInfo.ReplaceSprite(c, info.origin, info.packed));
                            }
                        }
                    }
                    EditorUtility.SetDirty(o);
                }
            }
            Reload();
        }
    }

    /*
    bool resize = false;
    Rect cursorChangeRect;
    float currentGameObjectViewWidth;
    private void ResizeScrollView() {
        GUI.DrawTexture(cursorChangeRect, EditorGUIUtility.whiteTexture);
        EditorGUIUtility.AddCursorRect(cursorChangeRect, MouseCursor.ResizeVertical);

        if (Event.current.type == EventType.MouseDown && cursorChangeRect.Contains(Event.current.mousePosition)) {
            resize = true;
        }
        if (resize) {
            currentGameObjectViewWidth = Event.current.mousePosition.x;
            cursorChangeRect.Set(currentGameObjectViewWidth, cursorChangeRect.y, cursorChangeRect.width, cursorChangeRect.height);
        }
        if (Event.current.type == EventType.MouseUp)
            resize = false;
    }
    */

    void ReloadTreeView() {
        if (m_AssetList != null) {
            m_AssetList.atlasList = atlas;
            m_AssetList.Reload();
        }

        /*
        if (m_ReferenceListView != null) {
            m_ReferenceListView.refs = single_sprites;
        }
        */
    }

    void AddSprite(Sprite sprite) {
    }

    bool DrawObject(Object tex, int index) {
        GUILayout.BeginHorizontal(GUILayout.MinHeight(20f));

        GUILayout.Label(index.ToString(), GUILayout.Width(24f));

        EditorGUILayout.ObjectField(tex, typeof(Object), false);
        bool remove = false;
        if (GUILayout.Button("X", GUILayout.Width(22f))) {
            remove = true;
        }

        GUILayout.EndHorizontal();
        return remove;
    }

    public static Texture2D Pack(SpriteAtlasData.SpriteInfo [] sprites, Texture2D targetTexture) {
        List<Texture2D> textures = new List<Texture2D>();
        List<SpriteMetaData> metaDatas = new List<SpriteMetaData>();

        string output_path = null;
        if (targetTexture != null) {
            output_path = AssetDatabase.GetAssetPath(targetTexture);
            targetTexture = null;
        }

        if (string.IsNullOrEmpty(output_path)) {
            output_path = "Assets/atlas.png";
        }

        try {
            List<string> changedTexture = new List<string>();
            for (int i = 0; i < sprites.Length; i++) {
                string info = "+ " + sprites[i].name;
                if (!sprites[i].update) {
                    info = "- " + sprites[i].name;
                }

                string packed_name = sprites[i].name;

                if (EditorUtility.DisplayCancelableProgressBar(string.Format("process {0} / {1}", i + 1, sprites.Length), info, i * 0.5f / sprites.Length)) {
                    EditorUtility.ClearProgressBar();
                    return null;
                }

                if (sprites[i].delete) {
                    continue;
                }

                Sprite sprite = sprites[i].packed;
                Vector4 border = (sprites[i].packed == null) ? Vector4.zero : sprites[i].packed.border;
                if (sprites[i].origin != null && sprites[i].update) {
                    sprite = sprites[i].origin;
                    if (sprite.border.sqrMagnitude != 0) {
                        border = sprite.border;
                    }
                }

                if (sprite == null) {
                    continue;
                }

                string stPath = AssetDatabase.GetAssetPath(sprite.texture);
                TextureImporter spriteImporter = AssetImporter.GetAtPath(stPath) as TextureImporter;
                if (spriteImporter.textureType == TextureImporterType.Default) {
                    textures.Add(RemporTexture(sprite.texture, ref changedTexture));
                    metaDatas.Add(newSpriteMetaData(packed_name, border));
                    continue;
                }

                if (spriteImporter.textureType != TextureImporterType.Sprite) {
                    continue;
                }

                if (spriteImporter.spriteImportMode == SpriteImportMode.Single) {
                    textures.Add(RemporTexture(sprite.texture, ref changedTexture));
                    metaDatas.Add(newSpriteMetaData(packed_name, border));
                    continue;
                }

                if (spriteImporter.spriteImportMode != SpriteImportMode.Multiple) {
                    continue;
                }

                Texture2D readableTexture = RemporTexture(sprite.texture, ref changedTexture);
                Texture2D tex = new Texture2D((int)sprite.rect.width, (int)sprite.rect.height, sprite.texture.format, false);

                Graphics.CopyTexture(
                    readableTexture, 0, 0,
                    (int)sprite.rect.x, (int)sprite.rect.y, (int)sprite.rect.width, (int)sprite.rect.height,
                    tex, 0, 0, 0, 0);
                tex.Apply();

                textures.Add(tex);
                metaDatas.Add(newSpriteMetaData(packed_name, border));
            }

            EditorUtility.DisplayProgressBar("packing", output_path, 0.5f);

            Texture2D finalTexture = new Texture2D(1, 1, TextureFormat.ARGB32, false);
            Rect[] rects = finalTexture.PackTextures(textures.ToArray(), 2, 2048);

            Debug.LogFormat("finalTexture {0} {1}", finalTexture.width, finalTexture.height);

            byte[] bytes = finalTexture.EncodeToPNG();
            System.IO.File.WriteAllBytes(output_path, bytes);
            bytes = null;

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            TextureImporter importer = AssetImporter.GetAtPath(output_path) as TextureImporter;
            importer.textureType = TextureImporterType.Sprite;
            importer.spriteImportMode = SpriteImportMode.Multiple;
            importer.alphaIsTransparency = true;

            finalTexture = AssetDatabase.LoadAssetAtPath<Texture2D>(output_path);

            SpriteMetaData[] metaData = new SpriteMetaData[rects.Length];
            for (int i = 0; i < rects.Length; i++) {
                metaData[i] = new SpriteMetaData();
                metaData[i].name = metaDatas[i].name;
                metaData[i].rect = ConvertToPixels(rects[i], finalTexture.width, finalTexture.height);
                metaData[i].border = metaDatas[i].border;
                metaData[i].pivot = metaDatas[i].pivot;
            }

            importer.spritesheet = metaData;
            importer.SaveAndReimport();

            for (int i = 0; i < changedTexture.Count; i++) {
                EditorUtility.DisplayProgressBar(string.Format("revert {0} / {1}", i + 1, changedTexture.Count), changedTexture[i], 0.5f + i * 0.5f / changedTexture.Count);
                MakeTextureReadable(changedTexture[i], false);
            }
        } catch (System.Exception e) {
            Debug.LogError(e);
            EditorUtility.ClearProgressBar();
            return null;
        }

        EditorUtility.ClearProgressBar();

        return AssetDatabase.LoadAssetAtPath<Texture2D>(output_path);
    }

    [MenuItem("Tools/ClearProgressBar")]
    public static void ClearProgressBar() {
        EditorUtility.ClearProgressBar();
    }

    static public Rect ConvertToPixels(Rect rect, int width, int height) {
        Rect final = new Rect();

        final.x = Mathf.RoundToInt(rect.x * width);
        final.width = Mathf.RoundToInt(rect.width * width);


        final.y = Mathf.RoundToInt(rect.y * height);
        final.height = Mathf.RoundToInt(rect.height * height);

        return final;
    }


    static SpriteMetaData newSpriteMetaData(string name) {
        return newSpriteMetaData(name, new Vector2(0.5f, 0.5f), Vector4.zero);
    }

    static SpriteMetaData newSpriteMetaData(string name, Vector2 pivot) {
        return newSpriteMetaData(name, pivot, Vector4.zero);
    }

    static SpriteMetaData newSpriteMetaData(string name, Vector4 border) {
        return newSpriteMetaData(name, new Vector2(0.5f, 0.5f), border);
    }

    static SpriteMetaData newSpriteMetaData(string name, Vector2 pivot, Vector4 border) {
        SpriteMetaData data = new SpriteMetaData();
        data.name = name;
        data.pivot = pivot;
        data.border = border;

        return data;
    }

    static bool MakeTextureReadable(Texture2D tex, bool readable) {
        if (tex == null) return false;
        return MakeTextureReadable(AssetDatabase.GetAssetPath(tex), readable);
    }

    static bool MakeTextureReadable(string path, bool readable) {
        if (string.IsNullOrEmpty(path)) return false;
        TextureImporter ti = AssetImporter.GetAtPath(path) as TextureImporter;
        if (ti == null) return false;

        TextureImporterCompression compression = readable ? TextureImporterCompression.Uncompressed : TextureImporterCompression.Compressed;

        if (ti.isReadable != readable || ti.textureCompression != compression) {
            ti.isReadable = readable;
            ti.textureCompression = compression;
            ti.SaveAndReimport();
            return true;
        }
        return false;
    }

    static Texture2D RemporTexture(Texture2D tex, ref List<string> changedList) {
        if (tex == null) return null;
        string path = AssetDatabase.GetAssetPath(tex);
        bool changed = MakeTextureReadable(path, true);
        Texture2D nt = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
        if (changed) {
            changedList.Add(path);
        }
        return nt;
    }

    public void onSelectChange(SpriteAtlasManagerWindow.AtlasListView view, SpriteAtlasData data, SpriteAtlasData.SpriteInfo si, Sprite s) {
        if (s == null && si != null) {
            s = si.packed;
        }

        string key = GetSpriteKey(s);

        List<SpriteReferenceInfo.GameObjectInfo> list;
        if (refInfo.TryGetValue(key, out list)) {
            m_refList.refs = list;
        } else {
            m_refList.refs = new List<SpriteReferenceInfo.GameObjectInfo>();
        }
        m_refList.Reload();
        m_refList.ExpandAll();
        return;
    }

    public int GetReferenceCount(Sprite sprite) {
        string key = GetSpriteKey(sprite);
        List<SpriteReferenceInfo.GameObjectInfo> list;
        if (refInfo.TryGetValue(key, out list)) {
            return list.Count;
        }
        return 0;
    }

    public List<GameObject> GetReserenceObjects(Sprite sprite) {
        List<GameObject> ret_list = new List<GameObject>();

        string key = GetSpriteKey(sprite);
        List<SpriteReferenceInfo.GameObjectInfo> list;
        if (refInfo.TryGetValue(key, out list)) {
            foreach(var info in list) {
                if (info.obj.GetType() == typeof(GameObject)) {
                    ret_list.Add(info.obj as GameObject);
                }
            }
        }

        return ret_list;
    }

    private void OnDestroy() {
        foreach (SpriteAtlasData data in atlas) {
            EditorUtility.SetDirty(data);
        }
    }

    class ReferenceListView : TreeView
    {
        public ReferenceListView() : base(new TreeViewState() /*, new AssetListTreeHeader()*/) {
        }

        protected override TreeViewItem BuildRoot() {
            TreeViewItem root = new TreeViewItem { id = -1, depth = -1, displayName = "GameObjects", children = new List<TreeViewItem>() };

            for (int i = 0; i < _refs.Count; i++) {
                root.AddChild(new TreeViewItem(i, 0, (_refs[i] != null) ? _refs[i].name : ""));
            }

            SetupDepthsFromParentsAndChildren(root);
            return root;
        }

        protected override void RowGUI(RowGUIArgs args) {
            Rect r = args.rowRect;
            r.x += 20;
            r.width = 300;

            bool e = GUI.enabled;
            GUI.enabled = false;
            EditorGUI.ObjectField(r, refs[args.item.id], typeof(Sprite), false);
            GUI.enabled = e;
        }

        public override void OnGUI(Rect rect) {
            base.OnGUI(rect);
            if (Event.current.type == EventType.MouseDown && Event.current.button == 0 && rect.Contains(Event.current.mousePosition)) {
                SetSelection(new int[0], TreeViewSelectionOptions.FireSelectionChanged);
            }
        }

        protected override bool CanMultiSelect(TreeViewItem item) {
            return true;
        }

        protected override void SelectionChanged(IList<int> selectedIds) {
            /*
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
            */
        }

        List<Sprite> _refs = new List<Sprite>();
        public List<Sprite> refs {
            get {
                return _refs;
            }

            set {
                _refs = value;
                if (_refs == null) _refs = new List<Sprite>();
                Reload();
            }
        }


        protected override bool CanStartDrag(CanStartDragArgs args) {
            return args.draggedItem.depth == 0;
        }

        protected override void SetupDragAndDrop(SetupDragAndDropArgs args) {
            List<Object> objReferences = new List<Object>();
            foreach (int id in args.draggedItemIDs) {
                Sprite sprite = refs[id];
                if (sprite != null) {
                    objReferences.Add(sprite);
                }
            }

            if (objReferences.Count == 0) { return; }

            DragAndDrop.StartDrag(string.Format("{0}", objReferences.Count));
            DragAndDrop.objectReferences = objReferences.ToArray();
        }

        protected override DragAndDropVisualMode HandleDragAndDrop(DragAndDropArgs args) {
            return DragAndDropVisualMode.Rejected;
        }
    }
}
