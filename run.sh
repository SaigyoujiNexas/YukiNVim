rm -rf ~/.clang-format
printf "BasedOnStyle: LLVM\nIndentWidth: 4" >>~/.clang-format

packet_manager=""
is_mac=false
packages=("neovim" "ripgrep" "fd" "gcc" "cmake" "make" "rbenv" "nodejs" "php")
function install_brew() {
	if type brew >/dev/null 2>&1; then
		echo "Homebrew is already installed"
	else
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
}

# config packet_manager and need sudo
if [[ "$(uname)" == "Darwin" ]]; then
	echo "This is mac"
	install_brew
	packet_manager="brew"
	is_mac=true
else
	packet_manager="apt"
fi

#update packet manager
if $is_mac; then
	brew update
	brew upgrade
else
	sudo apt update
	sudo apt upgrade
fi

# add platform packages.
if $is_mac; then
	packages+=("ruby-build")
	packages+=("python")
else
	packages+=("ruby")
	packages+=("python3")
fi

# config packages to build install command.
install_command="${packet_manager} install"

for package in "${packages[@]}"; do
	install_command="${install_command} ${package}"
done

if ! $is_mac; then
	install_command="sudo ${install_command}"
fi

$install_command

npm install -g neovim
pip3 install neovim

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

#install cargo
if ! type cargo >/dev/null 2>&1; then
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi
#install sdkman
if ! [ -d "$HOME/.sdkman" ]; then
	curl -s "https://get.sdkman.io" | bash
fi
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install java 21.0.3-graal
