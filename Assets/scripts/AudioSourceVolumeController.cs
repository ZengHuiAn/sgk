using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace SGK {
	[RequireComponent(typeof(AudioSource))]
	public class AudioSourceVolumeController : MonoBehaviour {
		static public float effectVolume = 0.5f;
		static public float voiceVolume = 0.5f;

		static HashSet<string> voiceName = new HashSet<string>();


        AudioSource _AudioSource = null;
        AudioSource audioSource {
            get {
                if (_AudioSource == null) {
                    _AudioSource = GetComponent<AudioSource>();
                }
                return _AudioSource;
            }
        }

		public enum AudioType {
			Default,
			Efffect,
			Voice,
		};

		public AudioType audioType;

		void Start () {
			
			if (audioSource.clip) {
				UpdateVolume(audioSource.clip.name, audioType);
			}
		}

		public void Play(AudioClip clip) {
			Play(clip, audioType);
		}

		public void Play(string clipName) {
			Play(clipName, audioType);
		}
		public void Stop(){
			audioSource.Stop ();
			audioSource.clip = null;
		}
		public void Play(AudioClip clip, AudioType type) {
			audioSource.clip = clip;
			if (clip == null) {
				return;
			}

			UpdateVolume(clip.name, type);

			if (audioSource.volume > 0.01f) {
				audioSource.Play();
			}
		}

        string currentClipName = "";
		public void Play(string clipName, AudioType type) {
			if (string.IsNullOrEmpty(clipName)) {
				audioSource.clip = null;
				return;
			}

			UpdateVolume(System.IO.Path.GetFileName(clipName), type);

			if (audioSource.volume <= 0.01f) {
				audioSource.clip = null;
				return;
			}

            currentClipName = name;

            SGK.ResourcesManager.LoadAsync(this, clipName, typeof(AudioClip), (o)=> {
                if (currentClipName != name) {
                    return;
                }

                audioSource.clip = (AudioClip)o;
                if (audioSource.clip != null) {
                    audioSource.Play();
                }
            });
		}


		public static void AddVoiceName(string name) {
			voiceName.Add(name);
		}

        void UpdateVolume(string clipName, AudioType type) {
			if (type == AudioType.Efffect) {
				audioSource.volume = effectVolume;
			} else if (type == AudioType.Voice) {
				audioSource.volume = voiceVolume;
			} else if (type == AudioType.Default) {
				if (voiceName.Contains(clipName)) {
					audioSource.volume = voiceVolume;
				} else {
					audioSource.volume = effectVolume;
				}
			}
		}
	}
}