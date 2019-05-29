//----------------------------------------------
//            NGUI: Next-Gen UI kit
// Copyright © 2011-2014 Tasharen Entertainment
//----------------------------------------------

using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Reflection;

/// <summary>
/// Tools for the editor
/// </summary>

public class NGUIEditorTools
{
	static Texture2D mBackdropTex;
	static Texture2D mContrastTex;
	static Texture2D mGradientTex;
	static GameObject mPrevious;

	/// <summary>
	/// Returns a blank usable 1x1 white texture.
	/// </summary>

	static public Texture2D blankTexture
	{
		get
		{
			return EditorGUIUtility.whiteTexture;
		}
	}


	/// <summary>
	/// Draws the tiled texture. Like GUI.DrawTexture() but tiled instead of stretched.
	/// </summary>

	static public void DrawTiledTexture (Rect rect, Texture tex)
	{
		GUI.BeginGroup(rect);
		{
			int width  = Mathf.RoundToInt(rect.width);
			int height = Mathf.RoundToInt(rect.height);

			for (int y = 0; y < height; y += tex.height)
			{
				for (int x = 0; x < width; x += tex.width)
				{
					GUI.DrawTexture(new Rect(x, y, tex.width, tex.height), tex);
				}
			}
		}
		GUI.EndGroup();
	}


	/// <summary>
	/// Draw a single-pixel outline around the specified rectangle.
	/// </summary>

	static public void DrawOutline (Rect rect, Color color)
	{
		if (Event.current.type == EventType.Repaint)
		{
			Texture2D tex = blankTexture;
			GUI.color = color;
			GUI.DrawTexture(new Rect(rect.xMin, rect.yMin, 1f, rect.height), tex);
			GUI.DrawTexture(new Rect(rect.xMax, rect.yMin, 1f, rect.height), tex);
			GUI.DrawTexture(new Rect(rect.xMin, rect.yMin, rect.width, 1f), tex);
			GUI.DrawTexture(new Rect(rect.xMin, rect.yMax, rect.width, 1f), tex);
			GUI.color = Color.white;
		}
	}

	/// <summary>
	/// Draw a selection outline around the specified rectangle.
	/// </summary>

	static public void DrawOutline (Rect rect, Rect relative, Color color)
	{
		if (Event.current.type == EventType.Repaint)
		{
			// Calculate where the outer rectangle would be
			float x = rect.xMin + rect.width * relative.xMin;
			float y = rect.yMax - rect.height * relative.yMin;
			float width = rect.width * relative.width;
			float height = -rect.height * relative.height;
			relative = new Rect(x, y, width, height);

			// Draw the selection
			DrawOutline(relative, color);
		}
	}

	/// <summary>
	/// Draw a visible separator in addition to adding some padding.
	/// </summary>

	static public void DrawSeparator ()
	{
		GUILayout.Space(12f);

		if (Event.current.type == EventType.Repaint)
		{
			Texture2D tex = blankTexture;
			Rect rect = GUILayoutUtility.GetLastRect();
			GUI.color = new Color(0f, 0f, 0f, 0.25f);
			GUI.DrawTexture(new Rect(0f, rect.yMin + 6f, Screen.width, 4f), tex);
			GUI.DrawTexture(new Rect(0f, rect.yMin + 6f, Screen.width, 1f), tex);
			GUI.DrawTexture(new Rect(0f, rect.yMin + 9f, Screen.width, 1f), tex);
			GUI.color = Color.white;
		}
	}

	/// <summary>
	/// Convenience function that displays a list of sprites and returns the selected value.
	/// </summary>

	static public string DrawList (string field, string[] list, string selection, params GUILayoutOption[] options)
	{
		if (list != null && list.Length > 0)
		{
			int index = 0;
			if (string.IsNullOrEmpty(selection)) selection = list[0];

			// We need to find the sprite in order to have it selected
			if (!string.IsNullOrEmpty(selection))
			{
				for (int i = 0; i < list.Length; ++i)
				{
					if (selection.Equals(list[i], System.StringComparison.OrdinalIgnoreCase))
					{
						index = i;
						break;
					}
				}
			}

			// Draw the sprite selection popup
			index = string.IsNullOrEmpty(field) ?
				EditorGUILayout.Popup(index, list, options) :
				EditorGUILayout.Popup(field, index, list, options);

			return list[index];
		}
		return null;
	}

