
TestRust: BuildTest CopyRust

BuildTest:
	cd copi_rust && ohrs build --release

CopyRust:
	rsync -av --exclude oh-package.json5  copi_rust/dist/ entry/libs/
