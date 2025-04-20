
@compute @workgroup_size(4,4,4)
fn n(@builtin(global_invocation_id) global_id : vec3u) {
    var k = to_index(P_GRID_RES_X, global_id);
    var p = vec3f(global_id) + .5 - .02 * $velocity_in[k].xyz * P_RDX;
    // #reorder
    var v = trilerp4(&$velocity_in, p); // #and
    var s = trilerp4(&$smoke_in, p); // #and
    var w = vec3f(global_id) / P_GRID_RES; // #endreorder
    var t = min(v.w, .02); //  Amount of fuel burnt

    if (u.t < P_ITERATIONS_BEFORE_ENV) {
        s.a *= exp(-.1);
    }
    // #reorder
    v = vec4(v.xyz * exp(-.002), v.w - t); // #and
    s = add_smoke(s, vec4(.3, .3, .3, t * P_BURN_SMOKE_EMIT)); // #and
    var f = trilerp1(&$temperature_in, p) * exp(-.06)
        + t * P_BURN_HEAT_EMIT; // #endreorder

    // Emit

    if (u.t < P_ITERATIONS) { // Head
        // #reorder
        surface(&v, &s, &f, w, 0, // TopBeak
            2, // Sphere count
            vec2(.033), // Sphere radius
            vec2(0, 2), // Velocity multiplier
            vec2(2), // Fuel amount
            vec2(1), // Temperature amount
            vec4(.7,.3,.3,.25),  // Smoke
            10); // Generated spline count
        // #and
        surface(&v, &s, &f, w, 1, // BottomBeak
            2, // Sphere count
            vec2(.04), // Sphere radius
            vec2(0, 2), // Velocity multiplier
            vec2(2), // Fuel amount
            vec2(1), // Temperature amount
            vec4(.7,.3,.3,.25), // Smoke
            10); // Generated spline count
        // #and
        surface(&v, &s, &f, w, 2, // Head
            3, // Sphere count
            vec2(.03), // Sphere radius
            vec2(-1, 1.5), // Velocity multiplier
            vec2(2), // Fuel amount
            vec2(.5), // Temperature amount
            vec4(.5,.3,.3,.2), // Smoke
            15); // Generated spline count
        // #and
        for (var i = 0; i < 4; i++) { // Crest
            spline(&v, &s, &f, w, 12 + i,
                5, // Sphere count
                vec2(.04), // Sphere radius
                vec2(.2, 1), // Velocity multiplier
                vec2(4), // Fuel amount
                vec2(3), // Temperature amount
                vec4(.7,.3,.3,.1)); // Smoke
        }
        // #endreorder
    } else if (u.t < P_ITERATIONS * 2) {
        surface(&v, &s, &f, w, 4, // Left wing
            3, // Sphere count
            vec2(.05, .03), // Sphere radius
            vec2(0, 3), // Velocity multiplier
            vec2(1, 4), // Fuel amount
            vec2(.5, .25), // Temperature amount
            vec4(.3, .3, .3, .4), // Smoke
            15); // Generated spline count
    } else if (u.t < P_ITERATIONS * 3) {
        surface(&v, &s, &f, w, -4, // Right wing
            3, // Sphere count
            vec2(.05, .03), // Sphere radius
            vec2(0, 3.3), // Velocity multiplier
            vec2(1, 4.3), // Fuel amount
            vec2(.5, .25), // Temperature amount
            vec4(.3, .3, .3, .4), // Smoke
            15); // Generated spline count
    } else if (u.t < P_ITERATIONS * 4) {
        surface(&v, &s, &f, w, 5, // Tail
            3, // Sphere count
            vec2(.03, .05), // Sphere radius
            vec2(0, 3), // Velocity multiplier
            vec2(1, 4), // Fuel amount
            vec2(-.25,.8), // Temperature amount
            vec4(.35, .3, .3, .6), // Smoke
            10); // Generated spline count
    } else if (u.t < P_ITERATIONS * 5) { // Body
        surface(&v, &s, &f, w, 6, // Neck
            5, // Sphere count
            vec2(.03), // Sphere radius
            vec2(0, 2), // Velocity multiplier
            vec2(1), // Fuel amount
            vec2(0), // Temperature amount
            vec4(.35, .3, .3, 1), // Smoke
            15); // Generated spline count
        surface(&v, &s, &f, w, 7, // Legs
            2, // Sphere count
            vec2(.03), // Sphere radius
            vec2(.3, 1), // Velocity multiplier
            vec2(2), // Fuel amount
            vec2(0), // Temperature amount
            vec4(.3, .25, .25, 3), // Smoke
            7); // Generated spline count
        surface(&v, &s, &f, w, -7,
            2, // Sphere count
            vec2(.03), // Sphere radius
            vec2(.3, 1), // Velocity multiplier
            vec2(2), // Fuel amount
            vec2(0), // Temperature amount
            vec4(.3, .25, .25, 3), // Smoke
            7); // Generated spline count
        surface(&v, &s, &f, w, 8, // Shins
            2, // Sphere count
            vec2(.03), // Sphere radius
            vec2(.3, 1), // Velocity multiplier
            vec2(2), // Fuel amount
            vec2(0), // Temperature amount
            vec4(.3, .25, .25, 3), // Smoke
            7); // Generated spline count
        surface(&v, &s, &f, w, -8,
            2, // Sphere count
            vec2(.03), // Sphere radius
            vec2(.3, 1), // Velocity multiplier
            vec2(2), // Fuel amount
            vec2(0), // Temperature amount
            vec4(.3, .25, .25, 3), // Smoke
            7); // Generated spline count

        surface(&v, &s, &f, w, 9, // Bottom
            2, // Sphere count
            vec2(.03), // Sphere radius
            vec2(.3, 1), // Velocity multiplier
            vec2(2), // Fuel amount
            vec2(2), // Temperature amount
            vec4(.3, .25, .25, 3), // Smoke
            7); // Generated spline count

        for (var i = 0; i < 4; i++) { // Talons
            spline(&v, &s, &f, w, 40 + i,
                5, // Sphere count
                vec2(.023), // Sphere radius
                vec2(4), // Velocity multiplier
                vec2(2), // Fuel amount
                vec2(10), // Temperature amount
                vec4(.5, .5, .5, .2)); // Smoke
        }
        for (var i = 0; i < 4; i++) { // Talons
            spline(&v, &s, &f, w, -(40 + i),
                5, // Sphere count
                vec2(.023), // Sphere radius
                vec2(4), // Velocity multiplier
                vec2(2), // Fuel amount
                vec2(10), // Temperature amount
                vec4(.5, .5, .5, .2)); // Smoke
        }
    } else { // Environment
        if (u.t < P_ITERATIONS * 5 + 100) {
            var x = vec4(P_Grid_LeftWing);
            surface(&v, &s, &f, (w - x.xyz) / x.w, 4, // Left wing
                3, // Sphere count
                vec2(.07), // Sphere radius
                vec2(10), // Velocity multiplier
                vec2(0), // Fuel amount
                vec2(.7), // Temperature amount
                vec4(
                    mix(vec3(.4), vec3(.3, .3, .5), (u.t - P_ITERATIONS * 5) * .01),
                    1), // Smoke
                15); // Generated spline count
            x = vec4(P_Grid_RightWing);
            surface(&v, &s, &f, (w - x.xyz) / x.w, -4, // Right wing
                3, // Sphere count
                vec2(.07), // Sphere radius
                vec2(10), // Velocity multiplier
                vec2(0), // Fuel amount
                vec2(.7), // Temperature amount
                vec4(
                    mix(vec3(.4), vec3(.3, .3, .5), (u.t - P_ITERATIONS * 5) * .01),
                    1), // Smoke
                15); // Generated spline count
            x = vec4(P_Grid_Tail);
            surface(&v, &s, &f, (w - x.xyz) / x.w, 5, // Tail
                1, // Sphere count
                vec2(.07), // Sphere radius
                vec2(6), // Velocity multiplier
                vec2(0), // Fuel amount
                vec2(0), // Temperature amount
                vec4(.4), // Smoke
                15); // Generated spline count
        }

        // #reorder
        if (w.y > .9) {
            v.z += u.d;
        } // #and
        if (w.x > .9) {
            v.y += .006;
        } // #endreorder
        w -= .5;
        var a = sign(w.x);
        w.x -= .25 * a;
        var l = length(w);
        if (l < .1 && l > .01) {
            v.x += w.y * .04 / l * a;
            v.y += -w.x * .04 / l * a;
        }
    }

    // Reset between sims
    if (i32(u.t) % P_ITERATIONS == 0) {
        f = 0;
        v = vec4(0);
        s = vec4(0);
    }

    // #reorder
    $velocity_out[k] = v + vec4(0,0,1,0) * f * .01;  // #and
    $smoke_out[k] = s; // #and
    $temperature_out[k] = f; // #endreorder
}

