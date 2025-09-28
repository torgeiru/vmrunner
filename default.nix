{
  pkgs ? import <nixpkgs> {},

  virtiofsd_pinned ? import (fetchTarball {
    name = "nixpkgs-pinned-for-virtiofsd";
    url = "https://github.com/NixOS/nixpkgs/archive/13e8d35b7d6028b7198f8186bc0347c6abaa2701.tar.gz";
    sha256 = "0nqbvgmm7pbpyd8ihg2bi62pxihj8r673bc9ll4qhi6xwlfqac5q";
  }) {},
 }:
pkgs.python3.pkgs.buildPythonPackage rec {
  pname = "vmrunner";
  version = "0.16.0";
  src = ./.;  # Use the current directory as the source
  pyproject = true;
  dontUseSetuptoolsCheck = true;
  doCheck = true;

  build-system = with pkgs.python3.pkgs; [
    setuptools
    setuptools-scm
  ];

  dependencies = with pkgs.python3.pkgs; [
    future
    jsonschema
    psutil
  ];

  create_bridge = ./vmrunner/bin/create_bridge.sh;

  passthru = {
    inherit create_bridge;
    virtiofsd = virtiofsd_pinned.virtiofsd;
  };

  meta = {
    description = "A convenience wrapper around qemu for IncludeOS integration tests";
    license = pkgs.lib.licenses.asl20;
  };

  nativeCheckInputs = [
    pkgs.shellcheck
    pkgs.pylint
  ];

  checkPhase = ''
    for f in vmrunner/bin/{*.sh,qemu-ifup,qemu-ifdown}; do
      echo Checking "$f" with shellcheck
      shellcheck "$f"
    done

    for f in vmrunner/*.py; do
      echo Checking $f with pylint
      pylint --persistent no "$f"
    done
  '';

}
