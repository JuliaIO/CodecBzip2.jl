# Decompression Codec
# ===================

struct Bzip2Decompression <: TranscodingStreams.Codec
    stream::BZStream
    small::Bool
    verbosity::Int
end

"""
    Bzip2Decompression(;small=false, verbosity=$(DEFAULT_VERBOSITY))

Create a bzip2 decompression codec.

Arguments
---------
- `small`: flag to activate an algorithm which uses less memory
- `verbosity`: verbosity level (0..4)
"""
function Bzip2Decompression(;small::Bool=false, verbosity::Integer=DEFAULT_VERBOSITY)
    if !(0 ≤ verbosity ≤ 4)
        throw(ArgumentError("verbosity must be within 0..4"))
    end
    return Bzip2Decompression(BZStream(), small, verbosity)
end

const Bzip2DecompressionStream{S} = TranscodingStream{Bzip2Decompression,S} where S<:IO

"""
    Bzip2DecompressionStream(stream::IO; kwargs...)

Create a bzip2 decompression stream (see `Bzip2Decompression` for `kwargs`).
"""
function Bzip2DecompressionStream(stream::IO; kwargs...)
    return TranscodingStream(Bzip2Decompression(;kwargs...), stream)
end


# Methods
# -------

function TranscodingStreams.finalize(codec::Bzip2Decompression)
    if codec.stream.state != C_NULL
        code = decompress_end!(codec.stream)
        if code != BZ_OK
            bzerror(codec.stream, code)
        end
    end
    return
end

function TranscodingStreams.startproc(codec::Bzip2Decompression, ::Symbol, error::Error)
    if codec.stream.state != C_NULL
        code = decompress_end!(codec.stream)
        if code != BZ_OK
            error[] = BZ2Error(code)
            return :error
        end
    end
    code = decompress_init!(codec.stream, codec.verbosity, codec.small)
    if code != BZ_OK
        error[] = BZ2Error(code)
        return :error
    end
    return :ok
end

function TranscodingStreams.process(codec::Bzip2Decompression, input::Memory, output::Memory, error::Error)
    stream = codec.stream
    stream.next_in = input.ptr
    stream.avail_in = input.size
    stream.next_out = output.ptr
    stream.avail_out = output.size
    code = decompress!(stream)
    Δin = Int(input.size - stream.avail_in)
    Δout = Int(output.size - stream.avail_out)
    if code == BZ_OK
        return Δin, Δout, :ok
    elseif code == BZ_STREAM_END
        return Δin, Δout, :end
    else
        error[] = BZ2Error(code)
        return Δin, Δout, :error
    end
end
