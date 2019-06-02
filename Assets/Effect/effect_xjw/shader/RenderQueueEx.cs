using UnityEngine;
using System.Collections;
using System;

[ExecuteInEditMode]
public class RenderQueueEx : MonoBehaviour
{
	[Range(-400, 4000)]
	public Int32 RenderIncrease;

	public bool IncludeChild = false;

	void Start()
	{
		_UpdateRenderQueue();
	}

#if UNITY_EDITOR
	void Update()
	{
		_UpdateRenderQueue();
	}
#endif

	void _UpdateRenderQueue()
	{
		Renderer renderer = GetComponent<Renderer>();
		if (renderer != null)
		{
			Material[] materials = renderer.sharedMaterials;
			//
			for (int iter = 0; iter < materials.Length; ++iter)
			{
				Material iterMaterial = materials[iter];
				if (iterMaterial != null && iterMaterial.shader != null)
				{
					iterMaterial.renderQueue = iterMaterial.shader.renderQueue + RenderIncrease;
				}
			}
		}
		//
		if (IncludeChild)
		{
			_UpdateChildrenRenderQueue();
		}
	}

	void _UpdateChildrenRenderQueue()
	{
		Renderer[] renderer = GetComponentsInChildren<Renderer>(true);
		for (int iter = 0; iter < renderer.Length; ++iter)
		{
			Renderer iterRender = renderer[iter];
			Material[] materials = iterRender.sharedMaterials;
			//
			for (int inIter = 0; inIter < materials.Length; ++inIter)
			{
				Material iterMaterial = materials[inIter];
				if (iterMaterial != null && iterMaterial.shader != null)
				{
					iterMaterial.renderQueue = iterMaterial.shader.renderQueue + RenderIncrease;
				}
			}
		}
	}
}
