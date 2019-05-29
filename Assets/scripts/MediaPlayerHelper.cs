using System;
using UnityEngine;
using UnityEngine.Video;
using UnityEngine.Events;
using UnityEngine.EventSystems;

namespace SGK
{
    public class MediaPlayerHelper : MonoBehaviour
    {
        public delegate void EventDelegate();
        public EventDelegate OnFinshed;

        [SerializeField]
        public VideoPlayer videoPlayer;
        public AudioSource audioSource;
        void Start()
        {
            videoPlayer.loopPointReached += OnFinshedEvent;
        }

        public void Load(VideoClip clip)
        {
            videoPlayer.clip = clip;
            if (audioSource != null)
            {
                videoPlayer.SetTargetAudioSource(0, audioSource);
            }
        }
        public void Play()
        {
            
            if (videoPlayer)
            {
                videoPlayer.Play();
            }
        }

        public void Pause()
        {
            if (videoPlayer)
            {
                videoPlayer.Pause();
            }
        }

        public void Stop()
        {
            if (videoPlayer)
            {
                videoPlayer.Stop();
            }
        }

        void OnFinshedEvent(VideoPlayer vPlayer)
        {
            if (OnFinshed != null)
            {
                OnFinshed.Invoke();
            }
        }
    }
}