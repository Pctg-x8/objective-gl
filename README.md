Objective-GL
---

**[Working-in-progress]**  
High-level OpenGL Wrapper/Helper.

## Features

- Easy to use OpenGL 3.x
- Memory/Resource safety(all objects are freed automatically)
- [dglsl](http://code.dlang.org/packages/dglsl) support(Write shader codes in Dlang source)
- Auto-generated vertex attribute configuration

## API Documentation

See https://pctg-x8.github.io/docs/objectivegl/gl.html

### Example: Rendering with Objective-GL

Add project directory(`.`) to `stringImportPaths` in project settings(dub.sdl).

```d
import derelict.glfw3.glfw3;
import objectivegl;					// Objective-GL
import dglsl;

final class VertexShaderSource : Shader!Vertex
{
	@input
	{
		vec2 pos;
		vec4 color;
	}
	@output vec4 col_frag;
	
	void main()
	{
		col_frag = color;
		gl_Position = vec4(pos, 0.0f, 1.0f);
	}
}
final class FragmentShaderSource : Shader!Fragment
{
	@input vec4 col_frag;
	@output vec4 color;
	
	void main() { color = col_frag; }
}
struct VertexData
{
	// input elements are marked by @element attribute
	@element("pos") float[2] pos;
	@element("color") float[4] col;
}

void main()
{
	DerelictGL3.load();
	DerelictGLFW3.load();
	if(!glfwInit()) throw new Exception("GLFW initialization failed.");
	scope(exit) glfwTerminate();
	
	// For Intel Graphics(Forced to use OpenGL 3.3 Core Profile)
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	
	auto pWindow = glfwCreateWindow(640, 480, "Rendering with Objective-GL", null, null);
	if(pWindow is null) throw new Exception("GLFW window creation failed.");
	glfwMakeContextCurrent(pWindow);
	DerelictGL3.reload();
	
	// objective-gl resources //
	auto shader = ShaderProgram.fromDSLClasses!(VertexData, VertexShaderSource, FragmentShaderSource);
	auto vertices = VertexArray.fromSlice([
		VertexData([0.0f, 0.0f], [1.0f, 1.0f, 1.0f, 1.0f]),
		VertexData([1.0f, 0.0f], [0.0f, 1.0f, 1.0f, 1.0f]),
		VertexData([0.0f, 1.0f], [1.0f, 0.0f, 1.0f, 1.0f])
	], shader);
	
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	while(!glfwWindowShouldClose(pWindow))
	{
		int w, h;
		glfwGetFramebufferSize(pWindow, &w, &h);
		glViewport(0, 0, w, h);
		glClear(GL_COLOR_BUFFER_BIT);
		
		shader.useWith!({ vertices.drawInstanced!GL_TRIANGLES(1); });
		
		glfwSwapBuffers(pWindow);
		glfwWaitEvents();
	}
}
```

## Future Features

- Create Texture2D from image files
- Texture1D/3D support
- Integer type support for Input Element Descriptor
- HDR/Buffer-like Pixel Format support
- Tessellator stage shaders support
