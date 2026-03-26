all: pi-sdeb bmv2-sdeb p4c-sdeb

p4c_version := v1.2.5.9

p4c:
	git clone --depth 1 -b $(p4c_version) https://github.com/p4lang/p4c p4c
	rm -rf p4c/debian
	cp -r p4lang-p4c p4c/debian

bmv2:
	git clone --recurse-submodules -b main https://github.com/p4lang/behavioral-model bmv2
	rm -rf bmv2/debian
	cp -r p4lang-bmv2 bmv2/debian

pi:
	git clone --recurse-submodules -b main https://github.com/p4lang/PI pi
	rm -rf pi/debian
	cp -r p4lang-pi pi/debian

############################
# Install build dependencies
############################

apt-update:
	apt-get update

p4c-install-deps: p4c apt-update
	cd p4c && \
	mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i -r && \
	mkdir -p fetch_content build && cd fetch_content && \
	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DENABLE_BMV2=ON \
		-DENABLE_EBPF=ON \
		-DENABLE_UBPF=ON \
		-DENABLE_DPDK=ON \
		-DENABLE_P4C_GRAPHS=ON \
		-DENABLE_P4TEST=ON \
		-DENABLE_DOCS=OFF \
		-DENABLE_GC=ON \
		-DENABLE_GTESTS=OFF \
		-DENABLE_PROTOBUF_STATIC=ON \
		-DENABLE_MULTITHREAD=OFF \
		-DENABLE_TEST_TOOLS=ON || (echo "CMake configuration failed" && exit 1) && \
	cd .. && \
	rm -rf fetch_content/_deps/*-build fetch_content/_deps/*-subbuild && \
	for src_folder in fetch_content/_deps/*-src; do \
		if [ -d "$$src_folder/.git"  ]; then \
			(cd "$$src_folder" && git clean -dfx) || (echo "Git clean failed" && exit 1); \
		fi; \
	done && \
	cp -r fetch_content/_deps build/ && \
	rm -rf fetch_content

bmv2-install-deps: bmv2 apt-update
	cd bmv2 && \
	git checkout 68f4a978f465fd76e98fcdecb762981843fb7310 && \
	mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i -r

pi-install-deps: pi apt-update
	cd pi && \
	git checkout 5689c91a8a7423781267b27d8b166c49a53904ff && \
	mk-build-deps -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" -i -r

#######################
# Build binary packages
########################

p4c-deb: p4c-install-deps
	cd p4c && \
	dpkg-buildpackage -us -uc

bmv2-deb: bmv2-install-deps
	cd bmv2 && \
	dpkg-buildpackage -us -uc

pi-deb: pi-install-deps
	cd pi && \
	dpkg-buildpackage -us -uc

########################
# Build source packages
########################

p4c-sdeb: p4c-install-deps
	cd p4c && \
	debuild -uc -us -sa

bmv2-sdeb: bmv2-install-deps
	cd bmv2 && \
	git checkout . && \
	git clean -dfx && \
	tar czf ../p4lang-bmv2_1.15.0.orig.tar.gz --exclude=debian --exclude=.pc . && \
	debuild -S -uc -us -sa

.PHONY: bmv2-repack
bmv2-repack:
	git -C bmv2 checkout .
	git -C bmv2 clean -dfx
	tar Cczf bmv2 p4lang-bmv2_1.15.0.orig.tar.gz --exclude=debian --exclude=.pc .
	rsync -a --delete p4lang-bmv2/ bmv2/debian/
	cd bmv2 && debuild -S -uc -us -sa

.PHONY: pi-repack
pi-repack:
	git -C pi checkout .
	git -C pi clean -dfx
	tar Cczf pi p4lang-pi_0.1.0.orig.tar.gz --exclude=debian --exclude=.pc .
	rsync -a --delete p4lang-pi/ pi/debian/
	cd pi && debuild -S -uc -us -sa

# Don't reinstall deps and don't clean (debuild -nc). *Do* refresh debian files.
bmv2-sdeb-quick:
	rsync -a --delete p4lang-bmv2/ bmv2/debian/
	cd bmv2 && \
	tar czf ../p4lang-bmv2_1.15.0.orig.tar.gz --exclude=debian --exclude=.pc . && \
	debuild -S -uc -us -sa

pi-sdeb: pi-install-deps
	cd pi && \
	debuild -uc -us -sa

clean:
	rm -f *.deb *.changes *.dsc *.buildinfo *.tar.*
	if [ -d "p4c" ]; then cd p4c && git clean -dfx; fi
	if [ -d "bmv2" ]; then cd bmv2 && git clean -dfx; fi
	if [ -d "pi" ]; then cd pi && git clean -dfx; fi

.PHONY: apt-update p4c-install-deps bmv2-install-deps pi-install-deps p4c-deb p4c-sdeb bmv2-deb bmv2-sdeb bmv2-sdeb-quick pi-deb pi-sdeb clean
