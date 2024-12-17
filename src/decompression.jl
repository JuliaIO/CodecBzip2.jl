# Decompressor Codec
# ==================

mutable struct DecompressorContext
    @atomic is_ready::Bool
    stream::BZStream
    function DecompressorContext()
        ctx = new(false, BZStream())
        finalizer(decompressor_ctx_finalizer!, ctx)
    end
end

function decompressor_ctx_finalizer!(ctx::DecompressorContext)
    # The atomic variable is needed because this may be called
    # with both finalizer and TranscodingStreams.finalize
    # and TranscodingStreams.finalize might get called in other finalizers
    if @atomicswap ctx.is_ready = false
        decompress_end!(ctx.stream)
    end
    return
end

mutable struct Bzip2Decompressor <: TranscodingStreams.Codec
    ctx::DecompressorContext
    small::Bool
    verbosity::Int
end

function Base.show(io::IO, codec::Bzip2Decompressor)
    print(io, summary(codec), "(small=$(codec.small), verbosity=$(codec.verbosity))")
end

"""
    Bzip2Decompressor(;small=false, verbosity=$(DEFAULT_VERBOSITY))

Create a bzip2 decompression codec.

Arguments
---------
- `small`: flag to activate an algorithm which uses less memory
- `verbosity`: verbosity level (0..4)
"""
function Bzip2Decompressor(;small::Bool=false, verbosity::Integer=DEFAULT_VERBOSITY)
    if !(0 ≤ verbosity ≤ 4)
        throw(ArgumentError("verbosity must be within 0..4"))
    end
    return Bzip2Decompressor(DecompressorContext(), small, verbosity)
end

const Bzip2DecompressorStream{S} = TranscodingStream{Bzip2Decompressor,S} where S<:IO

"""
    Bzip2DecompressorStream(stream::IO; kwargs...)

Create a bzip2 decompression stream (see `Bzip2Decompressor` for `kwargs`).
"""
function Bzip2DecompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:small, :verbosity))
    return TranscodingStream(Bzip2Decompressor(;x...), stream; y...)
end


# Methods
# -------

function TranscodingStreams.finalize(codec::Bzip2Decompressor)
    ctx = codec.ctx
    GC.@preserve ctx decompressor_ctx_finalizer!(ctx)
    return
end

function TranscodingStreams.startproc(codec::Bzip2Decompressor, ::Symbol, error_ref::Error)
    ctx = codec.ctx
    GC.@preserve ctx begin
        decompressor_ctx_finalizer!(ctx)
        code = decompress_init!(ctx.stream, codec.verbosity, codec.small)
        # errors in decompress_init! do not require clean up, so just throw
        if code == BZ_OK
            return :ok
        elseif code == BZ_CONFIG_ERROR
            error("BZ_CONFIG_ERROR: libbzip2 has been mis-compiled")
        elseif code == BZ_PARAM_ERROR
            error("BZ_PARAM_ERROR: this must be checked in Bzip2Decompressor constructor")
        elseif code == BZ_MEM_ERROR
            throw(OutOfMemoryError())
        else
            error("unexpected libbzip2 error code: $(code)")
        end
    end
end

function TranscodingStreams.process(codec::Bzip2Decompressor, input::Memory, output::Memory, error_ref::Error)
    ctx = codec.ctx
    GC.@preserve ctx begin
        stream = ctx.stream
        if stream.state == C_NULL
            error("startproc must be called before process")
        end
        stream.next_in = input.ptr
        avail_in = min(input.size, typemax(Cuint))
        stream.avail_in = avail_in
        stream.next_out = output.ptr
        avail_out = min(output.size, typemax(Cuint))
        stream.avail_out = avail_out
        code = decompress!(stream)
        Δin = Int(avail_in - stream.avail_in)
        Δout = Int(avail_out - stream.avail_out)
        if code == BZ_OK
            if iszero(input.size) && !iszero(stream.avail_out)
                error_ref[] = BZ2Error(BZ_UNEXPECTED_EOF)
                return Δin, Δout, :error
            else
                return Δin, Δout, :ok
            end
        elseif code == BZ_STREAM_END
            return Δin, Δout, :end
        elseif code == BZ_MEM_ERROR
            throw(OutOfMemoryError())
        else
            error_ref[] = BZ2Error(code)
            return Δin, Δout, :error
        end
    end
end
