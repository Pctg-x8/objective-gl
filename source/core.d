/**
 * <div class="header">
 * High-level OpenGL Wrapper/Helpers: Core Package
 * Authors: S.Percentage
 * </div>
 */
 /**
Macros:
 COPYRIGHT = Copyright 2016 S.Percentage
 DDOC = <!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<title>$(TITLE)</title>
<link rel="stylesheet" href="style.css" type="text/css" />
</head><body>
<div class="box">
<h1>$(TITLE)</h1>
$(BODY)
<hr>$(SMALL Page generated by $(LINK2 https://dlang.org/ddoc.html, Ddoc). $(COPYRIGHT))
</div>
</body></html>
*/
module objectivegl.core;

// Version Have_dglsl: Enabled dglsl support if required

public import derelict.opengl3.gl3;
import std.string, std.algorithm, std.range, std.meta, std.traits, std.typecons;
version(Have_dglsl)
{
	import dglsl;
}

/// Pixel Format for Textures
enum PixelFormat
{
	/// 32bpp full color
	RGBA = GL_RGBA,
	/// 8bpp single color
	Grayscale = GL_RED
}

/// OpenGL Texture Interfacing
abstract class Texture(GLenum TextureType)
{
	protected GLuint id;
	
	protected this() { glGenTextures(1, &this.id); }
	~this() { glDeleteTextures(1, &this.id); }
	
	protected void bind() { glBindTexture(TextureType, this.id); }
	static class Parameter
	{
		@disable this();
		
		static auto opIndexAssign(GLint value, GLenum param) { glTexParameteri(TextureType, param, value); }
	}
}

/// OpenGL Texture2D Representation
final class Texture2D : Texture!GL_TEXTURE_2D
{
	/// Makes empty texture
	public static auto newEmpty(int width, int height, PixelFormat format) in { assert(width >= 1 && height >= 1); } body
	{
		auto obj = new Texture2D();
		obj.bind();
		glTexImage2D(GL_TEXTURE_2D, 0, format, width, height, 0, format, GL_UNSIGNED_BYTE, null);
		Texture2D.Parameter[GL_TEXTURE_MIN_FILTER] = GL_LINEAR;
		Texture2D.Parameter[GL_TEXTURE_MAG_FILTER] = GL_LINEAR;
		return obj;
	}

	/// Updates texture
	public void update(int x, int y, int width, int height, const(ubyte)* pixels, PixelFormat format)
	{
		this.bind();
		glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, width, height, format, GL_UNSIGNED_BYTE, pixels);
	}
}

/// OpenGL Buffer Object Interfacing
abstract class Buffer(GLenum BufferType)
{
	protected GLuint id;
	protected this(GLuint buffer) { this.id = buffer; }
	~this() { glDeleteBuffers(1, &this.id); }
	
	protected static auto newOne(BufferDataT)(in BufferDataT* ptr, GLenum usage)
	{
		GLuint b;
		
		glGenBuffers(1, &b);
		glBindBuffer(BufferType, b); scope(exit) glBindBuffer(BufferType, 0);
		glBufferData(BufferType, BufferDataT.sizeof, ptr, usage);
		return b;
	}
}

/// OpenGL VertexArrayObject Representation
final class VertexArray
{
	private GLuint aid, bid;
	private GLuint vcount;

	private this(GLuint array, GLuint buffer, GLuint vcount)
	{
		this.aid = array;
		this.bid = buffer;
		this.vcount = vcount;
	}
	~this() { glDeleteBuffers(1, &this.bid); glDeleteVertexArrays(1, &this.aid); }

	/// Makes new Vertex Array Object from slice to be rendered with program
	public static auto fromSlice(T)(const T[] slice, const ShaderProgram program)
	{
		GLuint aid, bid;

		glGenVertexArrays(1, &aid);
		glGenBuffers(1, &bid);

		glBindVertexArray(aid); scope(exit) glBindVertexArray(0);
		glBindBuffer(GL_ARRAY_BUFFER, bid); scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBufferData(GL_ARRAY_BUFFER, slice.length * T.sizeof, slice.ptr, GL_STATIC_DRAW);
		program.applyInputLayouts();
		
		return new VertexArray(aid, bid, cast(GLuint)slice.length);
	}
	
