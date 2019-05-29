using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.U2D;
using UnityEngine.UI;
using Spine.Unity;
using UnityEngine.Networking;

//namespace SGK {
    public class shareImage : MonoBehaviour
    {
        public Texture2D theMR=null;
        public Image image=null;
        public string _url = "";
        bool changed = false;
        public string URL {
            get { return _url;  }
            set {
                if (_url != value) {
                    _url = value;
                    changed = true;
                    Load();
                }
            }
        }

        void Load() {
            image=this.gameObject.GetComponent<Image>();
            if (!changed || string.IsNullOrEmpty(_url)) {
                changed = false;
                return;
            }

            if (enabled && gameObject.activeInHierarchy) {
                changed = false;
                StartCoroutine(LoadThread(_url));
            }
        }
        IEnumerator LoadThread(string url){
            //print("ding===========>>>>"+url);
            WWW _www=new WWW("file://"+url);
            yield return _www;
            if(_www != null && string.IsNullOrEmpty(_www.error)){
              theMR=_www.texture;
              Sprite sprite =Sprite.Create(theMR,new Rect(0,0,theMR.width,theMR.height),new Vector2(0.5f,0.5f));
              image.sprite = sprite;
            }
        }
    }
    [XLua.LuaCallCSharp]
	public static class RawImageWWWExtension {
		public static void LoadWWWImage(this Image image ,string url) {
            shareImage loader = image.gameObject.GetComponent<shareImage>();
            if (loader == null) {
                loader = image.gameObject.AddComponent<shareImage>();
            }
            loader.URL = url;
		}
    }
//}