	/// <summary>
	/// Convenience function that displays a list of sprites and returns the selected value.
	/// </summary>

	static public string DrawAdvancedList (string field, string[] list, string selection, params GUILayoutOption[] options)
	{
		if (list != null && list.Length > 0)
		{
			int index = 0;
			if (string.IsNullOrEmpty(selection)) selection = list[0];

			// We need to find the sprite in order to have it selected
			if (!string.IsNullOrEmpty(selection))
			{
				for (int i = 0; i < list.Length; ++i)
				{
					if (selection.Equals(list[i], System.StringComparison.OrdinalIgnoreCase))
					{
						index = i;
						break;
					}
				}
			}

			// Draw the sprite selection popup
			index = string.IsNullOrEmpty(field) ?
				DrawPrefixList(index, list, options) :
				DrawPrefixList(field, index, list, options);

			return list[index];
		}
		return null;
	}


	static public bool WillLosePrefab (GameObject root)
	{
		if (root == null) return false;

		if (root.transform != null)
		{
			// Check if the selected object is a prefab instance and display a warning
			PrefabType type = PrefabUtility.GetPrefabType(root);

			if (type == PrefabType.PrefabInstance)
			{
				return EditorUtility.DisplayDialog("Losing prefab",
					"This action will lose the prefab connection. Are you sure you wish to continue?",
					"Continue", "Cancel");
			}
		}
		return true;
	}

	/// <summary>
	/// Helper function that returns the folder where the current selection resides.
	/// </summary>

	static public string GetSelectionFolder ()
	{
		if (Selection.activeObject != null)
		{
			string path = AssetDatabase.GetAssetPath(Selection.activeObject.GetInstanceID());

			if (!string.IsNullOrEmpty(path))
			{
				int dot = path.LastIndexOf('.');
				int slash = Mathf.Max(path.LastIndexOf('/'), path.LastIndexOf('\\'));
				if (slash > 0) return (dot > slash) ? path.Substring(0, slash + 1) : path + "/";
			}
		}
		return "Assets/";
	}

	/// <summary>
	/// Struct type for the integer vector field below.
	/// </summary>

	public struct IntVector
	{
		public int x;
		public int y;
	}

	/// <summary>
	/// Integer vector field.
	/// </summary>

	static public IntVector IntPair (string prefix, string leftCaption, string rightCaption, int x, int y)
	{
		GUILayout.BeginHorizontal();

		if (string.IsNullOrEmpty(prefix))
		{
			GUILayout.Space(82f);
		}
		else
		{
			GUILayout.Label(prefix, GUILayout.Width(74f));
		}

		NGUIEditorTools.SetLabelWidth(48f);

		IntVector retVal;
		retVal.x = EditorGUILayout.IntField(leftCaption, x, GUILayout.MinWidth(30f));
		retVal.y = EditorGUILayout.IntField(rightCaption, y, GUILayout.MinWidth(30f));

		NGUIEditorTools.SetLabelWidth(80f);

		GUILayout.EndHorizontal();
		return retVal;
	}

	/// <summary>
	/// Integer rectangle field.
	/// </summary>

	static public Rect IntRect (string prefix, Rect rect)
	{
		int left	= Mathf.RoundToInt(rect.xMin);
		int top		= Mathf.RoundToInt(rect.yMin);
		int width	= Mathf.RoundToInt(rect.width);
		int height	= Mathf.RoundToInt(rect.height);

		NGUIEditorTools.IntVector a = NGUIEditorTools.IntPair(prefix, "Left", "Top", left, top);
		NGUIEditorTools.IntVector b = NGUIEditorTools.IntPair(null, "Width", "Height", width, height);

		return new Rect(a.x, a.y, b.x, b.y);
	}

