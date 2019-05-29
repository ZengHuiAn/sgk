using UnityEngine;
using System.Collections;

[XLua.LuaCallCSharp]
public class LookatWithScale2 : MonoBehaviour
{
    public Transform target;
    public Vector3 size = Vector3.one;
    public static Vector3 oriScale;

    void Start() {
        oriScale = transform.localScale;
    }


    void Update()
    {
        if (target != null)
        {
            transform.LookAt(target.position);

            float distance = Vector3.Distance(target.position, transform.position);
            Vector3 scale = Vector3.one;

            if (size.x > 0) scale.x = oriScale.x * distance / size.x;
            if (size.y > 0) scale.y = oriScale.y * distance / size.y;
            if (size.z > 0) scale.z = oriScale.z * distance / size.z;

            transform.localScale = scale;
        }
    }
}