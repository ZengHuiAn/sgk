using UnityEngine;
using System.Collections;
using System.Text.RegularExpressions;
using System.Collections.Generic;
using System.Text;
using NPinyin;
namespace SGK {
public class SortChinese : MonoBehaviour {

	// Use this for initialization
	void Start () {

        //Debug.Log(GetSpellCodeASCII("麒麟aa"));
        //Debug.Log(GetSpellCodeASCII("2456"));
        //Debug.Log(GetSpellCodeASCII("qsss"));
        //Debug.Log(GetSpellCodeASCII("Qfggg"));
        //Debug.Log(GetSpellCodeASCII("汽车"));
        //Debug.Log(GetSpellCodeASCII("孙")); 
	}
	
	// Update is called once per frame
	void Update () {
	
	}

 /// <summary>
    /// 传首个字符串,返回ASCII码（65—90）
 /// </summary>
 /// <param name="CnStr"></param>
 /// <returns></returns>

    public static int GetSpellCodeASCII(string name)
    {
        string CnStr = name.Substring(0,1);
        int num;
        if (int.TryParse(CnStr,out num))
        {
            return num;
        }
        string str = GetCharSpellCode(CnStr);
        byte[] array = System.Text.Encoding.ASCII.GetBytes(str);
        return array[0];

    }

    /// <summary>

    /// 得到一个汉字的拼音第一个字母，如果是一个英文字母则直接返回大写字母

    /// </summary>

    /// <param name="CnChar">单个汉字</param>

    /// <returns>单个大写字母</returns>

    private static string GetCharSpellCode(string CnChar)
    {
        byte[] ZW = System.Text.Encoding.Default.GetBytes(CnChar);

        //如果是字母，则直接返回首字母

        if (ZW.Length == 1)
        {

            return CnChar.ToUpper();

        }
        else
        {

            return Pinyin.GetPinyin(CnChar).Substring(0, 1);

        }      

    }   
}
}