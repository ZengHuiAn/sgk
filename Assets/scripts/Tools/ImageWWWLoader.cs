using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.U2D;
using UnityEngine.UI;
using Spine.Unity;
using UnityEngine.Networking;

namespace SGK {
    public class ImageWWWLoader : MonoBehaviour
    {
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

        private void OnEnable() {
            Load();
        }

        void Load() {
            if (!changed || string.IsNullOrEmpty(_url)) {
                changed = false;
                return;
            }

            if (enabled && gameObject.activeInHierarchy) {
                changed = false;
                StartCoroutine(LoadThread(_url));
            }
        }

        IEnumerator LoadThread(string url) {
            UnityWebRequest www = UnityWebRequestTexture.GetTexture(url);
            yield return www.SendWebRequest();

            if (www.isNetworkError || www.isHttpError) {
                Debug.Log(www.error);
            } else {
                Texture texture = ((DownloadHandlerTexture)www.downloadHandler).texture;
                // assign texture
                Renderer renderer = GetComponent<Renderer>();
                if (renderer != null) {
                    renderer.material.mainTexture = texture;
                }

                RawImage image = GetComponent<RawImage>();
                if (image != null) {
                    image.texture = texture;
                }
            }
        }
    }

	public static class RawImageWWWExtension {
		public static void LoadWWWTexture(this RawImage image, string url) {
            ImageWWWLoader loader = image.gameObject.GetComponent<ImageWWWLoader>();
            if (loader == null) {
                loader = image.gameObject.AddComponent<ImageWWWLoader>();
            }
            loader.URL = url;
		}
    }
}
