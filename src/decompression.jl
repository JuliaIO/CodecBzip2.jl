# Decompression Codec
# ===================

struct Bzip2Decompression <: TranscodingStreams.Codec
    stream::BZStream
end

function Bzip2Decompression(;small::Bool=false, verbosity::Integer=0)
    stream = BZStream()
    code = decompress_init!(stream, verbosity, small)
    if code != BZ_OK
        bzerror(stream, code)
    end
    return Bzip2Decompression(stream)
end

const Bzip2DecompressionStream{S} = TranscodingStream{Bzip2Decompression,S} where S<:IO

function Bzip2DecompressionStream(stream::IO)
    return TranscodingStream(Bzip2Decompression(), stream)
end


# Methods
# -------

function TranscodingStreams.process(codec::Bzip2Decompression, input::Memory, output::Memory)
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
        bzerror(stream, code)
    end
end

function TranscodingStreams.finalize(codec::Bzip2Decompression)
    code = decompress_end!(codec.stream)
    if code != BZ_OK
        bzerror(stream, code)
    end
    return
end
