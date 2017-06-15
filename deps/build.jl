using BinDeps
@BinDeps.setup

libbz2 = library_dependency("libbz2",aliases=["libbz2-1"])
if is_windows()
	using WinRPM
	provides(WinRPM.RPM,"libbz2-1",libbz2,os = :Windows)
	@BinDeps.install Dict(:libbz2=>:libbz2)
end
