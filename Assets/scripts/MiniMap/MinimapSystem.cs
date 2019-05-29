
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using DG.Tweening;

[XLua.LuaCallCSharp]
public class MinimapSystem 
{
    static public void LoadImage(Texture2D texture2D, byte[] bytes)
    {
        if (texture2D && bytes != null)
        {
            texture2D.LoadImage(bytes);
        }
    }

    static public void SaveTexture(Texture2D texture, string path)
    {
        path = path.Replace('/', '\\');

        using (FileStream sv = new FileStream(path, FileMode.OpenOrCreate))
        {
            byte[] bs = texture.EncodeToPNG();
            sv.Write(bs, 0, bs.Length);
            sv.Close();
            sv.Dispose();
        }
    }

    static public byte[] GetTexture(string path)
    {
        path = path.Replace('/', '\\');
        if (File.Exists(path))
        {
            byte[] bs = File.ReadAllBytes(path);
            return bs;
        }
        return null;
    }

}