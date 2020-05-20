# Compressor Codec
# ================

mutable struct Bzip2Compressor <: TranscodingStreams.Codec
    stream::BZStream
    blocksize100k::Int
    workfactor::Int
    verbosity::Int
end

function Base.show(io::IO, codec::Bzip2Compressor)
    print(io, summary(codec), "(blocksize100k=$(codec.blocksize100k), workfactor=$(codec.workfactor), verbosity=$(codec.verbosity))")
end

const DEFAULT_BLOCKSIZE100K = 9
const DEFAULT_WORKFACTOR = 30
const DEFAULT_VERBOSITY = 0

"""
    Bzip2Compressor(;blocksize100k=$(DEFAULT_BLOCKSIZE100K), workfactor=$(DEFAULT_WORKFACTOR), verbosity=$(DEFAULT_VERBOSITY))

Create a bzip2 compression codec.

Arguments
---------
- `blocksize100k`: block size to be use for compression (1..9)
- `workfactor`: amount of effort the standard algorithm will expend before resorting to the fallback (0..250)
- `verbosity`: verbosity level (0..4)
"""
function Bzip2Compressor(;blocksize100k::Integer=DEFAULT_BLOCKSIZE100K,
                           workfactor::Integer=DEFAULT_WORKFACTOR,
                           verbosity::Integer=DEFAULT_VERBOSITY)
    if !(1 ≤ blocksize100k ≤ 9)
        throw(ArgumentError("blocksize100k must be within 1..9"))
    elseif !(0 ≤ workfactor ≤ 250)
        throw(ArgumentError("workfactor must be within 0..250"))
    elseif !(0 ≤ verbosity ≤ 4)
        throw(ArgumentError("verbosity must be within 0..4"))
    end
    return Bzip2Compressor(BZStream(), blocksize100k, workfactor, verbosity)
end

const Bzip2CompressorStream{S} = TranscodingStream{Bzip2Compressor,S} where S<:IO

"""
    Bzip2CompressorStream(stream::IO; kwargs...)

Create a bzip2 compression stream (see `Bzip2Compressor` for `kwargs`).
"""
function Bzip2CompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:blocksize100k, :workfactor, :verbosity))
    return TranscodingStream(Bzip2Compressor(;x...), stream; y...)
end


# Methods
# -------

function TranscodingStreams.finalize(codec::Bzip2Compressor)
    if codec.stream.state != C_NULL
        code = compress_end!(codec.stream)
        if code != BZ_OK
            bzerror(codec.stream, code)
        end
    end
    return
end

function TranscodingStreams.startproc(codec::Bzip2Compressor, ::Symbol, error::Error)
    if codec.stream.state != C_NULL
        code = compress_end!(codec.stream)
        if code != BZ_OK
            error[] = BZ2Error(code)
            return :error
        end
    end
    code = compress_init!(codec.stream, codec.blocksize100k, codec.verbosity, codec.workfactor)
    if code != BZ_OK
        error[] = BZ2Error(code)
        return :error
    end
    return :ok
end

function TranscodingStreams.process(codec::Bzip2Compressor, input::Memory, output::Memory, error::Error)
    stream = codec.stream
    stream.next_in = input.ptr
    stream.avail_in = input.size
    stream.next_out = output.ptr
    stream.avail_out = output.size
    code = compress!(stream, input.size > 0 ? BZ_RUN : BZ_FINISH)
    Δin = Int(input.size - stream.avail_in)
    Δout = Int(output.size - stream.avail_out)
    if code == BZ_RUN_OK || code == BZ_FINISH_OK
        return Δin, Δout, :ok
    elseif code == BZ_STREAM_END
        return Δin, Δout, :end
    else
        error[] = BZ2Error(code)
        return Δin, Δout, :error
    end
end
