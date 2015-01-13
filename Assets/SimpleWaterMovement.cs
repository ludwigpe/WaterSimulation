using UnityEngine;
using System.Collections;

public class SimpleWaterMovement : MonoBehaviour {
    public Vector2 windDir;

	// Use this for initialization
	void Start () {
	}
	
	// Update is called once per frame
	void Update () {

        Vector2 offset = renderer.material.GetTextureOffset("_BumpMap");
        offset.x += windDir.x * Time.deltaTime;
        offset.y += windDir.y * Time.deltaTime;
        renderer.material.SetTextureOffset("_BumpMap", offset);
        renderer.material.SetTextureOffset("_MainTex", offset);


        offset = renderer.material.GetTextureOffset("_BumpMap2");
        offset.x += -windDir.x * Time.deltaTime;
        offset.y += windDir.y * Time.deltaTime;
        renderer.material.SetTextureOffset("_BumpMap2", offset);

        
	}
}
