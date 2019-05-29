// #define CONFIG_FORMAT_XML
// #define CONFIG_FROM_XLSX

using System.Collections.Generic;
using UnityEngine;
using System.IO;
using System;

#if UNITY_EDITOR
using System.Net;
using UnityEditor;
#endif

using XLua;
using System.Xml.Serialization;
using System.Runtime.Serialization.Formatters.Binary;
using System.Runtime.Serialization;
using System.Xml;

namespace SGK
{
	public class Database
	{
        private static string FILE_PATH = Application.dataPath + "/" + ResourceBundle.RESOURCES_DIR + "/"; // Resources/";

		public static void SerializeObject<T> (T serializableObject, string fileName)
		{
			if (serializableObject == null) {
				return;
			}

			try {
				IFormatter formatter = new BinaryFormatter ();

				Stream stream = new FileStream (FILE_PATH + fileName, FileMode.Create);
				formatter.Serialize (stream, serializableObject);
				stream.Close ();
			} catch (Exception ex) {
				//Log exception here
				Debug.LogError (ex);
			}
		}

		public static T DeSerializeObject<T> (string fileName)
		{
			if (string.IsNullOrEmpty (fileName)) {
				return default(T);
			}

			T objectOut = default(T);

			try {
#if UNITY_EDITOR
				Stream stream = new FileStream(FILE_PATH + fileName, FileMode.Open);
				using (StreamReader reader = new StreamReader(stream)) {
					if (reader.Peek() == '<') {
						stream.Seek(0, SeekOrigin.Begin);
						objectOut = (T)((new XmlSerializer (typeof(T))).Deserialize (stream));
					} else {
						stream.Seek(0, SeekOrigin.Begin);
						objectOut = (T)((new BinaryFormatter ()).Deserialize (stream));
					}
				}
#else
				TextAsset textAsset = SGK.ResourcesManager.Load<TextAsset> (fileName);
				using (Stream stream = new MemoryStream (textAsset.bytes)) {
					if (textAsset.text.Length > 0 && textAsset.text [0] == '<') {
						objectOut = (T)((new XmlSerializer (typeof(T))).Deserialize (stream));
					} else {
						objectOut = (T)((new BinaryFormatter ()).Deserialize (stream));
					}
				}
#endif
			} catch (Exception ex) {
				//Log exception here
				Debug.LogError (ex);
			}
			return objectOut;
		}
        [Serializable]
        public class TableList
        {
            public List<string> tableNames;
        }
#if UNITY_EDITOR
        static void loadOneTable(string tableName)
		{
            // Debug.LogFormat("loadOneTable {0}", tableName);

            //make WebRequest to abc's URL
            WebRequest myRequest = WebRequest.Create("http://10.1.2.79/sgk/config2.php?db=" + tableName);

            //store the response in myResponse 
            HttpWebResponse myResponse = (HttpWebResponse)myRequest.GetResponse();
            if (myResponse.StatusCode != HttpStatusCode.OK) {
                Debug.LogErrorFormat("load config {0} failed: {1}", tableName, myResponse.StatusDescription);
                return;
            }

            // Debug.LogFormat("loadOneTable {0} {1}", tableName, myResponse.ContentLength);
            

            //register I/O stream associated with myResponse
            Stream myStream = myResponse.GetResponseStream();

            //create StreamReader that reads characters one at a time
            BinaryReader myReader = new BinaryReader(myStream, System.Text.Encoding.BigEndianUnicode);

            int length = myReader.ReadInt32();
            
            Stream stream = new FileStream(FILE_PATH + "config/" + tableName + ".def.bytes", FileMode.Create);
            using (BinaryWriter writer = new BinaryWriter(stream)) {
                writer.Write(myReader.ReadBytes(length));
            }
            stream.Close();

            stream = new FileStream(FILE_PATH + "config/" + tableName + ".cfg.bytes", FileMode.Create);
            using (BinaryWriter writer = new BinaryWriter(stream)) {
                writer.Write(myReader.ReadBytes((int)myResponse.ContentLength - length));
            }
            stream.Close();

            myReader.Close();//Close the reader and underlying stream
        }




        public static void LoadConfigFromServer()
        {
            try {
                //make WebRequest to abc's URL
                WebRequest myRequest = WebRequest.Create("http://10.1.2.79/sgk/config2.php");

                //store the response in myResponse 
                HttpWebResponse myResponse = (HttpWebResponse)myRequest.GetResponse();

                if (myResponse.StatusCode != HttpStatusCode.OK) {
                    Debug.LogErrorFormat("load config list failed: {0}", myResponse.StatusCode);
                    return;
                }

                //register I/O stream associated with myResponse
                Stream myStream = myResponse.GetResponseStream();

                //create StreamReader that reads characters one at a time
                StreamReader myReader = new StreamReader(myStream);

                string s = myReader.ReadToEnd();
                myReader.Close();//Close the reader and underlying stream

                TableList list = JsonUtility.FromJson<TableList>("{\"tableNames\":" + s + "}");
                for (int i = 0; i < list.tableNames.Count; i++) {
                    string tableName = list.tableNames[i];
                    EditorUtility.DisplayProgressBar(string.Format("loading {0}/{1}", i + 1, list.tableNames.Count), tableName, i * 1.0f / list.tableNames.Count);
                    try {
                        loadOneTable(tableName);
                    } catch (Exception e) {
                        Debug.LogErrorFormat("{0}: {1}", tableName, e);
                    }
                }

                writeTableList(list);

            } catch (Exception e) {
                Debug.LogError(e);
            } finally {
                EditorUtility.ClearProgressBar();
            }
        }
        static void writeTableList(TableList l)
        {
            FileStream fs = new FileStream(Application.dataPath + "/Lua/config/ConfigList.lua", FileMode.Create);
            StreamWriter w = new StreamWriter(fs);
            var content = l.tableNames;
            w.Write("local config = {");
            for (int i = 0; i < content.Count; ++i)
            {
                w.Write("\n\t\"" + content[i] + "\",");
            }

            w.Write("\n}\nreturn config;");
            w.Close();
            fs.Close();
        }
#endif

