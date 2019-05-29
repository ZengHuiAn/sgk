using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using XLua;

namespace SGK
{
    class DropdownController : MonoBehaviour
    {
        private Dropdown m_dropDown;
        private void Awake()
        {
            m_dropDown = GetComponent<Dropdown>(); 
            if (m_dropDown == null) {
                m_dropDown = GetComponentInChildren<Dropdown>();
            }
        }
        public void AddOpotion(string str,Sprite image)
        {
            if (m_dropDown)
            {
                Dropdown.OptionData op = new Dropdown.OptionData();
                op.text = str;
                if (image != null)
                {
                    op.image = image;
                }
                m_dropDown.options.Add(op);
            }
        }
    }
}
