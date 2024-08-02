using CodecBzip2
using Test
import TranscodingStreams
using TestsForCodecPackages:
    test_roundtrip_read,
    test_roundtrip_write,
    test_roundtrip_transcode,
    test_roundtrip_lines,
    test_roundtrip_seekstart

@testset "Bzip2 Codec" begin
    codec = Bzip2Compressor()
    @test codec isa Bzip2Compressor
    @test occursin(r"^(CodecBzip2\.)?Bzip2Compressor\(blocksize100k=\d+, workfactor=\d+, verbosity=\d+\)$", sprint(show, codec))
    @test CodecBzip2.initialize(codec) === nothing
    @test CodecBzip2.finalize(codec) === nothing

    codec = Bzip2Decompressor()
    @test codec isa Bzip2Decompressor
    @test occursin(r"^(CodecBzip2\.)?Bzip2Decompressor\(small=(true|false), verbosity=\d+\)$", sprint(show, codec))
    @test CodecBzip2.initialize(codec) === nothing
    @test CodecBzip2.finalize(codec) === nothing

    # Generated by `bz2.compress(b"foo")` on CPython 3.5.2.
    data = b"BZh91AY&SYI\xfe\xc4\xa5\x00\x00\x00\x01\x00\x01\x00\xa0\x00!\x00\x82,]\xc9\x14\xe1BA'\xfb\x12\x94"
    @test read(Bzip2DecompressorStream(IOBuffer(data))) == b"foo"
    @test read(Bzip2DecompressorStream(IOBuffer(vcat(data, data)))) == b"foofoo"

    # concatenate two bzip2 blocks
    buf = IOBuffer()
    stream = Bzip2CompressorStream(buf)
    write(stream, b"foo", TranscodingStreams.TOKEN_END)
    write(stream, b"bar", TranscodingStreams.TOKEN_END)
    @test read(Bzip2DecompressorStream(IOBuffer(take!(buf)))) == b"foobar"

    @test Bzip2CompressorStream <: TranscodingStreams.TranscodingStream
    @test Bzip2DecompressorStream <: TranscodingStreams.TranscodingStream

    test_roundtrip_read(Bzip2CompressorStream, Bzip2DecompressorStream)
    test_roundtrip_write(Bzip2CompressorStream, Bzip2DecompressorStream)
    test_roundtrip_lines(Bzip2CompressorStream, Bzip2DecompressorStream)
    test_roundtrip_seekstart(Bzip2CompressorStream, Bzip2DecompressorStream)
    test_roundtrip_transcode(Bzip2Compressor, Bzip2Decompressor)

    @test_throws ArgumentError Bzip2Compressor(blocksize100k=10)
    @test_throws ArgumentError Bzip2Compressor(workfactor=251)
    @test_throws ArgumentError Bzip2Compressor(verbosity=5)
    @test_throws ArgumentError Bzip2Decompressor(verbosity=5)
end
