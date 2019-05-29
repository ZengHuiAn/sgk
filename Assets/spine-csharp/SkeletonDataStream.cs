using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using UnityEngine;

namespace Spine {
    public class SkeletonDataStream
    {
#if false
        public Stream ptr;

        public SkeletonDataStream(byte[] bytes) {
            ptr = new MemoryStream(bytes);
        }

        public SkeletonDataStream(Stream stream) {
            ptr = stream;
        }

        public long Position {
            get {
                return ptr.Position;
            }
            set {
                ptr.Position = value;
            }
        }

        public void Close() {
            return;
        }

        public static void sp_freeInput(Stream ptr) {
            ptr.Close();
        }

        public static int sp_readByte(Stream ptr) {
            return ptr.ReadByte();
        }

        public static int sp_readInt(Stream input) {
            return (input.ReadByte() << 24) + (input.ReadByte() << 16) + (input.ReadByte() << 8) + input.ReadByte();
        }

        public static int sp_readVarint(Stream input, int optimizePositive) {
            int b = input.ReadByte();
            int result = b & 0x7F;
            if ((b & 0x80) != 0) {
                b = input.ReadByte();
                result |= (b & 0x7F) << 7;
                if ((b & 0x80) != 0) {
                    b = input.ReadByte();
                    result |= (b & 0x7F) << 14;
                    if ((b & 0x80) != 0) {
                        b = input.ReadByte();
                        result |= (b & 0x7F) << 21;
                        if ((b & 0x80) != 0) result |= (input.ReadByte() & 0x7F) << 28;
                    }
                }
            }
            return (optimizePositive != 0) ? result : ((result >> 1) ^ -(result & 1));
        }

        static byte[] buffer = new byte[32];
        public static float sp_readFloat(Stream input) {
            buffer[3] = (byte)input.ReadByte();
            buffer[2] = (byte)input.ReadByte();
            buffer[1] = (byte)input.ReadByte();
            buffer[0] = (byte)input.ReadByte();
            return BitConverter.ToSingle(buffer, 0);
        }

        public string ReadString() {
            int byteCount = sp_readVarint(ptr, 1);
            switch (byteCount) {
                case 0:
                    return null;
                case 1:
                    return "";
            }
            byteCount--;
            if (buffer.Length < byteCount) buffer = new byte[byteCount];
            ReadFully(ptr, buffer, 0, byteCount);
            return System.Text.Encoding.UTF8.GetString(buffer, 0, byteCount);
        }

        private static void ReadFully(Stream input, byte[] buffer, int offset, int length) {
            while (length > 0) {
                int count = input.Read(buffer, offset, length);
                if (count <= 0) throw new EndOfStreamException();
                offset += count;
                length -= count;
            }
        }

        public static void sp_readFloatArray(Stream input, float[] array, int start, int end, float scale) {
            for (int i = start; i < end; i++) {
                array[i] = sp_readFloat(input) * scale;
            }
        }

        const int CURVE_LINEAR = 0;
        const int CURVE_STEPPED = 1;
        const int CURVE_BEZIER = 2;
        const int BEZIER_SIZE = 10 * 2 - 1;
        const float LINEAR = 0, STEPPED = 1, BEZIER = 2;

        public static void sp_readCurve(Stream input, int frameIndex, float[] curves) {
            switch (input.ReadByte()) {
                case CURVE_STEPPED:
                    curves[frameIndex * BEZIER_SIZE] = STEPPED;
                    break;
                case CURVE_BEZIER:
                    SetCurve(curves, frameIndex, sp_readFloat(input), sp_readFloat(input), sp_readFloat(input), sp_readFloat(input));
                    break;
            }
        }

