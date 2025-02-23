# This is meant to be sourced, don't run this

get_var_val()
{
    echo "$1" | cut -d = -f 2-
}
