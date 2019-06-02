using UnityEngine;
using System.Collections;

public class MeshSortingOrder : MonoBehaviour {

    public string layerName;
    public int order;

    private Renderer rend;
    void Awake() {
        rend = GetComponent<Renderer>();
        rend.sortingLayerName = layerName;
        rend.sortingOrder = order;
    }

    public void Update() {
        if (rend.sortingLayerName != layerName)
            rend.sortingLayerName = layerName;
        if (rend.sortingOrder != order)
            rend.sortingOrder = order;
    }

    public void OnValidate() {
        rend = GetComponent<Renderer>();
        rend.sortingLayerName = layerName;
        rend.sortingOrder = order;
    }

    public void AddOrder(int addOrder)
    {
        rend = GetComponent<Renderer>();
        order = order + addOrder;
        rend.sortingOrder = order;
    }


}
