using BinDeps
@BinDeps.setup

libbz2 = library_dependency("libbz2",aliases=["libbz2-1"])
if Sys.iswindows()
	using WinRPM
	provides(WinRPM.RPM,"libbz2-1",libbz2,os = :Windows)
end
@BinDeps.install Dict(:libbz2=>:libbz2)
