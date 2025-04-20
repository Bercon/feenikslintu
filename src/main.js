S = performance.now();

navigator.gpu.requestAdapter().then(
    d => d.requestDevice({
        requiredLimits: {
            maxStorageBufferBindingSize: y = P_GRID_RES_X * P_GRID_RES_X * P_GRID_RES_X * 16,
            maxBufferSize: y
        },
    }).then(device => { // Intentionally "device", we can call configure({device, ...})

c.width = P_CANVAS_WIDTH;
c.height = P_CANVAS_HEIGHT;
c.style=`position: fixed; top: 0px; left: 0px`;

// #ifdef DEBUG
c.style.width = P_CANVAS_WIDTH / window.devicePixelRatio;
c.style.height = P_CANVAS_HEIGHT / window.devicePixelRatio;
// #endif

x = c.getContext(`webgpu`);
x.configure({
    device,
    format: `P_PRESENTATION_FORMAT`,
    usage: 24 // GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.STORAGE_BINDING
});

u = device.createBuffer({
    size: 4,
    usage: 72 //GPUBufferUsage.COPY_DST | GPUBufferUsage.UNIFORM |
});

b = [];
for (i = 0; i < 14; i++)
    b.push(device.createBuffer({
        size: y,
        usage: 132 //GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC
    }));
    // 0 pressure, only using 2/4th
    // 1 temperatureRead, only using 1/4th
    // 2 temperatureWrite, only using 2/4th (divergence multigrid)
    // 3 velocityRead
    // 4 velocityWrite
    // 5 smokeRead
    // 6 smokeWrite
    // 7 temp, used for blurring

    // 8 phoenix head
    // 9 phoenix left wing
    // 10 phoenix right wing
    // 11 phoenix body
    // 12 phoenix tail

y = `PHOENIX_VERTICES`;
z = ``;
for (i = 0; i < PHOENIX_NUM_FLOATS_TWICE; i += 6) {
    z += `vec3(`
        + y.substring(i, i + 2) * .01 + `,`
        + y.substring(i + 2, i + 4) * .01 + `,`
        + y.substring(i + 4, i + 6) * .01 + `),`
}

o = i = 0;
layout = device.createBindGroupLayout({ // Intentinoally "layout"
    entries: [
        // We don't want more than 8 buffers, because that's what supported by default without requesting more and that takes bytes
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: { type: `storage` } },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: { type: `storage` } },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: { type: `storage` } },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: { type: `storage` } },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: { type: `storage` } },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: { type: `storage` } },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: { type: `storage` } },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: { type: `storage` } },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, buffer: {} },
        { binding: i++, visibility: GPUShaderStage.COMPUTE, storageTexture: { format: `P_PRESENTATION_FORMAT` } }
    ]
});

p = [
    `CODE_DIVERGENCE`, // 0
    `CODE_GRADIENT_SUBTRACT`, // 1
    `CODE_LIGHTING`, // 2
    `CODE_ADVECT`.replaceAll(`Z`, z), // 3
    `CODE_RENDER` // 4
];

for (i = 0; i < 4; i++) {
    // blur H: velocity_out -> smoke_out  , X=width, Y=1, Q=width
    // blur V: smoke_out    -> tmp        , X=1, Y=width, Q=height
    // blur H: tmp          -> smoke_out  , ...
    // blur V: smoke_out    -> tmp        , ...
    a = [
        `$velocity_out$smoke_out$tmp$smoke_out`[i], // input, each optimized to single letter
        `$smoke_out$tmp$smoke_out$tmp`[i], // output, each optimized to single letter
        i % 2 ? 1 : P_CANVAS_WIDTH,
        i % 2 ? P_CANVAS_WIDTH : 1,
        i % 2 ? P_CANVAS_HEIGHT : P_CANVAS_WIDTH
    ];
    d = `CODE_BLUR`;
    for (k = 0; k < 5; k++) d = d.replaceAll(`ZWXYQ`[k], a[k]);
    p.push(d)
}

p.push(
    `CODE_COMPOSITE` // 9
);

// Multigrid templating, end up having duplicates of restrict & interpolate steps, but saves some bytes
q = P_GRID_RES_X;
for (i = 0; i < P_MULTIGRID_LEVELS; i++) { // 6 * 6 = 36
    a = [
        o, // Z = current element offset
        o += q * q * q, // W = coarser element offset
        q, // X = current grid size
        q /= 2 // Y = coarser grid size next level offset
    ];
    for (j = 0; j < 2; j++)
        a[4] = j, // Q = even / odd
        [`CODE_RESTRICT`,`CODE_SOLVE`,`CODE_INTERPOLATE`].map(d => {
            for (k = 0; k < 5; k++) d = d.replaceAll(`ZWXYQ`[k], a[k]);
            p.push(d)
        })
}

