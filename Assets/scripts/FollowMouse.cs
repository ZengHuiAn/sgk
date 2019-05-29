using UnityEngine;
using System.Collections;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class FollowMouse : MonoBehaviour,IPointerDownHandler, IDragHandler, IPointerUpHandler, 
    IEndDragHandler{

    public RectTransform canvas;          //得到canvas的ugui坐标
    private RectTransform imgRect;        //得到图片的ugui坐标
    Vector2 offset = new Vector3();    //用来得到鼠标和图片的差值
	private float m_minX;
	private float m_minY;
	private float m_maxX;
	private float m_maxY;
	//private int baseHeight = 1136; //基准分辨率
	//private int baseWidth = 750;
    // Use this for initialization
    void Start ()
	{
		imgRect = GetComponent<RectTransform> ();

        // 范围
		m_minX = -(canvas.sizeDelta.x-imgRect.rect.width)/2;
		m_minY = -(canvas.sizeDelta.y - imgRect.rect.height)/2;
        m_maxX = -m_minX;
        m_maxY = -m_minY;

    }

    //当鼠标按下时调用 接口对应  IPointerDownHandler
    public void OnPointerDown(PointerEventData eventData)
    {
        Vector2 mouseDown = eventData.position;    //记录鼠标按下时的屏幕坐标
        Vector2 mouseUguiPos = new Vector2();   //定义一个接收返回的ugui坐标
        //RectTransformUtility.ScreenPointToLocalPointInRectangle()：把屏幕坐标转化成ugui坐标
        //canvas：坐标要转换到哪一个物体上，这里img父类是Canvas，我们就用Canvas
        //eventData.enterEventCamera：这个事件是由哪个摄像机执行的
        //out mouseUguiPos：返回转换后的ugui坐标
        //isRect：方法返回一个bool值，判断鼠标按下的点是否在要转换的物体上
        bool isRect = RectTransformUtility.ScreenPointToLocalPointInRectangle(canvas, mouseDown, eventData.enterEventCamera, out mouseUguiPos);
        if (isRect)   //如果在
        {
            //计算图片中心和鼠标点的差值
            offset = imgRect.anchoredPosition - mouseUguiPos;
        }
    }

    //当鼠标拖动时调用   对应接口 IDragHandler
    public void OnDrag(PointerEventData eventData)
    {
        Vector2 mouseDrag = eventData.position;   //当鼠标拖动时的屏幕坐标
        Vector2 uguiPos = new Vector2();   //用来接收转换后的拖动坐标
        //和上面类似
        bool isRect = RectTransformUtility.ScreenPointToLocalPointInRectangle(canvas, mouseDrag, eventData.enterEventCamera, out uguiPos);

        if (isRect)
        {
            //设置图片的ugui坐标与鼠标的ugui坐标保持不变
			Vector2 tempVec2 = offset + uguiPos;
			if (tempVec2.y > m_maxY)
				tempVec2 = new Vector2(tempVec2.x,m_maxY);
			if (tempVec2.y < m_minY)
				tempVec2 = new Vector2(tempVec2.x,m_minY);
			if (tempVec2.x < m_minX)
				tempVec2 = new Vector2(m_minX,tempVec2.y);
			if (tempVec2.x > m_maxX)
				tempVec2 = new Vector2(m_maxX,tempVec2.y);
			imgRect.anchoredPosition = tempVec2;
        }
    }

    //当鼠标抬起时调用  对应接口  IPointerUpHandler
    public void OnPointerUp(PointerEventData eventData)
    {
        offset = Vector2.zero;
    }

    //当鼠标结束拖动时调用   对应接口  IEndDragHandler
    public void OnEndDrag(PointerEventData eventData)
    {
        offset = Vector2.zero;
    }

   
}
