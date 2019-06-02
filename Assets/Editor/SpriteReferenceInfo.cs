using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;


[CreateAssetMenu(fileName = "SpriteReferenceInfo", menuName = "config/Sprite Reference Info", order = 2)]
public class SpriteReferenceInfo : ScriptableObject
{
    [System.Serializable]
    public class GameObjectInfo
    {
        public Object _obj;
        public Object obj {
            get {
                return _obj;
            }
        }

        public string name;

        public List<string> paths;
        public GameObjectInfo(Object obj) {
            _obj = obj;
            name = obj.name;
            paths = new List<string>();
        }

        public void AddPath(string path) {
            if (!paths.Contains(path)) {
                paths.Add(path);
            }
        }
    }

    [System.Serializable]
    public class SpriteInfo
    {

        public string name;
        public Sprite sprite;
        public List<GameObjectInfo> objInfo;
        public SpriteInfo(Sprite sprite) {
            this.sprite = sprite;
            name = Key;
            objInfo = new List<GameObjectInfo>();
        }

        public void AddObject(Object root, string path) {
            GameObjectInfo info = objInfo.Find((o) => {
                return o._obj == root;
            });

            if (info == null) {
                info = new GameObjectInfo(root);
                objInfo.Add(info);
            }
            info.AddPath(path);
        }

        public string Key {
            get { return GetKey(sprite); }
        }

        public static string GetKey(Sprite sprite) {
            if (sprite == null) return "";

            string path = AssetDatabase.GetAssetPath(sprite.texture);
            if (sprite.rect.width >= sprite.texture.width && sprite.rect.height >= sprite.texture.height && sprite.rect.x <= 0 && sprite.rect.y <= 0) {
                return path;
            } else {
                return path + ":" + sprite.name;
            }
        }
    }

    [SerializeField]
    List<SpriteInfo> sprites = new List<SpriteInfo>();

    Dictionary<string, SpriteInfo> caches = null;

    public SpriteInfo FindSpriteInfo(Sprite sprite) {
        if (caches == null) {
            caches = new Dictionary<string, SpriteInfo>();
            foreach (SpriteInfo ite in sprites) {
                caches[ite.Key] = ite;
            }
        }

        SpriteInfo info;
        if (caches.TryGetValue(SpriteInfo.GetKey(sprite), out info)) {
            return info;
        }
        return null;
    }

    public int GetRefCount(Sprite sprite) {
        if (sprite == null) return 0;
        SpriteInfo info = FindSpriteInfo(sprite);
        if (info == null || info.objInfo == null) return 0;
        return info.objInfo.Count;
    }

    SpriteInfo GetSpriteInfo(Sprite sprite) {
        SpriteInfo info = FindSpriteInfo(sprite);
        if (info == null) {
            info = new SpriteInfo(sprite);
            sprites.Add(info);
            if (caches != null) {
                caches[info.Key] = info;
            }
        }
        return info;
    }

    void addSprite(Sprite sprite, Object root, string path) {
        if (sprite != null && sprite.texture != null) {
            string t_path = AssetDatabase.GetAssetPath(sprite.texture);
            if (string.IsNullOrEmpty(t_path)) return;
            if (t_path == "Resources/unity_builtin_extra") return;

            SpriteInfo info = GetSpriteInfo(sprite);
            info.AddObject(root, path);
        }
    }

    public static List<string> findSpritePropertyName(Component c) {
        List<string> names = new List<string>();
        System.Reflection.PropertyInfo[] propertys = c.GetType().GetProperties();
        foreach (var prop in propertys) {
            if (prop.PropertyType == typeof(Sprite)) {
                names.Add(prop.Name);
            } else if (prop.PropertyType == typeof(Sprite[])) {
                names.Add(prop.Name);
            } else if (prop.PropertyType == typeof(List<Sprite>)) {
                names.Add(prop.Name);
            }
        }

        System.Reflection.FieldInfo[] fields = c.GetType().GetFields();
        foreach (var field in fields) {
            if (field.FieldType == typeof(Sprite)) {
                names.Add(field.Name);
            } else if (field.FieldType == typeof(Sprite[])) {
                names.Add(field.Name);
            } else if (field.FieldType == typeof(List<Sprite>)) {
                names.Add(field.Name);
            }
        }
        return names;
    }

