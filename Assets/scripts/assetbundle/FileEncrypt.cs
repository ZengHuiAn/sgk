using ICSharpCode.SharpZipLib.Zip;
using System.IO;
using UnityEngine;
using ICSharpCode.SharpZipLib.Core;
using System.Runtime.InteropServices;
using System;
using System.Text;

public class FileEncrypt
{

    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern void decode(byte [] buffer, int pos, int count);
 
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern void encode(byte [] buffer, int pos, int count);

    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr zip_archive_create(string filename);
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern void zip_archive_delete(IntPtr archive);
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern int zip_stream_locate(IntPtr archive, string filename);
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern IntPtr zip_stream_create(IntPtr archive, string filename);
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern void zip_stream_delete(IntPtr stream);
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern int zip_stream_read(IntPtr stream, byte [] buffer, int offset, int count);
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong zip_stream_seek(IntPtr stream, long offset, int origin);
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong zip_stream_length(IntPtr stream);
    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern ulong zip_stream_postion(IntPtr stream);

    [DllImport(XLua.LuaDLL.Lua.LUADLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern void zip_stream_set_log_file(IntPtr stream, string path);

#if UNITY_ANDROID && !UNITY_EDITOR
    ~FileEncrypt()
    {
        if (FileEncrypt.EncryptStreamZIP.CZip != IntPtr.Zero)
        {
            zip_archive_delete(FileEncrypt.EncryptStreamZIP.CZip);
        }
    }
#endif

    public static void Encrypt(string source, string output = null)
    {
        if (output == null)
        {
            output = source;
        }

        try
        {
            string dir = Path.GetDirectoryName(output);
            if (!Directory.Exists(dir))
            {
                Directory.CreateDirectory(dir);
            }

            FileStream rfs = File.Open(source, FileMode.Open);
            byte[] bts = new byte[rfs.Length];
            rfs.Read(bts, 0, bts.Length);
            rfs.Close();

            encode(bts, 0, bts.Length);

            FileStream wfs = File.Open(output, FileMode.Create);
            wfs.Write(bts, 0, bts.Length);
            wfs.Flush();
            wfs.Close();
        }
        catch(System.Exception ex)
        {
            Debug.LogError(ex);
        }
    }

    // static int count = 0;
    public static AssetBundle LoadFromFile(string fullpath, out Stream fileStream)
    {
        // var watch = new System.Diagnostics.Stopwatch();
        // watch.Start();
        // Debug.Log("ASSETBUNDLE:" + fullpath + " : " + (count ++));
        fileStream = null;
#if UNITY_EDITOR
        FileStream fs = File.OpenRead(fullpath);
        byte [] bs = new byte[fs.Length];
        fs.Read(bs, 0, (int)fs.Length);
        decode(bs, 0, (int)fs.Length);
        return AssetBundle.LoadFromMemory(bs);
#else
        AssetBundle ab = null;
        EncryptStream et = new EncryptStream(fullpath);
        if (et.Exist())
        {
            ab = AssetBundle.LoadFromStream(et);
            if (ab != null) {
                fileStream = et;
            }
        } else {
            et.Dispose();
        }
        // ab = AssetBundle.LoadFromFile(fullpath);

        // watch.Stop();
        // UnityEngine.Debug.Log(string.Format("LoadFromStream bundle dela time {0}ms, {1}", watch.ElapsedMilliseconds, fullpath));
        return ab;
#endif
    }
     
    public static AssetBundleCreateRequest LoadFromFileAsync(string fullpath, out Stream fileStream)
    {
        // Debug.Log("ASSETBUNDLE ASYNC:" + fullpath + " : " + (count++));

        fileStream = null;

#if UNITY_EDITOR
        FileStream fs = File.OpenRead(fullpath);
        byte[] bs = new byte[fs.Length];
        fs.Read(bs, 0, (int)fs.Length);
        decode(bs, 0, (int)fs.Length);
        return AssetBundle.LoadFromMemoryAsync(bs);
#else

        AssetBundleCreateRequest req = null;
        EncryptStream et = new EncryptStream(fullpath);
        if (et.Exist())
        {
            fileStream = et;
            req = AssetBundle.LoadFromStreamAsync(et);
        }

        return req;
#endif
    }

    public static bool BundleExistInPackage(string path)
    {
#if UNITY_ANDROID && !UNITY_EDITOR
        if (EncryptStreamZIP.CZip == IntPtr.Zero)
        {
            Debug.LogError("EncryptStreamZIP zip is null");
            return false;
        }

        return zip_stream_locate(EncryptStreamZIP.CZip, "assets/" + path) >= 0;
#endif
        return File.Exists(Application.streamingAssetsPath + "/" + path);
    }

    private class EncryptStreamZIP : Stream
    {
        IntPtr mStream;
        static IntPtr mCZip;

        public static IntPtr CZip
        {
            get
            {
                if (mCZip == IntPtr.Zero)
                {
                    Debug.Log("data path:" + Application.dataPath);
                    Debug.Log("persistentDataPath path:" + Application.persistentDataPath);
#if UNITY_EDITOR
                    mCZip = zip_archive_create(Application.dataPath.Replace("Assets", "") + "build/fairy.apk");
#else
                    mCZip = zip_archive_create(Application.dataPath);
#endif
                }

                return mCZip;
            }
        }

        public EncryptStreamZIP(string path)
        {
            string npath = path.Replace(Application.streamingAssetsPath, "assets").Replace("\\", "/");
            mStream = zip_stream_create(CZip, npath);
        }

        public override bool CanRead { get { return Exist(); } }
        public override bool CanSeek { get { return Exist(); } }
        public override bool CanWrite { get { return false; } }
        public override long Length { get { return (long)zip_stream_length(mStream);} }
        public override long Position { get { return (long)zip_stream_postion(mStream); } set { }}
        public override void Flush() { }

        public override int Read(byte[] buffer, int offset, int count)
        {
            return zip_stream_read(mStream, buffer, offset, count);
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            ulong r = zip_stream_seek(mStream, offset, (int)origin);
            return (long)r;
        }

        public override void SetLength(long value)
        {
            throw new Exception("not support 'SetLength'");
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            throw new Exception("not support 'Write'");
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            if (Exist())
            {
                zip_stream_delete(mStream);
                mStream = IntPtr.Zero;
            }
        }

        public bool Exist()
        {
            return mStream != IntPtr.Zero;
        }

        public override void Close() {
            base.Close();
            if (Exist()) {
                zip_stream_delete(mStream);
                mStream = IntPtr.Zero;
            }
        }
    }

    public class EncryptStream : System.IO.Stream
    {
        Stream mStream;

        public EncryptStream(string path)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            if (path.IndexOf(Application.streamingAssetsPath) >= 0)
            {
                mStream = new EncryptStreamZIP(path);
            }else
            {
                try
                {
                    mStream = File.OpenRead(path);
                }
                catch (System.Exception ex)
                {
                    mStream = null;
                    Debug.LogError(ex);
                }
            }
#else
            try
            {
                mStream = File.OpenRead(path);
            }
            catch (System.Exception ex)
            {
                mStream = null;
                Debug.LogError(ex);
            }
#endif
        }

        public override bool CanRead { get { return mStream.CanRead; } }

        public override bool CanSeek { get { return mStream.CanSeek; } }

        public override bool CanWrite { get { return mStream.CanWrite; } }

        public override long Length { get { return mStream.Length; } }

        public override long Position
        {
            get { return mStream.Position; }
            set { mStream.Position = value; }
        }

        public override void Flush()
        {
            mStream.Flush();
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            int ret = mStream.Read(buffer, offset, count);
            decode(buffer, (int)mStream.Position - ret, ret);
            return ret;
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            return mStream.Seek(offset, origin);
        }

        public override void SetLength(long value)
        {
            mStream.SetLength(value);
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            encode(buffer, (int)mStream.Position, count);
            mStream.Write(buffer, offset, count);
        }

        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            if (mStream != null) {
                mStream.Dispose();
                mStream = null;
            }
        }

        public override void Close() {
            base.Close();
            if (mStream != null) {
                mStream.Close();
                mStream = null;
            }
        }

        public bool Exist()
        {
            return mStream != null && CanRead;
        }
    }
}
