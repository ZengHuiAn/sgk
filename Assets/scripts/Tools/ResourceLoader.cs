using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ResourceLoader : MonoBehaviour {
    private void OnDestroy() {
        SGK.ResourcesManager.ResetLoader();
    }
}
