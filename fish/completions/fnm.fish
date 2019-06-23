set -l subcommands alias default env install ls ls-remote uninstall use

complete -c fnm -f
complete -c fnm -l help -x -a 'auto pager groff plain' -k -d '[=FMT] (default=auto) | Show help in format FMT'
complete -c fnm -l version -f -d 'Show version information'

complete -c fnm -n "not __fnm_seen_subcommand_from $subcommands; and __fnm_not_seen_common_option" -a alias -d 'Alias a version'
complete -c fnm -n "not __fnm_seen_subcommand_from $subcommands; and __fnm_not_seen_common_option" -a default -d 'Alias a version as default'

complete -c fnm -n "not __fnm_seen_subcommand_from $subcommands; and __fnm_not_seen_common_option" -a env -d 'Show env configurations'
complete -c fnm -n '__fnm_seen_subcommand_from env; and __fnm_not_seen_common_option' -l fish -f -d 'Output an env configuration for fish shell'
complete -c fnm -n '__fnm_seen_subcommand_from env; and __fnm_not_seen_common_option' -l fnm-dir -r -d "=VAL (absent=$HOME/.fnm) | The directory to store internal fnm data"
complete -c fnm -n '__fnm_seen_subcommand_from env; and __fnm_not_seen_common_option' -l log-level -x -a 'quiet error all' -k -d '=VAL (absent=info) | The log level of fnm commands'
complete -c fnm -n '__fnm_seen_subcommand_from env; and __fnm_not_seen_common_option' -l multi -f -d 'Allow different Node versions for each shell'
complete -c fnm -n '__fnm_seen_subcommand_from env; and __fnm_not_seen_common_option' -l node-dist-mirror -x -a 'https://npm.taobao.org/dist' -d '=VAL (absent=https://nodejs.org/dist)'
complete -c fnm -n '__fnm_seen_subcommand_from env; and __fnm_not_seen_common_option' -l shell -x -a 'fish bash zsh' -k -d '=VAL | Specifies a specific shell type'
complete -c fnm -n '__fnm_seen_subcommand_from env; and __fnm_not_seen_common_option' -l use-on-cd -f -d 'Hook into the shell `cd` and automatically use the specified version for the project'

complete -c fnm -n "not __fnm_seen_subcommand_from $subcommands; and __fnm_not_seen_common_option" -a install -d 'Install another node version'

complete -c fnm -n "not __fnm_seen_subcommand_from $subcommands; and __fnm_not_seen_common_option" -a ls -d 'List all the installed versions'
complete -c fnm -n "not __fnm_seen_subcommand_from $subcommands; and __fnm_not_seen_common_option" -a ls-remote -d 'List all the versions upstream'

complete -c fnm -n "not __fnm_seen_subcommand_from $subcommands; and __fnm_not_seen_common_option" -a uninstall -d 'Uninstall a node version'

complete -c fnm -n "not __fnm_seen_subcommand_from $subcommands; and __fnm_not_seen_common_option" -a use -d 'Switch to another installed node version'
complete -c fnm -n '__fnm_seen_subcommand_from use; and __fnm_not_seen_common_option' -l quiet -f -d "Don't print stuff"

function __fnm_seen_subcommand_from
    set -l subcommand (commandline -pco)[2]
    return (contains -- $subcommand $argv)
end

function __fnm_not_seen_common_option
    set -l common_options help version
    set -l commandline (commandline -pco)
    set -e commandline[1]

    for option in $common_options
        set -l regex "^--$option(?:=|\$)"

        if string match -q -r -- $regex $commandline
            return 1
        end
    end
end

complete -c fnm -n '__fnm_seen_subcommand_from alias; and __fnm_not_seen_common_option; and __fnm_not_seen_installed_version' -a '$__fnm_installed_versions' -k
complete -c fnm -n '__fnm_seen_subcommand_from alias; and __fnm_not_seen_common_option; and __fnm_preceded_by_version' -a '$__fnm_alias_completions' -k

set -g __fnm_version_with_aliases_regex '\*\h([[:alnum:]\.]+)(?:\h\((.+)\))?'

function __fnm_not_seen_installed_version
    return (__fnm_not_seen_version $__fnm_installed_versions $argv)
end

function __fnm_not_seen_version
    set -l commandline (commandline -po)
    set -e commandline[1 2]

    for i in $commandline
        if contains -- $i $argv
            return 1
        end
    end
end

function __fnm_preceded_by_version
    __fnm_get_installed_versions $__fnm_version_with_aliases_regex __fnm_remove_system_version __fnm_append_aliases
    return (contains -- (commandline -pco)[-1] $__fnm_installed_versions)
end

function __fnm_get_installed_versions -a regex remove_system_version append_aliases
    set -g __fnm_installed_versions
    set -g __fnm_aliases
    set -g __fnm_alias_completions
    set -g __fnm_ls_output (command fnm ls)
    set -e __fnm_ls_output[1]

    if functions -q $remove_system_version; $remove_system_version; end

    for line in $__fnm_ls_output
        set -l match (string match -r $regex $line)
        set -l node_version $match[2]
        set -a __fnm_installed_versions $node_version

        if functions -q $append_aliases; $append_aliases $match[3] $node_version; end
    end
end

function __fnm_remove_system_version
    if string match -qe '* system' $__fnm_ls_output[1]
        set -e __fnm_ls_output[1]
    end 
end

function __fnm_append_aliases -a aliases node_version
    if set -q aliases
        set aliases (string split ', ' $aliases)
        set -a __fnm_aliases $aliases
        set -a __fnm_alias_completions $aliases\t$node_version
    end
end

complete -c fnm -n '__fnm_seen_subcommand_from default; and __fnm_not_seen_common_option; and __fnm_complete_for_default' -a '$__fnm_installed_versions' -k

function __fnm_complete_for_default
    __fnm_get_installed_versions '\*\h([[:alnum:]\.]+)' __fnm_remove_system_version
    return (__fnm_not_seen_installed_version)
end

complete -c fnm -n '__fnm_seen_subcommand_from install; and __fnm_not_seen_common_option; and __fnm_not_seen_remote_version' -a '$__fnm_remote_versions' -k

function __fnm_not_seen_remote_version
    set -g __fnm_remote_versions (command fnm ls-remote)
    set -e __fnm_remote_versions[1]
    set __fnm_remote_versions (string sub -s 3 $__fnm_remote_versions)

    return (__fnm_not_seen_version $__fnm_remote_versions)
end

complete -c fnm -n '__fnm_seen_subcommand_from uninstall; and __fnm_not_seen_common_option; and __fnm_complete_for_uninstall' -a '$__fnm_alias_completions $__fnm_installed_versions' -k

function __fnm_complete_for_uninstall
    __fnm_get_installed_versions $__fnm_version_with_aliases_regex __fnm_remove_system_version __fnm_append_aliases
    return (__fnm_not_seen_installed_version $__fnm_aliases)
end

complete -c fnm -n '__fnm_seen_subcommand_from use; and __fnm_not_seen_common_option; and __fnm_complete_for_use' -a '$__fnm_alias_completions $__fnm_installed_versions' -k

function __fnm_complete_for_use
    __fnm_get_installed_versions $__fnm_version_with_aliases_regex '' __fnm_append_aliases
    return (__fnm_not_seen_installed_version $__fnm_aliases)
end
