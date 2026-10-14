#!/bin/bash
# Java: adoptopenjdk 11 (halcyon plugin). adoptopenjdk is discontinued; move to temurin when you pick a version.
. "$(dirname "$0")/asdf-lib.sh"
asdf_setup
asdf_add java https://github.com/halcyon/asdf-java
asdf_install_global java adoptopenjdk-11
# Maven 3.8.7 is installed by hand
