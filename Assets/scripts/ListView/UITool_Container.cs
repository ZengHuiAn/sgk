using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UITool_Container : MonoBehaviour
{
    public bool playerOnStart;
    //public Arrangement arrangement;
    public List<Transform> notSetPosObjList;
    //一共多少行
    public int column = 1;
    [HideInInspector]
    public float cellWidth = 200f;
    [HideInInspector]
    public float cellHeight = 200f;
    //是否忽略屏幕适配
    public bool isIgnoreAdapter;
    public Action<Transform, int, int> onInitializeItem;
    [HideInInspector]
    public bool isLoop;

    public Transform contentPosTrans;
    public bool isUIAnimComplete;


}
