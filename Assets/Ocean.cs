using UnityEngine;
using System.Collections;

public class Ocean : MonoBehaviour {
    public Material m_oceanMat;
    public Material m_wireframeMat;
    public int m_ansio = 2; //Ansiotrophic filtering on wave textures
    public float m_lodFadeDist = 2000.0f; //The distance that mipmap level on wave textures fades to highest mipmap. A neg number will disable this
    public int m_resolution = 128; //The resolution of the grid used for the ocean
    public bool m_useMaxResolution = false; //If enable this will over ride the resolution setting and will use the largest mesh possible in Unity
    public float m_bias = 2.0f; //A higher number will push more of the mesh verts closer to center of grid were player is. Must be >= 1
    public int m_fourierGridSize = 128; //Fourier grid size.

    //These setting can be used to control the look of the waves from rough seas to calm lakes.
    //WARNING - not all combinations of numbers makes sense and the waves will not always look correct.
    public float m_windSpeed = 8.0f; //A higher wind speed gives greater swell to the waves
    public float m_waveAmp = 1.0f; //Scales the height of the waves
    public float m_inverseWaveAge = 0.84f; //A lower number means the waves last longer and will build up larger waves
    public Vector4 m_gridSizes = new Vector4(5488, 392, 28, 2); //The wave lengths. x must be largest, then y, the z, then w
    public GameObject m_sun;
    public float m_seaLevel = 0.0f;

    GameObject m_grid;
    int m_frameCount = 0;

    Mesh CreateRadialGrid(int segementsX, int segementsY)
    {

        Vector3[] vertices = new Vector3[segementsX * segementsY];
        Vector3[] normals = new Vector3[segementsX * segementsY];
        Vector2[] texcoords = new Vector2[segementsX * segementsY]; //not used atm

        float TAU = Mathf.PI * 2.0f;
        float r;
        for (int x = 0; x < segementsX; x++)
        {
            for (int y = 0; y < segementsY; y++)
            {
                r = (float)x / (float)(segementsX - 1);
                r = Mathf.Pow(r, m_bias);

                normals[x + y * segementsX] = new Vector3(0, 1, 0);

                vertices[x + y * segementsX].x = r * Mathf.Cos(TAU * (float)y / (float)(segementsY - 1));
                vertices[x + y * segementsX].y = 0.0f;
                vertices[x + y * segementsX].z = r * Mathf.Sin(TAU * (float)y / (float)(segementsY - 1));
            }
        }

        int[] indices = new int[segementsX * segementsY * 6];

        int num = 0;
        for (int x = 0; x < segementsX - 1; x++)
        {
            for (int y = 0; y < segementsY - 1; y++)
            {
                indices[num++] = x + y * segementsX;
                indices[num++] = x + (y + 1) * segementsX;
                indices[num++] = (x + 1) + y * segementsX;

                indices[num++] = x + (y + 1) * segementsX;
                indices[num++] = (x + 1) + (y + 1) * segementsX;
                indices[num++] = (x + 1) + y * segementsX;

            }
        }

        Mesh mesh = new Mesh();

        mesh.vertices = vertices;
        mesh.uv = texcoords;
        mesh.normals = normals;
        mesh.triangles = indices;

        return mesh;

    }

    void Start()
    {
        if (m_resolution * m_resolution >= 65000 || m_useMaxResolution)
        {
            m_resolution = (int)Mathf.Sqrt(65000);

            if (!m_useMaxResolution)
                Debug.Log("Warning - Grid resolution set to high. Setting resolution to the maxium allowed(" + m_resolution.ToString() + ")");
        }

        if (m_bias < 1.0f)
        {
            m_bias = 1.0f;
            Debug.Log("Ocean::Start - bias must not be less than 1, changing to 1");
        }

        Mesh mesh = CreateRadialGrid(m_resolution, m_resolution);

        float far = Camera.main.farClipPlane;

        m_grid = new GameObject("Ocean Grid");
        m_grid.AddComponent<MeshFilter>();
        m_grid.AddComponent<MeshRenderer>();
        m_grid.GetComponent<Renderer>().material = m_oceanMat;
        m_oceanMat.SetVector("_GridSizes", m_gridSizes);
        m_grid.GetComponent<MeshFilter>().mesh = mesh;
        m_grid.transform.localScale = new Vector3(far, 1, far);//Make radial grid have a radius equal to far plane

    }

    void Update()
    {

        //This makes sure the grid is always centered were the player is
        Vector3 pos = Camera.main.transform.position;
        pos.y = m_seaLevel;

        m_grid.transform.localPosition = pos;
    }


}
