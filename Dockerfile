FROM alpine AS build

WORKDIR /opt

RUN apk add --no-cache curl jq ca-certificates && \
    RELEASE_URL=$(curl -s https://api.github.com/repos/bol-van/zapret2/releases/latest | \
    jq -r '.assets[] | select(.name | test("^zapret2-v[0-9.]+\\.zip$")) | .browser_download_url') && \
    FILE_NAME=$(basename "$RELEASE_URL") && \
    curl -L "$RELEASE_URL" -o "$FILE_NAME" && \
    ZIP_FILE=$(ls zapret2-v*.zip | head -n 1) && \
    unzip "$ZIP_FILE" > /dev/null 2>&1 && \
    EXTRACTED_DIR=$(unzip -l "$ZIP_FILE" | awk '{print $4}' | grep '/$' | head -n 1 | cut -d/ -f1) && \
    rm -rf "$ZIP_FILE" && \
    mv "$EXTRACTED_DIR" zapret2 && \
    cd zapret2 && \
    chmod +x *.sh && \
    ./install_bin.sh && \
    BIN_DIR="/opt/zapret2/binaries" && \
    LINK="/opt/zapret2/nfq2/nfqws2" && \
    TARGET=$(readlink "$LINK") && \
    KEEP_DIR=$(basename "$(dirname "$TARGET")") && \
    echo "Keeping binaries directory: $KEEP_DIR" && \
    cd "$BIN_DIR" && \
    for dir in *; do \
        [ "$dir" = "$KEEP_DIR" ] && continue; \
        [ -d "$dir" ] || continue; \
        echo "Removing unused binaries: $dir"; \
        rm -rf "$dir"; \
    done && \
    mkdir -p /build/opt && \
    mv /opt/zapret2 /build/opt

COPY entrypoint.sh /build

FROM alpine

ARG TARGETPLATFORM

COPY --from=build /build/ /

RUN case "$TARGETPLATFORM" in \
        linux/arm64 | linux/amd64) \
            apk add --no-cache nftables && \
             rm -vrf /var/log/apk.log ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" ;; \
    esac

RUN apk add --no-cache netcat-openbsd curl nano tzdata ca-certificates tini && \
    rm -vrf /var/cache/apk/* && \
    chmod +x /entrypoint.sh

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]