	/// <summary>
	/// Integer vector field.
	/// </summary>

	static public Vector4 IntPadding (string prefix, Vector4 v)
	{
		int left	= Mathf.RoundToInt(v.x);
		int top		= Mathf.RoundToInt(v.y);
		int right	= Mathf.RoundToInt(v.z);
		int bottom	= Mathf.RoundToInt(v.w);

		NGUIEditorTools.IntVector a = NGUIEditorTools.IntPair(prefix, "Left", "Top", left, top);
		NGUIEditorTools.IntVector b = NGUIEditorTools.IntPair(null, "Right", "Bottom", right, bottom);

		return new Vector4(a.x, a.y, b.x, b.y);
	}

	/// <summary>
	/// Find all scene components, active or inactive.
	/// </summary>

	static public List<T> FindAll<T> () where T : Component
	{
		T[] comps = Resources.FindObjectsOfTypeAll(typeof(T)) as T[];

		List<T> list = new List<T>();

		foreach (T comp in comps)
		{
			if (comp.gameObject.hideFlags == 0)
			{
				string path = AssetDatabase.GetAssetPath(comp.gameObject);
				if (string.IsNullOrEmpty(path)) list.Add(comp);
			}
		}
		return list;
	}

	static public bool DrawPrefixButton (string text)
	{
		return GUILayout.Button(text, "DropDown", GUILayout.Width(76f));
	}

	static public bool DrawPrefixButton (string text, params GUILayoutOption[] options)
	{
		return GUILayout.Button(text, "DropDown", options);
	}

	static public int DrawPrefixList (int index, string[] list, params GUILayoutOption[] options)
	{
		return EditorGUILayout.Popup(index, list, "DropDown", options);
	}

	static public int DrawPrefixList (string text, int index, string[] list, params GUILayoutOption[] options)
	{
		return EditorGUILayout.Popup(text, index, list, "DropDown", options);
	}    

	/// <summary>
	/// Select the specified game object and remember what was selected before.
	/// </summary>

	static public void Select (GameObject go)
	{
		mPrevious = Selection.activeGameObject;
		Selection.activeGameObject = go;
	}
	
	/// <summary>
	/// Select the previous game object.
	/// </summary>

	static public void SelectPrevious ()
	{
		if (mPrevious != null)
		{
			Selection.activeGameObject = mPrevious;
			mPrevious = null;
		}
	}

	/// <summary>
	/// Previously selected game object.
	/// </summary>

	static public GameObject previousSelection { get { return mPrevious; } }

	/// <summary>
	/// Helper function that checks to see if the scale is uniform.
	/// </summary>

	static public bool IsUniform (Vector3 scale)
	{
		return Mathf.Approximately(scale.x, scale.y) && Mathf.Approximately(scale.x, scale.z);
	}



	/// <summary>
	/// Draw a distinctly different looking header label
	/// </summary>

	static public bool DrawHeader (string text) { return DrawHeader(text, text, false); }

	/// <summary>
	/// Draw a distinctly different looking header label
	/// </summary>

	static public bool DrawHeader (string text, string key) { return DrawHeader(text, key, false); }

	/// <summary>
	/// Draw a distinctly different looking header label
	/// </summary>

	static public bool DrawHeader (string text, bool forceOn) { return DrawHeader(text, text, forceOn); }

	/// <summary>
	/// Draw a distinctly different looking header label
	/// </summary>

