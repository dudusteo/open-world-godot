using Godot;
using System;

public partial class Terrain : Node3D
{

	[ExportCategory("Terrain")]
	[ExportGroup("Chunk Settings")]
	[Export] private int chunkSize;
	[Export] private int chunkRenderDistance;


	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{

		CreateChunks(chunkRenderDistance * 2);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}

	private void CreateChunks(int numberOfChunks)
	{
		var center = GetClosestChunkCenter(Position);
	}

	private Vector3 GetClosestChunkCenter(Vector3 entityPosition)
	{
		Vector3 chunkCenter = new()
		{
			X = Mathf.Floor(entityPosition.X / chunkSize) * chunkSize,
			Y = Mathf.Floor(entityPosition.Y / chunkSize) * chunkSize,
			Z = Mathf.Floor(entityPosition.Z / chunkSize) * chunkSize
		};

		return chunkCenter;
	}
}
