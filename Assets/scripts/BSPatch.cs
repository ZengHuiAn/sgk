using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

public class BSPatch {

    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern int bspatch_merge(string old_file, string out_file, string patch_file);


    public static void Main()
    {
        string old_file = Application.persistentDataPath + "/a";
        string patch_file = Application.persistentDataPath + "/c";
        string out_file = Application.persistentDataPath + "/d";

        Debug.Log("bspatch merge result: " + bspatch_merge(old_file, out_file, patch_file));
    }
}