	static public bool DrawHeader (string text, string key, bool forceOn)
	{
		bool state = EditorPrefs.GetBool(key, true);

		GUILayout.Space(3f);
		if (!forceOn && !state) GUI.backgroundColor = new Color(0.8f, 0.8f, 0.8f);
		GUILayout.BeginHorizontal();
		GUILayout.Space(3f);

		GUI.changed = false;
#if UNITY_3_5
		if (state) text = "\u25B2 " + text;
		else text = "\u25BC " + text;
		if (!GUILayout.Toggle(true, text, "dragtab", GUILayout.MinWidth(20f))) state = !state;
#else
		text = "<b><size=11>" + text + "</size></b>";
		if (state) text = "\u25B2 " + text;
		else text = "\u25BC " + text;
		if (!GUILayout.Toggle(true, text, "dragtab", GUILayout.MinWidth(20f))) state = !state;
#endif
		if (GUI.changed) EditorPrefs.SetBool(key, state);

		GUILayout.Space(2f);
		GUILayout.EndHorizontal();
		GUI.backgroundColor = Color.white;
		if (!forceOn && !state) GUILayout.Space(3f);
		return state;
	}

	/// <summary>
	/// Begin drawing the content area.
	/// </summary>

	static public void BeginContents ()
	{
		GUILayout.BeginHorizontal();
		GUILayout.Space(4f);
		EditorGUILayout.BeginHorizontal("AS TextArea", GUILayout.MinHeight(10f));
		GUILayout.BeginVertical();
		GUILayout.Space(2f);
	}

	/// <summary>
	/// End drawing the content area.
	/// </summary>

	static public void EndContents ()
	{
		GUILayout.Space(3f);
		GUILayout.EndVertical();
		EditorGUILayout.EndHorizontal();
		GUILayout.Space(3f);
		GUILayout.EndHorizontal();
		GUILayout.Space(3f);
	}

	/// <summary>
	/// Helper function that draws a serialized property.
	/// </summary>

	static public SerializedProperty DrawProperty (SerializedObject serializedObject, string property, params GUILayoutOption[] options)
	{
		return DrawProperty(null, serializedObject, property, false, options);
	}

	/// <summary>
	/// Helper function that draws a serialized property.
	/// </summary>

	static public SerializedProperty DrawProperty (string label, SerializedObject serializedObject, string property, params GUILayoutOption[] options)
	{
		return DrawProperty(label, serializedObject, property, false, options);
	}

	/// <summary>
	/// Helper function that draws a serialized property.
	/// </summary>

	static public SerializedProperty DrawPaddedProperty (SerializedObject serializedObject, string property, params GUILayoutOption[] options)
	{
		return DrawProperty(null, serializedObject, property, true, options);
	}

	/// <summary>
	/// Helper function that draws a serialized property.
	/// </summary>

	static public SerializedProperty DrawPaddedProperty (string label, SerializedObject serializedObject, string property, params GUILayoutOption[] options)
	{
		return DrawProperty(label, serializedObject, property, true, options);
	}

	/// <summary>
	/// Helper function that draws a serialized property.
	/// </summary>

	static public SerializedProperty DrawProperty (string label, SerializedObject serializedObject, string property, bool padding, params GUILayoutOption[] options)
	{
		SerializedProperty sp = serializedObject.FindProperty(property);

		if (sp != null)
		{
			if (padding) EditorGUILayout.BeginHorizontal();
			
			if (label != null) EditorGUILayout.PropertyField(sp, new GUIContent(label), options);
			else EditorGUILayout.PropertyField(sp, options);

			if (padding) 
			{
				GUILayout.Space(18f);
				EditorGUILayout.EndHorizontal();
			}
		}
		return sp;
	}

	/// <summary>
	/// Helper function that draws a serialized property.
	/// </summary>

	static public void DrawProperty (string label, SerializedProperty sp, params GUILayoutOption[] options)
	{
		DrawProperty(label, sp, true, options);
	}

	/// <summary>
	/// Helper function that draws a serialized property.
	/// </summary>

	static public void DrawProperty (string label, SerializedProperty sp, bool padding, params GUILayoutOption[] options)
	{
		if (sp != null)
		{
			if (padding) EditorGUILayout.BeginHorizontal();

			if (label != null) EditorGUILayout.PropertyField(sp, new GUIContent(label), options);
			else EditorGUILayout.PropertyField(sp, options);

			if (padding)
			{
				GUILayout.Space(18f);
				EditorGUILayout.EndHorizontal();
			}
		}
	}

