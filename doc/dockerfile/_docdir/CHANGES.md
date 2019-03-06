v6.1.0 2019-02-06 Cambridge
---------------------------

- Add support for Fedora 29 and OpenSUSE Leap 15.0 and Alpine 3.9.
- Demote some releases to Tier 2 from Tier 1.
- Add functions to calculate base distro tags in `Dockerfile_distro`.
- Install bzip2 and rsync on OpenSUSE distros.
- Add a `Dockerfile_opam.deprecated` container for being able to turn off older distros. 
- Install `which` into OpenSUSE containers by default.
- Use `+trunk` suffix for dev versions of compiler.
- Remove unused GNU Parallel wrapper in `dockerfile_cmd`.

v6.0.0 2018-11-15 Cambridge
---------------------------

This release focuses on the opam 2.0 release and the resulting
containers built on ocaml/opam2 on the Docker Hub.

- set the `OPAMYES` variable to true by default in ocaml
  containers so they remain non-interactive.
- install rsync in RPM distros
- Install opam-depext in the containers by default
- fix opam2 alpine and centos installation by installing openssl
- add a dependency on `ppx_sexp_conv` for dockerfile-cmd
- add support for Aarch32 in distros
- install coreutils in Alpine since OCaml 4.08 needs GNU stat to compile
- add support for Ubuntu 18.10 and Alpine 3.8 releases.
- add xz to Alpine and Zypper distributions.
- `install_opam_from_source` requires an explicit branch rather
  than defaulting to master.
- update version of Bubblewrap in containers to 0.3.1.
- port build system from Jbuilder to Dune.

v5.1.0 2018-06-15 Cambridge
---------------------------

- Remove unnecessary cmdliner dep in dockerfile-opam
- Support Tier2 distros in bulk builds

v5.0.0 2018-06-07 Cambridge
---------------------------

- Install the Bubblewrap sandboxing tool in all distributions and
  remove the older wrappers for opam2 namespace usage.
