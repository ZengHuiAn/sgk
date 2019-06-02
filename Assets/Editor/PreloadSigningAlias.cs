using UnityEngine;
using UnityEditor;
using System.IO;

[InitializeOnLoad]
public class PreloadSigningAlias
{
    static PreloadSigningAlias()
    {
        PlayerSettings.Android.keystorePass = "sgk@2018";
        PlayerSettings.Android.keyaliasName = "sgk";
        PlayerSettings.Android.keyaliasPass = "sgk@2018";
    }

}