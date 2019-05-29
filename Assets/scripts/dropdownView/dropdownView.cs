using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace SGK {
    public class dropdownView : MonoBehaviour {
        public RectTransform m_content;
        public GameObject m_itemPrefab;
        public GameObject m_secondItem;
        public GameObject m_pool;

        private int m_count = 0;
        // private float m_itemWidth = 0;
        private float m_itemHeight = 0;

        // private float m_secondWidth = 0;
        private float m_secondHeight = 0;

        private Dictionary<int, GameObject> m_itemMenu;
        private List<GameObject> m_itemPool;
        private List<GameObject> m_secondItemPool;

        private struct SecondItemStr {
            public int index;
            public GameObject go;
            public SecondItemStr(int idx, GameObject obj) {
                index = idx;
                go = obj;
            }
        }
        private List<SecondItemStr> m_secondItemMenu;

        private void Awake() {
            m_itemMenu = new Dictionary<int, GameObject>();
            m_itemPool = new List<GameObject>();
            m_secondItemPool = new List<GameObject>();
            m_secondItemMenu = new List<SecondItemStr>();
            if (m_itemPrefab) {
                // m_itemWidth = m_itemPrefab.GetComponent<RectTransform>().sizeDelta.x;
                m_itemHeight = m_itemPrefab.GetComponent<RectTransform>().sizeDelta.y;
            }
            if (m_secondItem) {
                // m_secondWidth = m_secondItem.GetComponent<RectTransform>().sizeDelta.x;
                m_secondHeight = m_secondItem.GetComponent<RectTransform>().sizeDelta.y;
            }
        }

        public void upContentSize(int index) {
            if (index != 0) {
                foreach (var it in m_itemMenu) {
                    if (it.Key > index) {
                        var _p = it.Value.transform.localPosition;
                        it.Value.transform.localPosition = new Vector3(_p.x, _p.y - m_secondHeight, _p.z);
                    }
                }
            }
            m_content.sizeDelta = new Vector2(m_content.sizeDelta.x, m_count * m_itemHeight + m_secondItemMenu.Count * m_secondHeight);
        }

        public GameObject addSecondItem(int index) {
            GameObject _go;
            if (m_secondItemPool.Count > 0) {
                _go = m_secondItemPool[0];
                _go.transform.SetParent(m_itemMenu[index].transform);
                m_secondItemPool.Remove(m_secondItemPool[0]);
            } else {
                _go = GameObject.Instantiate(m_secondItem, m_itemMenu[index].transform) as GameObject;
                _go.name = m_secondItem.name + index;
            }
            _go.transform.localPosition = new Vector3(_go.transform.localPosition.x, -(getSecondItemNumber(index) * m_secondHeight + m_itemHeight));
            _go.SetActive(true);
            var _str = new SecondItemStr(index, _go);
            m_secondItemMenu.Add(_str);
            upContentSize(index);
            return _go;
        }

        private int getSecondItemNumber(int index) {
            int i = 0;
            foreach (var it in m_secondItemMenu) {
                if (it.index == index) {
                    ++i;
                }
            }
            return i;
        }

        public void removeAllSecondItem() {
            for (int i = m_secondItemMenu.Count - 1; i >= 0; --i) {
                removeSecondItem(m_secondItemMenu[i].index);
            }
        }

        public void removeAllItem() {
            m_count = 0;
            foreach(var it in m_secondItemMenu) {
                it.go.transform.SetParent(m_pool.transform);
                it.go.SetActive(false);
                m_secondItemPool.Add(it.go);
            }
            foreach(var it in m_itemMenu) {
                it.Value.gameObject.transform.SetParent(m_pool.transform);
                it.Value.gameObject.SetActive(false);
                m_itemPool.Add(it.Value);
            }
            m_itemMenu.Clear();
            m_secondItemMenu.Clear();
        }

        public void removeSecondItem(int index) {
            for (int i = m_secondItemMenu.Count - 1; i >= 0; --i) {
                if (m_secondItemMenu[i].index == index) {
                    m_secondItemMenu[i].go.transform.SetParent(m_pool.transform);
                    m_secondItemMenu[i].go.SetActive(false);
                    m_secondItemPool.Add(m_secondItemMenu[i].go);
                    foreach (var it in m_itemMenu) {
                        if (it.Key > index) {
                            var _p = it.Value.transform.localPosition;
                            it.Value.transform.localPosition = new Vector3(_p.x, _p.y + m_secondHeight, _p.z);
                        }
                    }
                    m_secondItemMenu.Remove(m_secondItemMenu[i]);
                }
            }
            foreach (var it in m_itemMenu) {
                if (it.Key > index) {
                    var _p = it.Value.transform.localPosition;
                    it.Value.transform.localPosition = new Vector3(_p.x, _p.y + m_secondHeight, _p.z);
                }
            }
            upContentSize(index);
        }

        public GameObject addItemMenu(int index) {
            GameObject _go;
            if (m_itemPool.Count > 0) {
                _go = m_itemPool[0];
                _go.transform.SetParent(m_content);
                m_itemPool.Remove(m_itemPool[0]);
            } else {
                _go = GameObject.Instantiate(m_itemPrefab, m_content) as GameObject;
                _go.name = m_itemPrefab.name + index;
            }
            _go.transform.localPosition = new Vector3(0, -m_itemHeight * m_count, 0);
            _go.SetActive(true);
            ++m_count;
            m_itemMenu.Add(index, _go);
            upContentSize(0);
            return _go;
        }

        public int getCount() {
            return m_count;
        }
        // Use this for initialization
        void Start() {

        }

        // Update is called once per frame
        void Update() {

        }
    }
}