using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;
using SGK;

[ExecuteInEditMode]
public class BattlefieldSkillManager2 : MonoBehaviour {
    public System.Action<object> selectedDelegate;
    public System.Action changeSkillDelegate;

    Animator animator;
    // bool dirty = false;

    int tag_more = 0;
    int tag_show = 0;
    int tag_switch = 0;

    bool m_more = false;
    bool m_show = false;

    private void Start() {
        tag_more = Animator.StringToHash("More");
        tag_show = Animator.StringToHash("Show");
        tag_switch = Animator.StringToHash("Switch");
        animator = GetComponent<Animator>();

        animator.SetBool(tag_more, m_more);
        animator.SetBool(tag_show, m_show);
    }

    public void UpdateButtons() {
        if (changeSkillDelegate != null) {
            changeSkillDelegate();
        }
    }

    public void Show(bool more) {
        m_more = more;
        m_show = true;

        if (animator == null) {
            return;
        }
        animator.SetBool(tag_more, more);
        animator.SetBool(tag_show, true);
    }

    public void Hide() {
        m_show = false;
        if (animator == null) {
            return;
        }
        animator.SetBool(tag_show, false);
    }

    public void Switch(bool more) {
        m_more = more;
        m_show = true;

        if (animator == null) {
            return;
        }

        animator.SetBool(tag_more, more);
        if (!animator.GetBool(tag_show)) {
            animator.SetBool(tag_show, true);
        } else {
            animator.SetTrigger(tag_switch);
        }
    }

    public void onSelected(int pos) {
        if (selectedDelegate != null) {
            selectedDelegate(pos);
        }
    }
}