p = p.map((d, i) =>
    device.createComputePipeline({
        layout: device.createPipelineLayout({bindGroupLayouts:[layout]}),
        compute: {
            module: device.createShaderModule({
                // Hack to allow using 8 vec4f buffers for rendering
                code: `CODE_COMMON`.replaceAll("f32>;", i == 4 ? "vec4f>;" : "f32>;") + d
            })
        }
    }));

h = [
    0, P_GRID_RES_BY_4, P_GRID_RES_BY_4, P_GRID_RES_BY_4 // div
];

for (i = 0; i < P_MULTIGRID_LEVELS_MINUS_ONE; i++) { // restrict
    // console.log("restrict", l, " -> ", l + 1);
    a = P_GRID_RES_BY_4 / 2 ** (i + 1);
    h.push(6 * i + 10, a, a, a);
}
for (; i >= 0; i--) { // i is already at correct level after restrict
    // console.log("solve", l);
    a = P_GRID_RES / 4 / 2 ** i;
    // for (k = 0; k < P_PRESSURE_ITERATIONS; k++) { // TODO: Unroll if iters == 2
        h.push(6 * i + 11, a, a, a / 2); // solve even
        h.push(6 * i + 14, a, a, a / 2); // solve odd
        h.push(6 * i + 11, a, a, a / 2); // solve even
        h.push(6 * i + 14, a, a, a / 2); // solve odd
    // }
    // if (i) { // i != 0
        // console.log("interpolate", l, " -> ", l - 1);
        i && h.push(6 * i + 6, a, a, a) // interpolate
    // }
}
l = i = 1;
h.push(
    i++, P_GRID_RES_BY_4, P_GRID_RES_BY_4, P_GRID_RES_BY_4, // grad
    i++, P_GRID_RES_BY_8, P_GRID_RES_BY_8, 1, // light & bake
    i++, P_GRID_RES_BY_4, P_GRID_RES_BY_4, P_GRID_RES_BY_4, // advect
    i++, P_CANVAS_WIDTH / 8, P_CANVAS_HEIGHT / 8, 1, // render
    i++, P_CANVAS_HEIGHT / 60, 1, 1, // blur h
    i++, P_CANVAS_WIDTH / 60, 1, 1, // blur v
    i++, P_CANVAS_HEIGHT / 60, 1, 1, // blur h
    i++, P_CANVAS_WIDTH / 60, 1, 1, // blur v
    i++, P_CANVAS_WIDTH / 8, P_CANVAS_HEIGHT / 8, 1 // composite
);

t = j = 0;

(f = d => {
    k = j; // Swap read and write buffers required in advect step
    j = j ^ 1;

    // Run
    device.queue.writeBuffer(
        u,
        0,
        new Float32Array(
            [
                // .02,
                t
            ]
        )
    );

    l = t == P_TOTAL_ITERATIONS; // Render on final run

    q = device.createCommandEncoder();
    e = q.beginComputePass();
    i = 0;

    g = device.createBindGroup({
        layout,
        entries: [
            { binding: i++, resource: { buffer: l ? b[7] : b[0] } },
            { binding: i++, resource: { buffer: l ? b[8] : b[j + 1] } },
            { binding: i++, resource: { buffer: l ? b[9] : b[k + 1] } },
            { binding: i++, resource: { buffer: l ? b[10] : b[j + 3] } },
            { binding: i++, resource: { buffer: b[k + 3] } }, // Render buffer
            { binding: i++, resource: { buffer: l ? b[11] : b[j + 5] } },
            { binding: i++, resource: { buffer: l ? b[12] : b[k + 5] } },
            { binding: i++, resource: { buffer: b[[7,8,9,10,11,12,0][t / P_ITERATIONS | 0]] } },
            { binding: i++, resource: { buffer: u } },
            { binding: i++, resource: x.getCurrentTexture().createView() }
        ]
    });

    i = l ? 128 : 0;
    do {
        if (t % P_ITERATIONS != P_ITERATIONS - 1 && i == 120) { i+=4; continue; } // Bake only on 119th
        e.setPipeline(p[h[i++]]);
        e.setBindGroup(0, g);
        e.dispatchWorkgroups(h[i++],h[i++],h[i++]);
    } while(i < (l ? 152 : 128))

    e.end();

    device.queue.submit([q.finish()]);

    // console.log(Math.round(t / 7.2) + "%");

    t++ < P_TOTAL_ITERATIONS && requestAnimationFrame(f)

    // #ifdef DEBUG
    ;
    if (t > P_TOTAL_ITERATIONS) {
        console.log("Took", Math.round((performance.now() - S) * .001), "seconds");
        var d = c.toDataURL('image/png');
        c.addEventListener('click', function pngSaver() {
            var link = document.createElement('a');
            link.download = 'Feenikslintu.png';
            link.href = d;
            link.click();
            c.removeEventListener('click', pngSaver);
        });
    }
    // #endif

})()

})) // navigator promise
