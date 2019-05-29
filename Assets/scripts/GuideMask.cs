using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using UnityEngine.Sprites;

namespace SGK {
    public class GuideMask : MaskableGraphic, IPointerDownHandler, IPointerUpHandler {
        public System.Action onClick;
        public GameObject Box;
        public bool NeedPass = true;
        public float diameter = 0;
        private bool m_isCircle = false;
        public GameObject circleNode;
        private int m_click = 1;
        public System.Action onClick2;
        public System.Action onPress;
        private bool isPressing = false;
        private bool startPress = false;
        private float _pressTime = 0;
        public float pressTime = 0;

        // Vector3[] corners = new Vector3[4];

        public void setCirclePos(Vector3 pos) {
            var _p = new Vector3(pos.x, pos.y, pos.z);
            Vector2 _position = Vector2.zero;
            RectTransformUtility.ScreenPointToLocalPointInRectangle(canvas.transform as RectTransform, _p, canvas.GetComponent<Camera>(), out _position);

            var center = new Vector4(_position.x, _position.y, 0f, 0f);
            circleNode.GetComponent<Image>().material.SetVector("_Center", center);
        }

        private void setDiameter() {
            if (m_isCircle) {
                if (circleNode != null) {
                    circleNode.GetComponent<Image>().material.SetFloat("_Silder", diameter);
                }
            }
        }

        public bool isCircle {
            get {
                return m_isCircle;
            }
            set {
                m_isCircle = value;
                if (m_isCircle){
                    this.color = new Color(1, 1, 1, 0);
                    if (circleNode != null) {
                        circleNode.SetActive(true);
                        setDiameter();
                    }
                }
            }
        }

        private float m_lookupTime = 0.5f;
        public float lookupTime {
            get {
                return m_lookupTime;
            }
            set {
                if (m_lookupTime != value) {
                    m_lookupTime = value;
                }
            }
        }

        public bool PassEvent<T>(PointerEventData data, ExecuteEvents.EventFunction<T> function)
            where T : IEventSystemHandler {

            List<RaycastResult> results = new List<RaycastResult>();
            EventSystem.current.RaycastAll(data, results);
            GameObject current = data.pointerCurrentRaycast.gameObject;
            for (int i = 0; i < results.Count; i++) {
                if (current != results[i].gameObject && results[i].gameObject.activeSelf && results[i].gameObject.tag != "PassGuide") {
                    if (results[i].gameObject.GetComponent<UGUIClickEventListener>() ||
                        results[i].gameObject.GetComponent<Toggle>() ||
                        results[i].gameObject.GetComponent<UGUIPointerEventListener>() ||
                        results[i].gameObject.GetComponent<Button>()){
                        ExecuteEvents.Execute(results[i].gameObject, data, function);
                        return true;
                    }
                }
            }
            return false;
        }

        protected override void OnPopulateMesh(VertexHelper vbo) {
            vbo.Clear();

            // 填充顶点
            UIVertex vert = UIVertex.simpleVert;
            vert.color = color;

            Vector2 selfPiovt = rectTransform.pivot;
            Rect selfRect = rectTransform.rect;
            float outerLx = -selfPiovt.x * selfRect.width;
            float outerBy = -selfPiovt.y * selfRect.height;
            float outerRx = (1 - selfPiovt.x) * selfRect.width;
            float outerTy = (1 - selfPiovt.y) * selfRect.height;
            // 0 - Outer:LT
            vert.position = new Vector3(outerLx, outerTy);
            vbo.AddVert(vert);
            // 1 - Outer:RT
            vert.position = new Vector3(outerRx, outerTy);
            vbo.AddVert(vert);
            // 2 - Outer:RB
            vert.position = new Vector3(outerRx, outerBy);
            vbo.AddVert(vert);
            // 3 - Outer:LB
            vert.position = new Vector3(outerLx, outerBy);
            vbo.AddVert(vert);

            Bounds bounds = RectTransformUtility.CalculateRelativeRectTransformBounds(transform, Box.transform);

            var _targetMin = bounds.min;
            var _targetMax = bounds.max;

            // 4 - Inner:LT
            vert.position = new Vector3(_targetMin.x, _targetMax.y);
            vbo.AddVert(vert);
            // 5 - Inner:RT
            vert.position = new Vector3(_targetMax.x, _targetMax.y);
            vbo.AddVert(vert);
            // 6 - Inner:RB
            vert.position = new Vector3(_targetMax.x, _targetMin.y);
            vbo.AddVert(vert);
            // 7 - Inner:LB
            vert.position = new Vector3(_targetMin.x, _targetMin.y);
            vbo.AddVert(vert);



            vbo.AddTriangle(4, 0, 1);
            vbo.AddTriangle(4, 1, 5);
            vbo.AddTriangle(5, 1, 2);
            vbo.AddTriangle(5, 2, 6);
            vbo.AddTriangle(6, 2, 3);
            vbo.AddTriangle(6, 3, 7);
            vbo.AddTriangle(7, 3, 0);
            vbo.AddTriangle(7, 0, 4);
        }

