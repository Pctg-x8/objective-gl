/**
 * <div class="header">
 * High-level OpenGL Wrapper/Helpers: Utility Templates
 * Authors: S.Percentage
 * </div>
 */
module objectivegl.utils;
 
import std.meta;

/// Hex to RGBA for glClearColor/glColor4f(0xaarrggbb)
template HexColor(uint hex)
{
	immutable Alpha = ((hex >> 24) & 0xff) / 255.0f;
	immutable Red = ((hex >> 16) & 0xff) / 255.0f;
	immutable Green = ((hex >> 8) & 0xff) / 255.0f;
	immutable Blue = (hex & 0xff) / 255.0f;
	
	alias HexColor = AliasSeq!(Red, Green, Blue, Alpha);
}
