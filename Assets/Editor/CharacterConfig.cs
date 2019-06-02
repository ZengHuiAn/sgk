using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System;

namespace SGK {
	public class CharacterConfig {
		[MenuItem("Tools/SGK/GenerateConfig")]
		public static void GenerateBattleCharacterConfig() {
			string [] types = {"battle", "ui", "taskMonster", "timeMonster"};

			List<SGK.Database.BattlefieldCharacterConfig> battlefieldCharacterInfo = new List<Database.BattlefieldCharacterConfig>();

			for (int j = 0; j < types.Length; j++) {
				string [] folders = {"Assets/" + ResourceBundle.RESOURCES_DIR + "/" + SGK.Database.character_config_folder + types[j]};
				string[] assets = AssetDatabase.FindAssets("t:prefab", folders);

				for (int i = 0; i < assets.Length; i++) {
					string fileName = AssetDatabase.GUIDToAssetPath(assets[i]);

					GameObject obj = AssetDatabase.LoadAssetAtPath<GameObject>(fileName);
					if (obj != null) {
						Transform child = obj.transform.GetChild(0);

						string id = Path.GetFileNameWithoutExtension(fileName);

						SGK.Database.BattlefieldCharacterConfig t = new SGK.Database.BattlefieldCharacterConfig();

						t.id = id;
						t.type = types[j];
						t.x = child.position.x;
						t.y = child.position.y;
						t.z = child.position.z;

						t.sx = child.localScale.x;
						t.sy = child.localScale.y;
						t.sz = child.localScale.z;

                        BoxCollider collider = child.GetComponent<BoxCollider>();
                        if (collider != null) {
                            t.boundCenterX = collider.center.x;
                            t.boundCenterY = collider.center.y;
                            t.boundCenterZ = collider.center.z;
                            t.boundSizeX = collider.size.x;
                            t.boundSizeY = collider.size.y;
                            t.boundSizeZ = collider.size.z;
                        } else {
                            t.boundCenterX = t.boundCenterY = t.boundCenterZ = 0;
                            t.boundSizeX = t.boundSizeY = t.boundSizeZ = 0;
                        }

                        battlefieldCharacterInfo.Add(t);
					}
				}
			}
			Debug.LogFormat("battle character config count {0}", battlefieldCharacterInfo.Count);
			SGK.Database.SerializeObject(battlefieldCharacterInfo.ToArray(), "config/character.db.txt");
		}
	}
}
