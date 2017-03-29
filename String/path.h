
std::string BaseName(std::string const& pathname)
{
    return std::string(
        std::find_if(
            pathname.rbegin()
            , pathname.rend()
            , [](char ch) { return ch == '\\' || ch == '/'; }
        ).base()
        , pathname.end()
    );
}

std::string RemoveExtension(std::string const& filename)
{
    std::string::const_reverse_iterator pivot = std::find(filename.rbegin(), filename.rend(), '.');
    return pivot == filename.rend() ? filename : std::string(filename.begin(), pivot.base() - 1);
}