	/// Instanced drawing shorthand
	public void drawInstanced(GLenum primitiveType)(GLint count)
	{
		GLDevice.Vertices = this;
		glDrawArraysInstanced(primitiveType, 0, this.vcount, count);
	}

	/// Updates buffer data
	public void update(T)(const T[] slice)
	{
		glBindBuffer(GL_ARRAY_BUFFER, this.bid); scope(exit) glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBufferData(GL_ARRAY_BUFFER, slice.length * T.sizeof, slice.ptr, GL_STATIC_DRAW);
		this.vcount = cast(GLuint)slice.length;
	}
}

/// Type inferred Uniform Buffer factory
final class UniformBufferFactory
{
	@disable this();
	
	/// Makes new Static(Modified once, used many times) Uniform Buffer with Data
	public static auto newStatic(BufferStructureT)(BufferStructureT buffer)
	{
		return new UniformBuffer!BufferStructureT(Buffer!GL_UNIFORM_BUFFER.newOne(&buffer, GL_STATIC_DRAW));
	}
}

/// OpenGL Uniform Buffer Representation
final class UniformBuffer(BufferStructureT) : Buffer!GL_UNIFORM_BUFFER
{
	private this(GLuint id) { super(id); }
	/// Makes new Static(Modified once, used many times) Uniform Buffer with Data
	public static auto newStatic(BufferStructureT buffer)
	{
		return new UniformBuffer(newOne(&buffer, GL_STATIC_DRAW));
	}
	/// Makes new Static(Modified once, used many times) Uniform Buffer
	public static auto newStatic()
	{
		return new UniformBuffer(newOne!BufferStructureT(null, GL_STATIC_DRAW));
	}
	
	/// Updates buffer data
	public void update(BufferStructureT buffer)
	{
		glBindBuffer(GL_UNIFORM_BUFFER, this.id); scope(exit) glBindBuffer(GL_UNIFORM_BUFFER, 0);
		glBufferSubData(GL_UNIFORM_BUFFER, 0, BufferStructureT.sizeof, &buffer);
	}
}

/// UDA: Mark field as Input Element
struct element
{
	/// Attribute Name in shader
	string attrName;
	/// Is value normalized?(default is false)
	bool normalized = false;
}
/// Type to OpenGL Type Enum
private template TypeEnum(T)
{
	static if(is(T : float)) alias TypeEnum = GL_FLOAT;
	else static assert(false, "Unsupported Type");
}
// Map fields to input element descriptor
private template InputElementGen(alias Symbol)
{
	immutable Attr = getUDAs!(Symbol, element)[0];
	immutable InputElementGen = InputElement(Attr.attrName, Symbol.length, TypeEnum!(typeof(Symbol[0])),
		Attr.normalized ? GL_TRUE : GL_FALSE, __traits(parent, Symbol).sizeof, cast(const GLvoid*)Symbol.offsetof);
}
/// Auto generated input element descriptor list from vertex data structure
private alias IEDescList(VertexDataT) = staticMap!(InputElementGen, getSymbolsByUDA!(VertexDataT, element));

// Vertex(Shader Input) Elements
private struct InputElement
{
	string attrName;
	GLint size;
	GLenum type;
	GLboolean normalized;
	GLsizei stride;
	const GLvoid* offset;
}

/// Shader Source Types
enum ShaderType : GLenum
{
	/// Vertex Shader
	Vertex = GL_VERTEX_SHADER,
	/// Fragment(Pixel) Shader
	Fragment = GL_FRAGMENT_SHADER,
	/// Geometry Shader
	Geometry = GL_GEOMETRY_SHADER
}

/// OpenGL ShaderProgram Representation
final class ShaderProgram
{
	private struct ResolvedInputElement
	{
		GLuint index;
		GLint size;
		GLenum type;
		GLboolean normalized;
		GLsizei stride;
		const GLvoid* offset;
	}
	private ResolvedInputElement[] elements;
	private GLuint pid;

