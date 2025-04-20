@compute @workgroup_size(8,8)
fn n(@builtin(global_invocation_id) global_id: vec3u) {
    var b = vec2f(global_id.xy);
    var r = D(vec3(vec2f(global_id.xy), u.t)); // Same as composite.wgsl
    // #alternative
    var c = (b + r.xy - .5 * vec2f(P_CANVAS_WIDTH, P_CANVAS_HEIGHT)) / P_CANVAS_WIDTH; // #or
    var c = (b + r.xy - vec2f(P_CANVAS_WIDTH, P_CANVAS_HEIGHT) / 2) / P_CANVAS_WIDTH; // #endalternative
    var p = vec3f( // Camera position
        // 0,
        .5,
        -2.2,
        -.35
    );
    var z = normalize(
         vec3( // Cam target
            0,
            0,
            -.1
        )
        -p);
    var x = normalize(vec3(z.y, -z.x, 0));
    var y = cross(z, x);
    // Basic pinhole camera dir
    var d = z
        + c.x * x // * fov
        + c.y * y; // * fov
    // Ray-box intersection
    x = (-1 - p) / d;
    y = (1 - p) / d;
    z = min(x, y);
    var w = max(x, y);
    var t = max(z.x, max(z.y, z.z)); // Closest hit
    var o = min(w.x, min(w.y, w.z)); // Farthest hit
    w = vec3(0); // Color
    if (t <= o) { // Hit
        var a = 1.;
        t = P_STEP_LENGTH * r.z + max(0, t);
        while (t < o) { // Raymach loop
            x = (p + d * t + 1) / 2;
            var s = vec4f(0);
            // s = trilerp4(&$tmp, .5 + a * P_GRID_RES);
            // pos = (pos - vec3f(0.440,0.436,0.559)) / 0.16;
            // if (pos.x > 0 && pos.y > 0 && pos.z > 0
            //     && pos.x < 1 && pos.y < 1 && pos.z < 1
            // ) {
            //     s = add_smoke(s, trilerp4(&$tmp, .5 + pos * P_GRID_RES));
            // }
            S(x, &s, &$pressure,        vec4(P_Grid_Head));
            S(x, &s, &$temperature_in,  vec4(P_Grid_LeftWing));
            S(x, &s, &$temperature_out, vec4(P_Grid_RightWing));
            S(x, &s, &$velocity_in,     vec4(P_Grid_Tail));
            S(x, &s, &$smoke_in,        vec4(P_Grid_Body));
            S(x, &s, &$smoke_out,       vec4(0,0,0,1));

            // sample(x, &s, &$pressure, vec4(0,0,0,1));

            s.w *= P_STEP_LENGTH * P_OPTICAL_DENSITY;
            a *= exp(-s.w);
            w += a * s.xyz * s.w;
            t += P_STEP_LENGTH;
        }
        // Red corners for debugging
        // var hit = o * d + p; // Take the furtest hit
        // if (abs(hit.x) > .95 && abs(hit.y) > .95 && abs(hit.z) > .95) { w = vec3f(1,0,0); }
    }
    // w = max(vec4f(0), w);
    $velocity_out[global_id.x + global_id.y * P_CANVAS_WIDTH] = vec4f(w, 1);
}

fn S(
    p: vec3f, // Position
    s: ptr<function, vec4f>,
    t: ptr<storage, array<vec4f>, read_write>,
    v: vec4f, // Offset and scale
) {
    var b = (p - v.xyz) / v.w;
    if (b.x > 0 && b.y > 0 && b.z > 0
        && b.x < 1 && b.y < 1 && b.z < 1
    ) {
        (*s) = add_smoke((*s), trilerp4(t, .5 + b * P_GRID_RES));
    }
    // var a = trilerp4(t, .5 + b * P_GRID_RES);
    // b = abs(b - .5) - .5;
    // a.w *= smoothstep(0, .01, -max(max(b.x, b.y), b.z));
    // (*s) = add_smoke((*s), a);
}


