#!/usr/bin/env sh

SUCCESS="\033[32;1m✓\033[0m"
WARNING="\033[33;1m!\033[0m"
ERROR="\033[31;1m✗\033[0m"

if [[ ! "$OSTYPE" == "darwin"* ]]; then
    echo "${ERROR} Unsupported operating system (today)"
    exit 1
fi

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

install_package brew plantuml PlantUML

install_package brew dot graphviz GraphViz

if ! command -v cargo 2>&1 >/dev/null; then
    if [[ ! -x ${HOME}/.cargo/bin/cargo ]]; then
        install_package brew cargo rustup-init "Rust Toolchain"
    fi
    export PATH=$PATH:$HOME/.cargo/bin
fi

install_package cargo sdml sdml-cli SDML

if ! command -v femacs &>/dev/null; then
    set -- $(locale LC_MESSAGES)
    yesexpr="$1"; noexpr="$2"; yesword="$3"; noword="$4"
    cat <<EOF

While any text editor may be used with SDML we recommend a programmer's editor
such as TextMate, SublimeText, or vi (vim); or an IDE such as Visual Studio Code
or IDEA/CLion/RustRover.

- https://macromates.com/
- https://www.sublimetext.com/
- https://www.vim.org/
- https://code.visualstudio.com/
- https://www.jetbrains.com/

Emacs has been the primary SDML editor and has support for syntax highlighting
and org-mode support for writing documentation. The SDML language documentation
itself was written entirely in org-mode.

EOF
    EMACS_HOME=${HOME}/.emacs.d
    while true; do
        read -p "Do you wish to install Emacs (${yesword}/${noword})? " yn
        if [[ "$yn" =~ ${yesexpr} ]]; then
            brew tap d12frosted/emacs-plus
            install_package brew emacs "emacs-plus@28" Emacs

            if [[ ! -d ${EMACS_HOME} ]]; then
                if ! mkdir ${EMACS_HOME}; then
                    exit 3
                fi
            fi
            pushd ${EMACS_HOME} 2>&1 >/dev/null

            install_package brew git Git

            if [[ ! -d ./tree-sitter-sdml ]]; then
                git clone https://github.com/sdm-lang/tree-sitter-sdml.git || exit 3
                echo "${SUCCESS} Cloned tree-sitter library in ${EMACS_HOME}/tree-sitter-sdml"
            fi

            if [[ ! -d ./sdml-mode ]]; then
                git clone https://github.com/sdm-lang/emacs-sdml-mode.git sdml-mode || exit 3
                echo "${SUCCESS} Cloned sdml-mode in ${EMACS_HOME}/sdml-mode"
            fi

            echo "${SUCCESS} Checkout the documentation for instructions on Emacs configuration."

            popd 2>&1 >/dev/null
            break
        elif [[ "$yn" =~ ${noexpr} ]]; then
            break
        else
            echo "${WARNING} Answer ${yesword} or ${noword}."
        fi
    done
fi

echo ""
sdml --help