	private this(GLuint p, const InputElement[] elements)
	{
		this.pid = p;
		this.elements = elements.map!(x => ResolvedInputElement(glGetAttribLocation(p, x.attrName.toStringz),
			x.size, x.type, x.normalized, x.stride, x.offset)).array;
		
		this.uniforms = new UniformLocations();
		this.uniformBlocks = new UniformBlockIndices();
	}
	~this() { glDeleteProgram(this.pid); }
	
	version(Have_dglsl)
	{
		/// Make shader program from dglsl shader classes
		public static auto fromDSLClasses(VertexDataT, ShaderT...)()
		{
			ShaderT shaders;
			foreach(i, ST; ShaderT)
			{
				shaders[i] = new ST();
				shaders[i].compile();
			}
			auto p = new dglsl.Program!ShaderT(shaders);
			return new ShaderProgram(p.id, [IEDescList!VertexDataT]);
		}
	}
	/// Make shader program from source codes
	public static auto fromSources(VertexDataT, ShaderSources...)()
	{
		auto compileShader(ShaderType T, string Source)()
		{
			auto sh = glCreateShader(T);
			auto src = Source.toStringz;
			auto srcLength = Source.length;
			glShaderSource(sh, 1, &src, cast(GLint*)&srcLength);
			glCompileShader(sh);
			
			GLint status;
			glGetShaderiv(sh, GL_COMPILE_STATUS, &status);
			if(status == GL_FALSE)
			{
				GLint errlen;
				GLchar[] errbuf;
				glGetShaderiv(sh, GL_INFO_LOG_LENGTH, &errlen);
				errbuf.length = errlen;
				glGetShaderInfoLog(sh, cast(GLint)errbuf.length, null, errbuf.ptr);
				throw new Exception(errbuf.idup);
			}
			return sh;
		}
		template shaderCompilationList(ShaderSources...)
		{
			static if(ShaderSources.length < 2) alias shaderCompilationList = AliasSeq!();
			else alias shaderCompilationList = AliasSeq!(compileShader!(ShaderSources[0], ShaderSources[1]), shaderCompilationList!(ShaderSources[2 .. $]));
		}
		auto shaders = [shaderCompilationList!ShaderSources];
		scope(exit) shaders.each!glDeleteShader;
		
		auto p = glCreateProgram();
		shaders.each!(x => glAttachShader(p, x));
		glLinkProgram(p);
		
		GLint status;
		glGetProgramiv(p, GL_LINK_STATUS, &status);
		if(status == GL_FALSE)
		{
			GLint errlen;
			GLchar[] errbuf;
			glGetProgramiv(p, GL_INFO_LOG_LENGTH, &errlen);
			errbuf.length = errlen;
			glGetProgramInfoLog(p, cast(GLint)errbuf.length, null, errbuf.ptr);
			throw new Exception(errbuf.idup);
		}
		return new ShaderProgram(p, [IEDescList!VertexDataT]);
	}
	/// Build shader from imported source
	unittest
	{
		auto shader = ShaderProgram.fromSources!(VertexData,
			ShaderType.Vertex, import("vsh.glsl"),
			ShaderType.Fragment, import("fsh.glsl"));
	}

	private void applyInputLayouts() const
	{
		glUseProgram(this.pid);
		foreach(ref e; this.elements)
		{
			glEnableVertexAttribArray(e.index);
			glVertexAttribPointer(e.index, e.size, e.type, e.normalized, e.stride, e.offset);
		}
		glUseProgram(0);
	}
	
	/// Activates(Uses) shader program
	public void activate() const
	{
		glUseProgram(this.pid);
	}
	
	private class UniformLocations
	{
		GLuint[string] cache;
		