	/// <summary>
	/// Helper function that draws a compact Vector4.
	/// </summary>

	static public void DrawBorderProperty (string name, SerializedObject serializedObject, string field)
	{
		if (serializedObject.FindProperty(field) != null)
		{
			GUILayout.BeginHorizontal();
			{
				GUILayout.Label(name, GUILayout.Width(75f));

				NGUIEditorTools.SetLabelWidth(50f);
				GUILayout.BeginVertical();
				NGUIEditorTools.DrawProperty("Left", serializedObject, field + ".x", GUILayout.MinWidth(80f));
				NGUIEditorTools.DrawProperty("Bottom", serializedObject, field + ".y", GUILayout.MinWidth(80f));
				GUILayout.EndVertical();

				GUILayout.BeginVertical();
				NGUIEditorTools.DrawProperty("Right", serializedObject, field + ".z", GUILayout.MinWidth(80f));
				NGUIEditorTools.DrawProperty("Top", serializedObject, field + ".w", GUILayout.MinWidth(80f));
				GUILayout.EndVertical();

				NGUIEditorTools.SetLabelWidth(80f);
			}
			GUILayout.EndHorizontal();
		}
	}

	/// <summary>
	/// Helper function that draws a compact Rect.
	/// </summary>

	static public void DrawRectProperty (string name, SerializedObject serializedObject, string field)
	{
		DrawRectProperty(name, serializedObject, field, 56f, 18f);
	}

	/// <summary>
	/// Helper function that draws a compact Rect.
	/// </summary>

	static public void DrawRectProperty (string name, SerializedObject serializedObject, string field, float labelWidth, float spacing)
	{
		if (serializedObject.FindProperty(field) != null)
		{
			GUILayout.BeginHorizontal();
			{
				GUILayout.Label(name, GUILayout.Width(labelWidth));

				NGUIEditorTools.SetLabelWidth(20f);
				GUILayout.BeginVertical();
				NGUIEditorTools.DrawProperty("X", serializedObject, field + ".x", GUILayout.MinWidth(50f));
				NGUIEditorTools.DrawProperty("Y", serializedObject, field + ".y", GUILayout.MinWidth(50f));
				GUILayout.EndVertical();

				NGUIEditorTools.SetLabelWidth(50f);
				GUILayout.BeginVertical();
				NGUIEditorTools.DrawProperty("Width", serializedObject, field + ".width", GUILayout.MinWidth(80f));
				NGUIEditorTools.DrawProperty("Height", serializedObject, field + ".height", GUILayout.MinWidth(80f));
				GUILayout.EndVertical();

				NGUIEditorTools.SetLabelWidth(80f);
				if (spacing != 0f) GUILayout.Space(spacing);
			}
			GUILayout.EndHorizontal();
		}
	}

	/// <summary>
	/// Unity 4.3 changed the way LookLikeControls works.
	/// </summary>

	static public void SetLabelWidth (float width)
	{
#if UNITY_3_5 || UNITY_4_0 || UNITY_4_1 || UNITY_4_2
		EditorGUIUtility.LookLikeControls(width);
#else
		EditorGUIUtility.labelWidth = width;
#endif
	}

	/// <summary>
	/// Create an undo point for the specified objects.
	/// </summary>

	static public void RegisterUndo (string name, params Object[] objects)
	{
		if (objects != null && objects.Length > 0)
		{
#if UNITY_3_5 || UNITY_4_0 || UNITY_4_1 || UNITY_4_2
			UnityEditor.Undo.RegisterUndo(objects, name);
#else
			UnityEditor.Undo.RecordObjects(objects, name);
#endif
			foreach (Object obj in objects)
			{
				if (obj == null) continue;
				EditorUtility.SetDirty(obj);
			}
		}
	}

	/// <summary>
	/// Unity 4.5+ makes it possible to hide the move tool.
	/// </summary>

