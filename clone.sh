#!/bin/bash
git clone --filter=blob:none --no-checkout \
    https://github.com/TSUSAKA-ucl/cd-config-generation.git  gjk_worker
pushd gjk_worker/
git sparse-checkout set scripts nodejs
git checkout
cd nodejs/
pnpm install
popd
ln -s gjk_worker/scripts/ s

git clone --filter=blob:none --no-checkout \
    https://github.com/TSUSAKA-ucl/robot-assets.git
pushd robot-assets/
git sparse-checkout set scripts
git checkout
pnpm install
popd
ln -s ./robot-assets/scripts/ a
