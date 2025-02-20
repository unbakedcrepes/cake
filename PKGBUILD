pkgname=cake
pkgver=1.0.0
pkgrel=1
pkgdesc="The cake is a lie."
arch=('x86_64')
url="https://github.com/unbakedcrepes/cake"
license=('GPL')
depends=('arch-install-scripts' 'coreutils' 'e2fsprogs' 'systemd' 'util-linux')
source=("https://raw.githubusercontent.com/unbakedcrepes/cake/refs/heads/main/cake.sh")
sha256sums=('74f3159307738beaf2c4b2b89ffb35280c4b24d204de15f21e1e479cb5826310')

package() {
    install -Dm755 "$srcdir/cake.sh" "$pkgdir/usr/bin/cake"
}
