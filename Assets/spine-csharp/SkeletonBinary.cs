/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

#if (UNITY_5 || UNITY_4_0 || UNITY_4_1 || UNITY_4_2 || UNITY_4_3 || UNITY_4_4 || UNITY_4_5 || UNITY_4_6 || UNITY_4_7 || UNITY_WSA || UNITY_WP8 || UNITY_WP8_1)
#define IS_UNITY
#endif

using System;
using System.IO;
using System.Collections.Generic;

#if WINDOWS_STOREAPP
using System.Threading.Tasks;
using Windows.Storage;
#endif

namespace Spine {
	public class SkeletonBinary {
		public const int BONE_ROTATE = 0;
		public const int BONE_TRANSLATE = 1;
		public const int BONE_SCALE = 2;
		public const int BONE_SHEAR = 3;

		public const int SLOT_ATTACHMENT = 0;
		public const int SLOT_COLOR = 1;

		public const int PATH_POSITION = 0;
		public const int PATH_SPACING = 1;
		public const int PATH_MIX = 2;

		public const int CURVE_LINEAR = 0;
		public const int CURVE_STEPPED = 1;
		public const int CURVE_BEZIER = 2;

		public float Scale { get; set; }

		private AttachmentLoader attachmentLoader;
		// private byte[] buffer = new byte[32];
		private List<SkeletonJson.LinkedMesh> linkedMeshes = new List<SkeletonJson.LinkedMesh>();

		public SkeletonBinary (params Atlas[] atlasArray)
			: this(new AtlasAttachmentLoader(atlasArray)) {
		}

		public SkeletonBinary (AttachmentLoader attachmentLoader) {
			if (attachmentLoader == null) throw new ArgumentNullException("attachmentLoader");
			this.attachmentLoader = attachmentLoader;
			Scale = 1;
		}
			
		#if !ISUNITY && WINDOWS_STOREAPP
		private async Task<SkeletonData> ReadFile(string path) {
			var folder = Windows.ApplicationModel.Package.Current.InstalledLocation;
			using (var input = new BufferedStream(await folder.GetFileAsync(path).AsTask().ConfigureAwait(false))) {
				SkeletonData skeletonData = ReadSkeletonData(input);
				skeletonData.Name = Path.GetFileNameWithoutExtension(path);
				return skeletonData;
			}
		}

		public SkeletonData ReadSkeletonData (String path) {
			return this.ReadFile(path).Result;
		}
		#else
		public SkeletonData ReadSkeletonData (String path) {
		#if WINDOWS_PHONE
			using (var input = new BufferedStream(Microsoft.Xna.Framework.TitleContainer.OpenStream(path))) {
		#else
			using (var input = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read)) {
		#endif
				SkeletonData skeletonData = ReadSkeletonData(input);
				skeletonData.name = Path.GetFileNameWithoutExtension(path);
				return skeletonData;
			}
		}
		#endif // WINDOWS_STOREAPP

		public static readonly TransformMode[] TransformModeValues = {
			TransformMode.Normal,
			TransformMode.OnlyTranslation,
			TransformMode.NoRotationOrReflection,
			TransformMode.NoScale,
			TransformMode.NoScaleOrReflection
		};

		/// <summary>Returns the version string of binary skeleton data.</summary>
		public static string GetVersionString (SkeletonDataStream input) {
			if (input == null) throw new ArgumentNullException("input");
            try {
                // Hash.
                int byteCount = input.ReadVarint(true);
				if (byteCount > 1) input.Position += byteCount - 1;

                // Version.
                return input.ReadString();
			} catch (Exception e) {
				throw new ArgumentException("Stream does not contain a valid binary Skeleton Data.\n" + e, "input");
			}
		}

