// imgcrush Metal Shaders

#include <metal_stdlib>
using namespace metal;

// MARK: - Bilinear resize kernel

kernel void resize_bilinear(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }

    float2 inputSize = float2(input.get_width(), input.get_height());
    float2 outputSize = float2(output.get_width(), output.get_height());
    float2 scale = inputSize / outputSize;
    float2 coord = float2(gid) * scale;

    uint2 c00 = uint2(floor(coord));
    uint2 c11 = min(c00 + 1, uint2(inputSize - 1));
    uint2 c01 = uint2(c00.x, c11.y);
    uint2 c10 = uint2(c11.x, c00.y);

    float2 frac = coord - float2(c00);

    float4 p00 = input.read(c00);
    float4 p10 = input.read(c10);
    float4 p01 = input.read(c01);
    float4 p11 = input.read(c11);

    float4 top = mix(p00, p10, frac.x);
    float4 bottom = mix(p01, p11, frac.x);
    float4 result = mix(top, bottom, frac.y);

    output.write(result, gid);
}

// MARK: - Color space conversion kernel (sRGB ↔ Linear)

kernel void color_space_convert(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    constant int &mode [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }

    float4 color = input.read(gid);

    if (mode == 0) {
        // sRGB → Linear
        color.rgb = select(
            pow((color.rgb + 0.055) / 1.055, 2.4),
            color.rgb / 12.92,
            color.rgb <= 0.04045
        );
    } else {
        // Linear → sRGB
        color.rgb = select(
            1.055 * pow(color.rgb, 1.0 / 2.4) - 0.055,
            color.rgb * 12.92,
            color.rgb <= 0.0031308
        );
    }

    output.write(color, gid);
}
