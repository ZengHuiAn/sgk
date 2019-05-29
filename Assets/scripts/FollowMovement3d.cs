using UnityEngine;
using UnityEngine.AI;
using System.Collections;
using System.Collections.Generic;
using DG.Tweening;
namespace SGK {
	public class FollowMovement3d : MonoBehaviour {

		public Transform _TargetTF;         //要跟随的目标
		public float RecordGap = 0.1f;    //目标移动多远记录一次距离
		public float StopCount = 3f;      //记录还剩多少时停止移动
		public float WalkSpeed = 1.5f;       //走速度
		public float MaxRange = 2f;
		public List<Vector3> PosList = new List<Vector3>();
		MapPlayer mapPlayer;
        NavMeshAgent Nav;

        void Start() {
			mapPlayer = GetComponent<MapPlayer>();
            Nav = gameObject.GetComponent<NavMeshAgent>();
            if (Nav)
            {
                Nav.enabled = false;
            }
        }

		public void Reset(){
			if (mapPlayer != null) {
				mapPlayer.UpdateDirection(Vector3.zero, true);
			}
			PosList.Clear();
		}

		void OnDisabled() {
			//失去意识时清空记录
			PosList.Clear();
	    }
		public Transform TargetTF{
			get {
				return _TargetTF;
			}
			set{
				_TargetTF = value;
				//transform.position = new Vector3(_TargetTF.position.x,_TargetTF.position.y,_TargetTF.position.z+ (RecordGap*StopCount)) ; 
				if (Nav) {
					Nav.enabled = false;
				}
			}
		}
	    void Update() {
            if (Nav)
            {
                Nav.enabled = (_TargetTF == null);
            }
            if (_TargetTF == null)
            {
                PosList.Clear();
                mapPlayer.UpdateDirection(Vector3.zero, true);
                enabled = false;
                
                return;
            }
            float StopRange = StopCount * RecordGap;
            float Distance = Vector3.Distance(transform.position, _TargetTF.position);
			if (Distance > MaxRange){
				transform.position = new Vector3(_TargetTF.position.x,_TargetTF.position.y,_TargetTF.position.z+ StopRange);
				PosList.Clear();
				return;
			}
			if (Distance > StopRange){
				PosList.Add(_TargetTF.position);
			}else{
				if (mapPlayer) {
					mapPlayer.UpdateDirection(Vector3.zero, true);
				}
				return;
			}
			//if (PosList.Count <= StopCount) {
			//}
			Vector3 targetPostion = PosList[0];
			float speed = WalkSpeed + (Distance-StopRange);//采用追击方式移动
			//float speed = WalkSpeed * (Vector3.Distance(targetPostion,transform.position)/RecordGap);//采用模拟队长速度移动

			if (mapPlayer != null) {
				mapPlayer.UpdateDirection((targetPostion - transform.position).normalized, false);
			}
			transform.position = Vector3.MoveTowards(transform.position, targetPostion, speed * Time.deltaTime);
			PosList.RemoveAt(0);
	    }
	}
}