- Ensure that X11 is available in the containers so that the
  OCaml Graphics module is available (#8 via @kit-ty-kate)
- Add concept of a "Tier 1" and "Tier 2" distro so that we can
  categorise them more easily for container generation.
- Add support for Alpine 3.7 and Ubuntu 18.04 and Fedora 28.
- Update Ubuntu LTS to 18.04. 
- Deprecate Ubuntu 17.10 and 12.04 (now end-of-life).
- Alter the individual compiler containers to omit the patch version
  from the name. They will always have the latest patch version for CI.
- Allow distro selection to be filtered by OCaml version and architecture.
  This allows combinations like Ubuntu 18.04 (which breaks on earlier
  versions of OCaml due to the shift to PIE) to be expressed.
- Add missing OpenSUSE to the latest distros list.
- Add Ppc64le architecture.

v4.0.0 2017-12-25 Cambridge
---------------------------

Major API iteration to:

- switch to multistage container builds for smaller containers
- instead of separate `ocaml` and `opam` containers, just generate
  a single `opam` one which can optionally have the system compiler
  or a locally compiled one.
- explicitly support aliases for distributions, and allow older
  distributions to be marked as deprecated.

Other changes:
* Update OPAM 2 build mechanism to use `make cold`.
* Drop support for opam1 containers; use an older library version for those.
* Also mark OCaml 4.05.0 and 4.06.0 as a mainline release for opam2 as well.

v3.1.0 2017-07-14 Cambridge
---------------------------

* Mark OCaml 4.05.0 as a released stable version.
* Remove the Alpine 3.5 camlp4 hack as it has been fixed in a
  point release upstream.
* Add minimum constraint on sexplib in build rules (#6 reported by @smondet)
* Add support for Alpine 3.6 and Debian 10 (Buster).
* Bump the most recent Debian Stable to Debian 9.
* Bump the most recent Alpine to Alpine 3.6.
* Add OCaml 4.04.2 as the most recent compiler

v3.0.0 2017-06-14 Cambridge
---------------------------

* Add support for [multistage builds](https://docs.docker.com/engine/userguide/eng-image/multistage-build/)
  to the `from`, `add`, and `copy` commands.

There are also backwards incompatible changes to the package layout:

* Split up OPAM packages into `dockerfile` and `dockerfile-opam`.
  The latter contains the OPAM- and Linux-specific modules, with
  the core DSL in `dockerfile`.
* Port to [jbuilder](https://github.com/janestreet/jbuilder).

v2.2.3 2017-05-01 Cambridge
--------------------------

* Add OCaml 4.04.1 to the stable released set.
* Add Ubuntu 17.04 and Fedora 25 to the distribution list.
* Setup OPAM2 wrappers in containers. This will enforce Linux
  namespaces upon building and installing the packages, preventing
  them from doing network access when they shouldn't or writing files
  where they shouldn't (#1 from @AltGr).  These are not activated
  by default and are present in `/etc/opamrc.userns` in the relevant
  OPAM2 containers.

v2.2.2 2017-03-22 Cambridge
---------------------------

* Register 4.06.0 as a trunk compiler revision.
* Correctly install aspcud in all Alpine 3.5 containers.

v2.2.1 2017-02-22 Cambridge
---------------------------

* Bump latest stable OCaml to 4.04.0.
* Add OCaml 4.06.0dev into the build matrix.
* Support latest OPAM 2.0beta release.
* Bump the "latest" distro tags to Alpine 3.5 and OpenSUSE 42.2.

v2.2.0 2017-01-12 Cambridge
---------------------------

* Remove support for ARM variants from the default distribution
  list.  They will come back as explicitly supported multiarch
  targets, instead of the current qemu builds that are mixed up
  with x86_64 targets.
* Always install OPAM from source on Alpine until upstreaming
  is complete.
* Register 4.04 as a mainline compiler as well (fixes OPAM2).
* Add support for Alpine 3.5 and OpenSUSE 42.2, and promote
  the Alpine:latest images to Alpine 3.5.
* Do not install camlp4 by default in distributions.
* Refresh `aspcud` remote proxy with url-escaping fixes
  (via @OCamlPro-Henry in ocaml/opam#2809)
* Add Ubuntu 16.10 to the built-distros list.

v2.1.0 2016-11-07 Cambridge
---------------------------

* Update for OCaml 4.04 release. Now the "latest version"
  of the compiler is 4.03.0 since many packages do not yet
  compile for 4.04.
* Do not install `camlp4` in the base OPAM switch by default,
  as the dependencies in upstream OPAM work well enough to
  pull it in on-demand.

v2.0.0 2016-11-04 Cambridge
---------------------------

* Move `Dockerfile.Linux` to a separate `Dockerfile_linux`
  module, in preparation for `Dockerfile_windows` soon.
* Avoid using ppx annotations for sexp in the interface
  files, since this breaks ocamldoc.
* Add `Dockerfile.pp` for Format-style output.

v1.7.2
------

* Port to build using topkg and remove _oasis.
* Support `-safe-string` mode.
* Install `xz` into base Fedora and other RPM distros.
* Expose a `Linux.RPM.update` to force a Yum update.
* Install `openssl` as a dependency for OPAM2.

v1.7.1
------

* Support OPAM 2 better with explicit compiler selection.
* Correctly install ocamldoc in system OpenSUSE container.

v1.7.0
------

* *Multiarch:* Add Alpine 3.4 and Alpine/ARMHF 3.4 and
  deprecate Raspbian 7.
* Add OpenSUSE/Zypper support and add OpenSUSE 42.1 to the
  default distro build list.
* Add Ubuntu 16.10 to the distro list, and remove Ubuntu 15.10
  from default build list now that 16.10 LTS is available.
* Add Fedora 24 and make it the alias for Fedora stable. Also
  install `redhat-rpm-config` which is needed for pthreads.
* Add an `extra` arg the Dockerfile_distro matrix targets to
  add more distros to the mix, such as Raspbian.
* Support multiple OPAM versions in the matrix generation, 
  to make testing OPAM master easier.
* Always do an `rpm --rebuilddb` before a Yum invocation to
  deal with possible OverlayFS brokenness.
* Support `opam_version` to distro calls to build and install
  the latest version of OPAM2-dev.
* Add `xz` into Alpine containers so that untar of those works.
* Expose the development versions of OCaml compilers.

v1.6.0
------

* Add a more modern Git in CentOS 6 to make it work with OPAM
  remote refs.

v1.5.0
------

* Add released OCaml 4.03.0 into the compiler list, and break up
  the exposed variables into a more manageable set of
  `stable_ocaml_versions` and `all_ocaml_versions`.
* Install `centos-release-xen` remote into CentOS6/7 by default
  so that depexts for `xen-devel` work.

v1.4.0
------

* `Dockerfile_distro.generate_dockerfiles` goes into the current
  directory instead with each Dockerfile suffixed with the release
  name.  There is a new `generate_dockerfiles_in_directories`
  for the old behaviour.
* Move slow ARM distribution out of the default distro list into
  `Dockerfile_distro.slow_distros`.
* Add optional `?pin` argument to `dockerfile_distro` generation
  to make it easier to customise version of packages installed.

v1.3.0
------

* Rearrange OCaml installation commands to be in `Dockerfile` instead
  of in `Dockerfile_opam` (which is now purely OPAM installation).
* Create a `~/.ssh` folder with the right permissions in all distros.
* Ensure rsync is installed in all the Debian-based containers.
* Correctly label the ARMv7 containers with the `arch=armv7` label.
* Use ppx to build instead of camlp4. Now depends on OCaml 4.02+.

v1.2.1
------

* Remove redundant `apk update` from Alpine definition.
* Switch default cloud solver to one dedicated to these images so
  they can updated in sync (the default cloud one is getting hit
  by many bulk build hits in parallel and cannot cope with the load).
* Add `distro_of_tag` and `generate_dockerfile` to `Dockerfile_distro`.
* Add `nano` to images to satisfy `opam pin` going interactive.
* Also include `4.03.0` flambda build.
* Add ARMv7hf Raspbian distro (Wheezy and Jessie).

v1.2.0
------

* Add `dev-repo` metadata to OPAM file.
* Add support for installing the cloud solver for platforms where aspcud is not available.
* Add CMD entrypoints for containers.
* Alpine: add `bash` in container (requested by @justincormack)
* Debian: correct non-interactive typos and add `dialog` in container
* Remove `onbuild` triggers from OPAM containers as it inhibits caching (suggestion via @talex5)
* Include specific Debian versions (v7,8,9) in addition to the stable/unstable streams.
* Add `Dockerfile.crunch` to reduce the number of layers by combining
  repeated `RUN` commands.
* Set Debian `apt-get` commands to `noninteractive`.
* Add support for Ubuntu 12.04 LTS and also bleeding edge 16.04.
* Add sexplib convertors for `Dockerfile.t`.
* Add `Dockerfile_distro` module to handle supported online distributions.
* Add `Dockerfile.label` to support Docker 1.6 metadata labels.
* Add `generate_dockerfiles_in_git_branches` to make it easier
  to use Docker Hub dynamic branch support to build all permutations.
* Correctly escape the `run_exec`, `entrypoint_exec` and `cmd_exec`
  JSON arrays so that the strings are quoted.
* Run `yum clean` after a Yum installation.
* Add support for Alpine Linux.
* Cleanup OPAM build directory to save container space after building from source.
* Remove support for OpenSUSE remotes, as it is no longer maintained.

v1.1.1 2015-03-11 Cambridge
---------------------------

* Add a `?prefix` argument to `install_opam_from_source`

v1.1.0 2015-01-24 Cambridge
---------------------------

* Add `Dockerfile_opam` and `Dockerfile_opam_cmdliner` modules with
  specific rules for managing OPAM installations with Dockerfiles.

v1.0.0 2014-12-30 Cambridge
---------------------------

* Initial public release.

