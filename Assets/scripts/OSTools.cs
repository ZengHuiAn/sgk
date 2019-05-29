using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OSTools
{

#if UNITY_ANDROID && !UNITY_EDITOR
    static AndroidJavaClass mBridge;
    public static AndroidJavaClass Bridge {
        get {
            if ( mBridge == null)
            {
                mBridge = new AndroidJavaClass("com.cosyjoy.androidbridge.AndroidBridge");
            }
            return mBridge;
        }
    }

    public class OnClickCallBack : AndroidJavaProxy
    {
        public System.Action Callback;

        public OnClickCallBack(): 
            base("android.content.DialogInterface$OnClickListener")
        {
            
        }

        public void onClick(AndroidJavaObject dialog, int whichButton)
        {
            if (Callback != null)
            {
                Callback();
            }
        }
    }

#endif

    public static int GetCurrentMemory()
    {
#if UNITY_EDITOR
        return 0;
#elif UNITY_ANDROID && !UNITY_EDITOR
        try
        {
            return Bridge.CallStatic<int>("GetMemoryPSS");
        }
        catch (System.Exception ex)
        {
        	Debug.LogError(ex.ToString());
        }
        return 0;
#else
        throw new System.Exception("Do Not support 'GetCurrentMemory'");
#endif
    }

    public static void AlertDialog(string title, string text, string bt1, System.Action bt1cb, string bt2, System.Action bt2cb)
    {
#if UNITY_EDITOR
        if (UnityEditor.EditorUtility.DisplayDialog(title, text, bt1, bt2))
        {
            bt1cb();
        }
        else
        {
            bt2cb();
        }

#elif UNITY_ANDROID && !UNITY_EDITOR
        OnClickCallBack bt1ocb = new OnClickCallBack();
        bt1ocb.Callback = bt1cb;
        OnClickCallBack bt2ocb = new OnClickCallBack();
        bt2ocb.Callback = bt2cb;
        Bridge.CallStatic("AlertDialog", title, text, bt1, bt1ocb, bt2, bt2ocb);
#else
        throw new System.Exception("Do Not support 'AlertDialog'");
#endif
    }

}
