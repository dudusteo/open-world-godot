using Godot;
using System;

public partial class Chunk : Node3D
{
    [Export] public int ChunkSize = 8;
    [Export] private NoiseTexture2D noiseTexture;

    private int _chunkEdgeVertices;

    public override void _Ready()
    {
        _chunkEdgeVertices = ChunkSize + 1;
    }
}