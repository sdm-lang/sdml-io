#!/usr/bin/env sh

SUCCESS="\033[32;1m✓\033[0m"
WARNING="\033[33;1m!\033[0m"
ERROR="\033[31;1m✗\033[0m"

case "$OSTYPE" in
  darwin*)  INSTALL_DIR='$HOME/Library/Application\ Support' ;;
  linux*)   INSTALL_DIR='$HOME/.config' ;;
  msys*)    INSTALL_DIR='$HOMEPATH/AppData/Roaming' ;;
  cygwin*)  INSTALL_DIR='$HOMEPATH/AppData/Roaming' ;;
  *)        echo "${ERROR} Unsupported operating system (today)";
            exit 1 ;;
esac

function install_package {
    local installer=$1
    local command=$2
    if [[ $# == 4 ]] ; then
        local package=$3
        local display_name=$4
    else
        local package=${command}
        local display_name=$3
    fi

    if ! command -v ${command} 2>&1 >/dev/null; then
        echo "Installing ${display_name}..."
        if ! ${installer} install ${package}; then
            echo "${ERROR} ${installer} failed to install package ${package} for ${display_name}"
            exit 3
        fi
    fi
    echo "${SUCCESS} ${display_name} command-line installed"
}

if ! command -v brew 2>&1 >/dev/null; then
    echo "${WARNING} This installer requires the Homebrew package manager to be installed."
    echo "Go to https://brew.sh/"
    exit 1
fi

echo "\033[1m"
cat <<EOF

        ___          _____          ___ 
       /  /\        /  /::\        /__/\ 
      /  /:/_      /  /:/\:\      |  |::\ 
     /  /:/ /\    /  /:/  \:\     |  |:|:\    ___     ___ 
    /  /:/ /::\  /__/:/ \__\:|  __|__|:|\:\  /__/\   /  /\ 
   /__/:/ /:/\:\ \  \:\ /  /:/ /__/::::| \:\ \  \:\ /  /:/ 
   \  \:\/:/~/:/  \  \:\  /:/  \  \:\~~\__\/  \  \:\  /:/ 
    \  \::/ /:/    \  \:\/:/    \  \:\         \  \:\/:/ 
     \__\/ /:/      \  \::/      \  \:\         \  \::/ 
       /__/:/        \__\/        \  \:\         \__\/ 
       \__\/                       \__\/ 
                      Domain                      Language
        Simple                      Modeling

EOF
echo "\033[0m"

echo "Checking for required packages..."

install_package brew plantuml PlantUML
install_package brew dot graphviz GraphViz
install_package brew git Git

if ! command -v cargo 2>&1 >/dev/null; then
    if [[ ! -x ${HOME}/.cargo/bin/cargo ]]; then
        install_package brew cargo rustup-init "Rust Toolchain"
    fi
    export PATH=$PATH:$HOME/.cargo/bin
fi

install_package cargo sdml sdml-cli SDML

cat << EOF


While any text editor may be used with SDML we recommend a programmer's
editor such as TextMate, Sublime Text, or vi (vim); or an IDE such as
Visual Studio Code or IDEA/CLion/RustRover. Emacs has been the primary
SDML editor and has support for syntax highlighting and org-mode support
for writing documentation. The SDML language documentation itself was
written entirely in Emacs and org-mode.

Would you like to install one of the following editors and their
respective SDML support?

1 - Visual Studio Code (recommended)
2 - Emacs and sdml-mode (most complete support)
3 - TextMade and SDML.tmbundle
4 - Sublime Text and SDML.tmbundle (partial support)
5 - Neovim and tree-sitter-sdml (partial support)
6 - IntelliJ IDEA (partial support)
N - No editor support

EOF

function install_emacs {
    if ! brew tap d12frosted/emacs-plus; then
        echo "${ERROR} Could not tap the emacs-plus cask"
        exit 3
    fi
    install_package brew emacs "emacs-plus@28" Emacs

    EMACS_HOME=$(emacsclient --eval user-emacs-directory |cut -d '"' -f 2) || exit 3
    EMACS_HOME=${EMACS_HOME/#\~/${HOME}}
    if [[ ! -d ${EMACS_HOME} ]]; then
        if ! mkdir -p ${EMACS_HOME}; then
            exit 3
        fi
    fi
    echo "${SUCCESS} Emacs user directory is ${EMACS_HOME}"

    pushd ${EMACS_HOME} 2>&1 >/dev/null

    if [[ ! -d ${EMACS_HOME}/tree-sitter-sdml ]]; then
        if git clone https://github.com/sdm-lang/tree-sitter-sdml.git; then
            echo "${SUCCESS} Cloned tree-sitter library in ${EMACS_HOME}/tree-sitter-sdml"
        else
            echo "${ERROR} Could not clone tree-sitter library from repository";
            exit 3
        fi
    fi

    if [[ ! -d ${EMACS_HOME}/sdml-mode ]]; then
        if git clone https://github.com/sdm-lang/emacs-sdml-mode.git sdml-mode; then
            echo "${SUCCESS} Cloned sdml-mode in ${EMACS_HOME}/sdml-mode"
        else
            echo "${ERROR} Could not clone sdml-mode from repository";
            exit 3
        fi
    fi

    echo "${SUCCESS} Checkout the documentation for instructions on Emacs configuration."

    popd 2>&1 >/dev/null
}

function install_textmate_bundle {
    install_package brew mate textmate "TextMate" ;

    if [[ "$OSTYPE" == "linux"* ]]; then
		install_path = '${INSTALL_DIR}/textmate/bundles'
	else
		install_path = '${INSTALL_DIR}/TextMate/Bundles'
	fi

    mkdir -p ${install_path}

    pushd ${install_path} 2>&1 >/dev/null
	if [[ -d "./SDML.tmbundle" ]]; then
		pushd SDML.tmbundle 2>&1 >/dev/null
		if git pull; then
            echo "${SUCCESS} Updated bundle from repository"
        else
            echo "${ERROR} Could not update bundle from repository";
            exit 4
        fi
		popd 2>&1 >/dev/null
	else
		if git clone git://github.com/sdm-lang/SDML.tmbundle.git "SDML.tmbundle"; then
            echo "${SUCCESS} Cloned bundle from repository"
        else
            echo "${ERROR} Could not clone bundle from repository";
            exit 4
        fi
	fi
    popd 2>&1 >/dev/null

    if osascript -e 'tell app "TextMate" to reload bundles'; then
        echo "${SUCCESS} TextMate reloading bundles"
    else
        echo "${ERROR} Could not tell TextMate to reload ";
        exit 5
    fi
}

function install_sublime_package {
    install_package brew subl sublime-text "Sublime Text" ;

    if [[ "$OSTYPE" == "linux"* ]]; then
		install_path = '${INSTALL_DIR}/sublime-text/packages'
	else
		install_path = '${INSTALL_DIR}/Sublime\ Text/Packages'
	fi

    mkdir -p ${install_path}

    pushd ${install_path} 2>&1 >/dev/null
	if [[ -d "./SDML" ]]; then
		cd SDML
		if git pull; then
            echo "${SUCCESS} Updated bundle from repository"
        else
            echo "${ERROR} Could not update bundle from repository";
            exit 5
        fi
		cd ..
	else
		if git clone git://github.com/sdm-lang/sdml-sublime-package.git "SDML"; then
            echo "${SUCCESS} Cloned bundle from repository"
        else
            echo "${ERROR} Could not clone bundle from repository";
            exit 5
        fi
	fi
    popd 2>&1 >/dev/null
}

while true; do
    read -p "Select editor to install " editor
    case ${editor} in
        1) install_package brew code visual-studio-code "Visual Studio Code";
           if code --force --install-extension SimonJohnston.sdml; then
               echo "${SUCCESS} Visual Studio Extension installed"
           else
               echo "${ERROR} Visual Studio Extension install failed";
               exit 6
           fi
           ;;
        2) install_emacs
           ;;
        3) install_textmate_bundle
           ;;
        4) install_sublime_package
           ;;
        5) install_package brew vim neovim "Neovim" ;
           echo "${WARNING} Follow: some instructions"
           ;;
        6) install_package brew idea intellij-idea-ce "IntelliJ IDEA" ;
           echo "${WARNING} Follow: https://www.jetbrains.com/help/idea/textmate.html"
           ;;
        N*) break ;;
    esac
done

echo ""
sdml --help
