@compute @workgroup_size(8,8)
fn n(@builtin(global_invocation_id) global_id : vec3u) {
    var c = vec3(1.);
    for (var i = 0; i < P_GRID_RES_X; i++) {
        var p = vec3u(global_id.x, global_id.y, u32(P_GRID_RES_MINUS_ONE - i));
        var k = to_index(P_GRID_RES_X, p);
        // #reorder
        var s = $smoke_in[k]; // #and
        var t = $temperature_in[k]; // #endreorder
        $tmp[k] = vec4(
            s.xyz * (
                mix( // Fake lighting from the fire hitting the environment
                    vec3(3, 1.75, 1.04),
                    vec3(1.15, 1.35, 1.75),
                    smoothstep(.3, .45, length(.5 - vec3f(p) / P_GRID_RES))
                ) * c // Light
                // + vec3f(207, 238, 250) / 255 * .01  // Ambient light // + vec3(.4, .5, .7) * .05
                + mix( // Blackbody color
                    vec3(.5, .3, .1),
                    mix(
                        vec3(1, .6, .3),
                        vec3(.89, .91, 1),
                        clamp((t - 2) / 4, 0, 1)),
                    clamp((t - 1) / 2, 0, 1)
                ) * (max(t, 1) - 1) * P_BLACKBODY_BRIGHTNESS),
            s.w
        );
        c *= exp(-(1 - s.xyz) * s.w * P_OPTICAL_DENSITY / P_GRID_RES_X);
    }
}
