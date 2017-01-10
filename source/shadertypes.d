/**
 * <div class="header">
 * High-level OpenGL Wrapper/Helpers: Shader Types Definition
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
module objectivegl.shadertypes;

// Vector Types
public alias ShaderVec2 = float[2];			/// vec2
public alias ShaderVec4 = float[4];			/// vec4
public alias ShaderMatrix4 = float[4 * 4];	/// mat4
