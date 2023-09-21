#!/usr/bin/env sh

if [[ ! "$OSTYPE" == "darwin"* ]]; then
    echo "Unsupported operating system (today)"
    exit 1
fi

set -- $(locale LC_MESSAGES)
yesexpr="$1"; noexpr="$2"; yesword="$3"; noword="$4"

function install_package_manager {
    local command=$1
    local curl_command=$2
    local display_name=$3
    local script_args=$4

    if ! command -v ${command} 2>&1 >/dev/null; then
        echo "Installing ${display_name}..."
        script=$(mktemp)
        if ! curl ${curl_command} > ${script}; then
            exit 2
        fi
        if ! sh ${script} ${script_args}; then
            exit 2
        fi
        rm ${script}
    fi
    echo "${display_name} package manager installed"
}

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
            echo "${installer} failed to install package ${package} for ${display_name}"
            exit 3
        fi
    fi
    echo "${display_name} command-line installed"
}

install_package_manager brew "-fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh" Homebrew

install_package brew plantuml PlantUML

install_package brew dot graphviz GraphViz

if ! command -v cargo 2>&1 >/dev/null; then
    if [[ ! -x ${HOME}/.cargo/bin/cargo ]]; then
        install_package brew cargo rustup-init "Rust Toolchain"
    fi
    export PATH=$PATH:$HOME/.cargo/bin
fi

install_package cargo sdml sdml-cli SDML

if ! command -v emacs &>/dev/null; then
    while true; do
        read -p "Emacs is the primary SDML editor, do you wish to install (${yesword}/${noword})? " yn
        if [[ "$yn" =~ ${yesexpr} ]]; then
            brew tap d12frosted/emacs-plus
            install_package brew emacs "emacs-plus@28" Emacs

            if [[ ! -d ${HOME}/.emacs.d/ ]]; then
                if ! mkdir ${HOME}/.emacs.d; then
                    exit 3
                fi
            fi
            pushd ${HOME}/.emacs.d/ 2>&1 >/dev/null

            install_package brew git Git

            git clone https://github.com/sdm-lang/tree-sitter-sdml.git || exit 3
            pushd tree-sitter-sdml 2>&1 >/dev/null
            install_package brew gmake make "GNU Make"
            if [[ ! -d ${HOME}/.tree-sitter/bin/ ]]; then
                if ! mkdir ${HOME}/.tree-sitter/bin; then
                    exit 3
                fi
            fi
            gmake emacs  || exit 3
            popd 2>&1 >/dev/null

            git clone https://github.com/sdm-lang/emacs-sdml-mode.git sdml-mode || exit 3
            popd 2>&1 >/dev/null
        elif [[ "$yn" =~ ${noexpr} ]]; then
            break
        else
            echo "Answer ${yesword} or ${noword}."
        fi
    done
fi

echo ""
sdml --help