    public static void ReplaceSprite(GameObject obj, Sprite from, Sprite to) {
        Component[] coms = obj.GetComponents<Component>();
        foreach (Component c in coms) {
            if (c == null) continue;

            // SerializedObject serializedObject = new SerializedObject(c);
            //  serializedObject.FindProperty("");

            System.Reflection.PropertyInfo[] propertys = c.GetType().GetProperties();
            foreach (var prop in propertys) {
                if (prop.PropertyType == typeof(Sprite)) {
                    Sprite s = prop.GetValue(c, new object[] { }) as Sprite;
                    if (s != null && s == from) {
                        prop.SetValue(c, to, new object[] { });
                    }
                } else if (prop.PropertyType == typeof(Sprite[])) {
                    Sprite[] os = prop.GetValue(c, new object[] { }) as Sprite[];
                    for (int i = 0; i < os.Length; i++) {
                        Sprite s = os[i];
                        if (s != null && s == from) {
                            os[i] = to;
                        }
                    }
                } else if (prop.PropertyType == typeof(List<Sprite>)) {
                    List<Sprite> os = prop.GetValue(c, new object[] { }) as List<Sprite>;
                    for (int i = 0; i < os.Count; i++) {
                        Sprite s = os[i];
                        if (s != null && s == from) {
                            os[i] = to;
                        }
                    }
                }
            }

            System.Reflection.FieldInfo[] fields = c.GetType().GetFields();
            foreach (var field in fields) {
                if (field.FieldType == typeof(Sprite)) {
                    Sprite s = field.GetValue(c) as Sprite;
                    if (s != null && s == from) {
                        field.SetValue(c, to);
                    }
                } else if (field.FieldType == typeof(Sprite[])) {
                    Sprite[] os = field.GetValue(c) as Sprite[];
                    for (int i = 0; i < os.Length; i++) {
                        Sprite s = os[i];
                        if (s != null && s == from) {
                            os[i] = to;
                        }
                    }
                } else if (field.FieldType == typeof(List<Sprite>)) {
                    List<Sprite> os = field.GetValue(c) as List<Sprite>;
                    for (int i = 0; i < os.Count; i++) {
                        Sprite s = os[i];
                        if (s != null && s == from) {
                            os[i] = to;
                        }
                    }
                }
            }
        }
    }


    public static void FindSprite(GameObject obj, System.Action<Sprite> callback) {
        Component[] coms = obj.GetComponents<Component>();
        foreach (Component c in coms) {
            if (c == null) continue;

            System.Reflection.PropertyInfo[] propertys = c.GetType().GetProperties();
            foreach (var prop in propertys) {
                if (prop.PropertyType == typeof(Sprite)) {
                    Sprite s = prop.GetValue(c, new object[] { }) as Sprite;
                    if (s != null && callback != null) {
                        callback(s);
                    }
                } else if (prop.PropertyType == typeof(Sprite[])) {
                    Sprite[] os = prop.GetValue(c, new object[] { }) as Sprite[];
                    foreach (Sprite s in os) {
                        if (s != null && callback != null) {
                            callback(s);
                        }
                    }
                } else if (prop.PropertyType == typeof(List<Sprite>)) {
                    List<Sprite> os = prop.GetValue(c, new object[] { }) as List<Sprite>;
                    foreach (Sprite s in os) {
                        if (s != null && callback != null) {
                            callback(s);
                        }
                    }
                }
            }

            System.Reflection.FieldInfo[] fields = c.GetType().GetFields();
            foreach (var field in fields) {
                if (field.FieldType == typeof(Sprite)) {
                    Sprite s = field.GetValue(c) as Sprite;
                        if (s != null && callback != null) {
                            callback(s);
                        }
                    
                } else if (field.FieldType == typeof(Sprite[])) {
                    Sprite[] os = field.GetValue(c) as Sprite[];
                    foreach (Sprite s in os) {
                        if (s != null && callback != null) {
                            callback(s);
                        }
                    }
                } else if (field.FieldType == typeof(List<Sprite>)) {
                    List<Sprite> os = field.GetValue(c) as List<Sprite>;
                    foreach (Sprite s in os) {
                        if (s != null && callback != null) {
                            callback(s);
                        }
                    }
                }
            }
        }
    }

    public static void ScanGameObjectSprite(GameObject obj, System.Action<GameObject, Sprite, string> callback) {
        ScanGameObject(obj, (o, p) => FindSprite(o, s => callback(o, s, p) ));
    }

    public static void ScanGameObject(GameObject obj, System.Action<GameObject, string> callback, string path = "") {
        if (obj == null) return;
        if (callback == null) return;

        if (string.IsNullOrEmpty(path)) {
            path = obj.name;
        } else {
            path += "/" + obj.name;
        }

        callback(obj, path);

        Transform transform = obj.GetComponent<Transform>();
        for (int i = 0; i < transform.childCount; i++) {
            ScanGameObject(transform.GetChild(i).gameObject, callback, path);
        }
    }

    void ScanGameObject(GameObject obj, Object root = null, string path = "") {
        if (obj == null) return;
        if (root == null) root = obj;

        sprites.ForEach(si => {
            si.objInfo.RemoveAll(info => info.obj == null || info.paths.Count == 0 || info.obj == obj);
        });

        sprites.RemoveAll(si => si.sprite == null || si.objInfo.Count == 0);

        ScanGameObjectSprite(obj, (o, s, p) => addSprite(s, root, p));
    }
    
