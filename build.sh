set -e

mode="CI"
while getopts m: flag
do
    case "${flag}" in
        m) mode=${OPTARG};;
    esac
done
mode=${mode^^}
if [ "$mode" = "RELEASE" ]; then
    release_prefix="bin/DotNetCoreSandBox"
elif [ "$mode" = "CI" ]; then
    release_prefix="bin/DotNetCoreSandBox-CI"
else
    echo "Invalid Mode: $mode"
    exit 1
fi

echo "Build Mode: $mode"

common_args="-v m -c Release --framework netcoreapp3.1"
platform_args="-p:PublishSingleFile=true --self-contained true"

# Clean bin folder
rm -rf bin

# Build Cross-Platform
echo "Building Cross-Platform binaries"
release_name="$release_prefix-cross-platform"
plugin_path="$release_name/DotNetCoreSandBox.Server/plugins"
dotnet publish DotNetCoreSandBox.Server $common_args -o "$release_name/DotNetCoreSandBox.Server"
dotnet publish DotNetCoreSandBox.Target $common_args -o "$release_name/DotNetCoreSandBox.Target"
# Build Plugins
dotnet build DotNetCoreSandBox.Plugins.Core.Common $common_args -o "$plugin_path/DotNetCoreSandBox.Plugins.Core.Common"
dotnet build DotNetCoreSandBox.Plugins.Core.Windows $common_args -o "$plugin_path/DotNetCoreSandBox.Plugins.Core.Windows"
cp -r "$plugin_path" "$release_name/DotNetCoreSandBox.Target/plugins"

if [ "$mode" = "RELEASE" ]; then

    function buildPlatform() {
        rid=$1
        echo "Building $rid binaries"
        release_name="$release_prefix-$rid"
        dotnet publish DotNetCoreSandBox.Server $common_args -r $rid $platform_args -o "$release_name/DotNetCoreSandBox.Server"
        dotnet publish DotNetCoreSandBox.Target $common_args -r $rid $platform_args -o "$release_name/DotNetCoreSandBox.Target"
        if [ "$rid" = "win-x64" ]; then
            cp -r "$plugin_path" "$release_name/DotNetCoreSandBox.Server/plugins"
            cp -r "$plugin_path" "$release_name/DotNetCoreSandBox.Target/plugins"
        else 
            mkdir -p "$release_name/DotNetCoreSandBox.Server/plugins/DotNetCoreSandBox.Plugins.Core.Common"
            cp -r "$plugin_path/DotNetCoreSandBox.Plugins.Core.Common" "$release_name/DotNetCoreSandBox.Server/plugins/DotNetCoreSandBox.Plugins.Core.Common"
            mkdir -p "$release_name/DotNetCoreSandBox.Target/plugins/DotNetCoreSandBox.Plugins.Core.Common"
            cp -r "$plugin_path/DotNetCoreSandBox.Plugins.Core.Common" "$release_name/DotNetCoreSandBox.Target/plugins/DotNetCoreSandBox.Plugins.Core.Common"
        fi
    }

    buildPlatform linux-x64
    buildPlatform linux-arm64
    buildPlatform osx-x64
    buildPlatform win-x64
fi