		public SkeletonData ReadSkeletonData (Stream _input) {
			if (_input == null) throw new ArgumentNullException("input");

            SkeletonDataStream input = new SkeletonDataStream(_input);

            float scale = Scale;

			var skeletonData = new SkeletonData();
			skeletonData.hash = input.ReadString();
			if (skeletonData.hash.Length == 0) skeletonData.hash = null;
			skeletonData.version = input.ReadString();
			if (skeletonData.version.Length == 0) skeletonData.version = null;
			skeletonData.width = SkeletonDataStream.sp_readFloat(input.ptr);
			skeletonData.height = SkeletonDataStream.sp_readFloat(input.ptr);

			bool nonessential = input.ReadBoolean();

			if (nonessential) {
				skeletonData.fps = SkeletonDataStream.sp_readFloat(input.ptr);
				skeletonData.imagesPath = input.ReadString();
				if (skeletonData.imagesPath.Length == 0) skeletonData.imagesPath = null;
			}

			// Bones.
			for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr, 1); i < n; i++) {
				String name = input.ReadString();
				BoneData parent = i == 0 ? null : skeletonData.bones.Items[SkeletonDataStream.sp_readVarint(input.ptr, 1)];
				BoneData data = new BoneData(i, name, parent);
				data.rotation = SkeletonDataStream.sp_readFloat(input.ptr);		
				data.x = SkeletonDataStream.sp_readFloat(input.ptr) * scale;
				data.y = SkeletonDataStream.sp_readFloat(input.ptr) * scale;
				data.scaleX = SkeletonDataStream.sp_readFloat(input.ptr);
				data.scaleY = SkeletonDataStream.sp_readFloat(input.ptr);
				data.shearX = SkeletonDataStream.sp_readFloat(input.ptr);
				data.shearY = SkeletonDataStream.sp_readFloat(input.ptr);
				data.length = SkeletonDataStream.sp_readFloat(input.ptr) * scale;
				data.transformMode = TransformModeValues[SkeletonDataStream.sp_readVarint(input.ptr, 1)];
				if (nonessential) input.ReadInt(); // Skip bone color.
				skeletonData.bones.Add(data);
			}

