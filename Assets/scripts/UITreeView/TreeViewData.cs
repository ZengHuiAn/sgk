﻿/// <summary>
/// 树形菜单数据
/// </summary>
namespace SGK {
    public class TreeViewData {
        /// <summary>
        /// 数据内容
        /// </summary>
        public string Name;
        /// <summary>
        /// 数据所属的父ID
        /// </summary>
        public int ParentID;
        /// <summary>
        /// 回调函数
        /// </summary>
        public TreeViewControl.ClickItemdelegate OnClick;
        public TreeViewControl.ClickItemdelegate RefreshItem;
    }
}