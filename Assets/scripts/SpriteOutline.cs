using UnityEngine;

namespace SGK
{
    [ExecuteInEditMode]
    public class SpriteOutline : MonoBehaviour
    {
        public Color color = Color.white;

        [Range(0, 16)]
        public int outlineSize = 1;

        public SpriteRenderer spriteRenderer;
        void Start()
        {
            if (spriteRenderer == null)
            {
                spriteRenderer = GetComponent<SpriteRenderer>();
            }
        }
        void OnEnable()
        {
            if (spriteRenderer == null)
            {
                spriteRenderer = GetComponent<SpriteRenderer>();
            }

            UpdateOutline(true);
        }

        void OnDisable()
        {
            UpdateOutline(false);
        }

        void Update()
        {
            UpdateOutline(true);
        }

        void UpdateOutline(bool outline)
        {
            if (spriteRenderer != null)
            {
                MaterialPropertyBlock mpb = new MaterialPropertyBlock();
                spriteRenderer.GetPropertyBlock(mpb);
                mpb.SetFloat("_Outline", outline ? 1f : 0);
                mpb.SetColor("_OutlineColor", color);
                mpb.SetFloat("_OutlineSize", outlineSize);
                spriteRenderer.SetPropertyBlock(mpb);
            }
        }
    }
}