        [System.Serializable]
		[LuaCallCSharp]
		public struct BattlefieldCharacterConfig {
			public string id;
			public string type;
			public float x;
			public float y;
			public float z;
			public float sx;
			public float sy;
			public float sz;

            public float boundCenterX;
            public float boundCenterY;
            public float boundCenterZ;

            public float boundSizeX;
            public float boundSizeY;
            public float boundSizeZ;
        }

		public static string character_config_folder = "prefabs/character/";		
#if UNITY_EDITOR
		public static SGK.Database.BattlefieldCharacterConfig GenerateBattleCharacterConfig(string id, string type) {
			SGK.Database.BattlefieldCharacterConfig t = new SGK.Database.BattlefieldCharacterConfig();
			string fileName = string.Format("{0}/{1}.prefab", character_config_folder + type, id);
			GameObject obj = SGK.ResourcesManager.Load<GameObject>(fileName);
			if (obj != null) {
				Transform child = obj.transform.GetChild(0);
				t.x = child.position.x;
				t.y = child.position.y;
				t.z = child.position.z;
					
				t.sx = child.localScale.x;
				t.sy = child.localScale.y;
				t.sz = child.localScale.z;

                BoxCollider collider = child.GetComponent<BoxCollider>();
                if (collider != null) {
                    t.boundCenterX =  collider.center.x;
                    t.boundCenterY = collider.center.y;
                    t.boundCenterZ = collider.center.z;

                    t.boundSizeX = collider.size.x;
                    t.boundSizeY = collider.size.y;
                    t.boundSizeZ = collider.size.z;
                }

			} else {
				Debug.LogFormat("character config {0} not found", id);
				t.x = 0;
				t.y = 0;
				t.z = 0;
					
				t.sx = 0;
				t.sy = 0;
				t.sz = 0;
			}
			return t;
		}

		public static void GetBattlefieldCharacterTransform(string id, string type, out Vector3 position, out Vector3 scale) {
			SGK.Database.BattlefieldCharacterConfig c = GenerateBattleCharacterConfig(id, type);
			position.x = c.x;
			position.y = c.y;
			position.z = c.z;
			scale.x = c.sx;
			scale.y = c.sy;
			scale.z = c.sz;
		}

        public static void GetBattlefieldCharacterBound(string id, string type, out Vector3 center, out Vector3 size) {
            SGK.Database.BattlefieldCharacterConfig c = GenerateBattleCharacterConfig(id, type);

            center = new Vector3(c.boundCenterX, c.boundCenterY, c.boundCenterZ);
            size = new Vector3(c.boundSizeX, c.boundSizeY, c.boundSizeZ);
        }
#else
		public static SGK.Database.BattlefieldCharacterConfig GenerateBattleCharacterConfig(string id, string type) {
			return new SGK.Database.BattlefieldCharacterConfig();
		}

		static Dictionary<string, BattlefieldCharacterConfig> battlefieldCharacterInfo = null;
		public static void GetBattlefieldCharacterTransform(string id, string type, out Vector3 position, out Vector3 scale) {
			if (battlefieldCharacterInfo == null) {
				battlefieldCharacterInfo = new Dictionary<string, BattlefieldCharacterConfig>();
				BattlefieldCharacterConfig [] cfgs = DeSerializeObject<BattlefieldCharacterConfig[]>("config/character.db.txt");
				for (int i = 0; i < cfgs.Length; i++) {
					battlefieldCharacterInfo[cfgs[i].id + "_" + cfgs[i].type] = cfgs[i];
				}
			}

			BattlefieldCharacterConfig c;
			if (battlefieldCharacterInfo == null || !battlefieldCharacterInfo.TryGetValue(id + "_" + type, out c)) {
				position = Vector3.zero;
				scale = Vector3.one;
			} else {
				position.x = c.x;
				position.y = c.y;
				position.z = c.z;
				scale.x = c.sx;
				scale.y = c.sy;
				scale.z = c.sz;
			}
		}

        public static void GetBattlefieldCharacterBound(string id, string type, out Vector3 center, out Vector3 size) {
            if (battlefieldCharacterInfo == null) {
                battlefieldCharacterInfo = new Dictionary<string, BattlefieldCharacterConfig>();
                BattlefieldCharacterConfig[] cfgs = DeSerializeObject<BattlefieldCharacterConfig[]>("config/character.db.txt");
                for (int i = 0; i < cfgs.Length; i++) {
                    battlefieldCharacterInfo[cfgs[i].id + "_" + cfgs[i].type] = cfgs[i];
                }
            }

            BattlefieldCharacterConfig c;
            if (battlefieldCharacterInfo == null || !battlefieldCharacterInfo.TryGetValue(id + "_" + type, out c)) {
                center = Vector3.zero;
                size = Vector3.one;
            } else {
                center = new Vector3(c.boundCenterX, c.boundCenterY, c.boundCenterZ);
                size = new Vector3(c.boundSizeX, c.boundSizeY, c.boundSizeZ);
            }
        }
#endif
    }
}
