# CodecBzip2.jl

[![codecov.io][codecov-img]][codecov-url]

## Installation

```julia
Pkg.add("CodecBzip2")
```

## Usage

```julia
using CodecBzip2

# Some text.
text = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sollicitudin
mauris non nisi consectetur, a dapibus urna pretium. Vestibulum non posuere
erat. Donec luctus a turpis eget aliquet. Cras tristique iaculis ex, eu
malesuada sem interdum sed. Vestibulum ante ipsum primis in faucibus orci luctus
et ultrices posuere cubilia Curae; Etiam volutpat, risus nec gravida ultricies,
erat ex bibendum ipsum, sed varius ipsum ipsum vitae dui.
"""

# Streaming API.
stream = Bzip2CompressorStream(IOBuffer(text))
for line in eachline(Bzip2DecompressorStream(stream))
    println(line)
end
close(stream)

# Array API.
compressed = transcode(Bzip2Compressor, text)
@assert sizeof(compressed) < sizeof(text)
@assert transcode(Bzip2Decompressor, compressed) == Vector{UInt8}(text)
```

This package exports following codecs and streams:

| Codec                | Stream                     |
| -------------------- | -------------------------- |
| `Bzip2Compressor`    | `Bzip2CompressorStream`    |
| `Bzip2Decompressor`  | `Bzip2DecompressorStream`  |

See docstrings and [TranscodingStreams.jl](https://github.com/bicycle1885/TranscodingStreams.jl) for details.

[travisci-img]: https://travis-ci.org/bicycle1885/CodecBzip2.jl.svg?branch=master
[travisci-url]: https://travis-ci.org/bicycle1885/CodecBzip2.jl
[appveyor-img]: https://ci.appveyor.com/api/projects/status/bqm4qh5cd13u70cm?svg=true
[appveyor-url]: https://ci.appveyor.com/project/bicycle1885/codecbzip2-jl
[codecov-img]: http://codecov.io/github/bicycle1885/CodecBzip2.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/bicycle1885/CodecBzip2.jl?branch=master