	static public void HideMoveTool (bool hide)
	{
#if !UNITY_3_5 && !UNITY_4_0 && !UNITY_4_1 && !UNITY_4_2 && !UNITY_4_3
		UnityEditor.Tools.hidden = hide && (UnityEditor.Tools.current == UnityEditor.Tool.Move);
#endif
	}

	/// <summary>
	/// Convenience function that replaces the specified MonoBehaviour with one of specified class ID.
	/// </summary>

	static public SerializedObject ReplaceClass (MonoBehaviour mb, int classID)
	{
		SerializedObject ob = new SerializedObject(mb);
		ob.Update();
		ob.FindProperty("m_Script").objectReferenceInstanceIDValue = classID;
		ob.ApplyModifiedProperties();
		ob.Update();
		return ob;
	}

	/// <summary>
	/// Convenience function that replaces the specified MonoBehaviour with one of specified class ID.
	/// </summary>

	static public void ReplaceClass (SerializedObject ob, int classID)
	{
		ob.FindProperty("m_Script").objectReferenceInstanceIDValue = classID;
		ob.ApplyModifiedProperties();
		ob.Update();
	}
    

	static public Object LoadAsset (string path)
	{
		if (string.IsNullOrEmpty(path)) return null;
		return AssetDatabase.LoadMainAssetAtPath(path);
	}

	/// <summary>
	/// Convenience function to load an asset of specified type, given the full path to it.
	/// </summary>

	static public T LoadAsset<T> (string path) where T: Object
	{
		Object obj = LoadAsset(path);
		if (obj == null) return null;

		T val = obj as T;
		if (val != null) return val;

		if (typeof(T).IsSubclassOf(typeof(Component)))
		{
			if (obj.GetType() == typeof(GameObject))
			{
				GameObject go = obj as GameObject;
				return go.GetComponent(typeof(T)) as T;
			}
		}
		return null;
	}

	/// <summary>
	/// Get the specified object's GUID.
	/// </summary>

	static public string ObjectToGUID (Object obj)
	{
		string path = AssetDatabase.GetAssetPath(obj);
		return (!string.IsNullOrEmpty(path)) ? AssetDatabase.AssetPathToGUID(path) : null;
	}

#if !UNITY_3_5
	static MethodInfo s_GetInstanceIDFromGUID;
#endif

	/// <summary>
	/// Convert the specified GUID to an object reference.
	/// </summary>

	static public Object GUIDToObject (string guid)
	{
		if (string.IsNullOrEmpty(guid)) return null;
#if !UNITY_3_5
		// This method is not going to be available in Unity 3.5
		if (s_GetInstanceIDFromGUID == null)
			s_GetInstanceIDFromGUID = typeof(AssetDatabase).GetMethod("GetInstanceIDFromGUID", BindingFlags.Static | BindingFlags.NonPublic);
		int id = (int)s_GetInstanceIDFromGUID.Invoke(null, new object[] { guid });
		if (id != 0) return EditorUtility.InstanceIDToObject(id);
#endif
		string path = AssetDatabase.GUIDToAssetPath(guid);
		if (string.IsNullOrEmpty(path)) return null;
		return AssetDatabase.LoadAssetAtPath(path, typeof(Object));
	}

	/// <summary>
	/// Convert the specified GUID to an object reference of specified type.
	/// </summary>

	static public T GUIDToObject<T> (string guid) where T : Object
	{
		Object obj = GUIDToObject(guid);
		if (obj == null) return null;

		System.Type objType = obj.GetType();
		if (objType == typeof(T) || objType.IsSubclassOf(typeof(T))) return obj as T;

		if (objType == typeof(GameObject) && typeof(T).IsSubclassOf(typeof(Component)))
		{
			GameObject go = obj as GameObject;
			return go.GetComponent(typeof(T)) as T;
		}
		return null;
	}

	/// <summary>
	/// Add a border around the specified color buffer with the width and height of a single pixel all around.
	/// The returned color buffer will have its width and height increased by 2.
	/// </summary>

