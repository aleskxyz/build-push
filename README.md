# Build and Push Docker Image to Container Registry

Builds Docker images with customized image tags, labels, and annotations, and pushes them to a specified container registry. It is designed to run in a rootless, unprivileged container for enhanced security, including environments like self-hosted GitHub Action Runner Controller (ARC) on Kubernetes.

This is a composite GitHub Action that incorporates the following actions:

- [docker/metadata-action](https://github.com/docker/metadata-action)
- [redhat-actions/podman-login](https://github.com/redhat-actions/podman-login)
- [redhat-actions/buildah-build](https://github.com/redhat-actions/buildah-build)
- [redhat-actions/push-to-registr](https://github.com/redhat-actions/push-to-registr)

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `image_name` | Name of the Docker image to be built and pushed. | Yes | - |
| `registry_address` | URL of the container registry where the image will be pushed. | Yes | - |
| `registry_username` | Username for authentication with the container registry. | Yes | - |
| `registry_password` | Password for authentication with the container registry. | Yes | - |
| `context` | The directory path used as the build context. | No | `./` |
| `dockerfile_path` | Location of the Dockerfile. | No | `Dockerfile` |
| `flavor` | Specifies the tagging strategy. For options, see [Docker Metadata Action documentation](https://github.com/docker/metadata-action?tab=readme#flavor-input). | No | - |
| `tags` | Defines how the image is tagged. For detailed configuration, refer to [Docker Metadata Action documentation](https://github.com/docker/metadata-action?tab=readme#tags-input). | No | <pre>type=sha<br>type=ref,event=branch<br>type=ref,event=pr<br>type=schedule,pattern={{date 'YYYYMMDD-hhmmss'}}<br>type=semver,pattern={{version}}<br>type=semver,pattern={{major}}.{{minor}}<br>type=semver,pattern={{major}},enable=${{ !startsWith(github.ref, 'refs/tags/v0.') }}</pre> |
| `labels` | Custom labels to apply to the built image, separated by newlines. | No | - |
| `annotations` | Additional annotations for the image, separated by newlines. | No | - |
| `archs` | CPU architectures to target during the build, separated by commas (eg: `amd64,arm64`). **Note: Not functional in Kubernetes (ARC). Cannot be used with `platforms`.** | No | - |
| `platforms` | Target platforms for the image build, separated by commas (eg: `linux/amd64,linux/arm64`). **Note: Not functional in Kubernetes (ARC). Cannot be used with `archs`.** | No | - |
| `build_args` | Build-time variables in the form arg_name=arg_value. Separate multiple arguments with newlines. These are passed to Docker build with --build-arg. | No | - |
| `buildah_extra_args` | Additional arguments for the `buildah bud` command, separated by newlines. | No | `--isolation chroot` |
| `oci` | Sets the image format. `true` for OCI format, `false` for Docker format. Default is false. | No | `false` |
| `push_extra_args` | Extra arguments for the `podman push` command, separated by newlines. | No | - |

## Outputs

| Name | Description |
|------|-------------|
| `push_result` | JSON string with the digest and registry paths for pushed images. |

## Example Usage

```yaml
name: Build image and Push to  Github Container Registry
on:
  push:
jobs:
  build-push-ghcr:
    name: Build and push image
    runs-on: ubuntu-22.04
    permissions:
      contents: read
      packages: write
    steps:
    - name: Checkout
      uses: actions/checkout@v4
    - name: Build and Push Docker image to GHCR
      uses: aleskxyz/build-push@main
      with:
        image_name: ${{ github.event.repository.name }}
        registry_address: ghcr.io/${{ github.repository_owner }}
        registry_username: ${{ github.actor }}
        registry_password: ${{ github.token }}
        oci: true
        push_extra_args: |
          --disable-content-trust
```