        public static void SetCurve(float[] curves, int frameIndex, float cx1, float cy1, float cx2, float cy2) {
            float tmpx = (-cx1 * 2 + cx2) * 0.03f, tmpy = (-cy1 * 2 + cy2) * 0.03f;
            float dddfx = ((cx1 - cx2) * 3 + 1) * 0.006f, dddfy = ((cy1 - cy2) * 3 + 1) * 0.006f;
            float ddfx = tmpx * 2 + dddfx, ddfy = tmpy * 2 + dddfy;
            float dfx = cx1 * 0.3f + tmpx + dddfx * 0.16666667f, dfy = cy1 * 0.3f + tmpy + dddfy * 0.16666667f;

            int i = frameIndex * BEZIER_SIZE;
            curves[i++] = BEZIER;

            float x = dfx, y = dfy;
            for (int n = i + BEZIER_SIZE - 1; i < n; i += 2) {
                curves[i] = x;
                curves[i + 1] = y;
                dfx += ddfx;
                dfy += ddfy;
                ddfx += dddfx;
                ddfy += dddfy;
                x += dfx;
                y += dfy;
            }
        }

#else
        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr sp_newInput(IntPtr ptr, long len);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern void sp_inputSetPosition(IntPtr ptr, long position);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern long sp_inputGetPosition(IntPtr ptr);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern void sp_freeInput(IntPtr ptr);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int sp_readByte(IntPtr ptr);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int sp_readInt(IntPtr ptr);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern int sp_readVarint(IntPtr ptr, int optimizePositive);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern float sp_readFloat(IntPtr ptr);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern IntPtr sp_readString(IntPtr ptr, out IntPtr strlen);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern void sp_readColor(IntPtr ptr, out float r, out float g, out float b, out float a);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern void sp_readFloatArray(IntPtr ptr, float [] array, int start, int end, float scale);

        [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
        public static extern void sp_readCurve(IntPtr ptr, int frameIndex, float[] curves);

        IntPtr unmanagedPointer;

        public IntPtr ptr;
        long length;

        public SkeletonDataStream(byte[] bytes) {
            InitInput(bytes);
        }

        public SkeletonDataStream(Stream stream) {
            byte[] bytes = new byte[stream.Length];
            stream.Read(bytes, 0, (int)stream.Length);
            InitInput(bytes);
        }

        void InitInput(byte[] bytes) {
            unmanagedPointer = Marshal.AllocHGlobal(bytes.Length);
            Marshal.Copy(bytes, 0, unmanagedPointer, bytes.Length);
            length = bytes.Length;

            ptr = sp_newInput(unmanagedPointer, bytes.Length);
        }

        public void Close() {
            Marshal.FreeHGlobal(unmanagedPointer);
        }
        
        public long Length {
            get {
                return length;
            }
        }

        public long Position {
            get {
                return sp_inputGetPosition(ptr);
            }
            set {
                if (value < 0 || value > length) {
                    throw new IndexOutOfRangeException();
                }
                sp_inputSetPosition(ptr, value);
            }
        }

         public string ReadString() {
            IntPtr strlen;
            IntPtr str = sp_readString(ptr, out strlen);

            int len = strlen.ToInt32();
            if (len == 0) {
                return null;
            }

            if (len == 1) {
                return "";
            }

            len--;

            byte[] str_buffer = new byte[len];
            Marshal.Copy(str, str_buffer, 0, len);
            return Encoding.UTF8.GetString(str_buffer, 0, len);

#if false
            string ret = Marshal.PtrToStringAnsi(str, strlen.ToInt32());
            if (ret == null) {
                int len = strlen.ToInt32();
                byte[] buffer = new byte[len];
                Marshal.Copy(str, buffer, 0, len);
                return Encoding.UTF8.GetString(buffer);
            }
            return ret;
#endif
        }
#endif
        public int ReadByte() {
            return sp_readByte(ptr);
        }

        public int ReadInt() {
            return sp_readInt(ptr);
        }

        public int ReadVarint(bool optimizePositive) {
            return sp_readVarint(ptr, optimizePositive ? 1 : 0);
        }

        public float ReadFloat() {
            return sp_readFloat(ptr);
        }

        public bool ReadBoolean() {
            return ReadByte() != 0;
        }

        public sbyte ReadSByte() {
            int value = ReadByte();
            if (value == -1) throw new EndOfStreamException();
            return (sbyte)value;
        }

        public void ReadFloatArray(float[] array, int start, int end, float scale) {
            sp_readFloatArray(ptr, array, start, end, scale);
        }

        public void ReadCurve(int frameIndex, float[] curves) {
            sp_readCurve(ptr, frameIndex, curves);
        }

        /*
        public void ReadColor(out float r, out float g, out float b, out float a) {
            SkeletonDLL.sp_readColor(input, out r, out g, out b, out a);
        }
        */

        public static SkeletonDataStream Open(byte[] bytes) {
            return new SkeletonDataStream(bytes);
        }

        public static SkeletonDataStream Open(Stream stream) {
            return new SkeletonDataStream(stream);
        }
    }
}