		public auto opDispatch(string name)(int v) { this[name] = v; }
		public auto opDispatch(string name)(float v) { this[name] = v; }
		public auto opDispatch(string name)(float[2] v) { this[name] = v; }
		public auto opDispatch(string name)(in float[4] vf) { this[name] = vf; }
		public auto opDispatch(string name)(in float[4][4] matr) { this[name] = matr; }
		public auto opIndexAssign(int v, string name) { glUniform1i(this.getLocation(name), v); }
		public auto opIndexAssign(float v, string name) { glUniform1f(this.getLocation(name), v); }
		public auto opIndexAssign(float[2] v, string name) { glUniform2fv(this.getLocation(name), 1, v.ptr); }
		public auto opIndexAssign(in float[4] vf, string name) { glUniform4fv(this.getLocation(name), 1, vf.ptr); }
		public auto opIndexAssign(in float[4][4] matr, string name) { glUniformMatrix4fv(this.getLocation(name), 1, GL_FALSE, &matr[0][0]); }
		version(Have_gl3n)
		{
			import gl3n.linalg;
			public auto opDispatch(string name)(in vec2 vf) { this[name] = vf; }
			public auto opDispatch(string name)(in vec4 vf) { this[name] = vf; }
			public auto opIndexAssign(in vec2 vf, string name) { glUniform2fv(this.getLocation(name), 1, vf.value_ptr); }
			public auto opIndexAssign(in vec4 vf, string name) { glUniform4fv(this.getLocation(name), 1, vf.value_ptr); }
		}
		
		private auto getLocation(string name)
		{
			if(name !in cache) cache[name] = glGetUniformLocation(this.outer.pid, name.toStringz);
			return cache[name];
		}
	}
	/// Field like Uniform Accessors
	UniformLocations uniforms;
	
	private class UniformBlockIndices
	{
		GLuint[string] cache;
		
		public auto opDispatch(string name)(int idx) { this[name] = idx; }
		public auto opIndexAssign(int idx, string name) { glUniformBlockBinding(this.outer.pid, this.getIndex(name), idx); }
		
		private auto getIndex(string name)
		{
			if(name !in cache) cache[name] = glGetUniformBlockIndex(this.outer.pid, name.toStringz);
			return cache[name];
		}
	}
	/// Field like Uniform Block Binding
	UniformBlockIndices uniformBlocks;
}

/// Blend Function
alias BlendFunc = Tuple!(GLenum, "srcBlend", GLenum, "destBlend");
/// Predefined Blend Functions
final class BlendFunctions
{
	@disable this();
	
	static immutable Alpha = BlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
}

/// OpenGL Device Representation
final class GLDevice
{
	@disable this();
	
	/// Texture Units
	static class TextureUnits
	{
		@disable this();
		
		static void opIndexAssign(GLenum TextureType)(in Texture!TextureType tex, int index)
		{
			glActiveTexture(GL_TEXTURE0 + index);
			glBindTexture(TextureType, tex.id);
		}
	}
	/// Accessing texture unit with index
	unittest
	{
		GLDevice.TextureUnits[0] = texture;
	}
	
	/// Binding Point Table
	static class BindingPoint
	{
		@disable this();
		
		static void opIndexAssign(T)(in UniformBuffer!T buffer, int index)
		{
			glBindBufferBase(GL_UNIFORM_BUFFER, index, buffer.id);
		}
	}
	
	/// Input Assembler: Vertex Buffer and Input Layout
	static class Vertices
	{
		@disable this();
		
		static void opAssign(in VertexArray varray)
		{
			glBindVertexArray(varray.aid);
		}
	}
	
	/// Rasterizer State
	static class RasterizerState
	{
		@disable this();
		
		private static class DeviceCaps(GLenum CapEnum)
		{
			@disable this();
			
			static void opAssign(bool flag)
			{
				(flag ? glEnable : glDisable)(CapEnum);
			}
		}
		public alias Blending = DeviceCaps!GL_BLEND;
		public alias ScissorTest = DeviceCaps!GL_SCISSOR_TEST;
		public alias BackCulling = DeviceCaps!GL_CULL_FACE;
		public alias DepthTest = DeviceCaps!GL_DEPTH_TEST;
		public alias DepthClamp = DeviceCaps!GL_DEPTH_CLAMP;
		static void opDispatch(string name)(BlendFunc blend) if(name == "BlendFunc")
		{
			glBlendFunc(blend.srcBlend, blend.destBlend);
		}
	}
	
	/// Pixel Store
	static class PixelStore
	{
		@disable this();
		
		static auto opIndexAssign(GLint value, GLenum param) { glPixelStorei(param, value); }
	}
}
