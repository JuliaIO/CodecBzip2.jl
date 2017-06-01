using CodecBzip2
using Base.Test
import TranscodingStreams: test_roundtrip_read, test_roundtrip_write

@testset "Bzip2 Codec" begin
    test_roundtrip_read(Bzip2CompressionStream, Bzip2DecompressionStream)
    test_roundtrip_write(Bzip2CompressionStream, Bzip2DecompressionStream)
end
