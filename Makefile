Default: BuildNative OhpmInstall

all: Default BuildHap

Clean: CleanNative

OhpmInstall:
	ohpm install

BuildNative:
	$(MAKE) -C native

CleanNative:
	$(MAKE) -C native Clean

BuildHap:
	hvigorw assembleHap --mode module -p product=default -p buildMode=release --no-daemon
