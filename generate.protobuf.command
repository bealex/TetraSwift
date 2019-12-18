if which protoc-gen-swift >/dev/null; then
    DIR="$(dirname "$BASH_SOURCE")"
    for f in $DIR/Sources/Protocols/Tetra/Proto/*.proto; do
        protoc --proto_path="$DIR/Sources/Protocols/Tetra/Proto/" --swift_out="$DIR/Sources/Protocols/Tetra/Proto/Generated" `basename $f`
    done
else
    echo "error: protoc-gen-swift not installed, 'brew install swift-protobuf', for more information read https://github.com/apple/swift-protobuf"
fi
