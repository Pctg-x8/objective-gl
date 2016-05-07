/**
 * <div class="header">
 * High-level OpenGL Wrapper/Helpers: Utility Templates
 * Authors: S.Percentage
 * </div>
 */
module objectivegl.utils;
 
import std.meta;

/// Hex to RGBA for glClearColor/glColor4f
alias HexInterpret(uint hex) = AliasSeq!((hex & 0xff) / 255.0f, ((hex & 0xff00) >> 8) / 255.0f,
	((hex & 0xff0000) >> 16) / 255.0f, ((hex & 0xff000000) >> 24) / 255.0f);