        public void OnPointerUp(PointerEventData eventData) {
            if (onClick != null)
            {
                if (Vector2.Distance(eventData.pressPosition, eventData.position) < 10)
                {
                    if (m_click >= 1000)
                    {
                        onClick();
                        return;
                    }
                    Canvas canvas = GetComponentInParent<Canvas>();
                    if (RectTransformUtility.RectangleContainsScreenPoint(Box.GetComponent<RectTransform>(), eventData.position, canvas.worldCamera))
                    {
                        if (NeedPass)
                        {
                            eventData.position = Box.transform.position;
                            eventData.pressPosition = Box.transform.position;
                            if (PassEvent(eventData, ExecuteEvents.submitHandler) &&
                                PassEvent(eventData, ExecuteEvents.pointerDownHandler) &&
                                PassEvent(eventData, ExecuteEvents.pointerUpHandler))
                            {
                                onClick();
                            }
                        }
                        else
                        {
                            if (onClick2 != null)
                            {
                                onClick2();

                            }
                            onClick();
                        }
                    }
                    m_click += 1;
                }

            }
            else if (onPress != null)
            {
                Canvas canvas = GetComponentInParent<Canvas>();
                if (RectTransformUtility.RectangleContainsScreenPoint(Box.GetComponent<RectTransform>(), eventData.position, canvas.worldCamera))
                {
                    if (NeedPass)
                    {
                        eventData.position = Box.transform.position;
                        eventData.pressPosition = Box.transform.position;
                        if (PassEvent(eventData, ExecuteEvents.pointerUpHandler))
                        {
                            if (_pressTime >= pressTime)
                            {
                                onPress();
                            }
                        }
                    }
                    else
                    {
                        if (_pressTime >= pressTime)
                        {
                            onPress();
                        }
                    }
                }
            }
            isPressing = false;
            _pressTime = 0;
        }

        public void OnPointerDown(PointerEventData eventData) {
            isPressing = true;
            startPress = true;
            if (onPress != null)
            {
                StartCoroutine(longPress(eventData));
            }
        }

        private IEnumerator longPress(PointerEventData eventData)
        {
            while (true)
            {
                if (!isPressing)
                {
                    break;
                }
                Canvas canvas = GetComponentInParent<Canvas>();
                if (RectTransformUtility.RectangleContainsScreenPoint(Box.GetComponent<RectTransform>(), eventData.position, canvas.worldCamera))
                {
                    _pressTime = _pressTime + Time.deltaTime;
                    //Debug.Log("按住时间" + "    " + _pressTime);
                    if (startPress)
                    {
                        if (NeedPass)
                        {
                            eventData.position = Box.transform.position;
                            eventData.pressPosition = Box.transform.position;
                            PassEvent(eventData, ExecuteEvents.pointerDownHandler);
                        }
                        startPress = false;
                    }
                }
                yield return null;
            }
        }
        
        public static Vector3 GetNodePos(GameObject obj) {
            var _pos = new Vector3(0, 0, 0);
            Canvas _canvas = null;
            var _parent = obj.transform;
            var _camera = GameObject.Find("UICamera");
            if (_camera == null) {
                _camera = GameObject.FindWithTag("MainCamera");
            }
            while (true) {
                if (_parent) {
                    if (_parent.GetComponent<Canvas>()) {
                        _canvas = _parent.GetComponent<Canvas>();
                        break;
                    }
                } else {
                    break;
                }
                _parent = _parent.transform.parent;
            }
            if (_canvas != null) {
                if (_canvas.renderMode == RenderMode.ScreenSpaceOverlay) {
                    _pos = obj.transform.position;
                } else {
                    _pos = _camera.GetComponent<UnityEngine.Camera>().WorldToScreenPoint(obj.transform.position);
                }
            }else {
                _pos = Camera.main.GetComponent<UnityEngine.Camera>().WorldToScreenPoint(obj.transform.position);
            }
            return _pos;
        }


        public static GuideMask Get(GameObject obj) {
            GuideMask del = obj.GetComponent<GuideMask>();
            if (del == null) {
                del = obj.AddComponent<GuideMask>();
            }
            return del;
        }

        System.Action updateCallback;
        float next_udpate_time = -1f;
        public void SetUpdateCallback(System.Action callback) {
            updateCallback = callback;
            if (updateCallback != null) {
                updateCallback();
                next_udpate_time = lookupTime;
            }
        }

        private void Update() {
            if (next_udpate_time > 0 && updateCallback != null) {
                next_udpate_time -= Time.deltaTime;
                if (next_udpate_time <= 0) {
                    updateCallback();
                    SetAllDirty();
                    next_udpate_time = lookupTime;
                    setDiameter();
                }
            }
        }

        protected override void OnDestroy() {
            onClick = null;
            onClick2 = null;
        }
#if UNITY_EDITOR
        [ContextMenu("Test")]
        void DoSomething() {
            updateCallback();
            SetAllDirty();
            setDiameter();
        }
#endif
    }
}