	static public Color32[] AddBorder (Color32[] colors, int width, int height)
	{
		int w2 = width + 2;
		int h2 = height + 2;

		Color32[] c2 = new Color32[w2 * h2];

		for (int y2 = 0; y2 < h2; ++y2)
		{
			int y1 = NGUIMath.ClampIndex(y2 - 1, height);

			for (int x2 = 0; x2 < w2; ++x2)
			{
				int x1 = NGUIMath.ClampIndex(x2 - 1, width);
				int i2 = x2 + y2 * w2;
				c2[i2] = colors[x1 + y1 * width];

				if (x2 == 0 || x2 + 1 == w2 || y2 == 0 || y2 + 1 == h2)
					c2[i2].a = 0;
			}
		}
		return c2;
	}

	/// <summary>
	/// Add a soft shadow to the specified color buffer.
	/// The buffer must have some padding around the edges in order for this to work properly.
	/// </summary>

	static public void AddShadow (Color32[] colors, int width, int height, Color shadow)
	{
		Color sh = shadow;
		sh.a = 1f;

		for (int y2 = 0; y2 < height; ++y2)
		{
			for (int x2 = 0; x2 < width; ++x2)
			{
				int index = x2 + y2 * width;
				Color32 uc = colors[index];
				if (uc.a == 255) continue;

				Color original = uc;
				float val = original.a;
				int count = 1;
				float div1 = 1f / 255f;
				float div2 = 2f / 255f;
				float div3 = 3f / 255f;

				// Left
				if (x2 != 0)
				{
					val += colors[x2 - 1 + y2 * width].a * div1;
					count += 1;
				}

				// Top
				if (y2 + 1 != height)
				{
					val += colors[x2 + (y2 + 1) * width].a * div2;
					count += 2;
				}

				// Top-left
				if (x2 != 0 && y2 + 1 != height)
				{
					val += colors[x2 - 1 + (y2 + 1) * width].a * div3;
					count += 3;
				}

				val /= count;

				Color c = Color.Lerp(original, sh, shadow.a * val);
				colors[index] = Color.Lerp(c, original, original.a);
			}
		}
	}

	/// <summary>
	/// Add a visual depth effect to the specified color buffer.
	/// The buffer must have some padding around the edges in order for this to work properly.
	/// </summary>

	static public void AddDepth (Color32[] colors, int width, int height, Color shadow)
	{
		Color sh = shadow;
		sh.a = 1f;

		for (int y2 = 0; y2 < height; ++y2)
		{
			for (int x2 = 0; x2 < width; ++x2)
			{
				int index = x2 + y2 * width;
				Color32 uc = colors[index];
				if (uc.a == 255) continue;

				Color original = uc;
				float val = original.a * 4f;
				int count = 4;
				float div1 = 1f / 255f;
				float div2 = 2f / 255f;

				if (x2 != 0)
				{
					val += colors[x2 - 1 + y2 * width].a * div2;
					count += 2;
				}

				if (x2 + 1 != width)
				{
					val += colors[x2 + 1 + y2 * width].a * div2;
					count += 2;
				}

				if (y2 != 0)
				{
					val += colors[x2 + (y2 - 1) * width].a * div2;
					count += 2;
				}

				if (y2 + 1 != height)
				{
					val += colors[x2 + (y2 + 1) * width].a * div2;
					count += 2;
				}

				if (x2 != 0 && y2 != 0)
				{
					val += colors[x2 - 1 + (y2 - 1) * width].a * div1;
					++count;
				}

				if (x2 != 0 && y2 + 1 != height)
				{
					val += colors[x2 - 1 + (y2 + 1) * width].a * div1;
					++count;
				}

				if (x2 + 1 != width && y2 != 0)
				{
					val += colors[x2 + 1 + (y2 - 1) * width].a * div1;
					++count;
				}

				if (x2 + 1 != width && y2 + 1 != height)
				{
					val += colors[x2 + 1 + (y2 + 1) * width].a * div1;
					++count;
				}

				val /= count;

				Color c = Color.Lerp(original, sh, shadow.a * val);
				colors[index] = Color.Lerp(c, original, original.a);
			}
		}
	}
}
