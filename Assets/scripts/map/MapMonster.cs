using System.Collections;
using System.Collections.Generic;
using UnityEngine;
namespace SGK {
	public class MapMonster : MonoBehaviour{
		public GameObject character = null;
		void Start(){}
		public void UpdateDirection(Vector3 direction) {
			if (direction.sqrMagnitude > 0.01f) {
				character.transform.localEulerAngles = new Vector3 (0, 0, 0);
				Vector3 a2 = character.transform.eulerAngles;
				int angle = (int)(angle360(new Vector3(1, 0, -1), direction, new Vector3(-1, 0, -1)) - 22.5f) + (360 - (int)a2.y);
				if (angle < 0) {
					angle += 360;
				}
				angle = angle % 360;
				int character_direction = 1 + (int)Mathf.Floor(angle / 45);
				if (character_direction > 0) {
					//Debug.LogError(character_direction - 1);
					switch (character_direction - 1) {
						case 1:
						character.transform.localEulerAngles = new Vector3 (0, 0, 0);
							break;
						case 2:
						character.transform.localEulerAngles = new Vector3 (0, 0, 0);
							break;
						case 3:
						character.transform.localEulerAngles = new Vector3 (0, 0, 0);
							break;
						case 5:
						character.transform.localEulerAngles = new Vector3 (0, 180, 0);
							break;
						case 6:
						character.transform.localEulerAngles = new Vector3 (0, 180, 0);
							break;
						case 7:
						character.transform.localEulerAngles = new Vector3 (0, 180, 0);
							break;
					}
				}
			}
		}
		float angle360(Vector3 from, Vector3 to, Vector3 right) {
			float angle = Vector3.Angle(from, to);
			return (Vector3.Angle(right, to) > 90f) ? 360f - angle : angle;
		}
	}
}