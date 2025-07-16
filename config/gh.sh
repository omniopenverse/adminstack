#!/bin/bash

# List of valid commands
#
COMMANDS_LIST=(
    "login create show workplace user orgs repos"
)

# Initialize default values for options (Global variables)
#
option_user=false
option_orgs=""
option_exorgs="42-ready-player-hackathon"
option_repos=""
option_dir="$HOME/workplace"

# Function to display the help message
#
usage() {
    echo "Usage: $0 [-login] [-orgs <args>] [-exorgs <args>] [-dir <arg>] [--] <command>"
    echo
    echo "Options:"
    echo "  --user              Limit the scope to user repositories only"
    echo "  --orgs <args>       Select specific organizations. Comma separate list"
    echo "  --exorgs <args>     Exclude specific organizations. Comma separate list"
    echo "  --repos <args>      Select specific repositories. Comma separate list"
    echo "  --dir <arg>         Set the target directory where repository will be cloned (default $HOME/workplace)"
    echo "  --                  Stop parsing options (useful for positional args starting with '-')"
    echo
    echo "Available commands:"
    echo "  login               Login to github"
    echo "  create  workplace   Create the work directory with all organizations and repositories"
    echo "  show    orgs        Show the list of organizations of the logged user"
    echo "  show    repos       Show the list of repositories of the logged user"
    exit 1
}

# Argument parsing
#
while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)
        option_user=true
        shift
        ;;        
        --orgs)
        if [[ -n "$2" && "$2" != -* ]]; then
            option_orgs="$2"
            shift 2
        else
            echo "Error: --orgs requires an argument."
            usage
        fi
        ;;
        --exorgs)
        if [[ -n "$2" && "$2" != -* ]]; then
            option_exorgs="$2"
            shift 2
        else
            echo "Error: --exorgs requires an argument."
            usage
        fi
        ;;
        --repos)
        if [[ -n "$2" && "$2" != -* ]]; then
            option_repos="$2"
            shift 2
        else
            echo "Error: --repos requires an argument."
            usage
        fi
        ;;
        --dir)
        if [[ -n "$2" && "$2" != -* && -d "$2" ]]; then
            option_dir="$2"
            shift 2
        else
            echo "Error: -dir requires an existing directory path as argument."
            usage
        fi
        ;;
        --)
        shift
        break
        ;;
        -*)
        echo "Unknown option: $1"
        usage
        ;;
        *)
        # Stop processing options when positional arguments are encountered
        break
        ;;
    esac
done
#________________________________________________________________________
# Get all arguments
#
i=1
ARG_COUNT=$#
for arg in "$@"; do
    if [[ ! ${COMMANDS_LIST[@]} =~ "$arg" ]]; then
        echo "Error: invalid command."
        usage
    fi
    # Assign each argument to a variable like var1, var2, etc.
    eval "ARG$i='$arg'"
    i=$((i + 1))
done

#________________________________________________________________________

# Check if user is logged in
#
is_logged() {
    gh auth status
}

# login to github
#
login() {
    if [[ ! $(is_logged) ]]; then
        gh auth login
    fi
}

# Get User
#
get_user() {
    gh api user --jq ".login"
}

# Get all organizations of logged user\
#
get_orgs() {
    ORGS=$(get_user)
    if [[ $option_user == true ]]; then
        echo $ORGS
    else
        echo $ORGS && gh api /user/orgs --jq ".[].login"
    fi
}

# Get all repositories in given organisation
#
get_repos() {
    local ORGANIZATION=$1

    gh repo list "$ORGANIZATION" --limit 100 --json name -q '.[].name'
}

# Clone a repository in an organization
#
clone_repository() {
    local ORGANIZATION=$1
    local REPOSITORY=$2
    if [[ ! -d  "$option_dir/$ORGANIZATION/$REPOSITORY" ]]; then
        gh repo clone "$ORGANIZATION/$REPOSITORY" "$option_dir/$ORGANIZATION/$REPOSITORY" 
        echo "│ Repository $ORGANIZATION/$REPOSITORY cloned successfully."
    else
        echo "│ Warn: Folder $option_dir/$ORGANIZATION/$REPOSITORY already exists locally."
    fi
}

# Check if the organization is in the list of organizations to be included or excluded
#
check_organization() {
    local ORGANIZATION=$1

    if [[ $option_user == true ]]; then
        return 0
    elif [[ ! ${option_exorgs[@]} =~ $ORGANIZATION && (-z $option_orgs || ${option_orgs[@]} =~ $ORGANIZATION ) ]]; then
        return 0
    else
        return 1
    fi
}

# Check if the repository is in the list of repositories to be included or excluded
#
check_repository() {
    local REPOSITORY=$1

    if [[ -z $option_repos || ${option_repos[@]} =~ $REPOSITORY ]]; then
        return 0
    else
        return 1
    fi
}

# Create workplace
#
create_workplace() {
    local ORGANIZATIONS=$(get_orgs)

    for ORGANIZATION in $ORGANIZATIONS; do
        if check_organization $ORGANIZATION; then
            REPOSITORIES=$(get_repos $ORGANIZATION)
            echo "╭───────────$ORGANIZATION:"
            for REPOSITORY in $REPOSITORIES; do
                if check_repository $REPOSITORY; then
                    clone_repository $ORGANIZATION $REPOSITORY
                fi
            done;
            echo "╰────────────────────────────── ▪ ▪ ▪"
        fi
    done;
}

# Show repositories
#
show_repositories() {
    local ORGANIZATIONS=$(get_orgs)

    for ORGANIZATION in $ORGANIZATIONS; do
        if check_organization $ORGANIZATION; then
            echo "╭───────────$ORGANIZATION:"
            REPOSITORIES=$(get_repos $ORGANIZATION)
            for REPOSITORY in $REPOSITORIES; do
                if check_repository $REPOSITORY; then
                    echo "│ $REPOSITORY"
                fi
            done;
            echo "╰──────────────────────────────╯"

        fi
    done;
}

#________________________________________________________________________
# Run appropriate command
#
if [[ "$ARG_COUNT" = "1" && "$ARG1" = "login" ]]; then
    login
    exit 0
fi

if [[ "$ARG_COUNT" = "2" ]]; then
    if [[ "$ARG1" == "create" && "$ARG2" == "workplace" ]]; then
        create_workplace
        exit 0
    elif [[ "$ARG1" == "show" ]]; then
        if [[ "$ARG2" == "user" ]]; then
            get_user
            exit 0
        elif [[ "$ARG2" == "orgs" ]]; then
            get_orgs
            exit 0
        elif [[ "$ARG2" == "repos" ]]; then
            show_repositories
            exit 0
        fi
    fi
fi
echo "Error: Invalid command."
usage

