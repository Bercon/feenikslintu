
// comp: velocity_out, tmp -> canvas
@compute @workgroup_size(8, 8)
fn n(@builtin(global_invocation_id) global_id : vec3u) {
    var b = global_id.x + global_id.y * P_CANVAS_WIDTH;
    var p = $velocity_out[b]
        + pow( // Glow
            $tmp[b],
            vec4(1.7)) * .2; // Glow gamma & strength
    p = pow(p, vec4(.5))
        + D(vec3(vec2f(global_id.xy), 1000)).x / 255; // Debanding
    p.w = 1;
    textureStore(T, global_id.xy, p);
}