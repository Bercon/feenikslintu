# Feenikslintu

Feenikslintu is a demoscene 4kb exceutable graphics, meaning all code that generates the image fits into 4096 bytes. It participated to 4kb exceutable graphics category at Revision 2025 demoscene party.

The entry is packaged as Windows PowerShell script which runs the compressed image generation code in web browser.

![Feenikslintu](Feenikslintu/Feenikslintu.png)

If you have a powerful GPU, you can run the entry in your browser. Your browser must suppord WebGPU (Chrome, Edge, etc.): https://bercon.github.io/feenikslintu/

This entry is using the same engine as [INCENDIUM](https://github.com/Bercon/incendium), it has been modified to run 6 simulations, store all of them into different buffers and when render the scene by raymarching all of them simulatenously.

The engine is based on heavily optimized and stripped down version of [Roquefort](https://github.com/Bercon/roquefort), an in browser fluid simlator tech demo that runs even on less powerful hardware, especially if you drop the grid size smaller. Developing the Roquefort first allowed much easier debuging of the fluid simulation code. You can play around with the simulation here: https://bercon.github.io/roquefort/

## Highlights

* Fluid simulation and rendering is done with WebGPU compute shaders
* 3D fluid simulator with multigrid solver that uses red-black Gauss-Seidel iteration to run faster and to read/write same buffer
* Box blur computed using accumulation to get any kernel size at fixed 4 lookups per pixel. Gaussian blur is approximated by running box blur twice
* Volumetric shadows, restricted to primary axis light directions
* Baking lighting makes it possible to do only single vec4 lookup per simulation for each raymarching step
* 324 byte PowerShell bootstrapper for Brotli compressed webpage (40 bytes less than on used in [Felid](https://demozoo.org/graphics/342293/)), might be possible to compress it even more?

## Requirements

* Operating systems default browser must support WebGPU. Currently it means Chrome, Edge, or other new Chromium based browser. Non-nightly/beta Firefox and Safari won't work.
* Nvidia RTX 4080 level GPU to run 1080p 60hz. Running at 60hz is important for smooth artifact free fluid simulation

## Setup

Building intro and package it (install requirements: `pip install -R requirements.txt`):
```
python scripts/build.py
```

Drag'n'drop `build/index.html` to browser. To run packaged entry, double click `builld/entry.cmd`

The final entry was packaged with heavier settings than the defaults, try overkill settings like this to drop the size below 4kb:
```
python scripts/build.py --slow -s 100000 -D 15
```

## Compression

The entry uses Brotli compression that is quite unpredictable, *adding* characters sometimes decreases the size of the results. Flipping order of rows, using different characters and so on, which don't change the size of the data being compress can change the size of the compressed result by tens of bytes. A *packager* which is heavily based on [Pakettic](https://github.com/vsariola/pakettic) will suffle rows and try different variants of code to find the optimal layout. Running without this with ```python scripts/build.py --no_optimization``` gives 4187 bytes, while with enough suffling, we can drop this to 4093, improving compressiong by 94 bytes.

There is still room for improvement with the packager, it doesn't try variable renaming, swapping operation order, trying different variants such as `a/2` and `a*.5` which give the same result. All things Pakettic does for TIC-80 code. These could further improve the compression and make using the tool more automatic with less need for manually annotating the code. However, this requires implementing proper WGSL parsing which does take some amount of effort.

## Packaging and bootstrapping

The entry is compressed HTML page with brotli. Since brotli compressed content can only be served via web server, not locally opening the file we need a web server. This is achieved with Windows PowerShell script that serves the file itself with suitable offset once as via Windows builtin HTTP server. Technique introduce first (I think?) by Muhmac / Speckdrumm in Felid:  https://demozoo.org/graphics/342293/

One downside is that it opens the entry in the default browser. This entry requires WebGPU only supported in Chromium browsers like Edge or Chrome which means if default browser is Firefox, the entry will not work.

## Authors

* Jerry "Bercon" Ylilammi

## License

MIT license, see LICENSE
