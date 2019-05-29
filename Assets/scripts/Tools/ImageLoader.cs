using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.U2D;
using UnityEngine.UI;
using Spine.Unity;

namespace SGK {
	public class ImageLoader : MonoBehaviour {
		public SpriteRenderer spriteRenderer;
		public Image image;

		public string imageName;
		public string atlasName;

		System.Action<Sprite> callback;

        public static void Load(Image image, string name, System.Action<Sprite> callback = null, string atlasName = null) {
#if UNITY_EDITOR
            if (string.IsNullOrEmpty(System.IO.Path.GetExtension(name))) {
                throw new KeyNotFoundException();
            }

			if (!Application.isPlaying) {
				image.sprite = SGK.ResourcesManager.Load<Sprite>(name);
				if(callback != null) {
					callback(image.sprite);
				}
				return;
			}
#endif
            if (image.enabled && image.gameObject.activeInHierarchy) {
                SyncLoadSprite(image, name, atlasName, (o) => {
                    image.sprite = o;
                    if (callback != null) {
                        callback(o);
                    }
                }) ;
                return;
            }

            ImageLoader loader = image.gameObject.GetComponent<ImageLoader>();
			if (loader != null) {
                Destroy(loader);
            }

            loader = image.gameObject.AddComponent<ImageLoader>();

            loader.image = image;
			loader.imageName = name;
			loader.atlasName = atlasName;
			loader.callback = callback;
		}

		public static void Load(SpriteRenderer renderer, string name, System.Action<Sprite> callback = null, string atlasName = null) {
#if UNITY_EDITOR
            if (string.IsNullOrEmpty(System.IO.Path.GetExtension(name))) {
                throw new KeyNotFoundException();
            }

			if (!Application.isPlaying) {
				renderer.sprite = SGK.ResourcesManager.Load<Sprite>(name);
				if(callback != null) {
					callback(renderer.sprite);
				}
				return;
			}
#endif
            ImageLoader loader = renderer.gameObject.GetComponent<ImageLoader>();
			if (loader != null) {
				loader = renderer.gameObject.AddComponent<ImageLoader>();
			}

            loader.spriteRenderer = renderer;
			loader.imageName = name;
			loader.atlasName = atlasName;
			loader.callback = callback;
		}

        private void Start() {
            // LoadList.Add(this);
            DoLoad();
        }

        void DoLoad() { 
			if (!string.IsNullOrEmpty(imageName)) {
				StartAsyncLoad(this, this.image, imageName, callback, atlasName);
			} else if (callback != null) {
                callback(null);
            }
		}

		static void SyncLoadSprite(MonoBehaviour mb, string name, string atlasName, System.Action<Sprite> callback) {
            if (name == "0" || string.IsNullOrEmpty(name)) {
                if (callback != null) {
                    callback(null);
                }
                return;
            }

            if (string.IsNullOrEmpty(atlasName)) {
				SGK.ResourcesManager.LoadAsync(mb, name, typeof(Sprite), (o) => {
                    if (callback != null) {
                        callback(o as Sprite);
                    }
                });
			} else {
				SGK.ResourcesManager.LoadAsync(mb, atlasName, typeof(SpriteAtlas), (o) => {
					SpriteAtlas sa = o as SpriteAtlas;
                    Sprite sp = (sa != null) ? sa.GetSprite(name) : null;
                    if (callback != null) { 
						callback(sp);
					}
				});
			}
		}

		static void StartAsyncLoad(ImageLoader loader, Image image, string name, System.Action<Sprite> callback = null, string atlasName = null) {
			if (image == null && (loader == null || loader.spriteRenderer == null)) {
				return;
			}

			MonoBehaviour mb = loader;
			if (loader == null) {
				mb = image;
			}

			SyncLoadSprite(mb, name, atlasName, (o) => {
				if (o == null) {
					Debug.LogErrorFormat("sprite {0} not exists", name);
					return;
				}

				if (loader != null && loader.imageName != name) {
					Debug.LogErrorFormat("sprite {0}/{1} not match", name, loader.imageName);
					return;
				}

				if (image != null) {
					image.sprite = o as Sprite;
				}

				if (loader != null && loader.spriteRenderer != null) {
					loader.spriteRenderer.sprite = o as Sprite;
				}

				if (callback != null) {
					callback(o as Sprite);
				}
			});
		}

		static void StartAsyncLoad(ImageLoader loader, string name, System.Action<Sprite> callback = null, string atlasName = null) {
			if (loader == null || loader.spriteRenderer == null) {
				return;
			}

			SyncLoadSprite(loader, name, atlasName, (o) => {
				if (o == null) {
					Debug.LogErrorFormat("sprite {0} not exists", name);
					return;
				}

				loader.spriteRenderer.sprite = o as Sprite;
				if (callback != null) {
					callback(o as Sprite);
				}
			});
		}
	}

	public static class ImageExtension {
        public static void LoadSpriteWithExt(this Image image, string name, System.Action callback = null) {
            ImageLoader.Load(image, name, (o) => {
                if (callback != null) {
                    callback();
                    callback = null;
                }
            });
        }

        public static void LoadSprite(this Image image, string name) {	
			ImageLoader.Load(image, name + ".png");
		}

        public static void LoadSprite(this Image image, string name, bool nativeSize) {
			ImageLoader.Load(image, name + ".png", (o) => {
				image.SetNativeSize();
			});
		}

		public static void LoadSprite(this Image image, string name, Color color) {
			ImageLoader.Load(image, name + ".png", (o) => {
				image.color = color;
			});
		}
		public static void LoadSprite(this Image image, string name, System.Action callback = null) {
			ImageLoader.Load(image, name + ".png", (o) => {
				if (callback != null){
					callback();
                    callback = null;
				}
			});
		}

		public static void LoadSprite(this Image image, string name, string atlasName) {
			ImageLoader.Load(image, name + ".png", null, atlasName);
		}

		public static void LoadSprite(this SpriteRenderer renderer, string name) {
			ImageLoader loader = renderer.gameObject.GetComponent<ImageLoader>();
			if (loader == null) {
				loader = renderer.gameObject.AddComponent<ImageLoader>();
			}

			ImageLoader.Load(renderer, name + ".png");
		}
    }
}
