using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


[CreateAssetMenu(fileName = "new_SpriteAtlas", menuName = "Sprite Atlas Data", order = 2)]
public class SpriteAtlasData : ScriptableObject
{
    [System.Serializable]
    public class SpriteInfo {
        public string _name;
        public string name {
            get {
                if (string.IsNullOrEmpty(_name)) {
                    if (packed != null) {
                        _name = packed.name;
                    } else if (origin != null) {
                        _name = origin.name;
                    } else {
                        _name = "-";
                    }
                }
                return _name;
            }
        }

        public Sprite packed;
        public Sprite origin;

        [SerializeField]
        int _update;
        public bool update {
            get {
                return origin != null && origin != packed && (_update == 2 || _update == 0);
            }

            set {
                _update = value ? 2 : 1;
            }
        }

        [SerializeField]
        bool _on = true;
        public bool delete {
            get { return !_on; }
            set { _on = !value; }
        }

        public SpriteInfo(Sprite packed, Sprite origin = null) {
            this.packed = packed;
            this.origin = origin;
            this._name = name;
            this._origins = null;
        }

        Sprite[] _origins;
        public Sprite[] origins {
            get {
                return _origins;
            }
        }

        public void AddOrigin(Sprite s) {
            FindOrigin();
            for (int i = 0; i < _origins.Length; i++) {
                if (_origins[i] == s) { return; }
            }

            Sprite[] old = _origins;
            _origins = new Sprite[_origins.Length + 1];
            for (int i = 0; i < _origins.Length; i++) {
                if (i == _origins.Length - 1) {
                    _origins[i] = s;
                } else {
                    _origins[i] = old[i];
                }
            }
        }

        public void RemoveOrigin(Sprite s) {
            if (s == origin) {
                return;
            }

            FindOrigin();
            Sprite[] old = _origins;
            _origins = new Sprite[_origins.Length - 1];
            int j = 0;
            for (int i = 0; i < old.Length; i++) {
                if (s == old[i]) {
                    continue;
                }

                _origins[j++] = old[i];
            }
        }

        public void Cleanup() {
            _origins = null;
            // _update = 0;
            // _on = true;
        }

        public static Sprite FindOriginSprite(string name, Sprite sprite, ref List<Sprite> sameNameSprite) {
            if (sameNameSprite != null) {
                sameNameSprite.Clear();
            }

            string[] assets = AssetDatabase.FindAssets(name + " t:texture");

            List<string> paths = new List<string>();
            string path;
            for (int i = 0; i < assets.Length; i++) {
                path = AssetDatabase.GUIDToAssetPath(assets[i]);
                if (System.IO.Path.GetFileNameWithoutExtension(path) == name) {
                    paths.Add(path);
                    if (sameNameSprite != null) {
                        Sprite s = AssetDatabase.LoadAssetAtPath<Sprite>(path);
                        if (s != null) {
                            sameNameSprite.Add(s);
                        }
                    }
                }
            }

            if (paths.Count == 0) {
                return null;
            }

            int maxMatch = 0;
            if (paths.Count > 1) {
                int[] match = new int[paths.Count];
                string s = "";
                string origPath = (sprite != null) ? AssetDatabase.GetAssetPath(sprite.texture) : "";
                for (int j = 0; j < paths.Count; j++) {
                    string ss = paths[j];
                    match[j] = 0;
                    for (int i = 0; i < ss.Length && i < origPath.Length; i++) {
                        if (ss[i] == origPath[i]) {
                            match[j]++;
                            if (match[j] > match[maxMatch]) {
                                maxMatch = j;
                            }
                        } else {
                            break;
                        }
                    }
                    s = s + ss + "\n";
                }
                Debug.LogWarningFormat("Duplicate {0} t:texture choose {2}\n{1}", name, s, paths[maxMatch]);
            }

            return AssetDatabase.LoadAssetAtPath<Sprite>(paths[maxMatch]);
        }

        public bool FindOrigin() {
            if (_origins != null) {
                return false;
            }

            List<Sprite> _same_name_sprite = new List<Sprite>();
            Sprite _origin = FindOriginSprite(name, packed, ref _same_name_sprite);

            if (origin == null) {
                origin = _origin;
            } else {
                if (origin.name != name) {
                    _same_name_sprite.Add(origin);
                }
            }

            _origins = _same_name_sprite.ToArray();
            return true;
        }
    }


    public Texture2D texture;
    public SpriteInfo [] sprites;

    string _path;
    public string path {
        get {
            if (string.IsNullOrEmpty(_path) && texture != null) {
                _path = AssetDatabase.GetAssetPath(texture);
            }
            return _path;
        }
    }

    public void Pack() {
        TexturePacker.Pack(sprites, texture);
    }

    public void Scan() {
        if (texture == null) { return; }

        List<SpriteInfo> newList = new List<SpriteInfo>();

        Object[] assets = AssetDatabase.LoadAllAssetsAtPath(AssetDatabase.GetAssetPath(texture));
        foreach (Object o in assets) {
            if (o.GetType() != typeof(Sprite)) {
                continue;
            }

            Sprite s = o as Sprite;
            SpriteInfo info = FindSpriteInfo(s);
            if (info == null) {
                info = new SpriteInfo(s);
            } else if (info.packed == null) {
                info.packed = s;
            }
            newList.Add(info);
        }

        newList.Sort((a, b) => {
            return string.Compare(a.name, b.name);
        });

        sprites = newList.ToArray();
        EditorUtility.SetDirty(this);
    }

    public SpriteInfo FindSpriteInfo(Sprite sprite) {
        if (sprite == null) return null;
        return FindSpriteInfo(sprite.name);
    }

    public SpriteInfo FindSpriteInfo(string name) {
        if (string.IsNullOrEmpty(name) || sprites == null) return null;
        for (int i = 0; i < sprites.Length; i++) {
            if (sprites[i].name == name) {
                return sprites[i];
            }
        }
        return null;
    }

    public bool HaveSprite(string name) {
        return FindSpriteInfo(name) != null;
    }

    public bool HaveSprite(Sprite s) {
        return FindSpriteInfo(s) != null;
    }

    public void RemoveSprite(SpriteInfo info) {
        List<SpriteInfo> list = new List<SpriteInfo>();

        for (int i = 0; i < sprites.Length; i++) {
            if (sprites[i] == info) continue;
            list.Add(sprites[i]);
        }
        sprites = list.ToArray();
        EditorUtility.SetDirty(this);
    }

    public void AddSprite(Sprite s) {
        List<SpriteInfo> list = new List<SpriteInfo>();
        if (sprites != null) list.AddRange(sprites);
        list.Add(new SpriteAtlasData.SpriteInfo(null, s));
        list.Sort((a, b) => string.Compare(a.name, b.name));
        sprites = list.ToArray();
        EditorUtility.SetDirty(this);
    }
}
