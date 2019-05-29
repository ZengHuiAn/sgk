using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.UI;

public class FPSInfo : MonoBehaviour {
	int frame = 0;
	float dt = 0;

	public Text FPSText;

	[Range(0, 1)]
	public float reportTime = 0.5f;

	void Start () {
        tx = new System.Text.StringBuilder();
	}
	
	void Update () {
		frame ++;
		dt += Time.deltaTime;
		if (dt > reportTime) {
            FPSText.text = Info((int)(frame / dt));

			frame = 0;
			dt = 0;
		}
	}

    System.Text.StringBuilder tx;

    string Info(int fps) {
        tx.Length = 0;

        tx.AppendFormat("{0} {1} {2}\n{3} {4} {5}\n", fps,
            System.GC.GetTotalMemory(false) / 1048576,
            Profiler.GetMonoHeapSizeLong() / 1048576,
            Profiler.GetTotalAllocatedMemoryLong() / 1048576,
            Profiler.GetTotalReservedMemoryLong() / 1048576,
            Profiler.GetTotalUnusedReservedMemoryLong() / 1048576
        );

        return tx.ToString();
    }
}