    void ScanPath(string path) {
        ScanGameObject(AssetDatabase.LoadAssetAtPath<GameObject>(path));
    }

    public void Scan(bool scan_scene = true) {
        string[] folders = {
            "Assets/assetbundle",
            "Assets/Resources",
            "Assets/prefabs",
        };

        caches = null;
        sprites.Clear();

        bool watch = SpriteReferenceInfoDetector.watchEditorChange;
        SpriteReferenceInfoDetector.watchEditorChange = false;

        try {
            string[] assets = AssetDatabase.FindAssets("t:prefab", folders);
            for (int i = 0; i < assets.Length; i++) {
                string path = AssetDatabase.GUIDToAssetPath(assets[i]);
                if (EditorUtility.DisplayCancelableProgressBar(string.Format("scan prefab {0}/{1}", i + 1, assets.Length), path, (float)i / (float)assets.Length)) {
                    break;
                }

                if (path.Contains("unused")) {
                    continue;
                }

                ScanPath(path);
            }

            EditorBuildSettingsScene[] scenes = EditorBuildSettings.scenes;
            for (int i = 0; scan_scene && i < scenes.Length; i++) {
                EditorBuildSettingsScene s = scenes[i];
                if (!s.enabled || string.IsNullOrEmpty(s.path)) continue;

                if (EditorUtility.DisplayCancelableProgressBar(string.Format("scan scene {0}/{1}", i + 1, scenes.Length), s.path, (float)i / (float)scenes.Length)) {
                    break;
                }

                if (s.path.Contains("unused")) {
                    continue;
                }

                UnityEditor.SceneManagement.EditorSceneManager.OpenScene(s.path);

                SceneAsset root = AssetDatabase.LoadAssetAtPath<SceneAsset>(s.path);

                GameObject [] objs = UnityEditor.SceneManagement.EditorSceneManager.GetActiveScene().GetRootGameObjects();
                foreach(GameObject obj in objs) {
                    ScanGameObject(obj, root);
                }
            }
        } catch(System.Exception e) {
            Debug.LogError(e);
        } finally {
            EditorUtility.ClearProgressBar();
        }
        AssetDatabase.SaveAssets();
        SpriteReferenceInfoDetector.watchEditorChange = watch;
    }

    static SpriteReferenceInfo _instance = null;
    public static SpriteReferenceInfo Instance {
        get {
            if (_instance == null) {
                _instance = AssetDatabase.LoadAssetAtPath<SpriteReferenceInfo>("Assets/Editor/SpriteReferenceInfo.asset");
                if (_instance == null) {
                    _instance = new SpriteReferenceInfo();
                    AssetDatabase.CreateAsset(_instance, "Assets/Editor/SpriteReferenceInfo.asset");
                }
            }
            EditorUtility.SetDirty(_instance);
            return _instance;
        }
    }

    public void Cleanup() {
        caches = null;

        sprites.ForEach(si => {
            si.objInfo.RemoveAll(info => info.obj == null || info.paths.Count == 0);
        });

        sprites.RemoveAll(si =>si.sprite == null || si.objInfo.Count == 0);
    }

    public void OnAssetChange(HashSet<string> changed) {
        for (int i = sprites.Count - 1; i >= 0; i--) {
            SpriteInfo si = sprites[i];
            if (si.sprite == null) {
                sprites.RemoveAt(i);
                continue;
            }

            for(int j = si.objInfo.Count - 1; j >= 0; j --) {
                GameObjectInfo go = si.objInfo[j];
                if (go.obj == null) {
                    si.objInfo.RemoveAt(j);
                    continue;
                }

                if (changed.Contains(AssetDatabase.GetAssetPath(go.obj))) {
                    si.objInfo.RemoveAt(j);
                    continue;
                }
            }

            if (si.objInfo.Count == 0) {
                sprites.RemoveAt(i);
                continue;
            }
        }

        foreach(string obj in changed) {
            ScanPath(obj);
        }
    }

    public void Reload(GameObject obj) {
        ScanGameObject(obj);
    }

    public static void ReleaseInstance() {
        // _instance = null;
    }

    public List<Sprite> Top(int n) {
        List<SpriteInfo> info = sprites.FindAll((a) => {
            return !a.name.Contains(":");
        });

        info.Sort((a, b) => {
            return b.objInfo.Count - a.objInfo.Count;
        });

        List<Sprite> ss = new List<Sprite>();
        for (int i = 0; i < n && i < info.Count; i++) {
            ss.Add(info[i].sprite);
        }

        return ss;
    }
}
