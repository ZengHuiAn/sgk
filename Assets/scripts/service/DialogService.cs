using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;

using XLua;

namespace SGK {
    public class DialogService : MonoBehaviour, IService {
        private static DialogService _instance;

        public class DialogInfo {
            public string dialogName;
            public string scriptName;

			public LuaTable _delegate;
            public GameObject dialog;
        }

        Stack<DialogInfo> _dialog_stack = new Stack<DialogInfo>();


		public DialogService GetInstance() {
			return _instance;
		}

        public void Dispose() {
        }

        public void Open(string dialogName, string scriptName, bool keepPrev = false) {
            DialogInfo prefInfo = null;
            if (_dialog_stack.Count > 0 && !keepPrev) {
                prefInfo = _dialog_stack.Peek();
            }

            DialogInfo info = new DialogInfo();

            info.dialogName = dialogName;
            info.scriptName = scriptName;

            if (ShowDialog(info)) {
                _dialog_stack.Push(info);

                // close prev dialog
                if (prefInfo != null) {
                    Destroy(prefInfo.dialog);
                    prefInfo.dialog = null;
                }
            }
        }

        private bool ShowDialog(DialogInfo info) {
            /*
            Debug.LogFormat("ShowDialog {0} {1}", _dialog_stack.Count, info.dialogName);
            if (info.dialog != null) {
                return true;
            }

            GameObject prefab = ResourcesManager.Load(string.Format("prefabs/{0}", info.dialogName)) as GameObject;
            if (prefab == null) {
                Debug.LogFormat("prefab {0} load failed", info.dialogName);
                return false;
            }

            info.dialog = Instantiate(prefab);

			if (info._delegate == null && info.scriptName != null) {
				info._delegate = LuaBehaviour.Attach(info.dialog, info.scriptName);
            } else {
				LuaBehaviour.Attach(info.dialog, info._delegate);
            }
            */
            return true;
        }

        void DestroyDialogContext(DialogInfo info) {
            if (info.dialog != null) {
                Destroy(info.dialog);
                info.dialog = null;
            }

			info._delegate = null;
       }

        public void Close() {
            if (_dialog_stack.Count == 0) {
                return;
            }

            DialogInfo info;
            if (_dialog_stack.Count > 0) {
                info = _dialog_stack.Pop();
                DestroyDialogContext(info);
            }

            if (_dialog_stack.Count > 0) {
                info = _dialog_stack.Peek();
                ShowDialog(info);
            }
        }

        public void CloseAll() {
            while(_dialog_stack.Count > 0) {
                DialogInfo info = _dialog_stack.Pop();
                DestroyDialogContext(info);
            }
        }

        public void CloseTo(string name) {
            while (_dialog_stack.Count > 0) {
                DialogInfo info = _dialog_stack.Pop();
                if (info.dialogName == name) {
                    break;
                }

                DestroyDialogContext(info);
            }

            if (_dialog_stack.Count > 0) {
                ShowDialog(_dialog_stack.Peek());
            }
        }

		public void Register(LuaEnv xL) {
            _instance = this;
        }


        public void Unregister(LuaEnv xL) {
        }

        public void OnSceneChange() {
            CloseAll();
        }
    }
}