using System;
using UnityEngine;
using System.Text;
using System.IO;
using XLua;

namespace SGK
{
	[LuaCallCSharp]
	public static class FileUtils
	{

        public static bool LogFileRead = false;

        public static byte[] utf8FiliterRom(byte[] bts)
        {
            if (bts == null || bts.Length == 0)
            {
                return bts;
            }
            if (bts[0] == 239 && bts[1] == 187 && bts[2] == 191)
            {
                byte[] n = new byte[bts.Length - 3];
                for (int i = 3; i < bts.Length; ++i)
                {
                    n[i - 3] = bts[i];
                }
                return n;
            }
            return bts;
        }

        static byte[] luaCompileCode(byte[] bts)
        {
            if (bts == null || bts.Length == 0)
            {
                return bts;
            }

            bts[13] = (byte)IntPtr.Size;

            return bts;
        }


#if UNITY_ANDROID && !UNITY_EDITOR
        static string android_debug_file = null;
        static string get_android_debug_file(string fileName) {
            if (android_debug_file == null) {
                const string PREFIX = "/sdcard/sgk"; // Application.persistentDataPath
                if (Directory.Exists(PREFIX + "/patchs/Lua")) {
                    android_debug_file = PREFIX + "/patchs/";
                } else {
                    android_debug_file = "";
                }
                Debug.LogFormat("android_debug_file [{0}]", android_debug_file);
            }

            if (android_debug_file == "") {
                return null;
            }

            string fullName = android_debug_file + fileName;
            if (File.Exists(fullName)) {
                Debug.LogFormat("android_debug_file [{0}]", fullName);
                return fullName;
            }
            return null;
        }
#endif

        public static byte [] readFromAssets(string filePath) {
            filePath = Application.dataPath + "/" + filePath;
			if (File.Exists (filePath)) {
				return File.ReadAllBytes (filePath);
			}
			return null;
		}

        public static byte [] Load (ref string fileName)
		{
			string realFileName = "Lua/" + fileName.Replace (".", "/") + ".lua";

#if UNITY_EDITOR
            if (LogFileRead) {
                Debug.LogFormat("FileUtils.Load {0}", realFileName);
            }

            if (AssetManager.SimulateMode || AssetManager.SimulateLua) {
                byte[] bs;
                bs = readFromAssets(realFileName);
                if (bs != null) {
                    return bs;
                }

                bs = readFromAssets(realFileName + ".bytes");
                if (bs != null) {
                    return bs;
                }
            }
#elif UNITY_ANDROID
            string debug_file_name = get_android_debug_file(realFileName);
            if (!string.IsNullOrEmpty(debug_file_name)) { 
                return File.ReadAllBytes(debug_file_name);
            }
#endif
            TextAsset text = ResourcesManager.Load<TextAsset> (realFileName + ".bytes");
			if (text != null) {
				fileName = realFileName;
				return luaCompileCode(utf8FiliterRom(text.bytes)); ;
            }
			return null;
		}

        public static byte [] LoadBytesFromFile(string fileName)
        {
            string realFileName = "Lua/" + fileName;

#if UNITY_EDITOR
            if (AssetManager.SimulateMode || AssetManager.SimulateLua)
            {
                byte[] bs = readFromAssets(realFileName);
                if (bs == null)
                {
                    bs = readFromAssets(realFileName + ".bytes");
                }

                return utf8FiliterRom(bs);
            }
#elif UNITY_ANDROID
            string debug_file_name = get_android_debug_file(realFileName);
            if (!string.IsNullOrEmpty(debug_file_name)) {
                return File.ReadAllBytes(debug_file_name);
            }
#endif
            TextAsset text = ResourcesManager.Load<TextAsset>(realFileName + ".bytes");
            if (text == null)
            {
                Debug.LogFormat("LoadStringFromFile {0} failed", realFileName);
                return null;
            }

            return luaCompileCode(utf8FiliterRom(text.bytes)); 
        }
    }

}

