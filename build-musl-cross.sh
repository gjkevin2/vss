#!/usr/bin/env bash
# build-musl-cross.sh
# 目标：在 Linux 上生成 Windows 可直接解压使用的 x86_64-linux-musl-cross.zip

set -e

# 1. 装依赖
sudo apt-get update >/dev/null 2>&1 || sudo yum install -y gcc gcc-c++ make wget
sudo apt-get install -y build-essential git gawk bison python3 texinfo zip || \
sudo yum install -y git gawk bison python3 texinfo zip unzip

# 2. 拉源码
git clone --depth=1 https://github.com/richfelker/musl-cross-make.git
cd musl-cross-make

# 3. 写配置
cat > config.mak <<EOF
TARGET    = x86_64-linux-musl
OUTPUT    = $(pwd)/output
COMMON_CONFIG += --disable-nls
GCC_CONFIG    += --enable-languages=c,c++
EOF

# 4. 编译（并行，时间 10-30 min，看机器）
make -j$(nproc)

# 5. 安装到 output/
make install

# 6. 打包成 zip / tgz
cd output
zip -r9 ../x86_64-linux-musl-cross.zip .
tar czf ../x86_64-linux-musl-cross.tgz .

echo "✅ 完成！产物："
ls -lh ../x86_64-linux-musl-cross.*