			// Slots.
			for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr, 1); i < n; i++) {
				String slotName = input.ReadString();
				BoneData boneData = skeletonData.bones.Items[SkeletonDataStream.sp_readVarint(input.ptr, 1)];
				SlotData slotData = new SlotData(i, slotName, boneData);
				int color = input.ReadInt();
				slotData.r = ((color & 0xff000000) >> 24) / 255f;
				slotData.g = ((color & 0x00ff0000) >> 16) / 255f;
				slotData.b = ((color & 0x0000ff00) >> 8) / 255f;
				slotData.a = ((color & 0x000000ff)) / 255f;
				slotData.attachmentName = input.ReadString();
				slotData.blendMode = (BlendMode)SkeletonDataStream.sp_readVarint(input.ptr, 1);
				skeletonData.slots.Add(slotData);
			}

			// IK constraints.
			for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr, 1); i < n; i++) {
				IkConstraintData data = new IkConstraintData(input.ReadString());
				data.order = SkeletonDataStream.sp_readVarint(input.ptr, 1);
				for (int ii = 0, nn = SkeletonDataStream.sp_readVarint(input.ptr, 1); ii < nn; ii++)
					data.bones.Add(skeletonData.bones.Items[SkeletonDataStream.sp_readVarint(input.ptr, 1)]);
				data.target = skeletonData.bones.Items[SkeletonDataStream.sp_readVarint(input.ptr, 1)];
				data.mix = SkeletonDataStream.sp_readFloat(input.ptr);
				data.bendDirection = input.ReadSByte();
				skeletonData.ikConstraints.Add(data);
			}

			// Transform constraints.
			for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr, 1); i < n; i++) {
				TransformConstraintData data = new TransformConstraintData(input.ReadString());
				data.order = SkeletonDataStream.sp_readVarint(input.ptr, 1);
				for (int ii = 0, nn = SkeletonDataStream.sp_readVarint(input.ptr, 1); ii < nn; ii++)
				    data.bones.Add(skeletonData.bones.Items[SkeletonDataStream.sp_readVarint(input.ptr, 1)]);
				data.target = skeletonData.bones.Items[SkeletonDataStream.sp_readVarint(input.ptr, 1)];
				data.offsetRotation = SkeletonDataStream.sp_readFloat(input.ptr);
				data.offsetX = SkeletonDataStream.sp_readFloat(input.ptr) * scale;
				data.offsetY = SkeletonDataStream.sp_readFloat(input.ptr) * scale;
				data.offsetScaleX = SkeletonDataStream.sp_readFloat(input.ptr);
				data.offsetScaleY = SkeletonDataStream.sp_readFloat(input.ptr);
				data.offsetShearY = SkeletonDataStream.sp_readFloat(input.ptr);
				data.rotateMix = SkeletonDataStream.sp_readFloat(input.ptr);
				data.translateMix = SkeletonDataStream.sp_readFloat(input.ptr);
				data.scaleMix = SkeletonDataStream.sp_readFloat(input.ptr);
				data.shearMix = SkeletonDataStream.sp_readFloat(input.ptr);
				skeletonData.transformConstraints.Add(data);
			}

			// Path constraints
			for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr, 1); i < n; i++) {
				PathConstraintData data = new PathConstraintData(input.ReadString());
				data.order = SkeletonDataStream.sp_readVarint(input.ptr, 1);
				for (int ii = 0, nn = SkeletonDataStream.sp_readVarint(input.ptr, 1); ii < nn; ii++)
					data.bones.Add(skeletonData.bones.Items[SkeletonDataStream.sp_readVarint(input.ptr, 1)]);
				data.target = skeletonData.slots.Items[SkeletonDataStream.sp_readVarint(input.ptr, 1)];
				data.positionMode = (PositionMode)Enum.GetValues(typeof(PositionMode)).GetValue(SkeletonDataStream.sp_readVarint(input.ptr, 1));
				data.spacingMode = (SpacingMode)Enum.GetValues(typeof(SpacingMode)).GetValue(SkeletonDataStream.sp_readVarint(input.ptr, 1));
				data.rotateMode = (RotateMode)Enum.GetValues(typeof(RotateMode)).GetValue(SkeletonDataStream.sp_readVarint(input.ptr, 1));
				data.offsetRotation = SkeletonDataStream.sp_readFloat(input.ptr);
				data.position = SkeletonDataStream.sp_readFloat(input.ptr);
				if (data.positionMode == PositionMode.Fixed) data.position *= scale;
				data.spacing = SkeletonDataStream.sp_readFloat(input.ptr);
				if (data.spacingMode == SpacingMode.Length || data.spacingMode == SpacingMode.Fixed) data.spacing *= scale;
				data.rotateMix = SkeletonDataStream.sp_readFloat(input.ptr);
				data.translateMix = SkeletonDataStream.sp_readFloat(input.ptr);
				skeletonData.pathConstraints.Add(data);
			}

			// Default skin.
			Skin defaultSkin = ReadSkin(input, "default", nonessential);
			if (defaultSkin != null) {
				skeletonData.defaultSkin = defaultSkin;
				skeletonData.skins.Add(defaultSkin);
			}

			// Skins.
			for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr, 1); i < n; i++)
				skeletonData.skins.Add(ReadSkin(input, input.ReadString(), nonessential));

			// Linked meshes.
			for (int i = 0, n = linkedMeshes.Count; i < n; i++) {
				SkeletonJson.LinkedMesh linkedMesh = linkedMeshes[i];
				Skin skin = linkedMesh.skin == null ? skeletonData.DefaultSkin : skeletonData.FindSkin(linkedMesh.skin);
				if (skin == null) throw new Exception("Skin not found: " + linkedMesh.skin);
				Attachment parent = skin.GetAttachment(linkedMesh.slotIndex, linkedMesh.parent);
				if (parent == null) throw new Exception("Parent mesh not found: " + linkedMesh.parent);
				linkedMesh.mesh.ParentMesh = (MeshAttachment)parent;
				linkedMesh.mesh.UpdateUVs();
			}
			linkedMeshes.Clear();

			// Events.
			for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr, 1); i < n; i++) {
				EventData data = new EventData(input.ReadString());
				data.Int = SkeletonDataStream.sp_readVarint(input.ptr, 0);
				data.Float = SkeletonDataStream.sp_readFloat(input.ptr);
				data.String = input.ReadString();
				skeletonData.events.Add(data);
			}

			// Animations.
			for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr, 1); i < n; i++)
				ReadAnimation(input.ReadString(), input, skeletonData);

			skeletonData.bones.TrimExcess();
			skeletonData.slots.TrimExcess();
			skeletonData.skins.TrimExcess();
			skeletonData.events.TrimExcess();
			skeletonData.animations.TrimExcess();
			skeletonData.ikConstraints.TrimExcess();
			skeletonData.pathConstraints.TrimExcess();

            input.Close();

            return skeletonData;
		}


		/// <returns>May be null.</returns>
		private Skin ReadSkin (SkeletonDataStream input, String skinName, bool nonessential) {
			int slotCount = SkeletonDataStream.sp_readVarint(input.ptr, 1);
			if (slotCount == 0) return null;
			Skin skin = new Skin(skinName);
			for (int i = 0; i < slotCount; i++) {
				int slotIndex = SkeletonDataStream.sp_readVarint(input.ptr, 1);
				for (int ii = 0, nn = SkeletonDataStream.sp_readVarint(input.ptr, 1); ii < nn; ii++) {
					String name = input.ReadString();
					Attachment attachment = ReadAttachment(input, skin, slotIndex, name, nonessential);
					if (attachment != null) skin.AddAttachment(slotIndex, name, attachment);
				}
			}
			return skin;
		}

		private Attachment ReadAttachment (SkeletonDataStream input, Skin skin, int slotIndex, String attachmentName, bool nonessential) {
			float scale = Scale;

			String name = input.ReadString();
			if (name == null) name = attachmentName;

			AttachmentType type = (AttachmentType)input.ReadByte();
			switch (type) {
			case AttachmentType.Region: {
					String path = input.ReadString();
					float rotation = SkeletonDataStream.sp_readFloat(input.ptr);		
					float x = SkeletonDataStream.sp_readFloat(input.ptr);
					float y = SkeletonDataStream.sp_readFloat(input.ptr);
					float scaleX = SkeletonDataStream.sp_readFloat(input.ptr);
					float scaleY = SkeletonDataStream.sp_readFloat(input.ptr);
					float width = SkeletonDataStream.sp_readFloat(input.ptr);
					float height = SkeletonDataStream.sp_readFloat(input.ptr);
					int color = input.ReadInt();

					if (path == null) path = name;
					RegionAttachment region = attachmentLoader.NewRegionAttachment(skin, name, path);
					if (region == null) return null;
					region.Path = path;
					region.x = x * scale;
					region.y = y * scale;
					region.scaleX = scaleX;
					region.scaleY = scaleY;
					region.rotation = rotation;
					region.width = width * scale;
					region.height = height * scale;
					region.r = ((color & 0xff000000) >> 24) / 255f;
					region.g = ((color & 0x00ff0000) >> 16) / 255f;
					region.b = ((color & 0x0000ff00) >> 8) / 255f;
					region.a = ((color & 0x000000ff)) / 255f;
					region.UpdateOffset();
					return region;
				}
			case AttachmentType.Boundingbox: {
					int vertexCount = SkeletonDataStream.sp_readVarint(input.ptr, 1);
					Vertices vertices = ReadVertices(input, vertexCount);
					if (nonessential) input.ReadInt(); //int color = nonessential ? input.ReadInt() : 0; // Avoid unused local warning.
					
					BoundingBoxAttachment box = attachmentLoader.NewBoundingBoxAttachment(skin, name);
					if (box == null) return null;
					box.worldVerticesLength = vertexCount << 1;
					box.vertices = vertices.vertices;
					box.bones = vertices.bones;                    
					return box;
				}
			case AttachmentType.Mesh: {
					String path = input.ReadString();
					int color = input.ReadInt();
					int vertexCount = SkeletonDataStream.sp_readVarint(input.ptr, 1);					
					float[] uvs = ReadFloatArray(input, vertexCount << 1, 1);
					int[] triangles = ReadShortArray(input);
					Vertices vertices = ReadVertices(input, vertexCount);
					int hullLength = SkeletonDataStream.sp_readVarint(input.ptr, 1);
					int[] edges = null;
					float width = 0, height = 0;
					if (nonessential) {
						edges = ReadShortArray(input);
						width = SkeletonDataStream.sp_readFloat(input.ptr);
						height = SkeletonDataStream.sp_readFloat(input.ptr);
					}

					if (path == null) path = name;
					MeshAttachment mesh = attachmentLoader.NewMeshAttachment(skin, name, path);
					if (mesh == null) return null;
					mesh.Path = path;
					mesh.r = ((color & 0xff000000) >> 24) / 255f;
					mesh.g = ((color & 0x00ff0000) >> 16) / 255f;
					mesh.b = ((color & 0x0000ff00) >> 8) / 255f;
					mesh.a = ((color & 0x000000ff)) / 255f;
					mesh.bones = vertices.bones;
					mesh.vertices = vertices.vertices;
					mesh.WorldVerticesLength = vertexCount << 1;
					mesh.triangles = triangles;
					mesh.regionUVs = uvs;
					mesh.UpdateUVs();
					mesh.HullLength = hullLength << 1;
					if (nonessential) {
						mesh.Edges = edges;
						mesh.Width = width * scale;
						mesh.Height = height * scale;
					}
					return mesh;
				}
			case AttachmentType.Linkedmesh: {
					String path = input.ReadString();
					int color = input.ReadInt();
					String skinName = input.ReadString();
					String parent = input.ReadString();
					bool inheritDeform = input.ReadBoolean();
					float width = 0, height = 0;
					if (nonessential) {
						width = SkeletonDataStream.sp_readFloat(input.ptr);
						height = SkeletonDataStream.sp_readFloat(input.ptr);
					}

					if (path == null) path = name;
					MeshAttachment mesh = attachmentLoader.NewMeshAttachment(skin, name, path);
					if (mesh == null) return null;
					mesh.Path = path;
					mesh.r = ((color & 0xff000000) >> 24) / 255f;
					mesh.g = ((color & 0x00ff0000) >> 16) / 255f;
					mesh.b = ((color & 0x0000ff00) >> 8) / 255f;
					mesh.a = ((color & 0x000000ff)) / 255f;
					mesh.inheritDeform = inheritDeform;
					if (nonessential) {
						mesh.Width = width * scale;
						mesh.Height = height * scale;
					}
					linkedMeshes.Add(new SkeletonJson.LinkedMesh(mesh, skinName, slotIndex, parent));
					return mesh;
				}
			case AttachmentType.Path: {
					bool closed = input.ReadBoolean();
					bool constantSpeed = input.ReadBoolean();
					int vertexCount = SkeletonDataStream.sp_readVarint(input.ptr, 1);
					Vertices vertices = ReadVertices(input, vertexCount);
					float[] lengths = new float[vertexCount / 3];
					for (int i = 0, n = lengths.Length; i < n; i++)
						lengths[i] = SkeletonDataStream.sp_readFloat(input.ptr) * scale;
					if (nonessential) input.ReadInt(); //int color = nonessential ? input.ReadInt() : 0; // Avoid unused local warning.

					PathAttachment path = attachmentLoader.NewPathAttachment(skin, name);
					if (path == null) return null;
					path.closed = closed;
					path.constantSpeed = constantSpeed;
					path.worldVerticesLength = vertexCount << 1;
					path.vertices = vertices.vertices;
					path.bones = vertices.bones;
					path.lengths = lengths;
					return path;                    
				}			
			}
			return null;
		}

		private Vertices ReadVertices (SkeletonDataStream input, int vertexCount) {
			float scale = Scale;
			int verticesLength = vertexCount << 1;
			Vertices vertices = new Vertices();
			if(!input.ReadBoolean()) {
				vertices.vertices = ReadFloatArray(input, verticesLength, scale);
				return vertices;
			}
			var weights = new ExposedList<float>(verticesLength * 3 * 3);
			var bonesArray = new ExposedList<int>(verticesLength * 3);
			for (int i = 0; i < vertexCount; i++) {
				int boneCount = SkeletonDataStream.sp_readVarint(input.ptr, 1);
				bonesArray.Add(boneCount);
				for (int ii = 0; ii < boneCount; ii++) {
					bonesArray.Add(SkeletonDataStream.sp_readVarint(input.ptr, 1));
					weights.Add(SkeletonDataStream.sp_readFloat(input.ptr) * scale);
					weights.Add(SkeletonDataStream.sp_readFloat(input.ptr) * scale);
					weights.Add(SkeletonDataStream.sp_readFloat(input.ptr));
				}
			}

			vertices.vertices = weights.ToArray();
			vertices.bones = bonesArray.ToArray();
			return vertices;
		}

		private float[] ReadFloatArray (SkeletonDataStream input, int n, float scale) {
			float[] array = new float[n];
			if (scale == 1) {
				for (int i = 0; i < n; i++)
					array[i] = SkeletonDataStream.sp_readFloat(input.ptr);
			} else {
				for (int i = 0; i < n; i++)
					array[i] = SkeletonDataStream.sp_readFloat(input.ptr) * scale;
			}
			return array;
		}

		private int[] ReadShortArray (SkeletonDataStream input) {
			int n = SkeletonDataStream.sp_readVarint(input.ptr, 1);
			int[] array = new int[n];
			for (int i = 0; i < n; i++) 
				array[i] = (input.ReadByte() << 8) | input.ReadByte();
			return array;
		}

        void ReadSlotAnimation(ref ExposedList<Timeline> timelines, SkeletonDataStream input, ref float duration, float scale) {
            // Slot timelines.
            for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr,1); i < n; i++) {
                int slotIndex = SkeletonDataStream.sp_readVarint(input.ptr,1);
                for (int ii = 0, nn = SkeletonDataStream.sp_readVarint(input.ptr,1); ii < nn; ii++) {
                    int timelineType = input.ReadByte();
                    int frameCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
                    switch (timelineType) {
                        case SLOT_COLOR: {
                                ColorTimeline timeline = new ColorTimeline(frameCount);
                                timeline.slotIndex = slotIndex;
                                for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                                    float time = SkeletonDataStream.sp_readFloat(input.ptr);
                                    int color = input.ReadInt();
                                    float r = ((color & 0xff000000) >> 24) / 255f;
                                    float g = ((color & 0x00ff0000) >> 16) / 255f;
                                    float b = ((color & 0x0000ff00) >> 8) / 255f;
                                    float a = ((color & 0x000000ff)) / 255f;
                                    timeline.SetFrame(frameIndex, time, r, g, b, a);
                                    if (frameIndex < frameCount - 1) SkeletonDataStream.sp_readCurve(input.ptr, frameIndex, timeline.curves);
                                }
                                timelines.Add(timeline);
                                duration = Math.Max(duration, timeline.frames[(timeline.FrameCount - 1) * ColorTimeline.ENTRIES]);
                                break;
                            }
                        case SLOT_ATTACHMENT: {
                                AttachmentTimeline timeline = new AttachmentTimeline(frameCount);
                                timeline.slotIndex = slotIndex;
                                for (int frameIndex = 0; frameIndex < frameCount; frameIndex++)
                                    timeline.SetFrame(frameIndex, SkeletonDataStream.sp_readFloat(input.ptr), input.ReadString());
                                timelines.Add(timeline);
                                duration = Math.Max(duration, timeline.frames[frameCount - 1]);
                                break;
                            }
                    }
                }
            }
        }

        void ReadBoneAnimation(ref ExposedList<Timeline> timelines, SkeletonDataStream input, ref float duration, float scale) {
            // Bone timelines.
            for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr,1); i < n; i++) {
                int boneIndex = SkeletonDataStream.sp_readVarint(input.ptr,1);
                for (int ii = 0, nn = SkeletonDataStream.sp_readVarint(input.ptr,1); ii < nn; ii++) {
                    int timelineType = input.ReadByte();
                    int frameCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
                    switch (timelineType) {
                        case BONE_ROTATE: {
                                RotateTimeline timeline = new RotateTimeline(frameCount);
                                timeline.boneIndex = boneIndex;
                                for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                                    timeline.SetFrame(frameIndex, SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr));
                                    if (frameIndex < frameCount - 1) SkeletonDataStream.sp_readCurve(input.ptr, frameIndex, timeline.curves);
                                }
                                timelines.Add(timeline);
                                duration = Math.Max(duration, timeline.frames[(frameCount - 1) * RotateTimeline.ENTRIES]);
                                break;
                            }
                        case BONE_TRANSLATE:
                        case BONE_SCALE:
                        case BONE_SHEAR: {
                                TranslateTimeline timeline;
                                float timelineScale = 1;
                                if (timelineType == BONE_SCALE)
                                    timeline = new ScaleTimeline(frameCount);
                                else if (timelineType == BONE_SHEAR)
                                    timeline = new ShearTimeline(frameCount);
                                else {
                                    timeline = new TranslateTimeline(frameCount);
                                    timelineScale = scale;
                                }
                                timeline.boneIndex = boneIndex;
                                for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                                    timeline.SetFrame(frameIndex, SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr) * timelineScale, SkeletonDataStream.sp_readFloat(input.ptr)
                                        * timelineScale);
                                    if (frameIndex < frameCount - 1) SkeletonDataStream.sp_readCurve(input.ptr, frameIndex, timeline.curves);
                                }
                                timelines.Add(timeline);
                                duration = Math.Max(duration, timeline.frames[(frameCount - 1) * TranslateTimeline.ENTRIES]);
                                break;
                            }
                    }
                }
            }
        }

        void ReadIKAnimation(ref ExposedList<Timeline> timelines, SkeletonDataStream input, ref float duration, float scale) {
            // IK timelines.
            for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr,1); i < n; i++) {
                int index = SkeletonDataStream.sp_readVarint(input.ptr,1);
                int frameCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
                IkConstraintTimeline timeline = new IkConstraintTimeline(frameCount);
                timeline.ikConstraintIndex = index;
                for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                    timeline.SetFrame(frameIndex, SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr), input.ReadSByte());
                    if (frameIndex < frameCount - 1) SkeletonDataStream.sp_readCurve(input.ptr, frameIndex, timeline.curves);
                }
                timelines.Add(timeline);
                duration = Math.Max(duration, timeline.frames[(frameCount - 1) * IkConstraintTimeline.ENTRIES]);
            }
        }
        void ReadTransformAnimation(ref ExposedList<Timeline> timelines, SkeletonDataStream input, ref float duration, float scale) {
            // Transform constraint timelines.
            for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr,1); i < n; i++) {
                int index = SkeletonDataStream.sp_readVarint(input.ptr,1);
                int frameCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
                TransformConstraintTimeline timeline = new TransformConstraintTimeline(frameCount);
                timeline.transformConstraintIndex = index;
                for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                    timeline.SetFrame(frameIndex, SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr));
                    if (frameIndex < frameCount - 1) SkeletonDataStream.sp_readCurve(input.ptr, frameIndex, timeline.curves);
                }
                timelines.Add(timeline);
                duration = Math.Max(duration, timeline.frames[(frameCount - 1) * TransformConstraintTimeline.ENTRIES]);
            }
        }

        void ReadPathAnimation(ref ExposedList<Timeline> timelines, SkeletonDataStream input, ref float duration, float scale, ref SkeletonData skeletonData) {
            // Path constraint timelines.
            for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr,1); i < n; i++) {
                int index = SkeletonDataStream.sp_readVarint(input.ptr,1);
                PathConstraintData data = skeletonData.pathConstraints.Items[index];
                for (int ii = 0, nn = SkeletonDataStream.sp_readVarint(input.ptr,1); ii < nn; ii++) {
                    int timelineType = input.ReadSByte();
                    int frameCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
                    switch (timelineType) {
                        case PATH_POSITION:
                        case PATH_SPACING: {
                                PathConstraintPositionTimeline timeline;
                                float timelineScale = 1;
                                if (timelineType == PATH_SPACING) {
                                    timeline = new PathConstraintSpacingTimeline(frameCount);
                                    if (data.spacingMode == SpacingMode.Length || data.spacingMode == SpacingMode.Fixed) timelineScale = scale;
                                } else {
                                    timeline = new PathConstraintPositionTimeline(frameCount);
                                    if (data.positionMode == PositionMode.Fixed) timelineScale = scale;
                                }
                                timeline.pathConstraintIndex = index;
                                for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                                    timeline.SetFrame(frameIndex, SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr) * timelineScale);
                                    if (frameIndex < frameCount - 1) SkeletonDataStream.sp_readCurve(input.ptr, frameIndex, timeline.curves);
                                }
                                timelines.Add(timeline);
                                duration = Math.Max(duration, timeline.frames[(frameCount - 1) * PathConstraintPositionTimeline.ENTRIES]);
                                break;
                            }
                        case PATH_MIX: {
                                PathConstraintMixTimeline timeline = new PathConstraintMixTimeline(frameCount);
                                timeline.pathConstraintIndex = index;
                                for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                                    timeline.SetFrame(frameIndex, SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr), SkeletonDataStream.sp_readFloat(input.ptr));
                                    if (frameIndex < frameCount - 1) SkeletonDataStream.sp_readCurve(input.ptr, frameIndex, timeline.curves);
                                }
                                timelines.Add(timeline);
                                duration = Math.Max(duration, timeline.frames[(frameCount - 1) * PathConstraintMixTimeline.ENTRIES]);
                                break;
                            }
                    }
                }
            }
        }

        void ReadDeformAnimation(ref ExposedList<Timeline> timelines, SkeletonDataStream input, ref float duration, float scale, ref SkeletonData skeletonData) {
            // Deform timelines.
            for (int i = 0, n = SkeletonDataStream.sp_readVarint(input.ptr,1); i < n; i++) {
                Skin skin = skeletonData.skins.Items[SkeletonDataStream.sp_readVarint(input.ptr,1)];
                for (int ii = 0, nn = SkeletonDataStream.sp_readVarint(input.ptr,1); ii < nn; ii++) {
                    int slotIndex = SkeletonDataStream.sp_readVarint(input.ptr,1);
                    for (int iii = 0, nnn = SkeletonDataStream.sp_readVarint(input.ptr,1); iii < nnn; iii++) {
                        VertexAttachment attachment = (VertexAttachment)skin.GetAttachment(slotIndex, input.ReadString());
                        bool weighted = attachment.bones != null;
                        float[] vertices = attachment.vertices;
                        int deformLength = weighted ? vertices.Length / 3 * 2 : vertices.Length;

                        int frameCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
                        DeformTimeline timeline = new DeformTimeline(frameCount);
                        timeline.slotIndex = slotIndex;
                        timeline.attachment = attachment;

                        for (int frameIndex = 0; frameIndex < frameCount; frameIndex++) {
                            float time = SkeletonDataStream.sp_readFloat(input.ptr);
                            float[] deform;
                            int end = SkeletonDataStream.sp_readVarint(input.ptr,1);
                            if (end == 0)
                                deform = weighted ? new float[deformLength] : vertices;
                            else {
                                deform = new float[deformLength];
                                int start = SkeletonDataStream.sp_readVarint(input.ptr,1);
                                end += start;
                                input.ReadFloatArray(deform, start, end, scale);
                                if (!weighted) {
                                    for (int v = 0, vn = deform.Length; v < vn; v++)
                                        deform[v] += vertices[v];
                                }
                            }

                            timeline.SetFrame(frameIndex, time, deform);
                            if (frameIndex < frameCount - 1) SkeletonDataStream.sp_readCurve(input.ptr, frameIndex, timeline.curves);
                        }
                        timelines.Add(timeline);
                        duration = Math.Max(duration, timeline.frames[frameCount - 1]);
                    }
                }
            }
        }

        void ReadDrawOrderAnimation(ref ExposedList<Timeline> timelines, SkeletonDataStream input, ref float duration, float scale, ref SkeletonData skeletonData) {
            // Draw order timeline.
            int drawOrderCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
            if (drawOrderCount > 0) {
                DrawOrderTimeline timeline = new DrawOrderTimeline(drawOrderCount);
                int slotCount = skeletonData.slots.Count;
                for (int i = 0; i < drawOrderCount; i++) {
                    float time = SkeletonDataStream.sp_readFloat(input.ptr);
                    int offsetCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
                    int[] drawOrder = new int[slotCount];
                    for (int ii = slotCount - 1; ii >= 0; ii--)
                        drawOrder[ii] = -1;
                    int[] unchanged = new int[slotCount - offsetCount];
                    int originalIndex = 0, unchangedIndex = 0;
                    for (int ii = 0; ii < offsetCount; ii++) {
                        int slotIndex = SkeletonDataStream.sp_readVarint(input.ptr,1);
                        // Collect unchanged items.
                        while (originalIndex != slotIndex)
                            unchanged[unchangedIndex++] = originalIndex++;
                        // Set changed items.
                        drawOrder[originalIndex + SkeletonDataStream.sp_readVarint(input.ptr,1)] = originalIndex++;
                    }
                    // Collect remaining unchanged items.
                    while (originalIndex < slotCount)
                        unchanged[unchangedIndex++] = originalIndex++;
                    // Fill in unchanged items.
                    for (int ii = slotCount - 1; ii >= 0; ii--)
                        if (drawOrder[ii] == -1) drawOrder[ii] = unchanged[--unchangedIndex];
                    timeline.SetFrame(i, time, drawOrder);
                }
                timelines.Add(timeline);
                duration = Math.Max(duration, timeline.frames[drawOrderCount - 1]);
            }
        }

        void ReadEventAnimation(ref ExposedList<Timeline> timelines, SkeletonDataStream input, ref float duration, float scale, ref SkeletonData skeletonData) {
            // Event timeline.
            int eventCount = SkeletonDataStream.sp_readVarint(input.ptr,1);
            if (eventCount > 0) {
                EventTimeline timeline = new EventTimeline(eventCount);
                for (int i = 0; i < eventCount; i++) {
                    float time = SkeletonDataStream.sp_readFloat(input.ptr);
                    EventData eventData = skeletonData.events.Items[SkeletonDataStream.sp_readVarint(input.ptr,1)];
                    Event e = new Event(time, eventData);
                    e.Int = SkeletonDataStream.sp_readVarint(input.ptr, 0);
                    e.Float = SkeletonDataStream.sp_readFloat(input.ptr);
                    e.String = input.ReadBoolean() ? input.ReadString() : eventData.String;
                    timeline.SetFrame(i, e);
                }
                timelines.Add(timeline);
                duration = Math.Max(duration, timeline.frames[eventCount - 1]);
            }
        }

        private void ReadAnimation (String name, SkeletonDataStream input, SkeletonData skeletonData) {
			var timelines = new ExposedList<Timeline>();
			float scale = Scale;
			float duration = 0;

            ReadSlotAnimation(ref timelines, input, ref duration, scale);
            ReadBoneAnimation(ref timelines, input, ref duration, scale);
            ReadIKAnimation(ref timelines, input, ref duration, scale);
            ReadTransformAnimation(ref timelines, input, ref duration, scale);
            ReadPathAnimation(ref timelines, input, ref duration, scale, ref skeletonData);
            ReadDeformAnimation(ref timelines, input, ref duration, scale, ref skeletonData);
            ReadDrawOrderAnimation(ref timelines, input, ref duration, scale, ref skeletonData);
            ReadEventAnimation(ref timelines, input, ref duration, scale, ref skeletonData);

			timelines.TrimExcess();
			skeletonData.animations.Add(new Animation(name, timelines, duration));
		}

		internal class Vertices {
			public int[] bones;
			public float[] vertices;
		}
	}
}
