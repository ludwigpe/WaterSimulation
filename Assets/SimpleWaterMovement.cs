using UnityEngine;
using System.Collections;

public class SimpleWaterMovement : MonoBehaviour {
    public Vector2 windDir;

	// Use this for initialization
	void Start () {
	}
	
	// Update is called once per frame
	void Update () {

        Vector2 offset = GetComponent<Renderer>().material.GetTextureOffset("_BumpMap");
        offset.x += windDir.x * Time.deltaTime;
        offset.y += windDir.y * Time.deltaTime;
        GetComponent<Renderer>().material.SetTextureOffset("_BumpMap", offset);
        GetComponent<Renderer>().material.SetTextureOffset("_MainTex", offset);


        offset = GetComponent<Renderer>().material.GetTextureOffset("_BumpMap2");
        offset.x += -windDir.x * Time.deltaTime;
        offset.y += windDir.y * Time.deltaTime;
        GetComponent<Renderer>().material.SetTextureOffset("_BumpMap2", offset);

        
	}
}
