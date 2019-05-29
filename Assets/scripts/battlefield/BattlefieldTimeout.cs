using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace SGK {
	public class BattlefieldTimeout : MonoBehaviour {
		public float _left = -1;

		public Text text;
		public Animator animator;

		[Range(0, 60)]
		public float hurryTime = 10;

		public bool formatTime = true;
		
		public System.Action onTimeout;
		bool timeoutFired = false;

		public void StartWithTime(float time) {
			_left = time;
			timeoutFired = false;
			last_value = -1;
			last_real_time = Time.realtimeSinceStartup;
		}

		int last_value = 0;
		float last_real_time = 0;
		void Update() {
			if (_left < 0) {
				if (text != null) {
					text.text = "";
					return;
				}
				return;
			}

			_left -= (Time.realtimeSinceStartup - last_real_time);
			last_real_time = Time.realtimeSinceStartup;

			if (last_value == (int)_left) {
				return;
			}

			if (animator != null) {
				animator.SetBool("Hurry", (_left > 0 && _left <= hurryTime));
			}

			last_value = (int)_left;
			if (last_value <= 0 && !timeoutFired) {
				timeoutFired = true;
				if (onTimeout != null) {
					onTimeout();
				}
			}

			if (text != null) {
				if (formatTime) {
					int min = last_value / 60;
					int sec = last_value % 60;
					text.text = string.Format("{0}:{1}", min.ToString("00"), sec.ToString("00"));
				} else {
					text.text = string.Format("{0}", last_value);
				}
			}
		}

        private void OnDestroy() {
            onTimeout = null;
        }
    }
}
