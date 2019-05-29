using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UGUISpriteMaterialSelector : UGUISelector {
	[SerializeField]
	int _index = 0;

	public Material [] materials;

	public override int index {
		get {
			return _index;
		}

		set {
			if (value >= 0 && value < materials.Length) {
				_index = value;
				UpdateMaterial();
			}
		}
	}

    public override int Count {
        get { return (materials == null) ? 0 : materials.Length; }
    }

    [ContextMenu("Execute")]
	void UpdateMaterial() {
		Image image = GetComponent<Image>();
		if (image != null) image.material = materials[_index];
	}
}
