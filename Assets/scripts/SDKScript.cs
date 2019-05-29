using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

[XLua.LuaCallCSharp]
public class SDKScript : MonoBehaviour {
	public GameObject [] waitingObject = new GameObject[0];

	void Start () {
		ActiveAll();
	}

	void ActiveAll() {
        UnityEngine.SceneManagement.SceneManager.LoadScene(SGK.SceneService.PRESISTENT_SCENE_BUILD_INDEX);
        /*
        for (int i = 0; i < waitingObject.Length; i++) {
			waitingObject[i].SetActive(true);
		}
        */
	}

	public static bool isEnabled {
		get {
            return false;
		}
	}

	public static void Login() {
    	return;
	}

	public struct PayInfo {
		public string uid; 		 // 游戏账号uid
		public string price;        // 商品价格（元）

		public string productId;    // 商品ID
		public string productName;  // 商品名称（如：50钻石）
		public string productDesc;	 // 商品描述

		public string cpOrderId;    // 游戏商品订单号

		public string serverId;     // 服务器ID
		public string serverName;   // 区服名称
		public string roleId;          // 游戏角色ID
		public string roleLevel;        // 角色等级
		public string roleName;     // 角色名称

		public string currencyName;  // 货币名称
		public string exchangeRate;  // 货币对人民币比率

		public string ext;     // 透传字段，供游戏cp使用，回调时会原样返回
	}


	public static void Pay(PayInfo info) {
		return;
	}

	public static void Call(string func, string [] args = null) {
	}
}
