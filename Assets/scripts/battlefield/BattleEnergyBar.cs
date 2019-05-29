using UnityEngine;
using UnityEngine.UI;
using DG.Tweening;

public class BattleEnergyBar : MonoBehaviour {
    public RectTransform ValueShade;
    public Text ValueText;
    public float MaxValue = 100;

    int _EnergyValue = -1;
    int EnergyValue
    {
        get { return _EnergyValue; }
        set { if (value != _EnergyValue) {
                _EnergyValue = value;
                UpdateValueText();
            }        
        }

    }


    void UpdateValueText()
    {
        if (ValueText != null)
        {
            ValueText.text = _EnergyValue.ToString();
        }
    }

    float vector_x = 0;
    public void SetValue(int value, int side) {
        if (value <= MaxValue && value >= 0) {
            EnergyValue = value;
            if (side == 1){
                vector_x = 1 - value / MaxValue;
            }else{
                vector_x = value / MaxValue;

            }

            ValueShade.DOScale(new Vector3(vector_x, 1, 1), 0.5f);
        }
    }

}
