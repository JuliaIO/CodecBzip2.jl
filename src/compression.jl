# Compressor Codec
# ================

mutable struct CompressorContext
    @atomic is_ready::Bool
    stream::BZStream
    function CompressorContext()
        ctx = new(false, BZStream())
        finalizer(compressor_ctx_finalizer!, ctx)
    end
end

function compressor_ctx_finalizer!(ctx::CompressorContext)
    # The atomic variable is needed because this may be called
    # with both finalizer and TranscodingStreams.finalize
    # and TranscodingStreams.finalize might get called in other finalizers
    if @atomicswap(ctx.is_ready = false)
        compress_end!(ctx.stream)
    end
    return
end

struct Bzip2Compressor <: TranscodingStreams.Codec
    ctx::CompressorContext
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
    return Bzip2Compressor(CompressorContext(), blocksize100k, workfactor, verbosity)
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
    ctx = codec.ctx
    GC.@preserve ctx compressor_ctx_finalizer!(ctx)
    return
end

function TranscodingStreams.startproc(codec::Bzip2Compressor, ::Symbol, error_ref::Error)
    ctx = codec.ctx
    GC.@preserve ctx begin
        compressor_ctx_finalizer!(ctx)
        @atomic ctx.is_ready = true
        code = compress_init!(ctx.stream, codec.blocksize100k, codec.verbosity, codec.workfactor)
        # errors in compress_init! do not require clean up, so just throw
        if code == BZ_OK
            return :ok
        elseif code == BZ_CONFIG_ERROR
            error("BZ_CONFIG_ERROR: libbzip2 has been mis-compiled")
        elseif code == BZ_PARAM_ERROR
            error("BZ_PARAM_ERROR: this must be checked in Bzip2Compressor constructor")
        elseif code == BZ_MEM_ERROR
            throw(OutOfMemoryError())
        else
            error("unexpected libbzip2 error code: $(code)")
        end
    end
end

function TranscodingStreams.process(codec::Bzip2Compressor, input::Memory, output::Memory, error_ref::Error)
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
        code = compress!(stream, input.size > 0 ? BZ_RUN : BZ_FINISH)
        Δin = Int(avail_in - stream.avail_in)
        Δout = Int(avail_out - stream.avail_out)
        if code == BZ_RUN_OK || code == BZ_FINISH_OK
            return Δin, Δout, :ok
        elseif code == BZ_STREAM_END
            return Δin, Δout, :end
        else
            error_ref[] = BZ2Error(code)
            return Δin, Δout, :error
        end
    end
end