const Q = array(Z);

// #reorder
fn bezier4(t: f32, a: vec3f, b: vec3f, c: vec3f, d: vec3f) -> vec3f {
    var u = 1 - t;
    return u * u * u * a
        + 3 * u * u * t * b
        + 3 * u * t * t * c
        + t * t * t * d;
}
// Bezier derivative for direction
fn bezier4d(t: f32, a: vec3f, b: vec3f, c: vec3f, d: vec3f) -> vec3f {
    var u = 1 - t;
    return 3 * u * u * (b - a)
        + 6 * u * t * (c - b)
        + 3 * t * t * (d - c);
}
// #and
fn bezier1(t: f32, i: i32) -> vec3f {
    return bezier4(t, Q[i * 4], Q[i * 4 + 1], Q[i * 4 + 2], Q[i * 4 + 3]);
}
fn bezier1d(t: f32, i: i32) -> vec3f {
    return bezier4d(t, Q[i * 4], Q[i * 4 + 1], Q[i * 4 + 2], Q[i * 4 + 3]);
}
// #and
// Surface defined by 4 bezier splines, or 4x4 control vertices
fn spline(
    v: ptr<function, vec4f>,
    s: ptr<function, vec4f>,
    f: ptr<function, f32>,
    w: vec3f, // World pos
    o: i32, // Spline idx
    e: i32, // Sphere count
    h: vec2f, // Sphere radius
    r: vec2f, // Velocity multiplier
    t: vec2f, // Fuel amount
    q: vec2f, // Temperature amount
    z: vec4f // Smoke
) {
    for (var i = 0; i < e; i++) {
        var y = D(vec3f(f32(i), 1, u.t)).x;
        var p = bezier1(y, abs(o));
        var A = normalize(bezier1d(y, abs(o)));
        A.x = select(A.x, -A.x, o < 0);
        var B = clamp(-(length(select(w, vec3(1 - w.x, w.y, w.z), o < 0) - p) - mix(h.x, h.y, y)) / .01, 0, 1) * u.d;
        (*v) += vec4(A * mix(r.x, r.y, y), mix(t.x, t.y, y)) * B;
        (*s) = add_smoke((*s), vec4f(z.xyz, z.w * B));
        (*f) += mix(q.x, q.y, y) * B;
    }
}
// #and
// Surface defined by 4 bezier splines, or 4x4 control vertices
fn surface(
    v: ptr<function, vec4f>,
    s: ptr<function, vec4f>,
    f: ptr<function, f32>,
    w: vec3f, // World pos
    o: i32, // Starting spline
    e: i32, // Sphere count
    h: vec2f, // Sphere radius
    r: vec2f, // Velocity multiplier
    t: vec2f, // Fuel amount
    q: vec2f, // Temperature amount
    z: vec4f, // Smoke
    x: i32 // Generated spline count
) {
    // var t = u.t * .1;
    for (var j = 0; j < x; j++) {
        var x = f32(j) / f32(x - 1);
        var a = bezier1(x, abs(o) * 4);
        var b = bezier1(x, abs(o) * 4 + 1);
        var c = bezier1(x, abs(o) * 4 + 2);
        var d = bezier1(x, abs(o) * 4 + 3);
        for (var i = 0; i < e; i++) {
            var y = D(vec3f(f32(i), f32(j), u.t)).x;
            var p = bezier4(y, a, b, c, d);
            var A = normalize(bezier4d(y, a, b, c, d));
            A.x = select(A.x, -A.x, o < 0);
            var B = clamp(-(length(select(w, vec3(1 - w.x, w.y, w.z), o < 0) - p) - mix(h.x, h.y, y)) / .01, 0, 1) * u.d;
            (*v) += vec4(A * mix(r.x, r.y, y), mix(t.x, t.y, y)) * B;
            (*s) = add_smoke((*s), vec4f(z.xyz, z.w * B));
            (*f) += mix(q.x, q.y, y) * B;
        }
    }
}
// #endreorder
