using System.Collections.Generic;
using UnityEngine;
using DG.Tweening;
namespace SGK
{
    [RequireComponent(typeof(AudioSource))]
    // [RequireComponent(typeof(SceneService))]
    public class BackgroundMusicService : MonoBehaviour, IService {
        // SceneService sceneService;
        AudioSource audioSource;

        public AudioSourceVolumeController uiEffectAudioSource;

        public class SceneMusicInfo {
            public string sceneName;
            public int id;
            public string audioName;
        }

        public List<SceneMusicInfo> sceneMusicInfo = new List<SceneMusicInfo>();
        public List<SceneMusicInfo> battleMusicInfo = new List<SceneMusicInfo>();
        public string defaultSceneMusicName;
        public float volume = 0.75f;


        static BackgroundMusicService instance = null;

        public void Register(XLua.LuaEnv luaState) {
            instance = this;
        }

        public void Dispose() {

        }

        int map_id = 0;

        // Use this for initialization
        void OnEnable() {
            // sceneService = GetComponent<SceneService>();
            audioSource = GetComponent<AudioSource>();
            audioSource.loop = true;
            //sceneService.AfterSceneLoad += switchMusic;
        }

        void OnDisable() {
            //sceneService.AfterSceneLoad -= switchMusic;
        }

        void Start() {
            switchMusic();
        }

        void switchMusic() {
            string name = UnityEngine.SceneManagement.SceneManager.GetActiveScene().name;
            if (name == "battle" || name == "newSelectMapUp") {
                return;
            }

            string audioName = null;
            for (int i = 0; i < sceneMusicInfo.Count; i++) {
                if (sceneMusicInfo[i].sceneName == name) {
                    if (sceneMusicInfo[i].id == map_id) {
                        audioName = sceneMusicInfo[i].audioName;
                        break;
                    } else if (sceneMusicInfo[i].id == 0 && string.IsNullOrEmpty(audioName)) {
                        audioName = sceneMusicInfo[i].audioName;
                    }
                }
            }
            
            if (!string.IsNullOrEmpty(audioName)) {
                Play(audioName);
            } else {
                Play(defaultSceneMusicName);
            }
        }

        void _PlayBattleMusic(string name) {
            if (!string.IsNullOrEmpty(name)) {
                for (int i = 0; i < battleMusicInfo.Count; i++) {
                    if (battleMusicInfo[i].sceneName == name) {
                        Play(battleMusicInfo[i].audioName);
                        return;
                    }
                }
            }

            for (int i = 0; i < sceneMusicInfo.Count; i++) {
                if (sceneMusicInfo[i].sceneName == "battle") {
                    Play(sceneMusicInfo[i].audioName);
                    return;
                }
            }
            Play(defaultSceneMusicName);
        }

        string currentAudioName = "";
        static int play_counter = 0;
        static AudioClip _loadingAudioClip = null;
        void Play(string audioName) {
            if (audioName == currentAudioName) {
                return;
            }

            currentAudioName = audioName;
            if (string.IsNullOrEmpty(audioName)) {
                audioSource.clip = null;
                audioSource.Stop();
            } else {
                play_counter++;
                int counter = play_counter;
                SGK.ResourcesManager.LoadAsync(this, audioName, typeof(AudioClip), (o) => {
                    if (counter != play_counter) return;

                    AudioClip audio = o as AudioClip;
                    if (_loadingAudioClip == null && audioSource.clip == audio) {
                        return;
                    } else if (_loadingAudioClip != null) {
                        _loadingAudioClip = audio;
                    } else {
                        audioSource.Stop();
                        audioSource.clip = audio;
                        _loadingAudioClip = null;
                        audioSource.Play();
                        audioSource.DOFade(volume, 1.0f);  
                    }
                });
            }
        }

        void _SetMapID(int id) {
            map_id = id;
        }

        public static void SetMapID(int id) {
            if (instance != null) {
                instance._SetMapID(id);
            }
        }

        public static void PlayBattleMusic(string name) {
            if (instance != null) {
                instance._PlayBattleMusic(name);
            }
        }
        public static void PlayMusic(string name) {
            if (instance != null)
            {
                instance.Play(name);
            }
        }
        public static void RegisterSceneMusic(string scene, string name, int map_id = 0) {
            if (instance != null) {
                if (scene == "*") {
                    instance.defaultSceneMusicName = name;
                    return;
                }

                SceneMusicInfo info = new SceneMusicInfo();
                info.sceneName = scene;
                info.audioName = name;
                info.id = map_id;
                instance.sceneMusicInfo.Add(info);
            }
        }

        public static void RegisterBattleMusic(string scene, string name) {
            if (instance != null) {
                SceneMusicInfo info = new SceneMusicInfo();
                info.sceneName = scene;
                info.audioName = name;
                instance.battleMusicInfo.Add(info);
            }
        }

        public static void CleanMusicConfig() {
            if (instance != null) {
                instance.sceneMusicInfo.Clear();
                instance.battleMusicInfo.Clear();
            }
        }


        public static void SwitchMusic() {
            if (instance != null) {
                instance.switchMusic();
            }
        }

        public static void Pause()
        {
            instance.GetComponent<AudioSource>().Pause();
        }
        public static void UnPause()
        {
            instance.GetComponent<AudioSource>().UnPause();
        }

        public static void GetAudio(float value){
			instance.GetComponent<AudioSource>().volume = value;
        }

        public static void SetAudioListenerVolume(float value)
        {
            if (instance != null)
            {
                instance.volume = value;
            }
            AudioListener.volume = value;
        }

        public static void PlayUIClickSound(AudioClip clip) {
            if (instance != null) {
                instance.uiEffectAudioSource.Play(clip);
            }
        }
    }
}