#!/bin/bash
# __SP_application: run.lib
# __SP_version: 1
# __SP_runtime: bash
# __SP_api_version: 2
#
uselib run.siesta

function __SP_denchar_prepare() {
  __SP_siesta_prepare "${ionsuffix}"
}

function __SP_denchar_finish() {
  __SP_siesta_finish
}

function __SP_denchar_collect() {
  __SP_siesta_collect
}
