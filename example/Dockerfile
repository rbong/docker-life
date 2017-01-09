MAINTAINER Roger Bongers
# Update the environment
RUN pacman -Syy
RUN pacman -S --noconfirm archlinux-keyring
RUN pacman -Syyu --noconfirm
RUN pacman -S --noconfirm git
# Install editor
RUN pacman -S --noconfirm ctags neovim python-neovim python2-neovim
# Install file manageer
RUN pacman -S --noconfirm vifm
# Install shell
RUN pacman -S --noconfirm zsh grml-zsh-config zsh-completions
USER docker
RUN cd ~ && git clone http://github.com/rbong/dotfiles
RUN cd ~/dotfiles && ./install.sh
