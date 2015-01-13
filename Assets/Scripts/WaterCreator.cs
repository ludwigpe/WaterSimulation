using UnityEngine;
using System.Collections;

public class WaterCreator : MonoBehaviour {
    public int width;
    public int triWidth;
    public Material oceanMat;

    // Here are variables that describe the ways. Each entry in the vector4 corresponds to the entry for one way
    // example: Amplitude of wave1 = m_amplitude.x, wave2 = m_amplitude.y etc.
    public Vector4 m_amplitudes; 
    public Vector4 m_frequencies;
    public Vector4 m_steepness;
    public Vector4 m_speed;
    public Vector4 m_direction12;
    public Vector4 m_direction34;

    private Matrix4x4 m_waves = Matrix4x4.zero;
	// Use this for initialization
	void Start () {
        PutValuesInMatrix();
        oceanMat.SetMatrix("_Waves", m_waves);
	}

    // Update is called once per frame
    void Update()
    {
        oceanMat.SetMatrix("_Waves", m_waves);
	}

    /// <summary>
    /// Put all variable data into matrix form.
    /// Row 1 contains all amplitude data
    /// Row 2 contains all frequency data
    /// Row 3 contains all steepness data
    /// Row 4 contains all speed data
    /// </summary>
    void PutValuesInMatrix()
    {
        m_waves.SetRow(0, m_amplitudes);
        m_waves.SetRow(1, m_frequencies);
        m_waves.SetRow(2, m_steepness);
        m_waves.SetRow(3, m_speed);
    }


}
